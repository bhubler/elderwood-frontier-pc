extends Node2D
## Elderwood Frontier: a modest wilderness settlement with room to grow.
## The inn is an authored sprite; the other buildings are temporary placeholders.
const WELL_ART := preload("res://art/village_well.png")
const WELL_POSITION := Vector2(0, 35)
const ForestLayout := preload("res://scripts/forest_layout.gd")
const WorldCollision := preload("res://scripts/world_collision.gd")
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
		if ForestLayout.near_route(p, ForestLayout.ROADS, ForestLayout.TRAIL_CLEARANCE) \
		or ForestLayout.near_route(p, ForestLayout.TRAILS, ForestLayout.TRAIL_CLEARANCE) \
		or not ForestLayout.has_trunk_clearance(p, trees):
			continue
		trees.append(p)
	_load_wayfarer_art()
	_load_village_building_art()
	_load_wilderness_terrain()
	_load_wilderness_vegetation()
	_make_collision()
	queue_redraw()

func _make_collision() -> void:
	var obstacles := Node2D.new()
	obstacles.name = "WorldCollision"
	add_child(obstacles)

	var perimeter := PackedVector2Array([
		Vector2(-2380, -1280), Vector2(2380, -1280),
		Vector2(2380, 1280), Vector2(-2380, 1280)
	])
	var terrain := get_node_or_null("WildernessTerrain") as TileMapLayer
	if terrain != null and terrain.tile_set != null:
		var terrain_bounds := terrain.get_used_rect()
		var first := terrain_bounds.position
		var last := terrain_bounds.end - Vector2i.ONE
		perimeter = PackedVector2Array([
			terrain.map_to_local(first),
			terrain.map_to_local(Vector2i(last.x, first.y)),
			terrain.map_to_local(last),
			terrain.map_to_local(Vector2i(first.x, last.y))
		])
	WorldCollision.polygon(obstacles, "VillageBoundary", perimeter, CollisionPolygon2D.BUILD_SEGMENTS)
	if has_node("WayfarerInnArtwork"):
		WorldCollision.polygon(obstacles, "WayfarerInn", PackedVector2Array([
			Vector2(-640, -235), Vector2(-430, -341), Vector2(-151, -239),
			Vector2(-151, -208), Vector2(-367, -157), Vector2(-459, -147),
			Vector2(-640, -199)
		]))
	for building in buildings:
		var pos: Vector2 = building["pos"]
		# Follow the shoulders of the building so approaching from the rear stops
		# above the walls, while players can still round the upper corners.
		WorldCollision.polygon(obstacles, str(building["name"]).to_pascal_case(), PackedVector2Array([
			pos + Vector2(-92, 44), pos + Vector2(-92, -67),
			pos + Vector2(-48, -111), pos + Vector2(38, -119),
			pos + Vector2(92, -74), pos + Vector2(92, 44)
		]))
	var stall_bounds := Rect2(202, -27, 156, 56)
	if has_node("GeneralGoodsArtwork"):
		stall_bounds = Rect2(202, -45, 156, 56)
	WorldCollision.box(obstacles, "GeneralGoods", stall_bounds)
	WorldCollision.circle(obstacles, "Well", WELL_POSITION, 32.0)
	for p in [Vector2(-180, -80), Vector2(190, -110), Vector2(-210, 230)]:
		WorldCollision.circle(obstacles, "LanternPost", p, 4.0)
	WorldCollision.circle(obstacles, "VillageSign", Vector2(10, -290), 5.0)
	for tree_pos in trees:
		WorldCollision.circle(obstacles, "TreeTrunk", tree_pos, 8.0)

func _load_wilderness_terrain() -> void:
	var pack_path := "res://art/10_Wilderness_Bundle/Terrain_and_Nature/godot/terrain_tileset.tres"
	if not ResourceLoader.exists(pack_path):
		return
	var terrain := TileMapLayer.new()
	terrain.name = "WildernessTerrain"
	terrain.set_script(load("res://scripts/wilderness_terrain.gd"))
	terrain.z_index = -10
	add_child(terrain)

func _load_wilderness_vegetation() -> void:
	var pack_path := "res://art/10_Wilderness_Bundle/Trees_and_Bushes"
	if not DirAccess.dir_exists_absolute(pack_path):
		return
	var vegetation := Node2D.new()
	vegetation.name = "WildernessVegetation"
	vegetation.set_script(load("res://scripts/wilderness_vegetation.gd"))
	vegetation.trunks = trees.duplicate()
	add_child(vegetation)

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

func _load_village_building_art() -> void:
	# Individual building PNGs are optional; procedural placeholders remain until installed.
	# Copy the five PNGs into res://art/village_buildings/.
	var assets: Array[Dictionary] = [
		{"file": "town_hall.png", "pos": Vector2(380, -280), "scale": 0.42, "node": "TownHallArtwork"},
		{"file": "cottage_1.png", "pos": Vector2(-480, 167), "scale": 0.39, "node": "CottageOneArtwork"},
		{"file": "cottage_2.png", "pos": Vector2(-80, 327), "scale": 0.39, "node": "CottageTwoArtwork"},
		{"file": "cottage_3.png", "pos": Vector2(410, 222), "scale": 0.39, "node": "CottageThreeArtwork"},
		{"file": "general_goods.png", "pos": Vector2(280, -49), "scale": 0.38, "node": "GeneralGoodsArtwork"}
	]
	for item in assets:
		var path: String = "res://art/village_buildings/" + str(item["file"])
		if not ResourceLoader.exists(path):
			continue
		var texture: Texture2D = load(path) as Texture2D
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.name = str(item["node"])
		sprite.texture = texture
		sprite.position = item["pos"]
		sprite.scale = Vector2.ONE * float(item["scale"])
		sprite.z_index = 1
		add_child(sprite)


func iso(tx: int, ty: int) -> Vector2:
	return Vector2((tx - ty) * TILE_W * 0.5, (tx + ty) * TILE_H * 0.5)

func _draw() -> void:
	if not has_node("WildernessTerrain"):
		_draw_ground()
		_draw_village_paths()
	for tree_pos in trees:
		_draw_tree(tree_pos)
	for building in buildings:
		var art_node := ""
		match str(building["kind"]):
			"hall": art_node = "TownHallArtwork"
			"house":
				var pos: Vector2 = building["pos"]
				if pos.x < -300.0:
					art_node = "CottageOneArtwork"
				elif pos.x < 100.0:
					art_node = "CottageTwoArtwork"
				else:
					art_node = "CottageThreeArtwork"
		if not has_node(art_node):
			_draw_building(building)
	if not has_node("GeneralGoodsArtwork"):
		_draw_general_goods_stand(Vector2(280, -15))
	_draw_well(WELL_POSITION)
	_draw_lantern(Vector2(-180, -80))
	_draw_lantern(Vector2(190, -110))
	_draw_lantern(Vector2(-210, 230))
	_draw_sign(Vector2(10, -290))

func _draw_ground() -> void:
	# Painterly layered earth and grass. No visible diamond grid.
	draw_rect(Rect2(-2400, -1300, 4800, 2600), Color("#293e30"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 41129
	for i in range(3700):
		var p := Vector2(rng.randf_range(-1900.0, 1900.0), rng.randf_range(-1100.0, 1100.0))
		var radius := rng.randf_range(3.0, 20.0)
		var tint := Color("#344b36") if i % 4 == 0 else Color("#3c5139")
		if i % 7 == 0:
			tint = Color("#4a4b34")
		draw_circle(p, radius, Color(tint, 0.32))
	for i in range(2800):
		var p := Vector2(rng.randf_range(-1750.0, 1750.0), rng.randf_range(-1000.0, 1000.0))
		var grass := Color("#65734a") if i % 3 == 0 else Color("#49633e")
		draw_line(p, p + Vector2(rng.randf_range(-3.0, 3.0), -rng.randf_range(3.0, 9.0)), Color(grass, 0.54), 1.0)
	for i in range(230):
		var p := Vector2(rng.randf_range(-1700.0, 1700.0), rng.randf_range(-1000.0, 1000.0))
		draw_circle(p, rng.randf_range(2.0, 6.0), Color("#676b59", 0.67))

func _draw_village_paths() -> void:
	# Earth tracks: irregular soft edges, packed dirt, embedded pebbles.
	for route in ForestLayout.ROADS:
		_draw_dirt_track(PackedVector2Array(route), ForestLayout.ROAD_HALF_WIDTH)
	for route in ForestLayout.TRAILS:
		_draw_dirt_track(PackedVector2Array(route), ForestLayout.TRAIL_HALF_WIDTH)
	var routes := ForestLayout.ROADS + ForestLayout.TRAILS
	var rng := RandomNumberGenerator.new()
	rng.seed = 7183
	for route in routes:
		for j in range(route.size() - 1):
			var start: Vector2 = route[j]
			var end: Vector2 = route[j + 1]
			var length: float = start.distance_to(end)
			var count: int = int(length / 3.0)
			for k in range(count):
				var t: float = rng.randf()
				var along: Vector2 = start.lerp(end, t)
				var sideways: Vector2 = (end - start).normalized().orthogonal()
				var p: Vector2 = along + sideways * rng.randf_range(-31.0, 31.0)
				var radius: float = rng.randf_range(0.7, 3.3)
				var c := Color("#a48c65") if k % 5 == 0 else Color("#493f30")
				draw_circle(p, radius, Color(c, 0.57))
	for i in range(260):
		var p := Vector2(rng.randf_range(-730.0, 730.0), rng.randf_range(-500.0, 500.0))
		var c := Color("#687451") if i % 3 == 0 else Color("#536d42")
		draw_line(p, p + Vector2(3.0, -rng.randf_range(4.0, 11.0)), Color(c, 0.75), 1.5)

func _draw_dirt_track(route: PackedVector2Array, half_width: float) -> void:
	var width := half_width * 2.0
	draw_polyline(route, Color("#4d4933"), width, true)
	draw_polyline(route, Color("#65573b"), width * 0.86, true)
	draw_polyline(route, Color("#82704d"), width * 0.60, true)
	draw_polyline(route, Color("#9b8055", 0.25), width * 0.28, true)

func _draw_well(p: Vector2) -> void:
	draw_ellipse_placeholder(p + Vector2(0, 10), 48.0, 22.0, Color(0, 0, 0, 0.25))
	# Center the stone base on the collision footprint with the crank rising above it.
	draw_texture(WELL_ART, p + Vector2(-40, -68))

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
