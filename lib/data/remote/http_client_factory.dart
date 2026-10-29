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
      if (config.enableLogging) LogInterceptor(responseBody: false),
    ]);
    return dio;
  }
}

/// Sends the access token with every non-auth request; on 401 refreshes the token pair once
/// (shared by concurrent requests) and repeats the request. A rejected refresh ends the session.
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
    final tokens = sentToken == 'Bearer ${current.accessToken}'
        ? await (_refreshing ??= _refresh(current.refreshToken).whenComplete(() => _refreshing = null))
        : current;
    if (tokens == null) return handler.next(err);
    try {
      options.extra[_retriedKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

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
      // The server rejected the refresh token: the session is over. Without a response
      // (no network) the session is kept and the request fails with the original 401.
      if (e.response != null) await _session.end();
      return null;
    }
  }

  static bool _isAuthRequest(RequestOptions options) => options.uri.path.startsWith(ApiRoutes.authPrefix);
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
