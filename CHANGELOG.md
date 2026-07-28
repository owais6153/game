# Changelog

## Unreleased

- Fixed the launcher lifecycle so a settled shot advances the queue and spawns exactly one next launcher instead of spawning repeatedly every frame.
- Added runtime controller-path regression coverage for first/second shots, idle-frame spawn prevention, queue advancement, active-launcher count, and restart.
- Implemented clean gameplay milestone 1: portrait board, horizontal launcher input, straight upward shots, top/side containment, settlement-gated queue, and minimal HUD.
- Added isolated current-step contact-only merge service for Pearl → Ruby → Emerald → Sapphire → Diamond.
- Added headless integration tests for valid contact merges, rejection cases, one-merge-per-cycle, and top-border settling.

## Baseline

- Initialized clean-room Godot rebuild governance and blank portrait baseline.
- Added Android ETC2/ASTC texture-import support through `[rendering/textures/vram_compression] import_etc2_astc=true` in `project.godot`.
- Exported and package-validated the standalone blank Android baseline APK.
