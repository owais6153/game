# Button Icon Compatibility Hotfix

Godot 4.6.3 reports `Invalid assignment of property or key icon_max_width` on `Button`.

## Fix
- Removed every `Button.icon_max_width` assignment from runtime scripts.
- Disabled `expand_icon` for those action buttons.
- Resized the corresponding SVG assets to the intended intrinsic display sizes so icons remain compact.

## Files
- `scripts/home_overlay_layer.gd`
- `scripts/gameplay_hud_layer.gd`
- `scripts/result_overlay_layer.gd`
- `assets/runtime/ui/icons/*.svg` (affected action icons only)
- `CHANGELOG.md`
- `CURRENT_STATE.md`

No gameplay rules, physics, progression, table geometry, or scoring logic changed.
