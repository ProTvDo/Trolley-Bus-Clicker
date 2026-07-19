import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio.dart';
import 'models.dart';

enum GameState { start, playing, reconnecting, gameOver }

class GameController extends ChangeNotifier {
  GameController() {
    _loadBest();
    _resetTrack();
  }

  // ---- tunables (mirrors the original web game) ----
  static const lanes = 3;
  static const roadFrac = 0.7;
  static const busYFrac = 0.78;
  static const baseSpeed = 180.0;
  static const maxSpeedAdd = 160.0;
  static const maxLives = 3;
  static const tapsNeeded = 3;
  static const reconnectTime = 4.0;

  // ---- difficulty levels ----
  // Level 1: only adjacent-lane wire changes, generous reaction window.
  // Level 2: two-lane jumps introduced, window scales with jump size so
  //          it stays exactly as fair (per-lane) as a level-1 change.
  // Level 3: same jumps, tighter window - a real skill test.
  // Level 4: zwrotnice (switches) - the wire no longer picks its own
  //          direction; it forks and follows whichever way the player's
  //          wajcha (lever) is set to at the moment it's reached.
  int get level {
    if (score < 150) return 1;
    if (score < 450) return 2;
    if (score < 800) return 3;
    return 4;
  }

  int get maxJump => level >= 2 ? 2 : 1;

  bool get switchModeActive => level >= 4;

  /// -1 = left, 1 = right. The direction a not-yet-reached switch will
  /// resolve to; set ahead of time by tapping the on-screen wajcha lever.
  int wajchaDir = 1;

  void setWajcha(int dir) {
    if (wajchaDir == dir) return;
    wajchaDir = dir;
    notifyListeners();
  }

  /// A switch always forks into the two lanes that aren't fromLane (with
  /// only 3 lanes total, that's always exactly two). wajcha picks which one
  /// is live: -1 takes the lower-index branch (drawn on the left), +1 the
  /// higher-index one (drawn on the right). Pure and side-effect free, so
  /// it doubles as a live preview for not-yet-reached switches (see
  /// GamePainter) - call it again right when the segment becomes current to
  /// actually lock the outcome in via TrackSegment.resolve. Returns
  /// (hot, dead): hot is the real wire target, dead is the other branch,
  /// drawn but not live - landing on it disconnects you.
  (int hot, int dead) resolveSwitchTargets(int fromLane) {
    final candidates = [for (var l = 0; l < lanes; l++) if (l != fromLane) l]..sort();
    return wajchaDir < 0 ? (candidates[0], candidates[1]) : (candidates[1], candidates[0]);
  }

  double get _graceBase {
    switch (level) {
      case 1:
        return 170;
      case 2:
        return 150;
      default:
        return 120;
    }
  }

  /// Width (in track-distance units) of the transition window for a jump
  /// from [fromLane] to [lane], scaled by how many lanes it crosses so a
  /// 2-lane jump gets twice the reaction time of a 1-lane change instead of
  /// the same tight window.
  double graceForJump(int fromLane, int lane) => _graceBase * max(1, (lane - fromLane).abs());

  double graceFor(TrackSegment seg) => graceForJump(seg.fromLane, seg.lane);

  final _rng = Random();
  final sound = SoundEngine();

  double width = 0;
  double height = 0;

  GameState state = GameState.start;
  double score = 0;
  int best = 0;
  int lives = maxLives;
  int busLane = 1;
  double busDrawX = 0;
  double scrollY = 0;
  double speed = baseSpeed;
  double alignedTime = 0;
  double mult = 1;
  double flashT = 0;

  final List<TrackSegment> segments = [];
  final List<Spark> particles = [];
  late final List<Star> stars = List.generate(40, (_) {
    return Star(
      x: _rng.nextDouble(),
      y: _rng.nextDouble() * 0.55,
      r: _rng.nextDouble() * 1.6 + 0.4,
      tw: _rng.nextDouble() * pi * 2,
    );
  });

  int reconnectTapsLeft = tapsNeeded;
  double reconnectTimeLeft = reconnectTime;

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    best = prefs.getInt('zlapprad_best') ?? 0;
    notifyListeners();
  }

  Future<void> _saveBest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zlapprad_best', best);
  }

  void resize(double w, double h) {
    width = w;
    height = h;
  }

  double laneX(int lane) {
    final roadW = width * roadFrac;
    final left = (width - roadW) / 2;
    return left + roadW * ((lane + 0.5) / lanes);
  }

  ({double left, double right}) roadEdges() {
    final roadW = width * roadFrac;
    final left = (width - roadW) / 2;
    return (left: left, right: left + roadW);
  }

  TrackSegment _nextSegment(TrackSegment prev) {
    if (switchModeActive) return TrackSegment.generateSwitch(prev, _rng);
    return TrackSegment.generate(prev, lanes, maxJump, _rng);
  }

  void _resetTrack() {
    segments
      ..clear()
      ..add(TrackSegment.initial(lane: 1, dStart: -400, dEnd: 420));
    while (segments.last.dEnd < 1200) {
      segments.add(_nextSegment(segments.last));
    }
  }

  void _ensureTrackAhead() {
    var last = segments.last;
    while (last.dEnd < scrollY + height + 300) {
      last = _nextSegment(last);
      segments.add(last);
    }
    while (segments.length > 4 && segments[1].dEnd < scrollY - height) {
      segments.removeAt(0);
    }
  }

  TrackSegment currentSegment() {
    for (final s in segments) {
      if (scrollY >= s.dStart && scrollY < s.dEnd) return s;
    }
    return segments.last;
  }

  List<int> _wireValidLanes(TrackSegment seg) {
    if (scrollY < seg.dStart + graceFor(seg)) {
      final lo = min(seg.fromLane, seg.lane);
      final hi = max(seg.fromLane, seg.lane);
      return [for (var l = lo; l <= hi; l++) l];
    }
    return [seg.lane];
  }

  void startGame() {
    score = 0;
    lives = maxLives;
    busLane = 1;
    busDrawX = laneX(1);
    scrollY = 0;
    speed = baseSpeed;
    alignedTime = 0;
    mult = 1;
    particles.clear();
    state = GameState.playing;
    _resetTrack();
    notifyListeners();
  }

  void _triggerDisconnect() {
    if (state != GameState.playing) return;
    state = GameState.reconnecting;
    mult = 1;
    alignedTime = 0;
    reconnectTapsLeft = tapsNeeded;
    reconnectTimeLeft = reconnectTime;
    flashT = 0.25;
    sound.buzz();
    HapticFeedback.heavyImpact();
  }

  void reconnectTap() {
    if (state != GameState.reconnecting) return;
    reconnectTapsLeft--;
    sound.tap();
    HapticFeedback.lightImpact();
    if (reconnectTapsLeft <= 0) {
      busLane = currentSegment().lane;
      state = GameState.playing;
      sound.success();
    }
    notifyListeners();
  }

  void _loseLife() {
    lives--;
    if (lives <= 0) {
      _endGame();
    } else {
      sound.loseLife();
      busLane = currentSegment().lane;
      state = GameState.playing;
    }
  }

  void _endGame() {
    state = GameState.gameOver;
    sound.gameOver();
    if (score > best) {
      best = score.floor();
      _saveBest();
    }
  }

  void moveLane(int dir) {
    if (state != GameState.playing) return;
    busLane = (busLane + dir).clamp(0, lanes - 1);
  }

  void handleZoneTap(bool left) {
    switch (state) {
      case GameState.reconnecting:
        reconnectTap();
        break;
      case GameState.playing:
        moveLane(left ? -1 : 1);
        break;
      case GameState.start:
        startGame();
        break;
      case GameState.gameOver:
        break;
    }
  }

  void _spawnSpark(double x, double y) {
    particles.add(Spark(
      x: x + (_rng.nextDouble() * 10 - 5),
      y: y,
      vx: (_rng.nextDouble() * 2 - 1) * 40,
      vy: -40 - _rng.nextDouble() * 60,
      life: 0.4 + _rng.nextDouble() * 0.3,
      cyan: _rng.nextDouble() < 0.5,
    ));
  }

  void _updateParticles(double dt) {
    particles.removeWhere((p) => (p.age += dt) >= p.life);
    for (final p in particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 90 * dt;
    }
  }

  void update(double dt) {
    if (width == 0 || height == 0) return;
    if (state == GameState.playing) {
      scrollY += speed * dt;
      speed = baseSpeed + min(maxSpeedAdd, score * 0.025);
      _ensureTrackAhead();

      final seg = currentSegment();
      if (seg.isSwitch && !seg.resolved) {
        final (hot, dead) = resolveSwitchTargets(seg.fromLane);
        seg.resolve(hot, dead);
      }
      final valid = _wireValidLanes(seg);
      final aligned = valid.contains(busLane);

      if (aligned) {
        alignedTime += dt;
        mult = 1 + min(4, alignedTime * 0.5);
        score += (14 * mult) * dt;
        if (_rng.nextDouble() < dt * 14) {
          _spawnSpark(laneX(busLane), height * busYFrac - 34);
        }
      } else {
        _triggerDisconnect();
      }
    } else if (state == GameState.reconnecting) {
      reconnectTimeLeft -= dt;
      if (reconnectTimeLeft <= 0) _loseLife();
    }

    final targetX = laneX(busLane);
    busDrawX += (targetX - busDrawX) * min(1, dt * 10);

    if (flashT > 0) flashT = max(0, flashT - dt);

    _updateParticles(dt);
    notifyListeners();
  }

  void toggleMute() {
    sound.muted = !sound.muted;
    notifyListeners();
  }

  @override
  void dispose() {
    sound.dispose();
    super.dispose();
  }
}
