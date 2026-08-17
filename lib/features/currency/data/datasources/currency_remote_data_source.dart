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

  static final _homeCurrencies = SupportedCurrency.values
      .map((currency) => currency.code)
      .toList();

  @override
  Future<Result<List<ExchangeRateModel>>> getHomeRates() {
    return RestErrorParser.safeCall(() async {
      final latest = await _client.getRates();
      final date = latest['date'];
      if (date is! String) return <ExchangeRateModel>[];

      final previousDate = DateTime.parse(date).subtract(const Duration(days: 1));
      final previous = await _client.getRates(
        date: previousDate.toIso8601String().substring(0, 10),
      );

      return ExchangeRateModel.fromApiResponses(
        [latest, previous],
        _homeCurrencies,
      );
    });
  }

  @override
  Future<Result<List<ExchangeRateModel>>> getRatesForDates(
    List<String> dates,
    String targetCurrency,
  ) {
    if (dates.isEmpty) return Future.value(Success([]));

    return RestErrorParser.safeCall(() async {
      final responses = await Future.wait(
        dates.map((date) => _fetchDate(date)),
      );

      return ExchangeRateModel.fromApiResponses(
        responses.whereType<Map<String, dynamic>>().toList(),
        [targetCurrency],
      );
    });
  }

  Future<Map<String, dynamic>?> _fetchDate(String date) async {
    try {
      return await _client.getRates(date: date);
    } on DioException {
      return null;
    }
  }
}
