# Last Task Rollback Report

## Scope

Rollback only. No perspective replacement, gameplay, collision, table, target, win-sequence, Level 1, UI, or asset changes were made.

## History and restoration

- Bad pushed commit reverted: `2c7114cf091242b9d0dc8a1eda9adbb017421c1b` (`fix: unify table perspective and final win sequence`).
- Pre-task commit verified from Git log and reflog: `70733c0d2f3f78642d58dad5c5e04c614f1f8736` (`docs: record visible-touch fix build`).
- Restored working mechanics milestone: `3316d2dcdebde9528885c882b2de385c26862c66`, tag `visible-touch-table-alignment-fix-v1`.
- Restoration strategy: normal Git revert commit `97b6bc355172c3f1df394a85b9bc63f6fb376290`; history was not reset or force-pushed.

## Removed task artifacts

- Shared projection source and UID files.
- Shared projection capture tool and UID file.
- Shared-perspective report and screenshots.
- `build/android/shared-perspective-win-sequence-fix-v1.apk` and its `.idsig` companion.
- All documentation and test changes introduced solely by `2c7114c`.

Older APKs, reports, tags, 18-gem assets, and Level 1 data were retained.

## Validation

- Godot 4.6.3 headless parse/import: passed.
- `CLEAN_CONTACT_TESTS`: passed.
- `GEM18_CHAIN_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed.
- `MOTION_PROFILE`: passed.

## Fresh APK

- File: `build/android/pre-shared-perspective-restored.apk`
- Size: `99,204,339` bytes.
- Modified: `2026-07-30 12:03:14 +05:00`.
- SHA-256: `56EE18332CCFC0D96CE6D5E895D97558A3143F5FDDF77F9B0C2F665B8921CE6C`.
- ZIP validation: `AndroidManifest.xml`, `classes.dex`, and `lib/arm64-v8a/libgodot_android.so` are present.
- Device status: no Android device was connected; no install or launch is claimed.

## Remote status

The rollback commit and `pre-shared-perspective-restored-v1` tag are to be pushed to the existing `origin` without force-pushing.
