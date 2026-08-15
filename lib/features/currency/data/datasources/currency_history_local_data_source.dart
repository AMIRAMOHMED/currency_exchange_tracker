import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../models/currency_history_model.dart';

/// `Success(null)` = empty. [CacheFailure] = Hive threw.
abstract interface class CurrencyHistoryLocalDataSource {
  Future<Result<CurrencyHistoryModel?>> read(String code);
  Future<Result<void>> write(CurrencyHistoryModel model);
}

class CurrencyHistoryLocalDataSourceImpl
    implements CurrencyHistoryLocalDataSource {
  const CurrencyHistoryLocalDataSourceImpl(this._history);

  static const String boxName = 'history';

  final Box<CurrencyHistoryModel> _history;

  @override
  Future<Result<CurrencyHistoryModel?>> read(String code) =>
      _try(() => _history.get(code), 'read history $code');

  @override
  Future<Result<void>> write(CurrencyHistoryModel model) =>
      _try(() => _history.put(model.code, model), 'write history ${model.code}');

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
