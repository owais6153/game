# Asset Integration — Background, Table, and Gems v1

## Baseline

- Started from clean verified milestone `d2e99213f01005ba08ff1f9bd50a98ac11a967c7`, tagged `reference-table-gem-audio-v1`.
- The user-supplied `assets/` directory was intentionally untracked at the start of this task; the request explicitly authorized integrating it.

## Selected source assets

- Background: `assets/bg/ChatGPT Image Jul 29, 2026, 09_47_21 AM.png` (941×1672, RGB) — tropical beach composition.
- Table: `assets/tables/ChatGPT Image Jul 29, 2026, 09_52_25 AM (2).png` (1024×1536, alpha) — turquoise surface with coral rails.
- Gems: `assets/gems/Generated image 5 (1).png`, `Generated image 6 (1).png`, `Generated image 7.png`, `Generated image 8.png`, `Generated image 9.png` — Pearl through Diamond respectively (all 1024×1536, alpha).
- The selected Diamond source was the only Diamond supplied. Its derived runtime copy is `assets/runtime/gems/diamond.png`: transparent empty padding was trimmed and a transparent silhouette mask removed the large outer/lower halo. The supplied original stays unchanged.

`ASSET_INVENTORY.md` contains the full source inventory and every runtime output.

## Integration and calibration

- Background is a full-canvas Sprite2D at the fixed 720×1280 design resolution. Its source aspect ratio matches the canvas closely, so it is scaled without stretch or visible crop distortion. It has no input handlers.
- Table is a Sprite2D centered at `(360, 650)`. `GameConfig` is the single layout authority: top inner rails `x=129..594` at `y=224`; bottom inner rails `x=0..720` at `y=1080`; side rails are interpolated.
- `BoardSimulation` uses `table_left_at(y)` / `table_right_at(y)` for collisions. Launcher drag, spawn width, and the dynamic danger line use exactly the same functions. The physical top rail is `y=224`.
- Existing collision radius is unchanged at 42 px. `GemSpriteLayer` reads the already-authoritative entity state and uses Sprite2D textures only; it cannot change IDs, positions, radii, velocity, contacts, merge eligibility, score, chains, outcomes, or queue state.
- Merge source ghosts and HUD previews use the same runtime texture catalog. The upgraded-gem pulse stays presentation-only.

## Checks

- Godot 4.6.3 parse/import validation: passed.
- `tools/run_clean_contact_tests.gd`: passed (`CLEAN_CONTACT_TESTS: PASS`).
- Added/updated coverage for runtime gem mapping, clean Diamond selection, source texture availability, trapezoid rail validity, launcher bounds, danger-line span, existing contact-only merges/chains, no distant or cross-level merge, lifecycle, score, win/fail, reset, audio, and haptics.
- Responsive layout coverage retains 720×1280, 1080×1920, 1080×2400, 1440×3200, and 900×1280 portrait calculations. Canvas-item scaling keeps the non-distorted background, while the table/physics geometry stays in the fixed design space.

## Manual phone checklist

No phone was connected in this session. On-device review should check: empty board; unobstructed Pearl to the top rail; both side rail contacts; direct Pearl and Ruby merges; centered rectangular Emerald during collision; Sapphire/Diamond display; a contact chain; a crowded board; restart; and the five representative portrait ratios where available.

## APK

- File: `D:\Owais\game\build\android\asset-integration-background-table-gems-v1.apk`
- Size: 70,457,131 bytes
- Modified: 2026-07-29 10:24:35 +05:00
- Device status: `adb devices -l` found no connected device; no install or launch was attempted.
