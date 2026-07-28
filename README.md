# Gem Merge Rebuild

A clean-room Godot 4.6.3 portrait gem-launching merge game.

## Current milestone

`clean-contact-merge-v1`: a simple drawn-circle board with drag-horizontal / release-upward input and strict current-contact-only merging.

## Commands

```powershell
# Parse/import validation
D:\Owais\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game --editor --quit

# Headless integration tests
D:\Owais\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game -s res://tools/run_clean_contact_tests.gd
```

Android APK export and provenance are recorded in `BUILD_MANIFEST.md`.