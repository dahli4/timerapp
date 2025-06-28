import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../data/study_timer_model.dart';
import 'subject_detail_screen.dart';
import 'all_subjects_stats_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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

    // 연속 학습일 계산
    int currentStreak = _calculateCurrentStreak(records);

    // 현재 시간
    final now = DateTime.now();

    // 오늘 공부 시간 계산
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

    // 이번 달 공부 시간
    final thisMonthRecords = records.where(
      (r) => r.date.year == now.year && r.date.month == now.month,
    );
    int thisMonthMinutes = thisMonthRecords.fold(
      0,
      (sum, r) => sum + r.minutes,
    );
    int thisMonthSeconds = thisMonthRecords.fold(
      0,
      (sum, r) => sum + r.seconds,
    );
    thisMonthMinutes += thisMonthSeconds ~/ 60;
    thisMonthSeconds = thisMonthSeconds % 60;

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
              title: '삭제된 타이머',
              durationMinutes: 0,
              colorHex: 0xFF9E9E9E, // 회색으로 설정
              createdAt: DateTime.now(),
            ),
      );
      return timer.title;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 첫 번째 줄: 총 학습시간 + 오늘 공부
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.timer,
                      title: '총 학습시간',
                      value:
                          totalMinutes >= 60
                              ? '${totalMinutes ~/ 60}시간 ${totalMinutes % 60}분'
                              : '$totalMinutes분',
                      subtitle: '${records.length}개 세션',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.today,
                      title: '오늘 학습',
                      value:
                          todayMinutes >= 60
                              ? '${todayMinutes ~/ 60}시간 ${todayMinutes % 60}분'
                              : '$todayMinutes분',
                      subtitle: todayMinutes > 0 ? '계속 화이팅!' : '시작해볼까요?',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 두 번째 줄: 연속 학습일 + 이번 달 학습
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_fire_department,
                      title: '연속 학습일',
                      value: '$currentStreak일',
                      subtitle: currentStreak > 0 ? '꾸준히 공부 중!' : '오늘부터 시작!',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.calendar_month,
                      title: '이번 달',
                      value:
                          thisMonthMinutes >= 60
                              ? '${thisMonthMinutes ~/ 60}시간 ${thisMonthMinutes % 60}분'
                              : '$thisMonthMinutes분',
                      subtitle: '${now.month}월 학습량',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 과목별 통계 카드
              _buildSubjectStatsCard(
                subjectMinutes,
                subjectSeconds,
                getSubject,
                timerBox,
              ),
              const SizedBox(height: 20),

              // 최근 7일 차트 카드
              _buildWeeklyChartCard(last7Days, last7Minutes),
              const SizedBox(height: 20),

              // 최고 기록 카드 (독립)
              _buildBestDayCard(bestDay, bestMinutes, bestSeconds),
              const SizedBox(height: 20),

              // 목표 달성률 개별 카드 (임시로 숨김)
              // _buildGoalAchievementCard(records),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBestDayCard(String bestDay, int bestMinutes, int bestSeconds) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color:
          Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.03),
              Colors.amber.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.star_outlined,
                color: Colors.amber.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최고 기록',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bestDay.isNotEmpty ? bestDay : '아직 기록 없음',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (bestDay.isNotEmpty)
                    Text(
                      '${bestMinutes ~/ 60}시간 ${bestMinutes % 60}분',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectStatsCard(
    Map<String, int> subjectMinutes,
    Map<String, int> subjectSeconds,
    String Function(String) getSubject,
    Box<StudyTimerModel> timerBox,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AllSubjectsStatsScreen(),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color:
            Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.subject_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '과목별 누적 시간',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (subjectMinutes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '아직 공부 기록이 없습니다.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // 상위 5개만 표시
                ...(subjectMinutes.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .take(5)
                    .map((e) {
                      final minutes = e.value;
                      final seconds = subjectSeconds[e.key] ?? 0;

                      // 타이머 정보와 색상 가져오기
                      final timer = timerBox.values.firstWhere(
                        (t) => t.id == e.key,
                        orElse:
                            () => StudyTimerModel(
                              id: '',
                              title: '삭제된 타이머',
                              durationMinutes: 0,
                              colorHex: 0xFF9E9E9E, // 회색으로 설정
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
                                    timerId: e.key,
                                    subjectName: getSubject(e.key),
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
                                ).colorScheme.onSurface.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // 색상 인디케이터 추가
                                Container(
                                  width: 5,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        subjectColor,
                                        subjectColor.withValues(alpha: 0.7),
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
                                    getSubject(e.key),
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
                                const SizedBox(width: 12), // 여백 추가
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    minutes >= 60
                                        ? '${minutes ~/ 60}시간 ${minutes % 60}분'
                                        : '$minutes분 ${seconds % 60}초',
                                    style: TextStyle(
                                      fontSize: 12, // 크기 줄임
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChartCard(
    List<DateTime> last7Days,
    List<int> last7Minutes,
  ) {
    final maxMinutes =
        last7Minutes.isEmpty
            ? 60
            : last7Minutes.reduce((a, b) => a > b ? a : b);
    final chartHeight = maxMinutes > 0 ? maxMinutes.toDouble() : 60.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color:
          Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.teal.withValues(alpha: 0.03),
              Colors.teal.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bar_chart_outlined,
                    color: Colors.teal.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '최근 7일 공부량',
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
              height: 170, // 높이를 늘려서 overflow 방지
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final minutes = last7Minutes[i];
                  final height =
                      chartHeight > 0 ? (minutes / chartHeight) * 120 : 0.0;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height.clamp(4.0, 120.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors:
                                    minutes > 0
                                        ? [
                                          Colors.teal.shade400,
                                          Colors.teal.shade600,
                                        ]
                                        : [
                                          Colors.grey.shade300,
                                          Colors.grey.shade400,
                                        ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${last7Days[i].month}/${last7Days[i].day}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '$minutes분',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  minutes > 0
                                      ? Colors.teal.shade600
                                      : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 연속 학습일 계산
  int _calculateCurrentStreak(List<StudyRecordModel> records) {
    if (records.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 날짜별로 학습 기록이 있는지 확인
    final studyDates = <DateTime>{};
    for (final record in records) {
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      studyDates.add(recordDate);
    }

    int streak = 0;
    DateTime checkDate = today;

    // 오늘부터 역순으로 확인
    while (studyDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // 개별 통계 카드
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.02),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
