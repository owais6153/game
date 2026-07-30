# Gameplay HUD + Sequential Targets v1 Report

## Scope

This milestone changes only the HUD, catalog identity resolution, unlimited launches, and Level 1 sequential target flow. Table placement, rail geometry, perspective scaling, collider behavior, motion constants, and contact merging are unchanged.

## Authoritative gem mapping

`AssetCatalog.gem_entry(tier)` now owns each tier's stable ID, display name, runtime/HUD texture, texture path, collision-radius reference, and visual-scale reference. Launcher, current/next previews, and target card all use this same mapping.

## Level 1 flow

- Unlimited launches; danger-line overflow remains the only fail condition.
- Targets are sequential and visible one at a time: Jade (L3) x1, then Aquamarine (L4) x1.
- Only confirmed merge results for the active target can progress the target.

## Target collection timeline

`merge_confirmed -> result_created -> result_visible -> merge_presentation_completed -> target_collection_started -> target_collection_completed -> next_target_activated OR win_overlay_started`

The actual merged result is consumed from physics only after its merge presentation, then a dedicated visual scales, moves to the HUD target card, and fades away. The final win overlay appears only after that animation completes.

## Validation

- Godot headless parse/import: passed.
- `run_clean_contact_tests.gd`: passed; obsolete single-target HUD assertions were removed while collision, contact, rail, containment, perspective, and calibration coverage remains.
- `run_level_1_flow_tests.gd`: passed; covers all 18 mappings, unlimited queue flow, sequential advancement, final-win ordering, and reset safety.
- Fresh signed Android debug export: passed. APK contains `AndroidManifest.xml` and `classes.dex`.
- No device was connected, so this build is not device-tested.

## APK

- `build/android/gameplay-hud-sequential-targets-v1.apk`
- 100,750,262 bytes; 2026-07-30 14:11:00 +05:00
- SHA-256: `EDC72A77D57289443AC2B45935B4A39DB453C7B2E2A167669FAAA59B7F948D46`
