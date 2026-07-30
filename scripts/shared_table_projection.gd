class_name SharedTableProjection
extends RefCounted

## One bilinear mapping is the only way table-world pixels reach the screen.
## Physics remains in the unprojected table rectangle; renderer and input use
## this helper so gems, rails, launcher, shadows, and the danger line cannot
## drift apart.

static func logical_to_screen(point: Vector2) -> Vector2:
	var u := clampf(point.x / GameConfig.LOGICAL_TABLE_SIZE.x, 0.0, 1.0)
	var v := clampf(point.y / GameConfig.LOGICAL_TABLE_SIZE.y, 0.0, 1.0)
	var top := GameConfig.PROJECTED_TABLE_TOP_LEFT.lerp(GameConfig.PROJECTED_TABLE_TOP_RIGHT, u)
	var bottom := GameConfig.PROJECTED_TABLE_BOTTOM_LEFT.lerp(GameConfig.PROJECTED_TABLE_BOTTOM_RIGHT, u)
	return top.lerp(bottom, v)

static func screen_to_logical(point: Vector2) -> Vector2:
	# The quad is horizontally linear at a given v. Binary search v, then solve
	# u on that row. This is stable for our convex, bottom-anchored trapezoid.
	var low := 0.0
	var high := 1.0
	for _step in 32:
		var v := (low + high) * 0.5
		var left := GameConfig.PROJECTED_TABLE_TOP_LEFT.lerp(GameConfig.PROJECTED_TABLE_BOTTOM_LEFT, v)
		var right := GameConfig.PROJECTED_TABLE_TOP_RIGHT.lerp(GameConfig.PROJECTED_TABLE_BOTTOM_RIGHT, v)
		var row_y := lerpf(left.y, right.y, 0.5)
		if point.y > row_y:
			low = v
		else:
			high = v
	var v := (low + high) * 0.5
	var left := GameConfig.PROJECTED_TABLE_TOP_LEFT.lerp(GameConfig.PROJECTED_TABLE_BOTTOM_LEFT, v)
	var right := GameConfig.PROJECTED_TABLE_TOP_RIGHT.lerp(GameConfig.PROJECTED_TABLE_BOTTOM_RIGHT, v)
	var u := clampf(inverse_lerp(left.x, right.x, point.x), 0.0, 1.0)
	return Vector2(u * GameConfig.LOGICAL_TABLE_SIZE.x, v * GameConfig.LOGICAL_TABLE_SIZE.y)

static func round_trip_error(point: Vector2) -> float:
	return point.distance_to(screen_to_logical(logical_to_screen(point)))
