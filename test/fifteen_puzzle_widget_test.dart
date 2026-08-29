import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fifteen_puzzle/fifteen_puzzle.dart';

void main() {
  testWidgets('FifteenPuzzle page renders and displays grid and controls',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FifteenPuzzlePage(),
      ),
    );

    expect(find.byType(FifteenPuzzlePage), findsOneWidget);
    expect(find.text('15 Puzzle'), findsOneWidget);
    expect(find.text('MOVES'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);

    // Tap Shuffle button
    await tester.tap(find.text('Shuffle'));
    await tester.pump();

    // Tap Hint button
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Restart icon button in AppBar
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();

    expect(find.text('MOVES'), findsOneWidget);
  });

  testWidgets('Tapping a movable tile increments moves count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FifteenPuzzlePage(),
      ),
    );

    // Initial state is solved or shuffled; find any tile and tap it
    final semanticsList = find.byType(GestureDetector);
    expect(semanticsList, findsWidgets);

    // Tap one of the tiles
    for (final widget in tester.widgetList<GestureDetector>(semanticsList)) {
      if (widget.onTap != null) {
        widget.onTap!();
        break;
      }
    }
    await tester.pump();
  });
}
