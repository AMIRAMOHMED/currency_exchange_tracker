import 'package:hive_ce/hive.dart';

import '../features/currency/data/models/currency_history_model.dart';
import '../features/currency/data/models/day_rates_model.dart';

@GenerateAdapters([
  AdapterSpec<DayRatesModel>(),
  AdapterSpec<CurrencyHistoryModel>(),
])
part 'hive_adapters.g.dart';
