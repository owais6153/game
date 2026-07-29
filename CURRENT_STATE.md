# Current State

**Phase:** Asset Integration — Background, Table, and Gems v1 is exported and validated. It replaces procedural live gem/table/background rendering with the user-supplied tropical background, calibrated coral table, and Sprite2D runtime gem textures. Table visuals and physics now use one trapezoid layout model; all merge, chain, queue, score, win/fail, pause, sound, haptic, and restart rules remain unchanged. The standalone APK is `build/android/asset-integration-background-table-gems-v1.apk` (70,457,131 bytes, 2026-07-29 10:24:35 +05:00). No Android device was connected. See `ASSET_INTEGRATION_BACKGROUND_TABLE_GEMS_V1_REPORT.md` and `ASSET_INVENTORY.md`; commit/tag provenance is recorded in the following documentation commit.

**Phase:** Reference Table + Gem Audio v1 delivered at source commit `d2e99213f01005ba08ff1f9bd50a98ac11a967c7`, tagged `reference-table-gem-audio-v1`. The table is now a contained physical surface with visible procedural crystal scenery around it. Generic sine cues were replaced with original runtime crystal synthesis; gem and wall contacts are distinct, thresholded, and throttled. The standalone APK is `build/android/reference-table-gem-audio-v1.apk` (27,748,993 bytes, 2026-07-29 08:29:58 +05:00). Godot parse/import validation and the full headless suite passed. The ADB query did not complete in this session, so no device installation or launch was attempted. See `REFERENCE_TABLE_GEM_AUDIO_V1_REPORT.md`.

**Phase:** Sound + Haptics v1 delivered at source commit `5245163722e2c34f86657aa25483f47d96e7fdfa`, tagged `sound-haptics-v1`. It adds procedural one-shot sound, mobile-safe haptic routing, and session-only `S`/`V` controls. All gameplay rules are preserved. The standalone APK is `build/android/sound-haptics-v1.apk` (27,744,897 bytes, 2026-07-29 07:59:11 +05:00); `adb devices -l` found no connected device. See `SOUND_HAPTICS_V1_REPORT.md`.

**Phase:** Progression HUD v1 delivered at source commit `2dc007575457fec112acabc51b7d6dcfb9f06462`, tagged `progression-hud-v1`. It adds presentation-only current/next gem previews, a compact Diamond-target progression strip, and a simplified luxury HUD. It does not change physics, contact merge eligibility, chains, score rules, launcher lifecycle, danger handling, outcomes, or restart. The standalone APK is `build/android/progression-hud-v1.apk` (27,732,265 bytes, 2026-07-29 07:42:27 +05:00); no phone was connected for device testing.

**Phase:** Physics and pacing parity v1 delivered at source commit `3bba78f32f3994ff4d9b103cac3f8a2fd983e44b`, tagged `physics-pacing-parity-v1`. It changes only documented centralized feel values plus bounded tangential contact resistance and merge momentum handoff. Merge eligibility, chains, launcher lifecycle, score, win/fail, restart, and gem mapping remain unchanged. The standalone APK is `build/android/physics-pacing-parity-v1.apk` (27,728,010 bytes, 2026-07-29 07:25:11 +05:00); no phone was connected for device testing.

**Prior verified baseline:** Gameplay balance v1 delivered at source commit `4bb5469456bf23480b569a15b9c44c7692e30257`, tagged `gameplay-balance-v1`. It centralizes delta-based launch, damping, settling, collision, border, presentation, chain-display, and next-launcher pacing values without changing gameplay rules. No phone was connected for device testing.

## Do Not Regress

- Visual layout constants and `GemVisuals` must remain presentation-only; never pass their values into simulation, collision, merge eligibility, launcher lifecycle, danger timers, scoring, chains, or outcomes.
- Preserve the fixed portrait gameplay coordinate system. Canvas-item stretching scales the visual design; it does not authorize changes to board bounds or input math.
- Preserve the balance profile in `GameConfig`: all mobile-feel numbers are centralized and documented with approved ranges. Do not alter contact eligibility, merge resolution, scoring, chain logic, danger semantics, or launcher state transitions during tuning.

**Phase:** Gemstone visual prototype delivered at source commit `561235ad45a6dbf50a3b8a018820656dae53cd53`, tagged `gem-visual-prototype-v1`; gameplay source remains the verified playable-loop behavior with presentation-only visual updates.

## Verified Working Now

- `build/android/gem-visual-prototype-v1.apk` is the standalone Android delivery (27,723,914 bytes, 2026-07-29 04:40:27 +05:00).
- `GemVisuals` owns procedural visuals only: Pearl, Ruby, Emerald, Sapphire, and Diamond match their intended level mapping without affecting circular collision truth.
- Merge physics review found no justified simulation retune. The only safe improvement was render ordering: ghosts draw before live pieces so upgraded gems do not appear beneath fading source visuals.
- Godot parse/import validation and the complete headless controller/simulation suite passed. No device installation was attempted in this session.

**Phase:** Complete playable level loop delivered at source commit `2d982a8af80e0477caf2c8641f8543c28587a178`, tagged `clean-contact-merge-v3-playable-loop`.

## Verified Working Now

- `build/android/clean-contact-merge-v3-playable-loop.apk` is the verified standalone Android APK (27,719,661 bytes, 2026-07-29 04:16:50 +05:00).
- The level awards score only from confirmed merges: Ruby 10, Emerald 25, Sapphire 60, Diamond 150; each confirmed event in one resolution sequence increments its score multiplier.
- Creating Diamond wins once and blocks further launcher input/spawns. A settled non-active gem below the visual-only danger line for 0.75 seconds fails once; moving and active launcher gems are exempt.
- Replay, Retry, and Restart share the complete reset path and restore an empty board with exactly one active launcher.
- Parse/import validation, the complete headless controller/simulation suite, and standalone Android export passed. `adb devices` found no connected phone, so no device test was performed.

## Do Not Regress

- Score and win must consume confirmed merge events only; never rescan the board or collisions for outcomes.
- Danger timers must remain keyed by non-active piece ID and be cleared for moving, active, removed, merged, or safe pieces.
- Win/fail overlays must block launches and new launcher spawns until a full reset.

**Phase:** Clean Gameplay Milestone 2 chain-merge polish delivered at commit `10f8d59408cccd6287d308f5fc0ab0046326ea3a`, tagged `clean-contact-merge-v2-chain-polish`.

**Governance follow-up:** Documentation-only handoff hardening is committed in Git as `docs: harden AI project knowledge and agent workflow`. It adds no gameplay or build change.

## Verified Working Now

- This task began from clean commit `53306bf1f9d96fbb6918380657dd611ed1a7a51e`, tag `clean-contact-merge-v1-spawn-fix`, and delivered the confirmed standalone APK `build/android/clean-contact-merge-v2-chain-polish.apk` (27,711,469 bytes, 2026-07-29 03:44:48 +05:00).
- Empty board, one active launcher, drag/release, borders, visual-only danger line, and settlement-gated one-time queue advance remain covered by the headless suite.
- v2 preserves contact-only same-level merging, adds capped local contact chains, and uses presentation-only effects.

## Do Not Regress

- Only `SPAWNING_NEXT` can create a launcher; idle settled frames must not spawn.
- Never merge distant or cross-level gems, reuse stale pairs, or perform board-wide chain scanning.
- Presentation must never alter collision, positions, IDs, or merge candidates.
- Do not spawn a launcher until pieces are settled and merge presentation is complete.

The verified milestone source is commit `ac795736bbecb4ee83c346a2717276d66a2b483c`, tagged `clean-contact-merge-v1`. Its standalone APK is `build/android/clean-contact-merge-v1.apk` (27,707,373 bytes, built 2026-07-29 03:12:46 +05:00). Godot parse/import validation, headless integration tests, and Android export passed. No phone was connected, so device testing has not occurred.

Implemented scope: empty-board launcher, horizontal drag, negative-Y shot, visual-only danger line, top/side containment, settlement-gated next launcher, and current-contact-only gem merges. Do not modify merge behavior without a specific task and targeted regression tests. Chains, scoring, loss/win, sounds, menus, persistence, ads, and final art remain out of scope.

The verified spawn-lifecycle source is commit `53306bf1f9d96fbb6918380657dd611ed1a7a51e`, tagged `clean-contact-merge-v1-spawn-fix`. Its standalone APK is `build/android/clean-contact-merge-v1-spawn-fix.apk` (27,707,373 bytes, built 2026-07-29 03:23:14 +05:00). The launcher now follows `READY_TO_AIM → SHOT_IN_FLIGHT → RESOLVING → SPAWNING_NEXT → READY_TO_AIM`; one active launcher exists at a time and the queue advances once per completed shot. Headless parse/import validation and integration tests passed. No Android device was connected, so the APK has not been installed or tested on-device.
