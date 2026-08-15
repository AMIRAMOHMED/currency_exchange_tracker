import '../../../../core/errors/result.dart';
import '../../domain/entities/day_rates.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/currency_local_data_source.dart';
import '../datasources/currency_remote_data_source.dart';
import '../models/day_rates_model.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  const CurrencyRepositoryImpl({
    required CurrencyRemoteDataSource remoteDataSource,
    required CurrencyLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final CurrencyRemoteDataSource _remote;
  final CurrencyLocalDataSource _local;

  @override
  Future<Result<DayRates>> getLatest() async {
    final remote = await _remote.getRates();
    if (remote is Success<DayRatesModel>) {
      await _save(remote.value);
      return Success(remote.value.toEntity(isCached: false));
    }

    final cached = await _local.readLatest();
    if (cached is Success<DayRatesModel?> && cached.value != null) {
      return Success(cached.value!.toEntity(isCached: true));
    }
    return Failure(
      cached is Failure<DayRatesModel?>
          ? cached.error
          : (remote as Failure<DayRatesModel>).error,
    );
  }

  @override
  Future<Result<DayRates>> getByDate(DateTime date) async {
    final key = DayRatesModel.dateFormat.format(date);

    final cached = await _local.read(key);
    if (cached is Success<DayRatesModel?> && cached.value != null) {
      return Success(cached.value!.toEntity(isCached: true));
    }

    final remote = await _remote.getRates(date: key);
    if (remote is Success<DayRatesModel>) {
      await _local.write(remote.value);
      return Success(remote.value.toEntity(isCached: false));
    }
    return Failure((remote as Failure<DayRatesModel>).error);
  }

  Future<void> _save(DayRatesModel fresh) async {
    final existing = await _local.read(fresh.date);
    if (existing is Success<DayRatesModel?> && existing.value == fresh) return;
    await _local.write(fresh);
  }
}
