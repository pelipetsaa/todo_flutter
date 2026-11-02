import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/api/api_routes.dart';
import '../../core/dto/dtos.dart';
import '../local/token_storage.dart';
import '../mapper/mappers.dart';
import '../session/session_manager.dart';

class ApiConfig {
  const ApiConfig({required this.baseUrl, this.enableLogging = false});

  final String baseUrl;
  final bool enableLogging;
}

abstract final class HttpClientFactory {
  /// The free Render instance sleeps after 15 minutes without traffic and holds the first request while it starts,
  /// which can take close to a minute; a shorter timeout would turn every first sign-in into a network error.
  static const requestTimeout = Duration(seconds: 75);
  static const connectTimeout = Duration(seconds: 10);

  /// [adapter] replaces the real network in tests; [retryDelay] is the first backoff step for retried reads.
  static Dio create(
    ApiConfig config,
    SessionManager session, {
    HttpClientAdapter? adapter,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) {
    final options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: connectTimeout,
      sendTimeout: requestTimeout,
      receiveTimeout: requestTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    Dio build() {
      final dio = Dio(options);
      if (adapter != null) dio.httpClientAdapter = adapter;
      return dio;
    }

    // Refresh calls go through a bare client so that they never re-enter the auth interceptor.
    final refreshClient = build();
    final dio = build();
    dio.interceptors.addAll([
      AuthInterceptor(dio, refreshClient, session),
      RetryInterceptor(dio, baseDelay: retryDelay),
      // Headers stay out of the log: they carry the access token.
      if (config.enableLogging) LogInterceptor(requestHeader: false, responseBody: false),
    ]);
    return dio;
  }
}

/// Sends the access token with every non-auth request; on 401 refreshes the token pair once
/// (shared by concurrent requests) and repeats the request. A rejected refresh ends the session; a refresh
/// that gets no answer keeps it, and the request fails with that network error.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._refreshClient, this._session);

  static const _retriedKey = 'auth.retried';

  final Dio _dio;
  final Dio _refreshClient;
  final SessionManager _session;
  Future<StoredTokens?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tokens = _session.currentTokens;
    if (!_isAuthRequest(options) && tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || _isAuthRequest(options) || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }
    final current = _session.currentTokens;
    if (current == null) {
      await _session.end();
      return handler.next(err);
    }
    // Another request may have refreshed the pair while this one was in flight.
    final sentToken = options.headers['Authorization'];
    final StoredTokens? tokens;
    try {
      tokens = sentToken == 'Bearer ${current.accessToken}'
          ? await (_refreshing ??= _refresh(current.refreshToken).whenComplete(() => _refreshing = null))
          : current;
    } on DioException catch (e) {
      // Reported as this request's failure, so that it reads as "no connection" rather than "session expired".
      return handler.next(DioException(requestOptions: options, type: e.type, error: e.error, message: e.message));
    }
    if (tokens == null) return handler.next(err);
    try {
      options.extra[_retriedKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// The new pair, or null when the server rejected the refresh token and the session is over.
  /// Throws the [DioException] when the server could not be reached.
  Future<StoredTokens?> _refresh(String refreshToken) async {
    try {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        ApiRoutes.authRefresh,
        data: RefreshTokenDto(refreshToken: refreshToken).toJson(),
      );
      final tokens = TokenPairDto.fromJson(response.data!).toStoredTokens();
      await _session.start(tokens);
      return tokens;
    } on DioException catch (e) {
      if (e.response == null) rethrow;
      await _session.end();
      return null;
    }
  }

  /// [RequestOptions.path] is the route relative to the base URL, which may itself contain a path.
  static bool _isAuthRequest(RequestOptions options) => options.path.startsWith(ApiRoutes.authPrefix);
}

/// Repeats reads that failed with statuses a proxy returns while the server restarts or redeploys.
/// Only GETs are retried: repeating a POST could create the same todo twice.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 2, required this.baseDelay});

  static const _attemptKey = 'retry.attempt';
  static const _transientStatuses = {502, 503, 504};

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = options.extra[_attemptKey] as int? ?? 0;
    final retryable = options.method == 'GET' && _transientStatuses.contains(err.response?.statusCode);
    if (!retryable || attempt >= maxRetries) return handler.next(err);
    await Future<void>.delayed(baseDelay * (1 << attempt));
    try {
      options.extra[_attemptKey] = attempt + 1;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
