import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:currency_exchange_tracker/core/theme/app_colors.dart';

/// A single day/value pair for the 7-day currency line chart.
class CurrencyChartPoint {
  const CurrencyChartPoint({required this.value, this.dayLabel});

  final double value;

  /// Optional override. When omitted, [SevenDayCurrencyChart] uses weekday labels.
  final String? dayLabel;
}

/// Seven-day currency line chart styled to match the details screen design.
class SevenDayCurrencyChart extends StatelessWidget {
  const SevenDayCurrencyChart({
    super.key,
    required this.points,
    this.currencySymbol = '',
    this.useDayNumbers = false,
  }) : assert(points.length >= 2, 'Chart requires at least 2 daily points.');

  final List<CurrencyChartPoint> points;
  final String currencySymbol;

  /// When true, labels read `Day 1` … `Day 7` instead of `Mon` … `Sun`.
  final bool useDayNumbers;

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final captionStyle = Theme.of(context).textTheme.bodySmall;
    final values = points.map((point) => point.value).toList();
    final minY = _floorToStep(
      values.reduce((a, b) => a < b ? a : b) - 0.2,
      0.4,
    );
    final maxY = _ceilToStep(values.reduce((a, b) => a > b ? a : b) + 0.2, 0.4);
    final horizontalInterval = (maxY - minY) / 3;
    final yAxisLabels = List<double>.generate(
      4,
      (index) => minY + (horizontalInterval * index),
    );

    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: horizontalInterval,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: horizontalInterval,
                getTitlesWidget: (value, meta) {
                  if (!_isNearAny(value, yAxisLabels)) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      _formatAxisValue(value),
                      style: captionStyle,
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (!_isWholeDayIndex(value) || index >= points.length) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(_labelForIndex(index), style: captionStyle),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.round().clamp(0, points.length - 1);
                  final label = _labelForIndex(index);

                  return LineTooltipItem(
                    '$label\n${_formatTooltipValue(spot.y)}',
                    captionStyle!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: true,
              curveSmoothness: 0.22,
              color: AppColors.primary500,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => spot.x == points.length - 1,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.primary500,
                      strokeWidth: 2,
                      strokeColor: AppColors.surface,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.22),
                    AppColors.primary500.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForIndex(int index) {
    final override = points[index].dayLabel;
    if (override != null && override.isNotEmpty) {
      return override;
    }

    if (useDayNumbers) {
      return 'Day ${index + 1}';
    }

    if (index >= 0 && index < _weekdayLabels.length) {
      return _weekdayLabels[index];
    }

    return 'Day ${index + 1}';
  }

  bool _isWholeDayIndex(double value) {
    final lastIndex = points.length - 1;
    return value >= 0 &&
        value <= lastIndex &&
        (value - value.round()).abs() < 0.001;
  }

  bool _isNearAny(double value, List<double> targets) {
    return targets.any((target) => (value - target).abs() < 0.05);
  }

  String _formatAxisValue(double value) {
    if (currencySymbol.isEmpty) {
      return value.toStringAsFixed(2);
    }

    return NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: value >= 100 ? 0 : 2,
    ).format(value);
  }

  String _formatTooltipValue(double value) {
    if (currencySymbol.isEmpty) {
      return value.toStringAsFixed(2);
    }

    return NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    ).format(value);
  }

  double _floorToStep(double value, double step) {
    return (value / step).floor() * step;
  }

  double _ceilToStep(double value, double step) {
    return (value / step).ceil() * step;
  }
}
