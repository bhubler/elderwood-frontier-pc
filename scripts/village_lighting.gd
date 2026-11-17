extends Node2D
## Nightfall lighting pass. Uses Godot 2D lights, not baked-in image glow.
## Keep this separate from the village drawing so we can replace art later.

func _ready() -> void:
    var night := CanvasModulate.new()
    night.name = "DuskTint"
    night.color = Color(0.53, 0.59, 0.72)
    add_child(night)

    var light_texture: ImageTexture = _make_light_texture()
    var spots: Array[Vector2] = [
        Vector2(-390, -240), Vector2(390, -230),
        Vector2(-430, 170), Vector2(415, 180),
        Vector2(-185, -200), Vector2(185, -200),
        Vector2(-185, 70), Vector2(185, 70),
        Vector2(0, -75)
    ]
    for i in range(spots.size()):
        var lamp := PointLight2D.new()
        lamp.name = "WarmLight_%d" % i
        lamp.position = spots[i]
        lamp.texture = light_texture
        lamp.texture_scale = 2.5 if i < 4 else 1.8
        lamp.color = Color(1.0, 0.68, 0.36)
        lamp.energy = 0.9
        add_child(lamp)

func _make_light_texture() -> ImageTexture:
    var size_px: int = 128
    var img := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
    for y in range(size_px):
        for x in range(size_px):
            var dx: float = (float(x) - 63.5) / 63.5
            var dy: float = (float(y) - 63.5) / 63.5
            var radius: float = sqrt(dx * dx + dy * dy)
            var alpha: float = pow(maxf(0.0, 1.0 - radius), 2.0)
            img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
    return ImageTexture.create_from_image(img)
