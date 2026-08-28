# 02 — Assets

All assets come from `package:game_assets`. The module declares a
path-dependency on it in `pubspec.yaml`. The wrapper's `game_assets`
package owns the actual files.

## Source of truth

- **Declarative YAML**: `game_hub_core/game_assets/tool/definitions/fifteen_puzzle.yaml`
- **Procedural Python**: `game_hub_core/game_assets/tool/generate_tiles.py`
- **Regenerate**:
  ```bash
  cd game_hub_core/game_assets
  python3 tool/generate_svgs.py
  python3 tool/generate_tiles.py
  ```

## Core SVG assets

These are the visual primitives the page must reference. The table
maps each to a file under `game_assets/assets/svg/fifteen_puzzle/`.

| File | Size | Purpose |
| --- | --- | --- |
| `tile_1.svg … tile_15.svg` | 100x100 each | Numbered tiles 1–15 |
| `tile_blank.svg` | 100x100 | Empty slot (where 0 lives) |

## Fonts

System default (numbers rendered in SVG text).

## How the page loads an asset

```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/svg/fifteen_puzzle/<file>.svg',
  package: 'game_assets',
  width: 48,
)
```

## Asset budget

- **Hard cap**: total `assets/` in this module ≤ 200 KB
  (CI step in `game_hub_wrapper/.github/workflows/ci.yml`).
- This module's known usage: see sizes in the table above.
