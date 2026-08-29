import 'dart:async';
import 'package:flutter/material.dart';
import 'package:game_assets/game_assets.dart';

import 'fifteen_puzzle_state.dart';

class FifteenPuzzlePage extends StatefulWidget {
  const FifteenPuzzlePage({super.key});

  @override
  State<FifteenPuzzlePage> createState() => _FifteenPuzzlePageState();
}

class _FifteenPuzzlePageState extends State<FifteenPuzzlePage> {
  late FifteenState _state;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _state = FifteenState.shuffled();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _state.status != FifteenStatus.playing || _state.moves == 0) {
        return;
      }
      setState(() {
        _state = _state.tickElapsed(const Duration(seconds: 1));
      });
    });
  }

  void _onTapTile(int index) {
    if (_state.status == FifteenStatus.won) return;
    if (!_state.canMove(index)) return;

    final nextState = _state.tap(index);
    setState(() {
      _state = nextState;
    });

    SfxPlayer.instance.play('tap');

    if (nextState.status == FifteenStatus.won) {
      _timer?.cancel();
      SfxPlayer.instance.play('win');
      _showWinDialog();
    }
  }

  void _restartGame() {
    setState(() {
      _state = _state.reset();
    });
    _startTimer();
  }

  void _showWinDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.emoji_events, color: GameTokens.warning),
                SizedBox(width: 8),
                Text('Puzzle Solved!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Moves: ${_state.moves}'),
                const SizedBox(height: 4),
                Text('Time: ${_formatDuration(_state.elapsed)}'),
                if (_state.bestMoves != null) ...[
                  const Divider(),
                  Text('Best Moves: ${_state.bestMoves}'),
                ],
                if (_state.bestTimeMs != null)
                  Text(
                    'Best Time: ${_formatDuration(Duration(milliseconds: _state.bestTimeMs!))}',
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).maybePop();
                },
                child: const Text('Exit'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _restartGame();
                },
                child: const Text('New Game'),
              ),
            ],
          );
        },
      );
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildGameTheme(Brightness.dark),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        appBar: GameAppBar(
          title: '15 Puzzle',
          score: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatPill('MOVES', '${_state.moves}', GameTokens.primary),
              const SizedBox(width: 8),
              _buildStatPill('TIME', _formatDuration(_state.elapsed), GameTokens.warning),
            ],
          ),
          onRestart: _restartGame,
          onSettings: () {
            // Hint action: find the first valid move and suggest it
            final valid = _state.validMoves();
            if (valid.isNotEmpty) {
              final tileNum = _state.tiles[valid.first];
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hint: Tile $tileNum can move!'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF030712),
                        borderRadius: BorderRadius.circular(GameTokens.radiusLg),
                        border: Border.all(
                          color: const Color(0xFF1E293B),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: 16,
                              itemBuilder: (context, index) {
                                final tileVal = _state.tiles[index];
                                final isBlank = tileVal == 0;
                                final canSlide = _state.canMove(index);

                                final String svgPath = isBlank
                                    ? 'assets/svg/fifteen_puzzle/tile_blank.svg'
                                    : 'assets/svg/fifteen_puzzle/tile_$tileVal.svg';

                                return Semantics(
                                  button: !isBlank,
                                  label: isBlank
                                      ? 'Empty space'
                                      : 'Tile $tileVal${canSlide ? ', movable' : ''}',
                                  child: GestureDetector(
                                    onTap: () => _onTapTile(index),
                                    child: _buildTileContainer(tileVal, isBlank, svgPath),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _restartGame,
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('Shuffle'),
                          style: FilledButton.styleFrom(
                            backgroundColor: GameTokens.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Quick hint
                            final valid = _state.validMoves();
                            if (valid.isNotEmpty) {
                              final tileNum = _state.tiles[valid.first];
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Try moving tile $tileNum'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: const Text('Hint'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF334155)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GameTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileContainer(int tileVal, bool isBlank, String svgPath) {
    if (isBlank) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(GameTokens.radiusMd),
          border: Border.all(color: const Color(0xFF1E293B), width: 1),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Top shine highlight
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '$tileVal',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
