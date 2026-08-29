import 'package:flutter/material.dart';
import 'package:game_module/game_module.dart';

import 'fifteen_puzzle_page.dart';

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
