# Blank Android Baseline Report

## Scope

This task completed the clean rebuild's blank standalone Android baseline gate only. No gameplay code or mechanics were introduced.

## Configuration change

Added the following setting exactly once to `project.godot`:

```ini
[rendering/textures/vram_compression]
import_etc2_astc=true
```

This enables ETC2/ASTC texture imports for Android export compatibility.

## Validation

- Folder write probe: created and removed a temporary file successfully in `D:\Owais\game`.
- Godot 4.6.3 headless parse/import validation: passed.
- Android export preset: `Android` from `export_presets.cfg`.
- Export command: Godot headless `--export-debug Android`.
- APK package inspection: passed with Android `aapt`.

## Delivered APK

- Path: `D:\Owais\game\build\android\gem-merge-rebuild-baseline.apk`
- Size: 27,690,009 bytes
- Modified: 2026-07-29 02:55:38 +05:00
- SHA-256: `B29D90C5E082CFEA0567EA488B831458B8107F15690838BE5F06355139A93A1F`
- Package: `com.owais.gemmergerebuild`
- Architectures: `arm64-v8a`
- Device testing: not performed; no Android device was connected.

## Source traceability

- Source commit: `ad1e2d720f615ce326da91ac15b5a303543b15d8` (`build: verify blank Android baseline export`).
- Tag: `blank-android-baseline-verified`.
