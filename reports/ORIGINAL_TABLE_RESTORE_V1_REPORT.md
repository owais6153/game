# Original Table Restoration v1

Date: 2026-08-16

## Request

The user rejected the attempted multi-table scale calibration, asked work to stop, and chose to regenerate the replacement table rails. The requested temporary state is the original single table at its original position.

## Restored state

- Restored tracked runtime art `assets/runtime/table/new_table_v1.png` (920x810, 1,132,907 bytes, SHA-256 `1C32E185D32DC71A65C9CAC67C1351D1A5898D9B11B6599C3BA03BEC90F0236B`).
- Added `AssetCatalog.ORIGINAL_TABLE` and made `GameController` use it during initial setup and every level reconfiguration.
- Removed the rejected 1.15 horizontal artwork multiplier from the active render transform. The original base scale is again `0.7391304 x 0.9691358`.
- Restored the complete pre-random-table vertical model by 20 design pixels: outer `400..1185`, board `440..1110`, danger line `960`, launcher `1042`, and texture center Y `792.5`.
- Preserved the original rail X coordinates `188/532 -> 62/658` and all existing tall-screen responsive transformation behavior.

The 19 optimized backgrounds remain active. The ten replacement table WebPs remain preserved but gameplay-inactive for the user's upcoming rail regeneration. Current Coins/Next alignment, enlarged Next, Settings placement, text contrast, Target card, and merge path remain unchanged.

## Scope boundaries

No gem radius, collision response, contact/merge eligibility, velocity, damping, target/progression rule, reward, queue, audio/haptic, ad, result, or pointer behavior was retuned. The table model's requested 20-pixel restoration moves its artwork and all dependent coordinates together.

## Validation and Android status

The abandoned calibration's generated proof directory was removed. No final Godot visual/test acceptance is claimed after this restoration because the user explicitly stopped the calibration and will review the restored state while replacing the artwork. No APK or AAB was created or modified.
