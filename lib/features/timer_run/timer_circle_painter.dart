import 'package:flutter/material.dart';
import 'dart:math';

class TimerCirclePainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color progressColor;
  TimerCirclePainter({
    required this.progress,
    required this.bgColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final strokeWidth = 30.0;

    // 배경 도넛
    final bgPaint =
        Paint()
          ..color = bgColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // 진행 도넛(색상)
    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;

    final sweepAngle = 2 * pi * progress;
    // 완전히 0일 때는 아무것도 그리지 않음
    if (progress > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimerCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.progressColor != progressColor;
  }
}
