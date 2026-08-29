import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fifteen_puzzle/src/fifteen_puzzle_state.dart';

void main() {
  group('Solvability', () {
    test('counts inversions correctly', () {
      expect(Solvability.countInversions([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0]), 0);
      // Swap 14 and 15 -> 1 inversion
      expect(Solvability.countInversions([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 14, 0]), 1);
    });

    test('validates solvable vs unsolvable configurations', () {
      // Solved board is solvable
      expect(Solvability.isSolvable(FifteenState.solvedTiles), isTrue);

      // Classic 14-15 swap is unsolvable
      final unsolvable = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 14, 0];
      expect(Solvability.isSolvable(unsolvable), isFalse);

      // Invalid lists
      expect(Solvability.isSolvable([1, 2, 3]), isFalse);
      expect(Solvability.isSolvable(List.filled(16, 1)), isFalse);
    });

    test('6. a sample of 1000 random permutations produces solvable counts around 50%', () {
      var solvableCount = 0;
      for (var i = 0; i < 1000; i++) {
        final list = List<int>.generate(16, (index) => index)..shuffle(Random(i));
        if (Solvability.isSolvable(list)) {
          solvableCount++;
        }
      }
      // Solvability of random 15-puzzle permutations is exactly 50% on average
      expect(solvableCount, greaterThan(400));
      expect(solvableCount, lessThan(600));
    });
  });

  group('FifteenState - Pure Dart Logic', () {
    test('1. Initial state is solved (1..15, 0)', () {
      final state = FifteenState.initial();

      expect(state.tiles, FifteenState.solvedTiles);
      expect(state.moves, 0);
      expect(state.elapsed, Duration.zero);
      expect(state.status, FifteenStatus.playing);
      expect(state.blankIndex, 15);
      expect(state.isSolved, isTrue);
    });

    test('2. canMove returns true only for tiles orthogonal to the blank', () {
      final state = FifteenState.initial(); // Blank at 15 (row 3, col 3)

      // Orthogonal neighbors of 15 are 11 (Up) and 14 (Left)
      expect(state.canMove(11), isTrue);
      expect(state.canMove(14), isTrue);

      // Other tiles cannot move
      expect(state.canMove(15), isFalse); // Blank itself
      expect(state.canMove(10), isFalse); // Diagonal
      expect(state.canMove(0), isFalse);  // Top-left
      expect(state.canMove(-1), isFalse); // Out of bounds
      expect(state.canMove(16), isFalse); // Out of bounds

      final valid = state.validMoves();
      expect(valid.toSet(), equals({11, 14}));
    });

    test('3. tap on a non-adjacent tile is a no-op', () {
      final state = FifteenState.initial();
      final afterTap = state.tap(0);

      expect(afterTap, equals(state));
      expect(afterTap.moves, 0);
    });

    test('4. tap on adjacent tile swaps with blank and increments moves', () {
      final state = FifteenState.initial();
      // Tile 14 is at index 14, adjacent to blank at 15
      final nextState = state.tap(14);

      expect(nextState.moves, 1);
      expect(nextState.tiles[14], 0);
      expect(nextState.tiles[15], 14);
      expect(nextState.blankIndex, 14);
      expect(nextState.isSolved, isFalse);
    });

    test('5. isSolved returns true only when tiles == [1,2,...,15,0]', () {
      final solved = FifteenState.initial();
      expect(solved.isSolved, isTrue);

      final unsolved = solved.tap(14);
      expect(unsolved.isSolved, isFalse);

      final backToSolved = unsolved.tap(15);
      expect(backToSolved.isSolved, isTrue);
    });

    test('7. shuffle(seed: 1) is deterministic', () {
      final s1 = FifteenState.shuffled(seed: 42, steps: 50);
      final s2 = FifteenState.shuffled(seed: 42, steps: 50);

      expect(s1.tiles, equals(s2.tiles));
      expect(s1.moves, 0);
      expect(s1.elapsed, Duration.zero);
      expect(s1.status, FifteenStatus.playing);
    });

    test('8. shuffle always produces a solvable state (run 100x)', () {
      for (var i = 0; i < 100; i++) {
        final state = FifteenState.shuffled(seed: i * 7 + 1, steps: 200);
        expect(Solvability.isSolvable(state.tiles), isTrue);
      }
    });

    test('9. Win detection fires and sets status = won when the last tile is placed', () {
      // Create a 1-move-to-win state
      final almostSolvedTiles = List<int>.from(FifteenState.solvedTiles);
      almostSolvedTiles[14] = 0;
      almostSolvedTiles[15] = 14;

      final almostSolvedState = FifteenState(
        tiles: almostSolvedTiles,
        moves: 10,
        elapsed: const Duration(seconds: 45),
        status: FifteenStatus.playing,
        bestMoves: 20,
        bestTimeMs: 60000,
      );

      expect(almostSolvedState.isSolved, isFalse);
      expect(almostSolvedState.status, FifteenStatus.playing);

      // Move 14 into blank at 14
      final wonState = almostSolvedState.tap(15);

      expect(wonState.isSolved, isTrue);
      expect(wonState.status, FifteenStatus.won);
      expect(wonState.moves, 11);
      expect(wonState.bestMoves, 11); // New record
      expect(wonState.bestTimeMs, 45000); // New record

      // Tapping after won is no-op
      final tapAfterWin = wonState.tap(14);
      expect(tapAfterWin, equals(wonState));
    });

    test('tickElapsed increments duration when playing and moves > 0', () {
      final state = FifteenState.initial();
      final ticked = state.tickElapsed(const Duration(seconds: 1));
      expect(ticked.elapsed, const Duration(seconds: 1));

      final won = state.copyWith(status: FifteenStatus.won);
      expect(won.tickElapsed(const Duration(seconds: 1)), equals(won));
    });

    test('reset() reshuffles the board', () {
      final state = FifteenState.initial();
      final resetState = state.reset(seed: 99);

      expect(resetState.moves, 0);
      expect(resetState.elapsed, Duration.zero);
      expect(Solvability.isSolvable(resetState.tiles), isTrue);
    });

    test('equality, hashCode, and copyWith', () {
      final s1 = FifteenState.initial(bestMoves: 10, bestTimeMs: 5000);
      final s2 = FifteenState.initial(bestMoves: 10, bestTimeMs: 5000);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));

      final copy = s1.copyWith(moves: 5);
      expect(copy.moves, 5);
      expect(copy == s1, isFalse);
    });
  });
}
