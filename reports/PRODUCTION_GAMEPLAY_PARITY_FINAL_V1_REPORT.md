# Production Gameplay Parity Final v1 Report

## Outcome

This is the final Level 1 gameplay-feel milestone before new levels and screens. It addresses the latest `WhatsApp Video 2026-08-04 at 1.29.14 AM.mp4` against `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4`: the current build no longer relies on raw launch speed to create energy. It adds visible pile response, directional contact deformation, a readable elevated merge result, reference-shaped coin choreography, a stronger original sound bed, the requested L5 -> L7 -> L8 objective order, and a rail-contained edge guide.

The implementation does not copy reference art, audio, or code. The supplied project coin is used non-destructively; all sounds remain original procedural synthesis.

## Video findings resolved

- Both supplied recordings were approximately 24 FPS, and launch travel was already close. The slow feeling came from weak secondary motion, a flat parked top row, buried merge results, uniform animation, sparse/ordered coin travel, and a much quieter mix.
- In the latest game recording, merges around 8.75 s and 15.5 s left neighboring gems nearly static; from roughly 24-46 s the upper group read as a rigid row. The reference visibly compressed, rebounded, and rearranged its pile around 14.5-16.5 s and 46.5-50 s.
- The prior reward formed a symmetric halo and then beads along one path through a large empty sky area. The final reward uses an upward fan, four deterministic cubic lanes, permuted departure order, scale/spin variation, and an early leftward route around the target.
- The latest recording measured about `-34 dBFS` overall (`-34.5 dBFS` median 100 ms window); the reference measured about `-19.6 dBFS` overall (`-26.5 dBFS` median). The final mix is materially stronger while retaining caps and leaving phone listening as a hardware check.

## Mechanics and tuning

| Central value | Before | Final | Approved final range/role |
| --- | ---: | ---: | --- |
| Launch speed | 1160 | 1160 | unchanged, `1120-1200` |
| Damping px/s2 | 210 | 185 | `175-205` |
| Side/top/bottom restitution | .20/.16/.10 | .24/.22/.12 | contained redirection |
| Piece restitution | .22 | .30 | `.26-.34` |
| Approach-only tangent friction | .10 | .07 | `.05-.10` |
| Merge momentum/cap | .45 / 300 | .62 / 420 | bounded pile rearrangement |
| Merge duration/start/pop | .62 / .56 / 1.20 | .68 / .52 / 1.26 | presentation only |
| Contact animation | .16 uniform | .22 directional | presentation only |
| Coin fan/flight/stagger | .55 / 1.18-1.32 / .075 | .46 / 1.18-1.28 / .065 | 10/14 records, cap 56 |

Table art, rail anchors, perspective, all calibrated radii, contact/separation epsilon, same-level/contact-only merge eligibility, chain cap, launch speed, unlimited launcher, danger grace, confirmed-event currency, and full reset are preserved.

## Animation and coin implementation

- Confirmed telemetry carries the already-computed contact normal. A presentation-only impact axis applies squash/cross-stretch/kick in that direction while an inverse artwork node keeps the gemstone identity upright. Rest returns to exact scale/offset/rotation identity.
- A result begins at `0.52`, lifts up to 18 design px, tilts deterministically, uses an anisotropic `1.26` overshoot, dampens to 1.0, and is temporarily elevated in local rendering. Physics root position, radius, perspective, velocity, and z authority remain unchanged.
- Supplied source: `assets/buttons/ChatGPT Image Aug 4, 2026, 07_10_27 AM.png`. Runtime derivative: `assets/runtime/effects/coin_reward.png`. The 256 x 256 transparent crop is shared by the HUD and transient rewards through `AssetCatalog.COIN_REWARD`.
- Coin departure ranks are permuted across the fan; the final record remains last for exact counter settlement and one final haptic. Safety capping still emits removed values.

## Aim guide and objectives

`GameConfig.vertical_lane_top_y()` intersects a legal vertical lane with the authoritative sloped table rails. The controller starts the guide below that point and suppresses a too-short segment. Center, legal-left, and legal-right regressions prove line/dot containment.

Level 1 target order is exactly L5, L7, L8. Each unique merge-created result completes presentation, leaves physics, travels to TARGET, and only then advances. L8 remains the sole final qualification.

## Sound

All 18 one-shots and the six-second loop are generated once at startup. The ambience now includes a 120 BPM crystal/mallet rhythm, off-beat glass answers, light shaker, and restrained tonal bed. Central one-shot gains are stronger, but meaningful contact thresholds, cooldowns, three-player concurrency, the sound toggle, and service-only haptics remain unchanged. See `SOUND_HAPTICS_V1_REPORT.md` for the event map and manual listening checklist.

## Validation before export

- Godot 4.6.3 parse/import: passed (sandbox-only editor-settings warnings did not affect project import).
- `CLEAN_CONTACT_TESTS: PASS`
- `LEVEL_1_FLOW_TESTS: PASS`
- `GAMEPLAY_UI_FEEL_TESTS: PASS`
- `GEM18_CHAIN_TESTS: PASS`
- `PRODUCTION_UI_FINALIZATION_TESTS: PASS`
- `MOTION_PROFILE: PASS`
- Motion profile: empty launch `0.133 ms` average; 20 active gems `1.721 ms`; crowded board `1.518 ms`; six-step reward chain `0.315 ms`; zero per-gem process callbacks, zero gameplay resource loads after initialization, 18 cached one-shots, zero residual effects, and `node_delta=0`.

Four real 720 x 1600 Compatibility/ANGLE captures were reviewed under `reports/production-gameplay-parity-final-v1/final-screenshots/`: contained edge guide, major merge/fan, multi-lane HUD flight, and exact 400 -> 750 counter settlement.

## APK and device status

- APK: `D:\Owais\game\build\android\production-gameplay-parity-final-v1.apk`
- Size: `102,674,715 bytes`
- Modified: `2026-08-04 07:50:41 +05:00`
- SHA-256: `132FA633E3208C707D2BA8EF80D5F41A119A061F9608EC0A5C0BC68A06F36E78`
- Source commit/tag: `2f2dbafa96bcb13e423bc8a49e2cbb0306beb2d3` / `production-gameplay-parity-final-v1-source`
- Delivery tag: `production-gameplay-parity-final-v1`
- APK ZIP: 363 entries; `AndroidManifest.xml`, primary dex, and arm64 Godot runtime present; no `reports/` or `tools/` entries.
- Signature: APK Signature Scheme v2 and v3 verified; one RSA-2048 signer.
- `adb devices -l` completed with no attached device. Installation, launch, phone frame rate, loudness balance, touch feel, and haptics are not claimed.
