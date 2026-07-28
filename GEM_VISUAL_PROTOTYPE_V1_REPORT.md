# Gemstone Visual Prototype v1 Report

## Scope and merge-physics review

The review covered contact capture, overlap separation, damping/restitution, merge eligibility, source ghost timing, upgraded-piece spawn, and post-merge settlement. No simulation, collision, eligibility, chain, queue, danger-line, or launcher-lifecycle change was justified or made.

One presentation-only issue was corrected: source ghosts were rendered after live pieces, briefly covering the newly spawned upgraded gem. Ghosts, ring, and glow now render first; the immediate simulated upgraded gem renders above them. This makes the merge read as an inward transformation without changing physical state or timing.

## Visual decisions

- Pearl: round creamy body and soft highlight.
- Ruby: red faceted hexagonal gem.
- Emerald: green emerald-cut octagon.
- Sapphire: blue faceted octagon.
- Diamond: bright multi-facet diamond.
- Board: dark luxury backdrop, gold rails, and a restrained green jewelry-table inset.
- All visual work uses Godot drawing APIs only. There are no external PNG assets, shaders, bloom, post-processing, or heavy particles.

## Changed files

- `scripts/gem_visuals.gd` (new rendering-only helper)
- `scripts/game_controller.gd` (draw order and visual composition only)
- `tools/run_clean_contact_tests.gd` (level-to-style mapping regression)
- Project governance, state, architecture, specification, knowledge-base, manifest, changelog, and README documents.

## Validation

- Godot 4.6.3 parse/import validation: passed.
- Complete headless controller/simulation suite: passed (`CLEAN_CONTACT_TESTS: PASS`).
- Standalone Android debug export: passed and file existence verified.

## APK

- Path: `D:\Owais\game\build\android\gem-visual-prototype-v1.apk`
- Size: 27,723,914 bytes
- Modified: 2026-07-29 04:40:27 +05:00
- Source commit/tag: `561235ad45a6dbf50a3b8a018820656dae53cd53` / `gem-visual-prototype-v1`
- Device status: no real device was installed or launched in this session.

## Known limitations

The gems are intentionally procedural prototypes, not final production art. The game still has no sound, persistence, levels, ads, shop, analytics, backend, or playable-ad build.

## Phone test checklist

1. Compare each gem level and confirm its silhouette is visibly distinct.
2. Merge two Pearls and confirm the Ruby stays visible above fading source ghosts.
3. Test a chain merge and verify only physically contacting equal-level gems merge.
4. Wait after a merge and confirm exactly one next launcher appears.
5. Test Restart, Diamond win/Replay, and danger-line Retry.
