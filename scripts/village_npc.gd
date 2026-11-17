extends Node2D
## Small readable NPC marker until character sprites are selected.
func _draw() -> void:
    draw_ellipse_shadow()
    draw_circle(Vector2(0, -19), 11.0, Color("#c99a71"))
    draw_colored_polygon(PackedVector2Array([Vector2(-11,-9),Vector2(11,-9),Vector2(14,13),Vector2(-14,13)]), Color("#805b46"))
    draw_arc(Vector2(0,-22),12.0,PI,TAU,16,Color("#302b27"),4.0)
func draw_ellipse_shadow() -> void:
    draw_circle(Vector2(0,15),12.0,Color(0,0,0,0.35))
