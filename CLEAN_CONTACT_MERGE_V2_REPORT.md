# Clean Contact Merge v2 Chain Polish Report

## Scope

This milestone begins from the verified clean `clean-contact-merge-v1-spawn-fix` tag. It preserves launcher lifecycle, board geometry, danger line, borders, and queue behavior while adding merge presentation polish and contact-based chain merging.

## Documentation audit

Audited and updated: `AGENTS.md`, `GAME_SPEC.md`, `CURRENT_STATE.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, `AI_KNOWLEDGE_BASE.md`, `BUILD_MANIFEST.md`, `README.md`, and the v1/spawn-fix reports. `AGENTS.md` now explicitly requires the reading order, clean Git inspection, minimal scope, documentation updates, APK provenance, and truthful test/device reporting.

## Merge presentation flow

Simulation immediately consumes both valid sources and creates the upgraded gem at their midpoint. The controller receives a presentation event that draws source ghosts pulling/fading inward for `MERGE_SOURCE_PULL_DURATION = 0.12 s`, alongside an upgraded-gem pulse, glow, and expanding ring for `MERGE_PRESENTATION_DURATION = 0.22 s`. `MERGE_PULSE_SCALE = 1.28`. These effects are drawn only; they never modify physics, collision, IDs, or merge candidates. The next launcher waits until all presentations and board movement complete.

## Chain algorithm and safeguards

Initial candidates still come only from current-frame physical contacts captured before separation. After a valid merge, the service may check only the newly upgraded gem against live equal-level gems using actual radius distance. There is no board-wide, nearest-neighbor, or stale-pair scan. Each cycle consumes sources before spawn, deduplicates pairs, and caps chain cycles at `MERGE_CHAIN_DEPTH_CAP = 6`.

## Changed files

- `scripts/game_config.gd`
- `scripts/merge_service.gd`
- `scripts/game_controller.gd`
- `tools/run_clean_contact_tests.gd`
- governance, architecture, state, specification, README, changelog, and manifest documents

## Validation

- Godot 4.6.3 headless parse/import validation: passed.
- `tools/run_clean_contact_tests.gd`: passed (`CLEAN_CONTACT_TESTS: PASS`). Coverage includes contact/cross-level/distance rules, one-source-per-cycle, local valid chain, distant no-chain, chain cap, presentation gate, top border, and launcher lifecycle.
- Standalone Android debug export: passed and APK physically verified.

## APK

- File: `D:\Owais\game\build\android\clean-contact-merge-v2-chain-polish.apk`
- Size: 27,711,469 bytes
- Modified: 2026-07-29 03:44:48 +05:00
- Source commit/tag: `10f8d59408cccd6287d308f5fc0ab0046326ea3a` / `clean-contact-merge-v2-chain-polish`
- Device status: no device was connected; not installed or phone-tested.

## Phone test checklist

1. Launch one Pearl into a touching Pearl: confirm Ruby appears at the midpoint with a brief inward source animation and pulse/ring.
2. Place a Ruby physically touching that midpoint: confirm the new Ruby chains only into that touching Ruby.
3. Keep another Ruby visibly distant: confirm it does not chain.
4. Test Pearl/Ruby contact: confirm only a push occurs.
5. After any merge, wait: confirm exactly one next launcher appears only after the visual effect ends.
6. Repeat several shots and restart: confirm no idle spawning or queue skipping.

## Remaining risks

No Android device was connected for physical touch/performance testing. Visual timing should be checked on the target phone; effects are intentionally primitive and lightweight for Intel HD 620 and low-end Android hardware.
