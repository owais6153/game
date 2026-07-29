# Gameplay Balance v1 Report

## Baseline

- Verified baseline: `14d5de194e60dedf23c29e8c401e8c8b47e761a6` / `gem-visual-refinement-v1`.
- Scope: mobile feel only. Merge eligibility, level progression, scoring, chains, danger-line semantics, win/fail logic, and launcher lifecycle rules are unchanged.

## Centralized tuning changes

| Value | Before | After | Reason |
| --- | ---: | ---: | --- |
| Launch speed | 1050 px/s | 1100 px/s | More immediate upward shot while retaining a fixed vertical trajectory. |
| Damping | 324 px/s² | 285 px/s² | Less premature slowdown on clear shots. |
| Sleep threshold | 11 px/s | 9 px/s | Cleaner resting state with reduced abrupt stopping. |
| Side/top/bottom restitution | 0.23 / 0.18 / 0.12 | 0.20 / 0.14 / 0.10 | Reduces wall ping-pong while keeping containment. |
| Equal-mass collision restitution | 0.58 | 0.48 | Reduces excessive pushes and crowded-board bounce. |
| Separation epsilon | 0.25 px | 0.15 px | Less visible separation while preserving overlap resolution. |
| Source pull / merge presentation | 0.12 s / 0.22 s | 0.10 s / 0.20 s | Tighter merge read without changing simulation timing. |
| Merge pulse scale | 1.28 | 1.22 | Less oversized visual pulse. |
| Chain presentation stagger | none | 0.07 s | Makes sequential chain visuals legible; logic remains immediate and deterministic. |
| Next launcher readiness | immediate | 0.08 s | Adds a short rhythm pause after resolution without changing one-spawn lifecycle behavior. |
| Danger grace | 0.75 s | 0.75 s | Retained: existing fairness behavior was already appropriate. |

## Validation

- Godot 4.6.3 parse/import validation: passed.
- Headless controller/simulation suite: passed (`CLEAN_CONTACT_TESTS: PASS`).
- Added coverage: launch time range, maximum settle time, persistent-jitter absence, representative 120/60 Hz step stability, wall containment, chain visual cadence, along with existing contact-only merge, queue, and danger-grace tests.
- Standalone Android debug export: passed; APK existence verified.
- `adb devices -l`: no real device connected. No install or launch was attempted.

## Debug checklist and observations

The following checklist is ready for phone verification; no phone claim is made here:

- 10 consecutive launches: confirm one ready launcher returns after each settled resolution, with no duplicate queue advance.
- Top-border shot: confirm a clear shot reaches and softly settles at the top.
- Side-wall shot: confirm containment with no repeated wall ping-pong.
- Direct same-level merge: confirm only a physically contacting equal-level pair merges.
- Chain merge: confirm sequential visual pulses remain readable while contact-only logic remains immediate.
- Crowded-board settling: confirm no permanent overlap or micro-jitter after an impact.
- Danger-line edge case: confirm a moving or active gem does not fail, while a settled board gem below the line fails after 0.75 s.

Headless observations: deterministic contact, distant/cross-level rejection, containment, launcher cardinality, presentation gating, and danger behavior all passed. Physical touch feel, device FPS, and safe-area confirmation remain pending a connected phone.

## APK

- File: `D:\Owais\game\build\android\gameplay-balance-v1.apk`
- Size: 27,728,010 bytes
- Modified: 2026-07-29 06:45:13 +05:00
- Device status: no device connected; not installed or launched.

## Known limitations

- This is a tuning pass over procedural prototype visuals; final sounds, haptics, device profiling, and external art remain out of scope.
- The safe ranges in `AI_KNOWLEDGE_BASE.md` are guardrails, not permission to retune unrelated work.
