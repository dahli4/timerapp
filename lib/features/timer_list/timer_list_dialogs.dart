import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.grey,
  ];
  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '제목'),
              ),
              GestureDetector(
                onTap: () async {
                  Duration initial = Duration(
                    minutes: int.tryParse(durationController.text) ?? 0,
                  );
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // ← 추가!
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (context) {
                      Duration temp = initial;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom +
                              24, // 키보드/하단 여백
                          left: 16,
                          right: 16,
                          top: 16,
                        ),
                        child: SizedBox(
                          height: 320, // 기존보다 더 높게
                          child: Column(
                            children: [
                              Expanded(
                                child: CupertinoTimerPicker(
                                  mode: CupertinoTimerPickerMode.hm,
                                  initialTimerDuration: initial,
                                  onTimerDurationChanged: (Duration value) {
                                    temp = value;
                                  },
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  durationController.text =
                                      (temp.inMinutes).toString();
                                  Navigator.pop(context);
                                },
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: AbsorbPointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: '타이머 시간 (시:분 선택)',
                          suffixIcon: const Icon(Icons.access_time),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final min =
                              int.tryParse(durationController.text) ?? 0;
                          if (min >= 60) {
                            final h = min ~/ 60;
                            final m = min % 60;
                            return Text(
                              m > 0 ? '$h시간 $m분' : '$h시간',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            );
                          } else if (min > 0) {
                            return Text(
                              '$min분',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              ValueListenableBuilder<Color>(
                valueListenable: colorNotifier,
                builder:
                    (context, selectedColor, _) => Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children:
                          colors.map((color) {
                            return GestureDetector(
                              onTap: () => colorNotifier.value = color,
                              child: CircleAvatar(
                                backgroundColor: color,
                                radius: 16,
                                child:
                                    selectedColor == color
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                        : null,
                              ),
                            );
                          }).toList(),
                    ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(onPressed: onConfirm, child: Text(confirmText)),
          ],
        ),
  );
}
