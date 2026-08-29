class_name GameConfig
extends RefCounted

const VIEWPORT_SIZE := Vector2(720.0, 1280.0)
## V1 economy sink. The controller performs the deduction and save atomically;
## presentation reads this one value and never owns economy rules.
const NEXT_GEM_REROLL_COST := 100
## Retention/economy V1. Keep the relative hierarchy intentional: switching
## is cheapest, extra shots is medium, one safe continuation is expensive, and
## Skip remains the highest escape hatch.
const EXTRA_SHOTS_AMOUNT := 5
const EXTRA_SHOTS_COST := 300
const CONTINUE_COST := 500
const MAX_COIN_CONTINUES_PER_ATTEMPT := 1
## Second economy sink. Skipping jumps straight to the next level (no win
## screen, no interstitial, no level-complete reward) for a flat coin cost.
const SKIP_LEVEL_COST := 800
## Powers V1. Prices and ownership live in PowerInventoryService; only the
## in-play tuning belongs here. Every value is deliberately bounded so a power
## rescues one situation rather than solving the level: the board is 720x714,
## so a 165px bomb reaches roughly a two-gem ring around the tap and can never
## approach a full clear, and the cap holds even where gems are packed tightest.
const POWER_BOMB_RADIUS := 165.0 # safe readable range 140-190
const POWER_BOMB_MAX_CLEARED := 8
## Survivors just outside the blast are shoved outward so the hole reads as an
## explosion rather than gems silently vanishing. Reuses the target-merge blast
## feel at a lower impulse because this clears rather than only pushes.
const POWER_BOMB_PUSH_RADIUS := 260.0
const POWER_BOMB_PUSH_IMPULSE := 420.0
## Magnet pulls same-tier gems toward the current gem to set up one merge. The
## radius is wider than the bomb's because it only attracts; the speed is capped
## so pulled gems still collide and settle through the normal simulation.
const POWER_MAGNET_RADIUS := 300.0 # safe readable range 240-340
const POWER_MAGNET_MAX_ATTRACTED := 4
const POWER_MAGNET_PULL_SPEED := 900.0
## How long the magnetised gem keeps its field after the power is spent. Long
## enough to cover the shot and the settle that follows it, short enough that
## it cannot quietly reshape the board for the rest of the level.
const POWER_MAGNET_DURATION := 2.6
## Hammer destroys exactly one tapped gem. The pick radius is generous because a
## thumb is imprecise, but it never exceeds one gem's spacing so the wrong gem
## is not destroyed by a near miss.
const POWER_HAMMER_PICK_RADIUS := 64.0
## Authoritative table layout. The supplied table is a trapezoid, so the same
## rail model is consumed by Sprite2D placement, collision containment, drag
## clamps, launcher spawn, and danger-line drawing.
## The reference composition reserves a compact utility row plus a visible
## Target/path stack above the table. The table remains the dominant center
## surface and every visual/physics landmark is transformed together.
## Whole playfield lifted 64px versus the original composition (top/bottom
## table bounds, texture center, board, danger line, and launch point all
## shifted together by the same amount) to give the prominent Switch Gem
## action (with its text caption) a dedicated space below the table,
## at the user's explicit repeated request. This is a pure vertical
## translation: every relative distance, rail width, and physics spacing is
## unchanged. 64px is the largest shift that still keeps the objective
## stack's designed 20px-minimum gap to the table above (see
## UiDesignSystemType.OBJECTIVE_TABLE_GAP_MIN and
## run_ui_scale_layout_tests.gd's "must sit visibly above the table" guard);
## the sink-button row below clamps itself to whatever space that leaves.
const TABLE_LAYOUT_BASE_TOP := 356.0
const TABLE_LAYOUT_BASE_BOTTOM := 1151.0
const TABLE_TEXTURE_CENTER := Vector2(360.0, 780.0)
const TABLE_TEXTURE_SIZE := Vector2(720.0, 1280.0)
const TABLE_TEXTURE_RENDER_SCALE := Vector2(0.9583333, 0.752)
const BOARD_LEFT := 0.0
const BOARD_RIGHT := 720.0
const TABLE_BOTTOM_ALIGNMENT_DELTA_Y := 0.0
const BOARD_TOP := 390.0
const BOARD_BOTTOM := 1104.0
const TABLE_INNER_LEFT_TOP := 140.0
const TABLE_INNER_LEFT_BOTTOM := 58.0
const TABLE_INNER_RIGHT_TOP := 580.0
const TABLE_INNER_RIGHT_BOTTOM := 662.0
const DANGER_LINE_Y := 951.0
const DANGER_LINE_COLOR := Color("e85f52")
## Presentation-only guide/warning values. They never enter input, collision,
## overflow detection, timing, or solver decisions.
const AIM_GUIDE_WIDTH := 2.0
const AIM_GUIDE_ALPHA := 0.44
const AIM_GUIDE_TOUCH_HALF_WIDTH := 28.0
const DANGER_WARNING_NEAR_DISTANCE := 76.0
const DANGER_WARNING_PULSE_HZ := 1.65
const LAUNCH_Y := 1031.0
## Expanded portrait screens distribute extra height between the scenery above
## the table and a bounded vertical table stretch. The complete table model is
## transformed together; HUD geometry remains presentation-only and independent.
const TABLE_EXTRA_TOP_OFFSET_SHARE := 0.40
const TABLE_TALL_SCALE_MAX := 1.22
const TABLE_TALL_SCALE_REFERENCE_EXTRA := 320.0
static var portrait_bottom_offset_y := 0.0
static var viewport_center_offset_x := 0.0
static var table_vertical_scale_y := 1.0
## Largest active gameplay radius. The L6-L8 objective sequence uses a larger
## physical/readable step while L1-L5 retain the established launch ladder.
const PIECE_RADIUS := 66.0
## One authoritative radius drives both the alpha-trimmed visual body and its
## simple circle collider. Gold rims, glows, shadows and transparent texture
## padding never add collision size. L9-L18 remain outside the current level
## and retain their earlier 42px fallback. Values stay fixed for a lifetime.
const GEM_COLLISION_RADIUS := {1: 36.0, 2: 39.0, 3: 42.0, 4: 45.0, 5: 48.0, 6: 56.0, 7: 61.0, 8: 66.0, 9: 42.0, 10: 42.0, 11: 42.0, 12: 42.0, 13: 42.0, 14: 42.0, 15: 42.0, 16: 42.0, 17: 42.0, 18: 42.0, 19: 42.0, 20: 42.0}
## Runtime visual-body expansion maps the opaque gem body to the stable
## simple collider; it is a visual calibration only.
## Body-only textures are trimmed independently from their former baked
## shadows/glows. Their scale maps visible body edges directly to colliders.
## Derived at asset-preparation time from the solid alpha body. The tiny
## expansion maps the visible body edge to its existing fixed circle collider;
## it does not resize a piece or alter simulation values during play.
const GEM_VISUAL_BODY_SCALE := {1: 1.008, 2: 1.008, 3: 1.008, 4: 1.008, 5: 1.008, 6: 1.008, 7: 1.008, 8: 1.008, 9: 1.008, 10: 1.008, 11: 1.008, 12: 1.008, 13: 1.008, 14: 1.008, 15: 1.008, 16: 1.008, 17: 1.008, 18: 1.008, 19: 1.008, 20: 1.008}
## Presentation-only lower shadows. All 18 tiers use the same calibrated
## placement so a shadow cannot be mistaken for a physical body or contact.
const GEM_SHADOW_OFFSET := {1: Vector2(5.0, 30.0), 2: Vector2(5.0, 32.0), 3: Vector2(5.0, 34.0), 4: Vector2(5.0, 36.0), 5: Vector2(5.0, 38.0), 6: Vector2(5.0, 40.0), 7: Vector2(5.0, 42.0), 8: Vector2(5.0, 44.0), 9: Vector2(5.0, 34.0), 10: Vector2(5.0, 34.0), 11: Vector2(5.0, 34.0), 12: Vector2(5.0, 34.0), 13: Vector2(5.0, 34.0), 14: Vector2(5.0, 34.0), 15: Vector2(5.0, 34.0), 16: Vector2(5.0, 34.0), 17: Vector2(5.0, 34.0), 18: Vector2(5.0, 34.0), 19: Vector2(5.0, 34.0), 20: Vector2(5.0, 34.0)}
const GEM_SHADOW_OPACITY := {1: 0.50, 2: 0.50, 3: 0.50, 4: 0.50, 5: 0.50, 6: 0.50, 7: 0.50, 8: 0.50, 9: 0.50, 10: 0.50, 11: 0.50, 12: 0.50, 13: 0.50, 14: 0.50, 15: 0.50, 16: 0.50, 17: 0.50, 18: 0.50, 19: 0.50, 20: 0.50}
const GEM_SHADOW_WIDTH_MULTIPLIER := 0.98
const GEM_SHADOW_HEIGHT_MULTIPLIER := 0.42
const VISIBLE_CONTACT_TOLERANCE := 2.0
## One conservative table-depth scale is shared by every gem's visual root and
## simulation radius. It keeps rendered contact, rail containment, and merge
## eligibility in the same coordinate system.
const GEM_PERSPECTIVE_SCALE_BACK := 0.85
const GEM_PERSPECTIVE_SCALE_FRONT := 1.00
## CanvasItem z-index is bounded by Godot. Eight stable tie slots are enough
## for the visually indistinguishable equal-Y bucket; creation order remains
## the stable fallback for IDs that share a slot.
const GEM_VISUAL_Z_BUCKETS := 500
const GEM_VISUAL_Z_TIE_STRIDE := 8
# Gameplay balance v1 — all feel values live here. Keep simulation delta-based.
# The default/range notes are the approved safe tuning envelope for this prototype.
const DRAG_HIT_RADIUS_MULTIPLIER := 1.8 # default 1.8; safe 1.5–2.0
const LAUNCH_SPEED := 1200.0 # fast-feel pass: top of previously approved 1120–1200 range
const VELOCITY_DAMPING_PER_SECOND := 195.0 # quicker settle after the faster launch; prior range 175–205
const SLEEP_SPEED := 10.0 # snappier handoff while staying inside prior stable-settle range 8–11
const SIDE_WALL_RESTITUTION := 0.24 # contained redirection range 0.20–0.28
const TOP_WALL_RESTITUTION := 0.22 # visible but controlled rebound range 0.18–0.25
const BOTTOM_WALL_RESTITUTION := 0.12 # containment-only range 0.10–0.14
## True coefficient of restitution used by the equal-mass impulse equation.
## This is intentionally a soft bounce: contact separates instead of retaining
## inward velocity, without turning the table into frictionless billiards.
const COLLISION_RESTITUTION := 0.30 # lively separating response range 0.26–0.34
const COLLISION_TANGENTIAL_FRICTION := 0.07 # applied once per approaching impact; range 0.05–0.10
const MAX_PIECE_SPEED := 1200.0 # containment guard; preserves natural launch/collision speed
## A visually touching trimmed gem body may be up to two design pixels beyond
## the simple circular collider. Treat that calibrated visible-contact band as
## a confirmed contact so matching gems cannot remain stuck while touching.
const CONTACT_EPSILON := VISIBLE_CONTACT_TOLERANCE # calibrated range 0.20–2.0
const SEPARATION_EPSILON := 0.02 # keeps post-contact correction inside narrow merge tolerance
## Bounded physics-only stabilization for dense piles. This removes residual
## visual penetration without changing radii or merge eligibility.
const COLLISION_SEPARATION_PASSES := 3
const MAX_SIMULATION_SUBSTEPS := 8
const MAX_SUBSTEP_RADIUS_FRACTION := 0.45 # swept-step guard; never changes contact distance
## Presentation-only reward cadence. Physics, colliders, contact eligibility,
## momentum, score values, and launcher handoff are intentionally unaffected.
## Reward feedback v3 keeps one authoritative reward hierarchy:
## collision < normal merge < combo merge < final target < level complete.
## Every value below is a visual timeline key expressed in seconds.
const MERGE_PRESENTATION_DURATION := 0.42
const MERGE_CONTACT_COMPRESSION_DURATION := 0.035
const MERGE_CONTACT_COMPRESSION_SCALE := Vector2(1.04, 0.92)
const MERGE_SOURCE_PULL_START := 0.035
const MERGE_SOURCE_PULL_DURATION := 0.080
const MERGE_SOURCE_END_SCALE := 0.80
const MERGE_REVEAL_START := 0.12
const MERGE_RESULT_START_SCALE := 0.65
const MERGE_RESULT_POP_SCALE := 1.24
const MERGE_RESULT_POP_DURATION := 0.09
const MERGE_REVEAL_SOUND_AT := 0.12
## Hit-stop freezes only the pieces of the confirmed merge. The rest of the
## board keeps stepping, so this is a bounded per-body pause, not a game freeze.
const MERGE_HITSTOP_DURATION := 0.03
const COMBO_1_HITSTOP_DURATION := 0.035
const COMBO_2_HITSTOP_DURATION := 0.04
const COMBO_3_HITSTOP_DURATION := 0.045
const COMBO_4_HITSTOP_DURATION := 0.05
const TARGET_HITSTOP_DURATION := 0.05
const MERGE_RADIAL_DURATION := 0.18
const MERGE_RADIAL_START_SCALE := 0.30
const MERGE_RADIAL_END_SCALE := 1.30
const MERGE_RADIAL_INTENSITY_NORMAL := 0.35
const MERGE_RADIAL_INTENSITY_COMBO_1 := 0.45
const MERGE_RADIAL_INTENSITY_COMBO_2 := 0.60
const MERGE_RADIAL_INTENSITY_COMBO_3 := 0.80
const MERGE_RADIAL_INTENSITY_COMBO_4 := 0.92
const MERGE_RADIAL_INTENSITY_TARGET := 0.90
const MERGE_RADIAL_INTENSITY_FINAL_TARGET := 1.00
## Result-scale keyframes are `[time_from_merge, uniform_scale]` pairs applied
## after `reveal`. They are presentation-only and never touch collision radius.
const MERGE_TIMELINE_NORMAL := {
	"hitstop": MERGE_HITSTOP_DURATION,
	"pull_start": MERGE_SOURCE_PULL_START,
	"pull_duration": MERGE_SOURCE_PULL_DURATION,
	"reveal": MERGE_REVEAL_START,
	"duration": MERGE_PRESENTATION_DURATION,
	"sound_at": MERGE_REVEAL_SOUND_AT,
	"ring_at": 0.12,
	"ring_scale": 1.0,
	"radial_intensity": MERGE_RADIAL_INTENSITY_NORMAL,
	"start_scale": MERGE_RESULT_START_SCALE,
	"scale_keys": [[0.21, 1.24], [0.29, 0.93], [0.365, 1.05], [0.42, 1.0]],
	"pitch": 1.0,
}
const MERGE_TIMELINE_COMBO_1 := {
	"hitstop": COMBO_1_HITSTOP_DURATION,
	"pull_start": MERGE_SOURCE_PULL_START,
	"pull_duration": MERGE_SOURCE_PULL_DURATION,
	"reveal": MERGE_REVEAL_START,
	"duration": MERGE_PRESENTATION_DURATION,
	"sound_at": MERGE_REVEAL_SOUND_AT,
	"ring_at": 0.12,
	"ring_scale": 1.14,
	"radial_intensity": MERGE_RADIAL_INTENSITY_COMBO_1,
	"start_scale": 0.65,
	"scale_keys": [[0.21, 1.27], [0.29, 0.93], [0.365, 1.05], [0.42, 1.0]],
	"pitch": 1.06,
}
const MERGE_TIMELINE_COMBO_2 := {
	"hitstop": COMBO_2_HITSTOP_DURATION,
	"pull_start": MERGE_SOURCE_PULL_START,
	"pull_duration": MERGE_SOURCE_PULL_DURATION,
	"reveal": MERGE_REVEAL_START,
	"duration": MERGE_PRESENTATION_DURATION,
	"sound_at": MERGE_REVEAL_SOUND_AT,
	"ring_at": 0.12,
	"ring_scale": 1.22,
	"radial_intensity": MERGE_RADIAL_INTENSITY_COMBO_2,
	"start_scale": 0.64,
	"scale_keys": [[0.21, 1.30], [0.29, 0.93], [0.365, 1.05], [0.42, 1.0]],
	"pitch": 1.12,
}
const MERGE_TIMELINE_COMBO_3 := {
	"hitstop": COMBO_3_HITSTOP_DURATION,
	"pull_start": MERGE_SOURCE_PULL_START,
	"pull_duration": MERGE_SOURCE_PULL_DURATION,
	"reveal": MERGE_REVEAL_START,
	"duration": MERGE_PRESENTATION_DURATION,
	"sound_at": MERGE_REVEAL_SOUND_AT,
	"ring_at": 0.12,
	"ring_scale": 1.34,
	"radial_intensity": MERGE_RADIAL_INTENSITY_COMBO_3,
	"start_scale": 0.62,
	"scale_keys": [[0.21, 1.34], [0.29, 0.92], [0.365, 1.06], [0.42, 1.0]],
	"pitch": 1.18,
}
const MERGE_TIMELINE_COMBO_4 := {
	"hitstop": COMBO_4_HITSTOP_DURATION,
	"pull_start": MERGE_SOURCE_PULL_START,
	"pull_duration": MERGE_SOURCE_PULL_DURATION,
	"reveal": MERGE_REVEAL_START,
	"duration": MERGE_PRESENTATION_DURATION,
	"sound_at": MERGE_REVEAL_SOUND_AT,
	"ring_at": 0.12,
	"ring_scale": 1.46,
	"radial_intensity": MERGE_RADIAL_INTENSITY_COMBO_4,
	"start_scale": 0.60,
	"scale_keys": [[0.21, 1.38], [0.29, 0.91], [0.365, 1.07], [0.42, 1.0]],
	"pitch": 1.24,
}
const MERGE_TIMELINE_TARGET := {
	"hitstop": TARGET_HITSTOP_DURATION,
	"pull_start": 0.05,
	"pull_duration": 0.08,
	"reveal": 0.10,
	"duration": 0.42,
	"sound_at": 0.10,
	"ring_at": 0.10,
	"ring_scale": 1.38,
	"ring_layers": 5,
	"ring_segments": 52,
	"radial_intensity": MERGE_RADIAL_INTENSITY_TARGET,
	"start_scale": 0.62,
	"scale_keys": [[0.18, 1.32], [0.27, 0.96], [0.35, 1.08], [0.42, 1.0]],
	"pitch": 1.20,
}
## Final-target Phase A uses the same readable merge-first cadence as every
## target, with only a modest extra peak and ring scale.
const MERGE_TIMELINE_FINAL_TARGET := {
	"hitstop": TARGET_HITSTOP_DURATION,
	"pull_start": 0.05,
	"pull_duration": 0.07,
	"reveal": 0.10,
	"duration": 0.42,
	"sound_at": 0.10,
	"ring_at": 0.10,
	"ring_scale": 1.58,
	"ring_layers": 5,
	"ring_segments": 52,
	"radial_intensity": MERGE_RADIAL_INTENSITY_FINAL_TARGET,
	"start_scale": 0.60,
	"scale_keys": [[0.18, 1.40], [0.27, 0.96], [0.35, 1.10], [0.42, 1.0]],
	"pitch": 1.28,
}
## Every successful merge produces persistent gameplay pieces. The controller
## creates every sibling on the result reveal frame; BoardSimulation moves and
## collides them immediately from that same frame onward.
const BONUS_GEMS_NORMAL := 1
const BONUS_GEMS_COMBO_1 := 1
const BONUS_GEMS_COMBO_2 := 2
const BONUS_GEMS_COMBO_3 := 2
const BONUS_GEMS_COMBO_4_PLUS := 3
const BONUS_TIER_WEIGHTS := [0.50, 0.30, 0.20]
const BONUS_SPAWN_IMPULSE := 135.0
const BONUS_SPAWN_CLEARANCE := 3.0
const BONUS_MERGE_GRACE_MS := 650
## A shot can mint at most three real reward pieces, and delayed rewards never
## raise the live population beyond this cap. These bounds terminate unattended
## reward cascades without changing ordinary merge eligibility.
const BONUS_GEM_BUDGET_PER_SHOT := 3
const BONUS_BOARD_PIECE_CAP := 24
const BONUS_REWARD_MAX_CHAIN_DEPTH := 2
## Bonus siblings reuse the confirmed result's scale timeline. Normal and combo
## results settle from reveal to 1.0 in exactly this interval; final-target
## siblings use the remaining time to settle after their short shared phase.
const BONUS_VISUAL_BURST_DURATION := MERGE_PRESENTATION_DURATION - MERGE_REVEAL_START
const BONUS_SPAWN_DIRECTIONS_1 := [-90.0]
const BONUS_SPAWN_DIRECTIONS_2 := [-128.0, -52.0]
const BONUS_SPAWN_DIRECTIONS_3 := [-138.0, -90.0, -42.0]
## Combo labels for chain merges produced by one shot.
const COMBO_LABEL_POP_DURATION := 0.06
const COMBO_LABEL_SETTLE_DURATION := 0.10
const COMBO_LABEL_DURATION := 1.10
const COMBO_LABEL_RISE := 20.0
const COMBO_LABEL_OFFSET_Y := -58.0
const TARGET_ACHIEVED_LABEL_DURATION := 1.40
## Target collection starts only after the 420 ms merge feedback plus a readable
## 120 ms table-position hold. All three targets share this exact cadence.
const TARGET_COLLECTION_OVERLAP_START := 0.54
const FINAL_TARGET_COLLECTION_OVERLAP_START := TARGET_COLLECTION_OVERLAP_START
const TARGET_VISUAL_SCALE := 1.18
## A confirmed objective merge applies this single, deterministic radial nudge
## to other settled/live board gems. It never changes contact or merge rules.
const TARGET_MERGE_BLAST_RADIUS := 220.0 # safe readable range 180-240
const TARGET_MERGE_BLAST_IMPULSE := 78.0 # slight nudge range 60-90
const TARGET_MERGE_BLAST_EDGE_STRENGTH := 0.28
const MERGE_PULSE_SCALE := 1.22
const COLLISION_VISUAL_DURATION := 0.11
const COLLISION_VISUAL_MAX_COMPRESSION := 0.055
const COLLISION_VISUAL_COOLDOWN := 0.10
const SCORE_POPUP_DURATION := 0.46
const SCORE_POPUP_RISE := 36.0
const MAJOR_REWARD_TIER := 6
const MAJOR_MERGE_EFFECT_DURATION := 0.36
const MAJOR_SCORE_POPUP_DURATION := 0.78
const MAJOR_SCORE_POPUP_RISE := 58.0
const MAJOR_MERGE_EFFECT_SCALE := 1.18
const MAJOR_MERGE_SPARK_COUNT := 12
## The supplied reference visibly uses four rigid coin tokens. They form one
## compact cluster, then travel as one readable staggered group to the HUD.
const COIN_BURST_COUNT := 4
const MAJOR_COIN_BURST_COUNT := 4
const COIN_BURST_DURATION := 0.12
const COIN_REWARD_START_DELAY := 0.26
const TARGET_COIN_TABLE_HOLD := 1.20
const COIN_FLIGHT_DURATION := 0.55
const MAJOR_COIN_FLIGHT_DURATION := 0.62
const COIN_FLIGHT_STAGGER := 0.08
const COIN_SPAWN_STAGGER := 0.08
const COIN_BURST_RADIUS := 48.0
const MAJOR_COIN_BURST_RADIUS := 52.0
const COIN_DRAW_RADIUS := 17.0
const TARGET_COIN_SHADOW_OPACITY := 0.24
const TARGET_COIN_SHADOW_OFFSET := Vector2(3.0, 5.0)
const COIN_COUNTER_PULSE_DURATION := 0.18
const COIN_EFFECT_LIMIT := 32
const COIN_HUD_FALLBACK_DESTINATION := Vector2(92.0, 78.0)
const TARGET_COLLECTION_DURATION := 0.70
const TARGET_COLLECTION_CONFIRM_DURATION := 0.10
const TARGET_COLLECTION_TRAVEL_DURATION := 0.52
const TARGET_COLLECTION_FADE_START := 0.90
const TARGET_COLLECTION_POP_SCALE := 1.24
const TARGET_PANEL_PULSE_DURATION := 0.22
## Final-target hero sequence. Every value is measured from the hero start,
## which is `FINAL_TARGET_COLLECTION_OVERLAP_START` (180 ms) after the merge.
## Phase B travel -> Phase C hold -> Phase D flight -> Phase E panel impact.
const HERO_TRAVEL_DURATION := 0.25
const HERO_TRAVEL_START_SCALE := 1.0
const HERO_TRAVEL_END_SCALE := 1.0
const HERO_HOLD_DURATION := 1.05
const HERO_HOLD_RISE_DURATION := 0.12
const HERO_HOLD_PEAK_SCALE := 1.45
const HERO_HOLD_SETTLE_DURATION := 0.08
const HERO_HOLD_SCALE := 1.28
const HERO_HOLD_BREATH_SCALE := 1.31
const HERO_HOLD_BREATH_HZ := 1.15
## Measured from the start of the hero hold (T + 430 ms), so the caption lands
## about 530 ms after the merge completed.
const HERO_LABEL_AT := 0.10
const HERO_LABEL_DURATION := 1.30
const HERO_LABEL_TEXT := "TARGET COMPLETE!"
const HERO_LAUNCH_ANTICIPATION_DURATION := 0.07
const HERO_LAUNCH_ANTICIPATION_DISTANCE := 8.0
const HERO_LAUNCH_ANTICIPATION_SCALE := 1.35
const HERO_FLIGHT_DURATION := 0.31
const HERO_FLIGHT_END_SCALE := 0.35
const HERO_FLIGHT_TILT_DEGREES := 10.0
const HERO_PANEL_ANTICIPATION_LEAD := 0.08
const HERO_PANEL_ANTICIPATION_SCALE := 0.92
const HERO_PANEL_IMPACT_SCALE := 1.16
const HERO_PANEL_RECOIL_SCALE := 0.97
const HERO_PANEL_IMPACT_RISE := 0.09
const HERO_PANEL_IMPACT_RECOIL := 0.07
const HERO_PANEL_IMPACT_SETTLE := 0.08
const HERO_PANEL_SPARKLE_COUNT := 6
const HERO_PANEL_SPARKLE_DURATION := 0.27
const REWARD_AMOUNT_DURATION := 0.72
const REWARD_AMOUNT_START_SCALE := 0.55
const REWARD_AMOUNT_PEAK_SCALE := 1.20
## Level-complete coin reward. These sprites are cosmetic reward objects: they
## never enter the simulation, contact capture, or merge eligibility.
const LEVEL_REWARD_COIN_COUNT := 4
const LEVEL_REWARD_COIN_WAVE_SIZE := 4
const LEVEL_REWARD_COIN_WAVE_STAGGER := 0.035
const LEVEL_REWARD_COIN_SPAWN_AT := 1.85
const LEVEL_REWARD_COIN_LAND_DURATION := 0.22
const LEVEL_REWARD_COIN_TABLE_HOLD := 1.00
const LEVEL_REWARD_COIN_COLLECT_WAVE_SIZES := [2, 2, 3, 3, 2]
const LEVEL_REWARD_COIN_COLLECT_WAVE_DELAYS := [0.09, 0.075, 0.06, 0.05, 0.04, 0.03, 0.025]
const LEVEL_REWARD_COIN_FLIGHT_DURATION := 0.30
const LEVEL_REWARD_COIN_SCATTER_HALF_WIDTH := 0.38
const LEVEL_REWARD_COIN_SCATTER_HALF_HEIGHT := 82.0
const LEVEL_REWARD_COIN_IDLE_WOBBLE := 0.7
const LEVEL_REWARD_COIN_DRAW_RADIUS := 19.0
const LEVEL_REWARD_COIN_SHADOW_OPACITY := 0.24
const LEVEL_REWARD_COIN_SHADOW_OFFSET := Vector2(3.0, 5.0)
const COIN_COUNTER_WAVE_PUNCH_SCALE := 1.06
const COIN_COUNTER_FINAL_PUNCH_SCALE := 1.14
const COIN_COUNTER_FINAL_RECOIL_SCALE := 0.96
## Coins begin collecting exactly one landing plus one deliberate table hold
## after the first wave lands, so the player registers the whole pile first.
static func level_reward_collect_start() -> float:
	return LEVEL_REWARD_COIN_LAND_DURATION \
		+ float(level_reward_spawn_wave_count() - 1) * LEVEL_REWARD_COIN_WAVE_STAGGER \
		+ LEVEL_REWARD_COIN_TABLE_HOLD


static func target_coin_flight_start(flight_rank: int, coin_count: int) -> float:
	# Wait until the final staggered token has landed, then hold the whole target
	# reward group on the table before any member begins its HUD flight.
	return COIN_BURST_DURATION \
		+ float(maxi(0, coin_count - 1)) * COIN_SPAWN_STAGGER \
		+ TARGET_COIN_TABLE_HOLD \
		+ float(flight_rank) * COIN_FLIGHT_STAGGER


static func level_reward_spawn_wave_count() -> int:
	return int(ceil(float(LEVEL_REWARD_COIN_COUNT) / float(LEVEL_REWARD_COIN_WAVE_SIZE)))


static func level_reward_collect_plan(count: int = LEVEL_REWARD_COIN_COUNT) -> Array[Dictionary]:
	var sizes: Array[int] = []
	var allocated := 0
	for configured_size in LEVEL_REWARD_COIN_COLLECT_WAVE_SIZES:
		if allocated >= count:
			break
		var size := mini(int(configured_size), count - allocated)
		sizes.append(size)
		allocated += size
	var remaining := count - allocated
	if remaining > 5:
		sizes.append(remaining - 5)
		sizes.append(5)
	elif remaining > 0:
		sizes.append(remaining)
	var plan: Array[Dictionary] = []
	var index := 0
	var at := level_reward_collect_start()
	for wave in range(sizes.size()):
		for _slot in range(sizes[wave]):
			plan.append({"index": index, "wave": wave, "at": at})
			index += 1
		if wave < sizes.size() - 1:
			at += float(LEVEL_REWARD_COIN_COLLECT_WAVE_DELAYS[mini(wave, LEVEL_REWARD_COIN_COLLECT_WAVE_DELAYS.size() - 1)])
	return plan


static func level_reward_wave_count() -> int:
	var plan := level_reward_collect_plan()
	return 0 if plan.is_empty() else int(plan.back().wave) + 1


static func level_reward_total_duration() -> float:
	var plan := level_reward_collect_plan()
	var last_collect_at := level_reward_collect_start() if plan.is_empty() else float(plan.back().at)
	return last_collect_at + LEVEL_REWARD_COIN_FLIGHT_DURATION


## Total hero-to-settled celebration budget, used by tests and the task report.
static func final_celebration_duration() -> float:
	return LEVEL_REWARD_COIN_SPAWN_AT + level_reward_total_duration() + WIN_PRESENTATION_HOLD


static func merge_timeline(depth: int, final_target: bool, target_completed: bool = false) -> Dictionary:
	if final_target:
		return MERGE_TIMELINE_FINAL_TARGET
	if target_completed:
		return MERGE_TIMELINE_TARGET
	if depth <= 0:
		return MERGE_TIMELINE_NORMAL
	if depth == 1:
		return MERGE_TIMELINE_COMBO_1
	if depth == 2:
		return MERGE_TIMELINE_COMBO_2
	if depth == 3:
		return MERGE_TIMELINE_COMBO_3
	return MERGE_TIMELINE_COMBO_4


static func bonus_gem_count(depth: int) -> int:
	if depth <= 0:
		return BONUS_GEMS_NORMAL
	if depth == 1:
		return BONUS_GEMS_COMBO_1
	if depth == 2:
		return BONUS_GEMS_COMBO_2
	if depth == 3:
		return BONUS_GEMS_COMBO_3
	return BONUS_GEMS_COMBO_4_PLUS


static func bonus_spawn_directions(count: int) -> Array:
	if count <= 1:
		return BONUS_SPAWN_DIRECTIONS_1
	if count == 2:
		return BONUS_SPAWN_DIRECTIONS_2
	return BONUS_SPAWN_DIRECTIONS_3


## Chain labels stay proportional to the achievement. Low chains never borrow
## the rare wording reserved for deep chains.
static func combo_label_text(depth: int) -> String:
	if depth <= 0:
		return ""
	if depth == 4:
		return "COMBO 4 — AMAZING!"
	if depth >= 5:
		return "COMBO %d — PERFECT!" % depth
	if depth >= 3:
		return "COMBO %d!" % depth
	return "COMBO %d" % depth
const TARGET_SWAP_START_DELAY := 0.12
const TARGET_SWAP_OUTGOING_FADE_DURATION := 0.10
const TARGET_SWAP_GAP_DURATION := 0.02
const TARGET_SWAP_INCOMING_FADE_DURATION := 0.12
const TARGET_SWAP_OUTGOING_OFFSET := Vector2.ZERO
const TARGET_SWAP_INCOMING_OFFSET := Vector2.ZERO
const TARGET_SWAP_INCOMING_SCALE := 1.0
const PRESENTATION_EVENT_TRACE_LIMIT := 128
const MERGE_MOMENTUM_TRANSFER := 0.62 # bounded average of source momentum
const MERGE_MAX_SPAWN_SPEED := 420.0 # prevents an upgrade from shooting through a cluster
const CHAIN_PRESENTATION_STAGGER := 0.26 # readable visual cadence only; merge logic remains immediate
const NEXT_LAUNCHER_READY_DELAY := 0.02
## A released gem gives the launcher lane time to clear, then becomes a normal
## simulation body even if contacts keep it moving. This bounds replacement
## latency on crowded boards without changing any motion or collision value.
const LAUNCHER_HANDOFF_DELAY := 0.22
const MERGE_CHAIN_DEPTH_CAP := 6
const OVERLAY_BUTTON_RECT := Rect2(220.0, 770.0, 280.0, 64.0)
const OVERLAY_FADE_DURATION := 0.14
const RESULT_BACKDROP_OPACITY := 0.48
## Beat between the last collected reward coin and the Level Complete modal.
const WIN_PRESENTATION_HOLD := 0.18
## Rendering-only layout values. These never feed simulation or collision geometry.
## HUD measurements are in the fixed 720-wide design space, sampled from the
## supplied portrait reference: large SCORE left, five-ring ladder centered,
## and large NEXT right.  They are presentation-only.
const HUD_RECT := Rect2(24.0, 42.0, 672.0, 266.0)
const SCORE_PANEL_RECT := Rect2(38.0, 48.0, 174.0, 136.0)
const NEXT_PREVIEW_RECT := Rect2(510.0, 48.0, 178.0, 158.0)
const PROGRESSION_START_X := 252.0
const PROGRESSION_STEP_X := 56.0
const PROGRESSION_Y := 111.0
const PROGRESSION_SLOT_RADIUS := 23.0
const PROGRESSION_PREVIEW_BOUNDS := Vector2(37.0, 37.0)
const TARGET_PANEL_RECT := Rect2(253.0, 188.0, 214.0, 110.0)
const TARGET_HEADER_RECT := Rect2(262.0, 188.0, 196.0, 52.0)
const TARGET_BODY_RECT := Rect2(253.0, 222.0, 214.0, 74.0)
## The supplied L7/L8 artwork is intentionally allowed to use the generous
## cream portion of the GOAL card.  This is a presentation-only contain box:
## every source aspect ratio remains intact and no circular mask is applied.
const TARGET_PREVIEW_BOUNDS := Vector2(54.0, 50.0)
const RESTART_BUTTON_RECT := Rect2(472.0, 231.0, 138.0, 46.0)
const SETTINGS_BUTTON_RECT := Rect2(620.0, 206.0, 88.0, 88.0)
const TARGET_COLLECTION_DESTINATION := Vector2(360.0, 82.0)
const OVERLAY_RECT := Rect2(76.0, 398.0, 568.0, 484.0)
const SAFE_VISUAL_MARGIN := 24.0
const TARGET_LEVEL := 5
## Catalog-only extension. The baseline launcher, target, queue and HUD remain
## unchanged; this bounds merge eligibility for manually created higher tiers.
const MAX_GEM_LEVEL := 20
const DANGER_GRACE_DURATION := 0.75 # default 0.75 s; safe 0.65–0.90
## These values are awarded only when a confirmed result fulfills the active
## target. Ordinary merges advance the board without changing run coins.
const TARGET_COIN_REWARD_BY_RESULT_LEVEL := {
	2: 10,
	3: 25,
	4: 60,
	5: 150,
	6: 350,
	7: 800,
	8: 1800,
}
## Compatibility aliases for older tools. Production calls the target-named
## accessor so reward ownership stays explicit.
const MERGE_COIN_REWARD_BY_RESULT_LEVEL := TARGET_COIN_REWARD_BY_RESULT_LEVEL
const MERGE_SCORE_BY_RESULT_LEVEL := TARGET_COIN_REWARD_BY_RESULT_LEVEL
## Feedback routing is presentation-only. Only the explicitly approved contact,
## normal-merge, UI, and win events use supplied replacements; all other event
## identities retain the established procedural or approved supplied cues.
const AUDIO_MAX_CONCURRENT_PLAYERS := 5
const AUDIO_SAMPLE_RATE := 22050.0
## Slightly raised from 0.06 while remaining below the original 0.10 service
## gain and clearly below gameplay feedback.
const AUDIO_MUSIC_VOLUME := 0.07
const AUDIO_TONES := {
	"launch": {"frequency": 640.0, "duration": 0.075, "volume": 0.48, "brightness": 0.38, "fall": 0.78},
	"gem_contact": {"frequency": 1240.0, "duration": 0.055, "volume": 0.46, "brightness": 0.82, "fall": 0.64},
	"wall_contact": {"frequency": 760.0, "duration": 0.065, "volume": 0.32, "brightness": 0.34, "fall": 0.58},
	"normal_merge": {"volume": 0.70},
	"merge_2": {"frequency": 740.0, "duration": 0.14, "volume": 0.56, "brightness": 0.60, "fall": 1.16},
	"merge_3": {"frequency": 880.0, "duration": 0.15, "volume": 0.60, "brightness": 0.68, "fall": 1.20},
	"merge_4": {"frequency": 1046.0, "duration": 0.16, "volume": 0.65, "brightness": 0.76, "fall": 1.24},
	"merge_5": {"frequency": 1318.0, "duration": 0.19, "volume": 0.70, "brightness": 0.88, "fall": 1.30},
	"merge_6": {"frequency": 1480.0, "duration": 0.24, "volume": 0.75, "brightness": 0.90, "fall": 1.32},
	"merge_7": {"frequency": 1661.0, "duration": 0.27, "volume": 0.80, "brightness": 0.92, "fall": 1.34},
	"merge_8": {"frequency": 1760.0, "duration": 0.30, "volume": 0.85, "brightness": 0.94, "fall": 1.36},
	"chain": {"frequency": 1568.0, "duration": 0.13, "volume": 0.70, "brightness": 0.92, "fall": 1.24},
	# The hierarchy is merge < combo < mission complete < target complete. This
	# sits above chain (0.70) and below target_complete (0.78) so a claimed
	# objective never sounds bigger than a met target.
	"mission_complete": {"frequency": 880.0, "duration": 0.42, "volume": 0.74, "brightness": 0.54, "fall": 0.90},
	"target_collect": {"frequency": 1046.0, "duration": 0.48, "volume": 0.82, "brightness": 0.46, "fall": 0.82},
	"target_complete": {"volume": 0.78},
	"coin_tick": {"frequency": 1244.0, "duration": 0.09, "volume": 0.38, "brightness": 0.34, "fall": 1.18},
	# Powers V1. The charge cue leads every cinematic; each power then lands on
	# its own impact tone below, so the four stay distinguishable by ear alone.
	"power_charge": {"frequency": 520.0, "duration": 0.22, "volume": 0.52, "brightness": 0.44, "fall": 0.62},
	## Powers sit above a combo and below a completed target in the reward
	## hierarchy: a power is a deliberate spend, so it must land harder than an
	## incidental chain, but it is a means to an objective rather than one being
	## met. Bomb is the loudest and lowest because it clears the most.
	"power_switch": {"frequency": 1174.0, "duration": 0.16, "volume": 0.62, "brightness": 0.74, "fall": 1.22},
	"power_magnet": {"frequency": 988.0, "duration": 0.26, "volume": 0.68, "brightness": 0.58, "fall": 0.86},
	"power_hammer": {"frequency": 523.0, "duration": 0.20, "volume": 0.74, "brightness": 0.42, "fall": 1.40},
	"power_bomb": {"frequency": 392.0, "duration": 0.34, "volume": 0.86, "brightness": 0.30, "fall": 1.48},
	"coin_reward": {"volume": 0.72},
	"win": {"volume": 0.92},
	"button": {"volume": 0.32},
}
const GEM_CONTACT_SOUND_THRESHOLD := 170.0
const WALL_CONTACT_SOUND_THRESHOLD := 220.0
const CONTACT_SOUND_COOLDOWN := 0.075
const AUDIO_COOLDOWN_BY_EVENT := {
	"gem_contact": CONTACT_SOUND_COOLDOWN,
	"wall_contact": 0.11,
	"launch": 0.05,
	"normal_merge": 0.04,
	"merge_2": 0.04,
	"merge_3": 0.04,
	"merge_4": 0.03,
	"merge_5": 0.03,
	"merge_6": 0.03,
	"merge_7": 0.03,
	"merge_8": 0.03,
	"chain": 0.04,
	"target_collect": 0.16,
	"target_complete": 0.30,
	"mission_complete": 0.40,
	"coin_tick": 0.07,
	"coin_reward": 0.20,
	"win": 0.25,
	"button": 0.08,
	"power_switch": 0.12,
	"power_magnet": 0.12,
	"power_hammer": 0.12,
	"power_bomb": 0.15,
	"power_charge": 0.15,
}
const AUDIO_PITCH_RANGE_BY_EVENT := {
}
const AUDIO_PRIORITY_BY_EVENT := {
	"button": 10,
	"wall_contact": 20,
	"gem_contact": 30,
	"launch": 40,
	"target_collect": 50,
	"coin_tick": 55,
	"coin_reward": 60,
	"target_complete": 85,
	"normal_merge": 70,
	"merge_2": 70,
	"merge_3": 71,
	"merge_4": 72,
	"merge_5": 73,
	"merge_6": 74,
	"merge_7": 75,
	"merge_8": 76,
	"chain": 75,
	# Above chain, below target_complete (85): a completed mission must cut
	# through an incidental combo without ever masking a met target.
	"mission_complete": 83,
	# Between chain (75) and target_complete (85): a spent power must cut
	# through an incidental combo without ever masking a met objective.
	"power_switch": 78,
	"power_magnet": 79,
	"power_hammer": 80,
	"power_bomb": 82,
	# The charge cue leads the cinematic, so it must not outrank the impact it
	# is announcing.
	"power_charge": 77,
	"win": 100,
}
## Compatibility only for the retired extracted-event service. Production
## does not route these reference slices to movement, contact, or rewards.
const AUDIO_EVENT_VOLUME := {
	"launch": 1.0,
	"gem_contact": 1.0,
	"wall_contact": 0.86,
	"merge_reward": 1.0,
	"target_reward": 1.0,
	"fail": 0.86,
	"button": 0.78,
}
const HAPTICS_BY_EVENT := {
	"launch": {"duration_ms": 18, "amplitude": 0.22},
	"merge": {"duration_ms": 30, "amplitude": 0.48},
	"major_merge": {"duration_ms": 42, "amplitude": 0.66},
	"chain": {"duration_ms": 46, "amplitude": 0.72},
	"target_collect": {"duration_ms": 52, "amplitude": 0.78},
	"win": {"duration_ms": 90, "amplitude": 1.0},
	"fail": {"duration_ms": 70, "amplitude": 0.82},
	"coin_collect": {"duration_ms": 16, "amplitude": 0.20},
}

static func merge_coin_reward_for_result_level(level: int) -> int:
	return target_coin_reward_for_result_level(level)

static func target_coin_reward_for_result_level(level: int) -> int:
	return int(TARGET_COIN_REWARD_BY_RESULT_LEVEL.get(level, 0))

static func merge_score_for_result_level(level: int) -> int:
	return merge_coin_reward_for_result_level(level)

static func gem_name(level: int) -> String:
	return AssetCatalog.gem_name(level)

static func gem_collision_radius(level: int) -> float:
	return float(GEM_COLLISION_RADIUS.get(level, PIECE_RADIUS))

static func gem_color(level: int) -> Color:
	match level:
		1: return Color("f6ead0")
		2: return Color("20242d")
		3: return Color("20ae79")
		4: return Color("55c7e8")
		5: return Color("b7d93a")
		6: return Color("e8549a")
		7: return Color("c8324c")
		8: return Color("4f70dc")
		_: return Color.WHITE

static func configure_portrait_bottom(viewport_height: float) -> void:
	viewport_center_offset_x = 0.0
	_configure_table_height(viewport_height)


static func configure_viewport(viewport_size: Vector2) -> void:
	viewport_center_offset_x = maxf(0.0, (viewport_size.x - VIEWPORT_SIZE.x) * 0.5)
	_configure_table_height(viewport_size.y)


static func _configure_table_height(viewport_height: float) -> void:
	var extra_height := maxf(0.0, viewport_height - VIEWPORT_SIZE.y)
	portrait_bottom_offset_y = extra_height * TABLE_EXTRA_TOP_OFFSET_SHARE
	var tall_t := clampf(extra_height / TABLE_TALL_SCALE_REFERENCE_EXTRA, 0.0, 1.0)
	table_vertical_scale_y = lerpf(1.0, TABLE_TALL_SCALE_MAX, tall_t)


static func table_center_x() -> float:
	return TABLE_TEXTURE_CENTER.x + viewport_center_offset_x


static func table_texture_center() -> Vector2:
	return Vector2(table_center_x(), _table_y(TABLE_TEXTURE_CENTER.y))


static func table_texture_render_scale() -> Vector2:
	return Vector2(TABLE_TEXTURE_RENDER_SCALE.x, TABLE_TEXTURE_RENDER_SCALE.y * table_vertical_scale_y)


static func table_outer_top() -> float:
	return _table_y(TABLE_LAYOUT_BASE_TOP)


static func table_outer_bottom() -> float:
	return _table_y(TABLE_LAYOUT_BASE_BOTTOM)

static func board_top() -> float:
	return _table_y(BOARD_TOP)

static func board_bottom() -> float:
	return _table_y(BOARD_BOTTOM)

static func danger_line_y() -> float:
	return _table_y(DANGER_LINE_Y)

static func launch_y() -> float:
	return _table_y(LAUNCH_Y)


static func _table_y(base_y: float) -> float:
	return TABLE_LAYOUT_BASE_TOP + portrait_bottom_offset_y + (base_y - TABLE_LAYOUT_BASE_TOP) * table_vertical_scale_y

static func table_interpolation(y_position: float) -> float:
	return inverse_lerp(board_top(), board_bottom(), clampf(y_position, board_top(), board_bottom()))

static func gem_perspective_scale_at(y_position: float) -> float:
	return lerpf(GEM_PERSPECTIVE_SCALE_BACK, GEM_PERSPECTIVE_SCALE_FRONT, table_interpolation(y_position))

static func gem_visual_scale_at(_level: int, y_position: float) -> float:
	return gem_perspective_scale_at(y_position)

static func gem_visual_z_index(piece_id: int, y_position: float) -> int:
	# Larger local Y is closer to the player and must draw above smaller local Y.
	# The stable piece ID breaks exact-Y ties without allocating/reparenting nodes.
	var y_bucket := int(round(table_interpolation(y_position) * GEM_VISUAL_Z_BUCKETS))
	return y_bucket * GEM_VISUAL_Z_TIE_STRIDE + posmod(piece_id, GEM_VISUAL_Z_TIE_STRIDE)

static func table_left_at(y_position: float) -> float:
	return viewport_center_offset_x + lerpf(TABLE_INNER_LEFT_TOP, TABLE_INNER_LEFT_BOTTOM, table_interpolation(y_position))

static func table_right_at(y_position: float) -> float:
	return viewport_center_offset_x + lerpf(TABLE_INNER_RIGHT_TOP, TABLE_INNER_RIGHT_BOTTOM, table_interpolation(y_position))

static func table_playable_width_at(y_position: float) -> float:
	return table_right_at(y_position) - table_left_at(y_position)

static func launcher_drag_x(requested_x: float, y_position: float, radius: float) -> float:
	return clampf(requested_x, table_left_at(y_position) + radius, table_right_at(y_position) - radius)

static func aim_guide_contains(pointer: Vector2, active_position: Vector2, active_radius: float) -> bool:
	var lane_top := vertical_lane_top_y(active_position.x, 5.0)
	var start_y := lane_top + 10.0
	var finish_y := active_position.y - active_radius - 10.0
	if start_y >= finish_y - 8.0:
		return false
	return absf(pointer.x - active_position.x) <= AIM_GUIDE_TOUCH_HALF_WIDTH and pointer.y >= start_y and pointer.y <= finish_y


static func vertical_lane_top_y(x_position: float, radius: float = 0.0) -> float:
	# Find the first vertical point where the requested X (plus its optional
	# body margin) fits inside both sloped rails. Aim guides and launcher lanes
	# use this same authoritative geometry instead of escaping through the top.
	var top := board_top()
	var bottom := board_bottom()
	var left_top := table_left_at(top) + radius
	var right_top := table_right_at(top) - radius
	if x_position >= left_top and x_position <= right_top:
		return top
	var denominator := TABLE_INNER_LEFT_TOP - TABLE_INNER_LEFT_BOTTOM
	if x_position < left_top:
		var left_t := (TABLE_INNER_LEFT_TOP + viewport_center_offset_x + radius - x_position) / maxf(0.001, denominator)
		return lerpf(top, bottom, clampf(left_t, 0.0, 1.0))
	var right_t := (x_position - (TABLE_INNER_RIGHT_TOP + viewport_center_offset_x - radius)) / maxf(0.001, denominator)
	return lerpf(top, bottom, clampf(right_t, 0.0, 1.0))
