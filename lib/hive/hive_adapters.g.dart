// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class ExchangeRateModelAdapter extends TypeAdapter<ExchangeRateModel> {
  @override
  final typeId = 3;

  @override
  ExchangeRateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExchangeRateModel(
      date: fields[0] as String,
      currency: fields[1] as String,
      rate: (fields[2] as num).toDouble(),
      updatedAt: (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeRateModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.currency)
      ..writeByte(2)
      ..write(obj.rate)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
