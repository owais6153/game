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

- File: `build/android/visible-touch-table-alignment-fix-v1.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 11:02:43 +05:00`
- SHA-256: `63238FE064B48BC57ECBBCD1EE522C17347C86CE5B96F57A71B764F00B5AE5DC`
- Source commit: `3316d2dcdebde9528885c882b2de385c26862c66` (`fix: restore visible-touch collision and table alignment`)
- Tag: `visible-touch-table-alignment-fix-v1`
- ZIP validation: passed; `AndroidManifest.xml`, `classes.dex`, and arm64-v8a entries are present.
- Device status: no Android device was connected; installation and launch are not claimed.
