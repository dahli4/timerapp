import 'package:flutter/material.dart';
import '../../data/study_timer_model.dart';

class TimerListTile extends StatelessWidget {
  final StudyTimerModel timer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const TimerListTile({
    super.key,
    required this.timer,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = timer.colorHex != null ? Color(timer.colorHex!) : Colors.red;
    return ListTile(
      leading: Container(
        width: 8,
        height: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(timer.title),
      subtitle: Text(
        timer.durationMinutes >= 60
            ? (() {
              final h = timer.durationMinutes ~/ 60;
              final m = timer.durationMinutes % 60;
              return m > 0 ? '$h시간 $m분' : '$h시간';
            })()
            : '${timer.durationMinutes}분',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      minLeadingWidth: 16,
    );
  }
}
