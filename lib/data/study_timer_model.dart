import 'package:hive/hive.dart';

part 'study_timer_model.g.dart';

@HiveType(typeId: 0)
class StudyTimerModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final int durationMinutes;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final int? colorHex;

  StudyTimerModel({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.createdAt,
    this.colorHex,
  });
}
