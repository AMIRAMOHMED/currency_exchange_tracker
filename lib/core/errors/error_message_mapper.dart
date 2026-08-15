import 'app_failure.dart';

/// UI copy. Ignores [AppFailure.message] — that field is for logs only.
extension ErrorMessageMapper on AppFailure {
  String get userMessage => switch (this) {
    NetworkFailure() =>
      'No internet connection. Check your network and try again.',
    TimeoutFailure() =>
      'The request took too long to respond. Please try again.',
    ServerFailure(:final statusCode) => _serverMessage(statusCode),
    CacheFailure() =>
      'Could not read your saved rates. Please refresh to fetch them again.',
    UnknownFailure() => 'Something went wrong. Please try again.',
  };
}

String _serverMessage(int? statusCode) => switch (statusCode) {
  404 => 'No exchange rates are available for the selected date.',
  429 => 'Too many requests. Please wait a moment and try again.',
  final code? when code >= 500 =>
    'The rates service is temporarily unavailable. Please try again later.',
  _ => 'We could not load the exchange rates. Please try again.',
};
