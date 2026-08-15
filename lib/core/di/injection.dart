import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../features/currency/data/datasources/currency_history_local_data_source.dart';
import '../../features/currency/data/datasources/currency_local_data_source.dart';
import '../../features/currency/data/datasources/currency_remote_data_source.dart';
import '../../features/currency/data/models/currency_history_model.dart';
import '../../features/currency/data/models/day_rates_model.dart';
import '../../features/currency/data/repositories/currency_history_repository_impl.dart';
import '../../features/currency/data/repositories/currency_repository_impl.dart';
import '../../features/currency/domain/repositories/currency_history_repository.dart';
import '../../features/currency/domain/repositories/currency_repository.dart';
import '../../features/currency/domain/usecases/get_currencies_usecase.dart';
import '../../features/currency/domain/usecases/get_currency_history_usecase.dart';
import '../network/dio_client.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  final ratesBox = await Hive.openBox<DayRatesModel>(
    CurrencyLocalDataSourceImpl.boxName,
  );
  final historyBox = await Hive.openBox<CurrencyHistoryModel>(
    CurrencyHistoryLocalDataSourceImpl.boxName,
  );

  sl
    ..registerLazySingleton<DioClient>(DioClient.new)
    ..registerLazySingleton<CurrencyRemoteDataSource>(
      () => CurrencyRemoteDataSourceImpl(sl<DioClient>()),
    )
    ..registerLazySingleton<CurrencyLocalDataSource>(
      () => CurrencyLocalDataSourceImpl(ratesBox),
    )
    ..registerLazySingleton<CurrencyHistoryLocalDataSource>(
      () => CurrencyHistoryLocalDataSourceImpl(historyBox),
    )
    ..registerLazySingleton<CurrencyRepository>(
      () => CurrencyRepositoryImpl(
        remoteDataSource: sl<CurrencyRemoteDataSource>(),
        localDataSource: sl<CurrencyLocalDataSource>(),
      ),
    )
    ..registerLazySingleton<CurrencyHistoryRepository>(
      () => CurrencyHistoryRepositoryImpl(
        remoteDataSource: sl<CurrencyRemoteDataSource>(),
        localDataSource: sl<CurrencyHistoryLocalDataSource>(),
      ),
    )
    ..registerLazySingleton<GetCurrenciesUseCase>(
      () => GetCurrenciesUseCase(sl<CurrencyRepository>()),
    )
    ..registerLazySingleton<GetCurrencyHistoryUseCase>(
      () => GetCurrencyHistoryUseCase(sl<CurrencyHistoryRepository>()),
    );
}
