import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:currency_exchange_tracker/core/di/injection.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/history_point.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_currency_history_usecase.dart';
import 'package:currency_exchange_tracker/presentation/bloc/details_screen/details_screen_bloc.dart';
import 'package:currency_exchange_tracker/presentation/widgets/details/currency_detail_header.dart';
import 'package:currency_exchange_tracker/shared/widgets/stale_data_notice.dart';
import 'package:currency_exchange_tracker/presentation/widgets/seven_day_currency_chart.dart';
import 'package:currency_exchange_tracker/shared/widgets/empty_view.dart';
import 'package:currency_exchange_tracker/shared/widgets/error_view.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.currency});

  final CurrencyRate currency;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DetailsScreenBloc(sl<GetCurrencyHistoryUseCase>())
            ..add(LoadDetails(currency)),
      child: _DetailsView(currency: currency),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.currency});

  final CurrencyRate currency;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 0, scrolledUnderElevation: 0),
      body: BlocBuilder<DetailsScreenBloc, DetailsState>(
        buildWhen: (previous, current) {
          if (previous.runtimeType != current.runtimeType) return true;
          if (previous is DetailsSuccess && current is DetailsSuccess) {
            return !listEquals(previous.history, current.history) ||
                previous.isChartLoading != current.isChartLoading;
          }
          return true;
        },
        builder: (context, state) {
          if (state is DetailsLoading) {
            return _LoadingBody(currency: currency);
          }

          if (state is DetailsSuccess) {
            if (state.history.length < 2) {
              return _Status(
                child: const EmptyView(
                  subtitle: 'No chart data is available for this currency.',
                ),
              );
            }

            return _DetailsBody(
              currency: state.currency,
              history: state.history,
              isChartLoading: state.isChartLoading,
            );
          }

          if (state is DetailsError) {
            return _Status(
              child: ErrorView(
                error: state.error,
                onRetry: () => context.read<DetailsScreenBloc>().add(
                  LoadDetails(currency),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.currency});

  final CurrencyRate currency;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        CurrencyDetailHeader(
          flagAsset: currency.flagAsset,
          currencyName: currency.name,
          currencyCode: currency.code,
          rate: currency.rate,
          baseCurrency: 'EGP',
          change: currency.change,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Past 7 Days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Skeletonizer.zone(
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Bone.square(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.currency,
    required this.history,
    required this.isChartLoading,
  });

  final CurrencyRate currency;
  final List<HistoryPoint> history;
  final bool isChartLoading;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<DetailsScreenBloc>();
    bloc.add(RefreshDetailsData(currency));
    await bloc.stream.firstWhere(
      (s) => s is! DetailsSuccess || !s.isRefreshing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: const ValueKey('details_refresh'),
      color: AppColors.primary500,
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          CurrencyDetailHeader(
            flagAsset: currency.flagAsset,
            currencyName: currency.name,
            currencyCode: currency.code,
            rate: currency.rate,
            baseCurrency: 'EGP',
            change: currency.change,
          ),
          if (StaleDataNotice.shouldShow(currency.date)) ...[
            const SizedBox(height: AppSpacing.lg),
            StaleDataNotice(
              date: currency.date,
              onRefresh: () => _refresh(context),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Past 7 Days', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (isChartLoading)
            Skeletonizer.zone(
              child: AspectRatio(
                aspectRatio: 1.6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Bone.square(),
                ),
              ),
            )
          else
            SevenDayCurrencyChart(
              points: [
                for (final point in history)
                  CurrencyChartPoint(
                    value: point.rate,
                    dayLabel: DateFormat('E').format(point.date),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
