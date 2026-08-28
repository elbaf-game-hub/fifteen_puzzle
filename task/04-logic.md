# 04 — Logic

> The engine lives in `lib/src/fifteen_puzzle_state.dart`. **No imports of
> `package:flutter/*` allowed in this file.** The page imports the
> state, not the other way around.

## Class diagram

```
fifteen_puzzle_state.dart (pure Dart)
  └── classes listed below
fifteen_puzzle_page.dart (Flutter)
  └── owns the State subclass that wraps fifteen_puzzle_state
```

## Classes

### `FifteenStatus`

enum { playing, won }

### `FifteenState`

Owns List<int> tiles (length 16, 0 = blank), int moves, Duration elapsed, FifteenStatus status. Methods: tap(int index), shuffle({int seed}), isSolved, canMove(int index).

### `Solvability`

Pure function: given a permutation, return whether it is solvable (inversion count parity matches blank row).

## Hard rules

1. **No `Widget` or `BuildContext` references** in the state file.
   If a UI helper is needed, put it in `*_page.dart`.
2. **No `import 'package:flutter/...'`** in the state file.
   Use only `dart:core`, `dart:math`, `dart:collection`.
3. **Constructor takes everything it needs** — no global state.
   The page passes initial values and listens via `Stream` or
   `Listenable` if needed.
4. **Methods return new state, not mutate** when possible. For
   performance-critical loops (e.g. 2048 slide), in-place mutation
   is OK as long as the previous state is captured for undo.
5. **Seedable RNG** for any shuffle/random. Use `Random(seed)` so
   tests can be deterministic.

## Integration with the page

```dart
class FifteenPuzzlePage extends StatefulWidget {{
  const FifteenPuzzlePage({{super.key}});
  @override
  State<FifteenPuzzlePage> createState() => _FifteenPuzzlePageState();
}}

class _FifteenPuzzlePageState extends State<FifteenPuzzlePage> {{
  late FifteenPuzzleState _state;

  @override
  void initState() {{
    super.initState();
    _state = FifteenPuzzleState.initial();
  }}

  void _onAction(...) {{
    setState(() {{
      _state = _state.copyWith(...);
    }});
    SfxPlayer.instance.play('tap');
  }}

  @override
  Widget build(BuildContext context) => /* see 05-ui.md */;
}}
```
