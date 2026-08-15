import 'dart:io';

import 'package:dio/dio.dart';

import 'app_failure.dart';

abstract final class DioErrorMapper {
  static AppFailure map(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => TimeoutFailure(
        message: 'Request timed out: ${exception.requestOptions.uri}',
        cause: exception,
      ),
      DioExceptionType.connectionError => NetworkFailure(
        message: 'Could not reach ${exception.requestOptions.uri}',
        cause: exception,
      ),
      DioExceptionType.badCertificate => NetworkFailure(
        message: 'Rejected TLS certificate for ${exception.requestOptions.uri}',
        cause: exception,
      ),
      DioExceptionType.badResponse => ServerFailure(
        message: 'Server responded with an error status',
        statusCode: exception.response?.statusCode,
        cause: exception,
      ),
      DioExceptionType.cancel => UnknownFailure(
        message: 'Request was cancelled',
        cause: exception,
      ),
      DioExceptionType.unknown => _mapUnknown(exception),
    };
  }

  /// Dio funnels socket-level problems into [DioExceptionType.unknown], so the
  /// wrapped error decides whether this is a connectivity issue.
  static AppFailure _mapUnknown(DioException exception) {
    final error = exception.error;
    if (error is SocketException || error is HttpException) {
      return NetworkFailure(
        message:
            'Connection lost while calling ${exception.requestOptions.uri}',
        cause: exception,
      );
    }
    if (error is FormatException) {
      return ServerFailure(
        message: 'Malformed response body',
        cause: exception,
      );
    }
    return UnknownFailure(message: 'Unhandled Dio error', cause: exception);
  }
}
