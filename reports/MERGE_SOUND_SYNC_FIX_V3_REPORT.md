# Immediate Merge Sound Synchronization v3

Date: 2026-08-16

## VersionCode correction - 2026-08-17

The first release AAB below used versionCode 2, which Google Play had already consumed; it is superseded and must not be uploaded. The Android preset now persists versionCode 3. The corrected `build/android/majestic-gems-merge-sound-sync-v3-vc3.aab` embeds versionCode 3 and passes the release audit. A new repository guardrail requires every future release build to save a code greater than all previously recorded Play releases before export.

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

Both script runners printed their PASS sentinel before the environment's known Windows teardown/root-certificate exit 1.

## TEST APK delivery

- APK: `build/android/majestic-gems-merge-sound-sync-v3-test.apk`
- Size: 81,319,143 bytes (77.55 MiB)
- SHA-256: `58648E9C5FF783AB1D79020E2368CB6FECA56E7A3AEC232BB683303EE2A9695F`
- Source: `3f2fa01` / `merge-sound-sync-v3-source`
- Package: `com.owais.majestygems`, versionCode 2, versionName 1.0.1, min SDK 24, target/compile SDK 36
- Validation: v2 signature PASS with one RSA-2048 Godot debug signer; AAPT/ZIP PASS; `arm64-v8a` and `armeabi-v7a`; 992 entries; one manifest and primary dex; trimmed Ogg import present; zero report/test/source-audio leakage.
- Export note: the log reached `[DONE] export`, the APK remained stable for 30 seconds, and the exact silent wrapper processes were stopped after timeout. The production AAB preset was restored exactly and no AAB was generated.
- Device status: the bounded ADB probe timed out and its exact helper was stopped. Installation, launch, and subjective device listening are not claimed.

## RELEASE AAB delivery - 2026-08-17

- AAB: `build/android/majestic-gems-merge-sound-sync-v3.aab`
- Size: 69,163,559 bytes (65.96 MiB)
- SHA-256: `D08D5169C19AAA8E8F63FD9BFB3B6345CEE0C64B7C9C550D359B5BECC1346D30`
- Build source: `86f0c90` / `merge-sound-sync-v3-test-apk`; implementation source: `3f2fa01` / `merge-sound-sync-v3-source`
- Package: `com.owais.majestygems`, versionCode 2, versionName 1.0.1, min SDK 24, target/compile SDK 36; release manifest is not debuggable.
- Signing: JAR verification PASS using the existing Muhammad Owais Khan / Teckvertex Labs RSA-2048 upload certificate, SHA-256 `E3BA3287A50AF4AC49C07CBCB2E4F10940AD519642CB24F21BCF856B3F3BCE14`.
- Validation: Bundletool 1.18.3 PASS; 1,003 entries; three DEX files; both ARM ABI library pairs; production AdMob App ID present; immediate merge Ogg import present; zero report/test/source-audio leakage. `SOUND_PRIVACY_LINK_TESTS` and `ADMOB_INTEGRATION_TESTS` reached PASS before their documented Windows teardown messages.
- Export note: the new output filename did not alter the production preset or overwrite the previous v2 AAB. The log reached `[DONE] export`; after file stability was confirmed, the exact silent wrapper processes were stopped.
- Device status: AAB files are not directly installable; Play delivery and physical-device behavior are not claimed.
- Play note: versionCode remains 2. If Play Console already contains versionCode 2, the project needs explicit authorization to increment it before a new upload.

## Corrected RELEASE AAB delivery - versionCode 3 - 2026-08-17

- AAB: `build/android/majestic-gems-merge-sound-sync-v3-vc3.aab`
- Size: 69,163,616 bytes (65.96 MiB)
- SHA-256: `29E0476F88CEA5EC33AA579AC1E15CA432AA9E761C6A7DE6CDB7B9B61A2C5E3B`
- Build source: `aa3a1e1` / `android-version-code-3-source`; implementation source: `3f2fa01` / `merge-sound-sync-v3-source`
- Package: `com.owais.majestygems`, versionCode 3, versionName 1.0.1, min SDK 24, target/compile SDK 36; release manifest is not debuggable.
- Signing: JAR verification PASS using the existing Muhammad Owais Khan / Teckvertex Labs RSA-2048 upload certificate, SHA-256 `E3BA3287A50AF4AC49C07CBCB2E4F10940AD519642CB24F21BCF856B3F3BCE14`.
- Validation: Bundletool 1.18.3 PASS; 1,003 entries; three DEX files; both ARM ABI library pairs; production AdMob App ID present; immediate merge Ogg import present; zero report/test entries. `ADMOB_INTEGRATION_TESTS: PASS` printed before the documented late Poing mock callback teardown error.
- Export note: `version/code=3` was saved, committed, tagged, and pushed before export. The log reached `[DONE] export`; the AAB remained stable for 30 seconds, after which the exact two silent export processes were stopped. The versionCode-2 AAB remains untouched but superseded.
- Device status: AAB files are not directly installable; Play upload/delivery and physical-device behavior are not claimed.
