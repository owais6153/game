# Result Modal Unification + Home Play Label

## Scope
Presentation-only update requested after Crystal Magic v8.2.

## Changes
- `HomeOverlayLayer.present()` now always labels the main home action `PLAY`.
- `ResultOverlayLayer` now uses `UiDesignSystem.gameplay_modal_panel_style()` instead of the legacy `hero_screen_panel_style()`.
- Result panel minimum is 520×690 with the same 48px horizontal content margins and 14px vertical rhythm used by Pause.
- Result score uses the shared light glass status-card style.
- Primary result action is 424×82; Home is a 424×72 secondary action.
- Result buttons now use the same Global Tweens press feedback as the rest of the production UI.
- Failure badge moved from coral/cream styling to the shared blue glass badge language.
- User-facing failure transition copy is `READY TO RETRY`.

## Preserved
No simulation, physics, table, launcher, merge, target, scoring, coin authority, progression, persistence, audio, haptics, or result-qualification behavior was changed.

## Validation
- Static source audit confirms no `CONTINUE` assignment remains in `home_overlay_layer.gd`.
- Static source audit confirms Result uses `gameplay_modal_panel_style()` and shared button dimensions.
- Godot runtime/export validation was not run in this container because the Godot executable is unavailable.
