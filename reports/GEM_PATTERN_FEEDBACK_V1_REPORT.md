# Gem Categories, Pattern Blocks, and Target Feedback V1

## Outcome

The active visual catalog expands from 20 to 32 supplied gems without changing strict contact-only merging, local-tier physics, launcher behavior, danger handling, score authority, ads, or persistence. One audited registry now drives deterministic 3-4-level Same Shape / Same Color blocks and guarantees three distinct, reachable Unique targets on every generated level.

Every target now receives the same merge-first reward sequence, the final visible coin count matches earlier targets, coins read as table objects, all HUD box shadows are removed centrally, and the ten normalized table variants retain the verified shared rail model.

Baseline: commit `64cc6df`, tag `gem-pattern-feedback-2026-08-24-intake`. The baseline commit preserves the 12 user-supplied PNGs byte-for-byte before normalization or processing.

## Source normalization and precise cropping

The new files were visually inspected as pixels, not categorized from their filenames. Their content-preserving source mapping is:

| Intake filename suffix | Stable source ID | Shape | Color family | Style | Rarity |
| --- | --- | --- | --- | --- | --- |
| `10_21_06 PM (2)` | `gem_21` | circle | blue | gradient | Unique |
| `10_21_06 PM (3)` | `gem_22` | circle | pink | gradient | Unique |
| `10_21_06 PM (4)` | `gem_23` | circle | green | gradient | Unique |
| `10_21_08 PM (6)` | `gem_24` | rounded square | blue | gradient | Unique |
| `10_21_10 PM (9)` | `gem_25` | rounded square | blue | gradient | Unique |
| `10_21_11 PM (10)` | `gem_26` | rounded square | red | solid | Common |
| `10_21_14 PM (1)` | `gem_27` | circle | orange | gradient | Unique |
| `10_21_15 PM (3)` | `gem_28` | circle | purple | gradient | Unique |
| `10_21_16 PM (5)` | `gem_29` | circle | orange | gradient | Common |
| `10_21_17 PM (6)` | `gem_30` | rounded square | blue | gradient | Unique |
| `10_21_18 PM (7)` | `gem_31` | rounded square | pink | gradient | Unique |
| `10_21_19 PM (9)` | `gem_32` | rounded square | green | gradient | Unique |

`scripts/dev/prepare_supplied_art_refresh.gd` measures alpha >= 0.01, extracts that exact source rectangle, preserves aspect ratio, scales the longest edge to 256 px with Lanczos, clears sub-threshold edge alpha, and rejects a derivative whose used rectangle does not equal its complete image rectangle. New source alpha rectangles range from `968x946` to `1126x1108`; runtime output ranges from `256x243` to `256x256`.

All 32 sources total 37,692,448 bytes; runtime PNGs total 2,888,351 bytes, a 92.34% reduction. `assets/runtime/art_refresh_manifest.json` records all source/runtime hashes, sizes, and measured alpha rectangles. Source art is excluded from Android packaging; only runtime derivatives ship.

Physics never reads raw PNG dimensions, alpha bounds, metadata shape, or artwork pixels. The unchanged local L1-L8 `36/39/42/45/48/51/54/57` radii remain authoritative.

## Complete registry classification

Only categories present in the supplied set were used. There is one common visual material, so no invented crystal/metallic/candy material taxonomy exists.

| IDs | Shape | Color family | Style | Rarity |
| --- | --- | --- | --- | --- |
| 1 | circle | pink | solid | Common |
| 2 | circle | blue | solid | Common |
| 3 | circle | pink | solid | Common |
| 4 | circle | red | solid | Common |
| 5 | circle | green | solid | Common |
| 6 | rounded square | yellow | solid | Common |
| 7 | rounded square | purple | solid | Common |
| 8 | circle | blue | solid | Common |
| 9 | rounded square | pink | solid | Common |
| 10 | rounded square | blue | solid | Common |
| 11 | circle | orange | solid | Common |
| 12 | circle | blue | solid | Common |
| 13 | circle | yellow | solid | Common |
| 14 | circle | purple | solid | Common |
| 15 | circle | red | solid | Common |
| 16 | rounded square | green | solid | Common |
| 17 | rounded square | orange | solid | Common |
| 18 | rounded square | blue | solid | Common |
| 19 | rounded square | pink | solid | Common |
| 20 | rounded square | purple | solid | Common |
| 21 | circle | blue | gradient | Unique |
| 22 | circle | pink | gradient | Unique |
| 23 | circle | green | gradient | Unique |
| 24 | rounded square | blue | gradient | Unique |
| 25 | rounded square | blue | gradient | Unique |
| 26 | rounded square | red | solid | Common |
| 27 | circle | orange | gradient | Unique |
| 28 | circle | purple | gradient | Unique |
| 29 | circle | orange | gradient | Common |
| 30 | rounded square | blue | gradient | Unique |
| 31 | rounded square | pink | gradient | Unique |
| 32 | rounded square | green | gradient | Unique |

Common: 22 identities (`1-20, 26, 29`). Unique: 10 identities (`21-25, 27, 28, 30-32`). `gem_29` demonstrates that gradient alone does not imply Unique; it stays Common because its warm single-family treatment is less distinctive than the limited multi-hue Unique pool.

`AssetCatalog.gem_entry()` exposes metadata and a stable collision profile but returns an empty display name. No target, Next, progression, Level Ready, Home, result, or settings UI renders a gem name.

## Deterministic level-pattern system

`LevelConfig.pattern_for_level()` is a pure seeded lookup. It reconstructs history from level number, so retry/save reload needs no mutable pattern state:

- each block lasts exactly 3 or 4 levels;
- families alternate Same Shape / Same Color;
- a family does not reuse its immediately previous dominant value;
- within a block, level seed changes the exact identities and order while preserving the dominant rule;
- the generated dictionary records family, dominant value, block index/start/size for debugging.

Local progression roles are fixed and mechanically safe:

- L1-L4: four distinct Common identities and the only launcher ranks;
- L5: one non-target Unique supporting the pattern;
- L6-L8: three distinct Unique targets, ascending and reachable through the ordinary local merge path.

Same Shape selects all four Common plus L5 in the dominant shape; all three targets use the opposite shape. Same Color selects at least three of four Common plus L5 in the dominant color; all targets exclude it. Color blocks use audited families with enough Common and Unique support (`blue`, `pink`, `orange`, `purple`) rather than forcing sparse families or duplicating art.

## Target, wave, and sound feedback

- `TARGET_VISUAL_SCALE = 1.12` applies only to the detached collection proxy after the real result body is removed. Collider radius and live physics remain unchanged.
- Normal merge ring visibility increases through a brighter 30-segment, 3.8 px starting stroke and eight sparks.
- Every target gets three bounded layered rings, a larger 1.38 scale (1.58 final), 14 sparks, and stronger radial intensity. These are capped immediate-mode records, not nodes or particles.
- Target merge feedback runs for 420 ms. The presentation remains settled at the actual merge point for another 120 ms; collection begins at 540 ms.
- Every target then follows the same travel to board center, 1.05 s readable center hold/caption, anticipation, curved HUD flight, and panel impact. The HUD count changes on visible arrival.
- Audio order is merge reveal cue, target reward cue when collection begins after the hold, then `target_collect` at HUD arrival. The reward cue is no longer stacked with collection arrival.

Regression testing found and fixed a legacy fallback that retired the merge presentation at 420 ms and accidentally bypassed the new 120 ms hold. Target presentation records now remain alive, settled, until the configured collection boundary.

## Coin feedback

- Final visible coin count changes from 16 to 4, matching target 1/2 quantity. Reward integer authority is unchanged.
- Earlier target groups hold 1.20 s; final coins hold 1.00 s.
- Idle coins move only subtly along the table plane. The previous vertical bob that read as floating is removed.
- Contact shadow opacity changes from 0.46 to 0.24 with a smaller `(3,5)` offset. Shadows fade when flight begins and never affect gameplay.
- A pre-existing `_level_reward_wave_times.clear()` after plan construction was removed, preserving the cached staggered sound schedule instead of erasing it.

## Table and rail audit

Every runtime table is a 720x1280 derivative with the complete supplied portrait composition and transparent outer corners. The table renderer, board containment, drag clamp, launcher, danger line, and rail collision all consume the same `GameConfig` trapezoid:

- board Y: `455..1165`;
- inner rail X at back: `130..590`;
- inner rail X at front: `54..666`;
- texture center: `(360,844)`;
- texture scale: `(0.9583333,0.752)`.

The all-table regression samples each texture at multiple world rows and verifies physics remains just inside visible rail pixels. Fresh production-scene captures place real L7/L8 bodies at computed left/right contact on back/front rows. Reviewed tables show body edges meeting the visible inner rails without premature invisible bounce, penetration, exterior clipping, or corner trapping. Because all ten normalized designs pass the same opening model, no speculative geometry change was made.

## HUD shadow removal

`UiDesignSystem._frosted_glass_style()` now disables StyleBoxFancy shadow rendering and zeroes its color, blur, offset, and spread. `_rounded_style()` zeroes StyleBoxFlat shadow color, size, and offset. Amethyst fills, gradients, gloss, lavender rims, typography, dimensions, anchors, margins, and safe-area behavior remain unchanged.

This intentionally affects shared HUD/Home/modal/result style factories, preventing a shadow from being reintroduced by a secondary HUD card or state overlay.

## Optimization

- All 32 textures and metadata dictionaries are loaded once; generation queries the registry without scanning directories or analyzing pixels.
- Runtime derivatives replace 37.69 MB of source art with 2.89 MB of package-ready PNGs before Godot import compression.
- Merge rings remain capped draw records; coin records are freed at arrival and reset/failure paths clear all channels.
- The level-reward sound wave plan is computed once per final reward and retained.
- No shaders, GPUParticles, physics objects, or per-frame resource loads were added.

## Validation

Focused suite `GEM_PATTERN_FEEDBACK_V1_TESTS`: PASS across 80 levels. It covers 32 metadata records/textures, exact alpha-tight bounds, 22/10 pool split, both shape dominants, cool/warm color blocks, 3-4-level history, deterministic retries, three valid Unique targets, contrast rules, L6-L8 reachability, 1.12 scale, wave hierarchy, 120 ms hold, coin parity/holds/shadows, and zero HUD StyleBox shadows.

Existing focused regressions currently pass: scene variety/assets, reward feedback v3 (updated only where this explicit milestone supersedes its compact/non-final and 16-coin expectations), sound/privacy routing, UI/table scale, and reference strict-contact game feel. Complete suite results and Android artifact evidence are recorded at delivery.

`tests/capture_gem_pattern_feedback_v1.gd` ran the production scene through GL Compatibility/ANGLE and produced nine reviewed 720x1280 PNGs plus contact sheets under `reports/gem-pattern-feedback-v1/`. Evidence includes circle dominant, rounded-square dominant, cool color, warm color, computed rail contacts, three-ring target wave, settled origin hold, center travel/hold, and exactly four final coins resting on the table.

No Android device was connected at the time of source validation; on-device touch, listening, and long-session performance are not claimed.

## Delivery

Source commit/tag, APK filename/hash/audit, complete suite results, and connected-device status are appended in the delivery commit after validation.
