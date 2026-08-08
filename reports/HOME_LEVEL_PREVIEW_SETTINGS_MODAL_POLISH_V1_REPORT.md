# Home / Level Preview / Settings / Pause Modal Polish V1

Date: 2026-08-09

## Scope

Presentation-only UI pass requested after reviewing screenshots of the Crystal Magic Home and Pause screens.

## Implemented

- Home Level and Coins moved into matching frosted-glass status cards.
- Added top-right Home Settings control using the existing supplied cog source region.
- Added settings-only Home modal for Music, Sound FX, and Vibration.
- Home settings signals are connected to the existing GameController handlers and persisted by GameSettingsService.
- Home PLAY/CONTINUE now opens Level Preview instead of immediately resuming gameplay.
- Level Preview reads `hud_snapshot()` and shows level, target sequence position, target gem, and quantity/name objective.
- START GAME emits the existing `play_requested` event; BACK returns to Home without unpausing.
- Pause settings controls changed from default CheckButtons to styled ON/OFF toggle Buttons.
- Pause layout normalized to a 424 design-pixel content width: settings rows align, Resume spans full width, Restart/Home split evenly.
- Added reusable `SettingsSwitch` and Home status glass styles.

## Files changed

- `scripts/home_overlay_layer.gd`
- `scripts/game_controller.gd`
- `scripts/gameplay_hud_layer.gd`
- `scripts/ui_design_system.gd`
- `GAME_SPEC.md`
- `CURRENT_STATE.md`
- `CHANGELOG.md`
- `ARCHITECTURE.md`
- `AI_KNOWLEDGE_BASE.md`
- `reports/README.md`
- this report

## Gameplay isolation

No board geometry, table rendering, launcher timing, gem physics, collisions, merge rules, scoring, target rules, audio asset content, or simulation coordinates were changed.

## Validation

- Static source review completed.
- Balanced bracket/parenthesis checks completed for edited GDScript files.
- Project ZIP integrity will be checked before delivery.
- Godot executable is not installed in the editing environment, so no parser/run/export claim is made.
