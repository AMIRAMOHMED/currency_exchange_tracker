import 'package:equatable/equatable.dart';

import '../../../core/errors/app_failure.dart';
import '../../../features/currency/domain/entities/currency.dart';
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
    this.isRefreshing = false,
  });

  final Currency currency;
  final List<HistoryPoint> history;
  final bool isRefreshing;

  @override
  List<Object?> get props => [currency, history, isRefreshing];
}

final class DetailsError extends DetailsState {
  const DetailsError(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}
