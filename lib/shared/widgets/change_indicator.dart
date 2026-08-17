import 'package:flutter/material.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';

class ChangeIndicator extends StatelessWidget {
  const ChangeIndicator({
    super.key,
    required this.rate,
    required this.dailyRateChange,
  });

  final double rate;
  final double? dailyRateChange;

  static Color colorFor(double? dailyRateChange) {
    if (dailyRateChange == null) {
      return AppColors.textSecondary; // no yesterday data
    }
    if (dailyRateChange == 0) return AppColors.primary500; // flat rate
    return dailyRateChange < 0 ? AppColors.positive : AppColors.negative;
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final change = dailyRateChange;

    if (change == null) return Text('—', style: style);

    final previousRate = rate - change;
    final percent = previousRate == 0 ? null : change / previousRate * 100;
    final color = colorFor(change);
    final label = percent != null
        ? '${change.abs().toStringAsFixed(2)} (${percent.abs().toStringAsFixed(2)}%)'
        : change.abs().toStringAsFixed(2);
    final icon = change == 0
        ? null
        : (change > 0 ? Icons.arrow_upward : Icons.arrow_downward);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(label, style: style?.copyWith(color: color)),
      ],
    );
  }
}
