# Retention, Coin Economy, and Daily Missions Sprint V1

## Scope

Adds only limited-shot level data, Extra Shots, one safe Continue, daily missions/chest, targeted HUD/popup feedback, and analytics. Strict physical-contact merging, launcher generation, rails, target sequencing, and reward authority are unchanged.

## Economy

Central values: Switch Gem 100, Extra Shots +5 for 300, Continue 500 (maximum one per attempt), Skip Level 800. Existing target rewards of 10/25/60/150/350/800/1800 remain the earning model. Daily rewards are 45/90/140 plus a 180 chest. The hierarchy makes rerolls tactical, rescues meaningful, and Skip the high-cost escape.

## Save and daily logic

`retention.daily_state` is optional and defaults safely for closed-test saves. It stores local date, generated missions, progress, per-mission claims, and chest claim. Reset is evaluated at app startup; local device-clock manipulation remains a documented V1 limitation.

## Validation status

- Godot 4.6.3 editor import/class scan: passed; all new classes registered.
- Firebase runner: not executed successfully. The sandbox denied `user://logs` creation and Godot crashed before assertions. This is not a test pass.
- Android build/device/Firebase DebugView: not run in this implementation pass.
