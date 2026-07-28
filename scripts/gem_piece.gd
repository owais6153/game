class_name GemPiece
extends RefCounted

var id: int
var level: int
var position: Vector2
var velocity: Vector2 = Vector2.ZERO
var radius: float
var is_active_launcher: bool = false
var consumed: bool = false

func _init(piece_id: int, piece_level: int, at_position: Vector2, piece_radius: float) -> void:
	id = piece_id
	level = piece_level
	position = at_position
	radius = piece_radius

func is_moving() -> bool:
	return velocity.length() > GameConfig.SLEEP_SPEED

func is_settled() -> bool:
	return not is_moving()