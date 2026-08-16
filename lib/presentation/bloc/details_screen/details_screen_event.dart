import 'package:equatable/equatable.dart';

import '../../../features/currency/domain/entities/currency.dart';

sealed class DetailsScreenEvent extends Equatable {
  const DetailsScreenEvent();

  @override
  List<Object?> get props => [];
}

final class LoadDetails extends DetailsScreenEvent {
  const LoadDetails(this.currency);

  final Currency currency;

  @override
  List<Object?> get props => [currency];
}

final class RefreshDetailsData extends DetailsScreenEvent {
  const RefreshDetailsData(this.currency);

  final Currency currency;

  @override
  List<Object?> get props => [currency];
}
