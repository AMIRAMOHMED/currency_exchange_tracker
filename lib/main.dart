import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'hive/hive_registrar.g.dart';
import 'presentation/screens/currency_rates_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapters();
  await configureDependencies();

  runApp(const CurrencyExchangeTrackerApp());
}

class CurrencyExchangeTrackerApp extends StatelessWidget {
  const CurrencyExchangeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Exchange Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CurrencyRatesScreen(),
    );
  }
}
