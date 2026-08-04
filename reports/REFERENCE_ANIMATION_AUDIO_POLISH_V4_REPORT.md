# Reference Animation + Supplied Audio Polish v4 Report

## Outcome

The three requested animation beats now follow the supplied reference's measured structure: a quick color splash and single rigid result pop for merges, exactly four larger foreground coins only on target completion, and a held success check followed by an in-place fade to the next centered target. The separately supplied music and coin files are independently routed; music is continuous and soft, while coin and gem events remain foreground feedback.

Level 1 is still L5, then L7, then L8. Physics, table/rail geometry, radii, collision/merge eligibility, launch speed, damping, restitution, momentum, danger rules, reward integers, and result qualification did not change.

## Reference observations

The supplied reference `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4` was reviewed around the first target sequence at frame-level cadence and cross-checked at the later two rewards.

- Same-tier sources converge around `14.25-14.45 s`; coins first appear around `14.50 s`.
- A solid result-color splash is visible around `14.55-14.60 s`; the upgraded rigid gem appears/grows rapidly by roughly `14.65-14.75 s`. The reference does not use generic circular rings or radial ray spokes here.
- Four visible coins form one rising group. Full-reference review shows coin sequences only at the three target results near `14.6 s`, `46.6 s`, and `58.0 s`, never on ordinary merges.
- The completed target receives a large green check around `15.6 s`, holds, then the old centered card fades around `16.4-16.8 s`; the new centered target fades in around `17.0-17.2 s`. It does not fly top-left or enter from the right.

## Implemented animation

| Presentation value | Before v3 | v4 | Guardrail / reason |
| --- | ---: | ---: | --- |
| Merge total | `0.50 s` | `0.34 s` | Keep `0.30-0.38 s`; removes the slow/static pause. |
| Source pull | `0.10 s` | `0.08 s` | Short inward read before result. |
| Result pop | `0.62 -> 1.20` over `0.22 s` | `0.72 -> 1.12` over `0.14 s` | One uniform overshoot, then clean settle; no second wobble. |
| Merge effect | ring/rays, `0.56 s` major | irregular color splash, `0.26 s` (`0.30 s` major) | Reference-like filled accent behind unchanged artwork. |
| Coin pop / size | `0.38 s`, `14.5 px` | `0.22 s`, `17 px` | Four coins become readable immediately without multiplying count. |
| Coin flight | `1.70/1.75 s`, stagger `0.09 s` | `1.58/1.66 s`, stagger `0.15 s` | Faster overall reward with readable ordered separation. |
| Target collection | `0.84 s`, fade from 78% | `0.62 s`, fade from 90% | Foreground gem stays visible and reaches the card decisively. |
| Success check | `0.58 s` ornate ring/sparks | `0.94 s` large green check | Clear confirmation and longer rewarding hold. |
| Next target | directional travel after `0.30 s` | hold `0.78 s`; `0.24 s` out, `0.10 s` gap, `0.24 s` in | Centered opacity handoff measured from the reference. |

Gem presentation scale is always uniform, with zero animation rotation and zero animation position offset. Collision telemetry creates audio only and cannot register a deformation transform. Coins and the collection proxy remain in `RewardForegroundHost` above world gems and HUD cards.

## Supplied audio integration

| Layer | Preserved original | Runtime derivative | Runtime behavior |
| --- | --- | --- | --- |
| Music | `assets/sound/gem_merge_music_loop.wav`, 29.72 s, SHA-256 `AF055BE7F2BFC356778B3D1343CB442B46FAE753070EF671F90DD6889789AB2C` | `assets/runtime/audio/supplied_background_music_v4.ogg`, SHA-256 `C214AE23E35B5A2BD5D9038C84E13FCF40CE759AA970D781243EB864C46BB86E` | Dedicated player starts once, loops continuously, linear gain `0.14`, never movement-triggered. |
| Coin | `assets/sound/coin-sound.mp3`, 1.30 s, SHA-256 `AF8A9EC4D8B718703980C28B58C851AACF515DA9FC1E2D90AC592D1295D0EF76` | `assets/runtime/audio/supplied_coin_reward_v4.ogg`, 0.98 s, SHA-256 `B2008F0331507EBDCF4F5FC008EFE9DCF2FDCC64D4515C1A21E0D2746F1C501A` | One unpitched cue only on unique active-target qualification. |

The music derivative is a full-duration Ogg conversion without gain/EQ/pitch processing. The coin derivative trims only leading/trailing silence and adds short edge fades. Measured runtime music is `-15.5 dBFS` mean / `-1.0 dBFS` max before service gain; at `0.14` it is approximately `-32.6/-18.1 dBFS`. Coin is `-27.5/-6.9 dBFS` at unity event gain. This is objective gain staging, not a phone-speaker listening claim.

## Validation

- `GAMEPLAY_UI_FEEL_TESTS: PASS`
- `CLEAN_CONTACT_TESTS: PASS`
- `LEVEL_1_FLOW_TESTS: PASS`
- `GEM18_CHAIN_TESTS: PASS`
- `PRODUCTION_UI_FINALIZATION_TESTS: PASS`
- `MOTION_PROFILE: PASS`; crowded-board worst process sample `6.889 ms`, resource loads after initialization `0`, cached event streams `16`, node delta `0`.
- `REFERENCE_ANIMATION_AUDIO_POLISH_V4_CAPTURE: PASS`; all six 720 x 1600 ANGLE frames were reviewed.

The regression suite proves ordinary merges have no coin records/cue, a target reward has exactly four records and one coin cue, the music player is independent and toggle-safe, target movement stays foreground, the check/handoff timings remain bounded, and the complete physics signature is unchanged.

## Delivery

- Clean pre-change baseline: `a64e220` / `reference-animation-audio-polish-v4-baseline`.
- Source tag: `reference-animation-audio-polish-v4-source`.
- Final delivery tag and APK provenance are added after the single final Android export.
- Physical-device status: not yet claimed. The final delivery check will record `adb devices -l`; listening and haptic checks require a connected phone.

## Manual device checklist

- Confirm merge art stays rigid through contact, source pull, splash, pop, and settle.
- Confirm ordinary merges never show/hear coins; L5/L7/L8 each show exactly four and play one coin cue.
- Confirm the target gem/coins remain above the table and cards throughout travel.
- Confirm the completed target check reads clearly, holds, then fades in place before the new centered target.
- Listen through the music loop seam; confirm it stays soft and never restarts on movement/launch/contact.
- At normal phone volume, confirm coin and L5/L7/L8 merge cues dominate music without clipping or chatter.
