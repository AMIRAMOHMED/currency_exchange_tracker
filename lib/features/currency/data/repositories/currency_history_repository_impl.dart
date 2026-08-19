import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/history_point.dart';
import '../../domain/repositories/currency_history_repository.dart';
import '../datasources/currency_local_data_source.dart';
import '../datasources/currency_remote_data_source.dart';
import '../models/exchange_rate_model.dart';

class CurrencyHistoryRepositoryImpl implements CurrencyHistoryRepository {
  CurrencyHistoryRepositoryImpl({
    required CurrencyRemoteDataSource remoteDataSource,
    required CurrencyLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final CurrencyRemoteDataSource _remote;
  final CurrencyLocalDataSource _local;

  static const _minPoints = 2;
  static const _unavailable = Failure<List<HistoryPoint>>(
    ServerFailure(message: 'No history available for this currency'),
  );
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Stream<Result<List<HistoryPoint>>> getHistory({
    required String code,
    int days = 7,
    bool forceRefresh = false,
    DateTime? anchorDate,
  }) async* {
    final symbol = code.toUpperCase();
    final cached = await _readCached(symbol, days);
    final cachedPoints = _toPoints(cached);
    final enough = cachedPoints.length >= _minPoints;
    final anchor = anchorDate != null
        ? _dateFormat.format(anchorDate)
        : cached.firstOrNull?.date;

    if (!forceRefresh && enough) {
      yield Success(cachedPoints);
      if (anchor == null || _missingDates(cached, days, anchor).isEmpty) {
        return;
      }
    }

    final synced = await _sync(symbol, days, cached, forceRefresh, anchor);
    switch (synced) {
      case Success(:final value):
        if (forceRefresh || !enough || !listEquals(cachedPoints, value)) {
          yield Success(value);
        }
      case Failure(:final error):
        if (forceRefresh || !enough) yield Failure(error);
    }
  }

  Future<List<ExchangeRateModel>> _readCached(String symbol, int days) async {
    return switch (await _local.readHistoryForCurrency(symbol, limit: days)) {
      Success(:final value) => value,
      Failure() => [],
    };
  }

  Future<Result<List<HistoryPoint>>> _sync(
    String symbol,
    int days,
    List<ExchangeRateModel> cached,
    bool forceRefresh,
    String? anchor,
  ) async {
    if (anchor == null) return _unavailable;

    final dates = forceRefresh
        ? _dateRange(anchor, days)
        : _missingDates(cached, days, anchor);
    if (dates.isEmpty) return _pointsOrFailure(cached);

    final remote = await _remote.getRatesForDates(dates, symbol);
    switch (remote) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value) when value.isEmpty:
        return _unavailable;
      case Success(:final value):
        await _local.writeRates(value);
        return _pointsOrFailure(await _readCached(symbol, days));
    }
  }

  Result<List<HistoryPoint>> _pointsOrFailure(List<ExchangeRateModel> models) {
    final points = _toPoints(models);
    if (points.length < _minPoints) return _unavailable;
    return Success(points);
  }

  List<String> _dateRange(String anchor, int days) {
    final start = DateTime.parse(anchor);
    return List.generate(
      days,
      (index) => _dateFormat.format(start.subtract(Duration(days: index))),
    );
  }

  List<String> _missingDates(
    List<ExchangeRateModel> cached,
    int days,
    String anchor,
  ) {
    final known = cached.map((model) => model.date).toSet();
    return _dateRange(
      anchor,
      days,
    ).where((date) => !known.contains(date)).toList();
  }

  List<HistoryPoint> _toPoints(List<ExchangeRateModel> models) {
    return [
      for (final model in models)
        HistoryPoint(date: DateTime.parse(model.date), rate: model.rate),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }
}
