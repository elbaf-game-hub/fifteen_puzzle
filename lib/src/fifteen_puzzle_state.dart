import 'dart:math';

/// Lifecycle status for 15-Puzzle.
enum FifteenStatus { playing, won }

/// Pure-Dart Solvability validator for 15-Puzzle.
class Solvability {
  Solvability._();

  /// Counts the number of inversions in the tile array (excluding 0).
  static int countInversions(List<int> tiles) {
    var inversions = 0;
    for (var i = 0; i < tiles.length; i++) {
      final a = tiles[i];
      if (a == 0) continue;
      for (var j = i + 1; j < tiles.length; j++) {
        final b = tiles[j];
        if (b != 0 && a > b) {
          inversions++;
        }
      }
    }
    return inversions;
  }

  /// Determines if a 4x4 permutation of tiles 0..15 is mathematically solvable.
  ///
  /// For an even grid width (4):
  /// - If the blank tile is on an odd row from the bottom (row 1 or 3),
  ///   the number of inversions must be even.
  /// - If the blank tile is on an even row from the bottom (row 2 or 4),
  ///   the number of inversions must be odd.
  /// Therefore: (inversions + blankRowFromBottom) % 2 == 1.
  static bool isSolvable(List<int> tiles) {
    if (tiles.length != 16) return false;
    final blankIndex = tiles.indexOf(0);
    if (blankIndex < 0) return false;

    final blankRowFromTop = blankIndex ~/ 4;
    final blankRowFromBottom = 4 - blankRowFromTop;
    final inversions = countInversions(tiles);

    return (inversions + blankRowFromBottom) % 2 == 1;
  }
}

/// Immutable state representation of the 15-Puzzle.
class FifteenState {
  static const int size = 4;
  static const int totalTiles = 16;
  static const List<int> solvedTiles = <int>[
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12,
    13, 14, 15, 0,
  ];

  final List<int> tiles;
  final int moves;
  final Duration elapsed;
  final FifteenStatus status;
  final int? bestMoves;
  final int? bestTimeMs;

  const FifteenState({
    required this.tiles,
    required this.moves,
    required this.elapsed,
    required this.status,
    this.bestMoves,
    this.bestTimeMs,
  });

  /// Creates a solved initial board state.
  factory FifteenState.initial({int? bestMoves, int? bestTimeMs}) {
    return FifteenState(
      tiles: List.unmodifiable(solvedTiles),
      moves: 0,
      elapsed: Duration.zero,
      status: FifteenStatus.playing,
      bestMoves: bestMoves,
      bestTimeMs: bestTimeMs,
    );
  }

  /// Creates a shuffled board state guaranteed to be solvable.
  factory FifteenState.shuffled({
    int? seed,
    int steps = 200,
    int? bestMoves,
    int? bestTimeMs,
  }) {
    final state = FifteenState.initial(
      bestMoves: bestMoves,
      bestTimeMs: bestTimeMs,
    );
    return state.shuffle(seed: seed, steps: steps);
  }

  /// Index of the empty slot (0).
  int get blankIndex => tiles.indexOf(0);

  /// Returns true if the tiles are ordered from 1 to 15 followed by 0.
  bool get isSolved {
    for (var i = 0; i < totalTiles; i++) {
      if (tiles[i] != solvedTiles[i]) return false;
    }
    return true;
  }

  /// Checks if a tile at [index] is orthogonally adjacent to the blank tile.
  bool canMove(int index) {
    if (index < 0 || index >= totalTiles) return false;
    final bIndex = blankIndex;
    if (index == bIndex) return false;

    final row = index ~/ size;
    final col = index % size;
    final blankRow = bIndex ~/ size;
    final blankCol = bIndex % size;

    final rowDiff = (row - blankRow).abs();
    final colDiff = (col - blankCol).abs();

    return (rowDiff + colDiff) == 1;
  }

  /// Returns valid move indices adjacent to blank space.
  List<int> validMoves() {
    final bIndex = blankIndex;
    final bRow = bIndex ~/ size;
    final bCol = bIndex % size;
    final moves = <int>[];

    if (bRow > 0) moves.add((bRow - 1) * size + bCol);
    if (bRow < size - 1) moves.add((bRow + 1) * size + bCol);
    if (bCol > 0) moves.add(bRow * size + (bCol - 1));
    if (bCol < size - 1) moves.add(bRow * size + (bCol + 1));

    return moves;
  }

  /// Performs a tile move if legal.
  FifteenState tap(int index) {
    if (status == FifteenStatus.won || !canMove(index)) {
      return this;
    }

    final newTiles = List<int>.from(tiles);
    final bIndex = blankIndex;
    newTiles[bIndex] = newTiles[index];
    newTiles[index] = 0;

    final newMoves = moves + 1;
    final solved = _checkSolved(newTiles);
    final newStatus = solved ? FifteenStatus.won : FifteenStatus.playing;

    int? updatedBestMoves = bestMoves;
    int? updatedBestTimeMs = bestTimeMs;

    if (solved) {
      if (updatedBestMoves == null || newMoves < updatedBestMoves) {
        updatedBestMoves = newMoves;
      }
      final currentMs = elapsed.inMilliseconds;
      if (updatedBestTimeMs == null || currentMs < updatedBestTimeMs) {
        updatedBestTimeMs = currentMs;
      }
    }

    return copyWith(
      tiles: List.unmodifiable(newTiles),
      moves: newMoves,
      status: newStatus,
      bestMoves: updatedBestMoves,
      bestTimeMs: updatedBestTimeMs,
    );
  }

  /// Shuffles the puzzle by performing [steps] random legal moves.
  FifteenState shuffle({int? seed, int steps = 200}) {
    final rng = seed != null ? Random(seed) : Random();
    final currentTiles = List<int>.from(tiles.isEmpty ? solvedTiles : tiles);

    int lastMovedTile = -1;
    for (var i = 0; i < steps; i++) {
      final bIndex = currentTiles.indexOf(0);
      final bRow = bIndex ~/ size;
      final bCol = bIndex % size;

      final neighbors = <int>[];
      if (bRow > 0) neighbors.add((bRow - 1) * size + bCol);
      if (bRow < size - 1) neighbors.add((bRow + 1) * size + bCol);
      if (bCol > 0) neighbors.add(bRow * size + (bCol - 1));
      if (bCol < size - 1) neighbors.add(bRow * size + (bCol + 1));

      // Avoid immediately undoing previous move when possible
      final candidates = neighbors.where((idx) => currentTiles[idx] != lastMovedTile).toList();
      final chosen = (candidates.isNotEmpty ? candidates : neighbors)[rng.nextInt(candidates.isNotEmpty ? candidates.length : neighbors.length)];

      lastMovedTile = currentTiles[chosen];
      currentTiles[bIndex] = currentTiles[chosen];
      currentTiles[chosen] = 0;
    }

    // Ensure it's not solved immediately
    if (_checkSolved(currentTiles)) {
      final bIndex = currentTiles.indexOf(0);
      final valid = <int>[];
      final bRow = bIndex ~/ size;
      final bCol = bIndex % size;
      if (bRow > 0) valid.add((bRow - 1) * size + bCol);
      if (bCol > 0) valid.add(bRow * size + (bCol - 1));
      if (valid.isNotEmpty) {
        final chosen = valid.first;
        currentTiles[bIndex] = currentTiles[chosen];
        currentTiles[chosen] = 0;
      }
    }

    return copyWith(
      tiles: List.unmodifiable(currentTiles),
      moves: 0,
      elapsed: Duration.zero,
      status: FifteenStatus.playing,
    );
  }

  /// Increments the elapsed duration while playing.
  FifteenState tickElapsed(Duration delta) {
    if (status != FifteenStatus.playing) return this;
    return copyWith(elapsed: elapsed + delta);
  }

  /// Resets the game to a newly shuffled solvable state.
  FifteenState reset({int? seed, int steps = 200}) {
    return shuffle(seed: seed, steps: steps);
  }

  static bool _checkSolved(List<int> list) {
    for (var i = 0; i < totalTiles; i++) {
      if (list[i] != solvedTiles[i]) return false;
    }
    return true;
  }

  FifteenState copyWith({
    List<int>? tiles,
    int? moves,
    Duration? elapsed,
    FifteenStatus? status,
    int? bestMoves,
    int? bestTimeMs,
  }) {
    return FifteenState(
      tiles: tiles ?? this.tiles,
      moves: moves ?? this.moves,
      elapsed: elapsed ?? this.elapsed,
      status: status ?? this.status,
      bestMoves: bestMoves ?? this.bestMoves,
      bestTimeMs: bestTimeMs ?? this.bestTimeMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FifteenState &&
          runtimeType == other.runtimeType &&
          moves == other.moves &&
          elapsed == other.elapsed &&
          status == other.status &&
          bestMoves == other.bestMoves &&
          bestTimeMs == other.bestTimeMs &&
          _listEquals(tiles, other.tiles);

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        moves,
        elapsed,
        status,
        bestMoves,
        bestTimeMs,
        Object.hashAll(tiles),
      );
}
