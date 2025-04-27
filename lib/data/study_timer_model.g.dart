// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_timer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyTimerModelAdapter extends TypeAdapter<StudyTimerModel> {
  @override
  final int typeId = 0;

  @override
  StudyTimerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyTimerModel(
      id: fields[0] as String,
      title: fields[1] as String,
      durationMinutes: fields[2] as int,
      createdAt: fields[3] as DateTime,
      colorHex: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StudyTimerModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.durationMinutes)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.colorHex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyTimerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
