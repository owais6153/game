class_name CoinVisuals
extends RefCounted

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")

## Presentation-only table contact shadow. Callers decide when a coin is close
## enough to the table to cast it; no physics or reward state reads this shape.
static func draw_table_shadow(canvas: CanvasItem, center: Vector2, radius: float, alpha: float, scale: float = 1.0) -> void:
	if alpha <= 0.001:
		return
	canvas.draw_set_transform(center, 0.0, Vector2(1.0, 0.38))
	canvas.draw_circle(Vector2.ZERO, radius * 1.02 * scale, Color(0.10, 0.055, 0.025, alpha))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## One supplied-art coin language shared by the HUD and transient rewards. The
## helper owns no nodes, currency state, input, or gameplay decisions.
static func draw_coin(canvas: CanvasItem, center: Vector2, radius: float, alpha: float = 1.0, spin_phase: float = 0.0, rotation: float = 0.0) -> void:
	# The reference keeps each reward token readable as a circle. Rotation is
	# allowed, but there is no horizontal flip/squash that changes its silhouette.
	canvas.draw_circle(center, radius * 1.02, Color(1.0, 0.78, 0.16, alpha * 0.14))
	canvas.draw_set_transform(center, rotation, Vector2.ONE)
	var draw_size := Vector2.ONE * radius * 2.08
	canvas.draw_texture_rect(AssetCatalogType.COIN_REWARD, Rect2(-draw_size * 0.5, draw_size), false, Color(1.0, 1.0, 1.0, alpha))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
