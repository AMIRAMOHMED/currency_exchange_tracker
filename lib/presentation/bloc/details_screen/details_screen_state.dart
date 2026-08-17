import 'package:equatable/equatable.dart';

import '../../../core/errors/app_failure.dart';
import '../../../features/currency/domain/entities/currency_rate.dart';
import '../../../features/currency/domain/entities/history_point.dart';

sealed class DetailsState extends Equatable {
  const DetailsState();

  @override
  List<Object?> get props => [];
}

final class DetailsLoading extends DetailsState {
  const DetailsLoading();
}

final class DetailsSuccess extends DetailsState {
  const DetailsSuccess({
    required this.currency,
    required this.history,
    this.isChartLoading = false,
    this.isRefreshing = false,
  });

  final CurrencyRate currency;
  final List<HistoryPoint> history;
  final bool isChartLoading;
  final bool isRefreshing;

  DetailsSuccess copyWith({
    CurrencyRate? currency,
    List<HistoryPoint>? history,
    bool? isChartLoading,
    bool? isRefreshing,
  }) {
    return DetailsSuccess(
      currency: currency ?? this.currency,
      history: history ?? this.history,
      isChartLoading: isChartLoading ?? this.isChartLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [currency, history, isChartLoading, isRefreshing];
}

final class DetailsError extends DetailsState {
  const DetailsError(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}
