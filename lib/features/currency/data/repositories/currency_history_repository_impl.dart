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
    final anchor = _anchor(anchorDate, cached);

    if (!forceRefresh && cachedPoints.length >= _minPoints) {
      yield Success(cachedPoints);
      final missing = anchor != null
          ? _missingDates(cached, days, anchor)
          : <String>[];
      if (missing.isEmpty) {
        return;
      }
    }

    final synced = await _sync(symbol, days, cached, forceRefresh, anchor);
    switch (synced) {
      case Success(:final value):
        if (cachedPoints.length < _minPoints ||
            !listEquals(cachedPoints, value)) {
          yield Success(value);
        }
      case Failure(:final error):
        if (cachedPoints.length < _minPoints) yield Failure(error);
    }
  }

  Future<List<ExchangeRateModel>> _readCached(String symbol, int days) async {
    final local = await _local.readHistoryForCurrency(symbol, limit: days);
    if (local case Success(:final value)) return value;
    return [];
  }

  Future<Result<List<HistoryPoint>>> _sync(
    String symbol,
    int days,
    List<ExchangeRateModel> cached,
    bool forceRefresh,
    String? anchor,
  ) async {
    if (anchor == null) {
      return const Failure(
        ServerFailure(message: 'No history available for this currency'),
      );
    }

    final missing = forceRefresh
        ? _dateRange(anchor, days)
        : _missingDates(cached, days, anchor);
    if (missing.isEmpty) {
      return _pointsOrFailure(cached);
    }

    final remote = await _remote.getRatesForDates(missing, symbol);
    switch (remote) {
      case Failure(:final error):
        return cached.length >= _minPoints
            ? Success(_toPoints(cached))
            : Failure(error);
      case Success(:final value):
        if (value.isEmpty && cached.length < _minPoints) {
          return const Failure(
            ServerFailure(message: 'No history available for this currency'),
          );
        }

        if (value.isNotEmpty) {
          await _local.writeRates(value);
        }
        final afterCache = await _readCached(symbol, days);
        return _pointsOrFailure(afterCache);
    }
  }

  String? _anchor(DateTime? fromList, List<ExchangeRateModel> cached) {
    if (fromList != null) return _dateFormat.format(fromList);
    return cached.firstOrNull?.date;
  }

  Result<List<HistoryPoint>> _pointsOrFailure(List<ExchangeRateModel> models) {
    final points = _toPoints(models);
    if (points.length < _minPoints) {
      return const Failure(
        ServerFailure(message: 'No history available for this currency'),
      );
    }
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
    final points =
        models
            .map(
              (model) => HistoryPoint(
                date: DateTime.parse(model.date),
                rate: model.rate,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return points;
  }
}
