// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_goal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyGoalModelAdapter extends TypeAdapter<DailyGoalModel> {
  @override
  final int typeId = 2;

  @override
  DailyGoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyGoalModel(
      date: fields[0] as DateTime,
      goalMinutes: fields[1] as int,
      createdAt: fields[2] as DateTime,
      modifiedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyGoalModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.goalMinutes)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.modifiedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyGoalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
