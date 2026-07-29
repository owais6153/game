class_name GemVisuals
extends RefCounted

# Rendering-only gem kit. It deliberately accepts position/radius/level values
# and has no reference to simulation state, collision, or merge candidates.

static func draw_shadow(canvas: CanvasItem, position: Vector2, radius: float, alpha: float = 0.28) -> void:
	# Two very small flat shadows give depth without blur, shaders, or extra nodes.
	canvas.draw_circle(position + Vector2(4.0, 7.0), radius * 0.94, Color(0.01, 0.02, 0.04, alpha * 0.36))
	canvas.draw_circle(position + Vector2(3.0, 5.0), radius * 0.78, Color(0.01, 0.02, 0.04, alpha * 0.64))

static func draw_gem(canvas: CanvasItem, level: int, position: Vector2, radius: float, alpha: float = 1.0, scale: float = 1.0) -> void:
	var gem_radius := radius * scale
	match level:
		1: _draw_pearl(canvas, position, gem_radius, alpha)
		2: _draw_ruby(canvas, position, gem_radius, alpha)
		3: _draw_emerald(canvas, position, gem_radius, alpha)
		4: _draw_sapphire(canvas, position, gem_radius, alpha)
		5: _draw_diamond(canvas, position, gem_radius, alpha)
		_: _draw_pearl(canvas, position, gem_radius, alpha)

static func visual_style_name(level: int) -> String:
	match level:
		1: return "round pearl with soft highlight"
		2: return "faceted ruby"
		3: return "emerald-cut gem"
		4: return "faceted sapphire"
		5: return "multi-facet diamond"
		_: return "unknown"

static func _with_alpha(color: Color, alpha: float) -> Color:
	color.a *= alpha
	return color

static func _polygon(canvas: CanvasItem, points: PackedVector2Array, color: Color, outline: Color, width: float = 2.0) -> void:
	canvas.draw_colored_polygon(points, color)
	canvas.draw_polyline(points + PackedVector2Array([points[0]]), outline, width, true)

static func _draw_pearl(canvas: CanvasItem, p: Vector2, r: float, a: float) -> void:
	canvas.draw_circle(p, r, _with_alpha(Color("b9a990"), a))
	canvas.draw_circle(p + Vector2(-1, -2), r * 0.93, _with_alpha(Color("efe3ca"), a))
	canvas.draw_circle(p + Vector2(5, 7), r * 0.61, _with_alpha(Color("c8b8a0"), a * 0.55))
	canvas.draw_circle(p + Vector2(-9, -11), r * 0.27, _with_alpha(Color.WHITE, a * 0.86))
	canvas.draw_arc(p, r, 0.0, TAU, 28, _with_alpha(Color("fff8e8"), a), 2.0)

static func _draw_ruby(canvas: CanvasItem, p: Vector2, r: float, a: float) -> void:
	var points := PackedVector2Array([p + Vector2(-0.72*r, -0.35*r), p + Vector2(0, -r), p + Vector2(0.72*r, -0.35*r), p + Vector2(0.72*r, 0.35*r), p + Vector2(0, r), p + Vector2(-0.72*r, 0.35*r)])
	_polygon(canvas, points, _with_alpha(Color("c52142"), a), _with_alpha(Color("ffbdc8"), a))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(0.72*r, -0.35*r), p, p + Vector2(-0.72*r, -0.35*r)]), _with_alpha(Color("ff7180"), a * 0.78))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.72*r, 0.35*r), p, p + Vector2(0.72*r, 0.35*r), p + Vector2(0, r)]), _with_alpha(Color("85132a"), a * 0.56))
	canvas.draw_line(p + Vector2(-0.72*r, -0.35*r), p, _with_alpha(Color("8c1229"), a), 1.6)
	canvas.draw_line(p + Vector2(0.72*r, -0.35*r), p, _with_alpha(Color("8c1229"), a), 1.6)

static func _draw_emerald(canvas: CanvasItem, p: Vector2, r: float, a: float) -> void:
	var points := PackedVector2Array([p + Vector2(-0.72*r, -r), p + Vector2(0.72*r, -r), p + Vector2(r, -0.68*r), p + Vector2(r, 0.68*r), p + Vector2(0.72*r, r), p + Vector2(-0.72*r, r), p + Vector2(-r, 0.68*r), p + Vector2(-r, -0.68*r)])
	_polygon(canvas, points, _with_alpha(Color("118b59"), a), _with_alpha(Color("a8f2c8"), a))
	canvas.draw_rect(Rect2(p + Vector2(-0.66*r, -0.56*r), Vector2(1.32*r, 0.34*r)), _with_alpha(Color("78efb2"), a * 0.58), true)
	canvas.draw_rect(Rect2(p + Vector2(-0.64*r, 0.31*r), Vector2(1.28*r, 0.26*r)), _with_alpha(Color("07583d"), a * 0.34), true)
	canvas.draw_line(p + Vector2(-r, -0.68*r), p + Vector2(r, 0.68*r), _with_alpha(Color("075e41"), a * 0.72), 1.6)
	canvas.draw_line(p + Vector2(r, -0.68*r), p + Vector2(-r, 0.68*r), _with_alpha(Color("075e41"), a * 0.72), 1.6)

static func _draw_sapphire(canvas: CanvasItem, p: Vector2, r: float, a: float) -> void:
	var points := PackedVector2Array([p + Vector2(-0.64*r, -0.64*r), p, p + Vector2(0.64*r, -0.64*r), p + Vector2(r, 0), p + Vector2(0.64*r, 0.64*r), p, p + Vector2(-0.64*r, 0.64*r), p + Vector2(-r, 0)])
	_polygon(canvas, points, _with_alpha(Color("1e64bd"), a), _with_alpha(Color("b2e2ff"), a))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.64*r, -0.64*r), p, p + Vector2(0.64*r, -0.64*r), p + Vector2(0, -0.18*r)]), _with_alpha(Color("63b8ff"), a * 0.75))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.64*r, 0.64*r), p, p + Vector2(0.64*r, 0.64*r), p + Vector2(0, 0.18*r)]), _with_alpha(Color("103e7d"), a * 0.52))
	canvas.draw_line(p + Vector2(-r, 0), p + Vector2(r, 0), _with_alpha(Color("124789"), a), 1.6)
	canvas.draw_line(p + Vector2(0, -r*0.82), p + Vector2(0, r*0.82), _with_alpha(Color("124789"), a), 1.6)

static func _draw_diamond(canvas: CanvasItem, p: Vector2, r: float, a: float) -> void:
	var points := PackedVector2Array([p + Vector2(-0.9*r, -0.28*r), p + Vector2(0, -r), p + Vector2(0.9*r, -0.28*r), p + Vector2(0.54*r, 0.72*r), p, p + Vector2(-0.54*r, 0.72*r)])
	_polygon(canvas, points, _with_alpha(Color("bcecff"), a), _with_alpha(Color.WHITE, a))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.9*r, -0.28*r), p, p + Vector2(0.9*r, -0.28*r), p + Vector2(0, 0.18*r)]), _with_alpha(Color.WHITE, a * 0.8))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.54*r, 0.72*r), p, p + Vector2(0.54*r, 0.72*r)]), _with_alpha(Color("74cfee"), a * 0.7))
	canvas.draw_line(p + Vector2(0, -r), p + Vector2(0, 0.72*r), _with_alpha(Color("75b7d3"), a), 1.5)
	canvas.draw_line(p + Vector2(-0.9*r, -0.28*r), p + Vector2(0.54*r, 0.72*r), _with_alpha(Color("82cce5"), a * 0.72), 1.3)
