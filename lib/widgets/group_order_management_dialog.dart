import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/timer_group_model.dart';

Future<bool?> showGroupOrderManagementDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return const GroupOrderManagementDialog();
    },
  );
}

class GroupOrderManagementDialog extends StatefulWidget {
  const GroupOrderManagementDialog({super.key});

  @override
  State<GroupOrderManagementDialog> createState() =>
      _GroupOrderManagementDialogState();
}

class _GroupOrderManagementDialogState
    extends State<GroupOrderManagementDialog> {
  final Box<TimerGroupModel> _groupBox = Hive.box<TimerGroupModel>('groups');
  late List<TimerGroupModel> _groups;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    final groups = _groupBox.values.toList();

    // 기존 그룹에 order가 null이거나 0 미만인 경우 마이그레이션
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (group.order == null || group.order! < 0) {
        final updatedGroup = TimerGroupModel(
          id: group.id,
          name: group.name,
          colorHex: group.colorHex,
          createdAt: group.createdAt,
          modifiedAt: DateTime.now(),
          order: i,
        );
        group.delete();
        _groupBox.add(updatedGroup);
      }
    }

    // 순서대로 정렬 (null safe)
    _groups =
        _groupBox.values.toList()
          ..sort((a, b) => a.safeOrder.compareTo(b.safeOrder));
  }

  Future<void> _reorderGroups(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final movedGroup = _groups.removeAt(oldIndex);
    _groups.insert(newIndex, movedGroup);

    // 모든 그룹의 순서를 업데이트
    for (int i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      final updatedGroup = TimerGroupModel(
        id: group.id,
        name: group.name,
        colorHex: group.colorHex,
        createdAt: group.createdAt,
        modifiedAt: DateTime.now(),
        order: i,
      );

      // 기존 그룹 삭제하고 새로 추가
      await group.delete();
      await _groupBox.add(updatedGroup);
    }

    // 다시 로드
    _loadGroups();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reorder,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '그룹 순서 변경',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),

            // 안내 텍스트
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '드래그하여 그룹 순서를 변경할 수 있습니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // 그룹 목록
            Expanded(
              child:
                  _groups.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '생성된 그룹이 없습니다',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _groups.length,
                        onReorder: _reorderGroups,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          final color =
                              group.colorHex != null
                                  ? Color(group.colorHex!)
                                  : Colors.blue;

                          return Container(
                            key: ValueKey(group.id),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.drag_handle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                group.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '순서: ${index + 1}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          );
                        },
                      ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '완료',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
