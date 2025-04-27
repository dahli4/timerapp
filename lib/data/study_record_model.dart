import 'package:hive/hive.dart';

part 'study_record_model.g.dart';

@HiveType(typeId: 1)
class StudyRecordModel extends HiveObject {
  @HiveField(0)
  final String timerId; // 어떤 타이머(과목)인지
  @HiveField(1)
  final DateTime date; // 기록 날짜 (yyyy-MM-dd만 사용)
  @HiveField(2)
  final int minutes; // 공부한 분

  StudyRecordModel({
    required this.timerId,
    required this.date,
    required this.minutes,
  });
}
