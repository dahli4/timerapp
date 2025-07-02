import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../data/daily_goal_model.dart';

class GoalAchievementDetailScreen extends StatefulWidget {
  const GoalAchievementDetailScreen({super.key});

  @override
  State<GoalAchievementDetailScreen> createState() =>
      _GoalAchievementDetailScreenState();
}

class _GoalAchievementDetailScreenState
    extends State<GoalAchievementDetailScreen> {
  final Box<StudyRecordModel> _recordBox = Hive.box<StudyRecordModel>(
    'records',
  );

  @override
  Widget build(BuildContext context) {
    // 최근 30일 목표 달성률 계산
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final achievementData = _calculateAchievementData(thirtyDaysAgo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('목표 달성률'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 전체 통계 카드
              _buildOverallStatsCard(achievementData),
              const SizedBox(height: 20),

              // 최근 7일 상세 목표 달성률
              _buildRecentDaysCard(achievementData),
              const SizedBox(height: 20),

              // 월별 통계
              _buildMonthlyStatsCard(achievementData),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateAchievementData(DateTime fromDate) {
    final records = _recordBox.values.toList();
    final goals = Hive.box<DailyGoalModel>('daily_goals').values.toList();

    Map<String, int> dailyMinutes = {};
    Map<String, int> dailyGoals = {};
    List<double> achievementRates = [];

    // 일별 학습 시간 계산
    for (var record in records) {
      if (record.date.isAfter(fromDate)) {
        final dateKey =
            '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
        dailyMinutes[dateKey] =
            (dailyMinutes[dateKey] ?? 0) +
            record.minutes +
            (record.seconds / 60).round();
      }
    }

    // 일별 목표 시간 계산
    for (var goal in goals) {
      if (goal.date.isAfter(fromDate)) {
        final dateKey =
            '${goal.date.year}-${goal.date.month.toString().padLeft(2, '0')}-${goal.date.day.toString().padLeft(2, '0')}';
        dailyGoals[dateKey] = goal.goalMinutes;
      }
    }

    // 달성률 계산
    int achievedDays = 0;
    int totalDaysWithGoals = 0;

    for (var dateKey in dailyGoals.keys) {
      final studiedMinutes = dailyMinutes[dateKey] ?? 0;
      final goalMinutes = dailyGoals[dateKey]!;

      totalDaysWithGoals++;
      final achievementRate = (studiedMinutes / goalMinutes * 100).clamp(
        0.0,
        100.0,
      );
      achievementRates.add(achievementRate);

      if (studiedMinutes >= goalMinutes) {
        achievedDays++;
      }
    }

    final averageAchievement =
        achievementRates.isEmpty
            ? 0.0
            : achievementRates.reduce((a, b) => a + b) /
                achievementRates.length;

    return {
      'averageAchievement': averageAchievement,
      'achievedDays': achievedDays,
      'totalDaysWithGoals': totalDaysWithGoals,
      'dailyMinutes': dailyMinutes,
      'dailyGoals': dailyGoals,
      'achievementRates': achievementRates,
    };
  }

  Widget _buildOverallStatsCard(Map<String, dynamic> data) {
    final averageAchievement = data['averageAchievement'] as double;
    final achievedDays = data['achievedDays'] as int;
    final totalDaysWithGoals = data['totalDaysWithGoals'] as int;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
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
                Icon(
                  Icons.track_changes,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '전체 목표 달성률',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '평균 달성률',
                    '${averageAchievement.toStringAsFixed(1)}%',
                    Icons.percent,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    '목표 달성일',
                    '$achievedDays/$totalDaysWithGoals일',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
              ],
            ),
            if (totalDaysWithGoals > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: achievedDays / totalDaysWithGoals,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  achievedDays / totalDaysWithGoals >= 0.7
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(achievedDays / totalDaysWithGoals * 100).toStringAsFixed(1)}% 달성',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDaysCard(Map<String, dynamic> data) {
    final dailyMinutes = data['dailyMinutes'] as Map<String, int>;
    final dailyGoals = data['dailyGoals'] as Map<String, int>;

    // 최근 7일 데이터 준비
    final List<Map<String, dynamic>> recentDays = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final studiedMinutes = dailyMinutes[dateKey] ?? 0;
      final goalMinutes = dailyGoals[dateKey];

      recentDays.add({
        'date': date,
        'dateKey': dateKey,
        'studiedMinutes': studiedMinutes,
        'goalMinutes': goalMinutes,
        'achievementRate':
            goalMinutes != null && goalMinutes > 0
                ? (studiedMinutes / goalMinutes * 100).clamp(0, 100)
                : null,
      });
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '최근 7일 목표 달성률',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentDays.map((day) => _buildDayItem(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem(Map<String, dynamic> day) {
    final date = day['date'] as DateTime;
    final studiedMinutes = day['studiedMinutes'] as int;
    final goalMinutes = day['goalMinutes'] as int?;
    final achievementRate = day['achievementRate'] as double?;

    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = dayNames[date.weekday - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Text(
                  '${date.month}/${date.day}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  dayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      goalMinutes != null ? '목표: $goalMinutes분' : '목표 없음',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '학습: $studiedMinutes분',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (achievementRate != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (achievementRate / 100).clamp(0, 1),
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achievementRate >= 100
                          ? Colors.green
                          : achievementRate >= 70
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievementRate.toStringAsFixed(1)}% 달성',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          achievementRate >= 100
                              ? Colors.green
                              : achievementRate >= 70
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsCard(Map<String, dynamic> data) {
    // 이번 달과 지난 달 통계 계산
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '월별 목표 달성 통계',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMonthCard('이번 달', thisMonth, data)),
                const SizedBox(width: 16),
                Expanded(child: _buildMonthCard('지난 달', lastMonth, data)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(
    String title,
    DateTime month,
    Map<String, dynamic> data,
  ) {
    final dailyMinutes = data['dailyMinutes'] as Map<String, int>;
    final dailyGoals = data['dailyGoals'] as Map<String, int>;

    int totalStudied = 0;
    int totalGoals = 0;
    int achievedDays = 0;
    int totalDaysWithGoals = 0;

    for (var entry in dailyGoals.entries) {
      final parts = entry.key.split('-');
      final dateYear = int.parse(parts[0]);
      final dateMonth = int.parse(parts[1]);

      if (dateYear == month.year && dateMonth == month.month) {
        totalDaysWithGoals++;
        totalGoals += entry.value;

        final studiedMinutes = dailyMinutes[entry.key] ?? 0;
        totalStudied += studiedMinutes;

        if (studiedMinutes >= entry.value) {
          achievedDays++;
        }
      }
    }

    final achievementRate =
        totalGoals > 0 ? (totalStudied / totalGoals * 100).clamp(0, 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (totalDaysWithGoals > 0) ...[
            Text(
              '${achievementRate.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: achievementRate >= 70 ? Colors.green : Colors.orange,
              ),
            ),
            Text(
              '$achievedDays/$totalDaysWithGoals일 달성',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ] else ...[
            Text(
              '데이터 없음',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
