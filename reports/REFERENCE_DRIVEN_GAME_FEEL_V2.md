# Reference-Driven Game Feel v2

Date: 2026-08-18

## Reference observations

`current-gameplay-ours.mp4` is the 33.12 s Majestic Gems capture (576x1312, 55.92 fps, mono 48 kHz). `refrence.mp4` is the 59.24 s behavioral reference (360x640, 30 fps, stereo 48 kHz). Both decoded end-to-end. Review used normal playback, 0.5 s full-timeline contact sheets, and focused short sequences around launches, merges, target rewards, coin arrivals, and the reference finale.

The reference makes success legible through immediate contact, a rapid source/result change, a bright short impact, visibly larger result/reward motion, fast layered coins, and little dead time before the next shot. Majestic Gems previously kept appropriate identity and clean UI, but its 1.18x result pop and 0.92-1.00 s coin flights read too softly/slowly at normal speed. Its target checkmark obscured the artwork and looked generic.

## Before vs after

- Before: 0.30 s merge, 1.18x result, eight rays; after: 0.27 s merge, 1.26x result, 10 rays (12 at L6+).
- Before: target checkmark and 0.40 s travel; after: no checkmark, 0.32 s travel, glow/ray arrival, earlier transition.
- Before: coins floated for 0.92/1.00 s; after: 0.54/0.60 s with tighter stagger and a longer, clearer counter pulse.
- Before: normal contact 0.34/0.39 and ordinary merge 0.70; after: contact 0.28/0.32 and merge 0.78, making success unmistakably dominant without replacing assets.

## Merge

- Old behavior: 70 ms pull; the result started at 0.68 scale, peaked at 1.18 over 150 ms, then settled within 300 ms total.
- New behavior: 60 ms pull; result starts at 0.64, reaches 1.26 over 140 ms with cubic-out easing, then uses the existing bounded damped settle to 1.0 by 270 ms.
- Particles: procedural crystal flash/ring plus 10 radial rays for standard merges and 12 for L6+; no texture allocations or persistent emitter.
- Normal collisions retain the 110 ms, maximum 5.5% presentation-only compression and remain excluded for consumed merge pairs.

## Target

- Tick mark removed: YES.
- The already-confirmed result remains a foreground proxy, follows a quicker curved path, fades only near arrival, triggers a 380 ms card glow/ray pulse, updates authoritative progress, and begins sequential-target handoff after 120 ms.
- Collection duration: `0.40 -> 0.32 s`.

## Reward

- Coin travel: `0.92/1.00 -> 0.54/0.60 s`; burst `0.16 -> 0.12 s`; flight stagger `0.08 -> 0.045 s`.
- Counter feedback still reconciles each authoritative chunk on arrival; scale pulse `0.14 -> 0.18 s` so it remains visible despite faster travel.
- Final completion keeps existing reward logic and modal. Faster final target/coin feedback removes dead time before the existing result cue.

## Audio

- Original assets retained: YES. Music retained unchanged at linear gain `0.06`.
- Gains: gem contact `0.34 -> 0.28`; rail `0.39 -> 0.32`; ordinary merge `0.70 -> 0.78`; target arrival `0.82 -> 0.90`; final success `0.84 -> 0.92`.
- Immediate confirmed-frame merge timing, target-arrival timing, coin reward cue, tier pitch variation, cooldowns, five-voice priority pool, buses/limiter, settings, and haptics remain intact.
- No new layering or music ducking was needed; the wider relative hierarchy supplies the emphasis without changing identity.

## Contact bug

- Root cause: the custom circle simulation advanced once per frame, allowing a long frame to skip a contact interval. Additionally, pairs genuinely captured in an early substep could be rejected by a redundant distance test after later substeps had already separated them.
- Affected tiers: potentially every L1-L8 pair during high-speed or long-frame contact; collider radii themselves were already consistently mapped to visuals.
- Geometry changes: none. Radii, `CONTACT_EPSILON=0.20`, perspective mapping, borders, and visual body scale remain unchanged.
- Tunneling/contact changes: up to eight displacement-bounded substeps (`0.45x` smallest live radius per step), plus authoritative consumption of pairs captured inside the confirmed-contact branch.
- Regression: separation no merge, exact contact merge, slight overlap merge once, different-tier collision/no merge, fast-shot detection, resting push detection, and contact-only chain cases pass in `REFERENCE_GAME_FEEL_V2_TESTS`.

## Performance

- Simulation adds 1-8 bounded substeps only when displacement requires them; ordinary settled frames remain one step. The active piece count is small and no broad-phase structure or persistent allocations were added.
- Merge/target visuals remain immediate-mode bounded drawing. Standard/major spark counts are 10/12, coin count remains four, and existing effect caps remain active.
- Build impact and APK audit are recorded after the final debug export.

## Validation status

- Source videos decoded end-to-end: PASS.
- Previous/reference normal-speed review: PASS.
- Updated runtime normal-speed capture: pending until a comparable post-build capture can be recorded; code constants alone are not claimed as perceptual proof.
- `REFERENCE_GAME_FEEL_V2_TESTS`: PASS.
- `UI_SCALE_LAYOUT_TESTS`: PASS.
- `SOUND_PRIVACY_LINK_TESTS`: PASS.
