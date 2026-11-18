extends Node2D
## Temporary geometry for a bounded chapter room.
const BOUNDS := Rect2(-510, -290, 1020, 580)
var ground := Color("#282f2b")
var outdoors := false

func _draw() -> void:
    draw_rect(BOUNDS, ground)
    draw_rect(BOUNDS, ground.lightened(0.23), false, 4)
    for x in range(-480, 500, 48):
        for y in range(-265, 285, 48):
            var point := Vector2(x, y)
            if outdoors:
                draw_line(point, point + Vector2(4, -7), ground.lightened(0.14), 2)
            else:
                draw_line(point, point + Vector2(33, 0), ground.lightened(0.09), 2)
