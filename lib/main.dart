import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/di/injection.dart';
import 'hive/hive_registrar.g.dart';

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
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('Currency Exchange Tracker')),
      ),
    );
  }
}
