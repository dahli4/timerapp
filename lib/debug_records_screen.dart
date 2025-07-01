import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/study_record_model.dart';
import '../data/study_timer_model.dart';

class DebugRecordsScreen extends StatefulWidget {
  const DebugRecordsScreen({super.key});

  @override
  State<DebugRecordsScreen> createState() => _DebugRecordsScreenState();
}

class _DebugRecordsScreenState extends State<DebugRecordsScreen> {
  @override
  Widget build(BuildContext context) {
    final recordBox = Hive.box<StudyRecordModel>('records');
    final timerBox = Hive.box<StudyTimerModel>('timers');
    final records = recordBox.values.toList();
    final timers = timerBox.values.toList();

    // 최근 20개 기록만 표시
    final recentRecords = records.reversed.take(20).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 디버그'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              // 모든 기록 삭제 확인
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('모든 기록 삭제'),
                      content: const Text('정말로 모든 기록을 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
              );
              if (confirmed == true) {
                await recordBox.clear();
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 통계 요약
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '전체 기록: ${records.length}개',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '총 시간: ${_calculateTotalTime(records)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 기록 목록
          Expanded(
            child: ListView.builder(
              itemCount: recentRecords.length,
              itemBuilder: (context, index) {
                final record = recentRecords[index];
                final timer = timers.firstWhere(
                  (t) => t.id == record.timerId,
                  orElse:
                      () => StudyTimerModel(
                        id: 'unknown',
                        title: '삭제된 타이머',
                        durationMinutes: 0,
                        createdAt: DateTime.now(),
                      ),
                );

                return ListTile(
                  title: Text(timer.title),
                  subtitle: Text(
                    '${record.date.month}/${record.date.day} ${record.date.hour}:${record.date.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: Text(
                    '${record.minutes}분 ${record.seconds}초',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    // 상세 정보 표시
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(timer.title),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('타이머 ID: ${record.timerId}'),
                                Text('날짜: ${record.date}'),
                                Text('분: ${record.minutes}'),
                                Text('초: ${record.seconds}'),
                                Text(
                                  '총 초: ${record.minutes * 60 + record.seconds}',
                                ),
                                Text('타이머 설정: ${timer.durationMinutes}분'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTotalTime(List<StudyRecordModel> records) {
    int totalMinutes = records.fold(0, (sum, r) => sum + r.minutes);
    int totalSeconds = records.fold(0, (sum, r) => sum + r.seconds);
    totalMinutes += totalSeconds ~/ 60;
    totalSeconds = totalSeconds % 60;

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '$hours시간 $minutes분 $totalSeconds초';
    } else {
      return '$minutes분 $totalSeconds초';
    }
  }
}
