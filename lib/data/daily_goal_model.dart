import 'package:hive/hive.dart';

part 'daily_goal_model.g.dart';

@HiveType(typeId: 2) // 새로운 typeId 사용
class DailyGoalModel extends HiveObject {
  @HiveField(0)
  final DateTime date; // 목표 설정한 날짜

  @HiveField(1)
  final int goalMinutes; // 목표 시간 (분 단위)

  @HiveField(2)
  final DateTime createdAt; // 생성 시간

  @HiveField(3)
  final DateTime? modifiedAt; // 수정 시간

  DailyGoalModel({
    required this.date,
    required this.goalMinutes,
    required this.createdAt,
    this.modifiedAt,
  });

  // 날짜만 비교 (시간 제외)
  bool isSameDate(DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }

  // 목표 시간을 시간:분 형태로 변환
  String get goalTimeString {
    final hours = goalMinutes ~/ 60;
    final minutes = goalMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '$hours시간 $minutes분' : '$hours시간';
    }
    return '$minutes분';
  }
}
