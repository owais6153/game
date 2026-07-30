# Visible-Touch Table Alignment Fix v1

## Scope

Urgent regression repair only. No new level, target, UI, balance, save, progression, sound, haptic, or merge-rule feature was added.

## Root cause

`complete-perspective-view-variety-v1` multiplied each gem's visual container by a changing Y-based scale (`0.82` at the back through `1.10` at the front), plus a tier-growth multiplier. The simulation collider remained fixed. A visually shrunken gem therefore physically contacted another gem before their visible solid bodies met.

## Repair

- Disabled dynamic gem perspective and uncalibrated tier-growth scaling.
- Restored fixed visual-body rendering calibrated by `18-gem-size-collision-fix-v1`: `GEM_VISUAL_BODY_SCALE` and `GEM_COLLISION_RADIUS` remain fixed for each gem's entire lifetime.
- Kept the physics-mirroring root, visual container, sprite, and collider centered on the same `GemPiece.position`; both root and visual container retain a fixed scale.
- Kept the supplied bottom-anchored table artwork and the centralized `GameConfig` rail, launcher, spawn, drag-clamp, danger-line, and containment geometry unchanged.
- Kept stable Y/ID draw ordering only. It affects layer order, never gem position, scale, or collision.

## Validation

- Godot 4.6.3 headless import/parse: passed.
- `CLEAN_CONTACT_TESTS`: passed, including fixed-scale, centered visual-container, shared table-geometry, visible-contact, shadow-isolation, ordering, and win-sequencing checks.
- `GEM18_CHAIN_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed.
- `MOTION_PROFILE`: passed; no per-gem process callbacks or runtime gameplay texture loads after initialization.

## APK

This section is completed after the fresh Android export, ZIP validation, SHA-256 calculation, Git commit/tag, and push verification.
