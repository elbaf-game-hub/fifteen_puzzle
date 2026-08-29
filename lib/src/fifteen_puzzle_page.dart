import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final theme = buildGameTheme(Brightness.light);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: GameAppBar(
          title: '15 Puzzle',
          score: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GameTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GameTokens.radiusSm),
                ),
                child: Text(
                  'Moves: ${_state.moves}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: GameTokens.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GameTokens.boardDark.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(GameTokens.radiusSm),
                ),
                child: Text(
                  _formatDuration(_state.elapsed),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
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
                ),
              );
            }
          },
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameBoardArea(
                    aspectRatio: 1.0,
                    maxSide: 460,
                    padding: const EdgeInsets.all(GameTokens.sm),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final gridSize = constraints.maxWidth;
                        final tileSize = (gridSize - 24) / 4;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
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
                                child: AnimatedContainer(
                                  duration: GameTokens.durFast,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        GameTokens.radiusMd),
                                    boxShadow: !isBlank
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                  alpha: 0.08),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        GameTokens.radiusMd),
                                    child: SvgPicture.asset(
                                      svgPath,
                                      package: 'game_assets',
                                      fit: BoxFit.cover,
                                      placeholderBuilder: (context) =>
                                          _buildFallbackTile(tileVal, isBlank),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _restartGame,
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Shuffle'),
                      ),
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
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Hint'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackTile(int tileVal, bool isBlank) {
    if (isBlank) {
      return Container(
        decoration: BoxDecoration(
          color: GameTokens.boardDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2D9A1),
        borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        border: Border.all(color: const Color(0xFFB89A6A), width: 2),
      ),
      child: Center(
        child: Text(
          '$tileVal',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5B3A1A),
          ),
        ),
      ),
    );
  }
}
