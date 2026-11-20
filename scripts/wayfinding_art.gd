extends RefCounted

const ELDERWOOD_SIGN := "res://art/wayfinding/elderwood_sign.png"
const STONEHAVEN_SIGN := "res://art/wayfinding/stonehaven_sign.png"
const PINEWOOD_GATE := "res://art/wayfinding/pinewood_gate.png"
const ELDERWOOD_GATE := "res://art/wayfinding/elderwood_gate.png"

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

static func draw_landmark(canvas: CanvasItem, feet: Vector2, path: String) -> void:
	var texture := _texture(path)
	if texture != null:
		canvas.draw_texture(texture, feet - Vector2(texture.get_width() * 0.5, texture.get_height()))
