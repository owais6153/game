# Current State

**Current milestone:** Shared Perspective + Win Sequence Fix v1. The logical table world is rendered once through a shared SubViewport projection; no live gem has Y-based scaling or screen-space offsets. APK: `build/android/shared-perspective-win-sequence-fix-v1.apk`. See `reports/SHARED_PERSPECTIVE_WIN_SEQUENCE_FIX_V1_REPORT.md`.

**Current milestone:** Visible-Touch Table Alignment Fix v1 at commit `3316d2dcdebde9528885c882b2de385c26862c66`, tagged `visible-touch-table-alignment-fix-v1`. This is a narrow repair on top of `complete-perspective-view-variety-v1`: live gems no longer use dynamic Y perspective or uncalibrated tier scaling. Their fixed approved body textures, fixed colliders, sprite roots, shadows, and physics positions remain aligned in the same shared table-local coordinate system. The table artwork retains its bottom-anchored perspective and stable Y/ID draw ordering remains active. APK: `build/android/visible-touch-table-alignment-fix-v1.apk`. See `reports/VISIBLE_TOUCH_TABLE_ALIGNMENT_FIX_V1_REPORT.md`.

**Current milestone:** Level 1 Balance v1 builds from the approved `level-1-flow-v1` baseline. It preserves Level 1's L1-L8 range, L1/L1/L2 queue, empty start, no shot cap, overflow failure, motion, colliders, merge rules, table, and HUD. The sole target type is now two confirmed merge-created L4 Sapphires; the deterministic minimum is twelve Pearl-equivalent launches. See `reports/LEVEL_1_BALANCE_V1_REPORT.md`.

**Current milestone:** Level 1 Flow v1 is delivered at commit `4ad1d51e09e0efce75d6842b0310880095ad349c`, tagged `level-1-flow-v1`, from the clean `18-gem-progression-tested-v1` baseline. It adds only data-driven Level 1: L1-L8 normal-play exposure, deterministic low-tier L1/L2 queue, and one confirmed-merge-created L5 target. Motion, colliders, full catalog, table, HUD structure, feedback, queue lifecycle, danger failure, and win sequencing are preserved. APK: `build/android/level-1-flow-v1.apk` (99,200,243 bytes; SHA-256 `E7BDBBE6D1158F113F705980602A769DA64078194A61780E45D6AA4156616D9B`). No device was connected. See `reports/LEVEL_1_FLOW_V1_REPORT.md`.

**Current milestone:** 18-Gem Order v1. The final deterministic L1–L18 visual progression is recorded in `reports/18_GEM_ORDER_V1_REPORT.md`; `AssetCatalog.GEM_TIER_SOURCE_INDEX` is the only source of tier-to-asset truth. The approved size/collision calibration is preserved per asset after reordering. APK: `build/android/18-gem-order-v1.apk`; runtime source commit `3d7bb2e8b3d03dcf0bf7f2bb49cea9685cdcd194`.

**Current milestone:** 18-Gem Size & Collision Fix v1 at `fc71e2dad781134948d1962dfe2a49ad0b6521fe`. All 18 gem runtime textures now use alpha-trimmed calibrated derivatives with a fixed visual-to-collider mapping and separate visual-only shadows. The approved `18-gem-motion-smoothness-fix-v1` movement profile, collision radii, merge rules, table, UI, target flow, score, launcher, outcomes, sound, and haptics are unchanged. See `reports/18_GEM_SIZE_COLLISION_FIX_V1_REPORT.md`.

**Phase:** 18-Gem Motion Smoothness Fix v1, tagged `18-gem-motion-smoothness-fix-v1`. The 18-tier chain remains intact, while the smooth `new-table-shadow-contact-fix-v1` motion profile is restored: textures are cached at initialization, runtime derivatives are capped at 256 px, sprite appearance work is not repeated each frame, and Pearl–Diamond collision bodies match the baseline exactly. See `reports/18_GEM_MOTION_SMOOTHNESS_FIX_V1_REPORT.md`. No level, multi-target, perspective, table, HUD, launcher, score, sound, haptics, win/fail, or gameplay-design change is present. Android export remains blocked by the documented Godot CLI filename bug; no APK is claimed.

**In progress:** Visual Sequencing + Perspective + Contact Calibration v2. The baseline is clean commit `8fdebd4` / tag `visual-physics-calibration-v1`. This milestone separates `win_qualified` from `win_presented`, moves result UI into `ResultOverlayLayer`, adjusts upper table anchors to `58..662`, and calibrates the visual gem body independently from stable simple colliders. It is awaiting its final APK export, manifest record, commit, and tag.

**Phase:** New Table + Shadow-Separation Contact Fix v1 delivered at commit `0b562d5b85b0b4d0330ecd10da3f832408949ad9`, tagged `new-table-shadow-contact-fix-v1`. It activates the latest supplied table, uses body-only gem textures with presentation-only separated shadows, and preserves all simulation/merge rules. The standalone APK is `build/android/new-table-shadow-contact-fix-v1.apk` (76,113,263 bytes, 2026-07-29 13:05:58 +05:00). Godot parse/import and `CLEAN_CONTACT_TESTS` passed; no device was connected for installation.

**Phase:** Visual-Physics Calibration v1 delivered at source commit `8fdebd405c791eddf9188bd32e9f0de3b83cbd42`, tagged `visual-physics-calibration-v1`. It uses calibrated runtime textures and per-level collision radii (Pearl 42, Ruby 42, Emerald 32, Sapphire 42, Diamond 33 design px), a 0.75 px contact epsilon, and a shallower derived coral-table texture whose physical rails are `x=90..630` at the top and `x=0..720` at the bottom. Collision sound telemetry now comes from confirmed physical contacts, with debug visualization available by F8 in desktop/editor builds and disabled by default. See `reports/VISUAL_PHYSICS_CALIBRATION_V1_REPORT.md`.

**Phase:** Asset Integration — Background, Table, and Gems v1 delivered at source commit `7ac26f197d7768f13f8ea87c17e29b9893db4300`, tagged `asset-integration-background-table-gems-v1`. It replaces procedural live gem/table/background rendering with the user-supplied tropical background, calibrated coral table, and Sprite2D runtime gem textures. Table visuals and physics now use one trapezoid layout model; all merge, chain, queue, score, win/fail, pause, sound, haptic, and restart rules remain unchanged. The standalone APK is `build/android/asset-integration-background-table-gems-v1.apk` (70,457,131 bytes, 2026-07-29 10:24:35 +05:00). No Android device was connected. See `reports/ASSET_INTEGRATION_BACKGROUND_TABLE_GEMS_V1_REPORT.md` and `ASSET_INVENTORY.md`.

**Phase:** Reference Table + Gem Audio v1 delivered at source commit `d2e99213f01005ba08ff1f9bd50a98ac11a967c7`, tagged `reference-table-gem-audio-v1`. The table is now a contained physical surface with visible procedural crystal scenery around it. Generic sine cues were replaced with original runtime crystal synthesis; gem and wall contacts are distinct, thresholded, and throttled. The standalone APK is `build/android/reference-table-gem-audio-v1.apk` (27,748,993 bytes, 2026-07-29 08:29:58 +05:00). Godot parse/import validation and the full headless suite passed. The ADB query did not complete in this session, so no device installation or launch was attempted. See `reports/REFERENCE_TABLE_GEM_AUDIO_V1_REPORT.md`.

**Phase:** Sound + Haptics v1 delivered at source commit `5245163722e2c34f86657aa25483f47d96e7fdfa`, tagged `sound-haptics-v1`. It adds procedural one-shot sound, mobile-safe haptic routing, and session-only `S`/`V` controls. All gameplay rules are preserved. The standalone APK is `build/android/sound-haptics-v1.apk` (27,744,897 bytes, 2026-07-29 07:59:11 +05:00); `adb devices -l` found no connected device. See `reports/SOUND_HAPTICS_V1_REPORT.md`.

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
# Current milestone: Perspective Table View v1

Delivered from build source commit `5125a4c238d1c9963cad8d185d68491910892623` and tagged `perspective-table-view-v1`. The standalone APK is `build/android/perspective-table-view-v1.apk`; see `reports/PERSPECTIVE_TABLE_VIEW_V1_REPORT.md`. It changes only shared lower table/view composition, bounded visual-only Y perspective, and stable front/back ordering. Level 1 targets/balance, launcher queue/weights, gem order, collision radii, merge rules, score, danger failure, sounds, haptics, and all tier intrinsic sizes remain unchanged.
# Current milestone: Complete Perspective View & Variety v1

The project now uses a fully bottom-anchored table transform with perspective-only gem depth, fixed tier presentation growth, stable Y/ID occlusion, varied Level 1 source silhouettes, and result-presented target counting. Simulation and calibrated colliders remain unchanged. See `reports/COMPLETE_PERSPECTIVE_VIEW_VARIETY_V1_REPORT.md`.
