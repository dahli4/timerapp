import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../data/study_timer_model.dart';
import 'package:intl/intl.dart';

class SubjectDetailScreen extends StatefulWidget {
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
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  bool _showAllSessions = false; // 모든 세션 표시 여부

  // 최근 세션 표시 설정
  static const int _initialSessionCount = 5; // 기본 표시 개수
  static const int _maxSessionCount = 20; // 최대 표시 개수

  @override
  Widget build(BuildContext context) {
    // 타이머가 삭제되었는지 확인
    final timerBox = Hive.box<StudyTimerModel>('timers');
    final isDeleted =
        !timerBox.values.any((timer) => timer.id == widget.timerId);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isDeleted ? '삭제된 타이머' : widget.subjectName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.subjectColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.subjectColor,
                widget.subjectColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        actions:
            isDeleted
                ? [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '이 타이머의 모든 기록 삭제',
                      onPressed: () => _showDeleteRecordsDialog(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ]
                : null,
      ),
      body: ValueListenableBuilder<Box<StudyRecordModel>>(
        valueListenable: Hive.box<StudyRecordModel>('records').listenable(),
        builder: (context, box, _) {
          final records =
              box.values
                  .where((record) => record.timerId == widget.timerId)
                  .toList()
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
              color: widget.subjectColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 60,
              color: widget.subjectColor,
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
            '$widget.subjectName 타이머를 시작해보세요!',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
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

    // 가장 긴 세션 시간 (분)
    final longestSessionMinutes =
        records.isEmpty
            ? 0
            : records
                .map((r) => r.minutes + (r.seconds ~/ 60))
                .reduce((a, b) => a > b ? a : b);

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
            longestSessionMinutes,
          ),

          const SizedBox(height: 20),

          // 최근 7일 차트
          _buildWeeklyChart(context, dailyMinutes),

          const SizedBox(height: 20),

          // 최근 세션 기록 (캘린더 날짜 범위 내, 더보기 기능)
          _buildRecentSessions(context, records),
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
    int longestMinutes,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.subjectColor,
            widget.subjectColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.9),
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
                color: Colors.white.withValues(alpha: 0.8),
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
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  '평균',
                  '${avgMinutes.toStringAsFixed(0)}분',
                  Icons.timer_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  '최고기록',
                  '$longestMinutes분',
                  Icons.emoji_events_outlined,
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
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
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
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
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
              Icon(Icons.bar_chart, color: widget.subjectColor, size: 24),
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
            height: 160, // 높이를 늘려서 overflow 방지
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
                    final dateStr = '${entry.key.month}/${entry.key.day}';

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min, // 최소 크기로 제한
                          children: [
                            // 분 텍스트
                            Text(
                              '${entry.value}분',
                              style: TextStyle(
                                fontSize: 11, // 폰트 크기 줄임
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // 바 차트
                            Container(
                              width: double.infinity,
                              height: height.clamp(4.0, 80.0), // 최대 높이 제한
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.subjectColor,
                                    widget.subjectColor.withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6), // 간격 줄임
                            // 날짜 텍스트
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11, // 폰트 크기 줄임
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
    List<StudyRecordModel> allRecords,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 최근 기록들을 최대 개수 제한
    final recentRecords = allRecords.take(_maxSessionCount).toList();

    if (recentRecords.isEmpty) {
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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.history, color: widget.subjectColor, size: 24),
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
            Text(
              '최근 학습 기록이 없습니다',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // 표시할 기록 개수 결정
    final displayRecords =
        _showAllSessions
            ? recentRecords
            : recentRecords.take(_initialSessionCount).toList();

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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
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
              Icon(Icons.history, color: widget.subjectColor, size: 24),
              const SizedBox(width: 12),
              Text(
                '최근 세션',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (recentRecords.length > _initialSessionCount)
                Text(
                  recentRecords.length >= _maxSessionCount
                      ? '최근 ${displayRecords.length}개 (최대 $_maxSessionCount개)'
                      : '${recentRecords.length}개 중 ${displayRecords.length}개',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 세션 리스트
          ...displayRecords.map((record) {
            final minutes = record.minutes + (record.seconds ~/ 60);
            final seconds = record.seconds % 60;
            final dateStr = '${record.date.month}/${record.date.day}';
            final dayName =
                ['월', '화', '수', '목', '금', '토', '일'][record.date.weekday - 1];
            final timeStr = DateFormat('a h시 mm분', 'ko_KR').format(record.date);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.subjectColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.subjectColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.subjectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.subjectColor.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? Colors.white
                                          : widget.subjectColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.subjectColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            minutes > 0 ? '$minutes분 $seconds초' : '$seconds초',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.white : widget.subjectColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // 더보기/접기 버튼
          if (recentRecords.length > _initialSessionCount)
            const SizedBox(height: 8),
          if (recentRecords.length > _initialSessionCount)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllSessions = !_showAllSessions;
                  });
                },
                icon: Icon(
                  _showAllSessions ? Icons.expand_less : Icons.expand_more,
                  color: isDark ? Colors.blue.shade300 : widget.subjectColor,
                ),
                label: Text(
                  _showAllSessions
                      ? '접기'
                      : '더보기 (${recentRecords.length - _initialSessionCount}개)',
                  style: TextStyle(
                    color: isDark ? Colors.blue.shade300 : widget.subjectColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteRecordsDialog(BuildContext context) async {
    final recordBox = Hive.box<StudyRecordModel>('records');
    final recordCount =
        recordBox.values
            .where((record) => record.timerId == widget.timerId)
            .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('기록 삭제'),
            content: Text(
              '"${widget.subjectName}"의 모든 학습 기록 $recordCount개를 삭제하시겠습니까?\n\n'
              '이 작업은 되돌릴 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // 해당 타이머의 모든 기록 삭제
      final keysToDelete = <dynamic>[];
      for (int i = 0; i < recordBox.length; i++) {
        final record = recordBox.getAt(i);
        if (record?.timerId == widget.timerId) {
          keysToDelete.add(recordBox.keyAt(i));
        }
      }

      for (final key in keysToDelete) {
        await recordBox.delete(key);
      }

      // 이전 화면으로 돌아가기
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$recordCount개의 기록을 삭제했습니다.')));
      }
    }
  }
}
