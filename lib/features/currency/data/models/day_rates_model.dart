import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../domain/currencies.dart';
import '../../domain/entities/day_rates.dart';

class DayRatesModel extends Equatable {
  const DayRatesModel({required this.date, required this.rates});

  /// `yyyy-MM-dd`, also the Hive key.
  final String date;
  final Map<String, double> rates;

  static final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  factory DayRatesModel.fromJson(Map<String, dynamic> json) {
    final date = json['date'];
    final egp = json['egp'];
    if (date is! String || egp is! Map || DateTime.tryParse(date) == null) {
      throw const FormatException('Unexpected currency API payload');
    }

    final rates = <String, double>{};
    for (final info in supportedCurrencies) {
      final inverted = _invert(egp[info.code.toLowerCase()]);
      if (inverted != null) rates[info.code] = inverted;
    }
    if (rates.isEmpty) {
      throw const FormatException('Payload contained no tracked currencies');
    }

    return DayRatesModel(date: date, rates: rates);
  }

  DayRates toEntity({required bool isCached}) => DayRates(
    date: DateTime.parse(date),
    rates: Map.unmodifiable(rates),
    isCached: isCached,
  );

  /// API is EGP → foreign (0.0199). UI wants foreign → EGP (50.18).
  static double? _invert(Object? value) {
    if (value is! num) return null;
    final rate = value.toDouble();
    if (rate == 0 || !rate.isFinite) return null;
    final inverted = 1 / rate;
    return inverted.isFinite ? inverted : null;
  }

  @override
  List<Object?> get props => [date, rates];
}
