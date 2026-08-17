import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../features/currency/data/datasources/currency_local_data_source.dart';

class HiveMigrations {
  static const _versionBox = 'version';
  static const _schemaVersionKey = 'rates_schema_version';
  static const _currentVersion = 2;

  static Future<void> migrateRatesBox() async {
    if (await Hive.boxExists('history')) {
      await Hive.deleteBoxFromDisk('history');
    }

    final versionBox = await Hive.openBox(_versionBox);
    final storedVersion =
        versionBox.get(_schemaVersionKey, defaultValue: 1) as int;

    if (storedVersion < _currentVersion) {
      const ratesBox = CurrencyLocalDataSourceImpl.boxName;
      if (await Hive.boxExists(ratesBox)) {
        try {
          await Hive.deleteBoxFromDisk(ratesBox);
        } catch (_) {
          // Box may be corrupted; ignore and recreate on open.
        }
      }
      await versionBox.put(_schemaVersionKey, _currentVersion);
    }

    await versionBox.close();
  }
}
