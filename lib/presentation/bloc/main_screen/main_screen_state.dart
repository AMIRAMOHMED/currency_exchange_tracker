import 'package:equatable/equatable.dart';

import '../../../core/errors/app_failure.dart';
import '../../../features/currency/domain/entities/currency_rate.dart';
import '../../widgets/refresh_snack_listener.dart';

sealed class MainState extends Equatable with HasRefreshSnack {
  const MainState();

  DateTime? get lastCheckedAt => null;

  @override
  List<Object?> get props => [];
}

final class MainLoading extends MainState {
  const MainLoading();
}

final class MainSuccess extends MainState {
  const MainSuccess(
    this.currencies, {
    this.isRefreshing = false,
    this.lastCheckedAt,
    this.snack,
  });

  final List<CurrencyRate> currencies;
  final bool isRefreshing;

  @override
  final DateTime? lastCheckedAt;

  @override
  final RefreshSnack? snack;

  MainSuccess copyWith({
    List<CurrencyRate>? currencies,
    bool? isRefreshing,
    DateTime? lastCheckedAt,
    RefreshSnack? snack,
  }) {
    return MainSuccess(
      currencies ?? this.currencies,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      snack: snack ?? this.snack,
    );
  }

  @override
  List<Object?> get props => [currencies, isRefreshing, lastCheckedAt, snack];
}

final class MainError extends MainState {
  const MainError(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}
