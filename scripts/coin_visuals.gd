class_name CoinVisuals
extends RefCounted

## One procedural coin language shared by the HUD and transient rewards. The
## drawing helper owns no nodes, currency state, input, or gameplay decisions.
static func draw_coin(canvas: CanvasItem, center: Vector2, radius: float, alpha: float = 1.0, spin_phase: float = 0.0) -> void:
	var horizontal_scale := 0.30 + absf(cos(spin_phase)) * 0.70
	canvas.draw_set_transform(center, 0.0, Vector2(horizontal_scale, 1.0))
	canvas.draw_circle(Vector2.ZERO, radius + 2.0, Color(0.63, 0.31, 0.035, alpha * 0.82))
	canvas.draw_circle(Vector2.ZERO, radius, Color(1.0, 0.67, 0.08, alpha))
	canvas.draw_circle(Vector2.ZERO, radius * 0.72, Color(1.0, 0.84, 0.24, alpha))
	canvas.draw_arc(Vector2.ZERO, radius * 0.74, -2.55, -0.52, 14, Color(1.0, 0.97, 0.62, alpha * 0.94), 1.8)
	var mark := PackedVector2Array([
		Vector2(0.0, -radius * 0.40),
		Vector2(radius * 0.18, -radius * 0.08),
		Vector2(radius * 0.10, radius * 0.34),
		Vector2(-radius * 0.12, radius * 0.34),
		Vector2(-radius * 0.19, -radius * 0.08),
	])
	canvas.draw_polyline(mark, Color(0.78, 0.42, 0.045, alpha * 0.88), 1.6)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
