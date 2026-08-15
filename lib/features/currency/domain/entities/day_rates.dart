import 'package:equatable/equatable.dart';

class DayRates extends Equatable {
  const DayRates({
    required this.date,
    required this.rates,
    required this.isCached,
  });

  final DateTime date;

  /// EGP per 1 unit, keyed by code (`USD` → 50.18).
  final Map<String, double> rates;
  final bool isCached;

  @override
  List<Object?> get props => [date, rates, isCached];
}
