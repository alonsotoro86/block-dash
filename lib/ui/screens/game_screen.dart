import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../game/block_dash_game.dart';
import '../../state/app_state.dart';
import '../../theme/block_themes.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BlockDashGame _game;
  late final AppState _appState;
  int _score = 0;
  String? _comboText;
  bool _continueUsedThisGame = false;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _game = BlockDashGame(
      currentTheme: BlockThemes.byId(_appState.data.currentThemeId),
      onScoreChanged: (total, delta) => _safeSetState(() => _score = total),
      onLinesCleared: _handleLinesCleared,
      onGameOver: _handleGameOver,
      onCoinsEarned: (coins) => _appState.addCoins(coins),
      onConsumePowerUp: (id) => _appState.usePowerUp(id),
    );
  }

  /// Flame can invoke these callbacks (e.g. during `onLoad`) while Flutter
  /// is still in the middle of building this widget's subtree, which would
  /// make a direct `setState` throw. Deferring to the next frame keeps it
  /// safe regardless of when the game engine fires the callback.
  void _safeSetState(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  void _handleLinesCleared(int lines, int combo) {
    final text = switch (combo) {
      1 => null,
      2 => '¡Combo x2!',
      3 => '¡Genial!',
      4 => '¡Increíble!',
      _ => '¡ÉPICO x$combo!',
    };
    if (text == null) return;
    _safeSetState(() => _comboText = text);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _comboText = null);
    });
  }

  void _handleGameOver(int finalScore) {
    _appState.recordScore(finalScore);
    _appState.ads.maybeShowInterstitial();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _GameOverDialog(
          score: finalScore,
          canContinue: !_continueUsedThisGame,
          onContinue: () async {
            Navigator.of(context).pop();
            await _appState.watchRewardedFor(() async {
              _continueUsedThisGame = true;
              _game.board.reset();
              _game.startNewGame();
            });
          },
          onRetry: () {
            Navigator.of(context).pop();
            _continueUsedThisGame = false;
            _game.startNewGame();
          },
          onExit: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F3B),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(score: _score, coins: context.watch<AppState>().data.coins),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  GameWidget(game: _game),
                  if (_comboText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: _ComboBanner(text: _comboText!),
                    ),
                ],
              ),
            ),
            _PowerUpBar(game: _game),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int score;
  final int coins;
  const _TopBar({required this.score, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text('$score',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const Text('PUNTOS', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 4),
              Text('$coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComboBanner extends StatelessWidget {
  final String text;
  const _ComboBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) => Transform.scale(scale: 0.8 + value * 0.2, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}

class _PowerUpBar extends StatefulWidget {
  final BlockDashGame game;
  const _PowerUpBar({required this.game});

  @override
  State<_PowerUpBar> createState() => _PowerUpBarState();
}

class _PowerUpBarState extends State<_PowerUpBar> {
  static const _ids = ['hammer', 'bomb', 'swap', 'undo'];
  static const _icons = {
    'hammer': Icons.hardware,
    'bomb': Icons.circle,
    'swap': Icons.swap_horiz,
    'undo': Icons.undo,
  };
  static const _labels = {
    'hammer': 'Martillo',
    'bomb': 'Bomba',
    'swap': 'Swap',
    'undo': 'Deshacer',
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _ids.map((id) {
          final count = appState.powerUpCount(id);
          final armed = widget.game.activePowerUp == id;
          return _PowerUpButton(
            icon: _icons[id]!,
            label: _labels[id]!,
            count: count,
            armed: armed,
            onTap: count <= 0
                ? null
                : () async {
                    if (id == 'swap') {
                      await widget.game.useSwap();
                    } else if (id == 'undo') {
                      await widget.game.useUndo();
                    } else {
                      widget.game.armPowerUp(id);
                    }
                    setState(() {});
                  },
          );
        }).toList(),
      ),
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool armed;
  final VoidCallback? onTap;

  const _PowerUpButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.armed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: armed ? Colors.amberAccent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: armed ? Border.all(color: Colors.amberAccent) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: count > 0 ? Colors.white : Colors.white24, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: count > 0 ? Colors.white70 : Colors.white24)),
            Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: count > 0 ? Colors.white : Colors.white24)),
          ],
        ),
      ),
    );
  }
}

class _GameOverDialog extends StatelessWidget {
  final int score;
  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const _GameOverDialog({
    required this.score,
    required this.canContinue,
    required this.onContinue,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF262B52),
      title: const Text('¡Juego terminado!', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Puntaje: $score',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        if (canContinue)
          TextButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.play_circle, color: Colors.greenAccent),
            label: const Text('Ver anuncio y continuar', style: TextStyle(color: Colors.greenAccent)),
          ),
        TextButton(onPressed: onExit, child: const Text('Menú', style: TextStyle(color: Colors.white70))),
        ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}
