import '../../../../core/errors/result.dart';
import '../entities/currency_rate.dart';

abstract interface class CurrencyRepository {
  /// Load: cache first, then network. Pull: network only.
  Stream<Result<List<CurrencyRate>>> getHomeRates({bool forceRefresh = false});
}
