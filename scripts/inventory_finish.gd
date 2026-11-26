extends RefCounted
## Textured nine-slice surfaces for the inventory. The trim stays sharp as panels resize.

const SIZE := 96
const TRIM := 7
const INK := Color("#e5ddce")
const GOLD := Color("#cdb080")
const CHARCOAL := Color("#2b2c2d")
const RECESS := Color("#1c1d1e")
const BRASS := Color("#817054")

static var surfaces: Dictionary = {}

static func surface(base: Color, trim: Color, padding: int, recessed := false, rivets := false) -> StyleBoxTexture:
    var key := [base, trim, padding, recessed, rivets]
    if surfaces.has(key):
        return surfaces[key]
    var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
    var grain := RandomNumberGenerator.new()
    grain.seed = 18349
    for y in range(SIZE):
        for x in range(SIZE):
            var near := mini(x, y)
            var far := mini(SIZE - 1 - x, SIZE - 1 - y)
            var edge := mini(near, far)
            var shade := grain.randf_range(-0.023, 0.023) + (0.5 - float(y) / SIZE) * 0.034
            var pixel := _shade(base, shade)
            match edge:
                0: pixel = Color("#101012")
                1: pixel = _shade(trim, 0.16 if near < far else -0.23)
                2: pixel = _shade(trim, -0.39)
                3: pixel = _shade(base, 0.14 if near < far else 0.025)
                4, 5:
                    var lit := (far < near) if recessed else (near < far)
                    pixel = _shade(base, 0.055 if lit else -0.22)
            image.set_pixel(x, y, pixel)
    if rivets:
        for origin in [Vector2i(5, 5), Vector2i(SIZE - 8, 5), Vector2i(5, SIZE - 8), Vector2i(SIZE - 8, SIZE - 8)]:
            image.fill_rect(Rect2i(origin, Vector2i(3, 3)), trim.lightened(0.26))
            image.set_pixelv(origin + Vector2i(2, 2), trim.darkened(0.48))
    var style := StyleBoxTexture.new()
    style.texture = ImageTexture.create_from_image(image)
    style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
    for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
        style.set_texture_margin(side, TRIM + (1 if rivets else 0))
        style.set_content_margin(side, padding)
    surfaces[key] = style
    return style

static func _shade(color: Color, value: float) -> Color:
    return color.lightened(value) if value >= 0.0 else color.darkened(-value)

static func style_button(button: Button, base: Color, trim: Color, padding: int, recessed := true) -> void:
    button.add_theme_stylebox_override("normal", surface(base, trim, padding, recessed))
    button.add_theme_stylebox_override("disabled", surface(base, trim, padding, recessed))
    button.add_theme_stylebox_override("hover", surface(base.lightened(0.10), trim.lightened(0.25), padding, recessed))
    button.add_theme_stylebox_override("pressed", surface(base.darkened(0.16), trim.lightened(0.12), padding, true))
    var focus := StyleBoxFlat.new()
    focus.bg_color = Color.TRANSPARENT
    focus.border_color = GOLD
    focus.set_border_width_all(2)
    button.add_theme_stylebox_override("focus", focus)
    button.add_theme_color_override("font_color", INK)
    button.add_theme_color_override("font_hover_color", Color.WHITE)


static func style_dialog(panel: PanelContainer) -> void:
    panel.add_theme_stylebox_override("panel", surface(CHARCOAL, BRASS, 18, false, true))

static func style_dialog_action(button: Button) -> void:
    style_button(button, Color("#3a3228"), BRASS, 8, false)
