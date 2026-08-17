import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../../features/currency/domain/entities/currency_rate.dart';
import '../../../features/currency/domain/usecases/get_currencies_usecase.dart';
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

  Future<void> _onLoad(LoadMain event, Emitter<MainState> emit) async {
    emit(const MainLoading());
    await emit.forEach<Result<List<CurrencyRate>>>(
      _getCurrencies(),
      onData: _mapLoadResult,
      onError: (_, _) => const MainError(UnknownFailure()),
    );
  }

  Future<void> _onRefresh(
    RefreshMainData event,
    Emitter<MainState> emit,
  ) async {
    final current = state;
    if (current is! MainSuccess) return;

    emit(current.copyWith(isRefreshing: true));

    await emit.forEach<Result<List<CurrencyRate>>>(
      _getCurrencies(forceRefresh: true),
      onData: (result) => _mapRefreshResult(result, current),
      onError: (_, _) => current.copyWith(isRefreshing: false),
    );

    if (state is MainSuccess && (state as MainSuccess).isRefreshing) {
      emit((state as MainSuccess).copyWith(isRefreshing: false));
    }
  }

  MainState _mapLoadResult(Result<List<CurrencyRate>> result) {
    return switch (result) {
      Success(:final value) => MainSuccess(value),
      Failure(:final error) => MainError(error),
    };
  }

  MainState _mapRefreshResult(
    Result<List<CurrencyRate>> result,
    MainSuccess previous,
  ) {
    switch (result) {
      case Success(:final value) when value.isNotEmpty:
        return MainSuccess(value);
      case Success():
        return previous.copyWith(isRefreshing: false);
      case Failure():
        return previous.copyWith(isRefreshing: false);
    }
  }
}
