# HUD Panel Flattening V1

Date: 2026-08-25

## Scope

Follow-up audit of redundant UI surfaces after HUD and Popup Simplification V1.

## Changes

- Removed the nested `PanelContainer` header from Next. `NEXT` is now a direct label within the existing Next card.
- Removed non-interactive framed row panels from Home Settings and Pause Settings. Music and Sound retain their icons, labels, controls, action wiring, and touch targets without each row looking like another card.
- Removed the nested Result reward-card surface and margin wrapper. Earned and total currency data remain grouped by layout only inside the primary Result modal.

The only remaining panel surfaces are intentional top-level cards/modals or semantically distinct status elements; no gameplay, reward, target, input, privacy, or Android behavior changed.

## Validation

- `UI_SCALE_LAYOUT_TESTS: PASS` — including direct-label Next, compact Target, direct settings control, and screen-safe layout cases.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`.
- `SOUND_PRIVACY_LINK_TESTS: PASS`.

No Android export or physical-device test was run for this source-only UI pass.
