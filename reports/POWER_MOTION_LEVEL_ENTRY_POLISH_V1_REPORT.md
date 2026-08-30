# Power Motion and Level Entry Polish V1

Date: 2026-08-31

Baseline: `3a1b786` / `player-feedback-limited-shots-repair-v1-apk`

## Delivered behavior

- The cinematic duration remains 1.65 seconds and remains tap-skippable. Announce ends at 18%, every power arrives at 32%, and impact remains at 74%.
- Bomb and Hammer use the longer destination beat for their existing brace/shake. Magnet and Switch now orbit and tighten within 34-to-8 pixels of the action point instead of traveling slowly until impact.
- Power impact composes a deterministic 160ms table/gem sprite shake: Bomb 4.0px, Hammer 3.4px, Magnet/Switch 1.8px.
- After the shared screen cover finishes, entering play from Level Ready visibly fades in the table and live gem sprites over 520ms, rises them 28px, and settles table art from 96.5% to its exact centralized render scale. The connected-device pass caught and corrected an initial composition in which this timeline advanced behind the cover.

## Authority and scope

- All new motion is presentation-only. No `GemPiece.position`, board geometry, collision, merge eligibility, launcher timing, input coordinate, target, score, reward, failure, or save behavior changes.
- Impact motion starts from the existing cinematic impact signal. Existing staged power mutation, sound, and haptic routing remain exactly-once and unchanged.
- The level-entry reveal does not alter `app_flow_state`, synchronous navigation, screen-transition ownership, or gameplay snapshots.

## Tuning and safe ranges

- Power total: unchanged `1.65s`; arrival `0.46 -> 0.32` for Bomb/Hammer and `0.74 -> 0.32` for Magnet/Switch. Safe arrival range: `0.28-0.34` of total duration.
- Table shake: `0 -> 0.16s`; amplitudes `1.8-4.0px`. Safe duration `0.12-0.20s`; safe amplitude `1.5-4.5px`.
- Level entry: `0 -> 0.52s`, `28px` rise, `0.965 -> 1.0` table scale. Safe duration `0.45-0.65s`, rise `20-34px`, start scale `0.95-0.98`.

## Validation

- `POWER_MOTION_LEVEL_ENTRY_V1_TESTS`: PASS.
- `POWERS_GAMEPLAY_V1_TESTS`: PASS.
- `GAME_FLOW_REWARD_SPLASH_TESTS`: PASS.
- `PLAYER_FEEDBACK_REPAIR_V1_TESTS`: PASS.
- `MERGE_PHYSICS_V1_TESTS`: PASS.
- `LEVEL_DIFFICULTY_V1_TESTS`: PASS.
- The Windows runner retains its known post-PASS shutdown stall/access issue; every listed suite printed its PASS sentinel before termination, with no assertion failure.
- Final APK package metadata and v2 signature pass. `adb install -r` succeeds on connected V2149 `34385676890001M`.
- Device flow exercised cold launch, Home, PLAY, Level Ready, START GAME, the corrected post-cover table entry, the settled board, and a real launcher drag/shot. The Activity remained resumed and filtered logcat contained no fatal exception, ANR, GDScript parse/runtime error, or invalid call. Firebase `FA-SVC` logged `level_start`.
- Device evidence: `reports/power-motion-level-entry-v1/device/final-level-ready.png`, `final-level-entry.mp4`, `final-entry-mid.png`, `final-entry-settled.png`, and `final-after-shot.png`.
- The retained device save has zero Bomb/Magnet/Switch/Hammer inventory. It was not privately altered for a forced demo, so physical power feel remains for inventory-backed manual acceptance; both focused motion and existing gameplay-power suites passed.

## Milestones

- Final source commit/tag: `e3d352b` / `power-motion-level-entry-polish-v1-device-fix-source` (initial source milestone `0584a00` / `power-motion-level-entry-polish-v1-source`).
- APK: `build/android/majestic-gems-power-motion-level-entry-v1.0.15-vc17.apk`.
- Size/timestamp: 114,506,769 bytes; 2026-08-31 03:13:38 +05:00.
- SHA-256: `A11472512C862808BE6BA8AE065442C8D0BB3EE359B003AF8A4B6FF2B138EF12`.
- APK delivery commit/tag: recorded in the delivery milestone containing this final evidence and manifest entry.
