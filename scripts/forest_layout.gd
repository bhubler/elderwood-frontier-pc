extends RefCounted
## Ground routes shared by terrain art and tree placement.

const ROADS := [
	[Vector2(-760, 50), Vector2(-370, 55), Vector2(-100, 40), Vector2(170, 20), Vector2(640, 65)],
	[Vector2(0, -610), Vector2(-10, -280), Vector2(0, 40), Vector2(-20, 480), Vector2(-40, 720)],
	[Vector2(-95, 35), Vector2(-290, 130), Vector2(-480, 225)],
	[Vector2(80, 30), Vector2(260, -110), Vector2(380, -230)],
	[Vector2(80, 65), Vector2(230, 200), Vector2(410, 280)]
]
const TRAILS := [
	[
		Vector2(-760, 50), Vector2(-920, -25), Vector2(-945, -235),
		Vector2(-740, -345), Vector2(-380, -435), Vector2(-3, -507)
	],
	[
		Vector2(-3, -507), Vector2(345, -452), Vector2(690, -350),
		Vector2(920, -242), Vector2(895, -65), Vector2(640, 65)
	],
	[Vector2(0, -610), Vector2(4, -680)]
]
const PINEWOOD_ROAD := [
	Vector2(0, 855), Vector2(0, 664), Vector2(-184, 453), Vector2(-153, 231),
	Vector2(100, 55), Vector2(201, -146), Vector2(115, -380),
	Vector2(0, -566), Vector2(0, -820)
]
const PINEWOOD_CLEARING := [
	Vector2(-153, 231), Vector2(-315, 181), Vector2(-412, 61)
]

const ROAD_HALF_WIDTH := 36.0
const TRAIL_HALF_WIDTH := 28.0
const TRAIL_CLEARANCE := 52.0
const TRUNK_SPACING := 48.0

static func near_route(point: Vector2, routes: Array, clearance: float) -> bool:
	for route in routes:
		for i in range(route.size() - 1):
			var closest := Geometry2D.get_closest_point_to_segment(point, route[i], route[i + 1])
			if point.distance_squared_to(closest) < clearance * clearance:
				return true
	return false

# Keep only segments that could reach a point in the area.
static func routes_near_bounds(routes: Array, bounds: Rect2, clearance: float) -> Array:
	var segments: Array = []
	for route in routes:
		for i in range(route.size() - 1):
			var start: Vector2 = route[i]
			var end: Vector2 = route[i + 1]
			var segment_bounds := Rect2(start, Vector2.ZERO).expand(end)
			if segment_bounds.grow(clearance).intersects(bounds):
				segments.append([start, end])
	return segments

static func has_trunk_clearance(point: Vector2, trunks: Array[Vector2]) -> bool:
	for trunk in trunks:
		if point.distance_squared_to(trunk) < TRUNK_SPACING * TRUNK_SPACING:
			return false
	return true
