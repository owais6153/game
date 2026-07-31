# Unlimited Launcher Runtime Proof v1

## Baseline and scope

- Source baseline: `8a7bc72` / `unlimited-launcher-hud-final-repair-v1`.
- This repair addresses launcher continuity and target-preview fit only. Table placement, rails, perspective scaling, collision radii, contact-only merge rules, motion constants, audio, haptics, danger timing, and Level 1 balance are unchanged.

## Unlimited launches

- There is no `shot_limit`, shot counter, or production numeric launch cap in `LevelConfig` or `GameController`.
- The fired gem alone ends `SHOT_IN_FLIGHT`; unrelated board motion cannot block the replacement launcher.
- `READY_TO_AIM` now recovers to `SPAWNING_NEXT` if its active body/marker is unexpectedly missing. This is intentionally unavailable during target collection, win, and danger failure.
- The Level 1 regression now runs forty real `launch_active_piece()` -> `_process()` physics -> settle -> replacement cycles. It retains only the replacement between iterations so board-capacity danger is not conflated with launch-cap verification. Restart and moving-board-gem coverage remain present.

## HUD target preview

- The active L7/L8 GOAL still uses the approved `assets/buttons/Generated image 10.png` header/body regions and `AssetCatalog.gem_entry()` artwork.
- Its contain area is now `62 x 58` design pixels inside the supplied cream body. `HudRenderer._draw_contained_texture()` uses the smaller axis scale and never stretches, circle-masks, or clips tall, wide, square, diamond, or irregular gem assets.
- SCORE, NEXT, progression, REPLAY, and settings source assets/regions are unchanged from the preceding approved-HUD delivery.

## Validation

- Godot 4.6.3 headless parse/import: passed.
- `CLEAN_CONTACT_TESTS`: passed.
- `GEM18_CHAIN_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed, including the new forty-cycle real frame-loop launcher proof and missing-active recovery path.
- `MOTION_PROFILE`: passed; it reports zero gameplay resource loads after initialization.
- Godot emitted its known headless RID cleanup warnings after some runners; no test assertion failed.
- No Android device was connected, installed, or launched in this session.

## APK

- `build/android/unlimited-launcher-runtime-proof-v1.apk`
- Size: `102,335,924 bytes`
- Modified: `2026-07-31 08:39:07 +05:00`
- SHA-256: `FFD9F81B34ECE39C083469A71C1B3A9B421F52DAF73EC2C8E7EA762F2A6C4F46`
- Structure verified: `AndroidManifest.xml`, `classes.dex`, and `lib/arm64-v8a/libgodot_android.so` are present.
