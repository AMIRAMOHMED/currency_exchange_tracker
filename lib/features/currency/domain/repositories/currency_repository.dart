import '../../../../core/errors/result.dart';
import '../entities/day_rates.dart';

abstract interface class CurrencyRepository {
  Future<Result<DayRates>> getLatest();

  Future<Result<DayRates>> getByDate(DateTime date);
}
