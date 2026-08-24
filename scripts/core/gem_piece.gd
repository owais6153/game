class_name GemPiece
extends RefCounted

var id: int
var level: int
var position: Vector2
var velocity: Vector2 = Vector2.ZERO
var radius: float
var base_radius: float
var perspective_scale: float = 1.0
var is_active_launcher: bool = false
var consumed: bool = false
## Bonus pieces are ordinary gameplay pieces. Physics is active on their first
## visible frame; release grace only delays follow-up merge confirmation so the
## immediate motion and physical contacts remain readable.
var bonus_event_id := -1
var bonus_merge_grace_remaining := 0.0

func _init(piece_id: int, piece_level: int, at_position: Vector2, piece_radius: float) -> void:
	id = piece_id
	level = piece_level
	position = at_position
	base_radius = piece_radius
	apply_perspective_scale(GameConfig.gem_perspective_scale_at(at_position.y))

func apply_perspective_scale(next_scale: float) -> void:
	perspective_scale = clampf(next_scale, GameConfig.GEM_PERSPECTIVE_SCALE_BACK, GameConfig.GEM_PERSPECTIVE_SCALE_FRONT)
	radius = base_radius * perspective_scale

func is_moving() -> bool:
	return velocity.length() > GameConfig.SLEEP_SPEED

func is_settled() -> bool:
	return not is_moving()
