class_name BoardSimulation
extends RefCounted

func step(pieces: Array[GemPiece], delta: float, merger: ContactMergeService) -> void:
	for piece in pieces:
		if piece.consumed or not piece.is_moving():
			continue
		piece.position += piece.velocity * delta
		piece.velocity = piece.velocity.move_toward(Vector2.ZERO, GameConfig.VELOCITY_DAMPING_PER_SECOND * delta)
		_resolve_bounds(piece)
		if piece.velocity.length() < GameConfig.SLEEP_SPEED:
			piece.velocity = Vector2.ZERO
	for first_index in range(pieces.size()):
		var first := pieces[first_index]
		for second_index in range(first_index + 1, pieces.size()):
			_resolve_pair(first, pieces[second_index], merger)

func _resolve_bounds(piece: GemPiece) -> void:
	var left := GameConfig.BOARD_LEFT + piece.radius
	var right := GameConfig.BOARD_RIGHT - piece.radius
	var top := GameConfig.BOARD_TOP + piece.radius
	var bottom := GameConfig.BOARD_BOTTOM - piece.radius
	if piece.position.x < left:
		piece.position.x = left
		piece.velocity.x = abs(piece.velocity.x) * GameConfig.SIDE_WALL_RESTITUTION
	elif piece.position.x > right:
		piece.position.x = right
		piece.velocity.x = -abs(piece.velocity.x) * GameConfig.SIDE_WALL_RESTITUTION
	if piece.position.y < top:
		piece.position.y = top
		piece.velocity.y = abs(piece.velocity.y) * GameConfig.TOP_WALL_RESTITUTION
	elif piece.position.y > bottom:
		piece.position.y = bottom
		piece.velocity.y = -abs(piece.velocity.y) * GameConfig.BOTTOM_WALL_RESTITUTION

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
		var impulse := -relative_speed * GameConfig.COLLISION_RESTITUTION
		first.velocity -= normal * impulse
		second.velocity += normal * impulse
