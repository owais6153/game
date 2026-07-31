# Portrait Bottom Table + HUD Repair v1

## Baseline and evidence

- Baseline: `6f7c3ba` / `reference-accurate-hud-unlimited-level1-v1`.
- User evidence reviewed: `WhatsApp Image 2026-07-31 at 7.50.57 AM.jpeg`. It showed the fixed-height table floating above the bottom of an expanded portrait viewport, a cramped target card, and undersized settings control.

## Repair

- `GameConfig.portrait_bottom_offset_y` is configured from the expanded viewport height. At 720x1600 it is 320 px: table center moves from `(360,846)` to `(360,1166)`, board bounds from `416..1228` to `736..1548`, danger line from `1046` to `1366`, and launcher from `1144` to `1464`.
- The same accessors now drive table artwork, rail interpolation, collision bounds, drag clamp, launcher spawn, danger evaluation, perspective scale, and F8 diagnostics. Existing 720x1280 coordinates remain exactly unchanged.
- GOAL uses the supplied white panel region at a larger `(238,194,244,84)` frame and contains the active L7/L8 gem within 38x38 px. The supplied settings cog is 66x66 px; the supplied lower-right return artwork is a 66x66 px functional restart control.
- Restart executes the existing complete reset and returns to one L1-L4 ready launcher. The source contains no shot-limit state; launch generation remains cyclic until danger failure or completion of L7 then L8.

## Validation

- Godot 4.6.3 headless parse/import: passed.
- `CLEAN_CONTACT_TESTS`: passed, including expanded-portrait bottom-anchor assertions.
- `LEVEL_1_FLOW_TESTS`: passed, including 30 launcher cycles, 60 post-restart cycles, sequential target collection, and restart-icon reset.
- `MOTION_PROFILE`: passed; no gameplay per-frame resource loads.
- Table geometry, collision radii, contact merge rules, motion constants, sound/haptics, and danger duration are unchanged; only their shared vertical placement adapts on expanded screens.

## APK

- `build/android/portrait-bottom-table-hud-repair-v1.apk` exported fresh: `101,532,853 bytes`, modified `2026-07-31 08:03:43 +05:00`, SHA-256 `D74BEBEAF5B86CA625A7390564DE139174F4E70169B063BC3226539CE20B8371`.
- ZIP validation found `AndroidManifest.xml` and `classes.dex`. No device installation or launch was attempted in this repair session.
