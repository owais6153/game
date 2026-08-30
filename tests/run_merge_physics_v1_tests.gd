extends SceneTree

## Covers three reported gameplay defects:
##  - gems visibly overlapping,
##  - gems visibly touching a match and refusing to merge,
##  - chains that almost never continue past Combo 1.

const BoardSimulationType = preload("res://scripts/gameplay/board_simulation.gd")
const MergeServiceType = preload("res://scripts/gameplay/merge_service.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_dense_cluster_settles_without_overlap()
	_test_touching_matches_always_merge()
	_test_fresh_bonus_gems_rejoin_quickly()
	_test_chains_can_reach_combo_two()
	_test_merges_use_dense_coloured_waves_without_shards()
	if failures.is_empty():
		print("MERGE_PHYSICS_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("MERGE_PHYSICS_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## A gem pressed by several neighbours at once was left visibly overlapping,
## because only three separation sweeps ran per frame.
func _test_dense_cluster_settles_without_overlap() -> void:
	var simulation := BoardSimulationType.new()
	var merger := MergeServiceType.new()
	var pieces: Array[GemPiece] = []
	var identifier := 400
	# Deliberately packed tighter than resting spacing, in mixed tiers so
	# nothing merges away and the separation itself is what is measured.
	for row in range(4):
		for column in range(5):
			var tier := 1 + ((row + column) % 4)
			var radius := GameConfig.gem_collision_radius(tier)
			var position := Vector2(
				260.0 + float(column) * radius * 0.9,
				GameConfig.danger_line_y() - 260.0 + float(row) * radius * 0.9
			)
			pieces.append(GemPiece.new(identifier, tier, position, radius))
			identifier += 1
	for _frame in range(120):
		simulation.step(pieces, 1.0 / 60.0, merger)

	var worst := 0.0
	for first_index in range(pieces.size()):
		for second_index in range(first_index + 1, pieces.size()):
			var first := pieces[first_index]
			var second := pieces[second_index]
			if first.consumed or second.consumed:
				continue
			var overlap := (first.radius + second.radius) - first.position.distance_to(second.position)
			worst = maxf(worst, overlap)
	_assert(worst <= GameConfig.VISIBLE_CONTACT_TOLERANCE,
		"a settled cluster must not stay visibly overlapped (worst overlap %.2fpx)" % worst)


## Two same-tier gems resting in contact must always produce a merge candidate.
func _test_touching_matches_always_merge() -> void:
	for tier in range(1, GameConfig.MAX_GEM_LEVEL):
		if tier >= GameConfig.MAX_GEM_LEVEL:
			break
		var simulation := BoardSimulationType.new()
		var merger := MergeServiceType.new()
		var base_radius := GameConfig.gem_collision_radius(tier)
		var y := GameConfig.danger_line_y() - 300.0
		# GemPiece applies a perspective scale on construction, so its live radius
		# is smaller than the catalog value. Position from the scaled radius or the
		# pair is placed apart and never touches.
		var radius := base_radius * GameConfig.gem_perspective_scale_at(y)
		var pieces: Array[GemPiece] = [
			GemPiece.new(1, tier, Vector2(340.0 - radius, y), base_radius),
			GemPiece.new(2, tier, Vector2(340.0 + radius, y), base_radius),
		]
		simulation.step(pieces, 1.0 / 60.0, merger)
		var resolved := merger.resolve_with_chains(pieces, 900)
		_assert(int(resolved.merge_count) >= 1,
			"two touching tier-%d gems must merge, not sit there" % tier)
		if tier >= 8:
			break


## Bonus gems spawn on every merge, so a long grace meant there was almost
## always a gem visibly touching a match and refusing to combine.
func _test_fresh_bonus_gems_rejoin_quickly() -> void:
	_assert(GameConfig.BONUS_MERGE_GRACE_MS <= 250,
		"a fresh bonus gem must rejoin merging quickly (grace %dms reads as broken)"
			% GameConfig.BONUS_MERGE_GRACE_MS)
	_assert(GameConfig.BONUS_MERGE_GRACE_MS > 0,
		"some grace must remain so the spawn pop stays readable")


## Combo 1 was effectively the ceiling: a chain needed the merged gem to be
## already touching another of its new tier to within two pixels.
func _test_chains_can_reach_combo_two() -> void:
	var merger := MergeServiceType.new()
	var y := GameConfig.danger_line_y() - 300.0
	var scale := GameConfig.gem_perspective_scale_at(y)
	var r1 := GameConfig.gem_collision_radius(1) * scale
	var r2 := GameConfig.gem_collision_radius(2) * scale
	# Two tier-1s merge into a tier-2, which then reaches a tier-2 sitting just
	# beyond touching - the case that previously stopped the chain dead.
	var pieces: Array[GemPiece] = [
		GemPiece.new(1, 1, Vector2(340.0 - r1, y), GameConfig.gem_collision_radius(1)),
		GemPiece.new(2, 1, Vector2(340.0 + r1, y), GameConfig.gem_collision_radius(1)),
		# A fixed 14px beyond touching, not a fraction of the tolerance: scaling the
		# gap with the constant would make this assertion unfalsifiable. 14px is far
		# outside the old 2px contact window and inside the current chain window.
		GemPiece.new(3, 2, Vector2(340.0, y - r2 * 2.0 - 14.0), GameConfig.gem_collision_radius(2)),
	]
	merger.capture_contact(pieces[0], pieces[1])
	var resolved := merger.resolve_with_chains(pieces, 900)
	_assert(int(resolved.merge_count) >= 2,
		"a near-adjacent same-tier gem must continue the chain (merges %d)" % int(resolved.merge_count))
	_assert(GameConfig.CHAIN_CONTACT_TOLERANCE > 14.0,
		"the chain window must exceed the distance this test places its gem at")
	_assert(int(resolved.chain_depth) >= 1,
		"the chain must report depth, which is what drives Combo 2 feedback")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


## Dense concentric wavefronts now carry the cinematic weight without a moving
## shard array that can build up during repeated chains.
func _test_merges_use_dense_coloured_waves_without_shards() -> void:
	var effects = preload("res://scripts/presentation/gameplay_effects_layer.gd").new()
	root.add_child(effects)
	effects.begin_merge_feedback({
		"result_id": 1, "midpoint": Vector2(360.0, 800.0), "level": 4, "depth": 0,
		"timeline": GameConfig.MERGE_TIMELINE_NORMAL,
	})
	var ordinary: Dictionary = effects.merge_impacts[0]
	_assert(int(ordinary.get("ring_layers", 0)) >= 3,
		"an ordinary merge must use a dense multi-wave impact")

	# A target merge is a bigger moment and must throw more.
	effects.clear()
	effects.begin_merge_feedback({
		"result_id": 2, "midpoint": Vector2(360.0, 800.0), "level": 8, "depth": 0,
		"target_objective_completed": true,
		"timeline": GameConfig.MERGE_TIMELINE_TARGET,
	})
	var target: Dictionary = effects.merge_impacts[0]
	_assert(int(target.get("ring_layers", 0)) > int(ordinary.get("ring_layers", 0)),
		"a high target merge must use more wavefronts than an ordinary merge")
	_assert(GameConfig.merge_vfx_tier_scale(8) > GameConfig.merge_vfx_tier_scale(4)
		and GameConfig.merge_vfx_spark_count(8) > GameConfig.merge_vfx_spark_count(4),
		"larger result tiers must map to a bolder, shinier VFX tier")
	_assert(GameConfig.gem_color(4) != GameConfig.gem_color(8),
		"merge VFX must retain the exact result gem's colour identity")

	# Bounded, self-expiring, and cleared with the rest of the layer.
	effects.clear()
	for index in range(40):
		effects.begin_merge_feedback({
			"result_id": index, "midpoint": Vector2(360.0, 800.0), "level": 7, "depth": 2,
			"timeline": GameConfig.MERGE_TIMELINE_COMBO_2,
		})
	_assert(effects.merge_impacts.size() <= 12,
		"merge waves must stay bounded under repeated bursts (%d)" % effects.merge_impacts.size())
	for _frame in range(90):
		effects.update_effects(1.0 / 60.0)
	_assert(effects.merge_impacts.is_empty(),
		"merge waves must expire on their own rather than accumulating")
	effects.clear()
	_assert(effects.merge_impacts.is_empty(), "clear() must drop every merge wave")
	effects.queue_free()
