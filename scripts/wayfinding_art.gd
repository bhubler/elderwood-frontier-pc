extends RefCounted

const SIGN_PATH := "res://art/wayfinding/oak_sign.png"
const GATE_PATH := "res://art/wayfinding/trail_gate.png"
const LETTERING := Color("#f7dda4")

static var textures: Dictionary = {}

static func _texture(path: String) -> Texture2D:
	if textures.has(path):
		return textures[path]
	var texture: Texture2D
	# A newly pulled PNG can be available before its editor import cache exists.
	if OS.has_feature("editor") and FileAccess.file_exists(path):
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			texture = ImageTexture.create_from_image(image)
	if texture == null and ResourceLoader.exists(path, "Texture2D"):
		texture = load(path) as Texture2D
	textures[path] = texture
	return texture

static func draw_sign(canvas: CanvasItem, feet: Vector2, title: String) -> void:
	var sign := _texture(SIGN_PATH)
	if sign != null:
		canvas.draw_texture(sign, feet - Vector2(71, 166))
	var font_size := 13
	if ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 120.0:
		font_size = 10
	canvas.draw_string(ThemeDB.fallback_font, feet + Vector2(-63, -109), title,
		HORIZONTAL_ALIGNMENT_CENTER, 126, font_size, LETTERING)

static func draw_gate(canvas: CanvasItem, feet: Vector2, title: String) -> void:
	var gate := _texture(GATE_PATH)
	if gate != null:
		canvas.draw_texture(gate, feet - Vector2(114, 178))
	canvas.draw_string(ThemeDB.fallback_font, feet + Vector2(-67, -137), title,
		HORIZONTAL_ALIGNMENT_CENTER, 134, 12, LETTERING)
