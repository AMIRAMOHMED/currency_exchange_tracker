import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/di/injection.dart';
import 'core/network/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'hive/hive_registrar.g.dart';
import 'presentation/bloc/app_bloc_observer.dart';
import 'presentation/bloc/connectivity/connectivity_bloc.dart';
import 'presentation/screens/currency_rates_screen.dart';
import 'shared/widgets/connectivity_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    Bloc.observer = AppBlocObserver();
  }

  await Hive.initFlutter();
  Hive.registerAdapters();
  await configureDependencies();

  runApp(const CurrencyExchangeTrackerApp());
}

class CurrencyExchangeTrackerApp extends StatelessWidget {
  const CurrencyExchangeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ConnectivityBloc(sl<ConnectivityService>())
        ..add(const ConnectivityStarted()),
      child: MaterialApp(
        title: 'Currency Exchange Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) =>
            ConnectivityBanner(child: child ?? const SizedBox.shrink()),
        home: const CurrencyRatesScreen(),
      ),
    );
  }
}
