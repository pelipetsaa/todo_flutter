import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/dto/dtos.dart';
import '../../domain/domain_result.dart';
import '../../domain/error/domain_error.dart';

Future<DomainResult<T>> safeApiCall<T>(Future<T> Function() block) async {
  try {
    return Success(await block());
  } on DioException catch (e) {
    return Failure(e.toDomainError());
  } on IOException {
    return const Failure(NetworkError());
  } catch (e) {
    return Failure(UnknownError(e.toString()));
  }
}

extension DioExceptionMapper on DioException {
  DomainError toDomainError() {
    final response = this.response;
    if (response == null) {
      return switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => const NetworkError(),
        _ when error is IOException => const NetworkError(),
        _ => UnknownError(this.message),
      };
    }
    final message = ErrorResponse.tryParse(response.data)?.message;
    return switch (response.statusCode) {
      400 => ValidationFailure(serverMessage: message),
      401 => const UnauthorizedError(),
      404 => const NotFoundError(),
      409 => const ConflictError(),
      429 => const TooManyRequestsError(),
      final status => UnknownError(message ?? 'HTTP $status'),
    };
  }
}
