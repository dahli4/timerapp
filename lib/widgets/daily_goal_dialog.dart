import 'package:flutter/material.dart';
import '../utils/daily_goal_service.dart';

class DailyGoalDialog extends StatefulWidget {
  final DateTime? date;

  const DailyGoalDialog({super.key, this.date});

  @override
  State<DailyGoalDialog> createState() => _DailyGoalDialogState();
}

class _DailyGoalDialogState extends State<DailyGoalDialog> {
  final DailyGoalService _goalService = DailyGoalService();
  late int _selectedHours;
  late int _selectedMinutes;

  @override
  void initState() {
    super.initState();
    final targetDate = widget.date ?? DateTime.now();
    final existingGoal = _goalService.getGoalForDate(targetDate);

    if (existingGoal != null) {
      _selectedHours = existingGoal.goalMinutes ~/ 60;
      _selectedMinutes = existingGoal.goalMinutes % 60;
    } else {
      _selectedHours = 2; // 기본값 2시간
      _selectedMinutes = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetDate = widget.date ?? DateTime.now();
    final isToday = _isSameDate(targetDate, DateTime.now());
    final title = isToday ? '오늘의 목표 설정' : '목표 설정';

    // 라이트블루 색상 정의
    const lightBlue = Color(0xFF42A5F5);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.flag_outlined, color: lightBlue, size: 24),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isToday)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${targetDate.month}월 ${targetDate.day}일',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),

          // 현재 선택된 시간 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: lightBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: lightBlue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '선택된 시간: ${_formatSelectedTime()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: lightBlue,
              ),
            ),
          ),

          // 빠른 선택 버튼들 (고정 크기)
          Text(
            '목표 시간을 선택하세요',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // 3x2 그리드로 고정 크기 버튼들
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildTimeButton('1시간', 1, 0),
                _buildTimeButton('2시간', 2, 0),
                _buildTimeButton('3시간', 3, 0),
                _buildTimeButton('4시간', 4, 0),
                _buildTimeButton('5시간', 5, 0),
                _buildTimeButton('6시간', 6, 0),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _canSave() ? _saveGoal : null,
          child: const Text('저장'),
        ),
      ],
    );
  }

  Widget _buildTimeButton(String label, int hours, int minutes) {
    final isSelected = _selectedHours == hours && _selectedMinutes == minutes;
    const lightBlue = Color(0xFF42A5F5);

    return SizedBox(
      width: 80,
      height: 40,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedHours = hours;
            _selectedMinutes = minutes;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? lightBlue : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : lightBlue,
          side: BorderSide(color: lightBlue, width: isSelected ? 2 : 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatSelectedTime() {
    if (_selectedHours > 0 && _selectedMinutes > 0) {
      return '$_selectedHours시간 $_selectedMinutes분';
    } else if (_selectedHours > 0) {
      return '$_selectedHours시간';
    } else if (_selectedMinutes > 0) {
      return '$_selectedMinutes분';
    } else {
      return '시간을 선택해주세요';
    }
  }

  bool _canSave() {
    return _selectedHours > 0 || _selectedMinutes > 0;
  }

  Future<void> _saveGoal() async {
    if (!_canSave()) return;

    final targetDate = widget.date ?? DateTime.now();
    final totalMinutes = (_selectedHours * 60) + _selectedMinutes;

    try {
      await _goalService.setDailyGoal(targetDate, totalMinutes);

      if (mounted) {
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('목표가 설정되었습니다: ${_formatSelectedTime()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('목표 설정 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
