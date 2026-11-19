extends Node2D
const ART := {
    &"Mara": preload("res://art/characters/original/mara.png"),
    &"Elden": preload("res://art/characters/original/elden.png"),
    &"Pip": preload("res://art/characters/original/pip.png"),
    &"Rowan": preload("res://art/characters/original/rowan.png"),
}
var artwork_height: float

func _ready() -> void:
    var texture: Texture2D = ART.get(name)
    if texture == null:
        return
    var sprite := Sprite2D.new()
    sprite.name = "Artwork"
    sprite.texture = texture
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var height := artwork_height
    sprite.scale = Vector2.ONE * (height / texture.get_height())
    sprite.position = Vector2(0, 15.0 - height / 2.0)
    add_child(sprite)

func _draw() -> void:
    draw_ellipse_shadow()
    if ART.has(name):
        return
    draw_circle(Vector2(0, -19), 11.0, Color("#c99a71"))
    draw_colored_polygon(PackedVector2Array([Vector2(-11,-9),Vector2(11,-9),Vector2(14,13),Vector2(-14,13)]), Color("#805b46"))
    draw_arc(Vector2(0,-22),12.0,PI,TAU,16,Color("#302b27"),4.0)
func draw_ellipse_shadow() -> void:
    draw_circle(Vector2(0,15),12.0,Color(0,0,0,0.35))
