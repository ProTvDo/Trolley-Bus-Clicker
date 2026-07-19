import 'dart:math';

enum ObstacleKind { car, cone }

class TrackObstacle {
  final int lane;
  final double d;
  final bool blue;
  final ObstacleKind kind;

  TrackObstacle({
    required this.lane,
    required this.d,
    required this.blue,
    required this.kind,
  });
}

class TrackSegment {
  final int fromLane;
  final int lane;
  final double dStart;
  final double dEnd;
  final List<TrackObstacle> obstacles;

  /// True if [lane] was chosen by the player's wajcha (see
  /// GameController.switchModeActive) rather than randomly - drawn with a
  /// distinct marker so the player can recognise a switch point on sight.
  final bool isSwitch;

  /// For a switch segment, the other branch of the fork - drawn too (a real
  /// train switch shows both physical tracks), but it's not live: ending up
  /// on this lane is exactly as wrong as any other unaligned lane.
  final int? deadLane;

  TrackSegment({
    required this.fromLane,
    required this.lane,
    required this.dStart,
    required this.dEnd,
    required this.obstacles,
    this.isSwitch = false,
    this.deadLane,
  });

  static TrackSegment generate(
    int fromLane,
    double dStart,
    int lanes,
    int maxJump,
    Random rng, {
    int? forcedLane,
    int? deadLane,
    bool isSwitch = false,
  }) {
    // Lane changes are capped at maxJump lanes away from fromLane - the
    // caller widens the reaction window proportionally to the jump size
    // (see GameController.graceFor), so any jump up to maxJump stays fair.
    int lane;
    if (forcedLane != null) {
      lane = forcedLane;
    } else {
      final candidates = [
        for (var l = 0; l < lanes; l++)
          if (l != fromLane && (l - fromLane).abs() <= maxJump) l,
      ];
      lane = candidates[rng.nextInt(candidates.length)];
    }
    final len = 380 + rng.nextInt(620 - 380 + 1);
    final dEnd = dStart + len;
    final obstacles = <TrackObstacle>[];
    for (var l = 0; l < lanes; l++) {
      if (l == lane || l == deadLane) continue;
      if (rng.nextDouble() < 0.35) {
        obstacles.add(TrackObstacle(
          lane: l,
          d: dStart + len * (0.25 + rng.nextDouble() * 0.5),
          blue: rng.nextDouble() < 0.5,
          kind: rng.nextDouble() < 0.7 ? ObstacleKind.car : ObstacleKind.cone,
        ));
      }
    }
    return TrackSegment(
      fromLane: fromLane,
      lane: lane,
      dStart: dStart,
      dEnd: dEnd,
      obstacles: obstacles,
      isSwitch: isSwitch,
      deadLane: deadLane,
    );
  }
}

class Spark {
  double x;
  double y;
  final double vx;
  double vy;
  final double life;
  double age;
  final bool cyan;

  Spark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    this.age = 0,
    required this.cyan,
  });
}

class Star {
  final double x;
  final double y;
  final double r;
  final double tw;

  Star({required this.x, required this.y, required this.r, required this.tw});
}
