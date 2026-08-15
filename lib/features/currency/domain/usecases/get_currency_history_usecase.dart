import '../../../../core/errors/result.dart';
import '../entities/history_point.dart';
import '../repositories/currency_history_repository.dart';

class GetCurrencyHistoryUseCase {
  const GetCurrencyHistoryUseCase(this._repository);

  final CurrencyHistoryRepository _repository;

  Future<Result<List<HistoryPoint>>> call({
    required String code,
    required DateTime from,
  }) {
    return _repository.getHistory(code: code, from: from);
  }
}
