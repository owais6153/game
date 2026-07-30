# Physical Rails Match Table v1

## Scope

This is a rail-geometry-only repair. It aligns deterministic gem containment with the visible inner felt rails of `assets/runtime/table/new_table_v1.png`.

## Exact design-space anchors

| Rail | Top | Bottom |
|---|---:|---:|
| Left | `(171.4, 413.0)` | `(40.7, 1226.0)` |
| Right | `(547.8, 413.0)` | `(680.1, 1226.0)` |

The anchors were measured after applying the active table Sprite2D transform: center `(360, 846)`, scale `(0.7826087, 1.1802469)`.

## Implementation

- Removed the old vertical/X-only side-bound approximation (`table_left_at(y) + radius`, `table_right_at(y) - radius`) from normal movement.
- Added perpendicular circle-to-slanted-line containment in `BoardSimulation._resolve_slanted_rail()`.
- Launcher drag bounds now use the same line normals and exact rail anchors.
- The existing F8 development-only overlay draws the exact physical left/right rail lines, top/bottom joins, and all four anchors. It is off by default and has no gameplay authority.
- No `StaticBody2D`, `CollisionShape2D`, rectangular wall, or competing manual X clamp is active in the scene.

## Debug proof

The following captures show the physical diagnostic lines over the active table artwork:

- `reports/physical-rails-match-table-v1/screenshots/rail-overlay-full.png`
- `reports/physical-rails-match-table-v1/screenshots/rail-overlay-left.png`
- `reports/physical-rails-match-table-v1/screenshots/rail-overlay-right.png`

The magenta left line and cyan right line follow the visible inner rail edges; white markers are the exact configured endpoints.

## Validation

- Godot 4.6.3 headless `CLEAN_CONTACT_TESTS`: passed, including new direct rail endpoint, monotonic width, launcher-limit, no-stale-collider, no-conflicting-clamp, and debug-data-source tests.
- `GEM18_CHAIN_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed.
- `MOTION_PROFILE`: passed; crowded-board average `0.786 ms`, worst `2.360 ms`.
- Fresh APK ZIP validation found `AndroidManifest.xml`, `classes.dex`, and `lib/arm64-v8a/libgodot_android.so`.

## APK

- Path: `build/android/physical-rails-match-table-v1.apk`
- Size: `99,938,473 bytes`
- Modified: `2026-07-30 13:09:53 +05:00`
- SHA-256: `3B22B7DB5ADCA350FEA4D69CAD7E910407297B8AD8361C18BDCC541E4075B1D5`
- Source commit: `4e8d34f3e8ee9d94534810b557e4c6404c32c25f` (`fix: align physical rails with table artwork`).
- Tag: `physical-rails-match-table-v1`.
- Device status: no phone was connected; installation and phone testing were not performed.

## Explicit non-changes

No table-position, gem-order, Level 1, target, scoring, UI, motion constant, sound, haptic, pause, restart, danger, win/fail, merge, or launcher-lifecycle behavior was changed.
