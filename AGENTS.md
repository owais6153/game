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
- Create a clean commit and tag before and after each gameplay milestone.
- Update the relevant Markdown documents in the same task as every code, configuration, scene, test, or build change.
- Update `CHANGELOG.md` and `CURRENT_STATE.md` for every behavior change.
- Update `ARCHITECTURE.md` and `AI_KNOWLEDGE_BASE.md` for every architecture or module change.
- Record every delivered APK in `BUILD_MANIFEST.md`: filename, size, timestamp, commit hash, tag, validation, and device status.
- Create a task-specific report for every gameplay task.
- Make one mechanic change per task whenever practical.
- Do not perform broad refactors or retuning without explicit user approval.
- Do not claim success without passing relevant tests and confirming a standalone APK exists.
- Do not touch files outside `D:\Owais\game` without explicit approval.
