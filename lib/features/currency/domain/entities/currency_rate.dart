import 'package:equatable/equatable.dart';

import '../supported_currency.dart';

class CurrencyRate extends Equatable {
  const CurrencyRate({
    required this.code,
    required this.name,
    required this.rate,
    required this.date,
    this.change,
  });

  final String code;
  final String name;

  final double rate;

  final double? change;

  final DateTime date;

  String get flagAsset =>
      SupportedCurrency.fromCode(code)?.flagAsset ?? 'assets/flags/xx.png';

  @override
  List<Object?> get props => [code, name, rate, change, date];
}
