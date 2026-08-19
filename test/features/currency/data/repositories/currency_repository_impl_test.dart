import 'package:currency_exchange_tracker/core/errors/app_failure.dart';
import 'package:currency_exchange_tracker/core/errors/result.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_local_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/datasources/currency_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/currency/data/models/exchange_rate_model.dart';
import 'package:currency_exchange_tracker/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:currency_exchange_tracker/features/currency/domain/entities/currency_rate.dart';
import 'package:currency_exchange_tracker/features/currency/domain/supported_currency.dart';
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
  late CurrencyRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<ExchangeRateModel>[]);
  });

  setUp(() {
    remote = MockCurrencyRemoteDataSource();
    local = MockCurrencyLocalDataSource();
    repository = CurrencyRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );

    when(
      () => local.readLatestForCurrencies(any()),
    ).thenAnswer((_) async => const Success([]));

    when(() => local.writeRates(any())).thenAnswer((_) async => const Success(null));
  });

  Future<List<Result<List<CurrencyRate>>>> collect({bool forceRefresh = false}) {
    return repository.getHomeRates(forceRefresh: forceRefresh).toList();
  }

  List<ExchangeRateModel> allSupportedHomeModels({
    required String today,
    required String yesterday,
    double todayRate = 50.0,
    double yesterdayRate = 49.0,
  }) {
    return SupportedCurrency.values
        .expand(
          (currency) => homeRateModels(
            today: today,
            yesterday: yesterday,
            currency: currency.code,
            todayRate: todayRate + currency.index,
            yesterdayRate: yesterdayRate + currency.index,
          ),
        )
        .toList();
  }

  group('CurrencyRepositoryImpl', () {
    test(
      'should return cached memory data without remote call when not forceRefresh',
      () async {
        // Arrange
        final today = todayString();
        final yesterday = yesterdayString();
        final models = allSupportedHomeModels(today: today, yesterday: yesterday);

        when(() => remote.getHomeRates()).thenAnswer((_) async => Success(models));

        // Act — first call populates fresh memory cache
        await collect();
        clearInteractions(remote);

        final results = await collect();

        // Assert
        verifyNever(() => remote.getHomeRates());
        expect(results, hasLength(1));
        expect(results.single, isA<Success<List<CurrencyRate>>>());
      },
    );

    test('should call remote and update cache when forceRefresh is true', () async {
      // Arrange
      final today = todayString();
      final yesterday = yesterdayString();
      final initialModels = allSupportedHomeModels(
        today: today,
        yesterday: yesterday,
        todayRate: 50.0,
      );
      final refreshedModels = allSupportedHomeModels(
        today: today,
        yesterday: yesterday,
        todayRate: 60.0,
      );

      when(() => remote.getHomeRates()).thenAnswer(
        (_) async => Success(initialModels),
      );

      // Act — warm cache, then force a remote refresh with different data
      await collect();
      when(() => remote.getHomeRates()).thenAnswer(
        (_) async => Success(refreshedModels),
      );
      final results = await collect(forceRefresh: true);

      // Assert
      verify(() => remote.getHomeRates()).called(2);
      verify(() => local.writeRates(any())).called(2);
      expect(results, hasLength(1));
      expect(results.single, isA<Success<List<CurrencyRate>>>());
    });

    test('should emit Failure when remote fails and no cache exists', () async {
      when(() => remote.getHomeRates()).thenAnswer(
        (_) async => const Failure(NetworkFailure()),
      );

      final results = await collect();

      expect(results, hasLength(1));
      expect(results.single, isA<Failure<List<CurrencyRate>>>());
    });

    test('should emit Failure when remote is empty and no cache exists', () async {
      when(() => remote.getHomeRates()).thenAnswer(
        (_) async => const Success(<ExchangeRateModel>[]),
      );

      final results = await collect();

      expect(results, hasLength(1));
      expect(results.single, isA<Failure<List<CurrencyRate>>>());
    });

    test('regression: should keep disk cache when remote fails', () async {
      final today = todayString();
      final yesterday = yesterdayString();
      final models = allSupportedHomeModels(today: today, yesterday: yesterday);

      when(
        () => local.readLatestForCurrencies(any()),
      ).thenAnswer((_) async => Success(models));
      when(() => remote.getHomeRates()).thenAnswer(
        (_) async => const Failure(NetworkFailure()),
      );

      final results = await collect();

      expect(results, hasLength(1));
      expect(results.single, isA<Success<List<CurrencyRate>>>());
    });

    test(
      'regression: should keep disk cache when cached dates lag the device clock',
      () async {
        final now = DateTime.now();
        final latest = todayString(now.subtract(const Duration(days: 2)));
        final previous = todayString(now.subtract(const Duration(days: 3)));
        final models = allSupportedHomeModels(today: latest, yesterday: previous);

        when(
          () => local.readLatestForCurrencies(any()),
        ).thenAnswer((_) async => Success(models));
        when(() => remote.getHomeRates()).thenAnswer(
          (_) async => const Failure(NetworkFailure()),
        );

        final results = await collect();

        expect(results, hasLength(1));
        expect(results.single, isA<Success<List<CurrencyRate>>>());
        final rates = (results.single as Success<List<CurrencyRate>>).value;
        expect(rates.first.date, DateTime.parse(latest));
      },
    );

    test('should emit Failure on forceRefresh when remote fails even with cache', () async {
      final today = todayString();
      final yesterday = yesterdayString();
      final models = allSupportedHomeModels(today: today, yesterday: yesterday);

      when(
        () => local.readLatestForCurrencies(any()),
      ).thenAnswer((_) async => Success(models));
      when(() => remote.getHomeRates()).thenAnswer(
        (_) async => const Failure(NetworkFailure()),
      );

      final results = await collect(forceRefresh: true);

      expect(results, hasLength(1));
      expect(results.single, isA<Failure<List<CurrencyRate>>>());
    });

    test('should emit Success on forceRefresh even when remote matches cache', () async {
      final today = todayString();
      final yesterday = yesterdayString();
      final models = allSupportedHomeModels(today: today, yesterday: yesterday);

      when(
        () => local.readLatestForCurrencies(any()),
      ).thenAnswer((_) async => Success(models));
      when(() => remote.getHomeRates()).thenAnswer((_) async => Success(models));

      final results = await collect(forceRefresh: true);

      expect(results, hasLength(1));
      expect(results.single, isA<Success<List<CurrencyRate>>>());
    });

    test('should not emit duplicate Success when remote matches cache', () async {
      // Arrange
      final today = todayString();
      final yesterday = yesterdayString();
      final models = allSupportedHomeModels(today: today, yesterday: yesterday);

      when(
        () => local.readLatestForCurrencies(any()),
      ).thenAnswer((_) async => Success(models));

      when(() => remote.getHomeRates()).thenAnswer((_) async => Success(models));

      // Act
      final results = await collect();

      // Assert
      expect(results, hasLength(1));
      expect(results.single, isA<Success<List<CurrencyRate>>>());
      verify(() => remote.getHomeRates()).called(1);
    });

    test('should emit updated Success when remote differs from cache', () async {
      // Arrange
      final today = todayString();
      final yesterday = yesterdayString();
      final cachedModels = allSupportedHomeModels(
        today: today,
        yesterday: yesterday,
        todayRate: 50.0,
      );
      final remoteModels = allSupportedHomeModels(
        today: today,
        yesterday: yesterday,
        todayRate: 55.0,
      );

      when(
        () => local.readLatestForCurrencies(any()),
      ).thenAnswer((_) async => Success(cachedModels));

      when(() => remote.getHomeRates()).thenAnswer(
        (_) async => Success(remoteModels),
      );

      // Act
      final results = await collect();

      // Assert
      expect(results, hasLength(2));
      expect(results.every((result) => result is Success<List<CurrencyRate>>), isTrue);

      final firstRates = (results[0] as Success<List<CurrencyRate>>).value;
      final secondRates = (results[1] as Success<List<CurrencyRate>>).value;
      expect(firstRates.first.rate, 50.0 + SupportedCurrency.usd.index);
      expect(secondRates.first.rate, 55.0 + SupportedCurrency.usd.index);
    });

    test('should map CurrencyRate with rate, change, and date', () async {
      final today = todayString();
      final yesterday = yesterdayString();
      final models = homeRateModels(
        today: today,
        yesterday: yesterday,
        todayRate: 50.0,
        yesterdayRate: 48.0,
      );

      when(() => remote.getHomeRates()).thenAnswer(
        (_) async => Success(models),
      );

      final rates =
          ((await collect()).single as Success<List<CurrencyRate>>).value;
      final usd = rates.firstWhere((rate) => rate.code == 'USD');

      expect(usd.rate, 50.0);
      expect(usd.change, 2.0);
      expect(usd.date, DateTime.parse(today));
      expect(usd.name, SupportedCurrency.usd.name);
    });
  });
}
