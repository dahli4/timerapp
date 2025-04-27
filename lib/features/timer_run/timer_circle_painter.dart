import 'package:flutter/material.dart';
import 'dart:math';

class TimerCirclePainter extends CustomPainter {
  final double progress;
  TimerCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

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

    final outlinePaint =
        Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
    canvas.drawCircle(center, radius, outlinePaint);

    final needlePaint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 4;

    final angle = -pi / 2 + sweepAngle;
    final needleLength = radius;
    final needleEnd = Offset(
      center.dx + needleLength * cos(angle),
      center.dy + needleLength * sin(angle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);

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
