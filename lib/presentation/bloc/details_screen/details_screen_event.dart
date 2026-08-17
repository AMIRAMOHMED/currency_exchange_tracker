import 'package:equatable/equatable.dart';

import '../../../features/currency/domain/entities/currency_rate.dart';

sealed class DetailsScreenEvent extends Equatable {
  const DetailsScreenEvent();

  @override
  List<Object?> get props => [];
}

final class LoadDetails extends DetailsScreenEvent {
  const LoadDetails(this.currency);

  final CurrencyRate currency;

  @override
  List<Object?> get props => [currency];
}

final class RefreshDetailsData extends DetailsScreenEvent {
  const RefreshDetailsData(this.currency);

  final CurrencyRate currency;

  @override
  List<Object?> get props => [currency];
}
