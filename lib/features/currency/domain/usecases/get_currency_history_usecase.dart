import '../../../../core/errors/result.dart';
import '../entities/history_point.dart';
import '../repositories/currency_history_repository.dart';

class GetCurrencyHistoryUseCase {
  const GetCurrencyHistoryUseCase(this._repository);

  final CurrencyHistoryRepository _repository;

  Stream<Result<List<HistoryPoint>>> call({
    required String code,
    int days = 7,
    bool forceRefresh = false,
    DateTime? anchorDate,
  }) {
    return _repository.getHistory(
      code: code,
      days: days,
      forceRefresh: forceRefresh,
      anchorDate: anchorDate,
    );
  }
}
