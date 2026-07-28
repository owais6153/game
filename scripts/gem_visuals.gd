class_name GemVisuals
extends RefCounted

# Rendering-only gem kit. It deliberately accepts position/radius/level values
# and has no reference to simulation state, collision, or merge candidates.

static func draw_shadow(canvas: CanvasItem, position: Vector2, radius: float, alpha: float = 0.28) -> void:
	canvas.draw_circle(position + Vector2(5.0, 8.0), radius * 0.92, Color(0.01, 0.02, 0.04, alpha))

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
	canvas.draw_circle(p, r, _with_alpha(Color("e8ddc9"), a))
	canvas.draw_circle(p + Vector2(3, 4), r * 0.78, _with_alpha(Color("b9aa9a"), a * 0.5))
	canvas.draw_circle(p + Vector2(-8, -10), r * 0.34, _with_alpha(Color.WHITE, a * 0.82))
	canvas.draw_arc(p, r, 0.0, TAU, 28, _with_alpha(Color("fff8e8"), a), 2.2)

static func _draw_ruby(canvas: CanvasItem, p: Vector2, r: float, a: float) -> void:
	var points := PackedVector2Array([p + Vector2(-0.72*r, -0.35*r), p + Vector2(0, -r), p + Vector2(0.72*r, -0.35*r), p + Vector2(0.72*r, 0.35*r), p + Vector2(0, r), p + Vector2(-0.72*r, 0.35*r)])
	_polygon(canvas, points, _with_alpha(Color("cb2846"), a), _with_alpha(Color("ffb3bc"), a))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(0.72*r, -0.35*r), p, p + Vector2(-0.72*r, -0.35*r)]), _with_alpha(Color("ff7180"), a * 0.78))
	canvas.draw_line(p + Vector2(-0.72*r, -0.35*r), p, _with_alpha(Color("8c1229"), a), 1.6)
	canvas.draw_line(p + Vector2(0.72*r, -0.35*r), p, _with_alpha(Color("8c1229"), a), 1.6)

static func _draw_emerald(canvas: CanvasItem, p: Vector2, r: float, a: float) -> void:
	var points := PackedVector2Array([p + Vector2(-0.72*r, -r), p + Vector2(0.72*r, -r), p + Vector2(r, -0.68*r), p + Vector2(r, 0.68*r), p + Vector2(0.72*r, r), p + Vector2(-0.72*r, r), p + Vector2(-r, 0.68*r), p + Vector2(-r, -0.68*r)])
	_polygon(canvas, points, _with_alpha(Color("159b62"), a), _with_alpha(Color("9df3c3"), a))
	canvas.draw_rect(Rect2(p + Vector2(-0.65*r, -0.55*r), Vector2(1.3*r, 0.36*r)), _with_alpha(Color("66e6a5"), a * 0.62), true)
	canvas.draw_line(p + Vector2(-r, -0.68*r), p + Vector2(r, 0.68*r), _with_alpha(Color("075e41"), a * 0.72), 1.6)
	canvas.draw_line(p + Vector2(r, -0.68*r), p + Vector2(-r, 0.68*r), _with_alpha(Color("075e41"), a * 0.72), 1.6)

static func _draw_sapphire(canvas: CanvasItem, p: Vector2, r: float, a: float) -> void:
	var points := PackedVector2Array([p + Vector2(-0.64*r, -0.64*r), p, p + Vector2(0.64*r, -0.64*r), p + Vector2(r, 0), p + Vector2(0.64*r, 0.64*r), p, p + Vector2(-0.64*r, 0.64*r), p + Vector2(-r, 0)])
	_polygon(canvas, points, _with_alpha(Color("246fca"), a), _with_alpha(Color("a7dcff"), a))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.64*r, -0.64*r), p, p + Vector2(0.64*r, -0.64*r), p + Vector2(0, -0.18*r)]), _with_alpha(Color("63b8ff"), a * 0.75))
	canvas.draw_line(p + Vector2(-r, 0), p + Vector2(r, 0), _with_alpha(Color("124789"), a), 1.6)
	canvas.draw_line(p + Vector2(0, -r*0.82), p + Vector2(0, r*0.82), _with_alpha(Color("124789"), a), 1.6)

static func _draw_diamond(canvas: CanvasItem, p: Vector2, r: float, a: float) -> void:
	var points := PackedVector2Array([p + Vector2(-0.9*r, -0.28*r), p + Vector2(0, -r), p + Vector2(0.9*r, -0.28*r), p + Vector2(0.54*r, 0.72*r), p, p + Vector2(-0.54*r, 0.72*r)])
	_polygon(canvas, points, _with_alpha(Color("c7f2ff"), a), _with_alpha(Color.WHITE, a))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.9*r, -0.28*r), p, p + Vector2(0.9*r, -0.28*r), p + Vector2(0, 0.18*r)]), _with_alpha(Color.WHITE, a * 0.8))
	canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-0.54*r, 0.72*r), p, p + Vector2(0.54*r, 0.72*r)]), _with_alpha(Color("74cfee"), a * 0.7))
	canvas.draw_line(p + Vector2(0, -r), p + Vector2(0, 0.72*r), _with_alpha(Color("75b7d3"), a), 1.5)
