# Gem Merge Rebuild

A clean-room Godot 4.6.3 portrait gem-launching merge game.

## Current milestone

`clean-contact-merge-v3-playable-loop`: a simple drawn-circle playable level with strict contact-only chain merges, score/chain HUD, Diamond win, danger-line fail, and full Replay/Retry reset.

## Commands

```powershell
# Parse/import validation
D:\Owais\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game --editor --quit

# Headless integration tests
D:\Owais\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game -s res://tools/run_clean_contact_tests.gd
```

Android APK export and provenance are recorded in `BUILD_MANIFEST.md`.

Read `AGENTS.md` before changing this project. It defines the required documentation, Git, testing, and APK-provenance workflow for every task.
