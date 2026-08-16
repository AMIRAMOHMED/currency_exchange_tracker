import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';

/// Number of skeleton currency items to display during loading.
const kSkeletonCurrencyCount = 6;

/// Generates fake currency data for skeleton loading state.
/// These placeholders allow the widget tree to render while Skeletonizer
/// converts it into shimmer bones.
List<Currency> get skeletonCurrencies => List.generate(
      kSkeletonCurrencyCount,
      (i) => Currency(
        code: '---',
        name: 'Loading currency name',
        rate: 12.34,
        date: DateTime.now(),
        isCached: false,
        change: 0.12,
        changePercent: 1.23,
      ),
    );
