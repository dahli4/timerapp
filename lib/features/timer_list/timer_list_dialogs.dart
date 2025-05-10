import 'package:flutter/material.dart';

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
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour:
                          int.tryParse(durationController.text) != null
                              ? int.parse(durationController.text) ~/ 60
                              : 0,
                      minute:
                          int.tryParse(durationController.text) != null
                              ? int.parse(durationController.text) % 60
                              : 0,
                    ),
                  );
                  if (picked != null) {
                    final minutes = picked.hour * 60 + picked.minute;
                    durationController.text = minutes.toString();
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: '타이머 시간 (시:분 선택)',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 위 간격 추가
              const SizedBox(height: 8),
              ValueListenableBuilder<Color>(
                valueListenable: colorNotifier,
                builder:
                    (context, selectedColor, _) => Wrap(
                      spacing: 12,
                      runSpacing: 8, // 아래 간격 추가
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
              const SizedBox(height: 8), // 아래 간격 추가
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
