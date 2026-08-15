import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  bool get isOnline;

  Stream<bool> get onStatusChanged;

  Future<void> refresh();

  Future<void> dispose();
}

class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl() : _connectivity = Connectivity();

  static const Duration _settleDelay = Duration(milliseconds: 600);

  final Connectivity _connectivity;
  final StreamController<bool> _status = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _settleTimer;
  bool _isOnline = true;

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onStatusChanged => _status.stream;

  Future<void> start() async {
    _isOnline = _readOnline(await _connectivity.checkConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  @override
  Future<void> refresh() async {
    _emit(_readOnline(await _connectivity.checkConnectivity()));
  }

  @override
  Future<void> dispose() async {
    _settleTimer?.cancel();
    await _subscription?.cancel();
    await _status.close();
  }

  void _onChanged(List<ConnectivityResult> results) {
    _settleTimer?.cancel();
    _settleTimer = Timer(_settleDelay, () => _emit(_readOnline(results)));
  }

  void _emit(bool online) {
    if (_isOnline == online) return;
    _isOnline = online;
    if (!_status.isClosed) _status.add(online);
  }

  static bool _readOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
