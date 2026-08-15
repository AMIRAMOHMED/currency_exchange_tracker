import 'package:equatable/equatable.dart';

sealed class AppFailure extends Equatable {
  const AppFailure({this.message, this.cause, this.statusCode});
  final String? message;

  final Object? cause;

  final int? statusCode;

  @override
  List<Object?> get props => [runtimeType, message, cause, statusCode];

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode, cause: $cause)';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.message, super.cause});
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({super.message, super.cause});
}

final class ServerFailure extends AppFailure {
  const ServerFailure({super.message, super.cause, super.statusCode});
}

final class CacheFailure extends AppFailure {
  const CacheFailure({super.message, super.cause});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({super.message, super.cause});
}
