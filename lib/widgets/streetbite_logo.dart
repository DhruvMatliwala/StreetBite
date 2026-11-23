import 'package:flutter/material.dart';

/// Custom vector brand mark for StreetBite (map pin + steaming street-food bowl).
class StreetBiteLogo extends StatelessWidget {
  const StreetBiteLogo({super.key, this.size = 34.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StreetBiteLogoPainter(),
      ),
    );
  }
}

class _StreetBiteLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 108.0;
    canvas.save();
    canvas.scale(s, s);

    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 4, 100, 100),
      const Radius.circular(24),
    );
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFF8F00),
          Color(0xFFE65100),
          Color(0xFFBF360C),
        ],
      ).createShader(const Rect.fromLTWH(4, 4, 100, 100));
    canvas.drawRRect(bgRect, bgPaint);

    final pinPath = Path()
      ..moveTo(54, 16)
      ..cubicTo(37.5, 16, 24, 29.5, 24, 46)
      ..cubicTo(24, 65.5, 47.0, 86.8, 52.8, 92.6)
      ..cubicTo(53.45, 93.3, 54.55, 93.3, 55.2, 92.6)
      ..cubicTo(61.0, 86.8, 84, 65.5, 84, 46)
      ..cubicTo(84, 29.5, 70.5, 16, 54, 16)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = Colors.white);

    canvas.drawCircle(
      const Offset(54, 46),
      21.5,
      Paint()..color = const Color(0xFFE65100),
    );

    final skewerPaint = Paint()
      ..color = const Color(0xFFFFE082)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(40, 38), const Offset(68, 54), skewerPaint);
    canvas.drawLine(const Offset(68, 38), const Offset(40, 54), skewerPaint);

    final bowlPath = Path()
      ..moveTo(39, 48)
      ..lineTo(69, 48)
      ..cubicTo(69, 57.5, 62.5, 63, 54, 63)
      ..cubicTo(45.5, 63, 39, 57.5, 39, 48)
      ..close();
    canvas.drawPath(bowlPath, Paint()..color = const Color(0xFFFFB300));

    final rimRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(37.5, 45.8, 33, 2.8),
      const Radius.circular(1.4),
    );
    canvas.drawRRect(rimRect, Paint()..color = const Color(0xFFFFF8E1));

    final steamPaint = Paint()
      ..color = const Color(0xFFFFF8E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (final x in <double>[46.0, 54.0, 62.0]) {
      final topY = x == 54.0 ? 32.0 : 34.0;
      final steam = Path()
        ..moveTo(x, 42.5)
        ..cubicTo(x - 2.0, 39.5, x + 2.0, 36.5, x, topY);
      canvas.drawPath(steam, steamPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
