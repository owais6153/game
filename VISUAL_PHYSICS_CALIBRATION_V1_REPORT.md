# Visual-Physics Calibration v1

## Baseline and evidence

- Baseline source: `7ac26f1` / `asset-integration-background-table-gems-v1`, with documentation-only provenance commit `8aedef9` on top; the working tree was clean before this milestone.
- Recording: `WhatsApp Video 2026-07-29 at 10.41.41 AM.mp4`, 40 seconds, 576x1312, 24 fps. The local media runtime could read container metadata but could not decode the recording codec for frame/audio extraction in this session. The user’s observed issues were therefore treated as the visual acceptance criteria and are explicitly listed in the phone checklist below; no unsupported claim of audio listening is made.
- Asset inspection found that the live sprites were scaled from full texture rectangles while every piece retained the old 42 px collider. This made the visible artwork materially smaller than the physical body, especially Emerald and Diamond.

## Correction

### Table / background perspective

- Preserved the supplied original table and created `assets/runtime/table/coral_table_calibrated.png` as a non-destructive perspective derivative.
- Relaxed the inner top rail from `x=129..594` to `x=90..630` at `y=224`; bottom rail remains `x=0..720` at `y=1080`.
- The renderer, physical rail functions, spawn point, drag clamps, danger line, and containment all use the same `GameConfig` layout values.

### Gem calibration

| Gem | Prior runtime dimensions | Alpha >=32 bounds | Calibrated texture | Collision radius |
| --- | ---: | --- | ---: | ---: |
| Pearl | 433x512 | 8,9–425,482 | 421x477 | 42 px |
| Ruby | 461x512 | 8,9–452,481 | 448x476 | 42 px |
| Emerald | 390x512 | 11,23–375,493 | 368x474 | 32 px |
| Sapphire | 496x512 | 12,7–484,486 | 476x483 | 42 px |
| Diamond | 512x427 | 30,8–486,372 | 460x368 | 33 px |

- Calibrated files preserve a 2 px anti-alias rim and do not overwrite the user source or previous runtime copies.
- `CONTACT_EPSILON` is now 0.75 px (was 1.5 px); documented visible-contact tolerance is 1 design px.
- Emerald and Diamond use deliberately simple calibrated circles for deterministic, stable gameplay; no fragile image polygon colliders were introduced.

### Contact sound and diagnostics

- Collision telemetry carries the actual confirmed gem or rail contact point from `BoardSimulation`.
- Existing low-impact thresholds, cooldowns, and concurrency limits remain in place. Merge sound remains emitted only after confirmed merge execution.
- F8 toggles a developer-only desktop/editor diagnostic overlay for rails, collider circles, and temporary contact markers. It starts disabled and is not part of normal Android flow.

## Automated validation

- Godot 4.6.3 import/parse validation: passed.
- `tools/run_clean_contact_tests.gd`: passed (`CLEAN_CONTACT_TESTS: PASS`).
- Added coverage for calibrated radius mapping, alpha-padding non-inflation, one-pixel first-contact tolerance, per-level rail alignment, and collision-audio telemetry only at confirmed contact.
- Existing contact-only merge, chain, non-merge, launcher, score, win/fail, restart, and containment coverage remains passing.

## Manual phone checklist

1. Pearl/Pearl and Ruby/Ruby slow contact: artwork should meet before the collision/merge cue.
2. Pearl/Ruby: visible contact should push with no merge.
3. Emerald against a round gem and Diamond against either side rail: no obvious invisible gap or penetration.
4. Top rail, direct merge, and chain merge: rail and gem cues should occur at visible contact; rapid contacts should not spam.
5. In an editor/desktop preview, press F8 to capture debug screenshots, then restart normal Android flow and confirm the overlay is absent.

## Delivery

- APK: `build/android/visual-physics-calibration-v1.apk`
- Size: 72,539,231 bytes
- Built: 2026-07-29 10:58:56 +05:00
- Device status: no connected Android device was used; no install or launch is claimed.
- Source commit: `8fdebd405c791eddf9188bd32e9f0de3b83cbd42` (`fix: align table perspective and visible gem collisions`)
- Tag: `visual-physics-calibration-v1`
