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

  TrackSegment({
    required this.fromLane,
    required this.lane,
    required this.dStart,
    required this.dEnd,
    required this.obstacles,
  });

  static TrackSegment generate(int fromLane, double dStart, int lanes, Random rng) {
    int lane;
    do {
      lane = rng.nextInt(lanes);
    } while (lane == fromLane && lanes > 1);
    final len = 380 + rng.nextInt(620 - 380 + 1);
    final dEnd = dStart + len;
    final obstacles = <TrackObstacle>[];
    for (var l = 0; l < lanes; l++) {
      if (l == lane) continue;
      if (rng.nextDouble() < 0.35) {
        obstacles.add(TrackObstacle(
          lane: l,
          d: dStart + len * (0.25 + rng.nextDouble() * 0.5),
          blue: rng.nextDouble() < 0.5,
          kind: rng.nextDouble() < 0.7 ? ObstacleKind.car : ObstacleKind.cone,
        ));
      }
    }
    return TrackSegment(fromLane: fromLane, lane: lane, dStart: dStart, dEnd: dEnd, obstacles: obstacles);
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
