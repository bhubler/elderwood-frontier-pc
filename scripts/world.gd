extends Node2D
## Elderwood Village: hand-placed landmarks over deterministic isometric terrain.
## Placeholder vector art; future updates will replace it with authored sprites.
const TILE_W: float = 96.0
const TILE_H: float = 48.0
const EXTENT: int = 24

var trees: Array[Vector2] = []
var buildings: Array[Dictionary] = [
    {"pos": Vector2(-390, -195), "name": "THE WAYFARER INN", "roof": Color("#714438")},
    {"pos": Vector2(390, -185), "name": "BLACKSMITH", "roof": Color("#505e65")},
    {"pos": Vector2(-430, 220), "name": "GENERAL GOODS", "roof": Color("#756042")},
    {"pos": Vector2(415, 230), "name": "VILLAGE HALL", "roof": Color("#64526b")}
]

func _ready() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 17361
    for i in range(155):
        var tx: int = rng.randi_range(-EXTENT + 2, EXTENT - 2)
        var ty: int = rng.randi_range(-EXTENT + 2, EXTENT - 2)
        var p: Vector2 = iso(tx, ty)
        if abs(p.x) < 670.0 and abs(p.y) < 410.0:
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
    inn.scale = Vector2(0.53, 0.53)
    inn.z_index = 1
    add_child(inn)

func iso(tx: int, ty: int) -> Vector2:
    return Vector2((tx - ty) * TILE_W * 0.5, (tx + ty) * TILE_H * 0.5)

func _draw() -> void:
    _draw_ground()
    _draw_village_paths()
    _draw_square()
    for tree_pos in trees:
        _draw_tree(tree_pos)
    for building in buildings:
        if str(building["name"]) == "THE WAYFARER INN" and ResourceLoader.exists("res://art/wayfarer_inn.png"):
            continue
        _draw_building(building)
    _draw_lantern(Vector2(-185, -125))
    _draw_lantern(Vector2(185, -125))
    _draw_lantern(Vector2(-185, 145))
    _draw_lantern(Vector2(185, 145))
    _draw_sign(Vector2(0, -205))
    _draw_fountain(Vector2(0, -75))

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
    draw_rect(Rect2(-72, -720, 144, 1440), Color("#786c50"))
    draw_rect(Rect2(-700, -54, 1400, 108), Color("#786c50"))
    draw_rect(Rect2(-620, -335, 1240, 670), Color("#786c50"), false, 8.0)
    for i in range(-6, 7):
        draw_line(Vector2(i * 95.0, -50), Vector2(i * 95.0 + 32, 50), Color("#948365"), 2.0)

func _draw_square() -> void:
    draw_rect(Rect2(-235, -165, 470, 340), Color("#6a6857"))
    for x in range(-220, 221, 44):
        draw_line(Vector2(x, -165), Vector2(x, 175), Color("#545748"), 1.0)
    for y in range(-160, 176, 32):
        draw_line(Vector2(-235, y), Vector2(235, y), Color("#545748"), 1.0)
    draw_rect(Rect2(-235, -165, 470, 340), Color("#a39b78"), false, 5.0)

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
