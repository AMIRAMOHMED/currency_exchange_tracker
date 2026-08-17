import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../../features/currency/domain/entities/currency_rate.dart';
import '../../../features/currency/domain/entities/history_point.dart';
import '../../../features/currency/domain/usecases/get_currency_history_usecase.dart';
import 'details_screen_event.dart';
import 'details_screen_state.dart';

export 'details_screen_event.dart';
export 'details_screen_state.dart';

class DetailsScreenBloc extends Bloc<DetailsScreenEvent, DetailsState> {
  DetailsScreenBloc(this._getHistory) : super(const DetailsLoading()) {
    on<LoadDetails>(_onLoad);
    on<RefreshDetailsData>(_onRefresh);
  }

  static const _chartDays = 7;

  final GetCurrencyHistoryUseCase _getHistory;

  Future<void> _onLoad(LoadDetails event, Emitter<DetailsState> emit) async {
    emit(const DetailsLoading());
    await emit.forEach<Result<List<HistoryPoint>>>(
      _getHistory(code: event.currency.code, anchorDate: event.currency.date),
      onData: (result) => _mapLoadResult(result, event.currency),
      onError: (error, stackTrace) => const DetailsError(UnknownFailure()),
    );

    final current = state;
    if (current is DetailsSuccess && current.isChartLoading) {
      emit(current.copyWith(isChartLoading: false));
    }
  }

  Future<void> _onRefresh(
    RefreshDetailsData event,
    Emitter<DetailsState> emit,
  ) async {
    final current = state;
    if (current is! DetailsSuccess) return;

    emit(current.copyWith(isRefreshing: true));

    await emit.forEach<Result<List<HistoryPoint>>>(
      _getHistory(
        code: event.currency.code,
        anchorDate: event.currency.date,
        forceRefresh: true,
      ),
      onData: (result) => _mapRefreshResult(result, event.currency, current),
      onError: (error, stackTrace) => current.copyWith(isRefreshing: false),
    );

    // If the internet data was identical to cache, the stream ends without yielding.
    // We must manually turn off the spinner here.
    if (state is DetailsSuccess && (state as DetailsSuccess).isRefreshing) {
      emit((state as DetailsSuccess).copyWith(isRefreshing: false));
    }
  }

  DetailsState _mapLoadResult(
    Result<List<HistoryPoint>> result,
    CurrencyRate currency,
  ) {
    return switch (result) {
      Success(:final value) => DetailsSuccess(
        currency: currency,
        history: value,
        isChartLoading: value.length < _chartDays,
      ),
      Failure(:final error) => DetailsError(error),
    };
  }

  DetailsState _mapRefreshResult(
    Result<List<HistoryPoint>> result,
    CurrencyRate currency,
    DetailsSuccess previous,
  ) {
    switch (result) {
      case Success(:final value) when value.length >= 2:
        return DetailsSuccess(currency: currency, history: value);
      case Success():
        return previous.copyWith(isRefreshing: false);
      case Failure():
        return previous.copyWith(isRefreshing: false);
    }
  }
}
