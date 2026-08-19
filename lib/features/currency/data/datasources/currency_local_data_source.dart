import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../models/exchange_rate_model.dart';

abstract interface class CurrencyLocalDataSource {
  Future<Result<List<ExchangeRateModel>>> readLatestForCurrencies(
    List<String> currencies,
  );

  Future<Result<List<ExchangeRateModel>>> readHistoryForCurrency(
    String currency, {
    required int limit,
  });

  Future<Result<void>> writeRates(List<ExchangeRateModel> models);
}

class CurrencyLocalDataSourceImpl implements CurrencyLocalDataSource {
  const CurrencyLocalDataSourceImpl(this._rates);

  static const String boxName = 'rates';
  static const int keepDays = 30;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  final Box<ExchangeRateModel> _rates;

  @override
  Future<Result<List<ExchangeRateModel>>> readLatestForCurrencies(
    List<String> currencies,
  ) {
    return _guard(() {
      final result = <ExchangeRateModel>[];
      for (final currency in currencies.map((c) => c.toUpperCase()).toSet()) {
        result.addAll(_newestRows(currency, limit: 2));
      }
      return result;
    });
  }

  @override
  Future<Result<List<ExchangeRateModel>>> readHistoryForCurrency(
    String currency, {
    required int limit,
  }) {
    return _guard(() => _newestRows(currency, limit: limit));
  }

  List<ExchangeRateModel> _newestRows(String currency, {required int limit}) {
    final target = currency.toUpperCase();
    final history =
        _rates.values.where((rate) => rate.currency == target).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return history.take(limit).toList();
  }

  @override
  Future<Result<void>> writeRates(List<ExchangeRateModel> models) {
    return _guard(() async {
      await _rates.putAll({
        for (final model in models) _key(model.date, model.currency): model,
      });
      await _pruneOldEntries();
    });
  }

  Future<void> _pruneOldEntries() async {
    final cutoff = _dateFormat.format(
      DateTime.now().subtract(const Duration(days: keepDays)),
    );

    final staleKeys = _rates.keys.where((key) {
      final date = key.toString().split('_').first;
      return date.compareTo(cutoff) < 0;
    }).toList();

    if (staleKeys.isNotEmpty) {
      await _rates.deleteAll(staleKeys);
    }
  }

  static String _key(String date, String currency) => '${date}_$currency';

  Future<Result<T>> _guard<T>(FutureOr<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(
        CacheFailure(message: 'Local rates storage failed', cause: error),
      );
    }
  }
}
