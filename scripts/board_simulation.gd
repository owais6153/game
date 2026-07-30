class_name BoardSimulation
extends RefCounted

## Presentation feedback only. Simulation never uses this data to decide rules.
var _collision_impacts: Array[Dictionary] = []

func step(pieces: Array[GemPiece], delta: float, merger: ContactMergeService) -> void:
	_collision_impacts.clear()
	for piece in pieces:
		if piece.consumed:
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
		if not piece.consumed:
			piece.apply_perspective_scale(GameConfig.gem_perspective_scale_at(piece.position.y))
			_resolve_bounds(piece)
	for first_index in range(pieces.size()):
		var first := pieces[first_index]
		for second_index in range(first_index + 1, pieces.size()):
			_resolve_pair(first, pieces[second_index], merger)

func _resolve_bounds(piece: GemPiece) -> void:
	var top := GameConfig.BOARD_TOP + piece.radius
	var bottom := GameConfig.BOARD_BOTTOM - piece.radius
	if piece.position.y < top:
		_record_wall_impact(absf(piece.velocity.y), Vector2(piece.position.x, top - piece.radius))
		piece.position.y = top
		piece.velocity.y = abs(piece.velocity.y) * GameConfig.TOP_WALL_RESTITUTION
	elif piece.position.y > bottom:
		_record_wall_impact(absf(piece.velocity.y), Vector2(piece.position.x, bottom + piece.radius))
		piece.position.y = bottom
		piece.velocity.y = -abs(piece.velocity.y) * GameConfig.BOTTOM_WALL_RESTITUTION
	_resolve_slanted_rail(piece, GameConfig.LEFT_RAIL_TOP, GameConfig.left_rail_inward_normal())
	_resolve_slanted_rail(piece, GameConfig.RIGHT_RAIL_TOP, GameConfig.right_rail_inward_normal())

func _resolve_slanted_rail(piece: GemPiece, rail_origin: Vector2, inward_normal: Vector2) -> void:
	# A circle is tangent to a slanted rail at its perpendicular distance, not
	# at `rail_x + radius`. This is the physical counterpart of the visible rail.
	var inward_distance := (piece.position - rail_origin).dot(inward_normal)
	if inward_distance >= piece.radius:
		return
	var correction := piece.radius - inward_distance
	piece.position += inward_normal * correction
	var normal_velocity := piece.velocity.dot(inward_normal)
	if normal_velocity < 0.0:
		_record_wall_impact(absf(normal_velocity), piece.position - inward_normal * piece.radius)
		piece.velocity -= inward_normal * normal_velocity * (1.0 + GameConfig.SIDE_WALL_RESTITUTION)

func _resolve_pair(first: GemPiece, second: GemPiece, merger: ContactMergeService) -> void:
	var offset := second.position - first.position
	var distance := offset.length()
	var minimum_distance := first.radius + second.radius
	if distance > minimum_distance + GameConfig.CONTACT_EPSILON:
		return
	# Capture physical contact before changing positions.
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
		_collision_impacts.append({"kind": "gem", "strength": absf(relative_speed), "position": contact_point})
		var impulse := -relative_speed * GameConfig.COLLISION_RESTITUTION
		first.velocity -= normal * impulse
		second.velocity += normal * impulse
	# Contact resistance makes clusters slide and settle rather than read as
	# rigid frictionless billiard balls. It has no merge authority.
	var post_impact_relative := second.velocity - first.velocity
	var tangent := post_impact_relative - normal * post_impact_relative.dot(normal)
	var tangential_impulse := tangent * (GameConfig.COLLISION_TANGENTIAL_FRICTION * 0.5)
	first.velocity += tangential_impulse
	second.velocity -= tangential_impulse
	first.velocity = first.velocity.limit_length(GameConfig.MAX_PIECE_SPEED)
	second.velocity = second.velocity.limit_length(GameConfig.MAX_PIECE_SPEED)

func _record_wall_impact(strength: float, contact_position: Vector2) -> void:
	if strength > 0.0:
		_collision_impacts.append({"kind": "wall", "strength": strength, "position": contact_position})

func consume_collision_impacts() -> Array[Dictionary]:
	var result := _collision_impacts.duplicate()
	_collision_impacts.clear()
	return result
