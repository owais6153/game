# Splash + Icons + Level Preview Polish v1 — 2026-08-09

## Requested fixes

1. Remove the unattractive animated gem loop from the pre-level START GAME popup.
2. Clean up the square/full-art Godot splash and the preceding Android native splash.
3. Use the newly added @icons library where generic interface icons are needed.

## Implementation

- `HomeOverlayLayer`: removed the LevelIntro target Tween Composer loop; target art is static. Added @icons-derived Play, Back, Done, Settings, and settings-row icons.
- `GameplayHudLayer`: Settings now uses the @icons cog. Pause actions use Play/Restart/Home glyphs and settings rows use Music/Sound/Vibration glyphs.
- `ResultOverlayLayer`: Next/Retry/Home actions now use matching @icons-derived glyphs.
- `project.godot`: editor @icons plugin enabled; fallback boot splash changed to transparent Crystal Magic logo.
- `export_presets.cfg`: Android system splash gets a dedicated padded 432×432 logo; extra Godot Android boot splash disabled; launcher main icon kept unchanged.
- `assets/runtime/ui/icons/`: curated runtime-safe palette derivatives added.

## Safety boundary

No gameplay simulation, table geometry, colliders, merge rules, target rules, scoring, saved progression, audio authority, or fast-feel timing constants were changed.

## Validation available in this environment

- Checked referenced runtime icon/splash paths exist.
- Checked removed LevelIntro motion identifiers no longer remain in source.
- Checked ZIP/file structure and Android export settings text.
- Godot 4.6.x is not installed in this execution environment, so an actual editor parse/export/device launch is not claimed. Physical Android verification is still required for the native splash behavior because OEM launchers can apply their own splash/icon masking.
