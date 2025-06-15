import 'package:hive_flutter/hive_flutter.dart';
import '../data/study_record_model.dart';
import '../data/study_timer_model.dart';
import 'dart:math';

class DummyDataHelper {
  static Future<void> generateDummyData() async {
    final recordBox = Hive.box<StudyRecordModel>('records');
    final timerBox = Hive.box<StudyTimerModel>('timers');

    // 기존 데이터가 있는지 확인 (더미데이터는 한번만 생성)
    final hasData = recordBox.isNotEmpty && timerBox.length >= 3;
    if (hasData) return;

    // 더미 타이머들 생성 (이미 있다면 기존 것 사용)
    List<StudyTimerModel> dummyTimers = [];

    if (timerBox.isEmpty) {
      final timers = [
        StudyTimerModel(
          id: 'math_timer',
          title: '수학',
          durationMinutes: 25,
          colorHex: 0xFF4A90E2, // 파랑
          createdAt: DateTime(2025, 6, 1),
        ),
        StudyTimerModel(
          id: 'english_timer',
          title: '영어',
          durationMinutes: 30,
          colorHex: 0xFF7ED321, // 초록
          createdAt: DateTime(2025, 6, 1),
        ),
        StudyTimerModel(
          id: 'science_timer',
          title: '과학',
          durationMinutes: 45,
          colorHex: 0xFFE94B3C, // 빨강
          createdAt: DateTime(2025, 6, 2),
        ),
        StudyTimerModel(
          id: 'history_timer',
          title: '역사',
          durationMinutes: 20,
          colorHex: 0xFF9013FE, // 보라
          createdAt: DateTime(2025, 6, 3),
        ),
        StudyTimerModel(
          id: 'korean_timer',
          title: '국어',
          durationMinutes: 35,
          colorHex: 0xFFFF9500, // 주황
          createdAt: DateTime(2025, 6, 3),
        ),
      ];

      for (final timer in timers) {
        await timerBox.add(timer);
        dummyTimers.add(timer);
      }
    } else {
      dummyTimers = timerBox.values.toList();
    }

    // 2025년 6월 더미 기록 생성 (1일부터 15일까지)
    final random = Random(42); // 시드를 고정해서 항상 같은 데이터 생성

    for (int day = 1; day <= 15; day++) {
      // 하루에 2-5개의 학습 기록 생성
      final recordsPerDay = 2 + random.nextInt(4);

      for (int i = 0; i < recordsPerDay; i++) {
        final timer = dummyTimers[random.nextInt(dummyTimers.length)];

        // 시간 범위 설정 (아침 9시부터 밤 10시까지)
        final hour = 9 + random.nextInt(13);
        final minute = random.nextInt(60);
        final studyDate = DateTime(2025, 6, day, hour, minute);

        // 학습 시간 (1분에서 90분 사이, 대부분 15-60분)
        int minutes;
        final timeType = random.nextInt(100);
        if (timeType < 5) {
          // 5% 확률로 1-3분 (통계에 안들어감)
          minutes = 1 + random.nextInt(3);
        } else if (timeType < 20) {
          // 15% 확률로 짧은 시간 (5-15분)
          minutes = 5 + random.nextInt(11);
        } else if (timeType < 70) {
          // 50% 확률로 보통 시간 (15-45분)
          minutes = 15 + random.nextInt(31);
        } else {
          // 30% 확률로 긴 시간 (45-90분)
          minutes = 45 + random.nextInt(46);
        }

        final seconds = random.nextInt(60);

        await recordBox.add(
          StudyRecordModel(
            timerId: timer.id,
            date: studyDate,
            minutes: minutes,
            seconds: seconds,
          ),
        );
      }
    }

    print('더미 데이터 생성 완료: ${timerBox.length}개 타이머, ${recordBox.length}개 기록');
  }

  static Future<void> clearAllData() async {
    final recordBox = Hive.box<StudyRecordModel>('records');
    final timerBox = Hive.box<StudyTimerModel>('timers');

    await recordBox.clear();
    await timerBox.clear();

    print('모든 데이터 삭제 완료');
  }
}
