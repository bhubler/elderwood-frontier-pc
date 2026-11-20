extends TileMapLayer
## Shared Wilderness Bundle terrain for outdoor regions.
## This script is project code; the separately purchased assets stay local.
const ForestLayout := preload("res://scripts/forest_layout.gd")
const TILESET_PATH := "res://art/10_Wilderness_Bundle/Terrain_and_Nature/godot/terrain_tileset.tres"
const TERRAIN_SET := 0
const GRASS := 6 # shallow_green_grass
const TRAIL := 22
const COBBLE := 23
const EXTENT := 24

var roads: Array = ForestLayout.ROADS
var trails: Array = ForestLayout.TRAILS
var road_half_width := ForestLayout.ROAD_HALF_WIDTH
var trail_half_width := ForestLayout.TRAIL_HALF_WIDTH
var cobble_center := Vector2.ZERO
var cobble_radius := 78.0
var cobble_over_roads := false
var cell_extent := EXTENT
var ground_bounds := Rect2()

func village_playable_outline() -> PackedVector2Array:
	var first := Vector2i(-EXTENT, -EXTENT)
	var last := Vector2i(EXTENT, EXTENT)
	return PackedVector2Array([
		map_to_local(first),
		map_to_local(Vector2i(last.x, first.y)),
		map_to_local(last),
		map_to_local(Vector2i(first.x, last.y))
	])

func _ready() -> void:
	if not ResourceLoader.exists(TILESET_PATH):
		push_warning("Wilderness terrain pack not found; using prototype ground.")
		return
	tile_set = load(TILESET_PATH) as TileSet
	if tile_set == null:
		return
	# The supplied TileSet uses 64x32 isometric cells.
	var grass_cells: Array[Vector2i] = []
	var trail_cells: Array[Vector2i] = []
	var cobble_cells: Array[Vector2i] = []
	var cell_bounds := Rect2i(-cell_extent, -cell_extent, cell_extent * 2 + 1, cell_extent * 2 + 1)
	if ground_bounds.has_area():
		var first := local_to_map(ground_bounds.position)
		var area := Rect2i(first, Vector2i.ONE)
		for corner in [
			Vector2(ground_bounds.end.x, ground_bounds.position.y),
			Vector2(ground_bounds.position.x, ground_bounds.end.y), ground_bounds.end
		]:
			area = area.expand(local_to_map(corner))
		cell_bounds = area.grow(2)
	for y in range(cell_bounds.position.y, cell_bounds.end.y):
		for x in range(cell_bounds.position.x, cell_bounds.end.x):
			var cell := Vector2i(x, y)
			var pos := map_to_local(cell)
			if ground_bounds.has_area() and not ground_bounds.has_point(pos):
				continue
			var cobbled := pos.distance_to(cobble_center) < cobble_radius
			if cobble_over_roads and cobbled:
				cobble_cells.append(cell)
			elif ForestLayout.near_route(pos, roads, road_half_width) \
			or ForestLayout.near_route(pos, trails, trail_half_width):
				trail_cells.append(cell)
			elif cobbled:
				cobble_cells.append(cell)
			else:
				grass_cells.append(cell)
	set_cells_terrain_connect(grass_cells, TERRAIN_SET, GRASS, false)
	set_cells_terrain_connect(trail_cells, TERRAIN_SET, TRAIL, false)
	set_cells_terrain_connect(cobble_cells, TERRAIN_SET, COBBLE, false)
