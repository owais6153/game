# Production Gameplay UI V2 — Initial Audit

## Source availability

- Requested recording: `WhatsApp Video 2026-08-05 at 6.45.10 AM.mp4`.
- Result: unavailable in the project root, the supplied attachment directory, and `/mnt/data` at task start.
- Visual fallback inspected: `WhatsApp Video 2026-08-05 at 4.39.25 AM.mp4`, the latest gameplay recording available in the repository.
- Additional source: the complete V2 acceptance criteria supplied with this task and the prior production UI/gameplay evidence under `reports/`.

Items below are classified as either **video-observed** in the latest available recording or **spec-observed** from the missing-recording acceptance brief. The final report must keep this distinction.

## Complete UI issue checklist

| Surface | Initial issue | Evidence class | Resolution target |
|---|---|---|---|
| Top HUD | Merge path, coins, Next, level, settings, and target read as separate floating widgets | Video-observed and spec-observed | One safe-area shell and shared container grid |
| Coin panel | Value area is cramped and vulnerable to large-value clipping | Spec-observed | Responsive icon/value row; full values through 9,999 and compact suffixes afterward |
| Next panel | Icon/padding hierarchy does not balance the coin card | Video-observed and spec-observed | Equal secondary-card footprint and aspect-preserving preview |
| Merge path | Eight gems are readable only with stronger size/spacing and a clearer heading relationship | Video-observed and spec-observed | Retain authoritative eight-tier path in a compact, enlarged strip |
| Target | Objective lacks a readable gem name and explicit quantity progress; it does not dominate secondary data | Video-observed and spec-observed | Central prominent card with target position, name, quantity, progress bar, and larger icon |
| Level badge | Badge feels detached from the progression system | Video-observed and spec-observed | Attach it to the merge-path header |
| Settings | Button feels isolated despite being functional | Video-observed and spec-observed | Place it in a matching utility frame in the progression header; preserve 88×88 touch target |
| Aim guide | Approved launcher direction is not visually legible enough | Spec-observed | Subtle themed dotted guide while ready; hide on launch; no input/physics authority |
| Danger line | Constant basic line provides no proximity distinction | Spec-observed | Calm default and proximity-only pulse using read-only piece positions |
| Pause | Content hierarchy, dimming, row framing, and action sizing need production polish | Video-observed and spec-observed | Larger centered modal, strong Resume, secondary Restart/Home, framed settings rows, stronger dimmer |
| Coin reward | Flight must terminate at the live coin glyph and update/pulse only on arrivals | Prior evidence and spec-observed | Retain approved timing; verify live destination, foreground z-order, cleanup, and exactly-once behavior |
| Target collection | Travel must remain above panels and make old/new objective state readable | Prior evidence and spec-observed | Retain approved timing; verify foreground travel, arrival pulse, and centered target crossfade |
| Crowded board | Tier-to-tier detached-shadow variance adds visual noise | Video-observed and spec-observed | Normalize presentation-only shadow opacity and footprint; leave artwork scale/colliders untouched |
| Typography | Labels, values, target state, and capitalization do not share one hierarchy | Spec-observed | Reuse centralized title/body/value sizes and consistent uppercase labels |
| Spacing | Per-widget gaps and padding create uneven alignment | Video-observed and spec-observed | Central small/normal/large gap, shell padding, panel padding, and icon tokens |
| Responsive layout | Must be proven on current device, requested portrait sizes, narrow-tall, and notch inset | Spec-observed | Container-driven scaling, safe margins, no table obstruction, automated geometry assertions |
| Button states | Settings and popup actions require visible pressed/focus/disabled treatments | Spec-observed | Reuse cached production theme states and test press feedback |
| UI performance | UI must not rebuild nodes/resources or leak tweens/signals during state churn | Spec-observed | Snapshot-diff updates, cached theme/font, stable node-count and signal assertions |

## Frozen gameplay boundary

The V2 work may read controller snapshots and authoritative geometry, but it must not modify target generation, quantities, launcher weights/pool, scoring, reward logic/timing, simulation, rails, table geometry, perspective, colliders, sound/haptic timing, or win/fail sequencing. Rendering additions stay in `_draw()` and HUD/presentation services only.
