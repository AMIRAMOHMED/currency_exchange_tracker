import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../../features/currency/domain/entities/currency.dart';
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
    await _fetch(emit);
  }

  Future<void> _onRefresh(RefreshMainData event, Emitter<MainState> emit) async {
    if (state is! MainSuccess) return;

    final previous = state as MainSuccess;
    emit(MainSuccess(previous.currencies, isRefreshing: true));
    await _fetch(emit, previousData: previous);
  }

  Future<void> _fetch(Emitter<MainState> emit, {MainSuccess? previousData}) async {
    try {
      emit(_toState(await _getCurrencies(), previousData: previousData));
    } catch (_) {
      if (previousData != null) {
        emit(previousData);
      } else {
        emit(MainError(const UnknownFailure()));
      }
    }
  }

  MainState _toState(
    Result<List<Currency>> result, {
    MainSuccess? previousData,
  }) {
    return switch (result) {
      Success(:final value) => MainSuccess(value),
      Failure(:final error) => previousData ?? MainError(error),
    };
  }
}
