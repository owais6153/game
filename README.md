# Gem Merge Rebuild

A clean-room Godot 4.6.3 portrait gem-launching merge game.

## Current milestone

`visual-physics-calibration-v1`: calibrated table perspective, visible gem contact bounds, and confirmed-contact audio routing. See `reports/VISUAL_PHYSICS_CALIBRATION_V1_REPORT.md`.

## Commands

```powershell
# Parse/import validation
D:\Owais\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game --editor --quit

# Headless integration tests
D:\Owais\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game -s res://tools/run_clean_contact_tests.gd
```

Android APK export and provenance are recorded in `BUILD_MANIFEST.md`.

Read `AGENTS.md` before changing this project. It defines the required documentation, Git, testing, and APK-provenance workflow for every task.
# Gem Merge Rebuild

The current verified milestone uses supplied tropical background, coral table, and five gem assets while retaining the documented contact-only merge game loop. Read `AGENTS.md`, `CURRENT_STATE.md`, `ASSET_INVENTORY.md`, and `BUILD_MANIFEST.md` before changing the project.

Run the test suite from the project root:

```powershell
& 'D:\Owais\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe' --headless --path . -s res://tools/run_clean_contact_tests.gd
```
# Visual-sequencing contact v2

The current milestone uses the newly supplied table plus body-only gem textures and separate presentation shadows. Contact-only merge eligibility remains unchanged.
