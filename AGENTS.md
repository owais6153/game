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
- Create a task-specific report for every gameplay task.
- Preserve verified mechanics and their regression tests. Make the smallest scoped change possible; do not change unrelated launcher, board, queue, or collision behavior.
- Record tests actually run, the standalone APK file existence check, and connected-device status truthfully. Never infer phone testing from a successful export.
- Make one mechanic change per task whenever practical.
- Do not perform broad refactors or retuning without explicit user approval.
- For any level-loop work, test the controller path for confirmed-event score handling, overlay spawn blocking, danger-timer exemptions, and full reset in addition to the existing movement/merge/lifecycle suite.
- Do not claim success without passing relevant tests and confirming a standalone APK exists.
- Do not touch files outside `D:\Owais\game` without explicit approval.
