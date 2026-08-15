import '../../../../core/errors/rest_error_parser.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_client.dart';
import '../models/day_rates_model.dart';

abstract interface class CurrencyRemoteDataSource {
  /// [date] is `yyyy-MM-dd`. Null = latest.
  Future<Result<DayRatesModel>> getRates({String? date});
}

class CurrencyRemoteDataSourceImpl implements CurrencyRemoteDataSource {
  const CurrencyRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<Result<DayRatesModel>> getRates({String? date}) {
    return RestErrorParser.safeCall(() async {
      final json = await _client.getRates(date: date);
      return DayRatesModel.fromJson(json);
    });
  }
}
