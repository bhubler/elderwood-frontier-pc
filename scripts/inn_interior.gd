extends Node2D
## Separate off-map inn room; no modifications to the exterior village art.
const Terrain := preload("res://scripts/wilderness_terrain.gd")
const Art := preload("res://scripts/wayfinding_art.gd")
const FLOOR := Rect2(-390, -240, 780, 480)
const STOOLS := [Vector2(-150, 100), Vector2(120, 110), Vector2(-140, -90)]
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
    WorldCollision.box(self, "Hearth", Rect2(-305, -190, 145, 80))
    WorldCollision.box(self, "Counter", Rect2(115, -155, 185, 80))
    WorldCollision.box(self, "Table", Rect2(-120, -25, 220, 110))
    for p in STOOLS:
        WorldCollision.circle(self, "Stool", p, 25.0)

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
    _draw_prop(canvas, "hearth", Vector2(-232, -110))
    _draw_prop(canvas, "counter", Vector2(207, -75))
    _draw_prop(canvas, "table", Vector2(-10, 85))
    for p in STOOLS:
        _draw_prop(canvas, "stool", p + Vector2(0, 12))
    canvas.draw_string(ThemeDB.fallback_font, Vector2(-32, 198), "EXIT ↓",
        HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f3dba9"))

func _draw_prop(canvas: Node2D, name: String, feet: Vector2) -> void:
    var texture := Art._texture("res://art/interiors/" + name + ".png")
    if texture != null:
        canvas.draw_texture(texture, feet - Vector2(texture.get_width() * 0.5, texture.get_height()))
