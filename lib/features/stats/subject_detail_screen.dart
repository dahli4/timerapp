import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String timerId;
  final String subjectName;
  final Color subjectColor;

  const SubjectDetailScreen({
    super.key,
    required this.timerId,
    required this.subjectName,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(subjectName),
        backgroundColor: subjectColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ValueListenableBuilder<Box<StudyRecordModel>>(
        valueListenable: Hive.box<StudyRecordModel>('records').listenable(),
        builder: (context, box, _) {
          final records =
              box.values.where((record) => record.timerId == timerId).toList()
                ..sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬

          if (records.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildDetailContent(context, records);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 60,
              color: subjectColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '아직 기록이 없습니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$subjectName 타이머를 시작해보세요!',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    List<StudyRecordModel> records,
  ) {
    final totalMinutes = records.fold(0, (sum, r) => sum + r.minutes);
    final totalSeconds = records.fold(0, (sum, r) => sum + r.seconds);
    final adjustedMinutes = totalMinutes + (totalSeconds ~/ 60);
    final remainingSeconds = totalSeconds % 60;

    final sessionCount = records.length;
    final avgSessionMinutes =
        sessionCount > 0 ? (adjustedMinutes / sessionCount).toDouble() : 0.0;

    // 최근 7일 데이터
    final now = DateTime.now();
    final last7Days = List.generate(
      7,
      (i) => now.subtract(Duration(days: 6 - i)),
    );
    final dailyMinutes = <DateTime, int>{};

    for (final day in last7Days) {
      final dayRecords = records.where(
        (r) =>
            r.date.year == day.year &&
            r.date.month == day.month &&
            r.date.day == day.day,
      );
      final minutes = dayRecords.fold(
        0,
        (sum, r) => sum + r.minutes + (r.seconds ~/ 60),
      );
      dailyMinutes[day] = minutes;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 통계 요약
          _buildSummaryCard(
            context,
            adjustedMinutes,
            remainingSeconds,
            sessionCount,
            avgSessionMinutes,
          ),

          const SizedBox(height: 20),

          // 최근 7일 차트
          _buildWeeklyChart(context, dailyMinutes),

          const SizedBox(height: 20),

          // 최근 세션 기록
          _buildRecentSessions(context, records.take(10).toList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    int minutes,
    int seconds,
    int sessionCount,
    double avgMinutes,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [subjectColor, subjectColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: subjectColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 공부 시간',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${minutes ~/ 60}시간 ${minutes % 60}분',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (seconds > 0)
            Text(
              '$seconds초',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '총 세션',
                  '$sessionCount회',
                  Icons.play_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  '평균 세션',
                  '${avgMinutes.toStringAsFixed(0)}분',
                  Icons.timer_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(
    BuildContext context,
    Map<DateTime, int> dailyMinutes,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: subjectColor, size: 24),
              const SizedBox(width: 12),
              Text(
                '최근 7일 활동',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  dailyMinutes.entries.map((entry) {
                    final maxMinutes = dailyMinutes.values.fold(
                      0,
                      (a, b) => a > b ? a : b,
                    );
                    final height =
                        maxMinutes > 0 ? (entry.value / maxMinutes) * 80 : 0.0;
                    final dayName =
                        ['월', '화', '수', '목', '금', '토', '일'][entry.key.weekday -
                            1];

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${entry.value}분',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    subjectColor,
                                    subjectColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(
    BuildContext context,
    List<StudyRecordModel> recentRecords,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: subjectColor, size: 24),
              const SizedBox(width: 12),
              Text(
                '최근 세션',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentRecords.map((record) {
            final minutes = record.minutes + (record.seconds ~/ 60);
            final seconds = record.seconds % 60;
            final dateStr = '${record.date.month}/${record.date.day}';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: subjectColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: subjectColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    minutes > 0 ? '$minutes분 $seconds초' : '$seconds초',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: subjectColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
