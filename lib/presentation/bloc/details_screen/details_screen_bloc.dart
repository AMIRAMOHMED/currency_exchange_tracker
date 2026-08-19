import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../../features/currency/domain/entities/history_point.dart';
import '../../../features/currency/domain/usecases/get_currency_history_usecase.dart';
import '../../widgets/refresh_snack_listener.dart';
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
  DateTime? _lastRefreshAt;

  Future<void> _onLoad(LoadDetails event, Emitter<DetailsState> emit) async {
    if (state is! DetailsLoading) {
      emit(const DetailsLoading());
    }
    await emit.forEach<Result<List<HistoryPoint>>>(
      _getHistory(code: event.currency.code, anchorDate: event.currency.date),
      onData: (result) => switch (result) {
        Success(:final value) => DetailsSuccess(
          currency: event.currency,
          history: value,
          isChartLoading: value.length < _chartDays,
        ),
        Failure(:final error) => DetailsError(error),
      },
      onError: (_, _) => const DetailsError(UnknownFailure()),
    );

    if (state case DetailsSuccess current when current.isChartLoading) {
      emit(current.copyWith(isChartLoading: false));
    }
  }

  Future<void> _onRefresh(
    RefreshDetailsData event,
    Emitter<DetailsState> emit,
  ) async {
    if (state case DetailsSuccess current) {
      if (isRefreshCoolingDown(_lastRefreshAt)) {
        emit(current.copyWith(snack: refreshSnack(alreadyUpToDateText)));
        return;
      }

      emit(current.copyWith(isRefreshing: true));
      await emit.forEach<Result<List<HistoryPoint>>>(
        _getHistory(
          code: event.currency.code,
          anchorDate: event.currency.date,
          forceRefresh: true,
        ),
        onData: (result) => switch (result) {
          Success(:final value) when value.length >= 2 => _refreshDone(
            DetailsSuccess(currency: event.currency, history: value),
          ),
          Success() => current.copyWith(isRefreshing: false),
          Failure() => _refreshFailed(current),
        },
        onError: (_, _) => _refreshFailed(current),
      );

      if (state case DetailsSuccess after when after.isRefreshing) {
        emit(after.copyWith(isRefreshing: false));
      }
    }
  }

  DetailsSuccess _refreshDone(DetailsSuccess state) {
    _lastRefreshAt = DateTime.now();
    return state.copyWith(
      isRefreshing: false,
      lastCheckedAt: _lastRefreshAt,
      snack: updatedRatesSnack(state.currency.date),
    );
  }

  DetailsSuccess _refreshFailed(DetailsSuccess previous) {
    return previous.copyWith(
      isRefreshing: false,
      snack: refreshSnack(refreshFailedText, ok: false),
    );
  }
}
