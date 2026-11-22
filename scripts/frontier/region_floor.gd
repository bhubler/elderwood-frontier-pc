extends Node2D
## Floor backing and room details for the Forsaken chapter.
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
    for bounds in WATCH_CRATES:
        draw_rect(bounds, Color("#302319"))
        draw_rect(bounds.grow(-5), Color("#745439"))
        for i in range(1, 4):
            var x: float = bounds.position.x + bounds.size.x * i / 4.0
            draw_line(Vector2(x, bounds.position.y + 4), Vector2(x, bounds.end.y - 4), Color("#493421"), 2)
    draw_rect(WATCH_TABLE, Color("#3a2a22"))
    draw_rect(WATCH_TABLE.grow(-5), Color("#775234"))
    draw_rect(Rect2(-65, -119, 104, 35), Color("#b5a074"))
    draw_polyline(PackedVector2Array([Vector2(-55, -112), Vector2(-27, -98), Vector2(0, -110), Vector2(31, -92)]),
        Color("#68553b"), 2, true)
