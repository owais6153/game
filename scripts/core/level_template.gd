class_name LevelTemplate
extends RefCounted

## Reusable level compositions.
##
## Every level used to be assembled from three independent ladders - a queue
## cycle chosen by level number, a target quantity curve, and a limited-shots
## modulo - which meant that once each ladder reached its cap the levels stopped
## differing at all. From roughly level 14 onward there were exactly two shapes
## left, "normal" and "limited shots", repeating forever.
##
## A template names one *whole* composition instead: which launcher band feeds
## it, how crowded the opening board is and in what shape, what the target cards
## ask for, and whether shots are limited and how generously. Difficulty is then
## a property of the combination rather than of any single ladder, so a level can
## be hard because its queue is lean while its targets are short, or because its
## targets are long while its queue is kind - two levels in the same band that
## play very differently.
##
## Nothing here introduces a mechanic. Every field drives an existing system.
##
## Determinism: `for_level()` is a pure function of the level number. Retries and
## reinstalls reconstruct the same level, exactly as before.

const GENERATOR_VERSION := 2

# --- Difficulty bands -------------------------------------------------------

const BAND_TUTORIAL := "TUTORIAL"
const BAND_EASY := "EASY"
const BAND_NORMAL := "NORMAL"
const BAND_CHALLENGING := "CHALLENGING"
const BAND_HARD := "HARD"
const BAND_EXPERT := "EXPERT"

const BANDS := [BAND_TUTORIAL, BAND_EASY, BAND_NORMAL, BAND_CHALLENGING, BAND_HARD, BAND_EXPERT]

## Ordering used to assert the curve trends upward. Relief levels dip inside the
## trend; they never reset it.
const BAND_RANK := {
	BAND_TUTORIAL: 0,
	BAND_EASY: 1,
	BAND_NORMAL: 2,
	BAND_CHALLENGING: 3,
	BAND_HARD: 4,
	BAND_EXPERT: 5,
}

# --- Launcher queue bands ---------------------------------------------------

## What the launcher feeds the player, as a ten-shot cycle that is shuffled per
## level. A cycle rich in tier 3-4 gems hands over most of the merge work
## already done; a cycle of tier 1s makes the player build everything from the
## bottom. This is the single strongest difficulty lever the game already had,
## and it was previously pinned to level number alone.
##
## Every band keeps at least one tier-3 or tier-4 gem per cycle, so the L6-L8
## objectives stay constructible from the sequence alone and powers remain
## optional everywhere.
const QUEUE_BANDS := {
	"intro": [4, 4, 3, 3, 2, 2, 1, 1, 3, 2],
	"generous": [4, 3, 3, 2, 2, 2, 1, 1, 1, 4],
	"balanced": [1, 1, 1, 2, 2, 2, 3, 3, 4, 4],
	"lean": [1, 1, 1, 1, 2, 2, 2, 3, 3, 4],
	"scarce": [1, 1, 1, 1, 1, 2, 2, 2, 3, 4],
}

const QUEUE_BAND_IDS := ["intro", "generous", "balanced", "lean", "scarce"]

# --- Opening board layout archetypes ---------------------------------------

## Named shapes for the seeded opening board. All of them are produced by the
## existing row/column placement with the existing spacing rules; an archetype
## only decides *where* the gaps go and which rows are populated. None of them
## changes physics, collision geometry, or the danger-line margin.
const LAYOUT_STAGGERED_GAPS := "staggered_gaps"
const LAYOUT_LEFT_HEAVY := "left_heavy"
const LAYOUT_RIGHT_HEAVY := "right_heavy"
const LAYOUT_CENTER_HEAVY := "center_heavy"
const LAYOUT_SPLIT_CLUSTERS := "split_clusters"
const LAYOUT_ALTERNATING_GAPS := "alternating_gaps"
const LAYOUT_WIDE_CENTER_GAP := "wide_center_gap"
const LAYOUT_TWO_POCKET := "two_pocket"
const LAYOUT_CHAIN_OPPORTUNITY := "chain_opportunity"
const LAYOUT_SPARSE_TOP := "sparse_top"
const LAYOUT_DENSE_TOP := "dense_top"
const LAYOUT_EMPTY := "empty"

const LAYOUTS := [
	LAYOUT_EMPTY,
	LAYOUT_STAGGERED_GAPS,
	LAYOUT_LEFT_HEAVY,
	LAYOUT_RIGHT_HEAVY,
	LAYOUT_CENTER_HEAVY,
	LAYOUT_SPLIT_CLUSTERS,
	LAYOUT_ALTERNATING_GAPS,
	LAYOUT_WIDE_CENTER_GAP,
	LAYOUT_TWO_POCKET,
	LAYOUT_CHAIN_OPPORTUNITY,
	LAYOUT_SPARSE_TOP,
	LAYOUT_DENSE_TOP,
]

# --- Target structures ------------------------------------------------------

## Target cards are strictly sequential and are counted at merge time against
## whichever card is active. A gem merged *above* the active tier is not banked
## for a later card - see the audit note in `docs/TARGET_PROGRESSION_AUDIT` in
## LEVEL_DESIGN.md. Two rules follow, and `validate()` enforces both:
##
##  1. Tiers must ascend. A sequence that asks for a high tier before a low one
##     would strand the low-tier work the player must do anyway.
##  2. Only tiers 6-8 are objectives, and the top tier is asked for once. It is
##     the longest merge chain in the level; repeating it multiplies the hardest
##     work rather than deepening the objective.
const TARGET_STRUCTURES := {
	# Short ladders. The limited-shot rounds and the earliest levels use these.
	"pair_low": [{"tier": 6, "quantity": 1}, {"tier": 7, "quantity": 1}],
	"base_pair": [{"tier": 6, "quantity": 2}, {"tier": 7, "quantity": 1}],
	"top_pair": [{"tier": 7, "quantity": 1}, {"tier": 8, "quantity": 1}],
	# Full three-card climbs, varying which rung carries the weight.
	"climb_single": [{"tier": 6, "quantity": 1}, {"tier": 7, "quantity": 1}, {"tier": 8, "quantity": 1}],
	"climb_base": [{"tier": 6, "quantity": 2}, {"tier": 7, "quantity": 1}, {"tier": 8, "quantity": 1}],
	"climb_middle": [{"tier": 6, "quantity": 1}, {"tier": 7, "quantity": 2}, {"tier": 8, "quantity": 1}],
	"climb_wide": [{"tier": 6, "quantity": 3}, {"tier": 7, "quantity": 2}, {"tier": 8, "quantity": 1}],
	"climb_heavy": [{"tier": 6, "quantity": 2}, {"tier": 7, "quantity": 2}, {"tier": 8, "quantity": 1}],
	# Two-card structures that stop short of the apex, so the level's weight
	# sits in volume rather than in one long chain.
	"base_heavy": [{"tier": 6, "quantity": 3}, {"tier": 7, "quantity": 1}],
	"low_build": [{"tier": 6, "quantity": 2}, {"tier": 7, "quantity": 2}],
}

# --- Templates --------------------------------------------------------------

## `rows` is the seeded opening row count, `gaps` the openings per row (density),
## `queue` the launcher band, `targets` a key into TARGET_STRUCTURES, and
## `shot_margin` the multiplier applied to the solver's floor for limited
## rounds - higher is more forgiving.
##
## `power_hint` names the power the composition most rewards. It is analytics and
## briefing metadata only; nothing is granted or required.
const TEMPLATES := {
	"tutorial_open": {
		"band": BAND_TUTORIAL, "queue": "intro", "layout": LAYOUT_EMPTY,
		"rows": 0, "gaps": 2, "targets": "climb_single",
		"limited": false, "shot_margin": 0.0, "power_hint": "",
	},
	"tutorial_seeded": {
		"band": BAND_TUTORIAL, "queue": "intro", "layout": LAYOUT_STAGGERED_GAPS,
		"rows": 2, "gaps": 2, "targets": "climb_single",
		"limited": false, "shot_margin": 0.0, "power_hint": "",
	},
	# Breathing room. A generous queue against a shallow board: the level the
	# curve returns to after a spike.
	"relaxed": {
		"band": BAND_EASY, "queue": "generous", "layout": LAYOUT_SPARSE_TOP,
		"rows": 2, "gaps": 2, "targets": "climb_single",
		"limited": false, "shot_margin": 0.0, "power_hint": "",
	},
	"recovery": {
		"band": BAND_EASY, "queue": "generous", "layout": LAYOUT_LEFT_HEAVY,
		"rows": 2, "gaps": 2, "targets": "base_pair",
		"limited": false, "shot_margin": 0.0, "power_hint": "switch",
	},
	# Pre-placed adjacent same-tier material: the board wants to cascade if the
	# player finds the entry point.
	"chain_friendly": {
		"band": BAND_NORMAL, "queue": "balanced", "layout": LAYOUT_CHAIN_OPPORTUNITY,
		"rows": 3, "gaps": 1, "targets": "climb_base",
		"limited": false, "shot_margin": 0.0, "power_hint": "bomb",
	},
	# Crowded opening, deliberately short objectives. Pressure comes from the
	# board, not the target list.
	"dense_opening": {
		"band": BAND_NORMAL, "queue": "balanced", "layout": LAYOUT_DENSE_TOP,
		"rows": 4, "gaps": 1, "targets": "top_pair",
		"limited": false, "shot_margin": 0.0, "power_hint": "hammer",
	},
	# Sparse board, long objectives. The inverse trade of dense_opening.
	"target_heavy": {
		"band": BAND_CHALLENGING, "queue": "generous", "layout": LAYOUT_SPARSE_TOP,
		"rows": 2, "gaps": 1, "targets": "climb_wide",
		"limited": false, "shot_margin": 0.0, "power_hint": "",
	},
	# Narrow landing pockets. Placement matters more than material here.
	"precision": {
		"band": BAND_CHALLENGING, "queue": "lean", "layout": LAYOUT_TWO_POCKET,
		"rows": 3, "gaps": 1, "targets": "climb_single",
		"limited": false, "shot_margin": 0.0, "power_hint": "hammer",
	},
	"low_tier_build": {
		"band": BAND_CHALLENGING, "queue": "lean", "layout": LAYOUT_ALTERNATING_GAPS,
		"rows": 3, "gaps": 1, "targets": "low_build",
		"limited": false, "shot_margin": 0.0, "power_hint": "switch",
	},
	"high_pressure": {
		"band": BAND_HARD, "queue": "scarce", "layout": LAYOUT_CENTER_HEAVY,
		"rows": 4, "gaps": 1, "targets": "climb_base",
		"limited": false, "shot_margin": 0.0, "power_hint": "bomb",
	},
	"high_tier_build": {
		"band": BAND_HARD, "queue": "balanced", "layout": LAYOUT_SPLIT_CLUSTERS,
		"rows": 3, "gaps": 1, "targets": "climb_middle",
		"limited": false, "shot_margin": 0.0, "power_hint": "",
	},
	"expert": {
		"band": BAND_EXPERT, "queue": "scarce", "layout": LAYOUT_SPLIT_CLUSTERS,
		"rows": 4, "gaps": 1, "targets": "climb_heavy",
		"limited": false, "shot_margin": 0.0, "power_hint": "bomb",
	},
	"expert_volume": {
		"band": BAND_EXPERT, "queue": "lean", "layout": LAYOUT_WIDE_CENTER_GAP,
		"rows": 4, "gaps": 1, "targets": "climb_wide",
		"limited": false, "shot_margin": 0.0, "power_hint": "hammer",
	},
	# --- Limited-shot compositions -----------------------------------------
	# Limited rounds are accuracy challenges, not endurance checks, so they pair
	# a short objective with a real margin above the solver floor. They used to
	# be structurally *easier* than the normal levels around them, which is what
	# made the curve oscillate; the tight variants now carry real weight.
	"limited_generous": {
		"band": BAND_NORMAL, "queue": "generous", "layout": LAYOUT_RIGHT_HEAVY,
		"rows": 2, "gaps": 2, "targets": "pair_low",
		"limited": true, "shot_margin": 1.70, "power_hint": "switch",
	},
	"limited_dense": {
		"band": BAND_CHALLENGING, "queue": "generous", "layout": LAYOUT_DENSE_TOP,
		"rows": 4, "gaps": 1, "targets": "pair_low",
		"limited": true, "shot_margin": 1.60, "power_hint": "bomb",
	},
	"limited_standard": {
		"band": BAND_CHALLENGING, "queue": "balanced", "layout": LAYOUT_ALTERNATING_GAPS,
		"rows": 3, "gaps": 1, "targets": "base_pair",
		"limited": true, "shot_margin": 1.45, "power_hint": "",
	},
	"limited_tight": {
		"band": BAND_HARD, "queue": "lean", "layout": LAYOUT_WIDE_CENTER_GAP,
		"rows": 3, "gaps": 1, "targets": "base_heavy",
		"limited": true, "shot_margin": 1.32, "power_hint": "hammer",
	},
	"limited_expert": {
		"band": BAND_EXPERT, "queue": "lean", "layout": LAYOUT_CENTER_HEAVY,
		"rows": 4, "gaps": 1, "targets": "climb_single",
		"limited": true, "shot_margin": 1.30, "power_hint": "bomb",
	},
}

# --- Pacing -----------------------------------------------------------------

## Levels 1-3 teach the loop and are fixed. The limited-shots mechanic is still
## introduced at level 4, while the board is simple enough to read.
const FIRST_LIMITED_SHOTS_LEVEL := 4
const SCRIPTED_OPENING := ["tutorial_open", "tutorial_seeded", "relaxed", "limited_generous", "chain_friendly"]

## Pacing roles, cycled from level 6 onward. The curve trends upward but is not
## monotonic: a relief level after a spike is what makes the next spike read as
## one. A run of ever-harder levels flattens into "hard" and stops being felt.
const ROLE_CHALLENGE := "challenge"
const ROLE_RELIEF := "relief"
const ROLE_SPIKE := "spike"
const ROLE_CYCLE := [
	ROLE_CHALLENGE,
	ROLE_CHALLENGE,
	ROLE_RELIEF,
	ROLE_CHALLENGE,
	ROLE_SPIKE,
	ROLE_RELIEF,
	ROLE_CHALLENGE,
	ROLE_SPIKE,
]

## Limited-shot cadence. A flat "every third level" was immediately legible and
## made the variant feel like a metronome rather than a change of pace. This
## pattern keeps limited rounds frequent - five in every thirteen levels - while
## varying the gap between them from one level to four.
##
## Its length is coprime with ROLE_CYCLE's, so the combined pattern runs 104
## levels before it repeats.
## Four in every thirteen levels, with gaps of two to five between them. Held
## close to the previous one-in-three density on purpose: limited rounds carry
## shorter target ladders and so pay less, and making them more frequent would
## quietly deflate coin income across the whole run.
const LIMITED_PATTERN := [
	false, true, false, false, false, true, false,
	true, false, false, false, false, true,
]

## Which pool a role draws from, per band. Selection walks the pool by level so
## consecutive levels in the same band and role still differ.
## Pools widen as the bands rise. The top band is where a player spends most of
## their time, so it draws from the most templates, not the fewest - a narrow
## expert pool would rebuild the very plateau this system exists to remove.
const CHALLENGE_POOLS := {
	BAND_EASY: ["relaxed", "recovery"],
	BAND_NORMAL: ["chain_friendly", "dense_opening", "recovery"],
	BAND_CHALLENGING: ["precision", "target_heavy", "low_tier_build"],
	BAND_HARD: ["high_pressure", "high_tier_build", "precision", "low_tier_build"],
	BAND_EXPERT: ["expert", "expert_volume", "high_pressure", "high_tier_build", "precision"],
}

const SPIKE_POOLS := {
	BAND_EASY: ["chain_friendly"],
	BAND_NORMAL: ["precision", "target_heavy"],
	BAND_CHALLENGING: ["high_pressure", "high_tier_build"],
	BAND_HARD: ["expert", "expert_volume", "target_heavy"],
	BAND_EXPERT: ["expert", "expert_volume", "high_tier_build"],
}

const RELIEF_POOLS := {
	BAND_EASY: ["relaxed"],
	BAND_NORMAL: ["relaxed", "recovery"],
	BAND_CHALLENGING: ["recovery", "chain_friendly", "relaxed"],
	BAND_HARD: ["chain_friendly", "dense_opening", "recovery"],
	BAND_EXPERT: ["dense_opening", "target_heavy", "chain_friendly", "low_tier_build"],
}

const LIMITED_POOLS = {
	BAND_EASY: ["limited_generous"],
	BAND_NORMAL: ["limited_generous", "limited_dense"],
	BAND_CHALLENGING: ["limited_standard", "limited_dense", "limited_generous"],
	BAND_HARD: ["limited_tight", "limited_standard", "limited_dense"],
	BAND_EXPERT: ["limited_expert", "limited_tight", "limited_standard"],
}

## Where each band begins. The curve reaches its top band around level 40 and
## then varies composition within it rather than inventing new difficulty, which
## is what the existing content already did - only now the variation is real.
const BAND_ONSET := [
	{"level": 1, "band": BAND_TUTORIAL},
	{"level": 4, "band": BAND_EASY},
	{"level": 8, "band": BAND_NORMAL},
	{"level": 15, "band": BAND_CHALLENGING},
	{"level": 26, "band": BAND_HARD},
	{"level": 40, "band": BAND_EXPERT},
]


static func band_for_level(level_number: int) -> String:
	var band := BAND_TUTORIAL
	for entry in BAND_ONSET:
		if level_number >= int((entry as Dictionary).level):
			band = String((entry as Dictionary).band)
	return band


static func role_for_level(level_number: int) -> String:
	if level_number <= SCRIPTED_OPENING.size():
		return ROLE_CHALLENGE
	return String(ROLE_CYCLE[(level_number - SCRIPTED_OPENING.size() - 1) % ROLE_CYCLE.size()])


static func is_limited_shots_level(level_number: int) -> bool:
	if level_number < FIRST_LIMITED_SHOTS_LEVEL:
		return false
	if level_number <= SCRIPTED_OPENING.size():
		return bool(TEMPLATES[SCRIPTED_OPENING[level_number - 1]].limited)
	return bool(LIMITED_PATTERN[(level_number - SCRIPTED_OPENING.size() - 1) % LIMITED_PATTERN.size()])


static func _pool_for_level(level: int) -> Array:
	var band := band_for_level(level)
	if is_limited_shots_level(level):
		return LIMITED_POOLS.get(band, LIMITED_POOLS[BAND_NORMAL]) as Array
	match role_for_level(level):
		ROLE_RELIEF:
			return RELIEF_POOLS.get(band, RELIEF_POOLS[BAND_NORMAL]) as Array
		ROLE_SPIKE:
			return SPIKE_POOLS.get(band, SPIKE_POOLS[BAND_NORMAL]) as Array
	return CHALLENGE_POOLS.get(band, CHALLENGE_POOLS[BAND_NORMAL]) as Array


## Unadjusted pool pick. Kept separate from `id_for_level` so the anti-repeat
## rule below can look at the previous level without recursing.
##
## Indexed by a multiplicative hash rather than by `level % pool.size()`. The
## role cycle has an even length, so a plain modulo walk gave a two-entry pool
## the *same* index every time that role came round - which is how levels 50, 60
## and 100 all landed on one template in the first audit run.
static func _raw_id_for_level(level: int) -> String:
	if level <= SCRIPTED_OPENING.size():
		return String(SCRIPTED_OPENING[maxi(1, level) - 1])
	var pool := _pool_for_level(level)
	if pool.is_empty():
		return "chain_friendly"
	var mixed := int((level * 2654435761) & 0x7fffffff)
	return String(pool[mixed % pool.size()])


## The template id for a level. Pure and total: same input, same output, forever.
static func id_for_level(level_number: int) -> String:
	var level := maxi(1, level_number)
	var id := _raw_id_for_level(level)
	if level <= SCRIPTED_OPENING.size() + 1:
		return id
	if id != _raw_id_for_level(level - 1):
		return id
	# Two adjacent levels drew the same template. Step to the next entry in this
	# level's pool: back-to-back identical compositions are exactly the
	# repetition this system exists to remove.
	var pool := _pool_for_level(level)
	if pool.size() <= 1:
		return id
	var mixed := int((level * 2654435761) & 0x7fffffff)
	return String(pool[(mixed + 1) % pool.size()])


static func for_level(level_number: int) -> Dictionary:
	var id := id_for_level(level_number)
	var template: Dictionary = (TEMPLATES[id] as Dictionary).duplicate(true)
	template["id"] = id
	template["role"] = role_for_level(maxi(1, level_number))
	template["generator_version"] = GENERATOR_VERSION
	return template


static func targets_for(template: Dictionary) -> Array[Dictionary]:
	var key := String(template.get("targets", "climb_single"))
	var structure: Array = TARGET_STRUCTURES.get(key, TARGET_STRUCTURES["climb_single"]) as Array
	var targets: Array[Dictionary] = []
	for entry in structure:
		targets.append((entry as Dictionary).duplicate())
	return targets


static func queue_cycle_for(template: Dictionary) -> Array[int]:
	var band := String(template.get("queue", "balanced"))
	var cycle: Array[int] = []
	for value in (QUEUE_BANDS.get(band, QUEUE_BANDS["balanced"]) as Array):
		cycle.append(int(value))
	return cycle


## Structural validation. Run over every shipped level by the level-template
## test suite, so an edit to the tables above cannot ship a level that asks for
## something the merge economy cannot deliver.
static func validate(template: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	var id := String(template.get("id", "?"))
	if not BANDS.has(String(template.get("band", ""))):
		problems.append("%s: unknown difficulty band" % id)
	if not QUEUE_BANDS.has(String(template.get("queue", ""))):
		problems.append("%s: unknown queue band" % id)
	if not LAYOUTS.has(String(template.get("layout", ""))):
		problems.append("%s: unknown layout archetype" % id)
	var rows := int(template.get("rows", 0))
	if rows < 0 or rows > 4:
		problems.append("%s: opening rows %d outside the safe 0-4 range" % [id, rows])
	var targets := targets_for(template)
	if targets.is_empty():
		problems.append("%s: no target cards" % id)
	var previous_tier := 0
	for index in range(targets.size()):
		var target := targets[index]
		var tier := int(target.get("tier", 0))
		var quantity := int(target.get("quantity", 0))
		if tier < 6 or tier > 8:
			problems.append("%s: target tier %d is not an objective tier" % [id, tier])
		# Ascending only. Targets are counted against the active card at merge
		# time, so a descending sequence strands work the player must do anyway.
		if tier <= previous_tier:
			problems.append("%s: target tiers must ascend (%d after %d)" % [id, tier, previous_tier])
		previous_tier = tier
		if quantity < 1:
			problems.append("%s: target quantity %d is not positive" % [id, quantity])
		if tier == 8 and quantity > 1:
			problems.append("%s: tier 8 asked for %d times" % [id, quantity])
		if tier == 6 and quantity > 3:
			problems.append("%s: tier 6 asked for %d times" % [id, quantity])
		if tier == 7 and quantity > 2:
			problems.append("%s: tier 7 asked for %d times" % [id, quantity])
	if bool(template.get("limited", false)):
		var margin := float(template.get("shot_margin", 0.0))
		# A shipped level must never require flawless play.
		if margin < 1.25:
			problems.append("%s: limited shot margin %.2f leaves no room for error" % [id, margin])
	return problems
