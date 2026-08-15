import 'package:flutter/material.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/shared/widgets/change_indicator.dart';
import 'package:currency_exchange_tracker/shared/widgets/currency_flag_avatar.dart';

/// Reusable currency card widget displaying currency information.
class CurrencyCard extends StatelessWidget {
  const CurrencyCard({
    super.key,
    required this.flagAsset,
    required this.currencyCode,
    required this.currencyName,
    required this.rate,
    required this.baseCurrency,
    required this.changeValue,
    required this.changePercentage,
    this.onTap,
  });

  final String flagAsset;
  final String currencyCode;
  final String currencyName;
  final double rate;
  final String baseCurrency;
  final double changeValue;
  final double changePercentage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppColors.surfaceCard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CurrencyFlagAvatar(flagAsset: flagAsset),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currencyCode, style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        currencyName,
                        style: textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rate.toStringAsFixed(2),
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(baseCurrency, style: textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ChangeIndicator(
                      changeValue: changeValue,
                      changePercentage: changePercentage,
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
