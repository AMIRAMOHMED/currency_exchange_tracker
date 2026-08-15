import 'package:flutter/material.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';

class CurrencyStatRow {
  const CurrencyStatRow({required this.label, required this.value});

  final String label;
  final String value;
}

class CurrencyStatsCard extends StatelessWidget {
  const CurrencyStatsCard({super.key, required this.rows});

  final List<CurrencyStatRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: AppColors.surfaceCard,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _StatRow(label: rows[i].label, value: rows[i].value),
            if (i != rows.length - 1) const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}
