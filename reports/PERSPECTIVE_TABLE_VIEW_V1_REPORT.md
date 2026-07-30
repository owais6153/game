# Perspective Table View v1 Report

## Scope and baseline

- Source baseline: `9e03352292a372ac88a380216a0ef0d7ed1ef525` (`level-1-balance-v1`).
- Build source commit: `5125a4c238d1c9963cad8d185d68491910892623`.
- Reference used: the approved active supplied-table composition, `assets/runtime/table/new_table_v1.png`, together with the gameplay UI reference kept in `assets/ui/`.
- This milestone changes only table/view placement, visual-only gem perspective, and front/back visual ordering.

## Shared table layout

| Landmark | Old | New |
|---|---:|---:|
| Table texture center | `(360, 730)` | `(360, 770)` |
| Board top / bottom | `300 / 1112` | `340 / 1152` |
| Danger line Y | `930` | `970` |
| Launcher Y | `1028` | `1068` |

The image, rails, collision containment, drag clamp, launcher spawn, and danger-line drawing all use the same `GameConfig` coordinate model. Rail widths and every collision/merge constant are unchanged.

## Perspective and depth

- Formula: `lerp(0.90, 1.05, table_interpolation(table_local_y))`.
- The bounded transform is applied only to `GemSpriteLayer`'s child `Visual` container, which contains the gem sprite and its own shadow.
- The piece mirror root stays at `Vector2.ONE`; `GemPiece.radius`, collider values, velocities, and all simulation constants remain unchanged.
- Stable visual ordering uses normalized table-local Y; larger Y renders in front. Piece ID supplies the deterministic equal-Y tie rule, with stable node creation order as the fallback inside Godot's bounded z-index range.
- No textures, alpha scans, colliders, resources, nodes, or reparenting are created in the per-frame sync path.

## Validation

- Godot editor parse/import validation: passed.
- `CLEAN_CONTACT_TESTS`: passed, including added root/collider constancy, bounded monotonic perspective, depth order, tie order, and shared-transform assertions.
- `GEM18_CHAIN_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed.
- Motion profile: passed; 20-gem crowded-board average process time `1.638 ms`, worst `14.865 ms`; no gameplay resource loads after initialization.
- No Android device was connected, so device installation and play testing were not performed.

## APK

- File: `build/android/perspective-table-view-v1.apk`
- Size: `99,204,339 bytes`
- Modified: `2026-07-30 10:16:44 +05:00`
- SHA-256: `D4BDC9598A28DD5EEB494974215DD617DCDC6EDA9DDC341A93505732D4D77CEC`
- Verification: exists, non-zero, and valid APK/ZIP containing `AndroidManifest.xml` and `classes.dex`.

## Explicitly not changed

Targets, Level 1 balance, launcher weights, active gem selection, gem order, merge rules, scoring, danger/fail condition, shot rules, sounds, haptics, later levels, gem-shape variety, and intrinsic tier sizes were not changed.
