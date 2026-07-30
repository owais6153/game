# 18-Gem Motion Smoothness Fix v1

## Scope

Motion-regression fix only. No table, HUD, target, scoring, launcher, win/fail, sound, haptics, or gameplay-design behavior was changed.

## Comparison

- Smooth baseline: `new-table-shadow-contact-fix-v1` / `0b562d5b85b0b4d0330ecd10da3f832408949ad9`.
- 18-gem catalog commit before this fix: `13d9f24bf88e86ff0b887251e3964c29bd23eec4` / `18-gem-chain-v1`.

## Root cause

`AssetCatalog.gem_texture()` called `load()` on each live gem during every `GemSpriteLayer.sync_gems()` call. Because the controller syncs all gems each rendered frame, a crowded board repeatedly ran dynamic resource lookup in the motion path. The 18 runtime PNGs were also 486–866 px on their longest edge, increasing texture upload/memory pressure beyond what their on-screen 64–84 px use warrants.

## Fix

- Replaced the per-frame dynamic lookup with 18 explicit `preload()` resources held in a cached tier dictionary.
- Changed the sprite layer so texture/scale/shadow appearance is assigned only when a piece is created or changes tier. Per-frame work now updates only positions and visibility.
- Regenerated non-destructive `assets/runtime/gems18/` derivatives at a maximum 256 px long edge. The untouched originals remain in `assets/gems/`.
- Restored baseline collider values exactly for Pearl–Diamond: `42, 42, 32, 42, 33`. Tiers 6–18 use the baseline default `42` px body until a later explicit balance task.
- Preserved all baseline movement constants: launch 1160 px/s, damping 235 px/s², collision restitution 0.34, tangential friction 0.18, fixed delta simulation, settling thresholds, merge timing, and visual-only merge presentation.

## Development-only profile

Headless controller profile after the fix (CPU process time):

| Scenario | Average | Worst | Bodies |
|---|---:|---:|---:|
| Empty-board launch | 0.034 ms | 0.080 ms | 1 |
| Repeated launch | 0.031 ms | 1.212 ms | 2 |
| 10 active gems | 0.245 ms | 0.916 ms | 10 |
| 20 active gems | 0.837 ms | 2.194 ms | 20 |
| Crowded merge path | 0.591 ms | 3.683 ms | 20 |
| Restart | 0.030 ms | 0.134 ms | 1 |

The development profile confirms zero gameplay resource loads after initialization and zero per-gem process callbacks. It is CPU instrumentation, not a phone GPU benchmark.

## Validation

- Godot 4.6.3 asset import/parse validation: passed.
- `CLEAN_CONTACT_TESTS: PASS`.
- `GEM18_CHAIN_TESTS: PASS`, including cached-texture, mobile-size, baseline-physics, fixed-radius, no-perspective, and L1–L18 merge guards.
- `MOTION_PROFILE: PASS` across launch, repeated launch, 10/20-gem crowded boards, merge path, high tiers, and restart.
- No Android device was connected; device testing is not claimed.

## Delivery

- Requested APK: `build/android/18-gem-motion-smoothness-fix-v1.apk`.
- Source commit: the commit tagged `18-gem-motion-smoothness-fix-v1`.
- Export status: blocked by Godot 4.6.3's existing Android CLI filename validation bug. It rejected both the valid explicit `.apk` output path and the matching preset path with `Invalid filename! Android APK requires the *.apk extension.` No old APK was copied or relabelled, so no requested APK, size, or timestamp is claimed.
