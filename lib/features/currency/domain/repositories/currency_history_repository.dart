import '../../../../core/errors/result.dart';
import '../entities/history_point.dart';

abstract interface class CurrencyHistoryRepository {
  /// Load: cache first, then network. Pull: network only.
  Stream<Result<List<HistoryPoint>>> getHistory({
    required String code,
    int days = 7,
    bool forceRefresh = false,
    DateTime? anchorDate,
  });
}
