import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';

class StaleDataNotice extends StatelessWidget {
  const StaleDataNotice({super.key, required this.date, this.checkedAt});

  final DateTime date;
  final DateTime? checkedAt;

  static bool shouldShow(DateTime date) {
    final now = DateTime.now();
    return date.year != now.year ||
        date.month != now.month ||
        date.day != now.day;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formattedDate = DateFormat.MMMd().format(date);
    final checkedLabel = checkedAt == null
        ? null
        : 'Checked at ${DateFormat.jm().format(checkedAt!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppColors.primaryTintBanner,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.primary500,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest available rates — $formattedDate',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primary500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  checkedLabel ?? "Today's rates aren't published yet",
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
