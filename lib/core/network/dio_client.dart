import 'package:dio/dio.dart';

class DioClient {
  DioClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: _timeout,
              sendTimeout: _timeout,
              receiveTimeout: _timeout,
              responseType: ResponseType.json,
              headers: const {'Accept': 'application/json'},
            ),
          );

  static const String _latestHost = 'latest';
  static const String _domain = 'currency-api.pages.dev';
  static const String _path = '/v1/currencies/egp.json';
  static const Duration _timeout = Duration(seconds: 30);

  final Dio _dio;

  /// [date] is `yyyy-MM-dd`. Null = latest.
  Future<Map<String, dynamic>> getRates({String? date}) async {
    final response = await _dio.get<Map<String, dynamic>>(url(date));
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: const FormatException('Empty response body'),
      );
    }
    return data;
  }

  static String url([String? date]) =>
      'https://${date ?? _latestHost}.$_domain$_path';
}
