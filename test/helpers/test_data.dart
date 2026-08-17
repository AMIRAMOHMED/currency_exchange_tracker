import 'package:currency_exchange_tracker/features/currency/data/models/exchange_rate_model.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/history_point.dart';
import 'package:currency_exchange_tracker/features/currency/domain/supported_currency.dart';
import 'package:intl/intl.dart';

final dateFormat = DateFormat('yyyy-MM-dd');

String todayString([DateTime? reference]) =>
    dateFormat.format(reference ?? DateTime.now());

String yesterdayString([DateTime? reference]) => dateFormat.format(
  (reference ?? DateTime.now()).subtract(const Duration(days: 1)),
);

List<String> dateRangeFromAnchor(String anchor, int days) {
  final start = DateTime.parse(anchor);
  return List.generate(
    days,
    (index) => dateFormat.format(start.subtract(Duration(days: index))),
  );
}

CurrencyRate sampleCurrency({
  String code = 'USD',
  String name = 'US Dollar',
  double rate = 50.0,
  double? change = 1.0,
  DateTime? date,
}) {
  return CurrencyRate(
    code: code,
    name: name,
    rate: rate,
    change: change,
    date: date ?? DateTime.parse(todayString()),
  );
}

List<CurrencyRate> sampleCurrencies() {
  return SupportedCurrency.values
      .map(
        (currency) => CurrencyRate(
          code: currency.code,
          name: currency.name,
          rate: 10.0 + currency.index,
          change: 0.5,
          date: DateTime.parse(todayString()),
        ),
      )
      .toList();
}

HistoryPoint sampleHistoryPoint({required String date, double rate = 50.0}) {
  return HistoryPoint(date: DateTime.parse(date), rate: rate);
}

List<HistoryPoint> sampleHistoryPoints(
  int count, {
  String anchor = '2026-08-17',
}) {
  final dates = dateRangeFromAnchor(anchor, count);
  return dates
      .map((date) => HistoryPoint(date: DateTime.parse(date), rate: 50.0))
      .toList();
}

ExchangeRateModel exchangeRate({
  required String date,
  required String currency,
  required double rate,
}) {
  return ExchangeRateModel(
    date: date,
    currency: currency,
    rate: rate,
    updatedAt: 0,
  );
}

List<ExchangeRateModel> homeRateModels({
  String? today,
  String? yesterday,
  String currency = 'USD',
  double todayRate = 50.0,
  double yesterdayRate = 49.0,
}) {
  final todayDate = today ?? todayString();
  final yesterdayDate = yesterday ?? yesterdayString();
  return [
    exchangeRate(date: todayDate, currency: currency, rate: todayRate),
    exchangeRate(date: yesterdayDate, currency: currency, rate: yesterdayRate),
  ];
}

List<ExchangeRateModel> historyModels({
  required String currency,
  required List<String> dates,
  double rate = 50.0,
}) {
  return dates
      .map((date) => exchangeRate(date: date, currency: currency, rate: rate))
      .toList();
}
