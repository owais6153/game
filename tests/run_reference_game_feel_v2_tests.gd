extends SceneTree

const SimulationType = preload("res://scripts/gameplay/board_simulation.gd")
const MergeServiceType = preload("res://scripts/gameplay/merge_service.gd")
const PieceType = preload("res://scripts/core/gem_piece.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_visible_separation_does_not_merge()
	_test_exact_contact_merges_once()
	_test_visible_touch_tolerance_merges_once()
	_test_slight_overlap_merges_once()
	_test_different_types_collide_without_merge()
	_test_fast_shot_contact_is_substepped()
	_test_resting_piece_pushed_into_match()
	_test_dense_pile_separates_without_duplicate_contact()
	_test_chain_requires_each_contact()
	_test_feedback_contracts()
	if failures.is_empty():
		print("REFERENCE_GAME_FEEL_V2_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("REFERENCE_GAME_FEEL_V2_TESTS: FAIL (%d)" % failures.size())
	quit(1)

func _piece(id: int, level: int, position: Vector2, velocity := Vector2.ZERO) -> GemPiece:
	var piece := PieceType.new(id, level, position, GameConfig.gem_collision_radius(level))
	piece.apply_perspective_scale(GameConfig.gem_perspective_scale_at(position.y))
	piece.velocity = velocity
	return piece

func _resolve(pieces: Array[GemPiece], delta: float = 0.0) -> Dictionary:
	var merger := MergeServiceType.new()
	merger.max_result_level = 8
	var simulation := SimulationType.new()
	simulation.step(pieces, delta, merger)
	return merger.resolve_with_chains(pieces, 100)

func _test_visible_separation_does_not_merge() -> void:
	var radius := GameConfig.gem_collision_radius(1) * GameConfig.gem_perspective_scale_at(700)
	var result := _resolve([_piece(1, 1, Vector2(300, 700)), _piece(2, 1, Vector2(300 + radius * 2.0 + GameConfig.VISIBLE_CONTACT_TOLERANCE + 0.1, 700))])
	_assert(result.merge_count == 0, "Visibly separated matching gems must not merge")

func _test_exact_contact_merges_once() -> void:
	var radius := GameConfig.gem_collision_radius(1) * GameConfig.gem_perspective_scale_at(700)
	var result := _resolve([_piece(1, 1, Vector2(300, 700)), _piece(2, 1, Vector2(300 + radius * 2.0, 700))])
	_assert(result.merge_count == 1 and result.pieces.size() == 1, "Exact physical contact must merge exactly once")

func _test_visible_touch_tolerance_merges_once() -> void:
	var radius := GameConfig.gem_collision_radius(1) * GameConfig.gem_perspective_scale_at(700)
	var result := _resolve([_piece(1, 1, Vector2(300, 700)), _piece(2, 1, Vector2(300 + radius * 2.0 + GameConfig.VISIBLE_CONTACT_TOLERANCE - 0.1, 700))])
	_assert(result.merge_count == 1 and result.pieces.size() == 1, "Matching gems inside the calibrated visible-touch band must merge")

func _test_slight_overlap_merges_once() -> void:
	var radius := GameConfig.gem_collision_radius(1) * GameConfig.gem_perspective_scale_at(700)
	var result := _resolve([_piece(1, 1, Vector2(300, 700)), _piece(2, 1, Vector2(300 + radius * 2.0 - 1.0, 700))])
	_assert(result.merge_count == 1 and result.presentation_events.size() == 1, "A physics-step overlap must merge exactly once")

func _test_different_types_collide_without_merge() -> void:
	var first := _piece(1, 1, Vector2(300, 700), Vector2(120, 0))
	var second_radius := GameConfig.gem_collision_radius(2) * GameConfig.gem_perspective_scale_at(700)
	var second := _piece(2, 2, Vector2(300 + first.radius + second_radius, 700), Vector2.ZERO)
	var result := _resolve([first, second], 1.0 / 60.0)
	_assert(result.merge_count == 0 and result.pieces.size() == 2, "Different tiers must collide physically without merging")
	_assert(first.velocity.x < 120.0 or second.velocity.x > 0.0, "Different-tier contact must produce a collision response")

func _test_fast_shot_contact_is_substepped() -> void:
	var moving := _piece(1, 1, Vector2(300, 820), Vector2(0, -GameConfig.LAUNCH_SPEED))
	var resting := _piece(2, 1, Vector2(300, 700))
	var result := _resolve([moving, resting], 0.10)
	_assert(result.merge_count == 1, "A fast shot must not tunnel through a matching gem during a long frame")

func _test_resting_piece_pushed_into_match() -> void:
	var radius := GameConfig.gem_collision_radius(1) * GameConfig.gem_perspective_scale_at(700)
	var resting := _piece(1, 1, Vector2(300, 700))
	var pushed := _piece(2, 1, Vector2(300 + radius * 2.0 + 4.0, 700), Vector2(-120, 0))
	var result := _resolve([resting, pushed], 0.05)
	_assert(result.merge_count == 1, "A resting match pushed into contact must register")

func _test_dense_pile_separates_without_duplicate_contact() -> void:
	var simulation := SimulationType.new()
	var merger := MergeServiceType.new()
	merger.max_result_level = 8
	# Different tiers deliberately prevent merge consumption while three bodies
	# begin in one crowded contact cluster.
	var pieces: Array[GemPiece] = [
		_piece(31, 1, Vector2(330, 700)),
		_piece(32, 2, Vector2(390, 700)),
		_piece(33, 3, Vector2(360, 750)),
	]
	simulation.step(pieces, 0.0, merger)
	for first_index in range(pieces.size()):
		for second_index in range(first_index + 1, pieces.size()):
			var first := pieces[first_index]
			var second := pieces[second_index]
			_assert(first.position.distance_to(second.position) + 0.001 >= first.radius + second.radius, "Dense non-matching gems must finish a simulation step without overlap")
	_assert(merger.resolve_with_chains(pieces, 100).merge_count == 0, "Physics-only stabilization must not create a merge for different tiers")

func _test_chain_requires_each_contact() -> void:
	var r1 := GameConfig.gem_collision_radius(1) * GameConfig.gem_perspective_scale_at(700)
	var r2 := GameConfig.gem_collision_radius(2) * GameConfig.gem_perspective_scale_at(700)
	var touching: Array[GemPiece] = [_piece(1, 1, Vector2(300 - r1, 700)), _piece(2, 1, Vector2(300 + r1, 700)), _piece(3, 2, Vector2(300, 700))]
	var chain := _resolve(touching)
	_assert(chain.merge_count == 2, "A chain may continue only when the created result physically touches its next match")
	# Chains now reach slightly beyond touching, by CHAIN_CONTACT_TOLERANCE, so a
	# combo is a reward for good placement rather than a coincidence. The reach
	# is bounded, and that bound is the contract: a gem just past touching must
	# chain, one clearly beyond the tolerance must not.
	var within: Array[GemPiece] = [_piece(21, 1, Vector2(300 - r1, 700)), _piece(22, 1, Vector2(300 + r1, 700)), _piece(23, 2, Vector2(300, 700 - r2 * 2.0 - GameConfig.CHAIN_CONTACT_TOLERANCE * 0.5))]
	_assert(_resolve(within).merge_count == 2,
		"a follow-up gem inside the chain tolerance must continue the chain")
	var separated: Array[GemPiece] = [_piece(11, 1, Vector2(300 - r1, 700)), _piece(12, 1, Vector2(300 + r1, 700)), _piece(13, 2, Vector2(300, 700 - r2 * 2.0 - GameConfig.CHAIN_CONTACT_TOLERANCE - 12.0))]
	var no_chain := _resolve(separated)
	_assert(no_chain.merge_count == 1, "A gem beyond the chain tolerance must not proximity-chain")

func _test_feedback_contracts() -> void:
	# Reward feedback v3 replaces the 270 ms window with the approved 420 ms merge
	# timeline. Contact, merge eligibility, and physics values are unchanged.
	_assert(GameConfig.MERGE_RESULT_POP_SCALE == 1.24 and GameConfig.MERGE_PRESENTATION_DURATION == 0.42 and GameConfig.MERGE_SOURCE_PULL_DURATION == 0.080, "Merge and push animation must retain the approved readable reward cadence")
	_assert(GameConfig.COIN_FLIGHT_DURATION == 0.55 and GameConfig.MAJOR_COIN_FLIGHT_DURATION == 0.62 and GameConfig.COIN_FLIGHT_STAGGER == 0.08, "Coin flights must retain the restored readable cadence")
	_assert(GameConfig.TARGET_COLLECTION_DURATION == 0.70, "Target collection must retain the restored readable cadence")
	# Raised from three, which left a gem pressed by several neighbours visibly
	# overlapping. What matters is that the sweep count stays bounded and cheap -
	# it is O(n^2) per pass - not that it is any particular literal.
	_assert(GameConfig.COLLISION_SEPARATION_PASSES >= 3 and GameConfig.COLLISION_SEPARATION_PASSES <= 8,
		"Dense-pile stabilization must stay bounded to a small number of pair sweeps")
	var overlay_source := FileAccess.get_file_as_string("res://scripts/presentation/target_reward_overlay.gd")
	_assert(not overlay_source.contains("check_points") and not overlay_source.contains("draw_polyline"), "Target confirmation must not render a checkmark")
	_assert(float(GameConfig.AUDIO_TONES.normal_merge.volume) > float(GameConfig.AUDIO_TONES.gem_contact.volume) * 1.4, "Merge audio must clearly dominate normal collision")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
