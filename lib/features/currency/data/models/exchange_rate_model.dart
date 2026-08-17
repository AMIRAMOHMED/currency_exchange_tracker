import 'package:hive_ce/hive.dart';

@HiveType(typeId: 3)
class ExchangeRateModel extends HiveObject {
  ExchangeRateModel({
    required this.date,
    required this.currency,
    required this.rate,
    required this.updatedAt,
  });

  @HiveField(0)
  final String date;

  @HiveField(1)
  final String currency;

  @HiveField(2)
  final double rate;

  @HiveField(3)
  final int updatedAt;

  static List<ExchangeRateModel> fromApiResponses(
    List<Map<String, dynamic>> responses,
    List<String> targetCurrencies,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final results = <ExchangeRateModel>[];
    final targets = targetCurrencies.map((code) => code.toUpperCase()).toSet();

    for (final response in responses) {
      final date = response['date'];
      final egp = response['egp'];
      if (date is! String || egp is! Map) continue;

      for (final code in targets) {
        final inverted = _invert(egp[code.toLowerCase()]);
        if (inverted == null) continue;

        results.add(
          ExchangeRateModel(
            date: date,
            currency: code,
            rate: inverted,
            updatedAt: now,
          ),
        );
      }
    }

    return results;
  }

  /// API is EGP → foreign (0.0199). UI wants foreign → EGP (50.18).
  static double? _invert(Object? value) {
    if (value is! num) return null;
    final rate = value.toDouble();
    if (rate == 0 || !rate.isFinite) return null;
    final inverted = 1 / rate;
    return inverted.isFinite ? inverted : null;
  }
}
