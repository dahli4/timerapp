import 'package:hive/hive.dart';

part 'study_record_model.g.dart';

@HiveType(typeId: 1)
class StudyRecordModel extends HiveObject {
  @HiveField(0)
  final String timerId;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final int minutes;
  @HiveField(3)
  final int seconds; // 추가

  StudyRecordModel({
    required this.timerId,
    required this.date,
    required this.minutes,
    required this.seconds,
  });
}
