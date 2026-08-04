# New Background Music v1 Report

## Outcome

The newly supplied track is the game's continuous background music. It starts through the existing dedicated music player, loops independently of movement and contact, and is mixed softly enough for target coins and gem/merge feedback to dominate. No gameplay, animation, physics, reward, target, launcher, danger, or progression behavior changed.

## Source and runtime mapping

- Preserved source: `assets/sound/sonican-uplifting-loop-cheerful-happiness-297034.mp3`
- Source audit: 2,817,044 bytes; 88.032625 s; MP3 256 kb/s; stereo 44.1 kHz; SHA-256 `62778A13E946CF221388AB1AE935386C9144256E88C385CA1153210A4478CE43`; mean/max `-12.4/-0.5 dBFS`.
- Active derivative: `assets/runtime/audio/supplied_background_music_v5.ogg`
- Runtime audit: 1,767,914 bytes; 88.032653 s; Vorbis stereo 44.1 kHz quality 5; SHA-256 `1D2124D6B5C15CE09F8823A57BD2DBB2DEEA01CDDDCA33B297379F1ED1A64E3F`; mean/max `-12.4/0.0 dBFS`.
- Conversion preserved the complete track and stripped metadata; it did not apply gain, EQ, pitch, or trimming.
- The filename is recorded as user-supplied provenance only. This report does not infer licensing or ownership.

## Mix and routing

- Music gain: `0.14 -> 0.10` linear. Documented safe tuning range: `0.08-0.12`.
- Estimated playback mean/max: approximately `-32.4/-20.0 dBFS` before device and bus effects.
- Music uses one continuous dedicated player. Movement cannot start, seek, or restart it.
- `supplied_coin_reward_v4.ogg` stays separate and fires only for confirmed L5/L7/L8 target qualification.
- Existing tiered gem/contact/merge cues remain unchanged.
- The v4 music derivative stays preserved but inactive.

## Automated validation

All required suites passed: clean contact/audio routing, gameplay UI and feel, 18-gem chain/catalog, Level 1 flow, production UI finalization, and motion profile. Routing tests assert the exact v5 resource, reject the inactive v4 and contaminated reference loop, assert `0.10` gain, and preserve target-only coin audio. The motion profile retained zero per-gem callbacks, zero runtime resource loads, bounded effects, and stable node counts.

## Manual listening checklist

Not claimed without a connected device. On-device review should confirm:

1. Music begins once at startup and continues without movement-driven restart or seek.
2. Gem/merge feedback and the target coin cue dominate the soft background bed.
3. The approximately 88-second loop seam has no obvious click, gap, or level jump.
4. Sound toggle stops and resumes the expected mix cleanly.
5. Balance remains acceptable on phone speaker and headphones.

## Provenance

- Baseline commit: `5efe68fd741265a1332c97c60a6875430925e07a`
- Baseline tag: `new-background-music-v1-baseline`
- Source commit/tag: `25f83f74b23a1fa19bc121a950b834f7d8bcdc4c` / `new-background-music-v1-source`
- Export-source commit/tag: `EXPORT_SOURCE_COMMIT` / `new-background-music-v1-export-source`
- Delivery tag: `new-background-music-v1`
- APK: `build/android/new-background-music-v1.apk`; 109,063,713 bytes; SHA-256 `615AAA1A67040EDCE68BAA45FF01740A3C85E0EFFDFFF3D486935E3064CD3BF8`
- APK validation: 391 ZIP entries with forbidden project/build sources absent; v2/v3 signature verification passed with one RSA-2048 signer.
- Device status: ADB returned an empty list, so installation, launch, phone listening, and haptics are not claimed.
