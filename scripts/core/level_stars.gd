class_name LevelStars
extends RefCounted

## What a level's three stars ask for, and whether a finished attempt earned
## them.
##
## Pure arithmetic over a generated level config, in the same spirit as
## LevelMilestone and TreasureDrop: the level-start screen that shows the
## objectives, the result popup that awards them, and the map that draws the
## totals all read the same functions, so none of them can disagree.
##
## The three stars are deliberately different *kinds* of demand:
##
##   1. Complete the level. Always. Winning is the first star, so a star row is
##      never empty for a level the player has beaten and the other two read as
##      bonuses rather than as a pass mark.
##   2. Finish inside a shot budget. This is the efficiency star.
##   3. One varied objective, rotated per level. This is the star that makes two
##      levels in the same band read differently.
##
## Star 2 and star 3 pull in opposite directions on purpose - one rewards taking
## fewer shots, the other rewards the volume or the depth of what those shots
## produce - so three stars is a real decision about how to play rather than the
## same play done better.
##
## ## Every threshold is derived, never authored
##
## `LevelSolver.simulate()` plays the level out greedily with the real merge and
## bonus-gem rules and reports the shots and merges a perfect play-out needs.
## Both numeric stars are sized against that, so a threshold cannot drift away
## from what the level actually contains when a template is retuned - which is
## exactly how the old hand-written shot ladder made every limited level
## unwinnable. `scripts/dev/print_level_star_audit.gd` prints the resulting
## numbers, and `run_level_stars_v1_tests` asserts the achievability bounds for
## every level from 1 to 120.

const LevelSolverType = preload("res://scripts/core/level_solver.gd")
const LevelTemplateType = preload("res://scripts/core/level_template.gd")

const MAX_STARS := 3

const STAR_COMPLETE := "complete"
const STAR_SHOTS := "shots"
const STAR_BONUS := "bonus"

## The rotating third objective.
const KIND_MERGES := "merges"
const KIND_COMBO := "combo"
const KIND_NO_POWER := "no_power"

## Rotation order. Three kinds against a hash of the level number, so the third
## star is not a visible metronome the way `level % 3` would be.
const BONUS_KINDS := [KIND_MERGES, KIND_COMBO, KIND_NO_POWER]

## Shot star: multiplier on the perfect play-out, plus an absolute floor of
## spare shots so a short level is not decided by a single misfire.
##
## 1.25 sits below every shot-limit margin in LevelConfig (1.30 at its tightest,
## 1.70 at its most generous), which is what makes this star meaningfully harder
## than merely finishing a limited level while staying inside a budget the level
## is proven to be completable in.
const SHOT_STAR_MARGIN := 1.25
const SHOT_STAR_HEADROOM := 4
## On a limited level the star must sit strictly inside the level's own budget,
## or it would be handed out for free with the win.
const SHOT_STAR_LIMIT_GAP := 1

## Merge star: a multiplier on the perfect play-out's merge count.
##
## Below 1.0, deliberately, and this is the one threshold that is not tightened
## toward what is theoretically reachable.
##
## A real player takes 30-70% more shots than the play-out, which is more
## material and therefore more merges - but they also strand gems that the
## play-out pairs perfectly, and no player can beat the play-out's merges *per
## unit of material*. Those two effects push in opposite directions and their
## net is not something this file can know. The failure modes are not
## symmetrical: a star that is slightly too easy is a mild waste, while a star
## nobody can reach is a promise the level-start screen made and broke. So the
## bar sits under the level's own demonstrated merge count and this is the most
## forgiving of the three stars by design.
const MERGE_STAR_MARGIN := 0.90
const MERGE_STAR_FLOOR := 10
## Displayed merge counts are rounded to this, because "Merge 98 gems" reads as
## a number that fell out of a formula and "Merge 100 gems" reads as an
## objective. Rounding is downward, so it can only ever loosen the bar.
const MERGE_STAR_ROUNDING := 5

## Combo star: the chain depth to reach, by template band. Depth 1 is the first
## chained merge after a shot, so these ask for a two- or three-link chain.
##
## Capped at 3. Deeper chains do happen, but they depend on how the board
## happens to be stacked rather than on anything the player can aim for, and a
## star nobody can plan toward is a lottery ticket.
const COMBO_STAR_BY_BAND := {
	LevelTemplateType.BAND_TUTORIAL: 2,
	LevelTemplateType.BAND_EASY: 2,
	LevelTemplateType.BAND_NORMAL: 2,
	LevelTemplateType.BAND_CHALLENGING: 3,
	LevelTemplateType.BAND_HARD: 3,
	LevelTemplateType.BAND_EXPERT: 3,
}
const COMBO_STAR_DEFAULT := 2


## The three objectives for one generated level config, in display order.
##
## Each entry carries a stable `id`, the `kind` that decides how it is evaluated,
## its numeric `target` (0 where the objective is not numeric), and the `text`
## the level-start screen and the result popup both render. Presentation never
## composes its own wording, so the objective a player is shown before the level
## is word-for-word the one they are judged against after it.
static func objectives_for(config: Dictionary) -> Array[Dictionary]:
	var objectives: Array[Dictionary] = []
	objectives.append({
		"id": STAR_COMPLETE,
		"kind": STAR_COMPLETE,
		"target": 0,
		"text": "Complete the level",
	})
	var shots := shot_target(config)
	objectives.append({
		"id": STAR_SHOTS,
		"kind": STAR_SHOTS,
		"target": shots,
		"text": "Finish in %d shots or fewer" % shots,
	})
	objectives.append(_bonus_objective(config))
	return objectives


## Shots the efficiency star allows. Never below the perfect play-out plus a
## small headroom, and on a limited level never at or above the level's own
## limit.
static func shot_target(config: Dictionary) -> int:
	var minimum := LevelSolverType.minimum_shots(config)
	if minimum <= 0:
		# No play-out was found, so there is no honest budget to ask for. Fall
		# back to the level's own limit, which makes the star equivalent to
		# winning rather than impossible.
		return maxi(1, int(config.get("shot_limit", 0)))
	var target := maxi(minimum + SHOT_STAR_HEADROOM, int(ceil(float(minimum) * SHOT_STAR_MARGIN)))
	var limit := int(config.get("shot_limit", 0))
	if limit > 0:
		target = mini(target, limit - SHOT_STAR_LIMIT_GAP)
		# The clamp above can cross the floor on a tightly-budgeted level. The
		# play-out is the one number that is proven achievable, so it wins.
		target = maxi(target, mini(minimum + 2, limit - SHOT_STAR_LIMIT_GAP))
	return maxi(1, target)


## Merges the volume star asks for.
static func merge_target(config: Dictionary) -> int:
	var unlimited := config.duplicate(true)
	unlimited["shot_limit"] = 0
	var run := LevelSolverType.simulate(unlimited)
	var merges := int(run.get("merges", 0))
	if merges <= 0:
		return MERGE_STAR_FLOOR
	var target := int(floor(float(merges) * MERGE_STAR_MARGIN))
	target = (target / MERGE_STAR_ROUNDING) * MERGE_STAR_ROUNDING
	return maxi(MERGE_STAR_FLOOR, target)


static func combo_target(config: Dictionary) -> int:
	var band := String(config.get("difficulty_band", LevelTemplateType.BAND_NORMAL))
	return int(COMBO_STAR_BY_BAND.get(band, COMBO_STAR_DEFAULT))


## Which of the three rotating objectives this level carries.
static func bonus_kind(level_number: int) -> String:
	return String(BONUS_KINDS[_hash(level_number) % BONUS_KINDS.size()])


static func _bonus_objective(config: Dictionary) -> Dictionary:
	var level_number := int(config.get("level_number", 1))
	var kind := bonus_kind(level_number)
	match kind:
		KIND_COMBO:
			var combo := combo_target(config)
			return {
				"id": STAR_BONUS,
				"kind": kind,
				"target": combo,
				"text": "Reach a combo of %d" % combo,
			}
		KIND_NO_POWER:
			return {
				"id": STAR_BONUS,
				"kind": kind,
				"target": 0,
				"text": "Win without using a power",
			}
	var merges := merge_target(config)
	return {
		"id": STAR_BONUS,
		"kind": KIND_MERGES,
		"target": merges,
		"text": "Merge %d gems" % merges,
	}


## Per-star results for a finished attempt, in the same order as
## `objectives_for()`.
##
## `outcome` carries `won`, `shots_used`, `merges`, `best_combo` and
## `used_power`. Losing earns nothing at all: the other two objectives describe
## *how* a level was beaten, so crediting them for an attempt that was not
## beaten would let a player bank two stars by giving up efficiently.
static func evaluate(objectives: Array, outcome: Dictionary) -> Array[bool]:
	var results: Array[bool] = []
	var won := bool(outcome.get("won", false))
	for entry in objectives:
		var objective: Dictionary = entry as Dictionary
		if not won:
			results.append(false)
			continue
		results.append(_satisfied(objective, outcome))
	return results


static func _satisfied(objective: Dictionary, outcome: Dictionary) -> bool:
	var target := int(objective.get("target", 0))
	match String(objective.get("kind", "")):
		STAR_COMPLETE:
			return true
		STAR_SHOTS:
			# A level with no shots fired cannot have been won, so this is a
			# guard against a malformed outcome rather than a real case.
			var shots := int(outcome.get("shots_used", 0))
			return shots > 0 and shots <= target
		KIND_MERGES:
			return int(outcome.get("merges", 0)) >= target
		KIND_COMBO:
			return int(outcome.get("best_combo", 0)) >= target
		KIND_NO_POWER:
			return not bool(outcome.get("used_power", false))
	return false


static func awarded(objectives: Array, outcome: Dictionary) -> int:
	var count := 0
	for earned in evaluate(objectives, outcome):
		if earned:
			count += 1
	return count


## Total stars across a stored `level -> stars` map, clamped per level so a
## hand-edited save cannot inflate the header total.
static func total(stars_by_level: Dictionary) -> int:
	var sum := 0
	for key in stars_by_level.keys():
		sum += clampi(int(stars_by_level[key]), 0, MAX_STARS)
	return sum


static func stars_for_level(stars_by_level: Dictionary, level_number: int) -> int:
	return clampi(int(stars_by_level.get(level_number, 0)), 0, MAX_STARS)


## Star row as text, for the map and anywhere a compact readout is wanted.
static func glyphs(earned: int) -> String:
	var filled := clampi(earned, 0, MAX_STARS)
	return "★".repeat(filled) + "☆".repeat(MAX_STARS - filled)


## Separates the rotation from anything else keyed on the level number, so the
## third star does not land in lockstep with the treasure roll or the limited-
## shots cadence.
static func _hash(level_number: int) -> int:
	var value := (maxi(1, level_number) * 2246822519 + 374761393) & 0x7fffffff
	value = ((value >> 15) ^ value) & 0x7fffffff
	value = (value * 2654435761) & 0x7fffffff
	return ((value >> 13) ^ value) & 0x7fffffff
