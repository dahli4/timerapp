import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_timer_model.dart';
import 'timer_list_tile.dart';
import '../timer_run/timer_run_screen.dart';
import '../timer_run/infinite_timer_run_screen.dart';
import 'timer_list_dialogs.dart';

class GroupTimersScreen extends StatefulWidget {
  final String? groupId;
  final String groupName;
  final Color groupColor;

  const GroupTimersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupColor,
  });

  @override
  State<GroupTimersScreen> createState() => _GroupTimersScreenState();
}

class _GroupTimersScreenState extends State<GroupTimersScreen> {
  late Box<StudyTimerModel> _timerBox;

  @override
  void initState() {
    super.initState();
    _timerBox = Hive.box<StudyTimerModel>('timers');
  }

  void _showAddTimerDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController();
    final colorNotifier = ValueNotifier<Color>(widget.groupColor);
    final isInfiniteNotifier = ValueNotifier<bool>(false);

    showTimerDialog(
      context: context,
      titleController: titleController,
      durationController: durationController,
      colorNotifier: colorNotifier,
      isInfiniteNotifier: isInfiniteNotifier,
      onConfirm: () async {
        final title = titleController.text.trim();
        if (title.isEmpty) return;

        final isInfinite = isInfiniteNotifier.value;
        final duration =
            isInfinite ? 0 : (int.tryParse(durationController.text) ?? 0);

        if (!isInfinite && duration <= 0) return;

        final colorHex = colorNotifier.value.toARGB32();

        final timer = StudyTimerModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          durationMinutes: duration,
          createdAt: DateTime.now(),
          colorHex: colorHex,
          groupId: widget.groupId,
          isInfinite: isInfinite,
          isFavorite: false,
        );
        await _timerBox.add(timer);
        setState(() {});
        if (mounted) {
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
      text: timer.isInfinite ? '' : timer.durationMinutes.toString(),
    );
    final colorNotifier = ValueNotifier<Color>(
      timer.colorHex != null ? Color(timer.colorHex!) : widget.groupColor,
    );
    final isInfiniteNotifier = ValueNotifier<bool>(timer.isInfinite);

    showTimerDialog(
      context: context,
      titleController: titleController,
      durationController: durationController,
      colorNotifier: colorNotifier,
      isInfiniteNotifier: isInfiniteNotifier,
      onConfirm: () async {
        final title = titleController.text.trim();
        if (title.isEmpty) return;

        final isInfinite = isInfiniteNotifier.value;
        final duration =
            isInfinite ? 0 : (int.tryParse(durationController.text) ?? 0);

        if (!isInfinite && duration <= 0) return;

        final colorHex = colorNotifier.value.toARGB32();

        final newTimer = StudyTimerModel(
          id: timer.id,
          title: title,
          durationMinutes: duration,
          createdAt: timer.createdAt,
          colorHex: colorHex,
          groupId: timer.groupId,
          isInfinite: isInfinite,
          isFavorite: timer.isFavorite,
        );
        await _timerBox.putAt(idx, newTimer);
        setState(() {});
        if (mounted) {
          Navigator.pop(context);
        }
      },
      title: '타이머 수정',
      confirmText: '저장',
    );
  }

  @override
  Widget build(BuildContext context) {
    final timers =
        widget.groupId == null
            ? _timerBox.values.where((timer) => timer.groupId == null).toList()
            : _timerBox.values
                .where((timer) => timer.groupId == widget.groupId)
                .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.groupColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.groupId == null ? Icons.timer_outlined : Icons.folder,
                color: widget.groupColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.groupName),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  timers.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: widget.groupColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                size: 64,
                                color: widget.groupColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '이 그룹에 타이머가 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '+ 버튼을 눌러 새 타이머를 추가해보세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
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
                            final originalIdx = _timerBox.values
                                .toList()
                                .indexOf(timer);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: TimerListTile(
                                timer: timer,
                                onEdit:
                                    () => _showEditTimerDialog(
                                      originalIdx,
                                      timer,
                                    ),
                                onDelete: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('타이머 삭제'),
                                          content: Text(
                                            '정말로 "${timer.title}" 타이머를 삭제하시겠습니까?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                              child: const Text('삭제'),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirmed == true) {
                                    await _timerBox.deleteAt(originalIdx);
                                    setState(() {});
                                  }
                                },
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              timer.isInfinite
                                                  ? InfiniteTimerRunScreen(
                                                    timer: timer,
                                                  )
                                                  : TimerRunScreen(
                                                    timer: timer,
                                                  ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
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
