import 'package:dio/dio.dart';

import '../../../../core/errors/rest_error_parser.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/supported_currency.dart';
import '../models/exchange_rate_model.dart';

abstract interface class CurrencyRemoteDataSource {
  Future<Result<List<ExchangeRateModel>>> getHomeRates();

  Future<Result<List<ExchangeRateModel>>> getRatesForDates(
    List<String> dates,
    String targetCurrency,
  );
}

class CurrencyRemoteDataSourceImpl implements CurrencyRemoteDataSource {
  const CurrencyRemoteDataSourceImpl(this._client);

  final DioClient _client;

  static final _homeCurrencies = [
    for (final currency in SupportedCurrency.values) currency.code,
  ];

  @override
  Future<Result<List<ExchangeRateModel>>> getHomeRates() {
    return RestErrorParser.safeCall(() async {
      final latest = await _client.getRates();
      final date = latest['date'];
      if (date is! String) return <ExchangeRateModel>[];

      final previous = await _client.getRates(date: _dayBefore(date));
      return ExchangeRateModel.fromApiResponses([
        latest,
        previous,
      ], _homeCurrencies);
    });
  }

  @override
  Future<Result<List<ExchangeRateModel>>> getRatesForDates(
    List<String> dates,
    String targetCurrency,
  ) async {
    if (dates.isEmpty) return const Success([]);

    return RestErrorParser.safeCall(() async {
      DioException? lastError;
      final responses = <Map<String, dynamic>>[];

      for (final date in dates) {
        try {
          responses.add(await _client.getRates(date: date));
        } on DioException catch (error) {
          lastError = error;
        }
      }

      if (responses.isEmpty) {
        if (lastError != null) throw lastError;
        return <ExchangeRateModel>[];
      }

      return ExchangeRateModel.fromApiResponses(responses, [targetCurrency]);
    });
  }

  static String _dayBefore(String date) {
    final previous = DateTime.parse(date).subtract(const Duration(days: 1));
    return previous.toIso8601String().substring(0, 10);
  }
}
