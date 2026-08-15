import 'package:equatable/equatable.dart';

sealed class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

final class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

final class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}
