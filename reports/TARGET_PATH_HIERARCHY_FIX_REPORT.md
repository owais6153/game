# Target and Merge-Path Hierarchy Correction v1

Date: 2026-08-16

## Request and reference review

The requested priority was table first, Target second, and merge path third. The supplied 360x640 gameplay recording keeps its progression chain in a bright, high-contrast speech-bubble tray attached to the table sightline. The supplied 864x1792 still separates Coins/Next/Settings around the edges, centers a large Target card, places a strong eight-gem path below it, and lets the table remain the dominant surface.

The supplied MP4 and PNG were inspection references only. They were not copied into runtime assets and no reference artwork, panel, icon, or audio was imported. Temporary review frames stayed under ignored `.godot/` storage.

## Delivered correction

- Top safe-area row: Coins at left; Next and Settings at right; no Target card competing for the same horizontal row.
- Objective stack: centered 400x120 Target, 14 px gap, centered 620x88 merge-path tray, then a responsive 20-76 px gap to the table.
- Path visibility: 64 px gem slots (was 56), 22 px connectors (was 20), near-opaque white/cyan glass, 3 px rim, gloss, and stronger shadow.
- Table composition: all authoritative baseline Y landmarks move together by +40 px: outer table 360-1145 -> 400-1185, inner board 400-1070 -> 440-1110, danger 920 -> 960, launcher 1002 -> 1042, and texture center 752.5 -> 792.5.
- Tall-screen startup safety: snapshot refreshes re-read the already configured shared table geometry, preventing the Target/path stack from remaining at its baseline startup Y.

No gem collision radius, launch speed, movement, contact capture, merge eligibility, target generation/qualification, scoring, coin authority, queue behavior, danger timing, audio/haptics, or result flow changed.

## Validation

- Godot 4.6.3 project parse: PASS.
- `UI_SCALE_LAYOUT_TESTS`: PASS across 576x1312, 720x1280, 720x1440, 720x1560, 720x1600, 1080x1920, 1080x2340, and simulated-notch 1080x2400.
- `BRANDING_PUSH_LINE_TESTS`: PASS.
- `GAME_FLOW_REWARD_SPLASH_TESTS`: PASS.
- `ADMOB_INTEGRATION_TESTS`: printed PASS; the existing late mock callback emitted its known shutdown error afterward.
- `TARGET_PATH_HIERARCHY_CAPTURE`: PASS under Compatibility/ANGLE.
- `git diff --check`: PASS.

Reviewed real-render evidence:

- [720x1280 gameplay](target-path-hierarchy-fix/final-screenshots/720x1280-gameplay.png)
- [720x1600 gameplay](target-path-hierarchy-fix/final-screenshots/720x1600-gameplay.png)

The render review caught and corrected one tall-screen initialization defect before delivery. Final frames show no utility/Target overlap, no clipping, a readable eight-gem path in the gameplay sightline, and shared table/launcher/line alignment.

## Android delivery

The TEST APK and package/signature audit are recorded in `BUILD_MANIFEST.md`. No phone validation is inferred from desktop renders or export success.
