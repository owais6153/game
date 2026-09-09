extends SceneTree

## Prints the star objectives every level actually ships with, so the numbers can
## be read rather than assumed.
##
## The shot ladder that made every limited level unwinnable was authored by hand
## and never printed; this exists so the same thing cannot happen to stars. Run:
##
##   godot --headless --path . --script scripts/dev/print_level_star_audit.gd
##
## Development only. Nothing in the game loads it.

const LevelConfigType = preload("res://scripts/core/level_config.gd")
const LevelStarsType = preload("res://scripts/core/level_stars.gd")
const LevelSolverType = preload("res://scripts/core/level_solver.gd")

const LEVELS := 120


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("level  band          limited  minShots  starShots  slack%  perfMerges  objective")
	var kind_counts := {}
	var worst_shot_slack := 999.0
	var worst_shot_level := 0
	for level in range(1, LEVELS + 1):
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var objectives := LevelStarsType.objectives_for(config)
		var minimum := LevelSolverType.minimum_shots(config)
		var star_shots := int((objectives[1] as Dictionary).get("target", 0))
		var unlimited := config.duplicate(true)
		unlimited["shot_limit"] = 0
		var perfect_merges := int(LevelSolverType.simulate(unlimited).get("merges", 0))
		var bonus: Dictionary = objectives[2] as Dictionary
		var kind := String(bonus.get("kind", ""))
		kind_counts[kind] = int(kind_counts.get(kind, 0)) + 1
		var slack := 0.0
		if minimum > 0:
			slack = (float(star_shots) / float(minimum) - 1.0) * 100.0
			if slack < worst_shot_slack:
				worst_shot_slack = slack
				worst_shot_level = level
		print("%5d  %-12s  %-7s  %8d  %9d  %5.1f  %10d  %s" % [
			level,
			String(config.get("difficulty_band", "?")),
			"yes" if int(config.get("shot_limit", 0)) > 0 else "no",
			minimum,
			star_shots,
			slack,
			perfect_merges,
			String(bonus.get("text", "")),
		])
	print("")
	print("Third-star distribution over %d levels: %s" % [LEVELS, str(kind_counts)])
	print("Tightest shot star: level %d at +%.1f%% over a perfect play-out" % [worst_shot_level, worst_shot_slack])
	quit(0)
