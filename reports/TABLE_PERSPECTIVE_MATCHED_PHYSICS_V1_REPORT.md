# Table Perspective Matched Physics v1 Report

## Scope

Fresh standalone delivery of the narrow perspective/physics/rail alignment fix already implemented at source commit `25fac1fa0ae9e8939b7daa618cb02df12054eb83`. This packaging milestone makes no gameplay-code change.

## Reference

- Project-root video: `WhatsApp Video 2026-07-30 at 12.01.37 PM.mp4`.
- The supplied `/mnt/data` copy is not mounted in this session.

## Implementation verified

- Table position is unchanged.
- Normalized table depth: `inverse_lerp(BOARD_TOP, BOARD_BOTTOM, clamp(y, BOARD_TOP, BOARD_BOTTOM))`.
- Shared perspective formula: `lerp(0.85, 1.00, table_depth)` — 0.85 at the far/top rail and 1.00 at the front/bottom rail.
- Each deterministic `GemPiece` has a private immutable `base_radius` and private live `radius = base_radius * perspective_scale`. This project does not use `CollisionShape2D` resources, so shared collision-shape mutation cannot occur.
- The sprite root, body texture, and separate shadow use the same `perspective_scale`; they are centered on the simulation position and do not have independent body offsets.
- Rails are shared interpolation functions: `left(y)=lerp(205,18,t)` and `right(y)=lerp(515,702,t)`, where `t` is the normalized table depth. Body limits are `left(y)+radius` and `right(y)-radius`.
- Contacts, containment, overlap separation, merge capture, and merge eligibility use the same live radius. Shadows and transparent texture padding are presentation-only.
- Textures are preloaded/cached; the frame path performs no texture load, alpha scan, shape rebuild, or resource allocation.

## Validation

- Godot 4.6.3 headless parse/import validation completed.
- `CLEAN_CONTACT_TESTS: PASS`.
- `GEM18_CHAIN_TESTS: PASS`.
- `LEVEL_1_FLOW_TESTS: PASS`.
- `MOTION_PROFILE: PASS` (crowded board average 0.630 ms; worst 1.682 ms).
- Detailed automated evidence: `reports/table-perspective-matched-physics-v1/VALIDATION_EVIDENCE.md`.

## APK

- Path: `build/android/table-perspective-matched-physics-v1.apk`
- Size: 99,208,435 bytes
- Modified: 2026-07-30 12:45:07 +05:00
- SHA-256: `B4FCA00607414EAE4A9158B4727515BBD339935AC816C6E48EF38263D7057690`
- Structure verified: `AndroidManifest.xml`, `classes.dex`, and `lib/arm64-v8a/libgodot_android.so` are present.
- Device status: no Android device was connected; no installation or phone test is claimed.

## Explicit non-changes

No table repositioning, HUD/UI, Level 1 configuration, gem selection/order, motion constants, score, danger handling, launcher lifecycle, audio/haptics, pause/restart, win/fail logic, targets, or new-level work was changed.
