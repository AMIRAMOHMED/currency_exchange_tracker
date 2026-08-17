import 'package:currency_exchange_tracker/core/errors/app_failure.dart';
import 'package:currency_exchange_tracker/core/errors/result.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_local_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/models/exchange_rate_model.dart';
import 'package:currency_exchange_tracker/features/currency/data/repositories/currency_history_repository_impl.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/history_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_data.dart';

class MockCurrencyRemoteDataSource extends Mock
    implements CurrencyRemoteDataSource {}

class MockCurrencyLocalDataSource extends Mock
    implements CurrencyLocalDataSource {}

void main() {
  late MockCurrencyRemoteDataSource remote;
  late MockCurrencyLocalDataSource local;
  late CurrencyHistoryRepositoryImpl repository;

  const anchor = '2026-08-17';
  const code = 'USD';

  setUpAll(() {
    registerFallbackValue(<ExchangeRateModel>[]);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    remote = MockCurrencyRemoteDataSource();
    local = MockCurrencyLocalDataSource();
    repository = CurrencyHistoryRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );

    when(() => local.writeRates(any())).thenAnswer((_) async => const Success(null));
  });

  Future<List<Result<List<HistoryPoint>>>> collect({
    bool forceRefresh = false,
    DateTime? anchorDate,
  }) {
    return repository
        .getHistory(
          code: code,
          anchorDate: anchorDate ?? DateTime.parse(anchor),
          forceRefresh: forceRefresh,
        )
        .toList();
  }

  List<ExchangeRateModel> fullWeekCache({double rate = 50.0}) {
    return historyModels(
      currency: code,
      dates: dateRangeFromAnchor(anchor, 7),
      rate: rate,
    );
  }

  group('CurrencyHistoryRepositoryImpl', () {
    test(
      'should return cached data without remote call when cache is complete',
      () async {
        // Arrange
        final cached = fullWeekCache();
        when(
          () => local.readHistoryForCurrency(code, limit: any(named: 'limit')),
        ).thenAnswer((_) async => Success(cached));

        // Act
        final results = await collect();

        // Assert
        verifyNever(
          () => remote.getRatesForDates(any(), any()),
        );
        expect(results, hasLength(1));
        expect(results.single, isA<Success<List<HistoryPoint>>>());
        expect(
          (results.single as Success<List<HistoryPoint>>).value,
          hasLength(7),
        );
      },
    );

    test('should call remote and update cache when forceRefresh is true', () async {
      // Arrange
      final cached = fullWeekCache(rate: 50.0);
      final refreshed = fullWeekCache(rate: 55.0);

      var readCount = 0;
      when(
        () => local.readHistoryForCurrency(code, limit: any(named: 'limit')),
      ).thenAnswer((_) async {
        readCount++;
        return Success(readCount == 1 ? cached : refreshed);
      });

      when(
        () => remote.getRatesForDates(any(), code),
      ).thenAnswer((_) async => Success(refreshed.sublist(0, 3)));

      // Act
      final results = await collect(forceRefresh: true);

      // Assert
      verify(() => remote.getRatesForDates(any(), code)).called(1);
      verify(() => local.writeRates(any())).called(1);
      expect(results, hasLength(1));
      expect(results.single, isA<Success<List<HistoryPoint>>>());
    });

    test('should emit Failure when remote fails and cache is insufficient', () async {
      // Arrange
      when(
        () => local.readHistoryForCurrency(code, limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Success(<ExchangeRateModel>[]));

      when(
        () => remote.getRatesForDates(any(), code),
      ).thenAnswer((_) async => const Failure(NetworkFailure()));

      // Act
      final results = await collect(forceRefresh: true);

      // Assert
      expect(results, hasLength(1));
      expect(results.single, isA<Failure<List<HistoryPoint>>>());
      expect(
        (results.single as Failure).error,
        isA<NetworkFailure>(),
      );
    });

    test(
      'should emit Failure when remote is empty and cache is insufficient',
      () async {
        // Arrange
        when(
          () => local.readHistoryForCurrency(code, limit: any(named: 'limit')),
        ).thenAnswer((_) async => const Success(<ExchangeRateModel>[]));

        when(
          () => remote.getRatesForDates(any(), code),
        ).thenAnswer((_) async => const Success(<ExchangeRateModel>[]));

        // Act
        final results = await collect(forceRefresh: true);

        // Assert
        expect(results, hasLength(1));
        expect(results.single, isA<Failure<List<HistoryPoint>>>());
        expect(
          (results.single as Failure).error,
          isA<ServerFailure>(),
        );
      },
    );

    test('should not emit duplicate Success when forceRefresh sync matches cache', () async {
      // Arrange
      final cached = fullWeekCache();
      when(
        () => local.readHistoryForCurrency(code, limit: any(named: 'limit')),
      ).thenAnswer((_) async => Success(cached));

      when(
        () => remote.getRatesForDates(any(), code),
      ).thenAnswer((_) async => Success(cached));

      // Act
      final results = await collect(forceRefresh: true);

      // Assert — identical synced data produces no extra emission
      expect(results, isEmpty);
    });

    test('should emit updated Success when synced data differs from cache', () async {
      // Arrange
      final partialCache = historyModels(
        currency: code,
        dates: dateRangeFromAnchor(anchor, 2),
        rate: 50.0,
      );
      final completeCache = fullWeekCache(rate: 55.0);

      var readCount = 0;
      when(
        () => local.readHistoryForCurrency(code, limit: any(named: 'limit')),
      ).thenAnswer((_) async {
        readCount++;
        return Success(readCount == 1 ? partialCache : completeCache);
      });

      when(
        () => remote.getRatesForDates(any(), code),
      ).thenAnswer((_) async => Success(completeCache.sublist(0, 5)));

      // Act
      final results = await collect();

      // Assert
      expect(results, hasLength(2));
      expect(results.every((result) => result is Success<List<HistoryPoint>>), isTrue);

      final first = (results[0] as Success<List<HistoryPoint>>).value;
      final second = (results[1] as Success<List<HistoryPoint>>).value;
      expect(first, hasLength(2));
      expect(second, hasLength(7));
      expect(second.last.rate, 55.0);
    });

    test('regression: should keep cached Success when remote fails', () async {
      final partialCache = historyModels(
        currency: code,
        dates: dateRangeFromAnchor(anchor, 2),
        rate: 50.0,
      );

      when(
        () => local.readHistoryForCurrency(code, limit: any(named: 'limit')),
      ).thenAnswer((_) async => Success(partialCache));
      when(
        () => remote.getRatesForDates(any(), code),
      ).thenAnswer((_) async => const Failure(NetworkFailure()));

      final results = await collect();

      expect(results, hasLength(1));
      expect(results.single, isA<Success<List<HistoryPoint>>>());
    });

    test('should map HistoryPoint with date and rate', () async {
      // Arrange
      final dates = dateRangeFromAnchor(anchor, 2);
      final cached = historyModels(
        currency: code,
        dates: dates,
        rate: 42.5,
      );

      when(
        () => local.readHistoryForCurrency(code, limit: any(named: 'limit')),
      ).thenAnswer((_) async => Success(cached));

      // Act
      final results = await repository
          .getHistory(
            code: code,
            days: 2,
            anchorDate: DateTime.parse(anchor),
          )
          .toList();
      final points = (results.single as Success<List<HistoryPoint>>).value;

      // Assert
      expect(points, hasLength(2));
      expect(points.first.date, DateTime.parse(dates.last));
      expect(points.last.date, DateTime.parse(anchor));
      expect(points.last.rate, 42.5);
    });
  });
}
