import 'package:flutter/material.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';

/// Widget to display currency change with arrow indicator
class ChangeIndicator extends StatelessWidget {
  final double changeValue;
  final double changePercentage;

  const ChangeIndicator({
    super.key,
    required this.changeValue,
    required this.changePercentage,
  });

  bool get isUnchanged => changeValue == 0;

  bool get isPositive => changeValue > 0;

  Color get color {
    if (isUnchanged) return AppColors.primary500;
    return isPositive ? AppColors.positive : AppColors.negative;
  }

  IconData? get icon {
    if (isUnchanged) return null;
    return isPositive ? Icons.arrow_upward : Icons.arrow_downward;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final arrow = icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (arrow != null) ...[
          Icon(arrow, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          '${changeValue.abs().toStringAsFixed(2)} (${changePercentage.abs().toStringAsFixed(2)}%)',
          style: textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
