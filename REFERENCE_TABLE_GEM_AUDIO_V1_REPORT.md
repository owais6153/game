# Reference Table Composition + Gem Audio v1

## Baseline and evidence

- Starting source: `d2ecb8fc5e61e19d68ab386e9826e0d72e0bd60a`, the documentation-only follow-up to `sound-haptics-v1`; the tree was clean before implementation.
- Local comparison inputs inspected from the project root and kept ignored by Git: target `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4` (1280x576, 23.99 fps) and current `WhatsApp Video 2026-07-29 at 6.53.59 AM.mp4` (720x1624, 23.99 fps).
- Composition finding: the target places a distinct tabletop inside a larger decorative environment. The preceding portrait build let the felt board occupy nearly all available height. Audio finding: contacts read as short, bright glass/crystal tinks; merges read as compact layered crystal chimes, not beeps, thuds, clicks, or generic arcade tones.

## Implemented table/background composition

- Authoritative physical/visual bounds are now `x=58..662`, `y=224..1080` on the 720x1280 canvas. This leaves 58 px on both sides, 62 px below the HUD, and 200 px below the table for visible scenery and the launcher zone.
- The full-screen backdrop is a lightweight procedural crystal alcove: navy depth bands, small facet ornaments, a gold divider, table shadow, warm outer frame, gold rails, and green felt. It copies no artwork and uses no shader, blur, bloom, external assets, or particle field.
- Collision borders, launch position, danger line, table rendering, HUD, queue, overlays, and progression remain synchronized through `GameConfig`; this is not a visual-only resize.

## Original crystal audio identity

The old single sine-wave/sweep generator was removed. The new project-safe runtime synth uses inharmonic 1.0/2.73/4.18 partials, a very short deterministic high-frequency sparkle transient, quick attack, and exponential decay. No copyrighted or external samples are used or stored.

| Event | Design | Gate |
| --- | --- | --- |
| Gem contact | Bright short glass tink/clink | 220 px/s threshold, 75 ms cooldown |
| Wall contact | Softer, duller crystal tap | 290 px/s threshold, 110 ms cooldown |
| Launch | Restrained airy glass flick | Confirmed launch only |
| Merge L2–L5 | Impact plus increasingly bright 740/880/1046/1318 Hz shimmer | Confirmed merges only |
| Chain | Tasteful ascending crystal accent | Confirmed chain depth only |
| Win/fail | Concise polished flourish / restrained descending resonance | One-time result state only |

All cues are 22,050 Hz procedural output, limited to three concurrent voices, conservatively pre-gained (0.10–0.34), and clamped to avoid clipping. The existing sound switch suppresses all audio without affecting gameplay. Haptics remain light at launch, absent for ordinary contacts, medium for direct merge, stronger for chains, and distinct for win/fail.

## Regression and manual review

- Tests cover 720x1280, 1080x1920, 1080x2400, 1440x3200, and 900x1280 bounds; table reveal, launcher/danger placement, HUD/overlay safety, queue behavior, strict merges/chains, and distinct throttled gem/wall events.
- Desktop review sequence: launch, gem contact, wall contact, direct merge, chain, Diamond/win, fail, then rapid collisions. Phone review should confirm crystal character/loudness and no sound or vibration spam.

## Delivery

Validation, export provenance, commit, and tag are completed only after the Godot checks and APK export succeed.
