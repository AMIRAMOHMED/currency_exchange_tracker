sealed class ConnectivityEvent {
  const ConnectivityEvent();
}

final class ConnectivityStarted extends ConnectivityEvent {
  const ConnectivityStarted();
}

final class ConnectivityRefreshed extends ConnectivityEvent {
  const ConnectivityRefreshed();
}
