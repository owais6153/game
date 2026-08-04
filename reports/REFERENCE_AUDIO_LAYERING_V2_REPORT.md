# Reference Audio + Reward Layering v2 Report

## Outcome

This milestone corrects the six presentation problems reported against the latest gameplay recording while preserving the approved Level 1 mechanics. Reference music is continuous, event slices no longer restart it, earlier gem cues are restored, four coins and the collection gem render above gameplay/HUD boxes, L5→L7→L8 target identity changes are readable, and the launcher guide now matches the danger-line color.

## Baseline and scope

- Clean starting commit: `4dfd253896f29b7441ea5538603a9ebf7798a9a6` (`reference-feedback-match-v1`).
- Pre-change milestone tag: `reference-audio-layering-v2-baseline`.
- Supplied comparison: `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4`, SHA-256 `29EFA393864912DDB77E3851E034E8F2E457F489AF5D6AB6BADC0CEA13979DA3`.
- User-requested scope: audio classification/routing, foreground presentation order, coin readability, target collection/handoff, and guide color.
- Explicitly preserved: launch/motion constants, rigid silhouettes, table/rail geometry, radii, contact/merge eligibility, L1-L4 unlimited launcher queue, L5→L7→L8 target data, exact currency values, danger grace, reset, and result qualification.

## Root cause

The previous pass cut four short samples from the supplied reference recording and mapped them to launch/contact/merge/target events. Those windows contained the recording's continuous musical bed. Replaying the windows on gameplay events made the music sound tied to movement and exposed captured high-frequency effects as an unwanted glass cue.

Reward travel also lived in the default world canvas. A world z-index could place effects above live world gems but could not place them above the layer-40 HUD target/coin cards. The target completion then added both a world arrival burst and a HUD confirmation, while the target icon itself only performed a same-texture scale/fade.

## Implemented correction

### Continuous music and bounded gem sounds

- Production instantiates `AudioFeedbackService`, not `ReferenceAudioFeedbackService`.
- `assets/runtime/audio/reference_music_loop.ogg` is duplicated, marked to loop, assigned to one dedicated player, and started once during service initialization. No movement or controller event starts, stops, seeks, or restarts it.
- The earlier 15 cached gem one-shots cover launch, typed gem/wall contact, L2-L8 merges, chain, target collection, win, fail, and button.
- Separate coin burst/flight/arrival sounds remain disabled. Target and final result each emit one bounded cue; haptics remain unchanged.
- The existing sound toggle controls both the continuous player and one-shots. Three-player reuse, event cooldowns, and contact thresholds remain centralized.

### Foreground rewards and target handoff

- `GameplayHudLayer` builds one `RewardForegroundHost` at z `10` inside CanvasLayer `40`; `GameplayEffectsLayer` is attached to this host.
- HUD panels stay at z `0`; target confirmation is z `20`; Pause is z `30`; Results remain CanvasLayer `50`.
- Four coin records and the collection proxy therefore draw above live gems and target/coin boxes without covering Pause or Results.
- The duplicate `GameplayEffectsLayer.target_arrivals` world effect was removed. One HUD check/ring confirmation remains.
- Two prebuilt target sprites are reused. After the confirmation begins, the old L5/L7 target moves `(-72,-42)` while fading/scaling to `0.72`; L7/L8 starts `64 px` to the right at `0.92` scale and fades/slides into place. Start delay is `0.30 s`; transition duration is `0.42 s`. No snapshot update creates nodes.

### Readability and color

- Coin draw radius: `12.5 → 14.5 px` (approved safe range for this four-token art: `13.5-15.0`). Count, paths, stagger, duration, values, and cap are unchanged.
- Aim guide: white/gold → centralized `GameConfig.DANGER_LINE_COLOR` (`#E85F52`) for both line and start dot. Its rail-derived containment is unchanged.
- Music gain: `0.0 → 0.34` because the active path now owns one continuous player (safe listening range pending hardware: `0.25-0.42`).
- Target swap safe ranges: delay `0.24-0.36 s`, duration `0.36-0.48 s`, incoming horizontal offset `48-72 px`; these are presentation-only.

## Audio asset provenance

The active loop uses input window `25.05-26.90 s` from the preserved reference. Output is `1.800 s`, mono 48 kHz, 21,001 bytes, SHA-256 `F6620082833E5481282320ADCEAAB23C6F92A5EE497C29A5C093684F2EC0428F`. A 50 ms circular crossfade blends source tail `26.85-26.90 s` with head `25.05-25.10 s`; the main body is `25.10-26.85 s`. No gain, EQ, pitch, or synthesized layer was applied. The four previous event derivatives remain preserved for audit but are inactive.

## Automated validation

- `GAMEPLAY_UI_FEEL_TESTS: PASS`
- `CLEAN_CONTACT_TESTS: PASS`
- `LEVEL_1_FLOW_TESTS: PASS`
- `GEM18_CHAIN_TESTS: PASS`
- `PRODUCTION_UI_FINALIZATION_TESTS: PASS`
- `MOTION_PROFILE: PASS`
- Profile invariants: `cached_audio_streams=15`, `gameplay resource loads after initialization=0`, `bounded_effects=0`, `node_delta=0`.
- Deterministic ANGLE capture: `REFERENCE_AUDIO_LAYERING_V2_CAPTURE: PASS`; target handoff proof sampled outgoing alpha `0.658` / incoming alpha `0.779` with both persistent sprites visible.

One `Settings press feedback` timing assertion failed when six separate Godot processes were launched concurrently under load; `PRODUCTION_UI_FINALIZATION_TESTS` passed immediately when rerun alone and had also passed in the earlier isolated pass. The isolated pass is the final UI validation result.

The Windows certificate-store warning and known exit-time resource warning remained non-fatal. No relevant assertion failed.

## Visual evidence

Four reviewed 720×1600 Compatibility/ANGLE frames are stored under `reports/reference-audio-layering-v2/final-screenshots/`:

1. danger-colored ready guide;
2. four larger coins visibly crossing above the target card;
3. collected L5 proxy visibly overlapping the target box in the foreground;
4. faded L5 moving top-left while L7 fades in from the right.

## Delivery provenance

- Source commit/tag: recorded in the delivery update as `reference-audio-layering-v2-source`.
- Delivery commit/tag: recorded after APK manifest finalization as `reference-audio-layering-v2`.
- APK: `build/android/reference-audio-layering-v2.apk`; exact size, timestamp, SHA-256, validation, and device status are recorded in `BUILD_MANIFEST.md` after export.

## Manual device checklist

- Confirm music begins once, loops continuously, and does not audibly restart on launch/contact/merge.
- Confirm the restored contact cues read as short gem impacts rather than the captured glass slice and do not chatter in a crowded pile.
- Confirm no coin ticks play; verify L5/L7/L8 merge, target, and final cues at typical media volume.
- Confirm four coins and target travel stay above live gems/cards on the phone aspect ratio.
- Confirm old target fades top-left and the next target fades from the right after the check.
- Verify sound toggle and target/final haptics on hardware.

No phone result is inferred from desktop/headless validation.
