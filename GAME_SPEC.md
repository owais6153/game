# Game Spec — Clean Rebuild Scope

## Current scope

1. Prove a standalone blank Android baseline.
2. Then build a minimal contact-only merge slice with simple circles/colors.

## Planned contact-merge mechanics

- Portrait board with left, right, and top boundaries.
- Empty table at start; one active launcher below a visual-only danger line.
- Horizontal drag only; release launches straight upward with negative Y velocity.
- Unobstructed shots reach the top border and settle inside the board.
- Exactly one active launcher exists. The next one appears only after resolution settles.
- Levels: L1 Pearl, L2 Ruby, L3 Emerald, L4 Sapphire, L5 Diamond.
- Only physical contacts captured in the current simulation step may merge.
- Same-level pairs merge one level up; different/distant pairs do not.
- No chain merges in the first slice.

No score, win/fail, sounds, persistence, ads, menus, final art, analytics, or backend are in the first gameplay slice.
