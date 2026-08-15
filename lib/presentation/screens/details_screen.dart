import 'package:flutter/material.dart';

import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/presentation/widgets/details/chart_week_section_header.dart';
import 'package:currency_exchange_tracker/presentation/widgets/details/currency_detail_header.dart';
import 'package:currency_exchange_tracker/presentation/widgets/details/offline_status_banner.dart';
import 'package:currency_exchange_tracker/presentation/widgets/seven_day_currency_chart.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  static const _mockChartPoints = [
    CurrencyChartPoint(value: 48.20),
    CurrencyChartPoint(value: 48.35),
    CurrencyChartPoint(value: 48.55),
    CurrencyChartPoint(value: 48.40),
    CurrencyChartPoint(value: 48.62),
    CurrencyChartPoint(value: 48.48),
    CurrencyChartPoint(value: 48.75),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 0, scrolledUnderElevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CurrencyDetailHeader(
              flagAsset: 'assets/flags/usd.png',
              currencyName: 'US Dollar',
              currencyCode: 'USD',
              rate: 48.75,
              baseCurrency: 'EGP',
              changeValue: 0.35,
              changePercentage: 0.72,
            ),
            const SizedBox(height: AppSpacing.lg),
            const OfflineStatusBanner(
              lastUpdatedLabel: 'Last updated\nToday - 10:42 AM',
            ),
            const SizedBox(height: AppSpacing.lg),
            const ChartWeekSectionHeader(title: 'Past 7 Days'),
            const SizedBox(height: AppSpacing.md),
            SevenDayCurrencyChart(points: _mockChartPoints),
          ],
        ),
      ),
    );
  }
}
