import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:currency_exchange_tracker/core/di/injection.dart';
import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_currencies_usecase.dart';
import 'package:currency_exchange_tracker/presentation/bloc/main_screen/main_screen_bloc.dart';
import 'package:currency_exchange_tracker/presentation/screens/details_screen.dart';
import 'package:currency_exchange_tracker/presentation/utils/currency_presentation.dart';
import 'package:currency_exchange_tracker/presentation/utils/skeleton_placeholders.dart';
import 'package:currency_exchange_tracker/shared/widgets/app_skeletonizer.dart';
import 'package:currency_exchange_tracker/shared/widgets/currency_card.dart';
import 'package:currency_exchange_tracker/shared/widgets/empty_view.dart';
import 'package:currency_exchange_tracker/shared/widgets/error_view.dart';
import 'package:currency_exchange_tracker/shared/widgets/summary_info_card.dart';

class CurrencyRatesScreen extends StatelessWidget {
  const CurrencyRatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MainScreenBloc(sl<GetCurrenciesUseCase>())..add(const LoadMain()),
      child: const _CurrencyRatesView(),
    );
  }
}

class _CurrencyRatesView extends StatelessWidget {
  const _CurrencyRatesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 0, scrolledUnderElevation: 0),
      body: BlocBuilder<MainScreenBloc, MainState>(
        builder: (context, state) {
          if (state is MainError) {
            return ErrorView(
              error: state.error,
              onRetry: () =>
                  context.read<MainScreenBloc>().add(const LoadMain()),
            );
          }

          if (state is MainSuccess && state.currencies.isEmpty) {
            return const EmptyView(
              subtitle: 'No currency rates are available right now.',
            );
          }

          final isLoading = state is MainLoading;
          final currencies = state is MainSuccess
              ? state.currencies
              : skeletonCurrencies;

          return AppSkeletonizer(
            enabled: isLoading,
            child: _RatesList(currencies: currencies),
          );
        },
      ),
    );
  }
}

class _RatesList extends StatelessWidget {
  const _RatesList({required this.currencies});

  final List<Currency> currencies;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<MainScreenBloc>();
    bloc.add(const RefreshMainData());
    await bloc.stream.firstWhere((s) => s is! MainSuccess || !s.isRefreshing);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      color: AppColors.primary500,
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Currency Rates', style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Daily market snapshot', style: textTheme.bodyMedium),
          SummaryInfoCard(
            icon: Icons.bar_chart_rounded,
            iconColor: AppColors.primary500,
            title:
                '${currencies.length} ${currencies.length == 1 ? 'currency' : 'currencies'}',
            subtitle: 'Compared against EGP',
          ),
          for (final currency in currencies)
            CurrencyCard(
              flagAsset: currency.flagAsset,
              currencyCode: currency.code,
              currencyName: currency.name,
              rate: currency.rate,
              baseCurrency: 'EGP',
              changeValue: currency.changeValue,
              changePercentage: currency.changePercentage,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DetailsScreen(currency: currency),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
