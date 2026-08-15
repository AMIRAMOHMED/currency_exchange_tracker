import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../models/day_rates_model.dart';

/// `Success(null)` = empty. [CacheFailure] = Hive threw.
abstract interface class CurrencyLocalDataSource {
  Future<Result<DayRatesModel?>> read(String date);
  Future<Result<DayRatesModel?>> readLatest();
  Future<Result<void>> write(DayRatesModel model);
}

class CurrencyLocalDataSourceImpl implements CurrencyLocalDataSource {
  const CurrencyLocalDataSourceImpl(this._rates);

  static const String boxName = 'rates';
  static const int _keepDays = 14;

  final Box<DayRatesModel> _rates;

  @override
  Future<Result<DayRatesModel?>> read(String date) =>
      _try(() => _rates.get(date), 'read $date');

  @override
  Future<Result<DayRatesModel?>> readLatest() => _try(() {
    final keys = _rates.keys.cast<String>().toList()..sort();
    return keys.isEmpty ? null : _rates.get(keys.last);
  }, 'read latest');

  @override
  Future<Result<void>> write(DayRatesModel model) => _try(() async {
    await _rates.put(model.date, model);
    final keys = _rates.keys.cast<String>().toList()..sort();
    if (keys.length > _keepDays) {
      await _rates.deleteAll(keys.take(keys.length - _keepDays));
    }
  }, 'write ${model.date}');

  Future<Result<T>> _try<T>(
    FutureOr<T> Function() action,
    String description,
  ) async {
    try {
      return Success<T>(await action());
    } catch (error) {
      return Failure<T>(
        CacheFailure(message: 'Failed to $description', cause: error),
      );
    }
  }
}
