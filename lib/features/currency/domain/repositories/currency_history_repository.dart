import '../../../../core/errors/result.dart';
import '../entities/history_point.dart';

abstract interface class CurrencyHistoryRepository {
  Future<Result<List<HistoryPoint>>> getHistory({
    required String code,
    required DateTime from,
  });
}
