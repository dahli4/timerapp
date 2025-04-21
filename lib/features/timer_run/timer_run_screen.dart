import 'package:flutter/material.dart';
import '../../data/study_timer_model.dart';

class TimerRunScreen extends StatefulWidget {
  final StudyTimerModel timer;
  const TimerRunScreen({super.key, required this.timer});

  @override
  State<TimerRunScreen> createState() => _TimerRunScreenState();
}

class _TimerRunScreenState extends State<TimerRunScreen> {
  late int _secondsLeft;
  bool _isRunning = false;
  late final int _totalSeconds;
  late final String _title;
  late final int _durationMinutes;
  late final DateTime _createdAt;
  late final int? _colorHex;
  late final StudyTimerModel _timer;

  @override
  void initState() {
    super.initState();
    _timer = widget.timer;
    _title = _timer.title;
    _durationMinutes = _timer.durationMinutes;
    _createdAt = _timer.createdAt;
    _colorHex = _timer.colorHex;
    _totalSeconds = _durationMinutes * 60;
    _secondsLeft = _totalSeconds;
  }

  void _start() {
    setState(() {
      _isRunning = true;
    });
    _tick();
  }

  void _pause() {
    setState(() {
      _isRunning = false;
    });
  }

  void _reset() {
    setState(() {
      _secondsLeft = _totalSeconds;
      _isRunning = false;
    });
  }

  void _tick() async {
    while (_isRunning && _secondsLeft > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRunning) break;
      setState(() {
        _secondsLeft--;
      });
    }
    if (_secondsLeft == 0 && _isRunning) {
      setState(() {
        _isRunning = false;
      });
      // 타이머 종료 시 처리 (예: 기록 저장)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('타이머 종료!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$minutes:$seconds', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  iconSize: 48,
                  onPressed: _isRunning ? _pause : _start,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  iconSize: 48,
                  onPressed: _reset,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
