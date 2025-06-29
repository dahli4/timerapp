// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_group_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerGroupModelAdapter extends TypeAdapter<TimerGroupModel> {
  @override
  final int typeId = 3;

  @override
  TimerGroupModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimerGroupModel(
      id: fields[0] as String,
      name: fields[1] as String,
      colorHex: fields[2] as int?,
      createdAt: fields[3] as DateTime,
      modifiedAt: fields[4] as DateTime?,
      order: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TimerGroupModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorHex)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.modifiedAt)
      ..writeByte(5)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerGroupModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
