extends Control

signal landmark_selected(id: String)
const Data := preload("res://scripts/frontier/travel_map_data.gd")
const Art := preload("res://scripts/wayfinding_art.gd")
const Routes := preload("res://scripts/forest_layout.gd")
const INK := Color("#513821")
const PARCHMENT := Color("#d2b17b")
const Type := preload("res://scripts/elderwood_type.gd")
var progress: ConfigFile
var region := "village"
var current_region := ""
var current_position := Vector2.ZERO
var selected := ""
var pins: Dictionary = {}
var exploration_tint: ImageTexture
var parchment: Texture2D

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    resized.connect(queue_redraw)
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _chart_rect(bounds: Rect2) -> Rect2:
    var zoom := minf((size.x - 100.0) / bounds.size.x, (size.y - 110.0) / bounds.size.y)
    var chart_size := bounds.size * zoom
    return Rect2((size - chart_size) * 0.5, chart_size)

func _plot(point: Vector2, bounds: Rect2, chart: Rect2) -> Vector2:
    return chart.position + ((point - bounds.position) / bounds.size) * chart.size

func _draw() -> void:
    pins.clear()
    if progress == null or size.x < 150 or size.y < 150:
        return
    var bounds: Rect2 = Data.REGIONS[region][1]
    var step: int = Data.REGIONS[region][2]
    var chart := _chart_rect(bounds)
    var fog := Data.cells(progress, region)
    _draw_parchment()
    _draw_cartographic_margin(chart)
    _draw_exploration(bounds, chart, step, fog)
    var roads := Data.roads(region)
    _draw_woodlands(bounds, chart, step, fog, roads)
    _draw_roads(bounds, chart, step, fog, roads)
    var visited := Data.discovered(progress)
    for id: String in Data.LANDMARKS:
        var entry: Array = Data.LANDMARKS[id]
        if entry[0] != region or not visited.has(id):
            continue
        var pin := _plot(entry[2], bounds, chart)
        pins[id] = pin
        _draw_landmark(id, pin)
        if selected == id:
            var width := Type.BODY.get_string_size(entry[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
            var label_position := Vector2(clampf(pin.x + 11.0, 8.0, size.x - width - 8.0), maxf(pin.y - 27.0, 23.0))
            draw_string(Type.BODY, label_position, entry[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
    if current_region == region:
        var at := _plot(current_position.clamp(bounds.position, bounds.end), bounds, chart)
        draw_circle(at, 6.0, Color("#f8dfaa"), true, -1.0, true)
        draw_circle(at, 4.0, Color("#366660"), true, -1.0, true)

func _draw_parchment() -> void:
    var sheet := Rect2(Vector2.ZERO, size)
    if parchment == null and ResourceLoader.exists("res://art/ui/frontier_parchment.webp"):
        parchment = load("res://art/ui/frontier_parchment.webp") as Texture2D
    draw_rect(sheet, PARCHMENT)
    if parchment != null:
        draw_texture_rect(parchment, sheet, false)
    var name_text: String = Data.REGIONS[region][0]
    var width := Type.DISPLAY.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
    draw_string(Type.DISPLAY, Vector2((size.x - width) * 0.5, 39), name_text,
        HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
    var compass := Vector2(54, 70)
    draw_arc(compass, 16, 0, TAU, 24, Color(INK, 0.54), 1.0, true)
    draw_line(compass + Vector2(-21, 0), compass + Vector2(21, 0), Color(INK, 0.76), 1.0, true)
    draw_colored_polygon(PackedVector2Array([
        compass + Vector2(0, -22), compass + Vector2(5, 5), compass + Vector2(0, 2), compass + Vector2(-5, 5),
    ]), INK)
    draw_string(Type.DISPLAY, compass + Vector2(-5, -24), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)

func _draw_cartographic_margin(chart: Rect2) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = region.hash() + 3204
    for side: float in [-1.0, 1.0]:
        var inside := chart.position.x if side < 0.0 else chart.end.x
        for column in range(2):
            var x := inside + side * (28 + column * 38)
            if x < 68.0 or x > size.x - 68.0:
                continue
            for row in range(6):
                if rng.randf() < 0.24:
                    continue
                var y := lerpf(142.0, size.y - 92.0, (row + rng.randf()) / 6.0)
                _draw_stamp(0, Vector2(x + rng.randf_range(-9, 9), y), rng.randf_range(34, 58),
                    Color(1.0, 1.0, 1.0, 0.43))

func _draw_exploration(bounds: Rect2, chart: Rect2, step: int, fog: Dictionary) -> void:
    # Blend the reveal tint between neighboring cells, then sample it with linear filtering.
    var origin := Vector2i((bounds.position / step).floor()) - Vector2i.ONE
    var end := Vector2i((bounds.end / step).ceil()) + Vector2i.ONE
    var extent := end - origin
    var mask := Image.create_empty(extent.x, extent.y, false, Image.FORMAT_RGBA8)
    for y in range(extent.y):
        for x in range(extent.x):
            var cell := origin + Vector2i(x, y)
            var opacity := 0.0
            for row in range(-1, 2):
                for column in range(-1, 2):
                    if fog.has(cell + Vector2i(column, row)):
                        opacity += 0.12 if column == 0 and row == 0 else 0.023
            mask.set_pixel(x, y, Color(1.0, 0.91, 0.65, opacity))
    exploration_tint = ImageTexture.create_from_image(mask)
    var tint := Rect2(_plot(Vector2(origin) * step, bounds, chart), Vector2(extent) * step * chart.size / bounds.size)
    draw_texture_rect(exploration_tint, tint, false)

func _draw_woodlands(bounds: Rect2, chart: Rect2, step: int, fog: Dictionary, roads: Array) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = region.hash() + 41521
    var columns := ceili(chart.size.x / 26.0)
    var rows := ceili(chart.size.y / 25.0)
    for y in range(rows):
        for x in range(columns):
            var uv := Vector2((x + rng.randf_range(0.12, 0.88)) / columns,
                (y + rng.randf_range(0.12, 0.88)) / rows)
            var edge := minf(minf(uv.x, 1.0 - uv.x), minf(uv.y, 1.0 - uv.y))
            var where := bounds.position + uv * bounds.size
            var known := fog.has(Vector2i((where / step).floor()))
            var threshold := 0.60 if edge < 0.14 else 0.24
            if region == "east_pinewood" or region == "pinewood":
                threshold += 0.12
            var sample := rng.randf()
            var width := rng.randf_range(23.0, 46.0)
            if sample >= threshold or (edge > 0.14 and not known):
                continue
            if known and Routes.near_route(where, roads, step * 0.66):
                continue
            var at := _plot(where, bounds, chart)
            if at.x < 93 and at.y < 100:
                continue
            _draw_stamp(0, at, width, Color(1.0, 1.0, 1.0, 0.87 if known else 0.32))

func _draw_roads(bounds: Rect2, chart: Rect2, step: int, fog: Dictionary, roads: Array) -> void:
    for road: Array in roads:
        for i in range(road.size() - 1):
            var start: Vector2 = road[i]
            var destination: Vector2 = road[i + 1]
            var steps := maxi(1, ceili(start.distance_to(destination) / (step * 0.25)))
            for j in range(steps):
                var p := start.lerp(destination, float(j) / steps)
                var q := start.lerp(destination, float(j + 1) / steps)
                if bounds.has_point(p) and bounds.has_point(q) and fog.has(Vector2i(((p + q) * 0.5 / step).floor())):
                    var a := _plot(p, bounds, chart)
                    var b := _plot(q, bounds, chart)
                    draw_line(a, b, Color("#725336"), 3.0, true)
                    draw_line(a, b, Color("#d8b582"), 1.0, true)

func _draw_landmark(id: String, pin: Vector2) -> void:
    if id in ["elderwood", "inn", "guild", "manor", "church", "cabin"]:
        _draw_stamp(1, pin - Vector2(0, 10), 40.0, Color.WHITE)
    elif id in ["watchtower", "stonehaven", "ruins", "crypt"]:
        _draw_stamp(2, pin - Vector2(0, 12), 36.0, Color.WHITE)
    var color := Color("#fff0b2") if selected == id else Color("#b68642")
    draw_circle(pin, 6.0, INK, true, -1.0, true)
    draw_circle(pin, 3.7, color, true, -1.0, true)

func _draw_stamp(index: int, at: Vector2, width: float, tint: Color) -> void:
    var atlas := Art._texture("res://art/ui/cartography_stamps.png")
    if atlas != null:
        var target := Vector2(width, width)
        draw_texture_rect_region(atlas, Rect2(at - target * 0.5, target),
            Rect2(index * 96, 0, 96, 96), tint)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var id := _pin_at(event.position)
        tooltip_text = Data.LANDMARKS[id][1] if not id.is_empty() else ""
        mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not id.is_empty() else Control.CURSOR_ARROW
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var id := _pin_at(event.position)
        if not id.is_empty():
            landmark_selected.emit(id)
            accept_event()

func _pin_at(at: Vector2) -> String:
    var closest := ""
    var distance := 13.0
    for id: String in pins:
        var candidate := at.distance_to(pins[id])
        if candidate < distance:
            closest = id
            distance = candidate
    return closest
