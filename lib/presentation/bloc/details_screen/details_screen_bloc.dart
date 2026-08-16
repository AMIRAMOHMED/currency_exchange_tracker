import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../../features/currency/domain/entities/currency.dart';
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

  final GetCurrencyHistoryUseCase _getHistory;

  Future<void> _onLoad(LoadDetails event, Emitter<DetailsState> emit) async {
    emit(const DetailsLoading());
    await _fetch(event.currency, emit);
  }

  Future<void> _onRefresh(
    RefreshDetailsData event,
    Emitter<DetailsState> emit,
  ) async {
    if (state is! DetailsSuccess) return;

    final previous = state as DetailsSuccess;
    emit(
      DetailsSuccess(
        currency: previous.currency,
        history: previous.history,
        isRefreshing: true,
      ),
    );
    await _fetch(event.currency, emit, previousData: previous);
  }

  Future<void> _fetch(
    Currency currency,
    Emitter<DetailsState> emit, {
    DetailsSuccess? previousData,
  }) async {
    try {
      final result = await _getHistory(
        code: currency.code,
        from: currency.date,
      );
      emit(_toState(currency, result, previousData: previousData));
    } catch (_) {
      if (previousData != null) {
        emit(previousData);
      } else {
        emit(DetailsError(const UnknownFailure()));
      }
    }
  }

  DetailsState _toState(
    Currency currency,
    Result<List<HistoryPoint>> result, {
    DetailsSuccess? previousData,
  }) {
    return switch (result) {
      Success(:final value) => DetailsSuccess(
        currency: currency,
        history: value,
      ),
      Failure(:final error) => previousData ?? DetailsError(error),
    };
  }
}
