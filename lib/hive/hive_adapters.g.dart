// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class DayRatesModelAdapter extends TypeAdapter<DayRatesModel> {
  @override
  final typeId = 1;

  @override
  DayRatesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayRatesModel(
      date: fields[0] as String,
      rates: (fields[1] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, DayRatesModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.rates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayRatesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CurrencyHistoryModelAdapter extends TypeAdapter<CurrencyHistoryModel> {
  @override
  final typeId = 2;

  @override
  CurrencyHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CurrencyHistoryModel(
      code: fields[0] as String,
      points: (fields[1] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, CurrencyHistoryModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.points);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
