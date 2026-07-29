# Gem Merge Rebuild

A clean-room Godot 4.6.3 portrait gem-launching merge game.

## Current milestone

`gem-visual-refinement-v1`: the playable level loop now has a refined lightweight jewelry-table presentation, clearer gem facets and shadows, an improved visual-only merge pulse, and responsive portrait-safe HUD/overlay layout. The merge, collision, queue, danger, score, win, and reset rules are unchanged.

## Commands

```powershell
# Parse/import validation
D:\Owais\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game --editor --quit

# Headless integration tests
D:\Owais\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game -s res://tools/run_clean_contact_tests.gd
```

Android APK export and provenance are recorded in `BUILD_MANIFEST.md`.

Read `AGENTS.md` before changing this project. It defines the required documentation, Git, testing, and APK-provenance workflow for every task.
