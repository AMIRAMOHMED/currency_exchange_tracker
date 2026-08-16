import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:currency_exchange_tracker/core/di/injection.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/history_point.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_currency_history_usecase.dart';
import 'package:currency_exchange_tracker/presentation/bloc/details_screen/details_screen_bloc.dart';
import 'package:currency_exchange_tracker/presentation/utils/currency_presentation.dart';
import 'package:currency_exchange_tracker/presentation/widgets/details/chart_week_section_header.dart';
import 'package:currency_exchange_tracker/presentation/widgets/details/currency_detail_header.dart';
import 'package:currency_exchange_tracker/presentation/widgets/details/offline_status_banner.dart';
import 'package:currency_exchange_tracker/presentation/widgets/seven_day_currency_chart.dart';
import 'package:currency_exchange_tracker/shared/widgets/empty_view.dart';
import 'package:currency_exchange_tracker/shared/widgets/error_view.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.currency});

  final Currency currency;

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

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 0, scrolledUnderElevation: 0),
      body: BlocBuilder<DetailsScreenBloc, DetailsState>(
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

  final Currency currency;

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
          changeValue: currency.changeValue,
          changePercentage: currency.changePercentage,
        ),
        const SizedBox(height: AppSpacing.lg),
        const ChartWeekSectionHeader(title: 'Past 7 Days'),
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
  const _DetailsBody({required this.currency, required this.history});

  final Currency currency;
  final List<HistoryPoint> history;

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
            changeValue: currency.changeValue,
            changePercentage: currency.changePercentage,
          ),
          if (currency.isCached) ...[
            const SizedBox(height: AppSpacing.lg),
            OfflineStatusBanner(
              lastUpdatedLabel:
                  'Last updated\n${DateFormat.MMMd().format(currency.date)}',
              onRefresh: () => context.read<DetailsScreenBloc>().add(
                RefreshDetailsData(currency),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const ChartWeekSectionHeader(title: 'Past 7 Days'),
          const SizedBox(height: AppSpacing.md),
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
