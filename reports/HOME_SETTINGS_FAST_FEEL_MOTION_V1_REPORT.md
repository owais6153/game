# Home Settings + Fast Feel Motion v1 Report

## Requested changes
- Fix the Home settings control shown as a full-height translucent rail.
- Use the supplied motion addons to improve animation responsiveness and perceived game speed.
- Use the supplied icon library where needed.
- Update project documentation.

## Implemented
### Home settings alignment
`HomeSettingsFrame` remains 94×94 and now explicitly shrinks to the top/right on the HBox cross/main axes. The full-screen safe-area container is preserved so notches/cutouts remain respected.

### Global Tweens
`GlobalTweens.gd` is an autoload. Home/Level Intro/Pause buttons and setting switches get a short press compression. Toggle changes and confirmed target feedback get a short blue/cyan pulse.

### Tween Composer
`HomeOverlayLayer` creates reusable Tween Composer sequences for:
- Crystal Magic Home logo: subtle 1.0 ↔ 1.018 breathing loop.
- Level Intro target gem: subtle 1.0 ↔ 1.055 breathing loop.

These are presentation-only Controls and do not touch simulation-owned gem transforms.

### Fast-feel tuning (before → after)
- Launch speed: 1160 → 1200
- Velocity damping: 185 → 195
- Sleep threshold: 9 → 10
- Merge presentation: 0.50 s → 0.36 s
- Merge source pull: 0.10 s → 0.075 s
- Merge pop duration: 0.22 s → 0.14 s
- Score popup: 0.62 s → 0.46 s
- Coin burst: 0.22 s → 0.16 s
- Coin flight: 1.58 s → 0.92 s
- Major coin flight: 1.66 s → 1.00 s
- Coin flight stagger: 0.15 s → 0.08 s
- Target collection: 0.62 s → 0.40 s
- Target confirmation overlay: 0.94 s → 0.52 s
- Target swap start: 0.78 s → 0.26 s
- Target swap fade out/gap/in: 0.24/0.10/0.24 → 0.14/0.05/0.16 s
- Chain presentation stagger: 0.05 s → 0.03 s
- Launcher handoff: 0.30 s → 0.22 s
- Next-launcher ready delay: 0.04 s → 0.02 s
- Overlay fade: 0.18 s → 0.14 s
- Win hold: 0.32 s → 0.24 s

## Preserved
No changes were made to table geometry, collision radii, contact-only merge eligibility, level generation, target qualification, score authority, coin reward values, persistence, audio assets, or background/table/gem artwork.

## Icon-library note
No distinct icon library/plugin/icon pack was present in the supplied archive. The task therefore preserves existing HUD icons and does not claim icon-library integration. If the intended library is provided in a later archive, it can be wired in then.

## Validation performed
- Archive extracted successfully.
- Modified source/resources and referenced third-party scripts exist at their declared `res://` paths.
- `project.godot` contains the `GlobalTweens` autoload.
- Static source inspection confirmed the Home settings shrink flags and centralized timing values.
- No `.git` metadata was present in the supplied ZIP, so the repository status/log workflow from `AGENTS.md` could not be performed on this archive.
- Godot 4.6.3 is not installed in this execution environment, so parser/import, APK export, device install, and on-device visual/performance validation are not claimed.
