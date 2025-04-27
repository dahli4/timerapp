// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyRecordModelAdapter extends TypeAdapter<StudyRecordModel> {
  @override
  final int typeId = 1;

  @override
  StudyRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyRecordModel(
      timerId: fields[0] as String,
      date: fields[1] as DateTime,
      minutes: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StudyRecordModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.timerId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.minutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
