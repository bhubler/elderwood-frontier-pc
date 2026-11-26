extends Control

signal landmark_selected(id: String)
const Data := preload("res://scripts/frontier/travel_map_data.gd")
const Art := preload("res://scripts/wayfinding_art.gd")
const Type := preload("res://scripts/elderwood_type.gd")
const INK := Color("#513821")
const PARCHMENT := Color("#d2b17b")

# Atlas positions are editorial. The travel data owns world-space landing points.
const PLACES := {
    "elderwood": [Vector2(0.21, 0.72), "Elderwood Village", 1, 72],
    "stonehaven": [Vector2(0.41, 0.39), "Stonehaven", 2, 74],
    "caravan": [Vector2(0.59, 0.50), "Raided Caravan", -1, 54],
    "watchtower": [Vector2(0.64, 0.23), "Northern Watchtower", 2, 57],
    "shrine": [Vector2(0.68, 0.70), "Roadside Shrine", -1, 50],
    "ruins": [Vector2(0.77, 0.48), "Awakening Ruins", 2, 55],
    "cabin": [Vector2(0.86, 0.26), "Woodland Cabin", 1, 54],
    "cemetery": [Vector2(0.85, 0.76), "Forsaken Graveyard", -1, 55],
}
# Each route links named destinations, with a few points to shape its curves.
const ROUTES := [
    ["elderwood", "stonehaven", [Vector2(0.29, 0.67), Vector2(0.32, 0.53), Vector2(0.35, 0.46)]],
    ["stonehaven", "caravan", [Vector2(0.48, 0.42), Vector2(0.53, 0.50)]],
    ["caravan", "watchtower", [Vector2(0.61, 0.42), Vector2(0.58, 0.33)]],
    ["watchtower", "cabin", [Vector2(0.73, 0.19), Vector2(0.80, 0.22)]],
    ["caravan", "shrine", [Vector2(0.58, 0.58), Vector2(0.63, 0.65)]],
    ["caravan", "ruins", [Vector2(0.65, 0.46), Vector2(0.71, 0.47)]],
    ["shrine", "cemetery", [Vector2(0.75, 0.71), Vector2(0.80, 0.77)]],
]
const GROVES := [
    [Vector2(0.17, 0.31), Vector2(0.10, 0.17)],
    [Vector2(0.26, 0.24), Vector2(0.09, 0.10)],
    [Vector2(0.43, 0.65), Vector2(0.10, 0.12)],
    [Vector2(0.36, 0.81), Vector2(0.09, 0.06)],
    [Vector2(0.55, 0.78), Vector2(0.08, 0.10)],
    [Vector2(0.70, 0.34), Vector2(0.07, 0.08)],
    [Vector2(0.88, 0.55), Vector2(0.06, 0.12)],
    [Vector2(0.77, 0.85), Vector2(0.07, 0.045)],
]

var progress: ConfigFile
var current_region := ""
var current_position := Vector2.ZERO
var selected := ""
var pins: Dictionary = {}
var parchment: Texture2D

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    resized.connect(queue_redraw)

func _draw() -> void:
    pins.clear()
    if progress == null or size.x < 150 or size.y < 150:
        return
    _draw_parchment()
    var visited := Data.discovered(progress)
    _draw_woodlands()
    for route: Array in ROUTES:
        if visited.has(route[0]) and visited.has(route[1]):
            _draw_road(route)
    for id: String in PLACES:
        if visited.has(id):
            _draw_landmark(id)
    var nearest := _current_nearest_landmark()
    if not nearest.is_empty():
        var at: Vector2 = pins[nearest] + Vector2(-18, 4)
        draw_circle(at, 6.0, Color("#f6dfa7"), true, -1.0, true)
        draw_circle(at, 4.0, Color("#365f59"), true, -1.0, true)

func _draw_parchment() -> void:
    var sheet := Rect2(Vector2.ZERO, size)
    if parchment == null and ResourceLoader.exists("res://art/ui/frontier_parchment.webp"):
        parchment = load("res://art/ui/frontier_parchment.webp") as Texture2D
    draw_rect(sheet, PARCHMENT)
    if parchment != null:
        draw_texture_rect(parchment, sheet, false)
    _centered_text("The Elderwood Frontier", Vector2(size.x * 0.5, size.y * 0.13), 26)
    var compass := Vector2(size.x * 0.105, size.y * 0.24)
    draw_arc(compass, 17, 0, TAU, 28, Color(INK, 0.65), 1.0, true)
    draw_line(compass + Vector2(-22, 0), compass + Vector2(22, 0), INK, 1.0, true)
    draw_colored_polygon(PackedVector2Array([
        compass + Vector2(0, -24), compass + Vector2(5, 6), compass + Vector2(0, 3), compass + Vector2(-5, 6),
    ]), INK)
    _centered_text("N", compass - Vector2(0, 28), 13)

func _draw_woodlands() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 41521
    for grove: Array in GROVES:
        for i in range(16):
            var offset := Vector2.from_angle(rng.randf_range(0, TAU)) * sqrt(rng.randf()) * Vector2(grove[1])
            var where: Vector2 = grove[0] + offset
            var clear := true
            for place: Array in PLACES.values():
                if where.distance_to(place[0]) < 0.07:
                    clear = false
                    break
            if clear:
                _draw_stamp(0, where * size, rng.randf_range(24.0, 49.0), Color(1.0, 1.0, 1.0, 0.40))

func _draw_road(route: Array) -> void:
    var points: Array[Vector2] = [PLACES[route[0]][0]]
    points.append_array(route[2])
    points.append(PLACES[route[1]][0])
    var curve := Curve2D.new()
    curve.bake_interval = 3
    for i in range(points.size()):
        var tangent := (points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]) * size * 0.22
        curve.add_point(points[i] * size, -tangent, tangent)
    var line := curve.get_baked_points()
    draw_polyline(line, Color("#6d4e2f"), 4.5, true)
    draw_polyline(line, Color("#bd955b"), 2.0, true)

func _draw_landmark(id: String) -> void:
    var place: Array = PLACES[id]
    var pin: Vector2 = place[0] * size
    pins[id] = pin
    var chosen := selected == id
    draw_circle(pin, float(place[3]) * 0.32, Color("#eaca90"), true, -1.0, true)
    if chosen:
        draw_arc(pin, float(place[3]) * 0.38, 0, TAU, 36, Color("#784b23"), 1.8, true)
    if int(place[2]) >= 0:
        _draw_stamp(place[2], pin - Vector2(0, 7), place[3], Color.WHITE)
    else:
        var points := PackedVector2Array([pin + Vector2(0, -9), pin + Vector2(8, 0),
            pin + Vector2(0, 9), pin + Vector2(-8, 0)])
        draw_colored_polygon(points, Color("#825323"))
    _centered_text(place[1], pin + Vector2(0, float(place[3]) * 0.55), 17 if id in ["elderwood", "stonehaven"] else 14)

func _centered_text(value: String, position: Vector2, font_size: int) -> void:
    var width := Type.DISPLAY.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    draw_string(Type.DISPLAY, position - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)

func _draw_stamp(index: int, at: Vector2, width: float, tint: Color) -> void:
    var atlas := Art._texture("res://art/ui/cartography_stamps.png")
    if atlas != null:
        var target := Vector2(width, width)
        draw_texture_rect_region(atlas, Rect2(at - target * 0.5, target),
            Rect2(index * 96, 0, 96, 96), tint)

func _current_nearest_landmark() -> String:
    if current_region == "pinewood":
        if current_position.y < 0.0 and pins.has("stonehaven"):
            return "stonehaven"
        return "elderwood" if pins.has("elderwood") else ""
    if current_region == "graveyard":
        return "cemetery" if pins.has("cemetery") else ""
    var closest := ""
    var distance := INF
    for id: String in pins:
        var entry: Array = Data.LANDMARKS[id]
        if entry[0] != current_region:
            continue
        var position: Vector2 = entry[2]
        var candidate := current_position.distance_squared_to(position)
        if candidate < distance:
            closest = id
            distance = candidate
    if closest.is_empty() and current_region == "east_pinewood" and pins.has("stonehaven"):
        return "stonehaven"
    return closest

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var id := _pin_at(event.position)
        tooltip_text = PLACES[id][1] if not id.is_empty() else ""
        mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not id.is_empty() else Control.CURSOR_ARROW
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var id := _pin_at(event.position)
        if not id.is_empty():
            landmark_selected.emit(id)
            accept_event()

func _pin_at(at: Vector2) -> String:
    var closest := ""
    var distance := INF
    for id: String in pins:
        var candidate := at.distance_to(pins[id])
        if candidate < distance and candidate <= float(PLACES[id][3]) * 0.56:
            closest = id
            distance = candidate
    return closest
