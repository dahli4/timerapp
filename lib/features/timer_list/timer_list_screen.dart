import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timerapp/features/timer_run/timer_run_screen.dart';
import '../../data/study_timer_model.dart';

class TimerListScreen extends StatefulWidget {
  const TimerListScreen({super.key});

  @override
  State<TimerListScreen> createState() => _TimerListScreenState();
}

class _TimerListScreenState extends State<TimerListScreen> {
  final List<StudyTimerModel> _timers = [];

  @override
  void initState() {
    super.initState();
    _loadTimers();
  }

  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final timersJson = prefs.getStringList('timers') ?? [];
    setState(() {
      _timers.clear();
      _timers.addAll(
        timersJson.map((e) => StudyTimerModel.fromMap(jsonDecode(e))),
      );
    });
  }

  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final timersJson = _timers.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('timers', timersJson);
  }

  void _showAddTimerDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('새 타이머 추가'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: '시간(분)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final duration = int.tryParse(durationController.text) ?? 0;
                  if (title.isNotEmpty && duration > 0) {
                    setState(() {
                      _timers.add(
                        StudyTimerModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          durationMinutes: duration,
                          createdAt: DateTime.now(),
                        ),
                      );
                    });
                    await _saveTimers();
                    Navigator.pop(context);
                  }
                },
                child: const Text('추가'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('타이머 리스트')),
      body:
          _timers.isEmpty
              ? const Center(child: Text('등록된 타이머가 없습니다.'))
              : ListView.builder(
                itemCount: _timers.length,
                itemBuilder: (context, idx) {
                  final timer = _timers[idx];
                  return ListTile(
                    title: Text(timer.title),
                    subtitle: Text('${timer.durationMinutes}분'),
                    leading: const Icon(Icons.timer),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
