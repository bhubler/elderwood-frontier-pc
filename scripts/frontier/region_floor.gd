extends Node2D
## Temporary geometry for a bounded chapter room.
const BOUNDS := Rect2(-510, -290, 1020, 580)
var ground := Color("#282f2b")
var region_id := ""

func _draw() -> void:
    draw_rect(BOUNDS, ground)
    draw_rect(BOUNDS, ground.lightened(0.23), false, 4)
    var outdoors := region_id in ["graveyard", "stonehaven", "town_court", "raided_caravan", "old_cabin", "northern_watch"]
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
        "stonehaven", "town_court":
            draw_rect(Rect2(-485, -156, 970, 225), Color("#48433d"))
            for row in range(10):
                for column in range(34):
                    var p := Vector2(-477 + column * 28 + 9 * (row % 2), -148 + row * 21)
                    var tile := Color("#655c50") if (column + row) % 5 == 0 else Color("#56514a")
                    draw_rect(Rect2(p, Vector2(24, 17)), tile)
        "raided_caravan", "old_cabin", "northern_watch":
            draw_line(Vector2(0, 286), Vector2(0, -92), Color("#514738"), 82.0, true)
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
func _draw_stonework(at: Vector2, size: Vector2) -> void:
    draw_rect(Rect2(at - size / 2 + Vector2(0, 10), size), ground.darkened(0.45))
    draw_rect(Rect2(at - size / 2, size), ground.lightened(0.22))
    draw_rect(Rect2(at - size / 2 + Vector2(5, 5), size - Vector2(10, 10)), ground.lightened(0.1))
