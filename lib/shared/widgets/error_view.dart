import 'package:flutter/material.dart';

import 'package:currency_exchange_tracker/core/errors/app_failure.dart';
import 'package:currency_exchange_tracker/core/errors/error_message_mapper.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  factory ErrorView.network({
    required AppFailure error,
    required VoidCallback onRetry,
  }) {
    return ErrorView(error: error, onRetry: onRetry);
  }

  final AppFailure error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isNetworkError = error is NetworkFailure;
    //todo:why we made that on error layer that issue if intrent that pass already no ontrernat connection
    final title = isNetworkError
        ? 'No Internet Connection'
        : 'Something went wrong';

    final icon = isNetworkError
        ? Icons.wifi_off_rounded
        : Icons.error_outline_rounded;

    final iconColor = isNetworkError
        ? AppColors.primary500
        : AppColors.negative;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.userMessage,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
