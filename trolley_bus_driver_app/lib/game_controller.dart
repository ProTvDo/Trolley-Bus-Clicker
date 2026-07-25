import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio.dart';
import 'models.dart';

enum GameState { start, playing, reconnecting, gameOver, stageComplete, countdown }

class GameController extends ChangeNotifier {
  GameController() {
    _loadBest();
    _resetTrack();
    sound.startMusic();
  }

  // ---- tunables (mirrors the original web game) ----
  static const lanes = 3;
  static const roadFrac = 0.7;
  static const busYFrac = 0.78;
  static const baseSpeed = 180.0;
  static const maxSpeedAdd = 160.0;
  static const maxLives = 5;
  static const tapsNeeded = 3;
  static const reconnectTime = 4.0;
  static const celebrationDuration = 2.4;
  static const countdownStepDuration = 0.8;

  // ---- stages ----
  // A stage is a route with a number of bus stops (przystanki) to reach;
  // clearing the last one pauses play for a celebration (stars = lives
  // remaining) then a countdown before the next, longer and harder stage
  // begins. Stages go on forever - there's no final one.
  int stage = 1;

  int _stopsForStage(int n) => 2 + n;

  double _stopSpacingForStage(int n) => 650 + n * 40;

  int stopsNeeded = 0;
  int stopsPassed = 0;
  List<double> stopPositions = const [];
  double stopFlashT = 0;

  void _setupStops() {
    final spacing = _stopSpacingForStage(stage);
    stopsNeeded = _stopsForStage(stage);
    stopsPassed = 0;
    stopPositions = [for (var i = 1; i <= stopsNeeded; i++) i * spacing];
  }

  // ---- difficulty tiers, driven by stage ----
  // Stage 1: only adjacent-lane wire changes, generous reaction window.
  // Stage 2: two-lane jumps introduced, window scales with jump size so
  //          it stays exactly as fair (per-lane) as a stage-1 change.
  // Stage 3: same jumps, tighter window - a real skill test.
  // Stage 4+: zwrotnice (switches) - the wire no longer picks its own
  //          direction; it forks and follows whichever way the player's
  //          wajcha (lever) is set to at the moment it's reached. Beyond
  //          stage 4 the mechanics stay the same but speed keeps climbing
  //          and the reaction window keeps shrinking (down to a floor).
  int get level => min(4, stage);

  int get maxJump => level >= 2 ? 2 : 1;

  bool get switchModeActive => level >= 4;

  /// Chance that a new switch gets a car parked on one of its two branches,
  /// forcing the player to have the wajcha already pointed the other way by
  /// the time it resolves. Ramps in gradually from stage 10 to 15 (so the
  /// lever stays optional for a good while after switches first appear at
  /// stage 4), then holds at a cap - difficulty keeps climbing beyond that
  /// from speed and the shrinking reaction window instead.
  double get _hazardChance {
    if (!switchModeActive) return 0;
    return ((stage - 10) / 5).clamp(0.0, 1.0) * 0.7;
  }

  static const hazardHitWindow = 28.0;

  double get _baseSpeedForStage => baseSpeed + (stage - 1) * 8;

  double get _maxSpeedAddForStage => maxSpeedAdd + (stage - 1) * 12;

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
    if (stage <= 1) return 170;
    if (stage == 2) return 150;
    if (stage == 3) return 120;
    return max(70, 120 - (stage - 3) * 10);
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

  double celebrationTimeLeft = 0;
  int countdownStep = 0;
  double countdownTimer = 0;

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

  static const maxLeaderboardEntries = 10;
  List<LeaderboardEntry> leaderboard = [];
  String driverName = '';
  bool scoreSaved = false;

  /// Stage to resume at from the start screen's "Kontynuuj" button, or null
  /// if there's nothing paused - set by [quitToStart], cleared once consumed
  /// by [continueGame]/[startNewGame] or once a run actually ends in
  /// [_endGame] (a game over closes out the paused run it belonged to).
  int? savedStage;

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    best = prefs.getInt('zlapprad_best') ?? 0;
    driverName = prefs.getString('zlapprad_driver_name') ?? '';
    final saved = prefs.getInt('zlapprad_saved_stage');
    savedStage = (saved != null && saved > 1) ? saved : null;
    leaderboard = (prefs.getStringList('zlapprad_leaderboard') ?? [])
        .map(LeaderboardEntry.decode)
        .whereType<LeaderboardEntry>()
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    notifyListeners();
  }

  Future<void> _saveBest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zlapprad_best', best);
  }

  Future<void> _persistSavedStage(int? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('zlapprad_saved_stage');
    } else {
      await prefs.setInt('zlapprad_saved_stage', value);
    }
  }

  void setDriverName(String name) {
    driverName = name;
  }

  /// Adds the just-finished run to the top-10 leaderboard under the current
  /// [driverName] (once per run - see [scoreSaved]) and remembers the name
  /// for next time.
  Future<void> saveScoreToLeaderboard() async {
    if (scoreSaved) return;
    scoreSaved = true;
    final name = driverName.trim().isEmpty ? 'Kierowca' : driverName.trim();
    leaderboard = [...leaderboard, LeaderboardEntry(name: name, score: score.floor())]
      ..sort((a, b) => b.score.compareTo(a.score));
    if (leaderboard.length > maxLeaderboardEntries) {
      leaderboard = leaderboard.sublist(0, maxLeaderboardEntries);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('zlapprad_driver_name', name);
    await prefs.setStringList('zlapprad_leaderboard', leaderboard.map((e) => e.encode()).toList());
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
    if (switchModeActive) return TrackSegment.generateSwitch(prev, _rng, lanes: lanes, hazardChance: _hazardChance);
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

  void startGame({int? atStage}) {
    stage = atStage ?? 1;
    score = 0;
    scoreSaved = false;
    lives = maxLives;
    busLane = 1;
    busDrawX = laneX(1);
    scrollY = 0;
    speed = _baseSpeedForStage;
    alignedTime = 0;
    mult = 1;
    particles.clear();
    state = GameState.playing;
    _resetTrack();
    _setupStops();
    notifyListeners();
  }

  /// Resumes at the stage saved by [quitToStart], or starts a normal fresh
  /// run if there's nothing saved.
  void continueGame() => startGame(atStage: savedStage);

  /// Explicitly starts over from stage 1, discarding any saved checkpoint.
  void startNewGame() {
    savedStage = null;
    _persistSavedStage(null);
    startGame();
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

  void _loseLife({bool playSound = true}) {
    lives--;
    if (lives <= 0) {
      _endGame();
    } else {
      if (playSound) sound.loseLife();
      busLane = currentSegment().lane;
      state = GameState.playing;
    }
  }

  /// Fired the instant the bus reaches a hazard obstacle it didn't dodge -
  /// unlike a wire disconnect this skips the reconnect tap-QTE entirely and
  /// costs a life outright, since "still electrically connected" doesn't
  /// save you from having physically driven into a parked car.
  void _hitObstacle() {
    flashT = 0.3;
    sound.crash();
    HapticFeedback.heavyImpact();
    _loseLife(playSound: false);
  }

  void _endGame() {
    state = GameState.gameOver;
    sound.gameOver();
    if (score > best) {
      best = score.floor();
      _saveBest();
    }
    if (savedStage != null) {
      savedStage = null;
      _persistSavedStage(null);
    }
  }

  /// Player-initiated exit back to the start screen (the in-game quit
  /// button), as opposed to [_endGame] which fires when lives run out.
  /// Unlike a game over, this saves the current stage so the start screen's
  /// "Kontynuuj" button can pick the difficulty back up from here.
  void quitToStart() {
    if (state != GameState.playing &&
        state != GameState.reconnecting &&
        state != GameState.stageComplete &&
        state != GameState.countdown) {
      return;
    }
    if (score > best) {
      best = score.floor();
      _saveBest();
    }
    savedStage = stage > 1 ? stage : null;
    _persistSavedStage(savedStage);
    state = GameState.start;
    notifyListeners();
  }

  /// Called when the last stop of this stage's route is reached. Play
  /// pauses for a celebration (stars = lives remaining), then a countdown,
  /// then the next, longer and harder stage begins - see [update].
  void _completeStage() {
    state = GameState.stageComplete;
    celebrationTimeLeft = celebrationDuration;
    sound.success();
    HapticFeedback.mediumImpact();
    for (var i = 0; i < 18; i++) {
      _spawnSpark(
        width / 2 + (_rng.nextDouble() * 2 - 1) * width * 0.3,
        height * 0.4 + (_rng.nextDouble() * 2 - 1) * 60,
      );
    }
  }

  void _beginCountdown() {
    state = GameState.countdown;
    countdownStep = 3;
    countdownTimer = countdownStepDuration;
  }

  void _startStage() {
    stage++;
    busLane = 1;
    busDrawX = laneX(1);
    scrollY = 0;
    speed = _baseSpeedForStage;
    alignedTime = 0;
    mult = 1;
    particles.clear();
    state = GameState.playing;
    _resetTrack();
    _setupStops();
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
      case GameState.stageComplete:
      case GameState.countdown:
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
    switch (state) {
      case GameState.playing:
        scrollY += speed * dt;
        speed = _baseSpeedForStage + min(_maxSpeedAddForStage, score * 0.025);
        _ensureTrackAhead();

        if (stopFlashT > 0) stopFlashT = max(0, stopFlashT - dt);
        if (stopsPassed < stopPositions.length && scrollY >= stopPositions[stopsPassed]) {
          stopsPassed++;
          stopFlashT = 0.9;
          sound.tap();
          HapticFeedback.lightImpact();
          if (stopsPassed >= stopsNeeded) {
            _completeStage();
            break;
          }
        }

        final seg = currentSegment();
        if (seg.isSwitch && !seg.resolved) {
          final (hot, dead) = resolveSwitchTargets(seg.fromLane);
          seg.resolve(hot, dead);
        }

        for (final ob in seg.obstacles) {
          if (ob.isHazard && !ob.hit && ob.lane == busLane && (scrollY - ob.d).abs() < hazardHitWindow) {
            ob.hit = true;
            _hitObstacle();
            break;
          }
        }
        if (state != GameState.playing) break;

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
        break;
      case GameState.reconnecting:
        reconnectTimeLeft -= dt;
        if (reconnectTimeLeft <= 0) _loseLife();
        break;
      case GameState.stageComplete:
        celebrationTimeLeft -= dt;
        if (celebrationTimeLeft <= 0) _beginCountdown();
        break;
      case GameState.countdown:
        countdownTimer -= dt;
        if (countdownTimer <= 0) {
          if (countdownStep == 0) {
            _startStage();
          } else {
            countdownStep--;
            countdownTimer = countdownStepDuration;
            sound.tap();
          }
        }
        break;
      case GameState.start:
      case GameState.gameOver:
        break;
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
