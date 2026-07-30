# Complete Perspective View & Variety v1

## Baseline and scope

- Baseline: `845a113` / `perspective-table-view-v1`.
- Reference used: `assets/ui/Generated image 1 (3).png` (the uploaded path maps to this project copy).
- Level 2, multi-target gameplay, progression screens, saves, scoring changes, boosters, ads, analytics, and backend work were not added.

## Composition and depth

The old table centre/board was `(360, 770)` and `y=340..1152`. The complete composition anchors the table at `(360, 846)` with board geometry `y=390..1218`; the launcher is `y=1138` and the danger line is `y=1035`. Rails, collision containment, launch clamp, spawn, and danger line all use this same `GameConfig` transform. The environment is consequently visible above and beside the narrowing top rail.

Visual depth is `tier_base_scale[level] * lerp(0.82, 1.10, normalized_table_y)`. It applies only to the visual child container; physics roots, fixed colliders, velocities, and merge calculations are unchanged. Stable z ordering uses Y then piece ID. Shadows remain inside their owning visual container below the sprite.

## Tier size table

| Tiers | Base scale |
|---|---|
| L1-L3 | 0.94, 0.95, 0.97 |
| L4-L5 | 1.00, 1.02 |
| L6-L8 | 1.10, 1.15, 1.20 |
| L9-L18 | 1.22 through 1.40, in gradual 0.02 steps |

## Level 1 variety

Level 1 remains an eight-tier valid chain. Its source asset sequence now intentionally uses different supplied silhouettes: oval (L1), horizontal crystal (L2), cushion (L3), pear (L4), round (L5), square (L6), slender (L7), and diamond-like (L8). No source image was regenerated or edited; calibrated runtime derivatives, colliders, body scale, and shadow configuration remain reused.

## Win sequencing

Target result IDs are now queued when their merge is confirmed, but only count after that individual merge presentation completes. The result gem is already in simulation and synchronized before that completion, then the existing victory hold runs. This guarantees result creation → visible pop completion → target qualification → win overlay, exactly once.

## Validation

- Godot 4.6.3 import/parse completed.
- `CLEAN_CONTACT_TESTS`: PASS.
- `GEM18_CHAIN_TESTS`: PASS.
- `LEVEL_1_FLOW_TESTS`: PASS.
- `MOTION_PROFILE`: PASS; no per-gem process callbacks or gameplay texture loading after initialization.
- No Android device was connected, so no device installation is claimed.

## APK

- File: `build/android/complete-perspective-view-variety-v1.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 10:41:40 +05:00`
- SHA-256: `577F4E90610DD5A03CA849F890F65806DC75D6BE39BF4DF52569C95E478DABB9`
- ZIP validation: `AndroidManifest.xml` and `classes.dex` present.
