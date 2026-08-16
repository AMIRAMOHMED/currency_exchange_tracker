import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';

extension CurrencyPresentation on Currency {
  String get flagAsset => 'assets/flags/${code.toLowerCase()}.png';

  double get changeValue => change ?? 0;

  double get changePercentage => changePercent ?? 0;
}
