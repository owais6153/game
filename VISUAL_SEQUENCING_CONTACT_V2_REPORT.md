# Visual Sequencing + Contact v2 Report

## Baseline and evidence

- Baseline: `8fdebd4` / `visual-physics-calibration-v1`; clean before edits.
- Reviewed: `WhatsApp Video 2026-07-29 at 11.52.51 AM.mp4` and `WhatsApp Image 2026-07-29 at 11.52.29 AM.jpeg` in the project root. The screenshot shows the result card dimming the entire playfield and presenting while the expected Diamond is not visible.
- The local media tooling could not decode or extract video frames because FFmpeg is not installed. Findings that depend on the recording are therefore limited to its supplied evidence and the screenshot; no audio/frame extraction is claimed.

## Corrections

1. **Win sequence:** `diamond_created -> win_qualified -> merge_visual_complete -> win_overlay_presented`. Qualification blocks launch/spawn at once. The spawned Diamond is synchronized, the existing source pull/pulse completes, then a configurable 0.32 s hold presents the overlay and win flourish.
2. **Overlay isolation:** `ResultOverlayLayer` is placed in a `CanvasLayer`; it draws its own configurable backdrop. `GemSpriteLayer` reasserts source texture and `Color.WHITE` modulation at every sync. The gameplay root is never dimmed.
3. **Perspective:** `shallow_table.gdshader` widens only the upper supplied-table rows. The original art remains unchanged; authoritative upper rails changed from `90..630` to `58..662`, matching the shallower presentation and all physics, spawn, clamps, and danger bounds.
4. **Visible contact:** stable collider radii are retained for deterministic merging. Main gem bodies receive only render-time expansion (L1 1.08, L2 1.08, L3 1.05, L4 1.08, L5 1.10); contact epsilon is reduced `0.75 -> 0.20` design px and separation epsilon `0.10 -> 0.02` design px. Decorative glow/shadow/padding are excluded.
5. **Sound:** contact audio still originates exclusively in `BoardSimulation` after narrow-phase contact; merge audio remains confirmed-merge-only. Win audio now occurs after the Diamond visual presentation, not at logical qualification.

## Automated validation

- Godot 4.6.3 headless suite: `CLEAN_CONTACT_TESTS: PASS`.
- Added runtime assertions that a Diamond texture exists unchanged before the win UI, that win qualification blocks spawning, and that the overlay waits for presentation completion.

## Manual phone checklist

- Ruby/Ruby or Sapphire/Sapphire into the next gem; then final Diamond creation: confirm pulse/hold precede popup.
- Compare every gem before/after popup: texture and brightness must be identical.
- Slow Pearl/Pearl, Ruby/Ruby, and Pearl/Ruby contact; only touching same levels merge.
- Emerald/round-gem contact and Diamond side/top rail contact should not show an invisible gap.
- Check table rails at 16:9, 19.5:9, and taller portrait screens.

## Delivery

- Android export is currently blocked before compilation by Godot's filename validator despite valid `.apk` output paths. No old APK was relabeled or substituted. See `BUILD_MANIFEST.md`; a fresh package must be exported after correcting this project export configuration issue.
