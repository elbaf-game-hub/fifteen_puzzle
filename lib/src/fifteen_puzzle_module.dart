part of '../fifteen_puzzle.dart';

GameModule get fifteenPuzzleModule => const _FifteenPuzzleModule();

class _FifteenPuzzleModule implements GameModule {
  const _FifteenPuzzleModule();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: 'fifteen_puzzle',
        name: '15 Puzzle',
        description: 'Slide tiles into order.',
        icon: Icons.grid_4x4_outlined,
        color: Color(0xFFCBB58E),
        build: _buildPage,
      );

  static Widget _buildPage(BuildContext context) => const FifteenPuzzlePage();
}
