import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_timer_model.dart';
import 'timer_list_dialogs.dart';
import 'timer_list_tile.dart';
import '../timer_run/timer_run_screen.dart';

class TimerListScreen extends StatefulWidget {
  const TimerListScreen({super.key});

  @override
  State<TimerListScreen> createState() => _TimerListScreenState();
}

class _TimerListScreenState extends State<TimerListScreen> {
  late Box<StudyTimerModel> _timerBox;

  @override
  void initState() {
    super.initState();
    _timerBox = Hive.box<StudyTimerModel>('timers');
  }

  void _showAddTimerDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController();
    final colorNotifier = ValueNotifier<Color>(Colors.red);

    showTimerDialog(
      context: context,
      titleController: titleController,
      durationController: durationController,
      colorNotifier: colorNotifier,
      onConfirm: () async {
        final title = titleController.text.trim();
        final duration = int.tryParse(durationController.text) ?? 0;
        final colorHex = colorNotifier.value.value;
        if (title.isNotEmpty && duration > 0) {
          final timer = StudyTimerModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            durationMinutes: duration,
            createdAt: DateTime.now(),
            colorHex: colorHex,
          );
          await _timerBox.add(timer);
          setState(() {});
          Navigator.pop(context);
        }
      },
      title: '새 타이머 추가',
      confirmText: '추가',
    );
  }

  void _showEditTimerDialog(int idx, StudyTimerModel timer) {
    final titleController = TextEditingController(text: timer.title);
    final durationController = TextEditingController(
      text: timer.durationMinutes.toString(),
    );
    final colorNotifier = ValueNotifier<Color>(
      timer.colorHex != null ? Color(timer.colorHex!) : Colors.red,
    );

    showTimerDialog(
      context: context,
      titleController: titleController,
      durationController: durationController,
      colorNotifier: colorNotifier,
      onConfirm: () async {
        final title = titleController.text.trim();
        final duration = int.tryParse(durationController.text) ?? 0;
        final colorHex = colorNotifier.value.value;
        if (title.isNotEmpty && duration > 0) {
          final newTimer = StudyTimerModel(
            id: timer.id,
            title: title,
            durationMinutes: duration,
            createdAt: timer.createdAt,
            colorHex: colorHex,
          );
          await _timerBox.putAt(idx, newTimer);
          setState(() {});
          Navigator.pop(context);
        }
      },
      title: '타이머 수정',
      confirmText: '저장',
    );
  }

  @override
  Widget build(BuildContext context) {
    final timers = _timerBox.values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('타이머 리스트')),
      body:
          timers.isEmpty
              ? const Center(child: Text('등록된 타이머가 없습니다.'))
              : ListView.builder(
                itemCount: timers.length,
                itemBuilder: (context, idx) {
                  final timer = timers[idx];
                  return TimerListTile(
                    timer: timer,
                    onEdit: () => _showEditTimerDialog(idx, timer),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('삭제 확인'),
                              content: const Text('정말로 이 타이머를 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await _timerBox.deleteAt(idx);
                        setState(() {});
                      }
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TimerRunScreen(timer: timer),
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddTimerDialog,
          backgroundColor: Colors.transparent, // gradient가 보이도록
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
    );
  }
}
