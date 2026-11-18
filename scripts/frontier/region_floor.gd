extends Node2D
## Temporary geometry for a bounded chapter room.
const BOUNDS := Rect2(-510, -290, 1020, 580)
var ground := Color("#282f2b")
var region_id := ""

func _draw() -> void:
    draw_rect(BOUNDS, ground)
    draw_rect(BOUNDS, ground.lightened(0.23), false, 4)
    var outdoors := region_id in ["graveyard", "stonehaven"]
    for x in range(-480, 500, 48):
        for y in range(-265, 285, 48):
            var point := Vector2(x, y)
            if outdoors:
                draw_line(point, point + Vector2(4, -7), ground.lightened(0.14), 2)
            else:
                draw_line(point, point + Vector2(33, 0), ground.lightened(0.09), 2)
    match region_id:
        "graveyard":
            _draw_graveyard()
        "stonehaven":
            for x in [-420, -240, 195, 370]:
                _draw_stonework(Vector2(x, -210), Vector2(130, 60))
        _:
            for x in [-335, 335]:
                for y in [-175, 105]:
                    _draw_stonework(Vector2(x, y), Vector2(45, 36))
                    draw_circle(Vector2(x, y - 36), 17, Color(0.88, 0.53, 0.24, 0.25))
                    draw_circle(Vector2(x, y - 36), 5, Color("#e4a45d"))
            if region_id == "crypt_ritual":
                draw_arc(Vector2(0, -55), 110, 0, TAU, 64, Color("#695077"), 3, true)
                draw_arc(Vector2(0, -55), 91, 0, TAU, 64, Color("#51425b"), 2, true)

func _draw_graveyard() -> void:
    draw_polyline(PackedVector2Array([
        Vector2(0, 290), Vector2(-60, 170), Vector2(-36, 50),
        Vector2(14, -90), Vector2(0, -260)
    ]), Color("#494338"), 40, true)
    draw_polyline(PackedVector2Array([
        Vector2(-60, 170), Vector2(100, 155), Vector2(245, 95), Vector2(510, 120)
    ]), Color("#494338"), 28, true)
    for row in range(3):
        for column in range(4):
            var position_offset := Vector2(column * 73, row * 104)
            _draw_headstone(Vector2(-450, -163) + position_offset)
            _draw_headstone(Vector2(161, -172) + position_offset)

func _draw_headstone(at: Vector2) -> void:
    draw_rect(Rect2(at + Vector2(-18, -9), Vector2(46, 45)), Color("#343831"))
    draw_rect(Rect2(at + Vector2(-14, -22), Vector2(27, 29)), Color("#68716a"))
    draw_circle(at + Vector2(-0.5, -22), 13.5, Color("#68716a"))
    draw_line(at + Vector2(-7, -14), at + Vector2(6, -14), Color("#3e4842"), 2)

func _draw_stonework(at: Vector2, size: Vector2) -> void:
    draw_rect(Rect2(at - size / 2 + Vector2(0, 10), size), ground.darkened(0.45))
    draw_rect(Rect2(at - size / 2, size), ground.lightened(0.22))
    draw_rect(Rect2(at - size / 2 + Vector2(5, 5), size - Vector2(10, 10)), ground.lightened(0.1))
