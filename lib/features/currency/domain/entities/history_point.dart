import 'package:equatable/equatable.dart';

class HistoryPoint extends Equatable {
  const HistoryPoint({required this.date, required this.rate});

  final DateTime date;
  final double rate;

  @override
  List<Object?> get props => [date, rate];
}
