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
var paved_roads := false
var populate_on_ready := true
var streamed := false
var grass_source := -1
var grass_atlas := Vector2i.ZERO
var grass_underlay: TileMapLayer
var solid_grass_tiles: Array[Vector3i] = []

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
	if streamed:
		_find_solid_grass()
		grass_underlay = TileMapLayer.new()
		grass_underlay.name = "GrassUnderlay"
		grass_underlay.tile_set = tile_set
		grass_underlay.rendering_quadrant_size = rendering_quadrant_size
		grass_underlay.collision_enabled = false
		grass_underlay.navigation_enabled = false
		grass_underlay.z_index = -1
		add_child(grass_underlay)
	if populate_on_ready:
		paint_ground(ground_bounds)

func _find_solid_grass() -> void:
	var best := -1
	for i in range(tile_set.get_source_count()):
		var id := tile_set.get_source_id(i)
		var source := tile_set.get_source(id) as TileSetAtlasSource
		if source == null:
			continue
		for index in range(source.get_tiles_count()):
			var atlas := source.get_tile_id(index)
			var data := source.get_tile_data(atlas, 0)
			if data.terrain_set != TERRAIN_SET or data.terrain != GRASS:
				continue
			var score := 0
			var peering_bits := 0
			for bit in range(16):
				if data.is_valid_terrain_peering_bit(bit):
					peering_bits += 1
					if data.get_terrain_peering_bit(bit) == GRASS:
						score += 1
			if score == peering_bits:
				solid_grass_tiles.append(Vector3i(id, atlas.x, atlas.y))
			if score > best:
				best = score
				grass_source = id
				grass_atlas = atlas

func paint_ground(bounds: Rect2, fill_missing_only := false) -> void:
	if tile_set == null:
		return
	if streamed and fill_missing_only and bounds.has_area():
		_paint_streamed_patch(bounds)
		return
	_paint_terrain(self, bounds)

func _paint_streamed_patch(bounds: Rect2) -> void:
	# Terrain Connect can inspect the layer's existing cells. Solve only a
	# bounded neighborhood, then commit its interior to the cached forest.
	var solve_bounds := bounds.grow(2.0 * maxi(tile_set.tile_size.x, tile_set.tile_size.y))
	var cobble_bounds := Rect2(cobble_center - Vector2.ONE * cobble_radius, Vector2.ONE * cobble_radius * 2.0)
	var patch: TileMapLayer
	if solid_grass_tiles.is_empty() or (cobble_radius > 0.0 and solve_bounds.intersects(cobble_bounds)) \
	or not ForestLayout.routes_near_bounds(roads, solve_bounds, road_half_width).is_empty() \
	or not ForestLayout.routes_near_bounds(trails, solve_bounds, trail_half_width).is_empty():
		patch = TileMapLayer.new()
		patch.tile_set = tile_set
		_paint_terrain(patch, solve_bounds)
	var coverage := grass_underlay if grass_source >= 0 else self
	for cell in _cells_in_bounds(bounds):
		if coverage.get_cell_source_id(cell) >= 0:
			continue
		if grass_source >= 0:
			grass_underlay.set_cell(cell, grass_source, grass_atlas)
		if patch != null:
			set_cell(cell, patch.get_cell_source_id(cell), patch.get_cell_atlas_coords(cell),
				patch.get_cell_alternative_tile(cell))
		else:
			var tile := solid_grass_tiles[posmod(hash(cell), solid_grass_tiles.size())]
			set_cell(cell, tile.x, Vector2i(tile.y, tile.z))
	if patch != null:
		patch.free()

func _paint_terrain(layer: TileMapLayer, bounds: Rect2) -> void:
	var local_roads := roads
	var local_trails := trails
	if bounds.has_area():
		local_roads = ForestLayout.routes_near_bounds(roads, bounds, road_half_width)
		local_trails = ForestLayout.routes_near_bounds(trails, bounds, trail_half_width)
	var grass_cells: Array[Vector2i] = []
	var trail_cells: Array[Vector2i] = []
	var cobble_cells: Array[Vector2i] = []
	for cell in _cells_in_bounds(bounds):
		var pos := map_to_local(cell)
		if layer == self and streamed and grass_source >= 0:
			grass_underlay.set_cell(cell, grass_source, grass_atlas)
		var cobbled := pos.distance_to(cobble_center) < cobble_radius
		if cobble_over_roads and cobbled:
			cobble_cells.append(cell)
		elif ForestLayout.near_route(pos, local_roads, road_half_width) \
		or ForestLayout.near_route(pos, local_trails, trail_half_width):
			if paved_roads:
				cobble_cells.append(cell)
			else:
				trail_cells.append(cell)
		elif cobbled:
			cobble_cells.append(cell)
		else:
			grass_cells.append(cell)
	if not grass_cells.is_empty():
		layer.set_cells_terrain_connect(grass_cells, TERRAIN_SET, GRASS, streamed)
	if not trail_cells.is_empty():
		layer.set_cells_terrain_connect(trail_cells, TERRAIN_SET, TRAIL, streamed)
	if not cobble_cells.is_empty():
		layer.set_cells_terrain_connect(cobble_cells, TERRAIN_SET, COBBLE, false)


func _cells_in_bounds(bounds: Rect2) -> Array[Vector2i]:
	var cell_bounds := Rect2i(-cell_extent, -cell_extent, cell_extent * 2 + 1, cell_extent * 2 + 1)
	if bounds.has_area():
		var first := local_to_map(bounds.position)
		var area := Rect2i(first, Vector2i.ONE)
		for corner in [
			Vector2(bounds.end.x, bounds.position.y),
			Vector2(bounds.position.x, bounds.end.y), bounds.end
		]:
			area = area.expand(local_to_map(corner))
		cell_bounds = area.grow(2)
	var cells: Array[Vector2i] = []
	for y in range(cell_bounds.position.y, cell_bounds.end.y):
		for x in range(cell_bounds.position.x, cell_bounds.end.x):
			var cell := Vector2i(x, y)
			if not bounds.has_area() or bounds.has_point(map_to_local(cell)):
				cells.append(cell)
	return cells


func erase_ground_cell(cell: Vector2i) -> void:
	erase_cell(cell)
	if is_instance_valid(grass_underlay):
		grass_underlay.erase_cell(cell)

func ground_cells() -> Array[Vector2i]:
	if is_instance_valid(grass_underlay) and grass_source >= 0:
		return grass_underlay.get_used_cells()
	return get_used_cells()
