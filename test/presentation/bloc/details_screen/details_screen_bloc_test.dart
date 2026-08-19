import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/errors/app_failure.dart';
import 'package:currency_exchange_tracker/core/errors/result.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/history_point.dart';
import 'package:currency_exchange_tracker/features/currency/domain/usecases/get_currency_history_usecase.dart';
import 'package:currency_exchange_tracker/presentation/bloc/details_screen/details_screen_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_data.dart';

class MockGetCurrencyHistoryUseCase extends Mock
    implements GetCurrencyHistoryUseCase {}

void main() {
  late MockGetCurrencyHistoryUseCase mockGetHistory;

  const anchor = '2026-08-17';
  final currency = sampleCurrency(date: DateTime.parse(anchor));

  setUp(() {
    mockGetHistory = MockGetCurrencyHistoryUseCase();
  });

  DetailsScreenBloc buildBloc() => DetailsScreenBloc(mockGetHistory);

  group('LoadDetails', () {
    blocTest<DetailsScreenBloc, DetailsState>(
      'should emit DetailsSuccess without re-emitting the initial DetailsLoading',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadDetails(currency)),
      setUp: () {
        final history = sampleHistoryPoints(7, anchor: anchor);
        when(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
          ),
        ).thenAnswer((_) => Stream.value(Success(history)));
      },
      expect: () => [
        DetailsSuccess(currency: currency, history: sampleHistoryPoints(7, anchor: anchor)),
      ],
    );

    blocTest<DetailsScreenBloc, DetailsState>(
      'regression: should clear chart loading after short history loads',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadDetails(currency)),
      setUp: () {
        final history = sampleHistoryPoints(3, anchor: anchor);
        when(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
          ),
        ).thenAnswer((_) => Stream.value(Success(history)));
      },
      expect: () {
        final history = sampleHistoryPoints(3, anchor: anchor);
        return [
          DetailsSuccess(
            currency: currency,
            history: history,
            isChartLoading: true,
          ),
          DetailsSuccess(
            currency: currency,
            history: history,
            isChartLoading: false,
          ),
        ];
      },
    );

    blocTest<DetailsScreenBloc, DetailsState>(
      'should emit DetailsError when use case emits Failure',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadDetails(currency)),
      setUp: () {
        when(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
          ),
        ).thenAnswer(
          (_) => Stream.value(const Failure(ServerFailure())),
        );
      },
      expect: () => [
        isA<DetailsError>().having(
          (state) => state.error,
          'error',
          isA<ServerFailure>(),
        ),
      ],
    );
  });

  group('RefreshDetailsData', () {
    final history = sampleHistoryPoints(7, anchor: anchor);
    final previous = DetailsSuccess(currency: currency, history: history);

    blocTest<DetailsScreenBloc, DetailsState>(
      'should no-op when state is not DetailsSuccess',
      build: buildBloc,
      act: (bloc) => bloc.add(RefreshDetailsData(currency)),
      expect: () => <DetailsState>[],
      verify: (_) {
        verifyNever(
          () => mockGetHistory(
            code: any(named: 'code'),
            anchorDate: any(named: 'anchorDate'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        );
      },
    );

    blocTest<DetailsScreenBloc, DetailsState>(
      'should update history when refresh emits Success with at least 2 points',
      build: buildBloc,
      seed: () => previous,
      act: (bloc) => bloc.add(RefreshDetailsData(currency)),
      setUp: () {
        final refreshed = sampleHistoryPoints(7, anchor: anchor)
            .map((point) => HistoryPoint(date: point.date, rate: point.rate + 1))
            .toList();

        when(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
            forceRefresh: true,
          ),
        ).thenAnswer((_) => Stream.value(Success(refreshed)));
      },
      expect: () {
        final refreshed = sampleHistoryPoints(7, anchor: anchor)
            .map((point) => HistoryPoint(date: point.date, rate: point.rate + 1))
            .toList();

        return [
          previous.copyWith(isRefreshing: true),
          isA<DetailsSuccess>()
              .having((s) => s.history, 'history', refreshed)
              .having(
                (s) => s.snack?.text,
                'snack.text',
                startsWith('Up to date'),
              )
              .having((s) => s.lastCheckedAt, 'lastCheckedAt', isNotNull),
        ];
      },
    );

    blocTest<DetailsScreenBloc, DetailsState>(
      'should skip API when refresh is within cooldown',
      build: buildBloc,
      seed: () => previous,
      setUp: () {
        when(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
            forceRefresh: true,
          ),
        ).thenAnswer((_) => Stream.value(Success(history)));
      },
      act: (bloc) async {
        bloc.add(RefreshDetailsData(currency));
        await bloc.stream.firstWhere(
          (s) =>
              s is DetailsSuccess &&
              !s.isRefreshing &&
              (s.snack?.text.startsWith('Up to date') ?? false),
        );
        bloc.add(RefreshDetailsData(currency));
      },
      expect: () => [
        previous.copyWith(isRefreshing: true),
        isA<DetailsSuccess>()
            .having(
              (s) => s.snack?.text,
              'snack.text',
              startsWith('Up to date'),
            )
            .having((s) => s.lastCheckedAt, 'lastCheckedAt', isNotNull),
        isA<DetailsSuccess>()
            .having((s) => s.snack?.text, 'snack.text', 'Already up to date')
            .having((s) => s.lastCheckedAt, 'lastCheckedAt', isNotNull),
      ],
      verify: (_) {
        verify(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
            forceRefresh: true,
          ),
        ).called(1);
      },
    );

    blocTest<DetailsScreenBloc, DetailsState>(
      'should keep previous history when refresh emits empty Success',
      build: buildBloc,
      seed: () => previous,
      act: (bloc) => bloc.add(RefreshDetailsData(currency)),
      setUp: () {
        when(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
            forceRefresh: true,
          ),
        ).thenAnswer(
          (_) => Stream.value(const Success(<HistoryPoint>[])),
        );
      },
      expect: () => [
        previous.copyWith(isRefreshing: true),
        previous.copyWith(isRefreshing: false),
      ],
    );

    blocTest<DetailsScreenBloc, DetailsState>(
      'should keep previous history when refresh emits short Success',
      build: buildBloc,
      seed: () => previous,
      act: (bloc) => bloc.add(RefreshDetailsData(currency)),
      setUp: () {
        when(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
            forceRefresh: true,
          ),
        ).thenAnswer(
          (_) => Stream.value(Success(sampleHistoryPoints(1, anchor: anchor))),
        );
      },
      expect: () => [
        previous.copyWith(isRefreshing: true),
        previous.copyWith(isRefreshing: false),
      ],
    );

    blocTest<DetailsScreenBloc, DetailsState>(
      'should keep previous history and show offline snack when refresh fails',
      build: buildBloc,
      seed: () => previous,
      act: (bloc) => bloc.add(RefreshDetailsData(currency)),
      setUp: () {
        when(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
            forceRefresh: true,
          ),
        ).thenAnswer(
          (_) => Stream.value(const Failure(NetworkFailure())),
        );
      },
      expect: () => [
        previous.copyWith(isRefreshing: true),
        isA<DetailsSuccess>()
            .having((s) => s.isRefreshing, 'isRefreshing', false)
            .having((s) => s.history, 'history', history)
            .having(
              (s) => s.snack?.text,
              'snack.text',
              "Couldn't refresh — check your connection",
            )
            .having((s) => s.snack?.ok, 'snack.ok', false),
      ],
    );

    blocTest<DetailsScreenBloc, DetailsState>(
      'should clear spinner without success snack when stream ends empty',
      build: buildBloc,
      seed: () => previous,
      act: (bloc) => bloc.add(RefreshDetailsData(currency)),
      setUp: () {
        when(
          () => mockGetHistory(
            code: currency.code,
            anchorDate: currency.date,
            forceRefresh: true,
          ),
        ).thenAnswer((_) => const Stream.empty());
      },
      expect: () => [
        previous.copyWith(isRefreshing: true),
        previous.copyWith(isRefreshing: false),
      ],
    );
  });
}
