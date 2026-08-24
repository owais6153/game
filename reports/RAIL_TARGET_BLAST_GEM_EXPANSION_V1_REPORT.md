# Rail, Target Blast, and Gem Expansion V1

## Outcome

Two supplied gems expand the active name-free catalog to 34. Their runtime copies are precisely alpha-cropped. Rail collision is recalibrated to the visible inner lip of all ten table variants, target tiers are larger in both artwork and collider size, target merge waves are denser, completed targets give nearby board gems a slight one-shot radial push, and background music is slightly louder.

Baseline: `97e3c31` / `rail-target-blast-2026-08-25-intake`. This intake commit preserves both user-supplied PNGs byte-for-byte before stable renaming or derivative generation.

## Supplied gem integration

| Stable ID | Inspected artwork | Source alpha rectangle | Runtime size | Rarity |
| --- | --- | --- | --- | --- |
| `gem_33` | pink gradient circle | `(100,94,1054,1042)` | `256x253` | Unique |
| `gem_34` | pink gradient rounded square | `(146,141,962,954)` | `256x254` | Unique |

`scripts/dev/prepare_supplied_art_refresh.gd` uses alpha >= 0.01, extracts that exact source rectangle, preserves aspect ratio, resizes the longest edge to 256 px with Lanczos, clears sub-threshold edge alpha, and rejects any derivative whose used rectangle is smaller than its image. The originals total 2,246,844 bytes; runtime copies total 193,224 bytes. Registry totals are 22 Common / 12 Unique. `gem_name()` and catalog entry `name` remain empty.

All 34 source/runtime mappings, sizes, rectangles, and SHA-256 values are recorded in `assets/runtime/art_refresh_manifest.json`; manifest SHA-256 is `DA3EF0309B7850E9342184F7221621698BD99130859EA323D2512A480F7F68C7`.

## Rail recalibration

The previous test checked only whether physics was within 70 px of any visible alpha. That proved containment inside the outer table artwork but did not locate the inner playable lip precisely. `scripts/dev/measure_table_inner_rails.gd` now compares local color edges at five rows plus the table centerline across all ten 720x1280 derivatives.

The consistent inner-edge observations were approximately world X 137-141 / 579-582 at the back, 114-121 / 598-606 around y650, 89-97 / 623-637 around y850, and 71-74 / 646-649 around y1050. Centerline inner edges clustered at Y 453-454 on top and the earliest shared safe bottom edge at Y 1168.

| Geometry | Before | After |
| --- | ---: | ---: |
| Board top / bottom | 455 / 1165 | 454 / 1168 |
| Back inner rails | 130 / 590 | 140 / 580 |
| Front inner rails | 54 / 666 | 58 / 662 |

The safe tuning envelope is back X 138-142 / 578-582, front X 56-60 / 660-664, top Y 453-455, and bottom Y 1168-1172. The selected shared values avoid artwork penetration without creating a visibly early invisible bounce. Rendering, containment, drag clamp, vertical guide, launcher, danger line, contact telemetry, and F8 diagnostics still use the same `GameConfig` model.

## Target scale, physics, wave, and blast

| Tuning | Before | After | Safe range |
| --- | ---: | ---: | ---: |
| L6 radius | 51 | 56 | 54-58 |
| L7 radius | 54 | 61 | 59-63 |
| L8 radius | 57 | 66 | 64-68 |
| Detached target scale | 1.12 | 1.18 | 1.16-1.20 |
| Target ring layers | 3 | 5 | 4-6 |
| Target ring segments | 36 | 52 | 48-64 |
| Blast radius | none | 220 px | 180-240 px |
| Blast maximum impulse | none | 78 px/s | 60-90 px/s |

L1-L5 remain 36/39/42/45/48. Live target artwork reads the same enlarged L6-L8 radii as physics; no transient presentation scale changes a collider. Target collection adds the existing detached visual emphasis only after its real body is removed.

Every confirmed active-target completion applies `_apply_target_merge_blast()` exactly once. Eligible nearby pieces receive an outward velocity addition with distance falloff and a 0.28 edge multiplier. The result, active launcher, consumed pieces, and pieces outside 220 px are excluded. The function creates no objects, captures no contact, and performs no merge; ordinary simulation owns all later movement/collision.

Five ring scales and alpha values are calculated inside the existing capped immediate-mode merge record. No particles or physics nodes were added. The 420 ms merge and 120 ms merge-point hold remain unchanged.

## Audio

`AUDIO_MUSIC_VOLUME` increases from 0.06 to 0.07 (safe range 0.06-0.08). This is a small gain change only. Music/SFX buses, limiter, toggles, playback lifetime, event gains, and contact routing are unchanged.

## Validation

- `RAIL_TARGET_BLAST_GEM_EXPANSION_V1_TESTS`: PASS. Covers both exact crops, metadata/name absence, measured constants, L8 rail contact at five depths, contact telemetry only after physical contact, enlarged radii/scale, bounded blast exclusions, five-ring density, and music gain.
- `GEM_PATTERN_FEEDBACK_V1_TESTS`: PASS across 80 deterministic generated levels with the 34-identity / 22-Common / 12-Unique registry.
- `UI_SCALE_LAYOUT_TESTS`: PASS with the updated geometry and radius ladder.
- `SOUND_PRIVACY_LINK_TESTS`: PASS with 0.07 music gain.
- `REFERENCE_GAME_FEEL_V2_TESTS`: PASS; exact/visible-touch merges, non-match collision, fast-shot substeps, and chains remain contact-driven.
- GL Compatibility/ANGLE production capture: PASS. Reviewed `measured-rails-and-alpha-tight-gems.png` and `enlarged-target-five-ring-wave-and-blast.png` under `reports/rail-target-blast-gem-expansion-v1/screenshots/`.

All eleven repository suites print PASS: the new focused suite plus gem-pattern, reward-feedback, reference-feel, animation/audio/back/privacy, UI/layout, game-flow/reward/splash, sound/privacy, branding/push-line, scene-variety/assets, and AdMob.

## Delivery

- Intake: `97e3c31` / `rail-target-blast-2026-08-25-intake`.
- Source: `21637cb` / `rail-target-blast-gem-expansion-v1-source`.
- APK: `build/android/majestic-gems-rail-target-blast-gem-expansion-v1.apk`; 82,310,470 bytes; SHA-256 `4FBEC0C511EABB8B838F4B8672FAEBE512736CFBE2A32D0F76AB9735424A6D33`.
- Android identity: package `com.owais.majestygems`, debug versionCode 7 / versionName 1.0.5, min SDK 24, target/compile SDK 36. No AAB was generated.
- APK audit: v2 signature PASS, one RSA-2048 Godot debug signer, both ARM ABIs, 993 ZIP entries, all 34 runtime gems, changed compiled scripts, and zero source/test/report/dev/project-build payload.
- Delivery tag: `rail-target-blast-gem-expansion-v1` on the manifest/provenance commit.
- Device: ADB found no connected device. Installation, physical rail feel, touch, listening, haptics, and on-device performance are not claimed.
