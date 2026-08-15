import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/presentation/bloc/connectivity/connectivity_bloc.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        final isOffline = state is ConnectivityOffline;

        return Material(
          color: AppColors.background,
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.bottomCenter,
                child: isOffline
                    ? const SafeArea(bottom: false, child: _OfflineBar())
                    : const SizedBox(width: double.infinity),
              ),
              Expanded(
                child: MediaQuery(
                  data: isOffline
                      ? mediaQuery.copyWith(
                          padding: mediaQuery.padding.copyWith(top: 0),
                        )
                      : mediaQuery,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary500,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.surface,
            size: 14,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'No internet connection',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
