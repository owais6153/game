# Asset-matched Home + transparent logo v1

Date: 2026-08-05

## Outcome

Home now uses the supplied UI language instead of the interim generic card: a full tropical backdrop, floating GEM RUSH logo, compact Level/Coins status, and large glossy coral Play/Continue control. No level tree was introduced.

## Asset work

- Original upload preserved: `assets/logo/ChatGPT Image Aug 5, 2026, 03_32_00 AM.png`.
- Tool: built-in image generation/editing.
- Prompt intent: preserve exact GEM RUSH wording, gold plaque, pearl/red/green/blue gems, leaves and sparkles; remove the dark gradient; isolate on a flat magenta key with no extra background objects.
- Preserved keyed source: `assets/generated/gem_rush_logo_chroma_source_v2.png`.
- Runtime alpha derivative: `assets/runtime/ui/gem_rush_logo_transparent_v2.png`.
- Alpha check: 1254 x 1254 RGBA; four corners alpha `0`; opaque logo body retained; narrow partial-alpha antialias matte only at keyed edges.

## Scope protection

No simulation, collider, merge, launcher, target, coin, sound, reward, seeded-level, persistence, or forward progression logic changed.

## Validation

- `git diff --check`: PASS.
- All seven regression suites: PASS (infinite levels, Level 1 flow, clean contact, gameplay UI/feel, 18-gem chain, production UI, and motion profile).
- Real 720 x 1600 Compatibility/ANGLE capture: PASS and visually reviewed. Home has no opaque logo rectangle, clipping, overlap, or gameplay HUD leakage.
- Standalone APK: `build/android/assets-ui-screen-match-v1.apk`, 118,277,818 bytes, SHA-256 `7AAB0C4A93F29DC6B40B44D511BDC3A2DB40AC04C4456E6342791F932319824F`.
- APK audit: export signed successfully; 411 ZIP entries; zero packaged `.gd`, `reports/`, `build/`, or `.git/` paths.
- Connected-device validation: ADB reported no connected device; physical-device review is not claimed.
- Connected-device validation: not performed unless a device is detected during final delivery checks.
