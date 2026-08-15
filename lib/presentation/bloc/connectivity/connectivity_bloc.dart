import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/connectivity_service.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

export 'connectivity_event.dart';
export 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc(ConnectivityService service)
      : _service = service,
        super(_stateOf(service.isOnline)) {
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityRefreshed>(_onRefreshed);

    _lifecycle = AppLifecycleListener(
      onResume: () => add(const ConnectivityRefreshed()),
    );
  }

  final ConnectivityService _service;
  late final AppLifecycleListener _lifecycle;

  Future<void> _onStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    await emit.forEach<bool>(
      _service.onStatusChanged,
      onData: (isOnline) => _stateOf(isOnline),
    );
  }

  void _onRefreshed(ConnectivityRefreshed event, Emitter<ConnectivityState> emit) {
    _service.refresh();
  }

  @override
  Future<void> close() {
    _lifecycle.dispose();
    return super.close();
  }

  static ConnectivityState _stateOf(bool isOnline) =>
      isOnline ? const ConnectivityOnline() : const ConnectivityOffline();
}
