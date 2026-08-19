import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/currency_rate.dart';
import '../../domain/repositories/currency_repository.dart';
import '../../domain/supported_currency.dart';
import '../datasources/currency_local_data_source.dart';
import '../datasources/currency_remote_data_source.dart';
import '../models/exchange_rate_model.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  CurrencyRepositoryImpl({
    required CurrencyRemoteDataSource remoteDataSource,
    required CurrencyLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final CurrencyRemoteDataSource _remote;
  final CurrencyLocalDataSource _local;

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _currencyCodes = [
    for (final currency in SupportedCurrency.values) currency.code,
  ];

  ({String date, List<CurrencyRate> rates, bool fresh})? _memory;

  @override
  Stream<Result<List<CurrencyRate>>> getHomeRates({
    bool forceRefresh = false,
  }) async* {
    final today = _dateFormat.format(DateTime.now());

    final cached = _memoryRates(today) ?? await _diskRates(today);

    if (!forceRefresh && cached != null) {
      yield Success(cached);
      if (_memory?.fresh == true) return;
    }

    final showOutcome = forceRefresh || cached == null;
    final remote = await _remote.getHomeRates();
    switch (remote) {
      case Failure(:final error):
        if (showOutcome) yield Failure(error);
      case Success(:final value) when value.isEmpty:
        if (showOutcome) {
          yield const Failure(
            UnknownFailure(message: 'No data returned from API'),
          );
        }
      case Success(:final value):
        await _local.writeRates(value);
        final rates = _toRates(value);
        _memory = (date: today, rates: rates, fresh: true);
        if (showOutcome || !listEquals(cached, rates)) {
          yield Success(rates);
        }
    }
  }

  List<CurrencyRate>? _memoryRates(String today) {
    final cache = _memory;
    if (cache == null || cache.date != today || cache.rates.isEmpty) {
      return null;
    }
    return cache.rates;
  }

  Future<List<CurrencyRate>?> _diskRates(String today) async {
    final local = await _local.readLatestForCurrencies(_currencyCodes);
    if (local case Success(:final value) when value.isNotEmpty) {
      final rates = _toRates(value);
      if (rates.isEmpty) return null;

      _memory = (date: today, rates: rates, fresh: false);
      return rates;
    }
    return null;
  }

  List<CurrencyRate> _toRates(List<ExchangeRateModel> models) {
    final byCurrency = <String, List<ExchangeRateModel>>{};
    for (final model in models) {
      (byCurrency[model.currency] ??= []).add(model);
    }

    final rates = <CurrencyRate>[];
    for (final currency in SupportedCurrency.values) {
      final entries = byCurrency[currency.code];
      if (entries == null) continue;

      entries.sort((a, b) => a.date.compareTo(b.date));
      final latest = entries.last;
      final previous = entries.length > 1 ? entries[entries.length - 2] : null;
      final change = previous == null || previous.rate == 0
          ? null
          : latest.rate - previous.rate;

      rates.add(
        CurrencyRate(
          code: currency.code,
          name: currency.name,
          rate: latest.rate,
          change: change,
          date: DateTime.parse(latest.date),
        ),
      );
    }
    return rates;
  }
}
