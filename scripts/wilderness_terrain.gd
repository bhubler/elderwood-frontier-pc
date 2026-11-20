extends TileMapLayer
## Optional Wilderness Bundle terrain for the starting village.
## This script is project code; the separately purchased assets stay local.
const ForestLayout := preload("res://scripts/forest_layout.gd")
const TILESET_PATH := "res://art/10_Wilderness_Bundle/Terrain_and_Nature/godot/terrain_tileset.tres"
const TERRAIN_SET := 0
const GRASS := 6 # shallow_green_grass
const TRAIL := 22
const COBBLE := 23
const EXTENT := 24

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
	for y in range(-EXTENT, EXTENT + 1):
		for x in range(-EXTENT, EXTENT + 1):
			var cell := Vector2i(x, y)
			var pos := map_to_local(cell)
			# Path widths are measured in the same world coordinates as the village.
			if ForestLayout.near_route(pos, ForestLayout.ROADS, ForestLayout.ROAD_HALF_WIDTH) \
			or ForestLayout.near_route(pos, ForestLayout.TRAILS, ForestLayout.TRAIL_HALF_WIDTH):
				trail_cells.append(cell)
			elif pos.length() < 78.0:
				cobble_cells.append(cell)
			else:
				grass_cells.append(cell)
	set_cells_terrain_connect(grass_cells, TERRAIN_SET, GRASS, false)
	set_cells_terrain_connect(trail_cells, TERRAIN_SET, TRAIL, false)
	set_cells_terrain_connect(cobble_cells, TERRAIN_SET, COBBLE, false)
