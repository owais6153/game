# Spawn Lifecycle Fix Report

## Root cause

After the first shot settled, the prior controller cleared its launcher ID whenever `shot_count > 0`. The settled-board condition then called `spawn_active_piece()` on every later frame. Each freshly created launcher was itself settled and `shot_count` remained positive, so it was immediately cleared and replaced again. This blocked the next player shot.

## Fix

`GameController` now uses a one-shot state machine:

`READY_TO_AIM → SHOT_IN_FLIGHT → RESOLVING → SPAWNING_NEXT → READY_TO_AIM`

Only `SPAWNING_NEXT` creates a launcher. `spawn_active_piece()` returns false when an active launcher already exists, making it idempotent for the cycle. Input is accepted only in `READY_TO_AIM`. Resolution waits for settled pieces and no pending merge candidates before the next launcher is created.

## Files changed

- `scripts/game_controller.gd`
- `scripts/merge_service.gd`
- `tools/run_clean_contact_tests.gd`
- `CHANGELOG.md`, `CURRENT_STATE.md`, `ARCHITECTURE.md`, `AI_KNOWLEDGE_BASE.md`, `GAME_SPEC.md`, and `BUILD_MANIFEST.md`

## Regression coverage

The real controller path now verifies: one initial launcher; one replacement after the first shot; no extra spawn or queue advance during idle frames; no more than one active launcher; a normally launchable second shot; restart restoring one ready launcher; and the existing contact-merge and movement checks.

## Delivery

- APK: `D:\Owais\game\build\android\clean-contact-merge-v1-spawn-fix.apk`
- Size: 27,707,373 bytes
- Modified: 2026-07-29 03:23:14 +05:00
- Gameplay source: `53306bf1f9d96fbb6918380657dd611ed1a7a51e`
- Tag: `clean-contact-merge-v1-spawn-fix`

## Phone checklist

1. Install the APK and open it without a development server.
2. Launch the first gem and wait for it to settle.
3. Confirm exactly one next gem appears and can be dragged/launched.
4. Wait without launching again; confirm no additional gems appear and the NEXT label does not change.
5. Launch the second gem, then use Restart; confirm the board resets to one ready launcher.
