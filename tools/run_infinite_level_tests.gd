extends SceneTree

const LevelConfigType = preload("res://scripts/level_config.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_seeded_generation()
	_test_catalog_coverage_and_variety()
	if failures.is_empty():
		print("INFINITE_LEVEL_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_seeded_generation() -> void:
	for level_number in range(1, 201):
		var seed_value := LevelConfigType.seed_for_level(level_number)
		var first := LevelConfigType.generated(level_number, seed_value)
		var second := LevelConfigType.generated(level_number, seed_value)
		_check(first == second, "Level %d must regenerate identically from its seed" % level_number)
		var mapping: Dictionary = first.gem_identity_by_tier
		_check(mapping.size() == 8, "Level %d must map exactly eight local ranks" % level_number)
		var unique := {}
		for tier in range(1, 9):
			var identity := int(mapping.get(tier, 0))
			_check(identity >= 1 and identity <= 18, "Level %d tier %d identity is outside L1-L18" % [level_number, tier])
			unique[identity] = true
		_check(unique.size() == 8, "Level %d must use eight unique gems" % level_number)
		var previous_target := 4
		var targets: Array = first.target_sequence
		var expected_target_count := 1 if level_number == 1 else (2 if level_number == 2 or posmod(level_number, 4) == 0 else 3)
		_check(targets.size() == expected_target_count, "Level %d must have %d progression targets" % [level_number, expected_target_count])
		for target in targets:
			var target_rank := int((target as Dictionary).tier)
			_check(target_rank >= 5 and target_rank <= 8, "Level %d target must use local L5-L8" % level_number)
			_check(target_rank > previous_target, "Level %d targets must move strictly forward" % level_number)
			previous_target = target_rank
		for launcher_rank in first.launcher_sequence:
			_check(int(launcher_rank) >= 1 and int(launcher_rank) <= 4, "Level %d launcher must use local L1-L4" % level_number)
		_check((first.launcher_sequence as Array).has(3) and (first.launcher_sequence as Array).has(4), "Level %d must always retain reachable higher launchers" % level_number)
		var expected_band := "INTRO" if level_number == 1 else ("EASY" if level_number == 2 else ("NORMAL" if level_number <= 5 else ("CHALLENGE" if level_number <= 12 else "EXPERT")))
		_check(String(first.difficulty_band) == expected_band, "Level %d must use the expected capped difficulty band" % level_number)

func _test_catalog_coverage_and_variety() -> void:
	var identities := {}
	var backgrounds := {}
	var signatures := {}
	for level_number in range(1, 41):
		var config := LevelConfigType.generated(level_number, LevelConfigType.seed_for_level(level_number))
		var order: Array[int] = []
		for tier in range(1, 9):
			var identity := int((config.gem_identity_by_tier as Dictionary)[tier])
			identities[identity] = true
			order.append(identity)
		backgrounds[int(config.background_index)] = true
		signatures[str(order)] = true
	_check(identities.size() == 18, "The generated level stream must exercise all 18 gems")
	_check(backgrounds.size() == 5, "The generated level stream must exercise all five backgrounds")
	_check(signatures.size() >= 35, "Infinite levels must provide materially different eight-gem paths")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
