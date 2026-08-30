# Final HUD, Tiered VFX, Power Cinematic, and Audio Test Candidate

Date: 2026-08-30

## Scope and Claude reconciliation

Baseline `fadbeb1` already moved the power buttons off the playable board, added
bounded colored merge shards, and repaired repeating targeted-power guidance.
Claude then left an uncommitted audio pass that added five supplied cues but also
removed the prompt timer and cadence. This task retains the supplied audio work,
restores the interaction fix, and completes the requested HUD, VFX, power,
collision-audio, documentation, visual verification, and APK work as one pass.

## HUD correction

The root cause of the merge path overlapping the table was the limited-shots
height calculation: Shots (82) + Target (84) + progression (78) + two gaps (28)
is 272 design pixels, but the anchor was forbidden from entering the full 122px
top utility row. At 720x1280 the only possible result was to push the path down.

The centred stack now uses the unused horizontal space between Coins and Next,
with a safe-top floor and a 28-84px table gap. Powers remain 92px tiles in the
bottom band; gameplay buttons do not overlap the playable board. Visual proof:
`reports/powers-v1/screenshots/limited-shots-720x1280.png`.

The shared mission/ad-grant banner is temporarily drawn just inside the upper
table and remains input-transparent. This avoids covering the raised Shots and
Target panels; it never shifts table, HUD, or simulation geometry.

## Merge VFX hierarchy and mobile bound

Every confirmed merge keeps the established 420ms timeline and exact result
color. A continuous L1-L8 mapping now controls ring scale (0.92-1.34), spark
count (8-15 before target bonus), shard count/scale, ring weight, and a high-tier
white jewel core. Target merges add only a bounded bonus. Shards remain capped at
90 and all work uses immediate-mode drawing; no particle nodes, textures, or
simulation objects are created.

## Power presentation

The skippable cinematic is 1.08s (previously 0.92s). Bomb and Hammer have higher
brightness/debris multipliers than Magnet and Switch; each retains its own rays,
movement, color, shake, and impact identity. Board changes still apply only from
the cinematic impact signal, including when the player skips.

Visual proofs are the twelve `cinematic-<power>-<beat>.png` files under
`reports/powers-v1/screenshots/`. The capture completed with
`POWERS_V1_CAPTURE: PASS`; the Windows runner returned its known teardown access
violation only after the sentinel and all files were written.

## Audio and concurrency

Supplied Bomb, Hammer, Magnet, Switch, and Level Complete cues replace procedural
placeholders. The previous level-complete cue now identifies Daily Treasure
opening. Contact audio retains exact merge-pair suppression, then sorts remaining
confirmed impacts by strength and offers only the strongest three per frame.
The audio service independently admits at most three simultaneous contact voices
inside the existing five-player priority pool, so power/reward/result cues can
cut through a dense pile-up.

FFmpeg 9.0.1 measured the initial derivatives and exposed an overlong 3.5s Bomb
body, avoidable lead/tail silence, and a 500x500 cover-art video embedded in the
Hammer container. Final runtime cues are trimmed to Bomb 1.70s, Hammer 1.05s,
Magnet 0.56s, Switch 1.76s, and Level Complete 2.85s; destructive cues fade out
cleanly and all five files are audio-only stereo 48kHz Vorbis.

Originals remain under `assets/sound/`; runtime Ogg derivatives are under
`assets/runtime/audio/`. `assets/sound/.gdignore` prevents unsupported preserved
WAV codec variants from producing editor import failures. Source audio remains
Android-export excluded. Exact byte sizes and SHA-256 mappings are recorded in
`ASSET_INVENTORY.md`.

## Validation

- Godot editor import/class registration: PASS after source-audio ignore rule.
- `HUD_ALIGNMENT_V1_TESTS`: PASS, including forced limited-shots clearance.
- `MERGE_PHYSICS_V1_TESTS`: PASS, including tier mapping and shard bounds.
- `POWERS_GAMEPLAY_V1_TESTS`: PASS with writable isolated user data.
- `SOUND_PRIVACY_LINK_TESTS`: PASS, including supplied mappings and contact cap.
- Corrected-state full regression: 29/29 suites PASS (`FINAL2_REGRESSION passed=29 failed=0 total=29`).
- Post-FFmpeg re-import and `SOUND_PRIVACY_LINK_TESTS`: PASS.
- APK: `build/android/majestic-gems-final-vfx-hud-audio-test-v1.0.15-vc17.apk`, 114,502,601 bytes, SHA-256 `A5A64EF346E5869A61B95AE124E7F355002ED68E1BC5DF6F6AA48343E03B5444`.
- Package validation: `com.owais.majestygems`, versionCode 17/versionName 1.0.15, min SDK 24, target/compile SDK 36, both ARM ABIs, manifest/DEX present, APK Signature Scheme v2 PASS with one Godot debug signer.
- Payload audit: all five runtime cue imports are present; preserved `assets/sound`, reports, and tests are absent.
- Connected device: ADB reports V2149 `34385676890001M`. The APK was not installed or launched; phone visual/listening acceptance remains the tester's pass and is not inferred from desktop capture.

## Manual phone checklist

1. Drag/push the launcher repeatedly near the lower frame and confirm no power activates.
2. On a limited-shots level, confirm Shots, Target, and merge path all remain above the table.
3. Compare low-, mid-, and high-tier merges for exact gem color and increasing shine/weight without a frame hitch.
4. Trigger all four powers; confirm Bomb/Hammer read brighter and heavier while Magnet/Switch stay distinct.
5. Create a dense pile-up and confirm only a few strongest collisions sound, with merge/power/result cues still clear.
