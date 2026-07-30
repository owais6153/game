# Matched Perspective Physics Scale v1

## Scope and baseline

- Baseline: rollback commit `97b6bc355172c3f1df394a85b9bc63f6fb376290`, tag `pre-shared-perspective-restored-v1`.
- User video present in the project root: `D:\Owais\game\WhatsApp Video 2026-07-30 at 12.01.37 PM.mp4`.
- This isolated change affects only table-depth gem scaling, the directly related simulation radius, rail containment, and focused regression fixtures.

## Implementation

- Perspective uses the authoritative table-local Y interpolation already shared by the table rails: `scale = lerp(0.85, 1.00, inverse_lerp(BOARD_TOP, BOARD_BOTTOM, clamp(y)))`.
- Every `GemPiece` owns an immutable calibrated `base_radius` and one mutable `perspective_scale`; its live `radius` is always `base_radius * perspective_scale`.
- `BoardSimulation` updates that shared scale before bounds and contact resolution. The same live radius is used for rail limits, circle contact, overlap separation, confirmed merge capture, and merge eligibility.
- `GemSpriteLayer` applies the same `perspective_scale` to the complete gem visual root (body and separate shadow). The child visual container remains at scale `1.0`, preventing double scaling or independent sprite offsets.
- The custom deterministic `BoardSimulation` is not built from `RigidBody2D` or shared `CollisionShape2D` resources. Each active gem has its own scalar radius, so no shared resource-locking or physics-callback mutation issue exists.
- Rail containment still reads `GameConfig.table_left_at/right_at(y)` with the same shared live radius, keeping gems visually aligned to the left/right rails while travelling upward.
- Textures, alpha bounds, and runtime asset lookup remain outside the frame path.

## Verification

- Godot 4.6.3 headless parse/import validation: passed.
- `CLEAN_CONTACT_TESTS`: passed, including monotonic scale bounds, matched root/radius scale, left-rail travel, visible contact, same-tier contact merge, and different-tier non-merge coverage.
- `GEM18_CHAIN_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed.
- `MOTION_PROFILE`: passed. Crowded-board profile: average `1.660 ms`, worst `10.804 ms`, with zero per-gem process callbacks and zero gameplay resource loads after initialization.

## Video note

The project-root supplied video was confirmed present. This environment has no video decoder/player available to extract its frames or audio programmatically, so no false claim of a frame-by-frame review is made. The implementation directly follows the requested observable behavior: gems shrink gradually toward the far/top rail, stay on the shared rail geometry, and physically contact only when their scaled visible bodies touch.

## APK

- Path: `D:\Owais\game\build\android\matched-perspective-physics-scale-v1.apk`
- Size: `99,208,435` bytes.
- Modified: `2026-07-30 12:26:21 +05:00`.
- SHA-256: `FD9FCF41EE8580F63D1DD8887FFB29FDFF769B0C8E71F47B0A7AA139B2087C23`.
- Fresh standalone debug export completed through Godot's Android preset. ZIP validation found `AndroidManifest.xml` and `classes.dex`.
- Device status: no device was connected; no phone installation or launch is claimed.

## Explicit non-changes

No Level 2, multi-target rules, assets, table repositioning, score, targets, UI, sounds, haptics, pause, restart, win/fail sequencing, launcher lifecycle, or merge-rule changes were made.
