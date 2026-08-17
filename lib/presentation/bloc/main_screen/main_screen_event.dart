import 'package:equatable/equatable.dart';

sealed class MainScreenEvent extends Equatable {
  const MainScreenEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load — emits [MainLoading] because there is no data yet.
final class LoadMain extends MainScreenEvent {
  const LoadMain();

  @override
  List<Object?> get props => [];
}

/// Pull-to-refresh — never emits [MainLoading]; keeps existing data visible.
final class RefreshMainData extends MainScreenEvent {
  const RefreshMainData();

  @override
  List<Object?> get props => [];
}
