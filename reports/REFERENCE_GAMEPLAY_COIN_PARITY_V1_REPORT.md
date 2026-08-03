# Reference Gameplay + Coin Parity v1 Report

## Scope and baseline

- Clean starting delivery: `7c4d699` / `physics-reward-feedback-v1`.
- Exact gameplay source: `b9f15935174f8e52663fcf4c088cac92e0a35bc4`.
- Delivery tag: `reference-gameplay-coin-parity-v1`.
- Scope: keep recommendation point 1 (new levels) for later; improve the current level's reference-like animation/reward cadence and present score as coins.

The supplied reference recording was inspected for timing and composition. No reference frames, art, or audio are shipped. Coin rendering and all new cues are original procedural work.

## Reference observations and response

The reference stays engaging through a thin ready aim line, an immediate dense coin scatter, roughly a dozen staggered curved flights into the counter, visible counter increments during arrivals, and a slower readable result-gem pop. Its next shot does not wait for the long reward flight.

The existing `1160 px/s` launch already matched the observed quick traversal closely enough, so simulation tuning was preserved. Presentation changed as follows:

| Presentation value | Before | Delivered |
|---|---:|---:|
| Merge presentation | 0.27 s | 0.62 s |
| Source pull | 0.08 s | 0.14 s |
| Result start/pop scale | 0.82 / 1.13 | 0.56 / 1.20 |
| Result pop duration | 0.15 s | 0.36 s |
| Normal / major coins | none | 10 / 14 |
| Scatter duration | none | 0.55 s |
| Normal / major flight | none | 1.18 / 1.32 s |
| Per-coin stagger | none | 0.075 s |
| Contact visual | none | 0.16 s child-only squash/pop |

Safe future presentation ranges are merge `0.50-0.75 s`, scatter `0.42-0.65 s`, flight `0.95-1.45 s`, stagger `0.05-0.09 s`, and impact `0.12-0.20 s`. These are not simulation ranges.

## Coins and ownership

- `GameController.coins` is canonical. `score` delegates to it only for compatibility.
- Confirmed result IDs remain exactly-once guarded. L2-L8 rewards remain `10, 25, 60, 150, 350, 800, 1,800`, with the same confirmed chain multiplication.
- The authoritative total updates immediately. The HUD separately advances its visible COINS value when animated records arrive.
- Integer rewards are distributed without loss. Normal completion and the 56-record safety cap both reconcile display and controller totals.
- Gameplay and result UI now say COINS. `ScoreFormatter` remains display-only.

## Presentation/physics boundary

- The ready guide performs no raycast and owns no input or trajectory prediction.
- Coin records are drawn by one `GameplayEffectsLayer`; there is no node per coin.
- Merge growth and contact squash multiply only `GemSpriteLayer`'s `Visual` child. The physics root, position, radius, perspective, rails, impulse response, and merge eligibility never read them.
- `BoardSimulation` only adds impacted IDs to existing confirmed-contact telemetry; collision calculations are unchanged.
- Victory waits for final visible coins, then uses the existing 0.32-second hold and one guarded overlay. Ordinary launcher progression does not wait for coins.

## Original sound and haptics

- Added cached `coin_burst`, `coin_flight`, and `coin_collect` metallic transients using procedural harmonic partials, a fast strike, and pitch sweep.
- Cache truth is 18 one-shots plus the unchanged ambience. Three-player concurrency, cooldowns, and the sound toggle remain active.
- Only the final coin emits the light collection haptic (`16 ms`, amplitude `0.20`). Merge, major, and chain ownership is unchanged.

## Preserved gameplay

Level 1 remains the L1-L4 mixed bag with unlimited launches and exactly one L7 target followed by one L8. Launch speed, damping, sleep, restitution, tangential friction, walls, merge momentum, radii, table/rails, perspective, contact epsilon, merge rules, danger, and reset are unchanged. No other level was created or rebalanced.

## Validation

Godot 4.6.3 final results:

- `GAMEPLAY_UI_FEEL_TESTS: PASS`
- `PRODUCTION_UI_FINALIZATION_TESTS: PASS`
- `LEVEL_1_FLOW_TESTS: PASS`
- `CLEAN_CONTACT_TESTS: PASS`
- `GEM18_CHAIN_TESTS: PASS`
- `MOTION_PROFILE: PASS`

The profile reported zero per-gem process callbacks, zero gameplay resource loads after initialization, 18 cached one-shots, zero residual effects, and `node_delta=0`. The 20-gem sample averaged `3.698 ms`; the six-step reward chain averaged `0.377 ms`. Headless ObjectDB cleanup warnings are test-runner teardown noise, not a phone performance claim.

Four real 720 x 1600 Compatibility/ANGLE captures under `reports/reference-gameplay-parity-v1/final-screenshots/` were reviewed: ready aim, major burst, staggered HUD flight, and exact counter settlement from 400 to 750.

## APK delivery

- APK: `D:\Owais\game\build\android\reference-gameplay-coin-parity-v1.apk`
- Size: `100,806,453 bytes`
- Modified: `2026-08-03 23:11:13 +05:00`
- SHA-256: `CED1D7496791BBDEE3E01C85EF1D2D397A98998785A438B1C3B1613E1CE29A94`
- ZIP: 359 entries; manifest, primary dex, and arm64 runtime present; no `reports/` or `tools/` entries.
- Signature: APK Signature Scheme v2/v3 verified with one RSA-2048 signer.

`adb devices -l` returned no connected device. Installation, launch, phone frame rate, audio balance, haptic feel, and touch timing are not claimed.

## Phone checklist

- Confirm the aim line is readable without distraction.
- Confirm normal/major bursts remain clear in dense clusters.
- Confirm coin ticks do not mask merge/chain cues.
- Confirm final-coin haptic is light and does not chatter.
- Confirm ordinary next-launch input remains responsive during coin travel.
- Confirm victory follows the final coin and appears exactly once.
