# Unlimited Launcher + HUD Final Repair v1

## Evidence and root cause

- Baseline: `e530cbb` / `portrait-bottom-table-hud-repair-v1`.
- User evidence reviewed: `WhatsApp Image 2026-07-31 at 8.10.54 AM.jpeg`. The table was correctly bottom-anchored, but the screenshot had no active launcher while the board remained live.
- Root cause: the production lifecycle required `all_pieces_settled()` for `SHOT_IN_FLIGHT`, `RESOLVING`, and `SPAWNING_NEXT`. A moving unrelated board gem could therefore block every future launcher indefinitely, which presented as a shot limit.

## Repair

- The active fired gem alone now completes `SHOT_IN_FLIGHT`. `RESOLVING` waits only for pending merge candidates/presentation, and `SPAWNING_NEXT` creates the next configured launcher immediately. Win, danger failure, and target collection still block input/spawning exactly as intended.
- Added a direct regression with a moving unrelated board gem. It launches, settles the fired gem, advances the real lifecycle, and proves the next ready launcher appears.
- Restart now uses the approved REPLAY region from `assets/ui/Generated image 4.png`, not the back-arrow sheet region. Settings is enlarged to 76x76 px.
- GOAL is rebuilt from the approved `Generated image 10.png` red header and cream panel body regions. Its L7/L8 artwork uses 42x42 contain scaling and cannot overflow its body.

## Validation

- Godot 4.6.3 headless import/parse: passed.
- `CLEAN_CONTACT_TESTS`, `LEVEL_1_FLOW_TESTS`, `GEM18_CHAIN_TESTS`, and `MOTION_PROFILE`: passed.
- Level-flow validation covers 30 cyclic launches, 60 post-restart launches, and a moving-board-gem case that must still produce the next launcher.
- Table/rail geometry, collision radii, contact merge rules, motion constants, danger rules, sound, and haptics remain unchanged.

## APK

- `build/android/unlimited-launcher-hud-final-repair-v1.apk` exported fresh: `102,331,828 bytes`, modified `2026-07-31 08:23:44 +05:00`, SHA-256 `ED0215913CA8C4FB5B724EE395C3EC2466BBD0451FADDA3EF49192AC9E6BA83C`.
- ZIP validation found `AndroidManifest.xml` and `classes.dex`. No device installation or launch was attempted in this repair session.
