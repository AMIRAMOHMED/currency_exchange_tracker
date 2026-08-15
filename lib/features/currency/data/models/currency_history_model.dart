import 'package:equatable/equatable.dart';

import '../../domain/entities/history_point.dart';
import 'day_rates_model.dart';

class CurrencyHistoryModel extends Equatable {
  const CurrencyHistoryModel({required this.code, required this.points});

  /// Hive key (`USD`).
  final String code;

  /// `yyyy-MM-dd` → EGP per 1 unit.
  final Map<String, double> points;

  List<HistoryPoint> toEntities() {
    final list = [
      for (final entry in points.entries)
        HistoryPoint(date: DateTime.parse(entry.key), rate: entry.value),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  factory CurrencyHistoryModel.fromPoints({
    required String code,
    required List<HistoryPoint> points,
  }) => CurrencyHistoryModel(
    code: code,
    points: {
      for (final point in points)
        DayRatesModel.dateFormat.format(point.date): point.rate,
    },
  );

  @override
  List<Object?> get props => [code, points];
}
