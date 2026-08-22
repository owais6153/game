# Reward Feedback Real Gems V4

Date: 2026-08-22

## Outcome

This milestone corrects the central Reward Feedback V3 misunderstanding: the
objects produced by every successful merge are now persistent `GemPiece`
gameplay entities. They have normal radii, physics, rail containment, contact
capture, danger-line participation, settlement, and future merge eligibility.
No cosmetic mini-gem/fade channel remains.

The preserved reward hierarchy is:

`collision < merge < combo < high combo < target achievement < level complete`

## Real bonus gameplay gems

All tuning is centralized in `GameConfig`:

| Setting | Delivered value | Intended safe tuning range |
|---|---:|---:|
| Normal merge | 1 | 1 |
| COMBO 1 | 1 | 1 |
| COMBO 2 | 2 | 1-2 |
| COMBO 3 | 2 | 2 |
| COMBO 4+ | 3 | 2-3 |
| Tier weights | 50% low / 30% middle / 20% high | lower tiers must remain dominant |
| Spawn impulse | 165 px/s upward fan after pop | 145-190 px/s |
| Same-event grace | 180 ms | 150-200 ms |
| Spawn delay | 200 ms from confirmation | 180-220 ms |
| Pop / physics hold | 340 ms | 300-380 ms |
| Per-shot generated-piece budget | 3 | 2-3 |
| Maximum reward-generating depth | COMBO 2 | COMBO 2-3 |
| Live + pending piece cap | 24 | 20-28 |

For a result at local tier N, bonus selection uses only local tiers 1 through
N-2, with safe early-tier fallback to tier 1. It never hardcodes gem names;
`AssetCatalog` continues to map the generated level's local progression.

Spawn placement searches a bounded upper fan around the live result position,
clamps every candidate through the authoritative sloped table geometry, checks
clearance against all live and same-event pieces, and chooses the first clear
candidate (or the maximum-clearance candidate in a fully packed board). One
piece launches upward with small deterministic lateral variation; two use
upper-left/upper-right; three use upper-left/up/upper-right.

`GemPiece` also carries a short activation delay and stored velocity. During the
340 ms visual pop, `BoardSimulation` excludes that body from integration and
pair contact. On the following step it releases the stored impulse and begins
the 180 ms sibling grace. During grace, normal physical collision continues and
only a merge candidate between two same-event bonus pieces is suppressed. Each
piece can merge with existing bodies after activation; the event marker clears
when grace expires.

The requested 1/1/2/2/3 ladder is bounded by three controller-owned limits. Each
player launch resets a three-piece generation budget shared by every merge in
that shot's chain; COMBO 3+ cannot generate another reward tier; and scheduling
counts live plus pending bodies against a 24-piece population cap. Reaching a
limit simply omits further rewards; existing physics and ordinary confirmed
merges continue normally.

At creation, each sprite is drawn at the confirmed merge midpoint. It scales
`0.28 -> 1.18`, remains centered through that rise, then settles outward to
`1.00` at its collision-safe position over 340 ms. Only after this complete beat
does physics start, making cause and effect readable before any new contact.

## Merge impact and reusable shader

Normal merge now completes in 420 ms:

- 0-35 ms: source compression at `1.04 x 0.92`.
- 35-120 ms: readable snap to the midpoint and scale to 0.80.
- 120 ms: synchronized source hide, result reveal, ring, shader, and merge SFX.
- Result pop: `0.65 -> 1.24 -> 0.93 -> 1.05 -> 1.0`.

Combo peaks are 1.27 / 1.30 / 1.34 / 1.38 for COMBO 1 / 2 / 3 / 4+.
Hit-stop is 30 / 35 / 40 / 45 / 50 ms across normal through COMBO 4+.
Presentation starts are separated by 180 ms per chain depth, so COMBO 2 and 3
do not visually land in the same instant even though resolution stays immediate.

`GemSpriteLayer` owns one reusable mobile canvas-item radial shader. Eight
Sprite2D slots are preallocated and reuse one shader implementation; only small
per-slot materials hold uniforms. The radial lasts 180 ms, scales 0.30 -> 1.30,
and takes intensity 0.35 / 0.45 / 0.60 / 0.80 / 0.92 / 1.00 across normal,
COMBO 1, COMBO 2, COMBO 3, COMBO 4+, and final target. It renders behind live
gem sprites. There is no full-screen pass, distortion, bloom, lightning, or
camera shake.

## Target and level-complete payoff

Relevant non-final target merges immediately pulse the target panel to 1.07 and
briefly highlight its current gem icon. At collection arrival, both the progress
bar and numeric value animate from the previous displayed value. Their four
coins now all finish landing, remain together on the table for at least 260 ms,
then begin the existing staggered HUD flights.

The final target uses a `0.60 -> 1.40 -> 1.18` creation beat, 250 ms move to the
board center, 420 ms readable hero hold, 70 ms recoil anticipation to 1.35, and
310 ms curved HUD launch. The target panel answers `1.00 -> 0.92 -> 1.16 ->
0.97 -> 1.00`. Only that impact advances the presented target count. The exact
authoritative reward is then drawn prominently at the top of the playable board.

The jackpot uses 16 visual coins at 19 px radius, spawned 4+4+4+4 inside a
compact 0.38-width/82 px-height center band, with a 380 ms visible table hold
and accelerating collection groups 2, 2, 3, 3, 2, 4. The final four arrive
together as the clean confirmation group. HUD balance still advances
only toward the already-authoritative coin total and never awards twice. The
final group triggers `1.00 -> 1.14 -> 0.96 -> 1.00` on the coin HUD before Level
Complete is allowed to present.

## Audio and haptics audit

The existing audio service already provides distinct confirmed-contact,
normal-merge, tiered target merge, chain, target arrival, target complete, coin
tick, final coin reward, and win identities. Combo pitch is multiplied by the
same timeline ladder (1.00 through 1.24; final target 1.28), while the existing
cooldown, five-voice priority pool, merge-contact suppression, buses, and limiter
remain intact. Coin ticks remain throttled and the final group uses one
`coin_reward` cue.

No new audio assets were invented. A physical-phone listening pass is still
needed to judge whether the normal merge, target-panel impact, and final CHING
sources need replacement. The shipped controller explicitly disables haptic
output because the current product has no supported player-facing vibration
infrastructure; event routing remains a no-op sink. No risky platform-specific
haptic implementation was added.

## Performance and balance safeguards

- Real rewards add only `GemPiece` records and reuse the existing sprite sync;
  there are no per-piece Nodes in simulation.
- Radial nodes are pooled (8 maximum); reward coins and rings remain bounded.
- Bonus spawn randomness is deterministic per level seed/result ID and allocates
  only once per confirmed merge, never per frame.
- Three generated rewards per shot, COMBO 2 generation depth, and 24
  live-plus-pending pieces are hard caps;
  exhausting either cannot recursively mint another long reward chain.
- The focused regression simulates the bonus for three seconds, proves it
  remains in `pieces`, proves its marker expires, and proves it later becomes a
  source of a normal confirmed merge.
- The same-event test proves collision continues during grace, mutual merging is
  briefly suppressed, and merge eligibility returns after 180 ms.

Because permitted merges add real population, phone playtesting across several
complete levels remains required before economy/danger tuning is frozen. The
requested tuning values are exposed rather than replacing the rewards with fake
visuals. Automated validation covers both cascade limits, containment,
contact-only merging, launcher pacing, danger exemptions, final overlay spawn
blocking, and reset.

All live gems reuse the supplied soft-shadow asset at 0.34 opacity. Non-final
target and jackpot coins draw 0.32-opacity contact shadows at a visible 5x9 px
offset; each ellipse fades as its coin launches toward the HUD. These values were raised
after screenshot review showed the earlier faint pass did not register.
Shadows remain presentation-only and do not define collision or contact audio.

## Visual acceptance evidence

Godot GL Compatibility (ANGLE, Intel HD 620) produced:

- `reports/reward-feedback-real-gems-v4/reward-feedback-real-gems-v4.avi`
- `reports/reward-feedback-real-gems-v4/screenshots/`

The muted-first review confirms a clear normal POP, merge-center bonus emergence,
180 ms-spaced chain tiers, the COMBO 3 reward-generation cutoff, a later
confirmed merge using the persisted bonus, a four-coin non-final target table
hold, a distinct hero target sequence, a prominent real `+reward`, 16 larger
clustered coins, visible soft gem/coin grounding shadows, final HUD
impact, and delayed Level Complete. The capture is deterministic development
gameplay, not a physical-device recording. Physical listening, haptic feel, and
Android frame-time acceptance are not claimed.

## Validation

- Godot 4.6.3 project import/parse: PASS.
- `REWARD_FEEDBACK_V3_TESTS`: PASS (expanded for real pieces/grace/persistence).
- `REFERENCE_GAME_FEEL_V2_TESTS`: PASS.
- `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS`: PASS.
- `UI_SCALE_LAYOUT_TESTS`: PASS.
- `SOUND_PRIVACY_LINK_TESTS`: PASS.
- `GAME_FLOW_REWARD_SPLASH_TESTS`: PASS.
- `BRANDING_PUSH_LINE_TESTS`: PASS.
- `SCENE_VARIETY_ASSETS_TESTS`: PASS.
- `ADMOB_INTEGRATION_TESTS`: PASS.
- GL Compatibility/ANGLE screenshot and AVI capture: PASS.

All nine repository suites passed. The Windows runner prints each PASS sentinel
before its known post-quit access violation; no assertion failed.

Final debug APK: `build/android/majestic-gems-reward-feedback-real-gems-v4.apk`
(82,272,500 bytes; SHA-256
`4CEA7BC0B5B4B616FEDFA75A5DEC0693C7DF91D87BCFE5C6C2CD68700C769233`).
AAPT reports package `com.owais.majestygems`, versionCode 6, versionName 1.0.4,
minimum SDK 24, and target/compile SDK 36. APK Signature Scheme v2 passes with
one Godot RSA-2048 debug signer; both ARM ABIs and the changed compiled gameplay
scripts are present, with zero packaged `tests/` or `reports/` entries. The
committed AAB preset was restored byte-for-byte and no AAB was generated. ADB
found no connected device, so installation, touch feel, frame time, listening,
and physical-device acceptance are not claimed. Source commit/tag: `071d1ba` /
`reward-feedback-real-gems-v4-source`. Delivery tag
`reward-feedback-real-gems-v4` points to the manifest/provenance follow-up;
full artifact provenance is recorded in `BUILD_MANIFEST.md`.
