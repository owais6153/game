# Reference HUD + Unlimited Launches v1

- Removed gameplay-HUD Restart, sound, vibration, and sequential-target counters so the visible top composition matches the supplied reference: SCORE left, gem ladder center, NEXT right.
- The `TARGET 1/2` label was objective progress, not a shot cap; it is now absent from the gameplay HUD to avoid that misleading interpretation.
- No production shot-limit state exists. Launcher spawning remains unlimited until the existing danger-line fail or final objective completion.
- Added `stretch/aspect="expand"` so tall Android screens no longer letterbox the fixed portrait canvas with black bars.
- Table, rail geometry, collision, depth scaling, merge, and motion behavior were not changed.

Validation: Godot parse/import, clean-contact, and Level 1 flow checks passed. No device was connected.

APK: `build/android/reference-hud-unlimited-v1.apk` — 100,750,262 bytes; SHA-256 `E4FB51BCD659CC43EF278B26A4C7A2922D945AA15699C32BD9FE82A4FDE35240`.
