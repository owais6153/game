class_name BoardSimulation
extends RefCounted

## Contact telemetry is presentation-only. Fresh rewards move and collide from
## their first frame; their short merge grace never changes physical response.
var _collision_impacts: Array[Dictionary] = []
## Set by _resolve_pair whenever it actually changed something — separated an
## overlap or applied a contact impulse. It is the early-exit signal for the
## stabilization sweeps: a sweep that changed nothing leaves the board exactly
## as the previous sweep left it, so every sweep after it is a no-op too.
var _sweep_did_work := false

## Slack the broad phase adds over the exact contact distance, as a multiple of
## the largest radius on the board. It covers CONTACT_EPSILON plus the drift the
## separation sweeps introduce while they run, which is what lets one candidate
## list serve every sweep in a subframe.
const BROAD_PHASE_MARGIN_RADII := 2.0
## Sort-key packing. Board coordinates are quantized to sixteenths of a pixel and
## biased positive so the packed key orders exactly as the float edge does.
const BROAD_PHASE_INDEX_STRIDE := 65536
const BROAD_PHASE_EDGE_QUANTIZATION := 16.0
const BROAD_PHASE_EDGE_BIAS := 4096.0

## Table geometry cached for the duration of one step().
##
## _resolve_bounds runs on every piece in every substep and again inside every
## overlapping pair, so on a crowded board it is entered thousands of times per
## frame. Each entry used to re-derive the same four rail values through
## GameConfig.table_left_at/table_right_at/board_top/board_bottom, which between
## them call _table_y six times and table_interpolation twice — roughly ten
## static calls to recompute numbers that cannot change until the viewport is
## reconfigured. These fields hold them for the frame instead. The arithmetic
## below is the same expression GameConfig evaluates, so the bounds are
## identical, not approximated.
var _board_top := 0.0
var _board_bottom := 0.0
var _board_span := 0.0
var _viewport_offset_x := 0.0

func _cache_table_geometry() -> void:
	_board_top = GameConfig.board_top()
	_board_bottom = GameConfig.board_bottom()
	_board_span = _board_bottom - _board_top
	_viewport_offset_x = GameConfig.viewport_center_offset_x

## Mirrors GameConfig.table_interpolation against the cached rails.
func _table_interpolation(y_position: float) -> float:
	if is_zero_approx(_board_span):
		return GameConfig.table_interpolation(y_position)
	return (clampf(y_position, _board_top, _board_bottom) - _board_top) / _board_span

## Mirrors GameConfig.gem_perspective_scale_at against the cached rails.
func _perspective_scale_at(y_position: float) -> float:
	return lerpf(GameConfig.GEM_PERSPECTIVE_SCALE_BACK, GameConfig.GEM_PERSPECTIVE_SCALE_FRONT, _table_interpolation(y_position))

func step(pieces: Array[GemPiece], delta: float, merger: ContactMergeService) -> void:
	_collision_impacts.clear()
	for piece in pieces:
		if piece.bonus_merge_grace_remaining <= 0.0:
			continue
		piece.bonus_merge_grace_remaining = maxf(0.0, piece.bonus_merge_grace_remaining - delta)
		if piece.bonus_merge_grace_remaining <= 0.0:
			piece.bonus_event_id = -1
	_cache_table_geometry()
	var substeps := _required_substeps(pieces, delta)
	var sub_delta := delta / float(substeps)
	for _substep in range(substeps):
		_step_subframe(pieces, sub_delta, merger)

func _step_subframe(pieces: Array[GemPiece], delta: float, merger: ContactMergeService) -> void:
	for piece in pieces:
		if piece.consumed:
			continue
		if not piece.is_moving():
			piece.velocity = Vector2.ZERO
			piece.apply_perspective_scale(_perspective_scale_at(piece.position.y))
			_resolve_bounds(piece)
			continue
		piece.position += piece.velocity * delta
		piece.velocity = piece.velocity.move_toward(Vector2.ZERO, GameConfig.VELOCITY_DAMPING_PER_SECOND * delta)
		piece.apply_perspective_scale(_perspective_scale_at(piece.position.y))
		_resolve_bounds(piece)
		if piece.velocity.length() < GameConfig.SLEEP_SPEED:
			piece.velocity = Vector2.ZERO
	for piece in pieces:
		if not piece.consumed:
			piece.apply_perspective_scale(_perspective_scale_at(piece.position.y))
			_resolve_bounds(piece)
	var pairs := _candidate_pairs(pieces)
	_sweep_did_work = false
	var pair_index := 0
	while pair_index < pairs.size():
		_resolve_pair(pieces[pairs[pair_index]], pieces[pairs[pair_index + 1]], merger)
		pair_index += 2
	# A single pair sweep can leave a visible overlap when one gem is pressed by
	# several neighbours in the same frame. These physics-only stabilization
	# sweeps do not capture another merge or emit duplicate impact telemetry.
	for _pass in range(1, GameConfig.COLLISION_SEPARATION_PASSES):
		# A sweep that separated no overlap and applied no impulse left the board
		# untouched, so every remaining sweep would do the same. A settled board
		# costs one sweep instead of seven, and a crowded one stops as soon as the
		# overlaps it was given are actually relaxed.
		if not _sweep_did_work:
			break
		_sweep_did_work = false
		pair_index = 0
		while pair_index < pairs.size():
			_resolve_pair(pieces[pairs[pair_index]], pieces[pairs[pair_index + 1]], merger, false, false)
			pair_index += 2

## Broad phase for the pair sweeps.
##
## The nested all-pairs loops this replaces cost O(N^2) per sweep: at 40 gems,
## seven separation sweeps and up to eight substeps that is tens of thousands of
## _resolve_pair calls inside a single frame. A fast phone absorbs that; a
## low-end one stalls on it, which is what made merges and pushes hitch on a
## crowded table while the same build ran smoothly elsewhere.
##
## This is a sweep-and-prune on the vertical axis. Gems are ordered by their
## lower edge, and for each gem the sweep walks forward only while the next
## gem's lower edge is still within reach of this gem's upper edge, then rejects
## the rest on X. A uniform grid was tried first and pruned badly here: one cell
## size has to be sized to the largest gem on the board, which on a mixed board
## swallows most of the table in a single neighbourhood.
##
## BROAD_PHASE_MARGIN is slack over the exact contact distance, covering
## CONTACT_EPSILON and the drift the separation sweeps introduce while they run,
## so the list stays valid for all of them and is built once per subframe.
## `tests/run_broad_phase_equivalence_v1_tests.gd` brute-force checks that the
## resulting board is identical to the all-pairs original.
##
## Candidates are emitted in ascending (first_index, second_index) order, the
## order the nested loops visited pairs in, so resolution order — and therefore
## the settled board — is unchanged.
func _candidate_pairs(pieces: Array[GemPiece]) -> PackedInt32Array:
	var pairs := PackedInt32Array()
	var count := pieces.size()
	var maximum_radius := 0.0
	for piece in pieces:
		if not piece.consumed:
			maximum_radius = maxf(maximum_radius, piece.radius)
	if maximum_radius <= 0.0:
		return pairs
	var margin := maximum_radius * BROAD_PHASE_MARGIN_RADII
	# Order by lower edge without a GDScript comparator: the sort key packs the
	# quantized edge above the piece index so one native sort orders both.
	var order := PackedInt64Array()
	for index in range(count):
		var piece := pieces[index]
		if piece.consumed:
			continue
		var edge := int((piece.position.y - piece.radius + BROAD_PHASE_EDGE_BIAS) * BROAD_PHASE_EDGE_QUANTIZATION)
		order.append(edge * BROAD_PHASE_INDEX_STRIDE + index)
	order.sort()
	# Pair keys are packed the same way so that one native sort restores the
	# ascending index order the nested loops used.
	var keys := PackedInt64Array()
	for a in range(order.size()):
		var first_index := int(order[a] % BROAD_PHASE_INDEX_STRIDE)
		var first := pieces[first_index]
		var upper_limit := first.position.y + first.radius + margin
		for b in range(a + 1, order.size()):
			var second_index := int(order[b] % BROAD_PHASE_INDEX_STRIDE)
			var second := pieces[second_index]
			# Ordered by lower edge, so once one gem starts below the reach of
			# this one, every gem after it does too.
			if second.position.y - second.radius > upper_limit:
				break
			var reach := first.radius + second.radius + margin
			if absf(first.position.x - second.position.x) > reach:
				continue
			if first_index < second_index:
				keys.append(first_index * BROAD_PHASE_INDEX_STRIDE + second_index)
			else:
				keys.append(second_index * BROAD_PHASE_INDEX_STRIDE + first_index)
	keys.sort()
	for key in keys:
		pairs.append(int(key / BROAD_PHASE_INDEX_STRIDE))
		pairs.append(int(key % BROAD_PHASE_INDEX_STRIDE))
	return pairs

func _required_substeps(pieces: Array[GemPiece], delta: float) -> int:
	var maximum_displacement := 0.0
	var minimum_radius := INF
	for piece in pieces:
		if piece.consumed:
			continue
		maximum_displacement = maxf(maximum_displacement, piece.velocity.length() * delta)
		minimum_radius = minf(minimum_radius, piece.radius)
	if minimum_radius == INF or maximum_displacement <= 0.0:
		return 1
	var safe_displacement := maxf(1.0, minimum_radius * GameConfig.MAX_SUBSTEP_RADIUS_FRACTION)
	return clampi(int(ceil(maximum_displacement / safe_displacement)), 1, GameConfig.MAX_SIMULATION_SUBSTEPS)

func _resolve_bounds(piece: GemPiece) -> void:
	# This is the proven `new-table-shadow-contact-fix-v1` containment model.
	# It is intentionally the only side-bound authority: the same table
	# interpolation also drives the visual debug rails and launcher clamp.
	var interpolation := _table_interpolation(piece.position.y)
	var left := _viewport_offset_x + lerpf(GameConfig.TABLE_INNER_LEFT_TOP, GameConfig.TABLE_INNER_LEFT_BOTTOM, interpolation) + piece.radius
	var right := _viewport_offset_x + lerpf(GameConfig.TABLE_INNER_RIGHT_TOP, GameConfig.TABLE_INNER_RIGHT_BOTTOM, interpolation) - piece.radius
	var top := _board_top + piece.radius
	var bottom := _board_bottom - piece.radius
	# A piece this call already clamped to a boundary must not immediately
	# re-trigger the same wall impact here or on a later redundant resolve
	# pass this same frame purely from float noise in the recomputed
	# left/right/top/bottom (e.g. a changed piece.radius from perspective
	# scale). Require a measurable crossing, matching the pair-contact
	# tolerance already used elsewhere (GameConfig.SEPARATION_EPSILON).
	if piece.position.x < left - GameConfig.SEPARATION_EPSILON:
		_record_wall_impact(absf(piece.velocity.x), Vector2(left - piece.radius, piece.position.y), piece.id, Vector2.RIGHT)
		piece.position.x = left
		piece.velocity.x = abs(piece.velocity.x) * GameConfig.SIDE_WALL_RESTITUTION
	elif piece.position.x > right + GameConfig.SEPARATION_EPSILON:
		_record_wall_impact(absf(piece.velocity.x), Vector2(right + piece.radius, piece.position.y), piece.id, Vector2.LEFT)
		piece.position.x = right
		piece.velocity.x = -abs(piece.velocity.x) * GameConfig.SIDE_WALL_RESTITUTION
	if piece.position.y < top - GameConfig.SEPARATION_EPSILON:
		_record_wall_impact(absf(piece.velocity.y), Vector2(piece.position.x, top - piece.radius), piece.id, Vector2.DOWN)
		piece.position.y = top
		piece.velocity.y = abs(piece.velocity.y) * GameConfig.TOP_WALL_RESTITUTION
	elif piece.position.y > bottom + GameConfig.SEPARATION_EPSILON:
		_record_wall_impact(absf(piece.velocity.y), Vector2(piece.position.x, bottom + piece.radius), piece.id, Vector2.UP)
		piece.position.y = bottom
		piece.velocity.y = -abs(piece.velocity.y) * GameConfig.BOTTOM_WALL_RESTITUTION

func _resolve_pair(first: GemPiece, second: GemPiece, merger: ContactMergeService, capture_merge: bool = true, record_impact: bool = true) -> void:
	var offset := second.position - first.position
	var distance := offset.length()
	var minimum_distance := first.radius + second.radius
	if distance > minimum_distance + GameConfig.CONTACT_EPSILON:
		return
	# Newly split rewards are allowed to make visible physical contact before
	# they can create another merge. This applies to any pair containing a fresh
	# reward, sharply reducing instant unreadable cascades on crowded boards.
	var bonus_release_grace := first.bonus_merge_grace_remaining > 0.0 \
		or second.bonus_merge_grace_remaining > 0.0
	if capture_merge and not bonus_release_grace:
		merger.capture_contact(first, second)
	var normal := offset / distance if distance > 0.001 else Vector2.RIGHT
	var overlap := maxf(0.0, minimum_distance - distance)
	if overlap > 0.0:
		_sweep_did_work = true
		var correction := normal * (overlap * 0.5 + GameConfig.SEPARATION_EPSILON)
		first.position -= correction
		second.position += correction
		_resolve_bounds(first)
		_resolve_bounds(second)
	var relative_speed := (second.velocity - first.velocity).dot(normal)
	if relative_speed < 0.0:
		_sweep_did_work = true
		var contact_point := first.position + normal * first.radius
		if record_impact:
			_collision_impacts.append({"kind": "gem", "strength": absf(relative_speed), "position": contact_point, "normal": normal, "first_id": first.id, "second_id": second.id})
		# Equal masses share the normal impulse. The former multiplier-only
		# response left the pair moving inward whenever its value was below 0.5,
		# making crowded contacts look sticky. This uses the documented
		# coefficient of restitution and guarantees a bounded separating speed.
		var impulse := -relative_speed * (1.0 + GameConfig.COLLISION_RESTITUTION) * 0.5
		first.velocity -= normal * impulse
		second.velocity += normal * impulse
		# Apply tangential resistance once to an approaching impact. Resting
		# contacts no longer drain sideways motion again on every simulation step.
		var post_impact_relative := second.velocity - first.velocity
		var tangent := post_impact_relative - normal * post_impact_relative.dot(normal)
		var tangential_impulse := tangent * (GameConfig.COLLISION_TANGENTIAL_FRICTION * 0.5)
		first.velocity += tangential_impulse
		second.velocity -= tangential_impulse
	first.velocity = first.velocity.limit_length(GameConfig.MAX_PIECE_SPEED)
	second.velocity = second.velocity.limit_length(GameConfig.MAX_PIECE_SPEED)

func _record_wall_impact(strength: float, contact_position: Vector2, piece_id: int, normal: Vector2) -> void:
	if strength > 0.0:
		_collision_impacts.append({"kind": "wall", "strength": strength, "position": contact_position, "normal": normal, "piece_id": piece_id})

func consume_collision_impacts() -> Array[Dictionary]:
	var result := _collision_impacts.duplicate()
	_collision_impacts.clear()
	return result
