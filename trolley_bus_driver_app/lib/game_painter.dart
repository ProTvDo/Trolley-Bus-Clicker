import 'dart:math';

import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'models.dart';

const neonCyan = Color(0xFF4DEAFF);
const neonYellow = Color(0xFFFFE14D);
const neonPink = Color(0xFFFF4DE3);

/// A segment's fromLane/lane/deadLane as they should be drawn this frame -
/// either the real resolved values, or (for a switch not yet reached) a
/// live preview from the current wajcha setting.
class _ResolvedView {
  _ResolvedView(this.seg, this.fromLane, this.lane, this.deadLane);

  final TrackSegment seg;
  final int fromLane;
  final int lane;
  final int? deadLane;
}

class GamePainter extends CustomPainter {
  GamePainter(this.game, this.tick) : super(repaint: game);

  final GameController game;
  final double tick;

  double _screenY(double d) => game.height * GameController.busYFrac - (d - game.scrollY);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    game.resize(w, h);

    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF241736), Color(0xFF3A2150), Color(0xFF6B3159), Color(0xFF1A1220)],
        stops: [0, 0.45, 0.75, 1],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    final edges = game.roadEdges();

    _drawStars(canvas, w, h);
    _drawSkyline(canvas, w, h, edges);
    _drawBeach(canvas, w, h, edges);

    canvas.drawRect(
      Rect.fromLTRB(edges.left, 0, edges.right, h),
      Paint()..color = const Color(0xFF232030),
    );

    _drawLaneDashes(canvas, edges, h);

    canvas.drawLine(Offset(edges.left, 0), Offset(edges.left, h),
        Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 3);
    canvas.drawLine(Offset(edges.right, 0), Offset(edges.right, h),
        Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 3);

    for (var pd = (((game.scrollY - h) / 200).floor()) * 200.0; pd < game.scrollY + h; pd += 200) {
      final py = _screenY(pd);
      _drawPole(canvas, edges.left - 8, py);
      _drawPole(canvas, edges.right + 8, py);
    }

    for (var i = 0; i < game.stopPositions.length; i++) {
      final sy = _screenY(game.stopPositions[i]);
      if (sy < -50 || sy > h + 50) continue;
      _drawStopMarker(canvas, edges.left - 20, sy, passed: i < game.stopsPassed);
    }

    // For a switch not yet resolved, lane/deadLane are computed here as a
    // live preview from the current wajcha - not read off the segment,
    // which only knows the real outcome once it's actually been resolved.
    // Chained so a second not-yet-reached switch previews from the first
    // one's own preview, matching how they'll really resolve in order.
    final resolvedView = <_ResolvedView>[];
    int? cascadeLane;
    for (final seg in game.segments) {
      if (seg.isSwitch && !seg.resolved) {
        final fromLane = cascadeLane ?? seg.fromLane;
        final (hot, dead) = game.resolveSwitchTargets(fromLane);
        resolvedView.add(_ResolvedView(seg, fromLane, hot, dead));
        cascadeLane = hot;
      } else {
        resolvedView.add(_ResolvedView(seg, seg.fromLane, seg.lane, seg.deadLane));
        cascadeLane = null;
      }
    }

    for (final rv in resolvedView) {
      final seg = rv.seg;
      if (seg.dEnd < game.scrollY - 100 || seg.dStart > game.scrollY + h + 100) continue;
      for (final ob in seg.obstacles) {
        final oy = _screenY(ob.d);
        if (oy < -40 || oy > h + 40) continue;
        _drawObstacle(canvas, game.laneX(ob.lane), oy, ob);
      }
      if (seg.isSwitch) {
        final sy = _screenY(seg.dStart);
        if (sy >= -40 && sy <= h + 40) {
          _drawSwitchMarker(canvas, game.laneX(rv.fromLane), sy, rv.lane > rv.fromLane);
        }
      }
    }

    _drawDeadBranches(canvas, h, resolvedView);
    _drawWire(canvas, h, resolvedView);
    _drawParticles(canvas);
    _drawBus(canvas, h);

    if (game.flashT > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = Colors.white.withValues(alpha: (game.flashT * 1.6).clamp(0, 1)),
      );
    }
  }

  void _drawStars(Canvas canvas, double w, double h) {
    for (final s in game.stars) {
      final twv = 0.5 + 0.5 * sin(s.tw + tick * 0.002);
      canvas.drawCircle(
        Offset(s.x * w, s.y * h),
        s.r,
        Paint()..color = Colors.white.withValues(alpha: (0.25 + 0.5 * twv).clamp(0, 1)),
      );
    }
  }

  // Left of the road is Gdynia's downtown skyline; right of it is the
  // seafront (Bulwar Nadmorski) - see _drawBeach.
  void _drawSkyline(Canvas canvas, double w, double h, ({double left, double right}) edges) {
    final paint = Paint()..color = const Color(0xFF140E1C).withValues(alpha: 0.55);
    final skylineOffset = (game.scrollY * 0.15) % 80;
    for (var bx = -80.0; bx < w + 80; bx += 80) {
      final x = bx - (skylineOffset % 80);
      if (x + 56 > edges.left) continue;
      final bh = 60 + (((bx + skylineOffset) / 80).floor() * 37) % 90;
      canvas.drawRect(
        Rect.fromLTWH(x, h * 0.42 - bh, 56, bh.toDouble()),
        paint,
      );
    }
  }

  void _drawBeach(Canvas canvas, double w, double h, ({double left, double right}) edges) {
    if (edges.right >= w) return;
    final seaTop = h * 0.42;
    final seaRect = Rect.fromLTWH(edges.right, seaTop, w - edges.right, h - seaTop);
    canvas.drawRect(
      seaRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F3A52), Color(0xFF13566F), Color(0xFF1C7A8C)],
        ).createShader(seaRect),
    );

    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.5;
    final waveOffset = (game.scrollY * 0.2) % 40;
    for (var wy = seaTop + 10 - waveOffset; wy < h; wy += 40) {
      canvas.drawLine(Offset(edges.right + 6, wy), Offset(w, wy), wavePaint);
    }

    canvas.drawRect(
      Rect.fromLTWH(edges.right, seaTop - 4, min(26, w - edges.right), h - seaTop + 4),
      Paint()..color = const Color(0xFFCBB07A).withValues(alpha: 0.35),
    );
  }

  void _drawLaneDashes(Canvas canvas, ({double left, double right}) edges, double h) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    const dash = 18.0, gap = 18.0;
    for (var lidx = 1; lidx < GameController.lanes; lidx++) {
      final lx = edges.left + (edges.right - edges.left) * (lidx / GameController.lanes);
      var y = -((game.scrollY * 1.4) % (dash + gap));
      while (y < h) {
        canvas.drawLine(Offset(lx, y), Offset(lx, min(y + dash, h)), paint);
        y += dash + gap;
      }
    }
  }

  void _drawPole(Canvas canvas, double x, double y) {
    canvas.drawLine(
      Offset(x, y + 4),
      Offset(x, y - 46),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 4,
    );
  }

  void _drawStopMarker(Canvas canvas, double x, double y, {required bool passed}) {
    final color = passed ? Colors.white24 : neonYellow;
    canvas.save();
    canvas.translate(x, y);
    canvas.drawLine(
      const Offset(0, 16),
      const Offset(0, -14),
      Paint()
        ..color = color
        ..strokeWidth = 3,
    );
    final signRect = const Rect.fromLTWH(-16, -34, 32, 22);
    final signRRect = RRect.fromRectAndRadius(signRect, const Radius.circular(4));
    if (!passed) {
      canvas.drawRRect(
        signRRect,
        Paint()
          ..color = neonYellow.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawRRect(signRRect, Paint()..color = const Color(0xFF14141C));
    canvas.drawRRect(
      signRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color,
    );
    final tp = TextPainter(
      text: TextSpan(text: '🚏', style: TextStyle(fontSize: 15, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -34 + (22 - tp.height) / 2));
    canvas.restore();
  }

  void _drawObstacle(Canvas canvas, double x, double y, TrackObstacle ob) {
    canvas.save();
    canvas.translate(x, y);
    if (ob.kind == ObstacleKind.car) {
      final color = ob.blue ? const Color(0xFF3D6BD6) : const Color(0xFFC94B4B);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-20, -12, 40, 24), const Radius.circular(6)),
        Paint()..color = color,
      );
      final wheel = Paint()..color = const Color(0xFF111111);
      canvas.drawCircle(const Offset(-12, 12), 5, wheel);
      canvas.drawCircle(const Offset(12, 12), 5, wheel);
    } else {
      final path = Path()
        ..moveTo(0, -16)
        ..lineTo(14, 12)
        ..lineTo(-14, 12)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFFF8A2B));
      canvas.drawRect(const Rect.fromLTWH(-9, 2, 18, 4), Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  void _drawSwitchMarker(Canvas canvas, double x, double y, bool pointsRight) {
    const amber = Color(0xFFFF8A2B);
    canvas.save();
    canvas.translate(x, y);
    canvas.drawCircle(
      Offset.zero,
      13,
      Paint()
        ..color = amber.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(Offset.zero, 9, Paint()..color = const Color(0xFF14141C));
    canvas.drawCircle(
      Offset.zero,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = amber,
    );
    final dir = pointsRight ? 1.0 : -1.0;
    final arrow = Path()
      ..moveTo(-4 * dir, -5)
      ..lineTo(5 * dir, 0)
      ..lineTo(-4 * dir, 5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = amber);
    canvas.restore();
  }

  void _drawDeadBranches(Canvas canvas, double h, List<_ResolvedView> resolvedView) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFFBFF4FF).withValues(alpha: 0.22);
    for (final rv in resolvedView) {
      if (rv.deadLane == null) continue;
      if (rv.seg.dEnd < game.scrollY - 50 || rv.seg.dStart > game.scrollY + h + 50) continue;
      // The real wire keeps going after the fork; the dead branch doesn't -
      // it's drawn only through the fork itself, then simply ends.
      final start = Offset(game.laneX(rv.fromLane), _screenY(rv.seg.dStart));
      final end = Offset(game.laneX(rv.deadLane!), _screenY(rv.seg.dStart + game.graceForJump(rv.fromLane, rv.lane)));
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawWire(Canvas canvas, double h, List<_ResolvedView> resolvedView) {
    final pts = <Offset>[];
    for (final rv in resolvedView) {
      if (rv.seg.dEnd < game.scrollY - 50 || rv.seg.dStart > game.scrollY + h + 50) continue;
      pts.add(Offset(game.laneX(rv.fromLane), _screenY(rv.seg.dStart)));
      pts.add(Offset(game.laneX(rv.lane), _screenY(rv.seg.dStart + game.graceForJump(rv.fromLane, rv.lane))));
      pts.add(Offset(game.laneX(rv.lane), _screenY(rv.seg.dEnd)));
    }
    if (pts.length < 2) return;

    final glow = 6 + (game.mult - 1) * 10;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFBFF4FF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow / 2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFBFF4FF),
    );
  }

  void _drawParticles(Canvas canvas) {
    for (final p in game.particles) {
      final a = (1 - p.age / p.life).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x, p.y),
        2.4 * a + 0.6,
        Paint()..color = (p.cyan ? neonCyan : neonYellow).withValues(alpha: a),
      );
    }
  }

  void _drawBus(Canvas canvas, double h) {
    final x = game.busDrawX;
    final y = h * GameController.busYFrac;
    const w = 64.0, bh = 92.0;
    final aligned = game.state == GameState.playing;
    final seg = game.currentSegment();
    final wireX = game.laneX(seg.lane);

    final wirePaint = Paint()
      ..color = (aligned ? Colors.white : const Color(0xFFFF5050)).withValues(alpha: 0.5)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x - 10, y - bh * 0.42), Offset(wireX, _screenY(game.scrollY) + 2), wirePaint);
    canvas.drawLine(Offset(x + 10, y - bh * 0.42), Offset(wireX, _screenY(game.scrollY) + 2), wirePaint);

    final glowColor = aligned ? neonCyan : const Color(0xFFFF5A5A);
    final glowBlur = aligned ? (10 + (game.mult - 1) * 10) : 14.0;

    final bodyRRect = RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, y - bh / 2, w, bh), const Radius.circular(12));
    canvas.drawRRect(bodyRRect, Paint()..color = glowColor..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur / 2));
    canvas.drawRRect(bodyRRect, Paint()..color = const Color(0xFF2C6FE0));

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, y - bh * 0.02, w, bh * 0.16), const Radius.circular(3)),
      Paint()..color = neonYellow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w / 2 + 7, y - bh / 2 + 10, w - 14, bh * 0.3),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFB4E1FF).withValues(alpha: 0.85),
    );

    final wheel = Paint()..color = const Color(0xFF111111);
    canvas.drawCircle(Offset(x - w / 2 + 8, y + bh / 2 - 4), 7, wheel);
    canvas.drawCircle(Offset(x + w / 2 - 8, y + bh / 2 - 4), 7, wheel);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
