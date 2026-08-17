import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/errors/app_failure.dart';
import 'package:currency_exchange_tracker/core/errors/result.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_currencies_usecase.dart';
import 'package:currency_exchange_tracker/presentation/bloc/main_screen/main_screen_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_data.dart';

class MockGetCurrenciesUseCase extends Mock implements GetCurrenciesUseCase {}

void main() {
  late MockGetCurrenciesUseCase mockGetCurrencies;

  setUp(() {
    mockGetCurrencies = MockGetCurrenciesUseCase();
  });

  MainScreenBloc buildBloc() => MainScreenBloc(mockGetCurrencies);

  group('LoadMain', () {
    blocTest<MainScreenBloc, MainState>(
      'should emit [MainLoading, MainSuccess] when use case emits Success',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadMain()),
      setUp: () {
        when(() => mockGetCurrencies()).thenAnswer(
          (_) => Stream.value(Success(sampleCurrencies())),
        );
      },
      expect: () => [
        const MainLoading(),
        MainSuccess(sampleCurrencies()),
      ],
    );

    blocTest<MainScreenBloc, MainState>(
      'should emit [MainLoading, MainError] when use case emits Failure',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadMain()),
      setUp: () {
        when(() => mockGetCurrencies()).thenAnswer(
          (_) => Stream.value(const Failure(NetworkFailure())),
        );
      },
      expect: () => [
        const MainLoading(),
        isA<MainError>().having(
          (state) => state.error,
          'error',
          isA<NetworkFailure>(),
        ),
      ],
    );

    blocTest<MainScreenBloc, MainState>(
      'should emit [MainLoading, MainError(UnknownFailure)] when stream errors',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadMain()),
      setUp: () {
        when(() => mockGetCurrencies()).thenAnswer(
          (_) => Stream.error(Exception('stream failed')),
        );
      },
      expect: () => [
        const MainLoading(),
        isA<MainError>().having(
          (state) => state.error,
          'error',
          isA<UnknownFailure>(),
        ),
      ],
    );
  });

  group('RefreshMainData', () {
    final currencies = sampleCurrencies();

    blocTest<MainScreenBloc, MainState>(
      'should no-op when state is not MainSuccess',
      build: buildBloc,
      act: (bloc) => bloc.add(const RefreshMainData()),
      expect: () => <MainState>[],
      verify: (_) {
        verifyNever(() => mockGetCurrencies(forceRefresh: any(named: 'forceRefresh')));
      },
    );

    blocTest<MainScreenBloc, MainState>(
      'should set isRefreshing=true then emit updated data on success',
      build: buildBloc,
      seed: () => MainSuccess(currencies),
      act: (bloc) => bloc.add(const RefreshMainData()),
      setUp: () {
        final refreshed = [
          sampleCurrency(code: 'USD', rate: 99.0),
          ...currencies.skip(1),
        ];

        when(() => mockGetCurrencies(forceRefresh: true)).thenAnswer(
          (_) => Stream.value(Success(refreshed)),
        );
      },
      expect: () {
        final refreshed = [
          sampleCurrency(code: 'USD', rate: 99.0),
          ...currencies.skip(1),
        ];

        return [
          MainSuccess(currencies, isRefreshing: true),
          MainSuccess(refreshed),
        ];
      },
    );

    blocTest<MainScreenBloc, MainState>(
      'regression: should keep old data when refresh returns empty Success',
      build: buildBloc,
      seed: () => MainSuccess(currencies),
      act: (bloc) => bloc.add(const RefreshMainData()),
      setUp: () {
        when(() => mockGetCurrencies(forceRefresh: true)).thenAnswer(
          (_) => Stream.value(const Success(<CurrencyRate>[])),
        );
      },
      expect: () => [
        MainSuccess(currencies, isRefreshing: true),
        MainSuccess(currencies, isRefreshing: false),
      ],
    );

    blocTest<MainScreenBloc, MainState>(
      'should keep old data and stop refreshing when use case emits Failure',
      build: buildBloc,
      seed: () => MainSuccess(currencies),
      act: (bloc) => bloc.add(const RefreshMainData()),
      setUp: () {
        when(() => mockGetCurrencies(forceRefresh: true)).thenAnswer(
          (_) => Stream.value(const Failure(ServerFailure())),
        );
      },
      expect: () => [
        MainSuccess(currencies, isRefreshing: true),
        MainSuccess(currencies, isRefreshing: false),
      ],
    );

    blocTest<MainScreenBloc, MainState>(
      'regression: should clear spinner when refresh stream ends empty',
      build: buildBloc,
      seed: () => MainSuccess(currencies),
      act: (bloc) => bloc.add(const RefreshMainData()),
      setUp: () {
        when(() => mockGetCurrencies(forceRefresh: true)).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      expect: () => [
        MainSuccess(currencies, isRefreshing: true),
        MainSuccess(currencies, isRefreshing: false),
      ],
    );
  });
}
