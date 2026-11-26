extends Button

const Finish := preload("res://scripts/inventory_finish.gd")
const Art := preload("res://scripts/wayfinding_art.gd")
const ATLAS_PATH := "res://art/items/inventory_items.png"
const ICON_CELLS := {
    "rusty_sword": 0, "cloak": 1, "old_map": 2, "bread": 3,
    "healing_potion": 4, "rite_health_potions": 4, "rite_mana_potions": 5,
    "sentinel_sword": 6, "ruin_ward_clasp": 7, "ruin_watch_mantle": 8,
    "ancient_magic_stone": 9, "forbidden_grimoire": 10, "sealed_ledger": 11,
}
const RARITY_COLORS := {
    "Common": Color("#41413a"),
    "Uncommon": Color("#355d48"),
    "Rare": Color("#3e5381"),
    "Epic": Color("#634779"),
    "Legendary": Color("#885b31"),
    "Unique": Color("#7d3c42"),
    "Quest": Color("#62563a"),
}
static var icons: Dictionary = {}
var tooltip_heading := ""
var tooltip_meta := ""
var tooltip_body: Array[String] = []
var tooltip_accent := Finish.GOLD

func _init() -> void:
    custom_minimum_size = Vector2(64, 64)
    size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    expand_icon = true
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_theme_constant_override("icon_max_width", 52)
    add_theme_font_size_override("font_size", 24)

func show_item(item_id: String, item: Dictionary, empty_label := "Empty backpack slot") -> void:
    var empty := item.is_empty()
    disabled = empty
    var rarity: String = item.get("rarity", "Common")
    var background: Color = Finish.RECESS if empty else RARITY_COLORS.get(rarity, RARITY_COLORS["Common"])
    var border: Color = Color("#524a39") if empty else background.lightened(0.38)
    Finish.style_button(self, background, border, 5)
    icon = _item_icon(item_id) if not empty else null
    text = str(item.get("icon", "")) if icon == null else ""
    tooltip_text = empty_label if empty else str(item["name"])
    tooltip_heading = tooltip_text
    tooltip_meta = ""
    tooltip_body.clear()
    tooltip_accent = Finish.GOLD if empty else border.lightened(0.25)
    if empty:
        return
    tooltip_meta = "%s · %s" % [rarity, str(item.get("kind", "item")).capitalize()]
    var description := str(item.get("description", ""))
    if not description.is_empty():
        tooltip_body.append(description)
    for stat in ["attack", "defense", "charges", "weight", "value"]:
        if item.has(stat):
            tooltip_body.append("%s  %s" % [stat.capitalize(), str(item[stat])])

func _make_custom_tooltip(_text: String) -> Control:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", Finish.surface(Finish.RECESS, Finish.BRASS, 12, true, true))
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 5)
    panel.add_child(stack)
    _tooltip_line(stack, tooltip_heading, Finish.INK, 18)
    if not tooltip_meta.is_empty():
        _tooltip_line(stack, tooltip_meta, tooltip_accent, 14)
    for line in tooltip_body:
        _tooltip_line(stack, line, Finish.INK, 14)
    return panel

static func _tooltip_line(parent: VBoxContainer, content: String, color: Color, font_size: int) -> void:
    var label := Label.new()
    # Give the tooltip its final line breaks before Godot measures its popup window.
    var font := ThemeDB.fallback_font
    var lines: Array[String] = []
    for paragraph in content.split("\n"):
        var current := ""
        for word in paragraph.split(" ", false):
            var candidate := word if current.is_empty() else current + " " + word
            if not current.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 285:
                lines.append(current)
                current = word
            else:
                current = candidate
        lines.append(current)
    label.text = "\n".join(lines)
    label.add_theme_font_override("font", font)
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_size_override("font_size", font_size)
    parent.add_child(label)

static func _item_icon(item_id: String) -> Texture2D:
    if icons.has(item_id):
        return icons[item_id]
    if item_id == "watch_provisions":
        return Art._texture("res://art/interiors/shops/sacks.png")
    if not ICON_CELLS.has(item_id):
        return null
    var atlas := Art._texture(ATLAS_PATH)
    if atlas == null:
        return null
    var index: int = ICON_CELLS[item_id]
    var cell := atlas.get_size() / Vector2(4, 3)
    var texture := AtlasTexture.new()
    texture.atlas = atlas
    texture.filter_clip = true
    texture.region = Rect2(Vector2(index % 4, index >> 2) * cell, cell)
    icons[item_id] = texture
    return texture
