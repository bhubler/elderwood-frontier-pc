extends Node2D
## Elderwood Frontier: a modest wilderness settlement with room to grow.
## The inn is an authored sprite; the other buildings are temporary placeholders.
const TILE_W: float = 96.0
const TILE_H: float = 48.0
const EXTENT: int = 24

var trees: Array[Vector2] = []
var buildings: Array[Dictionary] = [
	{"pos": Vector2(380, -230), "name": "TOWN HALL", "roof": Color("#514c47"), "kind": "hall"},
	{"pos": Vector2(-480, 225), "name": "COTTAGE", "roof": Color("#625448"), "kind": "house"},
	{"pos": Vector2(-80, 385), "name": "COTTAGE", "roof": Color("#5a5141"), "kind": "house"},
	{"pos": Vector2(410, 280), "name": "COTTAGE", "roof": Color("#514c56"), "kind": "house"}
]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17361
	for i in range(155):
		var tx: int = rng.randi_range(-EXTENT + 2, EXTENT - 2)
		var ty: int = rng.randi_range(-EXTENT + 2, EXTENT - 2)
		var p: Vector2 = iso(tx, ty)
		if abs(p.x) < 730.0 and abs(p.y) < 520.0:
			continue
		trees.append(p)
	_load_wayfarer_art()
	queue_redraw()

func _load_wayfarer_art() -> void:
	# Add the supplied PNG at res://art/wayfarer_inn.png to enable artwork.
	var asset_path: String = "res://art/wayfarer_inn.png"
	if not ResourceLoader.exists(asset_path):
		return
	var tex: Texture2D = load(asset_path) as Texture2D
	if tex == null:
		return
	var inn := Sprite2D.new()
	inn.name = "WayfarerInnArtwork"
	inn.texture = tex
	inn.position = Vector2(-390, -290)
	inn.scale = Vector2(0.40, 0.40)
	inn.z_index = 1
	add_child(inn)

func iso(tx: int, ty: int) -> Vector2:
	return Vector2((tx - ty) * TILE_W * 0.5, (tx + ty) * TILE_H * 0.5)

func _draw() -> void:
	_draw_ground()
	_draw_village_paths()
	for tree_pos in trees:
		_draw_tree(tree_pos)
	for building in buildings:
		_draw_building(building)
	_draw_general_goods_stand(Vector2(210, -15))
	_draw_well(Vector2(0, 35))
	_draw_lantern(Vector2(-180, -80))
	_draw_lantern(Vector2(190, -110))
	_draw_lantern(Vector2(-210, 230))
	_draw_sign(Vector2(10, -290))

func _draw_ground() -> void:
	for ty in range(-EXTENT, EXTENT + 1):
		for tx in range(-EXTENT, EXTENT + 1):
			var c: Vector2 = iso(tx, ty)
			var tint: Color = Color("#314b37")
			if posmod(tx * 7 + ty * 13, 9) < 3:
				tint = Color("#3b563c")
			var diamond := PackedVector2Array([
				c + Vector2(0, -TILE_H * 0.5),
				c + Vector2(TILE_W * 0.5, 0),
				c + Vector2(0, TILE_H * 0.5),
				c + Vector2(-TILE_W * 0.5, 0)
			])
			draw_colored_polygon(diamond, tint)
			draw_polyline(PackedVector2Array([
				diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]
			]), Color(0.1, 0.17, 0.12, 0.16), 1.0)

func _draw_village_paths() -> void:
	# Narrow, irregular earth tracks instead of a formal stone plaza.
	var routes: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-760, 50), Vector2(-370, 55), Vector2(-100, 40), Vector2(170, 20), Vector2(640, 65)]),
		PackedVector2Array([Vector2(0, -610), Vector2(-10, -280), Vector2(0, 40), Vector2(-20, 480), Vector2(-40, 720)]),
		PackedVector2Array([Vector2(-95, 35), Vector2(-290, 130), Vector2(-480, 225)]),
		PackedVector2Array([Vector2(80, 30), Vector2(260, -110), Vector2(380, -230)]),
		PackedVector2Array([Vector2(80, 65), Vector2(230, 200), Vector2(410, 280)])
	]
	for route in routes:
		draw_polyline(route, Color("#514a36"), 56.0, true)
		draw_polyline(route, Color("#786a4b"), 46.0, true)
		draw_polyline(route, Color("#8a7955", 0.28), 3.0, true)
	# Scattered stones, roots, and patches of grass break up the trails.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7183
	for i in range(165):
		var p := Vector2(rng.randf_range(-710, 710), rng.randf_range(-480, 480))
		if p.length() < 130.0:
			continue
		var size := rng.randf_range(2.0, 7.0)
		draw_circle(p, size, Color("#67705a", 0.58) if i % 3 == 0 else Color("#4c633c", 0.72))

func _draw_well(p: Vector2) -> void:
	draw_ellipse_placeholder(p + Vector2(0, 10), 48.0, 22.0, Color(0, 0, 0, 0.25))
	draw_circle(p, 32.0, Color("#524f46"))
	draw_circle(p, 23.0, Color("#8c8878"))
	draw_circle(p, 17.0, Color("#253b42"))
	draw_line(p + Vector2(-25, -8), p + Vector2(-25, -60), Color("#594532"), 7.0)
	draw_line(p + Vector2(25, -8), p + Vector2(25, -60), Color("#594532"), 7.0)
	draw_line(p + Vector2(-32, -60), p + Vector2(32, -60), Color("#44372d"), 9.0)
	draw_line(p + Vector2(0, -60), p + Vector2(0, -23), Color("#a58a62"), 2.0)

func draw_ellipse_placeholder(p: Vector2, rx: float, ry: float, tint: Color) -> void:
	draw_set_transform(p, 0.0, Vector2(1.0, ry / rx))
	draw_circle(Vector2.ZERO, rx, tint)
	draw_set_transform(Vector2.ZERO)

func _draw_general_goods_stand(p: Vector2) -> void:
	# A small open-air trader's stall, not a permanent shop.
	draw_rect(Rect2(p + Vector2(-78, -12), Vector2(156, 56)), Color("#49372a"))
	draw_rect(Rect2(p + Vector2(-83, -19), Vector2(166, 14)), Color("#917049"))
	for x in [-70.0, 70.0]:
		draw_line(p + Vector2(x, -15), p + Vector2(x, -96), Color("#57402c"), 9.0)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-95, -97), p + Vector2(-55, -124),
		p + Vector2(65, -124), p + Vector2(95, -97)
	]), Color("#9b7751"))
	for x in [-50.0, 0.0, 50.0]:
		draw_line(p + Vector2(x, -120), p + Vector2(x + 10, -97), Color("#724e42"), 12.0)
	for x in [-45.0, -8.0, 29.0]:
		draw_circle(p + Vector2(x, -30), 13.0, Color("#a4793f"))
		draw_circle(p + Vector2(x + 7, -28), 8.0, Color("#71804a"))
	draw_rect(Rect2(p + Vector2(-64, 7), Vector2(30, 33)), Color("#796042"))
	draw_rect(Rect2(p + Vector2(42, 12), Vector2(30, 28)), Color("#796042"))
	draw_string(ThemeDB.fallback_font, p + Vector2(-65, 65), "GENERAL GOODS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ead4a3"))

func _draw_building(b: Dictionary) -> void:
	var p: Vector2 = b["pos"]
	var roof: Color = b["roof"]
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-125, 28), p + Vector2(0, 84),
		p + Vector2(125, 28), p + Vector2(0, -25)
	]), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(p + Vector2(-92, -67), Vector2(184, 111)), Color("#a98d6b"))
	draw_rect(Rect2(p + Vector2(-92, -67), Vector2(184, 111)), Color("#48382e"), false, 5.0)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-115, -65), p + Vector2(0, -155),
		p + Vector2(115, -65), p + Vector2(0, -12)
	]), roof)
	draw_line(p + Vector2(-115, -65), p + Vector2(0, -155), Color("#342c2b"), 6.0)
	draw_line(p + Vector2(0, -155), p + Vector2(115, -65), Color("#342c2b"), 6.0)
	draw_rect(Rect2(p + Vector2(-19, -9), Vector2(38, 53)), Color("#483126"))
	draw_circle(p + Vector2(10, 18), 3.0, Color("#e3c37b"))
	for x in [-67, 48]:
		draw_rect(Rect2(p + Vector2(x, -34), Vector2(23, 26)), Color("#e6b76b"))
		draw_rect(Rect2(p + Vector2(x, -34), Vector2(23, 26)), Color("#4a3c30"), false, 3.0)
	draw_rect(Rect2(p + Vector2(-108, 55), Vector2(216, 26)), Color("#3c3028"))
	draw_string(ThemeDB.fallback_font, p + Vector2(-101, 73), str(b["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f4dfb0"))

func _draw_tree(p: Vector2) -> void:
	draw_circle(p + Vector2(7, 5), 15.0, Color(0, 0, 0, 0.25))
	draw_line(p, p + Vector2(0, -57), Color("#554132"), 9.0)
	draw_circle(p + Vector2(0, -71), 29.0, Color("#1d382f"))
	draw_circle(p + Vector2(-13, -83), 20.0, Color("#2d5944"))
	draw_circle(p + Vector2(16, -82), 18.0, Color("#28503d"))

func _draw_lantern(p: Vector2) -> void:
	draw_line(p, p + Vector2(0, -70), Color("#3e332d"), 5.0)
	draw_circle(p + Vector2(0, -75), 19.0, Color(0.98, 0.68, 0.27, 0.16))
	draw_rect(Rect2(p + Vector2(-8, -84), Vector2(16, 18)), Color("#e5ac53"))
	draw_rect(Rect2(p + Vector2(-10, -86), Vector2(20, 22)), Color("#423b30"), false, 3.0)

func _draw_sign(p: Vector2) -> void:
	draw_line(p, p + Vector2(0, -65), Color("#594431"), 7.0)
	draw_rect(Rect2(p + Vector2(-95, -108), Vector2(190, 43)), Color("#4c382b"))
	draw_rect(Rect2(p + Vector2(-95, -108), Vector2(190, 43)), Color("#b89561"), false, 3.0)
	draw_string(ThemeDB.fallback_font, p + Vector2(-80, -79), "ELDERWOOD VILLAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f2dba7"))

func _draw_fountain(p: Vector2) -> void:
	draw_circle(p + Vector2(0, 8), 44.0, Color("#484f51"))
	draw_circle(p, 37.0, Color("#708e93"))
	draw_circle(p, 26.0, Color("#2f6b7c"))
	draw_circle(p, 8.0, Color("#c6b995"))
	draw_line(p + Vector2(0, -4), p + Vector2(0, -32), Color("#a5d8e6"), 3.0)
