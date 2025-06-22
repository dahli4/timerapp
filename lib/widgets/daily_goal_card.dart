import 'package:flutter/material.dart';
import '../utils/daily_goal_service.dart';

class DailyGoalCard extends StatefulWidget {
  final VoidCallback? onTap;

  const DailyGoalCard({super.key, this.onTap});

  @override
  State<DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<DailyGoalCard> {
  final DailyGoalService _goalService = DailyGoalService();

  @override
  Widget build(BuildContext context) {
    final progressInfo = _goalService.getTodayProgressInfo();

    if (!progressInfo.isGoalSet) {
      return _buildNoGoalCard();
    }

    return _buildProgressCard(progressInfo);
  }

  Widget _buildNoGoalCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Theme.of(context).colorScheme.surface : Colors.blue.shade50;
    final iconColor = isDark ? Colors.blue.shade300 : const Color(0xFF87CEEB);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      color: backgroundColor,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient:
                isDark
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade700.withValues(alpha: 0.08),
                        Colors.blue.shade600.withValues(alpha: 0.04),
                      ],
                    )
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 32, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 목표를 설정해보세요',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '목표 시간을 설정하고 성취감을 느껴보세요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline, color: iconColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(DailyProgressInfo info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightBlue = isDark ? Colors.blue.shade300 : const Color(0xFF87CEEB);
    final isAchieved = info.isAchieved;
    final progressColor = isAchieved ? Colors.green : lightBlue;
    final backgroundColor =
        isDark ? Theme.of(context).colorScheme.surface : Colors.blue.shade50;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      color: backgroundColor,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient:
                isDark
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade700.withValues(alpha: 0.08),
                        Colors.blue.shade600.withValues(alpha: 0.04),
                      ],
                    )
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAchieved ? Icons.emoji_events : Icons.flag,
                          color: progressColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '오늘의 목표',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (isAchieved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '달성!',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // 진행률 바
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: info.progress,
                        backgroundColor:
                            isDark ? Colors.grey[700] : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(info.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 시간 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '완료: ${info.completedTimeString}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '목표: ${info.goalTimeString}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (!isAchieved && info.remainingMinutes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lightBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: lightBlue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${info.remainingTimeString} 남음',
                          style: TextStyle(
                            color:
                                isDark
                                    ? Colors.blue.shade200
                                    : Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
