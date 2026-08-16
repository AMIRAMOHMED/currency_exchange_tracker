import 'package:equatable/equatable.dart';

sealed class MainScreenEvent extends Equatable {
  const MainScreenEvent();

  @override
  List<Object?> get props => [];
}

final class LoadMain extends MainScreenEvent {
  const LoadMain();

  @override
  List<Object?> get props => [];
}

final class RefreshMainData extends MainScreenEvent {
  const RefreshMainData();

  @override
  List<Object?> get props => [];
}
