import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/timer_group_model.dart';
import 'dart:math' as math;

Future<bool?> showGroupManagementDialog(BuildContext context) {
  final Box<TimerGroupModel> groupBox = Hive.box<TimerGroupModel>('groups');
  final nameController = TextEditingController();
  final colorNotifier = ValueNotifier<Color>(Colors.blue.shade500);

  final List<Color> colors = [
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

  Future<void> addGroup() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('그룹 이름을 입력해주세요')));
      return;
    }

    // 새 그룹의 순서를 기존 그룹 수 + 1로 설정
    final nextOrder = groupBox.values.length;

    final group = TimerGroupModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      colorHex: colorNotifier.value.toARGB32(),
      createdAt: DateTime.now(),
      order: nextOrder,
    );

    await groupBox.add(group);
    // UI 초기화 제거 - 성공 후에 다이얼로그가 닫히므로 불필요
  }

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Material(
            type: MaterialType.transparency,
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                margin: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 50,
                  bottom: math.max(
                    50,
                    MediaQuery.of(context).viewInsets.bottom + 10,
                  ),
                ),
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
                              Icons.folder_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '새 그룹 추가',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context, false),
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
                            // 그룹 이름 입력
                            Text(
                              '그룹 이름',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: '예: 업무, 공부, 취미',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                    color: selectedColor
                                                        .withValues(alpha: 0.3),
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
                                            return GestureDetector(
                                              onTap:
                                                  () =>
                                                      colorNotifier.value =
                                                          color,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: color,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: color.withValues(
                                                        alpha: 0.4,
                                                      ),
                                                      blurRadius:
                                                          isSelected ? 10 : 4,
                                                      offset: Offset(
                                                        0,
                                                        isSelected ? 4 : 2,
                                                      ),
                                                    ),
                                                  ],
                                                  border:
                                                      isSelected
                                                          ? Border.all(
                                                            color: Colors.white,
                                                            width: 3,
                                                          )
                                                          : null,
                                                ),
                                                child: Transform.scale(
                                                  scale: isSelected ? 1.0 : 0.9,
                                                  child:
                                                      isSelected
                                                          ? Center(
                                                            child: Container(
                                                              width: 16,
                                                              height: 16,
                                                              decoration:
                                                                  const BoxDecoration(
                                                                    shape:
                                                                        BoxShape
                                                                            .circle,
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                              child: Icon(
                                                                Icons.check,
                                                                color: color,
                                                                size: 10,
                                                              ),
                                                            ),
                                                          )
                                                          : null,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                            ),

                            const SizedBox(height: 20),

                            // 버튼들
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('취소'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final name = nameController.text.trim();
                                      if (name.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('그룹 이름을 입력해주세요'),
                                          ),
                                        );
                                        return;
                                      }

                                      await addGroup();
                                      if (context.mounted) {
                                        Navigator.pop(context, true);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      '추가',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
