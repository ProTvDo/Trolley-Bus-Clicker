import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'game_controller.dart';
import 'game_painter.dart';
import 'main.dart' show kBuildNumber;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final GameController _game = GameController();
  late final Ticker _ticker;
  final FocusNode _focusNode = FocusNode();
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
                _buildMuteButton(),
                _buildWajchaControl(),
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
                    if (_game.state != GameState.start) return const SizedBox.shrink();
                    return _buildStartOverlay();
                  },
                ),
                AnimatedBuilder(
                  animation: _game,
                  builder: (context, _) {
                    if (_game.state != GameState.gameOver) return const SizedBox.shrink();
                    return _buildGameOverOverlay();
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
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WYNIK',
                        style: TextStyle(
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
                            padding: const EdgeInsets.only(left: 6),
                            child: Opacity(
                              opacity: lost ? 0.25 : 1,
                              child: const Text('🦺', style: TextStyle(fontSize: 22)),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'poziom ${_game.level}',
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

  Widget _buildMuteButton() {
    return Positioned(
      top: 10,
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'KLIKAJ!⚡',
            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: neonYellow),
          ),
          const SizedBox(height: 6),
          Text(
            '${_game.reconnectTapsLeft.clamp(0, 999)} razy',
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
    return _Overlay(
      children: [
        const Text(
          '⚡ Złap Prąd! ⚡',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Prowadź trolejbus pod przewodami trakcyjnymi. Im dłużej jedziesz idealnie pod kablem, tym szybciej rosną punkty!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 22),
        _PlayButton(label: 'Zagraj', onTap: _game.startGame),
        const SizedBox(height: 26),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HowTo(icon: '👈', label: 'lewa strona ekranu = lewy pas'),
            SizedBox(width: 18),
            _HowTo(icon: '👉', label: 'prawa strona ekranu = prawy pas'),
            SizedBox(width: 18),
            _HowTo(icon: '🔌', label: 'zgubisz kabel? klikaj szybko!'),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'build $kBuildNumber',
          style: const TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildGameOverOverlay() {
    return _Overlay(
      children: [
        const Text(
          'BZZZT! Wypadłeś z linii',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70),
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
                const TextSpan(text: 'Najlepszy wynik: '),
                TextSpan(text: '${_game.best}', style: const TextStyle(color: neonCyan, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PlayButton(label: 'Jeszcze raz', onTap: _game.startGame),
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
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.1,
          colors: [Color(0xD8281438), Color(0xF206060C)],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('WAJCHA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white38, letterSpacing: 1)),
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
