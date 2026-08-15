import 'dart:async';

import 'package:dio/dio.dart';

import 'app_failure.dart';
import 'dio_error_mapper.dart';
import 'result.dart';

abstract final class RestErrorParser {
  static Future<Result<T>> safeCall<T>(Future<T> Function() request) async {
    try {
      return Success<T>(await request());
    } on DioException catch (exception) {
      return Failure<T>(DioErrorMapper.map(exception));
    } on FormatException catch (exception) {
      return Failure<T>(
        ServerFailure(
          message: 'Response body was not valid JSON',
          cause: exception,
        ),
      );
    } on TypeError catch (error) {
      return Failure<T>(
        ServerFailure(
          message: 'Response payload did not match the expected shape',
          cause: error,
        ),
      );
    } on TimeoutException catch (exception) {
      return Failure<T>(
        TimeoutFailure(message: 'Operation timed out', cause: exception),
      );
    } catch (error) {
      return Failure<T>(UnknownFailure(cause: error));
    }
  }
}
