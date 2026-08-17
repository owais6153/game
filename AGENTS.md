# Required Reading Order

Before inspecting or editing project files, every future agent must read, in this order:

1. `AGENTS.md`
2. `GAME_SPEC.md`
3. `CURRENT_STATE.md`
4. `CHANGELOG.md`
5. `ARCHITECTURE.md`
6. `AI_KNOWLEDGE_BASE.md`
7. `BUILD_MANIFEST.md`
8. Task-specific reports and tests relevant to the requested change

## Mandatory workflow

- Inspect `git status` and recent `git log` before each task.
- Identify the current milestone commit and tag before editing; stop and report if the tree is not clean unless the user explicitly authorizes work on it.
- Read every document in the Required Reading Order before inspecting gameplay code.
- Create a clean commit and tag before and after each gameplay milestone.
- Update the relevant Markdown documents in the same task as every code, configuration, scene, test, or build change.
- Update `CHANGELOG.md` and `CURRENT_STATE.md` for every behavior change.
- Update `ARCHITECTURE.md` and `AI_KNOWLEDGE_BASE.md` for every architecture or module change.
- Record every delivered APK in `BUILD_MANIFEST.md`: filename, size, timestamp, commit hash, tag, validation, and device status.
- Before every AAB export, inspect all uploaded and delivered AAB versions in `BUILD_MANIFEST.md`. Choose a `version/code` integer strictly greater than every previously used code and a semantic `version/name` strictly greater than the latest release name (increment the patch number by default, for example `1.0.1` -> `1.0.2`). Persist and commit both values in `export_presets.cfg` before building; never reuse or temporarily revert either value.
- Name every release AAB with its version name and version code, then use Bundletool to verify that the embedded manifest contains the prepared values before recording or delivering it. If either embedded value is not newer than the prior release, the AAB is invalid and must not be delivered.
- Create a task-specific report for every gameplay task.
- Create every new milestone report under `reports/`; never add a report file to the repository root. Keep `reports/README.md` indexed.
- After local validation, commit and tag each completed milestone, then push the existing branch and its new tag to the configured GitHub `origin`. Never force-push or replace the origin URL without explicit user authorization.
- Preserve verified mechanics and their regression tests. Make the smallest scoped change possible; do not change unrelated launcher, board, queue, or collision behavior.
- Record tests actually run, the standalone APK file existence check, and connected-device status truthfully. Never infer phone testing from a successful export.
- Make one mechanic change per task whenever practical.
- Do not perform broad refactors or retuning without explicit user approval.
- Rendering-only work must stay outside the simulation, merge-service, launcher, and collision paths. Keep procedural visuals in dedicated drawing helpers and add a mapping test whenever gem-level artwork changes.
- HUD/progression work must read controller snapshots only. It must not duplicate queue/progression rules, create input handlers over the board, or alter simulation coordinates.
- For any level-loop work, test the controller path for confirmed-event score handling, overlay spawn blocking, danger-timer exemptions, and full reset in addition to the existing movement/merge/lifecycle suite.
- Do not claim success without passing relevant tests and confirming a standalone APK exists.
- Do not touch files outside `D:\Owais\game` without explicit approval.
- Gameplay-feel work must change only centralized `GameConfig` tuning values unless the task explicitly authorizes a behavior change. Record before/after values, safe ranges, and test evidence in the task report.
- For balancing milestones, preserve delta-based simulation and add coverage for timing, settling, containment, launcher pacing, and danger grace behavior.
- For feedback work, keep audio and haptics behind dedicated services; route only confirmed controller events and update `reports/SOUND_HAPTICS_V1_REPORT.md` plus the central `GameConfig` event constants.
- For reference/composition work, table rendering and physics borders must read the same centralized `GameConfig` geometry. For audio work, contact telemetry must identify gem versus wall, use thresholds/cooldowns/concurrency caps, and never feed gameplay decisions. Record source/asset provenance and the manual listening checklist in the task report.
- For supplied-art integration, preserve originals under `assets/`; create any optimized or trimmed copies only under `assets/runtime/` and document source-to-runtime mappings in `ASSET_INVENTORY.md`. Use one authoritative layout model for table rendering, rails, launcher, drag clamp, spawn limits, and danger line. Artwork must never define physics radius, merge eligibility, or score behavior.
- For visual-physics calibration, measure alpha bounds before changing collision geometry; keep simple documented colliders in `GameConfig`, trim only non-destructive runtime derivatives, and add a regression that proves contact audio starts from confirmed physical contact. Keep F8 collider/rail/contact diagnostics disabled by default.
- For result UI, victory qualification and victory presentation are separate states. Use the dedicated `ResultOverlayLayer` CanvasLayer; never dim or alter the gameplay root, gem container, gem texture, or gem `modulate` when an overlay appears.
- For supplied table or shadow work, preserve originals under `assets/`, put derived body/shadow assets only under `assets/runtime/`, and keep all table rails plus physics geometry centralized in `GameConfig`. A shadow is presentation-only: it must never affect radii, contact capture, merge eligibility, sound telemetry, or containment.
