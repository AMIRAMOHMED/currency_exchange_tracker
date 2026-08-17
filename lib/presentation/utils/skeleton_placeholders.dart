import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/domain/supported_currency.dart';

/// Number of skeleton currency items to display during loading.
final kSkeletonCurrencyCount = SupportedCurrency.values.length;

/// Generates fake currency data for skeleton loading state.
/// These placeholders allow the widget tree to render while Skeletonizer
/// converts it into shimmer bones.
List<CurrencyRate> get skeletonCurrencies => List.generate(
  kSkeletonCurrencyCount,
  (i) => CurrencyRate(
    code: '---',
    name: 'Loading currency name',
    rate: 12.34,
    date: DateTime.now(),
    change: 0.12,
  ),
);
