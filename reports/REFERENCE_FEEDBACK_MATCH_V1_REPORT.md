# Reference Feedback Match v1 Report

## Outcome

This corrective milestone addresses the latest user feedback against `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4`. It removes the over-animation introduced by the previous pass: gems no longer deform on collision, merge results keep their shape, every reward uses four coins instead of 10/14, the target arrival has the reference's clear confirmation beat, and production no longer plays the invented procedural music or layered synthesized coin sounds.

Level 1 remains L5, then L7, then L8. This milestone does not create another level or change launch, physics, table, rail, collision, merge eligibility, currency, danger, launcher, reset, or result qualification behavior.

## Measured reference findings

- At the target merge near `14.5 s`, exactly four animated coins are visible in one tight cluster around the rigid result.
- The result remains proportionally rigid while scaling uniformly; no collision or merge frame shows independent X/Y squash.
- The collected result reaches the order/target area and the large green check is readable around `15.8 s`.
- The same four tokens form one spaced route toward the counter and complete around `17.0 s`; there is no 10/14-token fan or four-lane sky pattern.
- The ordinary reward around `46.55-48.45 s` likewise reads as one combined merge/coin sequence.
- The prior production pass explicitly added rhythmic crystal/mallet/shaker ambience, which is absent from the requested reference feel and has now been removed from the active runtime.

## Presentation tuning

| Central value | Previous | Corrected | Safe role/range |
| --- | ---: | ---: | --- |
| Merge duration | 0.68 s | 0.50 s | presentation only, `0.45-0.58` |
| Result start / peak | 0.52 / 1.26 | 0.62 / 1.20 | uniform only |
| Result pop duration | 0.30 s | 0.22 s | `0.18-0.26` |
| Lift / tilt / anisotropic stretch | 18 px / .075 rad / enabled | 0 / 0 / removed | rigid silhouette invariant |
| Contact deformation | .22 s directional squash/kick | removed | sound telemetry only |
| Normal / major coins | 10 / 14 | 4 / 4 | exact reference-visible count |
| Burst duration / radius | .46 s / 82-106 px | .38 s / 44-48 px | compact cluster |
| Flight / stagger | 1.18-1.28 s / .065 s | 1.70-1.75 s / .09 s | four readable ordered tokens |
| Coin draw radius | 15 px | 12.5 px | mobile-readable reference scale |
| Counter pulse | .24 s, 1.32x + rotation | .14 s, 1.14x, no rotation | restrained arrival |
| Target travel | .62 s | .84 s | visual proxy only |
| Target arrival effect | .22 s ring + six dots | .58 s ring + green check + eight sparks | HUD-layer overlay, above target card |

All simulation values remain: launch `1160`, damping `185`, sleep `9`, walls `.24/.22/.12`, piece restitution `.30`, tangent friction `.07`, merge momentum/cap `.62/420`, and the existing rails/radii/epsilons.

## Coin asset and choreography

The previous ornate palm/gem coin was too detailed at gameplay size. A new original front-facing gold token with one faceted star-gem mark was generated through the built-in image-generation workflow. Its preserved source is `assets/generated/reference_match_coin_source.png`; the keyed/cropped 256 px runtime derivative is `assets/runtime/effects/coin_reward_reference_v2.png`.

`GameplayEffectsLayer` creates exactly four integer-preserving records. They use fixed compact cluster offsets, ordered ranks `[0,1,2,3]`, one bounded cubic route, stable circular rendering, and one final arrival. The authoritative controller total still updates exactly once at merge confirmation, and HUD arrival chunks still reconcile to it exactly.

## Rigid gem invariant

Production collision routing no longer creates `piece_impact_feedbacks` or calls `GemSpriteLayer.set_impact_transform()`. The presentation setter itself collapses any requested vector scale to one uniform scalar and forces zero rotation. Merge emphasis therefore changes apparent size uniformly without changing the supplied artwork's proportions. No animation data reaches `GemPiece`, live radius, position, velocity, contact capture, merge eligibility, rails, or z authority.

## Reference-derived audio

Source recording SHA-256: `29EFA393864912DDB77E3851E034E8F2E457F489AF5D6AB6BADC0CEA13979DA3`.

| Runtime stream | Source window | Duration | SHA-256 |
| --- | --- | ---: | --- |
| `reference_launch.ogg` | 5.98-6.38 s | .400 s | `6F177B54BB82AF87357729528E65500A917A7E3BE42C63FB7AF1A34765900B77` |
| `reference_contact.ogg` | 6.90-7.32 s | .420 s | `1E22D1D9CF01E15CA446925878BF1340F2882E3E979095D89EAA0A11DD21BFEB` |
| `reference_merge_reward.ogg` | 46.55-48.45 s | 1.900 s | `67E6CAB8860975B0B18E91DE0190AA18BF3237705D50162675F5947B12B74446` |
| `reference_target_reward.ogg` | 14.45-17.10 s | 2.650 s | `706B7C5625E49F584E263A60C92A5C05C1CF5019D43F6AFBBFDFC8DF2097642E` |

The clips are mono 48 kHz Ogg derivatives with no normalization, EQ, pitch change, synthesis, or added music. `ReferenceAudioFeedbackService` preloads them, owns the reusable three-player pool, and keeps thresholds/cooldowns. A merge emits one combined ordinary or target sequence; coin phases and win overlay do not add duplicate sounds.

## Final local validation

- `GAMEPLAY_UI_FEEL_TESTS: PASS`
- `CLEAN_CONTACT_TESTS: PASS`
- `LEVEL_1_FLOW_TESTS: PASS`
- `GEM18_CHAIN_TESTS: PASS`
- `PRODUCTION_UI_FINALIZATION_TESTS: PASS`
- `MOTION_PROFILE: PASS` with zero per-gem process callbacks, zero gameplay resource loads after initialization, seven cached active audio-event mappings, zero retained bounded effects, and zero node delta.
- `REFERENCE_FEEDBACK_MATCH_CAPTURE: PASS` using Godot 4.6.3 Compatibility/ANGLE at 720 x 1600.
- The four reviewed renders prove a rigid merge result with a four-coin cluster, one compact coin route, a large visible HUD-layer target check, and exact `400 -> 550` settlement.
- APK export/signature/ZIP checks, source/delivery commit and tags, and ADB status are recorded after the release export below.

## Manual phone checklist

- Confirm no continuous music plays.
- Compare launch, gem contact, ordinary merge, and target merge directly with the supplied reference at typical media volume.
- Confirm gems remain rigid during all contacts and use only uniform merge scaling.
- Count exactly four animated coins on normal and major rewards.
- Confirm the target green check/ring is readable and coins do not duplicate at target arrival.
- Confirm no coin tick layer doubles the combined reference reward sample.
- Verify final-coin, merge, target, and win haptics remain singular on hardware.
