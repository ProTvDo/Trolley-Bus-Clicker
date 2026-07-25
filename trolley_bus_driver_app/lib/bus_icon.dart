import 'package:flutter/material.dart';

import 'game_painter.dart' show neonCyan, neonYellow;

/// Static trolleybus illustration for the welcome screen, drawn in the
/// same style as the in-game bus so branding and gameplay art match.
class TrolleybusIcon extends StatelessWidget {
  const TrolleybusIcon({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * (92 / 64),
      child: CustomPaint(painter: _TrolleybusPainter()),
    );
  }
}

class _TrolleybusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final x = w / 2;
    final y = h / 2;
    final busW = w;
    final busH = h;

    final wirePaint = Paint()
      ..color = neonCyan.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x - busW * 0.16, y - busH * 0.42), Offset(x, -4), wirePaint);
    canvas.drawLine(Offset(x + busW * 0.16, y - busH * 0.42), Offset(x, -4), wirePaint);

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: busW, height: busH),
      Radius.circular(busW * 0.19),
    );
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = neonCyan
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = const Color(0xFF2C6FE0));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - busW / 2, y - busH * 0.02, busW, busH * 0.16),
        Radius.circular(busW * 0.05),
      ),
      Paint()..color = neonYellow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - busW / 2 + busW * 0.11, y - busH / 2 + busH * 0.11, busW * 0.78, busH * 0.3),
        Radius.circular(busW * 0.09),
      ),
      Paint()..color = const Color(0xFFB4E1FF).withValues(alpha: 0.85),
    );

    final wheel = Paint()..color = const Color(0xFF111111);
    canvas.drawCircle(Offset(x - busW / 2 + busW * 0.125, y + busH / 2 - busH * 0.04), busW * 0.11, wheel);
    canvas.drawCircle(Offset(x + busW / 2 - busW * 0.125, y + busH / 2 - busH * 0.04), busW * 0.11, wheel);
  }

  @override
  bool shouldRepaint(covariant _TrolleybusPainter oldDelegate) => false;
}
