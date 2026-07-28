# Game Spec — Clean Contact Merge v1

## Scope

This milestone implements only the smallest playable board loop. It has no score, win/fail, chains, sound, persistence, menus, ads, final art, or progression.

## Board and input

- Portrait board: left/right/top visible boundaries; empty table at launch.
- One current launcher gem begins below the visible-only danger line.
- Dragging changes only its horizontal position, clamped between side borders.
- Releasing sends it straight upward with negative Y velocity.
- Launcher lifecycle is `READY_TO_AIM → SHOT_IN_FLIGHT → RESOLVING → SPAWNING_NEXT → READY_TO_AIM`.
- Exactly one active launcher exists. The next queue advances and one new launcher appears only after the launched piece and all board resolution have settled; idle frames never advance the queue or spawn another piece.
- The danger line is never a collision or movement clamp.
- Unobstructed gems hit the top border, stay inside the board, and settle.

## Gems and merge rules

- L1 Pearl → L2 Ruby → L3 Emerald → L4 Sapphire → L5 Diamond.
- Only contact pairs captured in the current simulation step before separation enter merge resolution.
- Sources must be distinct, same-level, unconsumed, and within radius sum + 1.5 px.
- Sources are marked consumed before the upgraded gem appears at their midpoint.
- A source can merge only once per resolution cycle. Candidates are cleared afterwards.
- No chains or global/nearest same-level scans exist.
