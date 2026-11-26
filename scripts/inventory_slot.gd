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
    if empty:
        tooltip_text = empty_label
    else:
        tooltip_text = "%s · %s" % [item["name"], rarity]
        if item.has("charges"):
            tooltip_text += " (%d remaining)" % int(item["charges"])

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
