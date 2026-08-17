import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';

class StaleDataNotice extends StatelessWidget {
  const StaleDataNotice({super.key, required this.date, this.onRefresh});

  final DateTime date;
  final VoidCallback? onRefresh;

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
                  'Rates from $formattedDate',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primary500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "These rates aren't from today",
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
