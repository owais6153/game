# Gem Visual Refinement v1 Report

## Baseline

- Baseline commit/tag: `561235ad45a6dbf50a3b8a018820656dae53cd53` / `gem-visual-prototype-v1`.
- Scope: rendering and fixed-canvas layout only. Simulation, collision, merge eligibility, score, chain, launcher lifecycle, danger line, and win/fail logic were not changed.

## Refinements

- Board: a restrained deep-green jewelry table now uses layered gold rails and a subtle inset border, while retaining the exact simulation board rectangle.
- Gems: Pearl gained depth and a smaller highlight; Ruby, Emerald, Sapphire, and Diamond gained restrained lower facets or cuts. Shapes remain distinct at the existing collision radius.
- Merge presentation: the pulse uses eased visual timing. Ghosts, ring, glow, and live gem order remain unchanged in their simulation isolation.
- HUD and overlays: clearer panel hierarchy, centered result text, visible action-button borders, and an overlay dimmer improve readability without adding screens or gameplay controls.

## Responsive portrait checks

The game retains its fixed 720x1280 design canvas with Godot canvas-item stretch. Visual-bound regression assertions verify that HUD, restart control, result panel, and result action fit the design canvas and do not overlap the gameplay board. This scales for 720x1280, 1080x1920, 1080x2400, 1440x3200, and wider/shorter portrait displays without changing collision coordinates. Physical phone inspection is still required for final safe-area confirmation.

## Performance

The work remains lightweight: Godot drawing calls only; no external textures, shaders, blur, bloom, post-processing, heavy particles, or per-gem nodes were added. Rendering remains suitable for low-end Android and the development PC's Intel HD 620.

## Files changed

- `scripts/game_config.gd`
- `scripts/gem_visuals.gd`
- `scripts/game_controller.gd`
- `tools/run_clean_contact_tests.gd`
- Project documentation listed in the milestone commit.

## Validation

- Godot 4.6.3 parse/import validation: passed.
- Headless controller/simulation suite: passed (`CLEAN_CONTACT_TESTS: PASS`).
- Android standalone export: passed; APK existence verified.
- `adb devices`: no device connected. No install or launch was performed.

## APK

- File: `D:\\Owais\\game\\build\\android\\gem-visual-refinement-v1.apk`
- Size: 27,723,914 bytes
- Modified: 2026-07-29 04:59:02 +05:00

## Known limitations and phone checklist

- This is still procedural prototype art, not final external production artwork.
- On a phone, check readability of all five gems while moving; HUD text at the top; Restart and Replay/Retry touch targets; danger-line alignment; and that merge effects never flicker or cover the live upgraded gem.
