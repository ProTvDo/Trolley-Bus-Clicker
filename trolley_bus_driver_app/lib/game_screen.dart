import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'bus_icon.dart';
import 'game_controller.dart';
import 'game_painter.dart';
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
  Duration _lastElapsed = Duration.zero;
  double _tick = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
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
                _buildQuitButton(),
                _buildWajchaControl(),
                _buildStopFlash(),
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
                    if (_game.state != GameState.start || _showLeaderboard) return const SizedBox.shrink();
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
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
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38),
                      ),
                    ],
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
      top: 56,
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

  Widget _buildQuitButton() {
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
            return _RoundButton(icon: '✕', onTap: () => _confirmQuit(context));
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

  Widget _buildStopFlash() {
    return Positioned(
      top: 90,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _game,
          builder: (context, _) {
            if (_game.stopFlashT <= 0 || _game.state != GameState.playing) return const SizedBox.shrink();
            final opacity = (_game.stopFlashT / 0.9).clamp(0.0, 1.0);
            final loc = AppLocalizations.of(context)!;
            return Center(
              child: Opacity(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: neonYellow.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    '🚏 ${loc.stopFlash(_game.stopsPassed, _game.stopsNeeded)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: neonYellow),
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
        const TrolleybusIcon(size: 72),
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
        const SizedBox(height: 22),
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
        TextButton(
          onPressed: () => setState(() => _showLeaderboard = true),
          child: Text(
            '🏆 ${loc.leaderboardButton}',
            style: const TextStyle(color: neonCyan, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        // Android-only: iOS forbids in-app quit buttons, and on web there's
        // nothing to close. defaultTargetPlatform (not dart:io's Platform)
        // so this file still compiles for the web build.
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(
              loc.closeApp,
              style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HowTo(icon: '👈', label: loc.howToLeft),
            const SizedBox(width: 18),
            _HowTo(icon: '👉', label: loc.howToRight),
            const SizedBox(width: 18),
            _HowTo(icon: '🔌', label: loc.howToReconnect),
          ],
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
  const _RoundButton({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 15))),
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

class _HowTo extends StatelessWidget {
  const _HowTo({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
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
