import 'package:equatable/equatable.dart';

class Currency extends Equatable {
  const Currency({
    required this.code,
    required this.name,
    required this.rate,
    required this.date,
    required this.isCached,
    this.change,
    this.changePercent,
  });

  final String code;
  final String name;

  /// EGP per 1 [code].
  final double rate;

  /// Today − yesterday. Null if yesterday is missing.
  final double? change;
  final double? changePercent;

  final DateTime date;
  final bool isCached;

  /// Rate went down (EGP stronger). Ignore when [change] is null.
  bool get isEgpStronger => (change ?? 0) < 0;

  @override
  List<Object?> get props => [
    code,
    name,
    rate,
    change,
    changePercent,
    date,
    isCached,
  ];
}
