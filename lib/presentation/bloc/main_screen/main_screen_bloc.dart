import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../../features/currency/domain/entities/currency_rate.dart';
import '../../../features/currency/domain/usecases/get_currencies_usecase.dart';
import '../../widgets/refresh_snack_listener.dart';
import 'main_screen_event.dart';
import 'main_screen_state.dart';

export 'main_screen_event.dart';
export 'main_screen_state.dart';

class MainScreenBloc extends Bloc<MainScreenEvent, MainState> {
  MainScreenBloc(this._getCurrencies) : super(const MainLoading()) {
    on<LoadMain>(_onLoad);
    on<RefreshMainData>(_onRefresh);
  }

  final GetCurrenciesUseCase _getCurrencies;
  DateTime? _lastRefreshAt;

  Future<void> _onLoad(LoadMain event, Emitter<MainState> emit) async {
    if (state is! MainLoading) {
      emit(const MainLoading());
    }
    await emit.forEach<Result<List<CurrencyRate>>>(
      _getCurrencies(),
      onData: (result) => switch (result) {
        Success(:final value) => MainSuccess(value),
        Failure(:final error) => MainError(error),
      },
      onError: (_, _) => const MainError(UnknownFailure()),
    );
  }

  Future<void> _onRefresh(
    RefreshMainData event,
    Emitter<MainState> emit,
  ) async {
    if (state case MainSuccess current) {
      if (isRefreshCoolingDown(_lastRefreshAt)) {
        emit(current.copyWith(snack: refreshSnack(alreadyUpToDateText)));
        return;
      }

      emit(current.copyWith(isRefreshing: true));
      await emit.forEach<Result<List<CurrencyRate>>>(
        _getCurrencies(forceRefresh: true),
        onData: (result) => switch (result) {
          Success(:final value) when value.isNotEmpty => _refreshDone(
            MainSuccess(value),
          ),
          Success() => current.copyWith(isRefreshing: false),
          Failure() => _refreshFailed(current),
        },
        onError: (_, _) => _refreshFailed(current),
      );

      if (state case MainSuccess after when after.isRefreshing) {
        emit(after.copyWith(isRefreshing: false));
      }
    }
  }

  MainSuccess _refreshDone(MainSuccess state) {
    _lastRefreshAt = DateTime.now();
    return state.copyWith(
      isRefreshing: false,
      lastCheckedAt: _lastRefreshAt,
      snack: updatedRatesSnack(state.currencies.first.date),
    );
  }

  MainSuccess _refreshFailed(MainSuccess previous) {
    return previous.copyWith(
      isRefreshing: false,
      snack: refreshSnack(refreshFailedText, ok: false),
    );
  }
}
