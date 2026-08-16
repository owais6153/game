# Immediate Merge Sound Synchronization v3

Date: 2026-08-16

## Request and diagnosis

The user reported that the selected merge sound was audible only after merging and after the result gem appeared. Static controller inspection showed that merge audio was already requested within `_apply_confirmed_merge_events()` during the confirmed merge frame. FFmpeg silence analysis then measured the actual cause in the selected `merge-target.mp3` file:

- source duration: `2.088 s`
- leading silence below `-45 dB`: `0.523125 s`
- source size/hash: 41,760 bytes / `B68136FA50DD04F5D82BFD8EE05F4E5EB0CE25BA4AC8406AD5639DBCD7711250`

Per the approved v2 mapping, this supplied filename is the ordinary-merge cue. Target-producing merges retain their original procedural tier cue.

## Correction

- Preserved `assets/sound/merge-target.mp3` byte-for-byte.
- Generated `assets/runtime/audio/merge-target-immediate.ogg` using FFmpeg `atrim=start=0.515,asetpts=PTS-STARTPTS` and Vorbis q5 at the source stereo 24 kHz format.
- Runtime derivative: 14,316 bytes; SHA-256 `05E9EE864FAACBCC73BB7ECF0FE6DC7A2663EB7A82AA1F20B0E7A3A5C541D085`; duration `1.573 s`.
- Measured remaining leading silence: `0.008042 s`, a reduction of about `0.515083 s`.
- Moved the existing merge-audio request to immediately after confirmed result classification, before texture caching, result presentation transforms, and effects setup. It remains in the same merge-confirmation frame and downstream of authoritative merge resolution.

No timer, early prediction, physics event, animation retiming, or gameplay callback was introduced. Mapping and gain remain `normal_merge -> merge-target` at `0.70`.

## Frozen behavior

Physics, contacts, collision shapes, merge eligibility and results, target matching/counting, chain rules, result IDs, scoring/coins, launcher lifecycle, animation duration, music, other SFX identities/gains, haptics, UI/privacy, ads/UMP, Android identity, and signing configuration are unchanged.

## Validation and delivery

- FFmpeg `silencedetect=-45 dB`: source lead-in `0.523125 s`; derivative lead-in `0.008042 s`; PASS.
- Godot 4.6.3 editor import/parse: PASS, exit 0; the new Ogg imported successfully. Known root-certificate/editor-settings warnings remain unrelated.
- `SOUND_PRIVACY_LINK_TESTS: PASS`: trimmed resource path/duration, immediate pre-presentation routing order, mappings/gains, voice pool, buses/limiter, cooldown/pitch protection, and no objective/lose route.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`: merge, target, result, reward, and reset flow unchanged.

Both script runners printed their PASS sentinel before the environment's known Windows teardown/root-certificate exit 1. TEST APK export/audit and device-status check remain pending. No AAB will be generated.
