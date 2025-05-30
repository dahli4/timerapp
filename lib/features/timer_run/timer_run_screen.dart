import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../data/study_timer_model.dart';
import 'timer_circle_painter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../utils/notification_helper.dart';

class TimerRunScreen extends StatefulWidget {
  final StudyTimerModel timer;
  const TimerRunScreen({super.key, required this.timer});

  @override
  State<TimerRunScreen> createState() => _TimerRunScreenState();
}

class _TimerRunScreenState extends State<TimerRunScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final int _totalSeconds;
  late final String _title;
  late final int _durationMinutes;
  late final StudyTimerModel _timer;

  Ticker? _ticker;
  double _elapsedSeconds = 0;
  bool _recordSaved = false; // 1분 이상 기록 저장 여부
  bool _isRunning = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = widget.timer;
    _title = _timer.title;
    _durationMinutes = _timer.durationMinutes;
    _totalSeconds = _durationMinutes * 60;
    _elapsedSeconds = 0;

    _ticker = createTicker((_) {
      if (!_isRunning) return;
      final now = DateTime.now();
      setState(() {
        _elapsedSeconds = now.difference(_startTime!).inMilliseconds / 1000.0;

        if (_elapsedSeconds >= 60 && !_recordSaved) {
          _saveRecord();
          _recordSaved = true;
        }

        if (_elapsedSeconds >= _totalSeconds) {
          _elapsedSeconds = _totalSeconds.toDouble();
          _isRunning = false;
          _ticker?.stop();
          if (!_recordSaved) {
            _saveRecord();
            _recordSaved = true;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('타이머 종료!')));
        }
      });
    });
  }

  void _start() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _startTime = DateTime.now().subtract(
        Duration(milliseconds: (_elapsedSeconds * 1000).toInt()),
      );
    });
    _ticker?.start();

    final secondsLeft =
        (_totalSeconds - _elapsedSeconds).clamp(0, _totalSeconds).toInt();
    scheduleTimerNotification(secondsLeft);
  }

  void _pause() {
    setState(() {
      _isRunning = false;
    });
    _ticker?.stop();
    cancelTimerNotification();
    if (_elapsedSeconds >= 60 && !_recordSaved) {
      _saveRecord();
      _recordSaved = true;
    }
  }

  void _reset() {
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
      _startTime = null;
      _recordSaved = false;
    });
    _ticker?.stop();
    cancelTimerNotification();
  }

  void _saveRecord() async {
    final recordBox = Hive.box<StudyRecordModel>('records');
    await recordBox.add(
      StudyRecordModel(
        timerId: widget.timer.id,
        date: DateTime.now(),
        minutes: _elapsedSeconds ~/ 60,
        seconds: (_elapsedSeconds % 60).toInt(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning) {
      if (_startTime != null) {
        final now = DateTime.now();
        setState(() {
          _elapsedSeconds = now.difference(_startTime!).inMilliseconds / 1000.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondsLeft =
        (_totalSeconds - _elapsedSeconds).clamp(0, _totalSeconds).toInt();
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    final progress = (_elapsedSeconds / _totalSeconds).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerTextColor =
        isDark ? Colors.white : Colors.black87; // 라이트모드에서 살짝 검은색
    final timerBgColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(300, 300),
                  painter: TimerCirclePainter(
                    progress: progress,
                    bgColor: timerBgColor, // 배경색 전달
                  ),
                ),
                Text(
                  '$minutes:$seconds',
                  style: TextStyle(
                    fontSize: 48,
                    color: timerTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // 정지한 시간 표시
            if (!_isRunning && _elapsedSeconds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  '정지한 시각: '
                  '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:'
                  '${(_elapsedSeconds % 60).toInt().toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            const SizedBox(height: 44),
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
