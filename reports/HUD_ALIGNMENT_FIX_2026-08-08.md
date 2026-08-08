# HUD Alignment Fix - 2026-08-08

Device screenshot showed the header and objective stack collapsing toward the left because several dynamically-created container nodes were using minimum width instead of the available design width.

Changes:
- Added horizontal `SIZE_EXPAND_FILL` to TopHudColumn.
- Added horizontal `SIZE_EXPAND_FILL` to UtilityRow and StatusRow.
- Added horizontal `SIZE_EXPAND_FILL` to GameplayObjectiveStack.
- Added horizontal `SIZE_EXPAND_FILL` to ProgressionCenter and TargetSlot.
- TargetSlot keeps only the target panel height as minimum size; width is supplied by the full-width parent.
- Increased target/table gap from 16 to 28 design pixels so the StyleBoxFancy shadow does not visually touch the table.

Expected layout:
- Coins: upper left.
- Next: upper right.
- Level: below Coins.
- Settings: below Next.
- Merge progression: horizontally centered above Target.
- Target: horizontally centered immediately above the table, with clean visual clearance.

No gameplay logic or table geometry changed.
