extends Node2D
## Separate off-map inn room; no modifications to the exterior village art.
const Terrain := preload("res://scripts/wilderness_terrain.gd")
const Art := preload("res://scripts/wayfinding_art.gd")
const FLOOR := Rect2(-390, -240, 780, 480)
const STOOLS := [Vector2(-150, 100), Vector2(120, 110), Vector2(-140, -90)]
const Prop := preload("res://scripts/interior_prop.gd")
var player: CharacterBody2D

const WorldCollision := preload("res://scripts/world_collision.gd")

func _ready() -> void:
    if ResourceLoader.exists(Terrain.TILESET_PATH):
        var tiles := Terrain.new()
        tiles.name = "InnStoneFloor"
        tiles.ground_bounds = FLOOR
        tiles.roads = []
        tiles.trails = []
        tiles.cobble_radius = 520.0
        tiles.modulate = Color("#c8ac8d")
        tiles.z_index = 1
        add_child(tiles)
    var furnishings := Node2D.new()
    furnishings.z_index = 2
    furnishings.draw.connect(_draw_furnishings.bind(furnishings))
    add_child(furnishings)
    WorldCollision.polygon(self, "RoomBoundary", PackedVector2Array([
        Vector2(-357, -207), Vector2(357, -207),
        Vector2(357, 207), Vector2(-357, 207)
    ]), CollisionPolygon2D.BUILD_SEGMENTS)
    var hearth := Prop.place(self, "manors/hearth", Vector2(-232, -110), Vector2(145, 80), player)
    Prop.loop(hearth, "fire", Vector2(6, -46), 8.0)
    Prop.place(self, "counter", Vector2(207, -75), Vector2(185, 80), player)
    var table := Prop.place(self, "table", Vector2(-10, 85), Vector2(220, 110), player)
    Prop.place(table, "inns/mug", Vector2(-39, -95), Vector2.ZERO, null, 0)
    for feet in STOOLS:
        var stool := Prop.place(self, "stool", feet + Vector2(0, 12), Vector2.ZERO, player)
        WorldCollision.circle(stool, "Footprint", Vector2(0, -12), 25.0)
    Prop.place(self, "inns/chair", Vector2(177, 123), Vector2(39, 30), player)
    Prop.place(self, "inns/cupboard", Vector2(-316, 26), Vector2(82, 34), player)
    Prop.place(self, "inns/chest", Vector2(302, 99), Vector2(69, 39), player)
    Prop.place(self, "manors/rug", Vector2(-2, 180), Vector2.ZERO, null, 1)

func _draw() -> void:
    draw_rect(Rect2(-420,-270,840,540), Color("#201c1b"))
    draw_rect(Rect2(-390,-240,780,480), Color("#76553a"))
    for x in range(-380,390,65):
        draw_line(Vector2(x,-230),Vector2(x,230),Color("#61442f"),2.0)
    for y in range(-230,240,65):
        draw_line(Vector2(-380,y),Vector2(380,y),Color("#61442f"),2.0)

func _draw_furnishings(canvas: Node2D) -> void:
    var wall := Art._texture("res://art/stonehaven/curtain_wall.png")
    if wall != null:
        for x in [-375, -125, 125]:
            canvas.draw_texture_rect(wall, Rect2(x, -240, 250, 57), false, Color("#bd9e82"))
    canvas.draw_rect(Rect2(-375, -204, 18, 426), Color("#40332a"))
    canvas.draw_rect(Rect2(357, -204, 18, 426), Color("#40332a"))
    canvas.draw_rect(Rect2(-65, 203, 130, 22), Color("#8a6a4a"))
    canvas.draw_string(ThemeDB.fallback_font, Vector2(-32, 198), "EXIT ↓",
        HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f3dba9"))
