import '../../../../core/errors/result.dart';
import '../currencies.dart';
import '../entities/currency.dart';
import '../entities/day_rates.dart';
import '../repositories/currency_repository.dart';

/// Home list: 2 calls (today + yesterday), then daily change for each pair.
class GetCurrenciesUseCase {
  const GetCurrenciesUseCase(this._repository);

  final CurrencyRepository _repository;

  Future<Result<List<Currency>>> call() async {
    final latest = await _repository.getLatest();
    if (latest is Failure<DayRates>) return Failure(latest.error);

    final today = (latest as Success<DayRates>).value;
    final yesterday = await _yesterdayOf(today.date);
    return Success(_rows(today, yesterday));
  }

  Future<DayRates?> _yesterdayOf(DateTime today) async {
    final date = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 1));
    final result = await _repository.getByDate(date);
    return result is Success<DayRates> ? result.value : null;
  }

  List<Currency> _rows(DayRates today, DayRates? yesterday) {
    final list = <Currency>[];
    for (final info in supportedCurrencies) {
      final rate = today.rates[info.code];
      if (rate == null) continue;

      final yesterdayRate = yesterday?.rates[info.code];
      double? change;
      double? percent;
      if (yesterdayRate != null && yesterdayRate != 0) {
        change = rate - yesterdayRate;
        percent = change / yesterdayRate * 100;
      }

      list.add(
        Currency(
          code: info.code,
          name: info.name,
          rate: rate,
          change: change,
          changePercent: percent,
          date: today.date,
          isCached: today.isCached,
        ),
      );
    }
    return list;
  }
}
