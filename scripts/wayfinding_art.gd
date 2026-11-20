extends RefCounted

const SIGN := preload("res://art/wayfinding/oak_sign.png")
const GATE := preload("res://art/wayfinding/trail_gate.png")
const LETTERING := Color("#f7dda4")

static func draw_sign(canvas: CanvasItem, feet: Vector2, title: String) -> void:
	canvas.draw_texture(SIGN, feet - Vector2(71, 166))
	var font_size := 13
	if ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 120.0:
		font_size = 10
	canvas.draw_string(ThemeDB.fallback_font, feet + Vector2(-63, -109), title,
		HORIZONTAL_ALIGNMENT_CENTER, 126, font_size, LETTERING)

static func draw_gate(canvas: CanvasItem, feet: Vector2, title: String) -> void:
	canvas.draw_texture(GATE, feet - Vector2(114, 178))
	canvas.draw_string(ThemeDB.fallback_font, feet + Vector2(-67, -137), title,
		HORIZONTAL_ALIGNMENT_CENTER, 134, 12, LETTERING)
