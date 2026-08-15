import 'package:flutter/material.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/presentation/screens/details_screen.dart';
import 'package:currency_exchange_tracker/shared/widgets/currency_card.dart';
import 'package:currency_exchange_tracker/shared/widgets/summary_info_card.dart';

/// Main screen displaying currency rates.
class CurrencyRatesScreen extends StatelessWidget {
  const CurrencyRatesScreen({super.key});

  static const _currencies = [
    _CurrencyItem(
      flagAsset: 'assets/flags/usd.png',
      currencyCode: 'USD',
      currencyName: 'US Dollar',
      rate: 48.75,
      baseCurrency: 'EGP',
      changeValue: 0.35,
      changePercentage: 0.72,
    ),
    _CurrencyItem(
      flagAsset: 'assets/flags/eur.png',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      rate: 53.21,
      baseCurrency: 'EGP',
      changeValue: -0.18,
      changePercentage: -0.34,
    ),
    _CurrencyItem(
      flagAsset: 'assets/flags/gbp.png',
      currencyCode: 'GBP',
      currencyName: 'British Pound',
      rate: 62.15,
      baseCurrency: 'EGP',
      changeValue: 0.41,
      changePercentage: 0.66,
    ),
    _CurrencyItem(
      flagAsset: 'assets/flags/sar.png',
      currencyCode: 'SAR',
      currencyName: 'Saudi Riyal',
      rate: 13.00,
      baseCurrency: 'EGP',
      changeValue: 0.05,
      changePercentage: 0.39,
    ),
    _CurrencyItem(
      flagAsset: 'assets/flags/jpy.png',
      currencyCode: 'JPY',
      currencyName: 'Japanese Yen',
      rate: 0.32,
      baseCurrency: 'EGP',
      changeValue: 0.0,
      changePercentage: -0.21,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 0, scrolledUnderElevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _buildSubtitle(context),
            _buildSummaryCard(),
            _buildCurrencyList(context),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Currency Rates', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('Daily market snapshot', style: textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return const SummaryInfoCard(
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.primary500,
      title: '5 currencies',
      subtitle: 'Compared against EGP',
    );
  }

  Widget _buildCurrencyList(BuildContext context) {
    return Column(
      children: [
        for (final currency in _currencies)
          _buildCurrencyCard(context, currency),
      ],
    );
  }

  Widget _buildCurrencyCard(BuildContext context, _CurrencyItem currency) {
    return CurrencyCard(
      flagAsset: currency.flagAsset,
      currencyCode: currency.currencyCode,
      currencyName: currency.currencyName,
      rate: currency.rate,
      baseCurrency: currency.baseCurrency,
      changeValue: currency.changeValue,
      changePercentage: currency.changePercentage,
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const DetailsScreen()));
      },
    );
  }
}

class _CurrencyItem {
  const _CurrencyItem({
    required this.flagAsset,
    required this.currencyCode,
    required this.currencyName,
    required this.rate,
    required this.baseCurrency,
    required this.changeValue,
    required this.changePercentage,
  });

  final String flagAsset;
  final String currencyCode;
  final String currencyName;
  final double rate;
  final String baseCurrency;
  final double changeValue;
  final double changePercentage;
}
