import '../../../../core/errors/result.dart';
import '../entities/currency_rate.dart';
import '../repositories/currency_repository.dart';

class GetCurrenciesUseCase {
  const GetCurrenciesUseCase(this._repository);

  final CurrencyRepository _repository;

  Stream<Result<List<CurrencyRate>>> call({bool forceRefresh = false}) =>
      _repository.getHomeRates(forceRefresh: forceRefresh);
}
