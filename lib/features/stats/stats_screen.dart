import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../data/study_timer_model.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordBox = Hive.box<StudyRecordModel>('records');
    final timerBox = Hive.box<StudyTimerModel>('timers');
    final records = recordBox.values.toList();

    // 누적 시간 계산
    int totalMinutes = records.fold(0, (sum, r) => sum + r.minutes);
    int totalSeconds = records.fold(0, (sum, r) => sum + r.seconds);
    totalMinutes += totalSeconds ~/ 60;
    totalSeconds = totalSeconds % 60;

    // 오늘 공부 시간
    final now = DateTime.now();
    final todayRecords = records.where(
      (r) =>
          r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day,
    );
    int todayMinutes = todayRecords.fold(0, (sum, r) => sum + r.minutes);
    int todaySeconds = todayRecords.fold(0, (sum, r) => sum + r.seconds);
    todayMinutes += todaySeconds ~/ 60;
    todaySeconds = todaySeconds % 60;

    // 과목별 누적 시간
    final Map<String, int> subjectMinutes = {};
    final Map<String, int> subjectSeconds = {};
    for (final r in records) {
      subjectMinutes[r.timerId] = (subjectMinutes[r.timerId] ?? 0) + r.minutes;
      subjectSeconds[r.timerId] = (subjectSeconds[r.timerId] ?? 0) + r.seconds;
    }
    // 초를 분으로 환산
    subjectSeconds.forEach((id, sec) {
      subjectMinutes[id] = (subjectMinutes[id] ?? 0) + sec ~/ 60;
      subjectSeconds[id] = sec % 60;
    });

    // 최근 7일 공부 시간
    final List<DateTime> last7Days = List.generate(
      7,
      (i) => now.subtract(Duration(days: 6 - i)),
    );
    final List<int> last7Minutes = List.generate(7, (i) {
      final day = last7Days[i];
      final dayRecords = records.where(
        (r) =>
            r.date.year == day.year &&
            r.date.month == day.month &&
            r.date.day == day.day,
      );
      int min = dayRecords.fold(0, (sum, r) => sum + r.minutes);
      int sec = dayRecords.fold(0, (sum, r) => sum + r.seconds);
      min += sec ~/ 60;
      return min;
    });

    // 최고 공부일
    final Map<String, int> dayMinutes = {};
    final Map<String, int> daySeconds = {};
    for (final r in records) {
      final key = '${r.date.year}-${r.date.month}-${r.date.day}';
      dayMinutes[key] = (dayMinutes[key] ?? 0) + r.minutes;
      daySeconds[key] = (daySeconds[key] ?? 0) + r.seconds;
    }
    String bestDay = '';
    int bestMinutes = 0;
    int bestSeconds = 0;
    dayMinutes.forEach((key, min) {
      final sec = daySeconds[key] ?? 0;
      final totalMin = min + sec ~/ 60;
      if (totalMin > bestMinutes) {
        bestMinutes = totalMin;
        bestSeconds = sec % 60;
        bestDay = key;
      }
    });

    // 과목명 매핑
    String getSubject(String id) {
      final timer = timerBox.values.firstWhere(
        (t) => t.id == id,
        orElse:
            () => StudyTimerModel(
              id: '',
              title: '알 수 없음',
              durationMinutes: 0,
              createdAt: DateTime.now(),
            ),
      );
      return timer.title;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 누적 시간
            Text(
              '총 공부 ${totalMinutes ~/ 60}시간 ${totalMinutes % 60}분 $totalSeconds초',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 28), // 간격 넓힘
            // 오늘 공부
            Text(
              '오늘 ${todayMinutes ~/ 60}시간 ${todayMinutes % 60}분 $todaySeconds초',
              style: const TextStyle(fontSize: 18, color: Colors.indigo),
            ),
            const SizedBox(height: 32), // 간격 넓힘
            // 과목별 누적 시간 (Bar)
            const Text(
              '과목별 누적 시간',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...subjectMinutes.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        getSubject(e.key),
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    Text(
                      '${e.value ~/ 60}시간 ${e.value % 60}분 ${subjectSeconds[e.key]}초',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36), // 간격 넓힘
            // 최근 7일 공부량 (Bar)
            const Text(
              '최근 7일 공부량',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final min = last7Minutes[i];
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: min.toDouble() * 2, // 1분=2px
                          width: 18,
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${last7Days[i].month}/${last7Days[i].day}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text('$min분', style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 36), // 간격 넓힘
            // 최고 공부일
            Text(
              bestDay.isNotEmpty
                  ? '가장 오래 공부한 날: $bestDay (${bestMinutes ~/ 60}시간 ${bestMinutes % 60}분 $bestSeconds초)'
                  : '아직 기록 없음',
              style: const TextStyle(fontSize: 16, color: Colors.deepOrange),
            ),
          ],
        ),
      ),
    );
  }
}
