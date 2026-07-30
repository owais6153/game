# Supplied HUD Art + L7/L8 Balance v1

## Scope

Uses the approved `assets/buttons/Generated image 10.png` sheet directly for the gameplay SCORE and NEXT panels. No table, rail, perspective, collider, motion, contact-merge, sound, haptic, pause, restart, or danger-line behavior changed.

## Level 1

- Exactly two sequential targets: L7 x1, then L8 x1.
- Launches remain unlimited; danger-line overflow remains the failure condition.
- The launcher now uses a controlled mixed low-tier cycle: L1, L2, L1, L3, L2, L1, L4, L2, L3, L1. This avoids the former repeated same-line L1/L1 auto-solve pattern without introducing direct L7/L8 spawns.

## Validation

- Godot parse/import: passed.
- `CLEAN_CONTACT_TESTS`: passed.
- `GEM18_CHAIN_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed.
- `MOTION_PROFILE`: passed; no per-frame texture loading.
- No Android device was connected; device testing is not claimed.
