# 18-Gem Size & Collision Fix v1

## Scope and baseline

- Approved motion baseline: `18-gem-motion-smoothness-fix-v1` / `6953b4095b8924096a7d71445771cecbc893e30d`.
- This milestone changes only presentation asset trimming, visual-body mapping, and visual-only shadow placement for the 18 existing gem tiers.
- The original source PNGs under `assets/gems/` and the earlier `assets/runtime/gems18/tier_*.png` files remain unchanged.
- Motion/physics constants were not changed: launch speed, damping, restitution, friction, solver, timestep, velocity limits, sleep/settle thresholds, merge timing, and simulation circle radii are byte-for-byte unchanged from the approved motion build.

## Calibration method

`tools/calibrate_18_gem_bodies.gd` performs one offline alpha scan at threshold 128 and writes non-destructive files under `assets/runtime/gems18/calibrated/`. Each derivative contains the solid visible body plus one pixel of antialias padding. It excludes transparent margins, external glows, and all shadows. Runtime texture lookup remains a `preload()` cache; no alpha scan or texture load runs during gameplay.

All pieces continue to use existing fixed simple `Circle` colliders. The display target is the fixed collider diameter multiplied by the documented 1.008 body-only visual mapping. Shadows are separate Sprite2D nodes and never participate in collision, merge, rail, or sound logic.

## Per-gem calibration

| Tier | Runtime texture | Visible body (px) | Display target | Collider | Shadow offset / opacity |
| --- | --- | ---: | ---: | --- | --- |
| L1 | `calibrated/tier_01.png` | 252 x 254 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.42 |
| L2 | `calibrated/tier_02.png` | 197 x 254 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.40 |
| L3 | `calibrated/tier_03.png` | 254 x 254 | 64.5 x 64.5 | Circle r32, offset 0,0 | 4,18 / 0.38 |
| L4 | `calibrated/tier_04.png` | 254 x 252 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.40 |
| L5 | `calibrated/tier_05.png` | 191 x 254 | 66.5 x 66.5 | Circle r33, offset 0,0 | 4,19 / 0.34 |
| L6 | `calibrated/tier_06.png` | 227 x 254 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L7 | `calibrated/tier_07.png` | 254 x 218 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L8 | `calibrated/tier_08.png` | 195 x 254 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L9 | `calibrated/tier_09.png` | 142 x 254 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L10 | `calibrated/tier_10.png` | 236 x 237 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L11 | `calibrated/tier_11.png` | 181 x 254 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L12 | `calibrated/tier_12.png` | 254 x 250 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L13 | `calibrated/tier_13.png` | 254 x 179 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L14 | `calibrated/tier_14.png` | 228 x 241 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L15 | `calibrated/tier_15.png` | 254 x 249 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L16 | `calibrated/tier_16.png` | 246 x 254 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L17 | `calibrated/tier_17.png` | 254 x 231 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |
| L18 | `calibrated/tier_18.png` | 240 x 254 | 84.7 x 84.7 | Circle r42, offset 0,0 | 5,23 / 0.36 |

## Validation

- Godot 4.6.3 import/parse validation: passed.
- `CLEAN_CONTACT_TESTS: PASS`.
- `GEM18_CHAIN_TESTS: PASS`, including all calibrated texture paths, preloaded resource identity, alpha-manifest coverage, all same-tier merge paths, cross-tier rejection, L18 terminal behavior, fixed radii, and no perspective/frame alpha processing.
- `MOTION_PROFILE: PASS` with zero gameplay resource loads after initialization and zero per-gem processing callbacks.
- Android debug export: passed; ZIP structure includes `AndroidManifest.xml` and `classes.dex`.
- No Android device was connected, so installation and phone testing are not claimed.

## Files changed

- `assets/runtime/gems18/calibrated/` and its `calibration_manifest.json`
- `tools/calibrate_18_gem_bodies.gd`
- `scripts/asset_catalog.gd`
- `scripts/game_config.gd`
- `tools/run_18_gem_chain_tests.gd`

## APK

- File: `build/android/18-gem-size-collision-fix-v1.apk`
- Size: `99,187,450` bytes
- Modified: `2026-07-30 08:30:36 +05:00`
- SHA-256: `391A97C53874B783AE00A835F3A3C07EB6D75340686556B18E3B8C42999F7D8D`
