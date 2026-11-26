extends Control

signal landmark_selected(id: String)
const Data := preload("res://scripts/frontier/travel_map_data.gd")
const Type := preload("res://scripts/elderwood_type.gd")
var progress: ConfigFile
var region := "village"
var current_region := ""
var current_position := Vector2.ZERO
var selected := ""
var pins: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    resized.connect(queue_redraw)

func _chart_rect(bounds: Rect2) -> Rect2:
    var zoom := minf((size.x - 38.0) / bounds.size.x, (size.y - 38.0) / bounds.size.y)
    var chart_size := bounds.size * zoom
    return Rect2((size - chart_size) * 0.5, chart_size)

func _plot(point: Vector2, bounds: Rect2, chart: Rect2) -> Vector2:
    return chart.position + ((point - bounds.position) / bounds.size) * chart.size

func _draw() -> void:
    pins.clear()
    if progress == null or size.x < 40 or size.y < 40:
        return
    var bounds: Rect2 = Data.REGIONS[region][1]
    var step: int = Data.REGIONS[region][2]
    var chart := _chart_rect(bounds)
    var fog := Data.cells(progress, region)
    draw_rect(Rect2(Vector2.ZERO, size), Color("#141516"))
    draw_rect(chart, Color("#232427"))
    for cell: Vector2i in fog:
        var patch := Rect2(Vector2(cell) * step, Vector2.ONE * step).intersection(bounds)
        if patch.has_area():
            var shade := Color("#414a3b").lightened(float(posmod(cell.x * 13 + cell.y * 7, 5)) * 0.018)
            draw_rect(Rect2(_plot(patch.position, bounds, chart), patch.size * chart.size / bounds.size), shade)
    for road: Array in Data.roads(region):
        for i in range(road.size() - 1):
            var start: Vector2 = road[i]
            var destination: Vector2 = road[i + 1]
            var steps := maxi(1, ceili(start.distance_to(destination) / (step * 0.25)))
            for j in range(steps):
                var p := start.lerp(destination, float(j) / steps)
                var q := start.lerp(destination, float(j + 1) / steps)
                if bounds.has_point(p) and bounds.has_point(q) and fog.has(Vector2i(((p + q) * 0.5 / step).floor())):
                    draw_line(_plot(p, bounds, chart), _plot(q, bounds, chart), Color("#af9569"), 2.0, true)
    draw_rect(chart, Color("#837054"), false)
    var visited := Data.discovered(progress)
    for id: String in Data.LANDMARKS:
        var entry: Array = Data.LANDMARKS[id]
        if entry[0] != region or not visited.has(id):
            continue
        var pin := _plot(entry[2], bounds, chart)
        pins[id] = pin
        var color := Color("#ffe2a3") if selected == id else Color("#d4ad69")
        draw_colored_polygon(PackedVector2Array([pin + Vector2(0, -8), pin + Vector2(7, 0),
            pin + Vector2(0, 8), pin + Vector2(-7, 0)]), color)
        if selected == id:
            var width := Type.BODY.get_string_size(entry[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
            var label_position := Vector2(clampf(pin.x + 11.0, 8.0, size.x - width - 8.0), maxf(pin.y - 12.0, 18.0))
            draw_string(Type.BODY, label_position, entry[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#fff0d1"))
    if current_region == region:
        var at := _plot(current_position.clamp(bounds.position, bounds.end), bounds, chart)
        draw_circle(at, 5.0, Color("#e9f5e7"), true, -1.0, true)
        draw_arc(at, 8.0, 0.0, TAU, 20, Color("#7dc5b9"), 2.0, true)

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
