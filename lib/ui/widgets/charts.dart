import 'package:flutter/material.dart';

import '../../services/workout_stats.dart';
import 'format.dart';

/// Line chart of [DailyPoint]s drawn with a [CustomPainter] — no chart
/// package needed, fully offline.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.unit,
    this.height = 220,
  });

  final List<DailyPoint> points;
  final String unit;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(
          points: points,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points, required this.color});

  final List<DailyPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 46.0, padR = 12.0, padT = 12.0, padB = 26.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    if (points.isEmpty || w <= 0 || h <= 0) {
      _drawCentered(canvas, size, 'No data yet — log a workout!');
      return;
    }

    var minV = points.first.value;
    var maxV = points.first.value;
    for (final p in points) {
      if (p.value < minV) minV = p.value;
      if (p.value > maxV) maxV = p.value;
    }
    if ((maxV - minV).abs() < 1e-6) {
      minV -= 1;
      maxV += 1;
    }

    double x(int i) =>
        padL + (points.length == 1 ? w / 2 : w * i / (points.length - 1));
    double y(double v) => padT + h * (1 - (v - minV) / (maxV - minV));

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var g = 0; g <= 3; g++) {
      final v = minV + (maxV - minV) * g / 3;
      final yy = y(v);
      canvas.drawLine(Offset(padL, yy), Offset(padL + w, yy), gridPaint);
      _drawText(
        canvas,
        _fmtValue(v),
        Offset(2, yy - 8),
        const TextStyle(fontSize: 10, color: Colors.grey),
      );
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final pt = Offset(x(i), y(points[i].value));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < points.length; i++) {
      final center = Offset(x(i), y(points[i].value));
      canvas.drawCircle(center, 4.5, Paint()..color = color);
      canvas.drawCircle(
        center,
        4.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    _drawText(
      canvas,
      formatDay(points.first.date),
      Offset(padL, padT + h + 6),
      const TextStyle(fontSize: 10, color: Colors.grey),
    );
    _drawTextRight(
      canvas,
      formatDay(points.last.date),
      Offset(padL + w, padT + h + 6),
      const TextStyle(fontSize: 10, color: Colors.grey),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

/// Bar chart of [DailyPoint]s (e.g. volume per day), also CustomPainter-only.
class VolumeBars extends StatelessWidget {
  const VolumeBars({
    super.key,
    required this.points,
    required this.unit,
    this.height = 200,
  });

  final List<DailyPoint> points;
  final String unit;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarsPainter(
          points: points,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.points, required this.color});

  final List<DailyPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 46.0, padR = 12.0, padT = 12.0, padB = 26.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    if (points.isEmpty || w <= 0 || h <= 0) {
      _drawCentered(canvas, size, 'No data yet — log a workout!');
      return;
    }

    var maxV = 0.0;
    for (final p in points) {
      if (p.value > maxV) maxV = p.value;
    }
    if (maxV <= 0) maxV = 1;

    final slot = w / points.length;
    final barW = slot * 0.6;
    final barPaint = Paint()..color = color.withValues(alpha: 0.85);
    for (var i = 0; i < points.length; i++) {
      final bh = h * (points[i].value / maxV);
      final left = padL + slot * i + (slot - barW) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, padT + h - bh, barW, bh),
          const Radius.circular(4),
        ),
        barPaint,
      );
    }

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var g = 0; g <= 2; g++) {
      final v = maxV * g / 2;
      final yy = padT + h * (1 - g / 2);
      canvas.drawLine(Offset(padL, yy), Offset(padL + w, yy), gridPaint);
      _drawText(
        canvas,
        _fmtValue(v),
        Offset(2, yy - 8),
        const TextStyle(fontSize: 10, color: Colors.grey),
      );
    }

    _drawText(
      canvas,
      formatDay(points.first.date),
      Offset(padL, padT + h + 6),
      const TextStyle(fontSize: 10, color: Colors.grey),
    );
    _drawTextRight(
      canvas,
      formatDay(points.last.date),
      Offset(padL + w, padT + h + 6),
      const TextStyle(fontSize: 10, color: Colors.grey),
    );
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

String _fmtValue(double v) =>
    v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

void _drawText(Canvas canvas, String text, Offset at, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, at);
}

void _drawTextRight(Canvas canvas, String text, Offset atRight, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(atRight.dx - tp.width, atRight.dy));
}

void _drawCentered(Canvas canvas, Size size, String text) {
  final tp = TextPainter(
    text: const TextSpan(
      text: '',
      style: TextStyle(fontSize: 14, color: Colors.grey),
    ),
    textDirection: TextDirection.ltr,
  );
  tp.text = TextSpan(
    text: text,
    style: const TextStyle(fontSize: 14, color: Colors.grey),
  );
  tp.layout(maxWidth: size.width - 32);
  tp.paint(
    canvas,
    Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
  );
  tp.dispose();
}
