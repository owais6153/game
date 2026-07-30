# Restored Working Table Rails v1

## Scope

This repair restores only the last historically proven rail/border-following implementation and translates it with the table's existing bottom alignment. It makes no change to gem assets/order, Level 1, targets, physics constants, perspective formula, UI, sound/haptics, pause/restart, scoring, or win flow.

## Historical source of truth

- Working historical milestone: `0b562d5b85b0b4d0330ecd10da3f832408949ad9` (`new-table-shadow-contact-fix-v1`).
- The later rail replacement was `4e8d34f` / `physical-rails-match-table-v1`. It introduced perpendicular slanted-line resolution and separate normal-based launcher limits, replacing the earlier table-interpolated containment.

## Restored implementation

- Restored the proven single side-bound authority in `scripts/board_simulation.gd`: `table_left_at(y) + radius` and `table_right_at(y) - radius`.
- Restored the matching launcher drag clamp in `scripts/game_controller.gd`.
- Removed the newer `_resolve_slanted_rail()` resolver, its line normals, and its separate launcher-limit helpers. There are no `StaticBody2D` or `CollisionShape2D` rail nodes and no competing normal-movement side system.

## Bottom-table adaptation

The source table center moved from `(360, 730)` to the retained current bottom-aligned `(360, 846)`: an exact `+116px` Y translation. The historical rail geometry was moved by that same delta without changing its shape:

| Rail | Historical | Current |
|---|---|---|
| Left top | `(178, 300)` | `(178, 416)` |
| Left bottom | `(44, 1112)` | `(44, 1228)` |
| Right top | `(542, 300)` | `(542, 416)` |
| Right bottom | `(676, 1112)` | `(676, 1228)` |

The danger line and launcher use the same translation: `930 -> 1046` and `1028 -> 1144`. Gem visual/collider perspective scaling remains unchanged.

## Visual debug evidence

The development-only F8 overlay reads the same `GameConfig.table_left_at()` / `table_right_at()` geometry as containment and launcher input. It is disabled by default in the production APK.

- `reports/restored-working-table-rails-v1/screenshots/rail-overlay-full.png`
- `reports/restored-working-table-rails-v1/screenshots/rail-overlay-left.png`
- `reports/restored-working-table-rails-v1/screenshots/rail-overlay-right.png`

The captures were rendered at the 720x1280 Android design resolution. They show the full table rails plus a gem constrained at the left and right launcher edges.

## Validation

- Godot 4.6.3 parse/import validation: passed.
- `CLEAN_CONTACT_TESTS`: passed.
- `GEM18_CHAIN_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed.
- `MOTION_PROFILE`: passed; 20-gem average `1.179 ms`, worst `3.052 ms`.
- APK ZIP structure: verified `AndroidManifest.xml`, `classes.dex`, and `lib/arm64-v8a/libgodot_android.so`.
- No Android phone was connected; device installation/testing is not claimed.

## APK

- Path: `build/android/restored-working-table-rails-v1.apk`
- Size: `100,750,262 bytes`
- Modified: `2026-07-30 13:37:45 +05:00`
- SHA-256: `96A6BD76DDC1574208B74730E8F857A12AB729A77437B6CADABF8ED951C8948A`.
