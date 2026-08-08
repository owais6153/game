# Crystal Magic HUD + Branding Alignment v1

Date: 2026-08-09

## Requested changes

- Keep Coins/Next and Level/Settings at the top.
- Increase HUD readability slightly.
- Place Target above the merge path with about 15-20 px separation.
- Place the merge-path panel directly above the table.
- Keep placement responsive across portrait device sizes.
- Rename the game to Crystal Magic.
- Use the supplied Crystal Magic logo for branding, with a transparent runtime version; keep the icon artwork as supplied.

## Implementation

- `GameplayObjectiveStack` child order is now Target then Progression.
- `TARGET_PROGRESSION_GAP = 18.0`.
- `PROGRESSION_TABLE_GAP = 10.0`.
- Objective anchor bottom remains derived from `GameConfig.board_top()`, so taller portrait canvases follow the same table offset.
- Coins/Next cards, status row, Level/Settings, Target, progression gems, next gem, target gem and associated typography were enlarged roughly 10-15%.
- Progression panel minimum width is 548 design px so it reads as one intentional bar above the table.
- `project.godot` is named `Crystal Magic`.
- `AssetCatalog.BRAND_LOGO` points to the new transparent Crystal Magic runtime asset.
- Launcher icon and boot splash point to the as-supplied square artwork encoded as PNG.

## Preserved behavior

No changes were made to simulation, table geometry, physics, collision, merge eligibility, spawning, target rules, scoring, audio, haptics, or gameplay timing.

## Validation performed here

- Static project/script inspection.
- ZIP/file-path validation.
- PNG dimensions/alpha checks for branding assets.
- No Godot executable is available in this environment, so an editor run/export/device test is not claimed.
