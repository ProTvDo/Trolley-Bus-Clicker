import 'dart:math';

enum ObstacleKind { car, cone }

class TrackObstacle {
  final int lane;
  final double d;
  final bool blue;
  final ObstacleKind kind;

  /// True only for obstacles placed on a switch branch to force wajcha use
  /// (see TrackSegment.generateSwitch) - decorative obstacles from
  /// TrackSegment.generate never set this and are never hit-tested.
  final bool isHazard;

  /// Set once GameController's collision check fires for this obstacle, so
  /// a single crash can't cost more than one life while the bus lingers in
  /// its distance window.
  bool hit = false;

  TrackObstacle({
    required this.lane,
    required this.d,
    required this.blue,
    required this.kind,
    this.isHazard = false,
  });
}

class TrackSegment {
  /// Predecessor segment, kept only until this one resolves - lets an
  /// unresolved switch's [fromLane] always reflect the predecessor's real
  /// (possibly still-changing) target lane instead of a value snapshotted
  /// too early. Cleared on [resolve] so old segments can be garbage
  /// collected instead of being held forever by a growing reference chain.
  TrackSegment? _prevSeg;
  int? _fromLaneValue;

  int lane;
  int? deadLane;
  bool resolved;
  final double dStart;
  final double dEnd;
  final List<TrackObstacle> obstacles;

  /// True if [lane] is chosen by the player's wajcha (see
  /// GameController.switchModeActive) rather than randomly - drawn with a
  /// distinct marker and a second, dead branch line so the player can
  /// recognise a switch point on sight.
  final bool isSwitch;

  int get fromLane => _fromLaneValue ?? _prevSeg!.lane;

  TrackSegment._({
    TrackSegment? prevSeg,
    int? fromLaneValue,
    required this.lane,
    required this.dStart,
    required this.dEnd,
    required this.obstacles,
    this.isSwitch = false,
    this.resolved = true,
  })  : _prevSeg = prevSeg,
        _fromLaneValue = fromLaneValue;

  factory TrackSegment.initial({required int lane, required double dStart, required double dEnd}) {
    return TrackSegment._(fromLaneValue: lane, lane: lane, dStart: dStart, dEnd: dEnd, obstacles: []);
  }

  /// Regular (non-switch) segment: fully resolved immediately, exactly as
  /// before. [prev] must already be resolved (true for every segment
  /// generated while level < 4, which is the only time this is called).
  static TrackSegment generate(TrackSegment prev, int lanes, int maxJump, Random rng) {
    final fromLane = prev.lane;
    final candidates = [
      for (var l = 0; l < lanes; l++)
        if (l != fromLane && (l - fromLane).abs() <= maxJump) l,
    ];
    final lane = candidates[rng.nextInt(candidates.length)];
    final len = 380 + rng.nextInt(620 - 380 + 1);
    final dStart = prev.dEnd;
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
    return TrackSegment._(fromLaneValue: fromLane, lane: lane, dStart: dStart, dEnd: dEnd, obstacles: obstacles);
  }

  /// A switch ("zwrotnica"): which lane it forks to is deliberately left
  /// unresolved at generation time - it's only decided by [resolve], right
  /// when the player reaches it, from whatever the wajcha is set to *then*.
  ///
  /// With probability [hazardChance] one of the two branches this switch
  /// could fork to gets a parked car: whichever branch the wajcha is
  /// pointed at when this segment resolves is the one the wire - and the
  /// bus, if it stays connected - actually follows, so a hazard left
  /// un-dodged isn't just a visual, it's a forced hit.
  static TrackSegment generateSwitch(TrackSegment prev, Random rng, {required int lanes, double hazardChance = 0}) {
    final len = 380 + rng.nextInt(620 - 380 + 1);
    final dStart = prev.dEnd;
    final obstacles = <TrackObstacle>[];
    if (rng.nextDouble() < hazardChance) {
      final candidates = [for (var l = 0; l < lanes; l++) if (l != prev.lane) l];
      final blockedLane = candidates[rng.nextInt(candidates.length)];
      obstacles.add(TrackObstacle(
        lane: blockedLane,
        d: dStart + len * (0.35 + rng.nextDouble() * 0.3),
        blue: rng.nextDouble() < 0.5,
        kind: ObstacleKind.car,
        isHazard: true,
      ));
    }
    return TrackSegment._(
      prevSeg: prev,
      lane: prev.lane,
      dStart: dStart,
      dEnd: dStart + len,
      obstacles: obstacles,
      isSwitch: true,
      resolved: false,
    );
  }

  /// Locks in the fork outcome. Called exactly once, the moment this
  /// segment becomes current.
  void resolve(int hotLane, int deadLaneValue) {
    _fromLaneValue = fromLane;
    lane = hotLane;
    deadLane = deadLaneValue;
    resolved = true;
    _prevSeg = null;
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

class LeaderboardEntry {
  final String name;
  final int score;

  LeaderboardEntry({required this.name, required this.score});

  String encode() => '${name.replaceAll('|', ' ')}|$score';

  static LeaderboardEntry? decode(String raw) {
    final i = raw.lastIndexOf('|');
    if (i < 0) return null;
    final score = int.tryParse(raw.substring(i + 1));
    if (score == null) return null;
    return LeaderboardEntry(name: raw.substring(0, i), score: score);
  }
}
