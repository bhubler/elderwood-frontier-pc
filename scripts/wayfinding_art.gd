extends RefCounted

const SIGN_PATH := "res://art/wayfinding/oak_sign.png"
const GATE_PATH := "res://art/wayfinding/trail_gate.png"
const LETTERING := Color("#e9c582")
const INK_SHADOW := Color("#231408")
static var inscription_font: SystemFont

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
	_draw_inscription(canvas, feet + Vector2(0, -113), title, 105.0, 13)

static func draw_gate(canvas: CanvasItem, feet: Vector2, title: String) -> void:
	var gate := _texture(GATE_PATH)
	if gate != null:
		canvas.draw_texture(gate, feet - Vector2(114, 178))
	_draw_inscription(canvas, feet + Vector2(0, -142), title, 122.0, 13)

static func _draw_inscription(canvas: CanvasItem, center: Vector2, title: String, width: float, font_size: int) -> void:
	if inscription_font == null:
		inscription_font = SystemFont.new()
		inscription_font.font_names = PackedStringArray(["Georgia", "DejaVu Serif", "Times New Roman"])
		inscription_font.font_weight = 700
	while font_size > 1 and inscription_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		font_size -= 1
	var ascent := inscription_font.get_ascent(font_size)
	var descent := inscription_font.get_descent(font_size)
	var baseline := center + Vector2(-width * 0.5, (ascent - descent) * 0.5)
	canvas.draw_string_outline(inscription_font, baseline + Vector2(0, 1), title,
		HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 2, INK_SHADOW)
	canvas.draw_string(inscription_font, baseline, title,
		HORIZONTAL_ALIGNMENT_CENTER, width, font_size, LETTERING)
