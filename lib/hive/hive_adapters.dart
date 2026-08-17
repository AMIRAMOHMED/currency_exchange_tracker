import 'package:hive_ce/hive.dart';

import '../features/currency/data/models/exchange_rate_model.dart';

@GenerateAdapters([AdapterSpec<ExchangeRateModel>()])
part 'hive_adapters.g.dart';
