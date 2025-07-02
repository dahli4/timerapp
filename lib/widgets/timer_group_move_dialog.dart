import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/timer_group_model.dart';
import '../data/study_timer_model.dart';

Future<bool?> showTimerGroupMoveDialog(
  BuildContext context,
  StudyTimerModel timer,
) {
  final Box<TimerGroupModel> groupBox = Hive.box<TimerGroupModel>('groups');
  final Box<StudyTimerModel> timerBox = Hive.box<StudyTimerModel>('timers');

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color:
                  Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
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
                        Icons.drive_file_move_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '그룹 이동',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Timer info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(
                              timer.colorHex ?? Colors.blue.shade600.toARGB32(),
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            timer.isInfinite
                                ? Icons.all_inclusive
                                : Icons.timer_outlined,
                            color: Color(
                              timer.colorHex ?? Colors.blue.shade600.toARGB32(),
                            ),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                timer.title,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timer.isInfinite
                                    ? '무제한'
                                    : '${timer.durationMinutes}분',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Group list
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // 그룹 없음 옵션
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.folder_off_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        title: const Text('그룹 없음'),
                        subtitle: Text(
                          timer.groupId == null ? '현재 위치' : '기본 위치로 이동',
                          style: TextStyle(
                            color:
                                timer.groupId == null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface
                                        .withOpacity(0.6),
                            fontWeight:
                                timer.groupId == null
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                          ),
                        ),
                        trailing:
                            timer.groupId == null
                                ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                                : null,
                        enabled: timer.groupId != null,
                        onTap:
                            timer.groupId != null
                                ? () async {
                                  await _moveTimerToGroup(
                                    timerBox,
                                    timer,
                                    null,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                }
                                : null,
                      ),

                      // 그룹 목록
                      ...groupBox.values.map((group) {
                        final isCurrentGroup = timer.groupId == group.id;
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(
                                group.colorHex ??
                                    Colors.blue.shade500.toARGB32(),
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.folder_outlined,
                              color: Color(
                                group.colorHex ??
                                    Colors.blue.shade500.toARGB32(),
                              ),
                              size: 20,
                            ),
                          ),
                          title: Text(group.name),
                          subtitle: Text(
                            isCurrentGroup ? '현재 위치' : '이 그룹으로 이동',
                            style: TextStyle(
                              color:
                                  isCurrentGroup
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface
                                          .withOpacity(0.6),
                              fontWeight:
                                  isCurrentGroup
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                            ),
                          ),
                          trailing:
                              isCurrentGroup
                                  ? Icon(
                                    Icons.check,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )
                                  : null,
                          enabled: !isCurrentGroup,
                          onTap:
                              !isCurrentGroup
                                  ? () async {
                                    await _moveTimerToGroup(
                                      timerBox,
                                      timer,
                                      group.id,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  }
                                  : null,
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _moveTimerToGroup(
  Box<StudyTimerModel> timerBox,
  StudyTimerModel timer,
  String? newGroupId,
) async {
  final timers = timerBox.values.toList();
  final index = timers.indexWhere((t) => t.id == timer.id);

  if (index >= 0) {
    final updatedTimer = StudyTimerModel(
      id: timer.id,
      title: timer.title,
      durationMinutes: timer.durationMinutes,
      createdAt: timer.createdAt,
      colorHex: timer.colorHex,
      groupId: newGroupId,
      isInfinite: timer.isInfinite,
      isFavorite: timer.isFavorite,
    );
    await timerBox.putAt(index, updatedTimer);
  }
}
