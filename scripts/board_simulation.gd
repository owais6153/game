class_name BoardSimulation
extends RefCounted

## Contact telemetry is presentation-only. Bonus activation and post-release
## merge holds are explicit controller-authored pacing; radii stay unchanged.
var _collision_impacts: Array[Dictionary] = []
var _activation_holds: Dictionary = {}

func step(pieces: Array[GemPiece], delta: float, merger: ContactMergeService) -> void:
	_collision_impacts.clear()
	_activation_holds.clear()
	for piece in pieces:
		if piece.bonus_activation_delay_remaining > 0.0:
			_activation_holds[piece.id] = true
			piece.bonus_activation_delay_remaining = maxf(0.0, piece.bonus_activation_delay_remaining - delta)
			if piece.bonus_activation_delay_remaining <= 0.0:
				piece.velocity = piece.bonus_pending_velocity
				piece.bonus_pending_velocity = Vector2.ZERO
			# Physics begins on the next simulation step, after one complete visual
			# pop. The sibling grace also does not burn down while this body is held.
			continue
		if piece.bonus_merge_grace_remaining <= 0.0:
			continue
		piece.bonus_merge_grace_remaining = maxf(0.0, piece.bonus_merge_grace_remaining - delta)
		if piece.bonus_merge_grace_remaining <= 0.0:
			piece.bonus_event_id = -1
	var substeps := _required_substeps(pieces, delta)
	var sub_delta := delta / float(substeps)
	for _substep in range(substeps):
		_step_subframe(pieces, sub_delta, merger)

func _step_subframe(pieces: Array[GemPiece], delta: float, merger: ContactMergeService) -> void:
	for piece in pieces:
		if piece.consumed:
			continue
		if _activation_holds.has(piece.id):
			piece.apply_perspective_scale(GameConfig.gem_perspective_scale_at(piece.position.y))
			_resolve_bounds(piece)
			continue
		if not piece.is_moving():
			piece.velocity = Vector2.ZERO
			piece.apply_perspective_scale(GameConfig.gem_perspective_scale_at(piece.position.y))
			_resolve_bounds(piece)
			continue
		piece.position += piece.velocity * delta
		piece.velocity = piece.velocity.move_toward(Vector2.ZERO, GameConfig.VELOCITY_DAMPING_PER_SECOND * delta)
		piece.apply_perspective_scale(GameConfig.gem_perspective_scale_at(piece.position.y))
		_resolve_bounds(piece)
		if piece.velocity.length() < GameConfig.SLEEP_SPEED:
			piece.velocity = Vector2.ZERO
	for piece in pieces:
		if not piece.consumed and not _activation_holds.has(piece.id):
			piece.apply_perspective_scale(GameConfig.gem_perspective_scale_at(piece.position.y))
			_resolve_bounds(piece)
	for first_index in range(pieces.size()):
		var first := pieces[first_index]
		for second_index in range(first_index + 1, pieces.size()):
			_resolve_pair(first, pieces[second_index], merger)

func _required_substeps(pieces: Array[GemPiece], delta: float) -> int:
	var maximum_displacement := 0.0
	var minimum_radius := INF
	for piece in pieces:
		if piece.consumed or _activation_holds.has(piece.id):
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
	var left := GameConfig.table_left_at(piece.position.y) + piece.radius
	var right := GameConfig.table_right_at(piece.position.y) - piece.radius
	var top := GameConfig.board_top() + piece.radius
	var bottom := GameConfig.board_bottom() - piece.radius
	if piece.position.x < left:
		_record_wall_impact(absf(piece.velocity.x), Vector2(left - piece.radius, piece.position.y), piece.id, Vector2.RIGHT)
		piece.position.x = left
		piece.velocity.x = abs(piece.velocity.x) * GameConfig.SIDE_WALL_RESTITUTION
	elif piece.position.x > right:
		_record_wall_impact(absf(piece.velocity.x), Vector2(right + piece.radius, piece.position.y), piece.id, Vector2.LEFT)
		piece.position.x = right
		piece.velocity.x = -abs(piece.velocity.x) * GameConfig.SIDE_WALL_RESTITUTION
	if piece.position.y < top:
		_record_wall_impact(absf(piece.velocity.y), Vector2(piece.position.x, top - piece.radius), piece.id, Vector2.DOWN)
		piece.position.y = top
		piece.velocity.y = abs(piece.velocity.y) * GameConfig.TOP_WALL_RESTITUTION
	elif piece.position.y > bottom:
		_record_wall_impact(absf(piece.velocity.y), Vector2(piece.position.x, bottom + piece.radius), piece.id, Vector2.UP)
		piece.position.y = bottom
		piece.velocity.y = -abs(piece.velocity.y) * GameConfig.BOTTOM_WALL_RESTITUTION

func _resolve_pair(first: GemPiece, second: GemPiece, merger: ContactMergeService) -> void:
	if _activation_holds.has(first.id) or _activation_holds.has(second.id):
		return
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
	if not bonus_release_grace:
		merger.capture_contact(first, second)
	var normal := offset / distance if distance > 0.001 else Vector2.RIGHT
	var overlap := maxf(0.0, minimum_distance - distance)
	if overlap > 0.0:
		var correction := normal * (overlap * 0.5 + GameConfig.SEPARATION_EPSILON)
		first.position -= correction
		second.position += correction
		_resolve_bounds(first)
		_resolve_bounds(second)
	var relative_speed := (second.velocity - first.velocity).dot(normal)
	if relative_speed < 0.0:
		var contact_point := first.position + normal * first.radius
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
