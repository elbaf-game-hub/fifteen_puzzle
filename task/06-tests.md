# 06 — Tests

Two test files: `test/fifteen_puzzle_state_test.dart` (engine) and
`test/fifteen_puzzle_widget_test.dart` (page).

## Engine tests (state)

> Target: ≥90% line coverage on `lib/src/fifteen_puzzle_state.dart`.

1. Initial state is solved (1..15, 0)
2. canMove returns true only for tiles orthogonal to the blank
3. tap on a non-adjacent tile is a no-op
4. tap on adjacent tile swaps with blank and increments moves
5. isSolved returns true only when tiles == [1,2,...,15,0]
6. Solvability: a sample of 1000 random permutations produces solvable counts ~50%
7. shuffle(seed: 1) is deterministic
8. shuffle always produces a solvable state (run 100x)
9. Win detection fires exactly once when the last tile is placed
10. Widget test: tap tile 14 (adjacent to blank at 15) moves it to position 15

## Widget tests (page)

A minimal smoke test that the page renders and the primary
interaction works:

```dart
// test/fifteen_puzzle_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fifteen_puzzle/fifteen_puzzle.dart';

void main() {
  testWidgets('FifteenPuzzle page renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FifteenPuzzlePage()));
    expect(find.byType(FifteenPuzzlePage), findsOneWidget);
  });
}
```

## Coverage bar

```bash
cd game_hub_modules/fifteen_puzzle
flutter test --coverage
# open coverage/lcov-report.html
```

Required: lines covered on `lib/src/fifteen_puzzle_state.dart` ≥ 90%.
The CI step in the wrapper fails the build otherwise.

## What NOT to test

- Pure widget rendering details (e.g. "the title is centered").
- SFX firing (you'd have to mock `audioplayers`; not worth it).
- The `GameModule` descriptor — it's a static const.

## How to run a single test

```bash
flutter test test/fifteen_puzzle_state_test.dart --plain-name "tap places"
```
