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
      appBar: AppBar(title: const Text('학습 타이머')),
      body:
          timers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '등록된 타이머가 없습니다',
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
                      '+ 버튼을 눌러 새 타이머를 추가해보세요',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListView.builder(
                  itemCount: timers.length,
                  itemBuilder: (context, idx) {
                    final timer = timers[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: TimerListTile(
                        timer: timer,
                        onEdit: () => _showEditTimerDialog(idx, timer),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    '타이머 삭제',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    '정말로 "${timer.title}" 타이머를 삭제하시겠습니까?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('취소'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
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
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimerDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}
