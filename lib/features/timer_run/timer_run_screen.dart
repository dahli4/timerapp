import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import '../../data/study_timer_model.dart';

class TimerRunScreen extends StatefulWidget {
  final StudyTimerModel timer;
  const TimerRunScreen({super.key, required this.timer});

  @override
  State<TimerRunScreen> createState() => _TimerRunScreenState();
}

class _TimerRunScreenState extends State<TimerRunScreen>
    with SingleTickerProviderStateMixin {
  late final int _totalSeconds;
  late final String _title;
  late final int _durationMinutes;
  late final DateTime _createdAt;
  late final int? _colorHex;
  late final StudyTimerModel _timer;

  Ticker? _ticker;
  double _elapsedSeconds = 0;
  bool _isRunning = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _timer = widget.timer;
    _title = _timer.title;
    _durationMinutes = _timer.durationMinutes;
    _createdAt = _timer.createdAt;
    _colorHex = _timer.colorHex;
    _totalSeconds = _durationMinutes * 60;
    _elapsedSeconds = 0;
  }

  void _start() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now().subtract(
        Duration(milliseconds: (_elapsedSeconds * 1000).toInt()),
      );
    });
    _ticker?.dispose();
    _ticker = createTicker((_) {
      if (!_isRunning) return;
      final now = DateTime.now();
      setState(() {
        _elapsedSeconds = now.difference(_startTime!).inMilliseconds / 1000.0;
        if (_elapsedSeconds >= _totalSeconds) {
          _elapsedSeconds = _totalSeconds.toDouble();
          _isRunning = false;
          _ticker?.stop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('타이머 종료!')));
        }
      });
    });
    _ticker?.start();
  }

  void _pause() {
    setState(() {
      _isRunning = false;
    });
    _ticker?.stop();
  }

  void _reset() {
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
      _startTime = null;
    });
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secondsLeft =
        (_totalSeconds - _elapsedSeconds).clamp(0, _totalSeconds).toInt();
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    final progress = (_elapsedSeconds / _totalSeconds).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(200, 200),
              painter: TimerCirclePainter(progress: progress),
            ),
            const SizedBox(height: 16),
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

class TimerCirclePainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0

  TimerCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // 경과 부분 (빨간색, 채우기)
    final redPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    final sweepAngle = 2 * pi * progress;
    if (progress > 0) {
      Path path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
      );
      path.close();
      canvas.drawPath(path, redPaint);
    }

    // 테두리(Outline)
    final outlinePaint =
        Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
    canvas.drawCircle(center, radius, outlinePaint);

    // 침(바늘) - 원 밖으로 안 나가게 radius만큼만
    final needlePaint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 4;

    final angle = -pi / 2 + sweepAngle;
    final needleLength = radius; // 바늘 길이 = 반지름
    final needleEnd = Offset(
      center.dx + needleLength * cos(angle),
      center.dy + needleLength * sin(angle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);

    // 중심 원 (디자인용)
    final centerDot =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerDot);
  }

  @override
  bool shouldRepaint(covariant TimerCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
