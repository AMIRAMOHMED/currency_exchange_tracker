import 'package:flutter/material.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/shared/widgets/change_indicator.dart';
import 'package:currency_exchange_tracker/shared/widgets/currency_flag_avatar.dart';

class CurrencyDetailHeader extends StatelessWidget {
  const CurrencyDetailHeader({
    super.key,
    required this.flagAsset,
    required this.currencyName,
    required this.currencyCode,
    required this.rate,
    required this.baseCurrency,
    required this.changeValue,
    required this.changePercentage,
    this.onBack,
  });

  final String flagAsset;
  final String currencyName;
  final String currencyCode;
  final double rate;
  final String baseCurrency;
  final double changeValue;
  final double changePercentage;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack ?? () => Navigator.maybePop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CurrencyFlagAvatar(flagAsset: flagAsset, radius: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                currencyName,
                style: textTheme.headlineMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                rate.toStringAsFixed(2),
                style: textTheme.displayLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                baseCurrency,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            ChangeIndicator(
              changeValue: changeValue,
              changePercentage: changePercentage,
            ),
            Text(
              ' today',
              style: textTheme.bodySmall?.copyWith(
                color: changeValue == 0
                    ? AppColors.primary500
                    : (changeValue > 0
                          ? AppColors.positive
                          : AppColors.negative),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
