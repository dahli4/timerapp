import 'package:hive_flutter/hive_flutter.dart';
import '../data/daily_goal_model.dart';
import '../data/study_record_model.dart';

class DailyGoalService {
  static const String _boxName = 'daily_goals';

  // 싱글톤 패턴
  static final DailyGoalService _instance = DailyGoalService._internal();
  factory DailyGoalService() => _instance;
  DailyGoalService._internal();

  // Hive 박스 가져오기
  Box<DailyGoalModel> get _goalBox => Hive.box<DailyGoalModel>(_boxName);
  Box<StudyRecordModel> get _recordBox => Hive.box<StudyRecordModel>('records');

  // 오늘 목표 가져오기
  DailyGoalModel? getTodayGoal() {
    final today = DateTime.now();
    final goals = _goalBox.values.where((goal) => goal.isSameDate(today));
    return goals.isNotEmpty ? goals.first : null;
  }

  // 특정 날짜 목표 가져오기
  DailyGoalModel? getGoalForDate(DateTime date) {
    final goals = _goalBox.values.where((goal) => goal.isSameDate(date));
    return goals.isNotEmpty ? goals.first : null;
  }

  // 목표 설정/수정
  Future<void> setDailyGoal(DateTime date, int goalMinutes) async {
    final existingGoal = getGoalForDate(date);

    if (existingGoal != null) {
      // 기존 목표 수정
      final updatedGoal = DailyGoalModel(
        date: existingGoal.date,
        goalMinutes: goalMinutes,
        createdAt: existingGoal.createdAt,
        modifiedAt: DateTime.now(),
      );
      await existingGoal.delete();
      await _goalBox.add(updatedGoal);
    } else {
      // 새 목표 생성
      final newGoal = DailyGoalModel(
        date: DateTime(date.year, date.month, date.day),
        goalMinutes: goalMinutes,
        createdAt: DateTime.now(),
      );
      await _goalBox.add(newGoal);
    }
  }

  // 오늘 달성한 시간 계산 (분 단위)
  int getTodayCompletedMinutes() {
    final today = DateTime.now();
    final todayRecords = _recordBox.values.where((record) {
      return record.date.year == today.year &&
          record.date.month == today.month &&
          record.date.day == today.day;
    });

    int totalMinutes = 0;
    for (final record in todayRecords) {
      totalMinutes += record.minutes;
      // 30초 이상이면 1분으로 반올림
      if (record.seconds >= 30) {
        totalMinutes += 1;
      }
    }

    return totalMinutes;
  }

  // 특정 날짜 달성한 시간 계산
  int getCompletedMinutesForDate(DateTime date) {
    final records = _recordBox.values.where((record) {
      return record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day;
    });

    int totalMinutes = 0;
    for (final record in records) {
      totalMinutes += record.minutes;
      if (record.seconds >= 30) {
        totalMinutes += 1;
      }
    }

    return totalMinutes;
  }

  // 오늘 목표 달성률 계산 (0.0 ~ 1.0)
  double getTodayProgress() {
    final goal = getTodayGoal();
    if (goal == null || goal.goalMinutes == 0) return 0.0;

    final completed = getTodayCompletedMinutes();
    final progress = completed / goal.goalMinutes;
    return progress > 1.0 ? 1.0 : progress;
  }

  // 목표 달성 여부
  bool isTodayGoalAchieved() {
    return getTodayProgress() >= 1.0;
  }

  // 목표 삭제
  Future<void> deleteGoalForDate(DateTime date) async {
    final goal = getGoalForDate(date);
    if (goal != null) {
      await goal.delete();
    }
  }

  // 진행률 정보 객체
  DailyProgressInfo getTodayProgressInfo() {
    final goal = getTodayGoal();
    final completed = getTodayCompletedMinutes();
    final progress = getTodayProgress();

    return DailyProgressInfo(
      goalMinutes: goal?.goalMinutes ?? 0,
      completedMinutes: completed,
      progress: progress,
      isGoalSet: goal != null,
      isAchieved: isTodayGoalAchieved(),
    );
  }
}

// 진행률 정보 클래스
class DailyProgressInfo {
  final int goalMinutes;
  final int completedMinutes;
  final double progress;
  final bool isGoalSet;
  final bool isAchieved;

  DailyProgressInfo({
    required this.goalMinutes,
    required this.completedMinutes,
    required this.progress,
    required this.isGoalSet,
    required this.isAchieved,
  });

  String get goalTimeString {
    final hours = goalMinutes ~/ 60;
    final minutes = goalMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '$hours시간 $minutes분' : '$hours시간';
    }
    return '$minutes분';
  }

  String get completedTimeString {
    final hours = completedMinutes ~/ 60;
    final minutes = completedMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '$hours시간 $minutes분' : '$hours시간';
    }
    return '$minutes분';
  }

  int get remainingMinutes {
    final remaining = goalMinutes - completedMinutes;
    return remaining > 0 ? remaining : 0;
  }

  String get remainingTimeString {
    final remaining = remainingMinutes;
    final hours = remaining ~/ 60;
    final minutes = remaining % 60;
    if (hours > 0) {
      return minutes > 0 ? '$hours시간 $minutes분' : '$hours시간';
    }
    return '$minutes분';
  }
}
