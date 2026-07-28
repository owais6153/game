# AI Knowledge Base

## Non-negotiable rebuild rules

- This is clean-room code; do not copy code from the deleted project.
- Gameplay source of truth is `GAME_SPEC.md`.
- The build must be standalone: no development server is required to open the APK.
- Preserve Git traceability and document each task as required by `AGENTS.md`.
- Do not add mechanics outside the current scoped task.

## Merge invariant

The only allowed merge input is a current-step physical contact captured by `BoardSimulation` before separation. `ContactMergeService` must not scan all gems, search nearest neighbors, reuse candidates from previous frames, or require pieces to be settled. Chain merging is not present in v1.

## Launcher invariant

There is exactly one active launcher while the game is ready for input. Launcher creation is lifecycle-gated, not merely “board settled”-gated: a shot must enter `SHOT_IN_FLIGHT`, finish resolution, enter `SPAWNING_NEXT`, create one launcher, and then return to `READY_TO_AIM`. Do not reintroduce frame-by-frame spawning conditions based only on a missing active ID or settled board.
