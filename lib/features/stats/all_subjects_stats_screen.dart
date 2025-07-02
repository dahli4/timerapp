import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../data/study_timer_model.dart';
import 'subject_detail_screen.dart';

class AllSubjectsStatsScreen extends StatelessWidget {
  const AllSubjectsStatsScreen({super.key});

  String getSubject(String timerId) {
    final timerBox = Hive.box<StudyTimerModel>('timers');
    final timer = timerBox.values.firstWhere(
      (t) => t.id == timerId,
      orElse:
          () => StudyTimerModel(
            id: '',
            title: '삭제된 타이머',
            durationMinutes: 0,
            colorHex: 0xFF9E9E9E,
            createdAt: DateTime.now(),
          ),
    );
    return timer.title;
  }

  @override
  Widget build(BuildContext context) {
    final recordBox = Hive.box<StudyRecordModel>('records');
    final timerBox = Hive.box<StudyTimerModel>('timers');
    final records = recordBox.values.toList();

    // 과목별 누적 시간 계산
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

    // 시간순으로 정렬
    final sortedEntries =
        subjectMinutes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('전체 과목별 통계'), elevation: 0),
      body: SafeArea(
        child:
            sortedEntries.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '아직 공부 기록이 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '타이머를 사용해서 공부를 시작해보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      final minutes = entry.value;

                      // 타이머 정보와 색상 가져오기
                      final timer = timerBox.values.firstWhere(
                        (t) => t.id == entry.key,
                        orElse:
                            () => StudyTimerModel(
                              id: '',
                              title: '삭제된 타이머',
                              durationMinutes: 0,
                              colorHex: 0xFF9E9E9E,
                              createdAt: DateTime.now(),
                            ),
                      );
                      final subjectColor =
                          timer.colorHex != null
                              ? Color(timer.colorHex!)
                              : Colors.blue.shade600;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => SubjectDetailScreen(
                                    timerId: entry.key,
                                    subjectName: getSubject(entry.key),
                                    subjectColor: subjectColor,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // 색상 인디케이터
                                Container(
                                  width: 5,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        subjectColor,
                                        subjectColor.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                Expanded(
                                  child: Text(
                                    getSubject(entry.key),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: subjectColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    minutes >= 60
                                        ? '${minutes ~/ 60}시간 ${minutes % 60}분'
                                        : '$minutes분',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: subjectColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withOpacity(0.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
