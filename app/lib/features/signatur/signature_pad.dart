import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';

/// A drawing pad that supports multi-stroke signatures.
/// Each pan gesture produces a stroke; lifting the pen (onPanEnd)
/// inserts a `null` sentinel to separate strokes.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.onChanged,
    required this.points,
  });

  final ValueChanged<List<Offset?>> onChanged;
  final List<Offset?> points;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late List<Offset?> _points;

  @override
  void initState() {
    super.initState();
    _points = List<Offset?>.from(widget.points);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) {
        setState(() => _points.add(d.localPosition));
        widget.onChanged(_points);
      },
      onPanUpdate: (d) {
        setState(() => _points.add(d.localPosition));
        widget.onChanged(_points);
      },
      onPanEnd: (_) {
        setState(() => _points.add(null)); // Stift heben
        widget.onChanged(_points);
      },
      child: CustomPaint(
        painter: _SignaturePainter(_points),
        size: const Size(double.infinity, 160),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool penDown = false;
    for (final point in points) {
      if (point == null) {
        penDown = false;
        continue;
      }
      if (!penDown) {
        path.moveTo(point.dx, point.dy);
        penDown = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);

    // Gestrichelte Baseline
    final dashPaint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1;
    const dashW = 8.0;
    const gapW = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height - 16),
        Offset((x + dashW).clamp(0.0, size.width), size.height - 16),
        dashPaint,
      );
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.points != points;
}
