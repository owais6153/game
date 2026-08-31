extends SceneTree

## Proves the broad-phase pair sweep in BoardSimulation is a pure optimization.
##
## The simulation used to test every gem against every other gem, seven
## separation sweeps deep, inside every substep. That is O(N^2) per sweep and it
## is what made merges and pushes stall on a crowded table on low-end hardware.
## `_candidate_pairs` now narrows the sweep to gems that can actually reach each
## other, and `_resolve_bounds` reads table geometry cached for the frame rather
## than re-deriving it through GameConfig on every call.
##
## Neither change is allowed to alter the board. This suite pins that down two
## ways: the candidate list must contain every pair the all-pairs loops would
## have acted on, and a long chaotic run must end on byte-identical piece state
## and identical contact telemetry. `tools/bench/board_simulation_baseline.gd`
## is the pre-optimization simulation kept verbatim for this comparison; if the
## physics contract is ever changed on purpose, that baseline must be updated in
## the same task and the reason recorded in the task report.

const GemPieceType = preload("res://scripts/core/gem_piece.gd")
const BoardSimulationType = preload("res://scripts/gameplay/board_simulation.gd")
const BaselineSimulationType = preload("res://tools/bench/board_simulation_baseline.gd")
const MergeServiceType = preload("res://scripts/gameplay/merge_service.gd")

var failures: Array[String] = []


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _init() -> void:
	_test_candidate_list_covers_every_acting_pair()
	_test_simulation_state_is_identical()
	_test_settled_board_skips_redundant_sweeps()
	if failures.is_empty():
		print("BROAD_PHASE_EQUIVALENCE_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		print("  FAIL: %s" % failure)
	print("BROAD_PHASE_EQUIVALENCE_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## Scattered gems at speed. Chaotic on purpose: a relaxation solver amplifies any
## divergence, so an identical end state over many frames is a strong signal.
func _board(seed_value: int, count: int) -> Array[GemPiece]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pieces: Array[GemPiece] = []
	for index in range(count):
		var level := rng.randi_range(1, 6)
		var radius := GameConfig.gem_collision_radius(level)
		var y := rng.randf_range(GameConfig.board_top() + radius, GameConfig.board_bottom() - radius)
		var x := rng.randf_range(GameConfig.table_left_at(y) + radius, GameConfig.table_right_at(y) - radius)
		var piece := GemPieceType.new(index, level, Vector2(x, y), radius)
		piece.velocity = Vector2(rng.randf_range(-900.0, 900.0), rng.randf_range(-900.0, 900.0))
		pieces.append(piece)
	return pieces


## A gem the broad phase omits is never tested for contact, so an omission can
## cost a merge or leave a visible overlap. Every pair within contact range must
## be present, and the list must stay in the ascending order the nested loops
## resolved pairs in — a relaxation sweep is order-dependent.
func _test_candidate_list_covers_every_acting_pair() -> void:
	var missing := 0
	var out_of_order := 0
	var candidate_total := 0
	var brute_force_total := 0
	for seed_value in range(30):
		for count in [8, 20, 35, 50]:
			var pieces := _board(seed_value * 97 + count, count)
			var simulation := BoardSimulationType.new()
			simulation._cache_table_geometry()
			var pairs: PackedInt32Array = simulation._candidate_pairs(pieces)
			var present: Dictionary = {}
			var previous_first := -1
			var previous_second := -1
			var index := 0
			while index < pairs.size():
				var first := pairs[index]
				var second := pairs[index + 1]
				if second <= first or first < previous_first or (first == previous_first and second <= previous_second):
					out_of_order += 1
				previous_first = first
				previous_second = second
				present[first * 65536 + second] = true
				index += 2
			candidate_total += pairs.size() / 2
			for i in range(pieces.size()):
				for j in range(i + 1, pieces.size()):
					brute_force_total += 1
					var contact_distance := pieces[i].radius + pieces[j].radius + GameConfig.CONTACT_EPSILON
					if pieces[i].position.distance_to(pieces[j].position) <= contact_distance:
						if not present.has(i * 65536 + j):
							missing += 1
	_assert(missing == 0, "Broad phase omitted %d pairs that were within contact range" % missing)
	_assert(out_of_order == 0, "Broad phase emitted %d candidates out of ascending index order" % out_of_order)
	_assert(candidate_total < brute_force_total, "Broad phase must test fewer pairs than the all-pairs sweep (%d vs %d)" % [candidate_total, brute_force_total])


func _test_simulation_state_is_identical() -> void:
	var state_mismatches := 0
	var telemetry_mismatches := 0
	for seed_value in range(12):
		for count in [6, 15, 28, 44]:
			var baseline := _play(BaselineSimulationType.new(), _board(seed_value * 31 + count, count), 90)
			var optimized := _play(BoardSimulationType.new(), _board(seed_value * 31 + count, count), 90)
			var baseline_pieces: Array = baseline[0]
			var optimized_pieces: Array = optimized[0]
			if baseline_pieces.size() != optimized_pieces.size():
				state_mismatches += 1
				continue
			for index in range(baseline_pieces.size()):
				var expected: GemPiece = baseline_pieces[index]
				var actual: GemPiece = optimized_pieces[index]
				if expected.position != actual.position or expected.velocity != actual.velocity or expected.radius != actual.radius:
					state_mismatches += 1
			if baseline[1] != optimized[1]:
				telemetry_mismatches += 1
	_assert(state_mismatches == 0, "Optimized simulation diverged from the all-pairs baseline on %d pieces" % state_mismatches)
	_assert(telemetry_mismatches == 0, "Optimized simulation produced different contact telemetry on %d boards" % telemetry_mismatches)


func _play(simulation, pieces: Array[GemPiece], frames: int) -> Array:
	var merger := MergeServiceType.new()
	var telemetry: Array[String] = []
	for frame in range(frames):
		simulation.step(pieces, 1.0 / 60.0, merger)
		for impact in simulation.consume_collision_impacts():
			telemetry.append("%s|%.6f|%.4f,%.4f" % [impact.kind, impact.strength, impact.position.x, impact.position.y])
		merger.clear()
	return [pieces, telemetry]


## The separation sweeps exist to relax overlaps. On a board where nothing is in
## contact there is nothing to relax, so the sweeps after the first must be
## skipped rather than walked. This is the case a settled table sits in between
## shots, which is most of the session.
func _test_settled_board_skips_redundant_sweeps() -> void:
	var pieces: Array[GemPiece] = []
	var y := GameConfig.board_bottom() - 120.0
	var spacing := GameConfig.gem_collision_radius(1) * 4.0
	var x := GameConfig.table_left_at(y) + spacing
	var index := 0
	while x < GameConfig.table_right_at(y) - spacing and index < 6:
		pieces.append(GemPieceType.new(index, 1, Vector2(x, y), GameConfig.gem_collision_radius(1)))
		x += spacing
		index += 1
	_assert(pieces.size() >= 3, "Settled-board case needs a few separated gems to be meaningful")
	var simulation := BoardSimulationType.new()
	var merger := MergeServiceType.new()
	simulation.step(pieces, 1.0 / 60.0, merger)
	_assert(not simulation._sweep_did_work, "Well-separated resting gems give the sweeps nothing to do, so the extra sweeps are skipped")
	for piece in pieces:
		_assert(piece.velocity == Vector2.ZERO, "A settled gem must stay at rest through a step")
