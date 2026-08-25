# HUD and Popup Simplification V1

Date: 2026-08-25

## Scope

Full presentation cleanup for gameplay HUD, Home settings, Pause, Result, and shared panel styles. Gameplay, table geometry, gem physics, level generation, Android configuration, and reward authority are unchanged.

## Changes

- Removed the redundant `COINS` caption from Home and gameplay HUD; both now communicate currency with the coin artwork and numeric amount.
- Rebuilt Target as one compact 340x84 surface. It now contains the target gem, `TARGET n/n`, and numeric quantity only. The nested target surface/badge structure and horizontal progress bar are removed.
- Removed the gameplay settings frame/center nesting. The cog is now one 64px Button with a restrained dark-amethyst frame. Home settings no longer use a separate glass frame.
- Removed the white highlight border from the shared frosted panel primitive. All menus, popups, cards, switches, and buttons retain their violet border but no longer stack bright white glass effects.
- Reduced Home Settings to 500x470 by removing its redundant subtitle. Reduced Pause from 700px to 560px by removing its decorative gem and duplicate `SETTINGS` caption. Reduced Result from 690px to 620px and tightened its decorative/subtitle rows.
- Retained current anchors, safe-area behavior, modal actions, button order, target authority, coin/reward data, and shadow-free style rule.

## Validation

- `UI_SCALE_LAYOUT_TESTS: PASS` across normal/tall phone and notch cases. Includes checks that Target has no progress bar, Coins has no redundant heading, and the settings cog is one 64px button.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`.
- `REFERENCE_GAME_FEEL_V2_TESTS: PASS`.
- `SOUND_PRIVACY_LINK_TESTS: PASS`.

No Android build or device test was run for this source/UI milestone.
