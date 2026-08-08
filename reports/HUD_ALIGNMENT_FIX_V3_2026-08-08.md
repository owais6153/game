# HUD Alignment Fix v3 - 2026-08-08

## Reported issue
Runtime screenshot showed the complete HUD cluster compressed toward the upper-left: Next sat beside Coins instead of at the right edge, Settings followed the same collapse, and the progression/Target stack centered inside a narrow minimum-width parent rather than over the table.

## Root cause
The dynamically-created `MarginContainer` roots relied on anchor presets before the first effective layout pass. In the affected runtime layout their usable width resolved to child minimum width, so HBox spacers and CenterContainers did not have the 720px logical design width to distribute against.

## Fix
- `SafeHudMargin` now uses explicit 0..720 design-canvas geometry.
- `GameplayObjectiveAnchor` now uses explicit 0..720 design-canvas geometry.
- `_refresh_safe_margins()` reasserts those widths and then applies left/right safe padding internally.
- Responsive scale, safe insets, table-top based objective Y positioning, StyleBoxFancy glass styling, and gameplay behavior remain unchanged.

## Expected placement
- Coins: top-left.
- Next: top-right.
- Level: directly below Coins.
- Settings: directly below Next.
- Merge progression: centered above Target.
- Target: centered above the existing table.
