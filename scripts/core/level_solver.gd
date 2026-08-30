class_name LevelSolver
extends RefCounted

## Feasibility analysis for limited-shot levels.
##
## Two bounds are computed, because neither alone answers the question.
##
## 1. `material_ratio` - a hard floor. Merging is strictly tier N + tier N ->
##    tier N + 1, so every gem is worth a power of two in "tier-1 equivalents"
##    and merging conserves that total; a tier-T target costs exactly 2^(T-1).
##    Because every value is a power of two, any multiset summing to at least
##    2^(T-1) can be carried up into one tier-T gem. This bound counts only the
##    seeded board and the shots the limit allows.
##
## 2. `simulate()` - a greedy play-out that also counts the bonus gems merges
##    spawn. Those are the game's main material source, which is why the floor
##    alone reads as impossible for every level: it ignores them. The play-out
##    assumes perfect placement, so it is an upper bound on what a player can
##    achieve.
##
## Read together: if the simulation fails, the level is impossible for anyone.
## If the floor exceeds 1.0, it is guaranteed regardless of play. In between,
## `shots_used` against the limit is the margin a real player has to work with.

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")

## Spare shots a shipped level must leave after a perfect play-out. Below this
## the level demands near-flawless play.
const MIN_SPARE_SHOTS := {
	"EASY": 12,
	"MEDIUM": 7,
	"HARD": 3,
}


static func units_for_tier(tier: int) -> int:
	return 1 << maxi(0, tier - 1)


static func supplied_units(config: Dictionary) -> int:
	var total := 0
	for entry in (config.get("starting_board", []) as Array):
		total += units_for_tier(int((entry as Dictionary).get("tier", 1)))
	var sequence: Array = config.get("launcher_sequence", []) as Array
	var shots := int(config.get("shot_limit", 0))
	if sequence.is_empty():
		return total
	for index in range(maxi(0, shots)):
		total += units_for_tier(int(sequence[posmod(index, sequence.size())]))
	return total


static func required_units(config: Dictionary) -> int:
	var total := 0
	for entry in (config.get("target_sequence", []) as Array):
		var target: Dictionary = entry as Dictionary
		total += units_for_tier(int(target.get("tier", 1))) * maxi(1, int(target.get("quantity", 1)))
	return total


static func material_ratio(config: Dictionary) -> float:
	var required := required_units(config)
	if required <= 0:
		return INF
	return float(supplied_units(config)) / float(required)


## Greedy play-out. Each shot adds its gem, then everything that can merge is
## merged from the lowest tier up, exactly as a carry. Completed targets are
## removed from the board, matching collection.
##
## `bonus_per_merge` models the gems merges spawn. It is deliberately settable
## so the pessimistic case (0) and the shipped case can both be measured.
static func simulate(config: Dictionary, bonus_per_shot := GameConfig.BONUS_GEM_BUDGET_PER_SHOT, bonus_tier := 1) -> Dictionary:
	var sequence: Array = config.get("launcher_sequence", []) as Array
	var shot_limit := int(config.get("shot_limit", 0))
	if sequence.is_empty():
		return {"completed": false, "shots_used": 0, "targets_done": 0, "targets_total": 0}

	# Board as a tier histogram; placement is assumed perfect.
	var counts := {}
	for entry in (config.get("starting_board", []) as Array):
		var tier := int((entry as Dictionary).get("tier", 1))
		counts[tier] = int(counts.get(tier, 0)) + 1

	var targets: Array[Dictionary] = []
	for entry in (config.get("target_sequence", []) as Array):
		var target: Dictionary = entry as Dictionary
		targets.append({
			"tier": int(target.get("tier", 1)),
			"remaining": maxi(1, int(target.get("quantity", 1))),
		})

	var target_index := 0
	var shots_used := 0
	var budget := shot_limit if shot_limit > 0 else sequence.size() * 8
	while shots_used < budget and target_index < targets.size():
		counts[int(sequence[posmod(shots_used, sequence.size())])] = int(
			counts.get(int(sequence[posmod(shots_used, sequence.size())]), 0)) + 1
		shots_used += 1
		# The board grants at most BONUS_GEM_BUDGET_PER_SHOT bonus gems per shot,
		# reset each launch. Without that cap the merge-spawns-a-gem loop is an
		# infinite material generator and every level trivially "passes".
		var bonus_budget := bonus_per_shot

		# Carry upward until nothing else can pair. Bonus gems from each merge
		# re-enter the pool, so they can themselves be merged.
		var merged_something := true
		while merged_something:
			merged_something = false
			var tiers: Array = counts.keys()
			tiers.sort()
			for tier in tiers:
				var available := int(counts.get(tier, 0))
				if available < 2 or tier >= GameConfig.MAX_GEM_LEVEL:
					continue
				var pairs := available / 2
				counts[tier] = available - pairs * 2
				counts[tier + 1] = int(counts.get(tier + 1, 0)) + pairs
				if bonus_budget > 0:
					var granted := mini(bonus_budget, pairs)
					bonus_budget -= granted
					counts[bonus_tier] = int(counts.get(bonus_tier, 0)) + granted
				merged_something = true

			# Collect anything the active target asks for.
			while target_index < targets.size():
				var active: Dictionary = targets[target_index]
				var tier := int(active.tier)
				if int(counts.get(tier, 0)) <= 0:
					break
				counts[tier] = int(counts.get(tier, 0)) - 1
				active.remaining = int(active.remaining) - 1
				merged_something = true
				if int(active.remaining) <= 0:
					target_index += 1

	var done := 0
	for index in range(targets.size()):
		if index < target_index:
			done += 1
	return {
		"completed": target_index >= targets.size(),
		"shots_used": shots_used,
		"spare_shots": maxi(0, shot_limit - shots_used) if shot_limit > 0 else -1,
		"targets_done": done,
		"targets_total": targets.size(),
	}


static func classify(config: Dictionary) -> String:
	if int(config.get("shot_limit", 0)) <= 0:
		return "UNLIMITED"
	var run := simulate(config)
	if not bool(run.completed):
		return "AVOID"
	var spare := int(run.spare_shots)
	if spare >= int(MIN_SPARE_SHOTS.EASY):
		return "EASY"
	if spare >= int(MIN_SPARE_SHOTS.MEDIUM):
		return "MEDIUM"
	if spare >= int(MIN_SPARE_SHOTS.HARD):
		return "HARD"
	return "AVOID"


static func analyse(config: Dictionary) -> Dictionary:
	var run := simulate(config)
	var pessimistic := simulate(config, 0)
	return {
		"level_number": int(config.get("level_number", 0)),
		"limited": int(config.get("shot_limit", 0)) > 0,
		"shot_limit": int(config.get("shot_limit", 0)),
		"board_gems": (config.get("starting_board", []) as Array).size(),
		"material_ratio": material_ratio(config),
		"completed": bool(run.completed),
		"shots_used": int(run.shots_used),
		"spare_shots": int(run.spare_shots),
		"completed_without_bonus": bool(pessimistic.completed),
		"classification": classify(config),
	}


## Shots a perfect play-out needs with no limit imposed. This is the floor any
## shot limit must clear; a limit below it makes the level unwinnable for
## everyone, however well they play.
static func minimum_shots(config: Dictionary) -> int:
	var unlimited := config.duplicate(true)
	unlimited["shot_limit"] = 0
	var run := simulate(unlimited)
	if not bool(run.completed):
		return -1
	return int(run.shots_used)
