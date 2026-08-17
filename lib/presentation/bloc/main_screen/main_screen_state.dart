import 'package:equatable/equatable.dart';

import '../../../core/errors/app_failure.dart';
import '../../../features/currency/domain/entities/currency_rate.dart';

sealed class MainState extends Equatable {
  const MainState();

  @override
  List<Object?> get props => [];
}

final class MainLoading extends MainState {
  const MainLoading();
}

final class MainSuccess extends MainState {
  const MainSuccess(this.currencies, {this.isRefreshing = false});

  final List<CurrencyRate> currencies;
  final bool isRefreshing;

  MainSuccess copyWith({
    List<CurrencyRate>? currencies,
    bool? isRefreshing,
  }) {
    return MainSuccess(
      currencies ?? this.currencies,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [currencies, isRefreshing];
}

final class MainError extends MainState {
  const MainError(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}
