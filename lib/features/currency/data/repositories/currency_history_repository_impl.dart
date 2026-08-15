import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/history_point.dart';
import '../../domain/repositories/currency_history_repository.dart';
import '../datasources/currency_history_local_data_source.dart';
import '../datasources/currency_remote_data_source.dart';
import '../models/currency_history_model.dart';
import '../models/day_rates_model.dart';

class CurrencyHistoryRepositoryImpl implements CurrencyHistoryRepository {
  const CurrencyHistoryRepositoryImpl({
    required CurrencyRemoteDataSource remoteDataSource,
    required CurrencyHistoryLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  static const _historyDays = 7;
  static const _minHistoryPoints = 5;

  final CurrencyRemoteDataSource _remote;
  final CurrencyHistoryLocalDataSource _local;

  @override
  Future<Result<List<HistoryPoint>>> getHistory({
    required String code,
    required DateTime from,
  }) async {
    final symbol = code.toUpperCase();
    final start = DateTime(from.year, from.month, from.day);
    final remote = await _fetchHistory(symbol, start);
    if (remote is Success<List<HistoryPoint>>) {
      await _saveHistory(symbol, remote.value);
      return remote;
    }

    final cached = await _local.read(symbol);
    if (cached is Success<CurrencyHistoryModel?> &&
        cached.value != null &&
        cached.value!.points.length >= _minHistoryPoints) {
      return Success(cached.value!.toEntities());
    }
    return Failure(
      cached is Failure<CurrencyHistoryModel?>
          ? cached.error
          : (remote as Failure<List<HistoryPoint>>).error,
    );
  }

  Future<Result<List<HistoryPoint>>> _fetchHistory(
    String code,
    DateTime start,
  ) async {
    final results = await Future.wait([
      for (var i = 0; i < _historyDays; i++)
        _remote.getRates(
          date: DayRatesModel.dateFormat.format(
            start.subtract(Duration(days: i)),
          ),
        ),
    ]);

    final points = <HistoryPoint>[];
    AppFailure? offline;
    for (final result in results) {
      if (result is Success<DayRatesModel>) {
        final rate = result.value.rates[code];
        if (rate != null) {
          points.add(
            HistoryPoint(date: DateTime.parse(result.value.date), rate: rate),
          );
        }
      } else if (result is Failure<DayRatesModel> &&
          (result.error is NetworkFailure || result.error is TimeoutFailure)) {
        offline = result.error;
      }
    }

    if (points.length >= _minHistoryPoints) {
      points.sort((a, b) => a.date.compareTo(b.date));
      return Success(points);
    }
    return Failure(
      offline ??
          const ServerFailure(
            message: 'No history available for this currency',
          ),
    );
  }

  Future<void> _saveHistory(String code, List<HistoryPoint> points) async {
    final fresh = CurrencyHistoryModel.fromPoints(code: code, points: points);
    final existing = await _local.read(code);
    if (existing is Success<CurrencyHistoryModel?> && existing.value == fresh) {
      return;
    }
    await _local.write(fresh);
  }
}
