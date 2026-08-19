import 'package:currency_exchange_tracker/core/errors/result.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_local_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/models/exchange_rate_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../../../../helpers/test_data.dart';

class _FakeRatesBox extends Fake implements Box<ExchangeRateModel> {
  _FakeRatesBox(this._items);

  final List<ExchangeRateModel> _items;

  @override
  Iterable<ExchangeRateModel> get values => _items;
}

void main() {
  group('CurrencyLocalDataSourceImpl.readLatestForCurrencies', () {
    test(
      'regression: returns two newest rows even when they lag device today',
      () async {
        final now = DateTime.now();
        final latest = todayString(now.subtract(const Duration(days: 2)));
        final previous = todayString(now.subtract(const Duration(days: 3)));
        final older = todayString(now.subtract(const Duration(days: 10)));

        final source = CurrencyLocalDataSourceImpl(
          _FakeRatesBox([
            exchangeRate(date: older, currency: 'USD', rate: 40),
            exchangeRate(date: previous, currency: 'USD', rate: 49),
            exchangeRate(date: latest, currency: 'USD', rate: 50),
            exchangeRate(date: latest, currency: 'EUR', rate: 55),
            exchangeRate(date: previous, currency: 'EUR', rate: 54),
          ]),
        );

        final result = await source.readLatestForCurrencies(['USD', 'EUR']);
        final rows = (result as Success<List<ExchangeRateModel>>).value;

        expect(
          rows.map((row) => '${row.date}_${row.currency}'),
          unorderedEquals([
            '${latest}_USD',
            '${previous}_USD',
            '${latest}_EUR',
            '${previous}_EUR',
          ]),
        );
        expect(rows.any((row) => row.date == older), isFalse);
      },
    );
  });
}
