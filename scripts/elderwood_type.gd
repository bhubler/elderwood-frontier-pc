extends RefCounted

const BODY := preload("res://art/fonts/noto_serif.res")
const DISPLAY := preload("res://art/fonts/display_font.tres")
const GOLD := Color("#ebcb88")

static func heading(label: Label, color := GOLD) -> void:
    label.add_theme_font_override("font", DISPLAY)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", Color("#241911"))
    label.add_theme_constant_override("outline_size", 3)
    label.add_theme_color_override("font_shadow_color", Color("#0c0a09"))
    label.add_theme_constant_override("shadow_offset_y", 2)
