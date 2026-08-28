import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'achievements.dart';
import 'app_update.dart';
import 'bus_icon.dart';
import 'bus_skins.dart';
import 'game_controller.dart';
import 'game_painter.dart';
import 'gdynia_stops.dart';
import 'l10n/generated/app_localizations.dart';
import 'main.dart' show kBuildNumber, kUpdateDate, kUpdateNumber;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final GameController _game = GameController();
  late final Ticker _ticker;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  bool _nameControllerSynced = false;
  bool _showLeaderboard = false;
  bool _showAchievements = false;
  bool _showSkins = false;
  bool _showStopsAlbum = false;
  Duration _lastElapsed = Duration.zero;
  double _tick = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      AppUpdateService.instance.checkAndStart();
    }
  }

  void _onTick(Duration elapsed) {
    final dtMs = (elapsed - _lastElapsed).inMicroseconds / 1000.0;
    _lastElapsed = elapsed;
    final dt = (dtMs / 1000.0).clamp(0.0, 0.05);
    _tick = elapsed.inMilliseconds.toDouble();
    _game.update(dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _game.dispose();
    _focusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _game.moveLane(-1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _game.moveLane(1);
    } else if (_game.state == GameState.reconnecting) {
      _game.reconnectTap();
    } else if (_game.state == GameState.start && event.logicalKey == LogicalKeyboardKey.space) {
      _game.startGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A10),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    return CustomPaint(painter: GamePainter(_game, _tick), size: Size.infinite);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _game.handleZoneTap(true),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _game.handleZoneTap(false),
                      ),
                    ),
                  ],
                ),
                _buildHud(),
                _buildDestinationSign(),
                _buildMuteButton(),
                _buildPauseButton(),
                _buildStopButton(),
                _buildWajchaControl(),
                _buildStopFlash(),
                _buildAchievementToast(),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.reconnecting) return const SizedBox.shrink();
                    return _buildReconnectOverlay();
                  },
                ),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.start ||
                        _showLeaderboard ||
                        _showAchievements ||
                        _showSkins ||
                        _showStopsAlbum) {
                      return const SizedBox.shrink();
                    }
                    return _buildStartOverlay();
                  },
                ),
                // Sits above the start overlay in the Stack: the overlay paints
                // its own full-screen gradient, so anything drawn earlier would
                // be hidden behind it.
                _buildUpdateStamp(),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.start || !_showLeaderboard) return const SizedBox.shrink();
                    return _buildLeaderboardOverlay();
                  },
                ),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.start || !_showAchievements) return const SizedBox.shrink();
                    return _buildAchievementsOverlay();
                  },
                ),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.start || !_showSkins) return const SizedBox.shrink();
                    return _buildSkinsOverlay();
                  },
                ),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.start || !_showStopsAlbum) return const SizedBox.shrink();
                    return _buildStopsAlbumOverlay();
                  },
                ),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.gameOver) return const SizedBox.shrink();
                    return _buildGameOverOverlay();
                  },
                ),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.stageComplete) return const SizedBox.shrink();
                    return _buildStageCompleteOverlay();
                  },
                ),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.countdown) return const SizedBox.shrink();
                    return _buildCountdownOverlay();
                  },
                ),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (!_game.paused) return const SizedBox.shrink();
                    return _buildPausedOverlay();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: AnimatedBuilder(
            animation: _game,
            builder: (context, _) {
              final loc = AppLocalizations.of(context)!;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.hudScoreLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: neonYellow,
                        ),
                      ),
                      Text(
                        '${_game.score.floor()}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black54)],
                        ),
                      ),
                      if (_game.mult > 1.02)
                        Text(
                          'x${_game.mult.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: neonCyan),
                        ),
                    ],
                  ),
                  Flexible(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(GameController.maxLives, (i) {
                          final lost = i >= _game.lives;
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Opacity(
                              opacity: lost ? 0.25 : 1,
                              child: const Text('🦺', style: TextStyle(fontSize: 18)),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.hudStageStatus(_game.stage, _game.stopsPassed, _game.stopsNeeded),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38),
                      ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationSign() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF14141C).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: neonYellow.withValues(alpha: 0.4)),
            ),
            child: const Text(
              '🚎 GDYNIA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: neonYellow, letterSpacing: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMuteButton() {
    return Positioned(
      top: 62,
      right: 14,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _game,
          builder: (context, _) {
            return _RoundButton(
              icon: _game.sound.muted ? '🔇' : '🔊',
              onTap: _game.toggleMute,
            );
          },
        ),
      ),
    );
  }

  /// Bigger and neon-outlined (44px, cyan/pink) rather than the original
  /// 38px grey-on-grey circles - those were "prawie niewidoczne" (barely
  /// visible) against the busy game background, per user feedback.
  Widget _buildPauseButton() {
    return Positioned(
      top: 10,
      right: 64,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _game,
          builder: (context, _) {
            if (_game.state != GameState.playing || _game.paused) {
              return const SizedBox.shrink();
            }
            return _RoundButton(icon: '⏸', accent: neonCyan, size: 44, fontSize: 18, onTap: _game.pauseGame);
          },
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return Positioned(
      top: 10,
      right: 14,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _game,
          builder: (context, _) {
            const active = {
              GameState.playing,
              GameState.reconnecting,
              GameState.stageComplete,
              GameState.countdown,
            };
            if (!active.contains(_game.state)) return const SizedBox.shrink();
            return _RoundButton(icon: '⏹', accent: neonPink, size: 44, fontSize: 18, onTap: () => _confirmQuit(context));
          },
        ),
      ),
    );
  }

  Future<void> _confirmQuit(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14141C),
        title: Text(loc.quitDialogTitle, style: const TextStyle(color: Colors.white)),
        content: Text(
          _game.stage > 1 ? loc.quitDialogBodySaved(_game.stage) : loc.quitDialogBodyPlain,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.quitConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) _game.quitToStart();
  }

  /// "Aktualizacja nr 2 · 28.07.2026" pinned to the start screen's bottom-left
  /// corner, so a returning player can see the game was updated. The date
  /// arrives as ISO (see kUpdateDate) and is reformatted for the player's
  /// locale; if it's missing or unparseable, only the number is shown.
  Widget _buildUpdateStamp() {
    return Positioned(
      left: 0,
      bottom: 0,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _game,
          builder: (context, _) {
            if (_game.state != GameState.start || _showLeaderboard) {
              return const SizedBox.shrink();
            }
            final loc = AppLocalizations.of(context)!;
            final localeName = Localizations.localeOf(context).toLanguageTag();
            var text = '${loc.updateLabel} $kUpdateNumber';
            if (kUpdateDate.isNotEmpty) {
              final parsed = DateTime.tryParse(kUpdateDate);
              final shown = parsed == null
                  ? kUpdateDate
                  : DateFormat.yMd(localeName).format(parsed);
              text = '$text · $shown';
            }
            return Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 10),
              child: Text(
                text,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white38),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Stop plaque styled after a real trolleybus stop sign: the Gdynia stop
  /// name, a one-line city fact, and the stage's stop counter. Holds steady
  /// for most of its lifetime and only fades over the last moments, so the
  /// text stays readable while the bus keeps moving underneath.
  Widget _buildStopFlash() {
    return Positioned(
      top: 84,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _game,
          builder: (context, _) {
            final stop = _game.currentStop;
            if (_game.stopFlashT <= 0 || stop == null || _game.state != GameState.playing) {
              return const SizedBox.shrink();
            }
            final opacity = (_game.stopFlashT / 0.8).clamp(0.0, 1.0);
            final loc = AppLocalizations.of(context)!;
            final lang = Localizations.localeOf(context).languageCode;
            return Center(
              child: Opacity(
                opacity: opacity,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141C).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: neonYellow.withValues(alpha: 0.7), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: neonYellow.withValues(alpha: 0.25),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🚏 ${stop.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: neonYellow,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        stop.storyFor(lang),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.stopFlash(_game.stopsPassed, _game.stopsNeeded),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white38,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Small banner for a just-unlocked achievement, deliberately placed near
  /// the bottom of the screen (unlike the Gdynia stop plaque up top) so the
  /// two never fight for the same space when both fire close together.
  Widget _buildAchievementToast() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _game,
          builder: (context, _) {
            final id = _game.justUnlockedAchievementId;
            if (_game.achievementToastT <= 0 || id == null) return const SizedBox.shrink();
            Achievement? achievement;
            for (final a in kAchievements) {
              if (a.id == id) {
                achievement = a;
                break;
              }
            }
            if (achievement == null) return const SizedBox.shrink();
            final opacity = (_game.achievementToastT / 0.6).clamp(0.0, 1.0);
            final loc = AppLocalizations.of(context)!;
            final lang = Localizations.localeOf(context).languageCode;
            return Center(
              child: Opacity(
                opacity: opacity,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141C).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: neonCyan.withValues(alpha: 0.7), width: 1.5),
                    boxShadow: [BoxShadow(color: neonCyan.withValues(alpha: 0.25), blurRadius: 16)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(achievement.icon, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loc.achievementUnlockedPrefix,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: neonCyan, letterSpacing: 0.6),
                            ),
                            Text(
                              achievement.nameFor(lang),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWajchaControl() {
    return Positioned(
      bottom: 22,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _game,
          builder: (context, _) {
            if (_game.state != GameState.playing || !_game.switchModeActive) {
              return const SizedBox.shrink();
            }
            return Center(child: _WajchaControl(dir: _game.wajchaDir, onSet: _game.setWajcha));
          },
        ),
      ),
    );
  }

  Widget _buildReconnectOverlay() {
    final progress = (_game.reconnectTimeLeft / GameController.reconnectTime).clamp(0.0, 1.0);
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${loc.reconnectPrompt}⚡',
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: neonYellow),
          ),
          const SizedBox(height: 6),
          Text(
            loc.reconnectTapsLeft(_game.reconnectTapsLeft.clamp(0, 999)),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Container(
            width: 140,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [neonPink, neonYellow]),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartOverlay() {
    final loc = AppLocalizations.of(context)!;
    return _Overlay(
      children: [
        TrolleybusIcon(size: 72, skin: _game.currentSkin),
        const SizedBox(height: 14),
        const Text(
          'Trolley Bus Driver',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          loc.startTagline,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: neonYellow),
        ),
        const SizedBox(height: 14),
        Text(
          loc.startSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<bool>(
          valueListenable: AppUpdateService.instance.ready,
          builder: (context, updateReady, _) {
            if (!updateReady) return const SizedBox.shrink();
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => AppUpdateService.instance.completeUpdate(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: neonCyan.withValues(alpha: 0.14),
                    border: Border.all(color: neonCyan.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    '⬇️ ${loc.updateReadyBanner}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: neonCyan, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (_game.savedStage != null) ...[
          _PlayButton(label: loc.continueStage(_game.savedStage!), onTap: _game.continueGame),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _game.startNewGame,
            child: Text(
              loc.newGame,
              style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ] else
          _PlayButton(label: loc.play, onTap: _game.startGame),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: TextButton(
                onPressed: () => setState(() => _showLeaderboard = true),
                child: Text(
                  '🏆 ${loc.leaderboardButton}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: neonCyan, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
            Flexible(
              child: TextButton(
                onPressed: () => setState(() => _showAchievements = true),
                child: Text(
                  '🎖️ ${loc.achievementsButton}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: neonCyan, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: TextButton(
                onPressed: () => setState(() => _showSkins = true),
                child: Text(
                  '🎨 ${loc.skinsButton}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: neonCyan, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
            Flexible(
              child: TextButton(
                onPressed: () => setState(() => _showStopsAlbum = true),
                child: Text(
                  '📖 ${loc.stopsAlbumButton}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: neonCyan, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        // Android-only: iOS forbids in-app quit buttons, and on web there's
        // nothing to close. defaultTargetPlatform (not dart:io's Platform)
        // so this file still compiles for the web build.
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => SystemNavigator.pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: neonPink.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '⏻ ${loc.closeApp}',
                  style: const TextStyle(color: neonPink, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _HowTo(icon: '👈', label: loc.howToLeft)),
              Expanded(child: _HowTo(icon: '👉', label: loc.howToRight)),
              Expanded(child: _HowTo(icon: '🔌', label: loc.howToReconnect)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Presented by: fb @Trajtekzbroda',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white38),
        ),
        const SizedBox(height: 4),
        const Text(
          'Powered by protvdo.pl',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white38),
        ),
        const SizedBox(height: 6),
        Text(
          'build $kBuildNumber',
          style: const TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildGameOverOverlay() {
    if (!_nameControllerSynced && _game.driverName.isNotEmpty) {
      _nameController.text = _game.driverName;
      _nameControllerSynced = true;
    }
    final loc = AppLocalizations.of(context)!;
    return _Overlay(
      children: [
        Text(
          loc.gameOverTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        Text(
          '${_game.score.floor()}',
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: neonYellow),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
              children: [
                TextSpan(text: loc.bestScoreLabel),
                TextSpan(text: '${_game.best}', style: const TextStyle(color: neonCyan, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_game.scoreSaved)
          Text(
            '✓ ${loc.scoreSavedConfirm}',
            style: const TextStyle(color: neonCyan, fontWeight: FontWeight.w700, fontSize: 13),
          )
        else ...[
          SizedBox(
            width: 220,
            child: TextField(
              controller: _nameController,
              maxLength: 16,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: _game.setDriverName,
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                hintText: loc.driverNameHint,
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                _game.setDriverName(_nameController.text);
                _game.saveScoreToLeaderboard();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: neonCyan),
                ),
                child: Text(
                  loc.saveToLeaderboard,
                  style: const TextStyle(color: neonCyan, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _PlayButton(label: loc.playAgain, onTap: _game.startGame),
      ],
    );
  }

  Widget _buildLeaderboardOverlay() {
    final entries = _game.leaderboard;
    final loc = AppLocalizations.of(context)!;
    return _Overlay(
      children: [
        Text(
          '🏆 ${loc.leaderboardTitle}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Text(
            loc.leaderboardEmpty,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320, minWidth: 240),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text(
                              '${i + 1}.',
                              style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entries[i].name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          Text(
                            '${entries[i].score}',
                            style: const TextStyle(color: neonYellow, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        _PlayButton(label: loc.back, onTap: () => setState(() => _showLeaderboard = false)),
      ],
    );
  }

  Widget _buildAchievementsOverlay() {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final unlocked = _game.unlockedAchievements;
    return _Overlay(
      children: [
        Text(
          '🎖️ ${loc.achievementsButton}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          loc.achievementsProgress(unlocked.length, kAchievements.length),
          style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400, minWidth: 260),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final a in kAchievements)
                  _AchievementRow(
                    achievement: a,
                    unlocked: unlocked.contains(a.id),
                    lang: lang,
                    lockedLabel: loc.achievementsLocked,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _PlayButton(label: loc.back, onTap: () => setState(() => _showAchievements = false)),
      ],
    );
  }

  Widget _buildSkinsOverlay() {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return _Overlay(
      children: [
        Text(
          '🎨 ${loc.skinsButton}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 14),
        TrolleybusIcon(size: 60, skin: _game.currentSkin),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360, minWidth: 260),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final skin in kBusSkins)
                  _SkinRow(
                    skin: skin,
                    selected: _game.selectedSkinId == skin.id,
                    unlocked: _game.isSkinUnlocked(skin),
                    lang: lang,
                    lockedHint: skin.requiresAchievement == null
                        ? ''
                        : loc.skinLockedHint(_achievementNameFor(skin.requiresAchievement!, lang)),
                    onTap: () => _game.selectSkin(skin.id),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _PlayButton(label: loc.back, onTap: () => setState(() => _showSkins = false)),
      ],
    );
  }

  String _achievementNameFor(String achievementId, String lang) {
    for (final a in kAchievements) {
      if (a.id == achievementId) return a.nameFor(lang);
    }
    return achievementId;
  }

  /// Browsable collection of every Gdynia stop the player has ever had
  /// shown on the plaque (see GameController.seenStopIndices) - the same
  /// data that backs the "odkrywca"/"przewodnik" achievements, just given
  /// its own place to revisit rather than only flashing by mid-run.
  Widget _buildStopsAlbumOverlay() {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final seen = _game.seenStopIndices;
    return _Overlay(
      children: [
        Text(
          '📖 ${loc.stopsAlbumButton}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          loc.stopsAlbumProgress(seen.length, kGdyniaStops.length),
          style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400, minWidth: 260),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < kGdyniaStops.length; i++)
                  _StopRow(
                    stop: kGdyniaStops[i],
                    unlocked: seen.contains(i),
                    lang: lang,
                    lockedLabel: loc.stopsAlbumLocked,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _PlayButton(label: loc.back, onTap: () => setState(() => _showStopsAlbum = false)),
      ],
    );
  }

  Widget _buildStageCompleteOverlay() {
    final loc = AppLocalizations.of(context)!;
    return _Overlay(
      children: [
        Text(
          loc.stageComplete(_game.stage),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(GameController.maxLives, (i) {
            final earned = i < _game.lives;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                earned ? '⭐' : '☆',
                style: TextStyle(fontSize: 40, color: earned ? neonYellow : Colors.white24),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Text(
          loc.scoreLabel(_game.score.floor()),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildCountdownOverlay() {
    final loc = AppLocalizations.of(context)!;
    final labels = ['3', '2', '1', loc.go];
    return _Overlay(
      children: [
        Text(
          loc.nextStage(_game.stage + 1),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          labels[3 - _game.countdownStep],
          style: TextStyle(
            fontSize: _game.countdownStep == 0 ? 44 : 72,
            fontWeight: FontWeight.w800,
            color: neonYellow,
            shadows: const [Shadow(blurRadius: 18, color: neonYellow)],
          ),
        ),
      ],
    );
  }

  Widget _buildPausedOverlay() {
    final loc = AppLocalizations.of(context)!;
    return _Overlay(
      children: [
        const Text('⏸', style: TextStyle(fontSize: 48, color: neonCyan)),
        const SizedBox(height: 8),
        Text(
          loc.pauseButton,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 24),
        _PlayButton(label: '▶ ${loc.resumeButton}', onTap: _game.resumeGame),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => _confirmQuit(context),
          child: Text(
            '⏹ ${loc.stopButton}',
            style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.1,
          colors: [Color(0xD8281438), Color(0xF206060C)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [neonYellow, Color(0xFFFFB84D)]),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0A0A10)),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.accent,
    this.size = 38,
    this.fontSize = 15,
  });

  final String icon;
  final VoidCallback onTap;

  /// Tint for background/border - null keeps the original barely-there grey
  /// look, used only by the mute button. Pause/stop pass a neon accent so
  /// they actually stand out against the busy game background instead of
  /// blending into it (the original complaint: the quit "✕" was nearly
  /// invisible).
  final Color? accent;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final tint = accent;
    return Material(
      color: tint?.withValues(alpha: 0.22) ?? Colors.white.withValues(alpha: 0.08),
      shape: CircleBorder(side: BorderSide(color: tint?.withValues(alpha: 0.85) ?? Colors.white24, width: tint != null ? 1.5 : 1)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: Text(icon, style: TextStyle(fontSize: fontSize, color: tint ?? Colors.white))),
        ),
      ),
    );
  }
}

class _WajchaControl extends StatelessWidget {
  const _WajchaControl({required this.dir, required this.onSet});

  final int dir;
  final void Function(int dir) onSet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WajchaHalf(label: '⬅', selected: dir == -1, onTap: () => onSet(-1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              AppLocalizations.of(context)!.wajchaLabel,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white38, letterSpacing: 1),
            ),
          ),
          _WajchaHalf(label: '➡', selected: dir == 1, onTap: () => onSet(1)),
        ],
      ),
    );
  }
}

class _WajchaHalf extends StatelessWidget {
  const _WajchaHalf({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFF8A2B) : Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 18, color: selected ? const Color(0xFF0A0A10) : Colors.white70)),
          ),
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.achievement,
    required this.unlocked,
    required this.lang,
    required this.lockedLabel,
  });

  final Achievement achievement;
  final bool unlocked;
  final String lang;
  final String lockedLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Opacity(
        opacity: unlocked ? 1 : 0.4,
        child: Row(
          children: [
            Text(unlocked ? achievement.icon : '🔒', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlocked ? achievement.nameFor(lang) : lockedLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: unlocked ? Colors.white : Colors.white60,
                    ),
                  ),
                  if (unlocked)
                    Text(
                      achievement.descriptionFor(lang),
                      style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkinRow extends StatelessWidget {
  const _SkinRow({
    required this.skin,
    required this.selected,
    required this.unlocked,
    required this.lang,
    required this.lockedHint,
    required this.onTap,
  });

  final BusSkin skin;
  final bool selected;
  final bool unlocked;
  final String lang;
  final String lockedHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.45,
      child: Material(
        color: selected ? neonCyan.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: unlocked ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                TrolleybusIcon(size: 34, skin: skin),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skin.nameFor(lang),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: unlocked ? Colors.white : Colors.white60,
                        ),
                      ),
                      if (!unlocked)
                        Text(
                          lockedHint,
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  const Text('✓', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: neonCyan))
                else if (!unlocked)
                  const Text('🔒', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.unlocked,
    required this.lang,
    required this.lockedLabel,
  });

  final GdyniaStop stop;
  final bool unlocked;
  final String lang;
  final String lockedLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Opacity(
        opacity: unlocked ? 1 : 0.4,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unlocked ? '🚏' : '🔒', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlocked ? stop.name : lockedLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: unlocked ? Colors.white : Colors.white60,
                    ),
                  ),
                  if (unlocked)
                    Text(
                      stop.storyFor(lang),
                      style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowTo extends StatelessWidget {
  const _HowTo({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Each item lives in its own Expanded 1/3rd of the row's real width -
      // no fixed width here, so it scales down safely on narrow phones
      // instead of forcing the row wider than the screen (the exact bug
      // this replaced: 3 fixed 90px boxes didn't fit in a 320px-wide phone).
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
