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
      'should emit MainSuccess without re-emitting the initial MainLoading',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadMain()),
      setUp: () {
        when(() => mockGetCurrencies()).thenAnswer(
          (_) => Stream.value(Success(sampleCurrencies())),
        );
      },
      expect: () => [
        MainSuccess(sampleCurrencies()),
      ],
    );

    blocTest<MainScreenBloc, MainState>(
      'should emit MainLoading then MainSuccess when retrying from error',
      build: buildBloc,
      seed: () => const MainError(NetworkFailure()),
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
      'should emit MainError when use case emits Failure',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadMain()),
      setUp: () {
        when(() => mockGetCurrencies()).thenAnswer(
          (_) => Stream.value(const Failure(NetworkFailure())),
        );
      },
      expect: () => [
        isA<MainError>().having(
          (state) => state.error,
          'error',
          isA<NetworkFailure>(),
        ),
      ],
    );

    blocTest<MainScreenBloc, MainState>(
      'should emit MainError(UnknownFailure) when stream errors',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadMain()),
      setUp: () {
        when(() => mockGetCurrencies()).thenAnswer(
          (_) => Stream.error(Exception('stream failed')),
        );
      },
      expect: () => [
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
          isA<MainSuccess>()
              .having((s) => s.currencies, 'currencies', refreshed)
              .having((s) => s.snack?.text, 'snack.text', 'Rates updated')
              .having((s) => s.lastCheckedAt, 'lastCheckedAt', isNotNull),
        ];
      },
    );

    blocTest<MainScreenBloc, MainState>(
      'should skip API when refresh is within cooldown',
      build: buildBloc,
      seed: () => MainSuccess(currencies),
      setUp: () {
        when(() => mockGetCurrencies(forceRefresh: true)).thenAnswer(
          (_) => Stream.value(Success(currencies)),
        );
      },
      act: (bloc) async {
        bloc.add(const RefreshMainData());
        await bloc.stream.firstWhere(
          (s) =>
              s is MainSuccess &&
              !s.isRefreshing &&
              s.snack?.text == 'Rates updated',
        );
        bloc.add(const RefreshMainData());
      },
      expect: () => [
        MainSuccess(currencies, isRefreshing: true),
        isA<MainSuccess>()
            .having((s) => s.snack?.text, 'snack.text', 'Rates updated')
            .having((s) => s.lastCheckedAt, 'lastCheckedAt', isNotNull),
        isA<MainSuccess>()
            .having((s) => s.snack?.text, 'snack.text', 'Already up to date')
            .having((s) => s.lastCheckedAt, 'lastCheckedAt', isNotNull),
      ],
      verify: (_) {
        verify(() => mockGetCurrencies(forceRefresh: true)).called(1);
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
      'should keep old data and show offline snack when refresh fails',
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
        isA<MainSuccess>()
            .having((s) => s.isRefreshing, 'isRefreshing', false)
            .having((s) => s.currencies, 'currencies', currencies)
            .having(
              (s) => s.snack?.text,
              'snack.text',
              "Couldn't refresh — check your connection",
            )
            .having((s) => s.snack?.ok, 'snack.ok', false),
      ],
    );

    blocTest<MainScreenBloc, MainState>(
      'should clear spinner without success snack when stream ends empty',
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
