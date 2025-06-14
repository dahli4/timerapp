import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_timer_model.dart';
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

  Future<void> showTimerDialog({
    required BuildContext context,
    required TextEditingController titleController,
    required TextEditingController durationController,
    required ValueNotifier<Color> colorNotifier,
    required VoidCallback onConfirm,
    required String title,
    String confirmText = '확인',
  }) {
    final colors = [
      Colors.red.shade500,
      Colors.orange.shade500,
      Colors.amber.shade500,
      Colors.green.shade500,
      Colors.blue.shade500,
      Colors.indigo.shade500,
      Colors.purple.shade500,
      Colors.pink.shade500,
      Colors.teal.shade500,
      Colors.cyan.shade500,
    ];

    ValueNotifier<String> durationDisplayNotifier = ValueNotifier(
      durationController.text.isEmpty ? '' : durationController.text,
    );

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        const keyboardDialogGap = 10.0; // 키보드와 다이얼로그 사이 고정 간격
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: keyboardHeight > 0 ? 20 : 80,
            bottom: keyboardHeight > 0 ? keyboardDialogGap : 80,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color:
                  Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 8,
                      top: 16,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목 입력
                        Text(
                          '이름',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: '타이머 이름',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 시간 설정
                        Text(
                          '시간',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<String>(
                          valueListenable: durationDisplayNotifier,
                          builder:
                              (context, duration, _) => _TimeSelectorWidget(
                                durationController: durationController,
                                durationDisplayNotifier:
                                    durationDisplayNotifier,
                              ),
                        ),

                        const SizedBox(height: 20),

                        // 색상 선택
                        Text(
                          '색상',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<Color>(
                          valueListenable: colorNotifier,
                          builder:
                              (context, selectedColor, _) => Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: selectedColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: selectedColor.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '선택된 색상',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 5,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 1,
                                          ),
                                      itemCount: colors.length,
                                      itemBuilder: (context, index) {
                                        final color = colors[index];
                                        final isSelected =
                                            selectedColor == color;
                                        return _ColorButtonWidget(
                                          color: color,
                                          isSelected: isSelected,
                                          onTap:
                                              () => colorNotifier.value = color,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              '취소',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                            ),
                            child: Text(
                              confirmText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddTimerDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController();
    final colorNotifier = ValueNotifier<Color>(
      const Color(0xFF5A9FD4),
    ); // 라이트블루

    showTimerDialog(
      context: context,
      titleController: titleController,
      durationController: durationController,
      colorNotifier: colorNotifier,
      onConfirm: () async {
        final title = titleController.text.trim();
        final duration = int.tryParse(durationController.text) ?? 0;
        final colorHex = colorNotifier.value.toARGB32();
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
      timer.colorHex != null
          ? Color(timer.colorHex!)
          : const Color(0xFF5A9FD4), // 라이트블루
    );

    showTimerDialog(
      context: context,
      titleController: titleController,
      durationController: durationController,
      colorNotifier: colorNotifier,
      onConfirm: () async {
        final title = titleController.text.trim();
        final duration = int.tryParse(durationController.text) ?? 0;
        final colorHex = colorNotifier.value.toARGB32();
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
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
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

class _TimeSelectorWidget extends StatelessWidget {
  final TextEditingController durationController;
  final ValueNotifier<String> durationDisplayNotifier;

  const _TimeSelectorWidget({
    required this.durationController,
    required this.durationDisplayNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTimePicker(context),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: durationDisplayNotifier,
                  builder:
                      (context, duration, _) =>
                          _buildTimeText(context, duration),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeText(BuildContext context, String duration) {
    final minutes = int.tryParse(duration) ?? 0;
    if (minutes == 0) {
      return Text(
        '시간 선택',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    String displayText;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      displayText =
          remainingMinutes > 0 ? '$hours시간 $remainingMinutes분' : '$hours시간';
    } else {
      displayText = '$minutes분';
    }

    return Text(
      displayText,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    Duration initial = Duration(
      minutes:
          durationController.text.isEmpty
              ? 0
              : (int.tryParse(durationController.text) ?? 0),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        Duration temp = initial;
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '시간 선택',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: initial,
                  onTimerDurationChanged: (Duration value) => temp = value,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    durationController.text = temp.inMinutes.toString();
                    durationDisplayNotifier.value = temp.inMinutes.toString();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColorButtonWidget extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButtonWidget({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: isSelected ? 10 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: Transform.scale(
          scale: isSelected ? 1.0 : 0.9,
          child:
              isSelected
                  ? Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(Icons.check, color: color, size: 10),
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}
