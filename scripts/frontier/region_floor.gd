extends Node2D
## Floor backing and room details for the Forsaken chapter.
const Ruins := preload("res://scripts/frontier/awakening_ruins.gd")
const Overworld := preload("res://scripts/frontier/overworld_layout.gd")
const OverworldGround := preload("res://scripts/frontier/overworld_ground.gd")
const BOUNDS := Rect2(-510, -290, 1020, 580)
var ground := Color("#282f2b")
var region_id := ""
var grass_backing := false
var tiled_ground := false
const OUTDOOR_ROOMS := ["graveyard", "town_court", "old_cabin", "bandit_camp", "goblin_hollow"]
const GRAVEYARD_ROADS := [
    [Vector2(0, 290), Vector2(-60, 170), Vector2(-36, 50), Vector2(14, -90), Vector2(0, -260)],
    [Vector2(-60, 170), Vector2(100, 155), Vector2(245, 95), Vector2(510, 120)],
    [Vector2(-60, 170), Vector2(-240, 182), Vector2(-430, 193)],
    [Vector2(100, 155), Vector2(344, 225)]
]
const WayfindingArt := preload("res://scripts/wayfinding_art.gd")
const SEAL_PATH := "res://art/landmarks/bonecaller_seal.png"
const ROOM_WALL := preload("res://art/stonehaven/curtain_wall.png")
const WATCH_TABLE := Rect2(-128, -132, 256, 64)
const WATCH_CRATES := [Rect2(-367, -92, 95, 70), Rect2(265, -111, 91, 67)]

static func is_interior(id: String) -> bool:
    return id not in OUTDOOR_ROOMS and id not in ["stonehaven", "east_pinewood"]


func _draw() -> void:
    if region_id == "stonehaven" or region_id == "east_pinewood":
        var urban := region_id == "stonehaven"
        if grass_backing:
            draw_rect(Overworld.FOREST.grow(900), Color("#344b2b"))
            return
        var roads := Overworld.CITY_ROADS if urban else Overworld.FOREST_ROADS
        OverworldGround.draw_ground(self, Overworld.bounds(region_id, BOUNDS).grow(770), roads, urban)
        return
    if not is_interior(region_id):
        if not tiled_ground:
            var roads := GRAVEYARD_ROADS if region_id == "graveyard" else [[Vector2(0, 300), Vector2(0, -110)]]
            OverworldGround.draw_ground(self, BOUNDS.grow(590), roads, region_id == "town_court")
        return
    if Ruins.ROOMS.has(region_id):
        _draw_ruins()
        return
    if not tiled_ground:
        draw_rect(BOUNDS, ground)
        for y in range(-286, 289, 23):
            var stagger := 17 if floori((y + 286) / 23.0) % 2 == 0 else 0
            for x in range(-510, 490, 35):
                var stone := ground.lightened(0.07 + float(posmod(x * 13 + y * 17, 7)) * 0.012)
                draw_rect(Rect2(x + stagger, y, 33, 21), stone)
    _draw_room_walls()
    if region_id == "northern_watch":
        _draw_watch_room()
    elif region_id == "crypt_ritual":
        var seal := WayfindingArt._texture(SEAL_PATH)
        if seal != null:
            draw_texture_rect(seal, Rect2(-132, -141, 264, 172), false)


func _draw_room_walls() -> void:
    for x in [-510.0, -170.0, 170.0]:
        draw_texture_rect(ROOM_WALL, Rect2(x, -290, 340, 75), false, Color("#959080"))
    draw_rect(Rect2(-510, -220, 19, 510), Color("#403b34"))
    draw_rect(Rect2(491, -220, 19, 510), Color("#403b34"))
    draw_rect(Rect2(-510, 269, 455, 21), Color("#403b34"))
    draw_rect(Rect2(55, 269, 455, 21), Color("#403b34"))
    for x in [-330, 330]:
        var light := Vector2(x, -223)
        draw_circle(light, 34, Color(0.94, 0.61, 0.21, 0.16))
        draw_circle(light, 5, Color("#ffbd64"))

func _draw_watch_room() -> void:
    draw_rect(Rect2(-48, 227, 96, 46), Color("#5a4330"))
    draw_rect(Rect2(-44, 231, 88, 37), Color("#78634b"))
    var supplies := WayfindingArt._texture("res://art/interiors/counter.png")
    var table := WayfindingArt._texture("res://art/interiors/table.png")
    if supplies != null:
        for bounds in WATCH_CRATES:
            draw_texture_rect(supplies, Rect2(bounds.position - Vector2(0, 19), bounds.size + Vector2(0, 19)), false)
    if table != null:
        draw_texture_rect(table, Rect2(WATCH_TABLE.position - Vector2(0, 55), WATCH_TABLE.size + Vector2(0, 55)), false)

func _draw_ruins() -> void:
    var bounds := Ruins.bounds(region_id)
    if not tiled_ground:
        draw_rect(bounds, ground)
        for y in range(int(bounds.position.y) + 3, int(bounds.end.y) - 23, 23):
            var stagger := 16 if posmod(y - int(bounds.position.y) - 3, 46) == 0 else 0
            for x in range(int(bounds.position.x) + stagger, int(bounds.end.x) - 35, 35):
                var shade := ground.lightened(float(posmod(x * 13 + y * 17, 7)) * 0.014)
                draw_rect(Rect2(x, y, 33, 21), shade)
    for wall in Ruins.walls(region_id):
        if wall.size.x > wall.size.y:
            for x in range(int(wall.position.x), int(wall.end.x), 128):
                var width := minf(128, wall.end.x - x)
                draw_texture_rect(ROOM_WALL, Rect2(x, wall.position.y - 14, width, 40), false, Color("#aca49b"))
        else:
            for y in range(int(wall.position.y), int(wall.end.y), 48):
                var length := minf(48, wall.end.y - y)
                draw_texture_rect(ROOM_WALL, Rect2(wall.position.x - 4, y, 30, length), false, Color("#8e8c86"))
    for exit in Ruins.ROOMS[region_id]["points"]:
        var at: Vector2 = exit[2]
        draw_rect(Rect2(at - Vector2(42, 22), Vector2(84, 36)), Color("#232222"))
        for step in range(4):
            draw_texture_rect(ROOM_WALL, Rect2(at.x - 39, at.y - 20 + step * 8, 78, 7), false,
                Color("#938774").lightened(step * 0.035))
