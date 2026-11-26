extends HBoxContainer

const ElderwoodType := preload("res://scripts/elderwood_type.gd")

const Slot := preload("res://scripts/inventory_slot.gd")
const Finish := preload("res://scripts/inventory_finish.gd")
const Art := preload("res://scripts/wayfinding_art.gd")
const ICONS := "res://art/items/spell_icons.png"
const SCHOOLS := [
    "Elemental", "Restoration", "Necromancy", "Blood Magic", "Curse Magic",
    "Shadow Magic", "Soul Magic", "Alteration", "Sacred Miracles",
    "Runecrafting", "Enchanting", "Alchemy",
]

var title: Label
var entries: VBoxContainer
var school := "Elemental"
var summon_learned := false

func _ready() -> void:
    add_theme_constant_override("separation", 24)
    var sidebar := ScrollContainer.new()
    sidebar.custom_minimum_size.x = 210
    sidebar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    sidebar.follow_focus = true
    add_child(sidebar)
    var navigation := VBoxContainer.new()
    navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    navigation.add_theme_constant_override("separation", 5)
    sidebar.add_child(navigation)
    var selection := ButtonGroup.new()
    for name_text: String in SCHOOLS:
        var button := Button.new()
        button.text = name_text
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.toggle_mode = true
        button.button_group = selection
        button.button_pressed = name_text == school
        button.pressed.connect(_show_school.bind(name_text))
        Finish.style_button(button, Finish.CHARCOAL, Finish.BRASS, 8, false)
        navigation.add_child(button)
    var page := VBoxContainer.new()
    page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    page.add_theme_constant_override("separation", 16)
    add_child(page)
    title = Label.new()
    ElderwoodType.heading(title)
    title.add_theme_font_size_override("font_size", 25)
    title.add_theme_color_override("font_color", Finish.GOLD)
    page.add_child(title)
    entries = VBoxContainer.new()
    page.add_child(entries)
    _show_school(school)

func show_progress(learned: bool) -> void:
    summon_learned = learned
    _show_school(school)

func _show_school(selected: String) -> void:
    school = selected
    title.text = school
    for child in entries.get_children():
        entries.remove_child(child)
        child.queue_free()
    match school:
        "Elemental":
            _add_spell("Fireball", "Known · Starting spell",
                "Launch a guiding bolt of fire toward an enemy.", "RMB or F · 2 mana in Pinewood, 30 mana in frontier areas", 0)
        "Restoration":
            _add_spell("Mending Light", "Preview · Unavailable",
                "A restoration spell intended to heal wounds.", "", 2)
        "Necromancy":
            _add_spell("Summon Skeleton", "Known" if summon_learned else "Locked",
                "Raise a skeleton to fight beside you." if summon_learned else "Study the Forbidden Grimoire to learn this spell.",
                "Q · 45 mana in frontier areas" if summon_learned else "", 1)
        _:
            var empty := Label.new()
            empty.text = "No known spells in this school."
            entries.add_child(empty)

func _add_spell(spell_name: String, status: String, description: String, controls: String, index: int) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    entries.add_child(row)
    var tile := Slot.new()
    tile.custom_minimum_size = Vector2(78, 78)
    tile.add_theme_constant_override("icon_max_width", 66)
    var atlas := Art._texture(ICONS)
    if atlas != null:
        var width := atlas.get_width() / 3.0
        var icon := AtlasTexture.new()
        icon.atlas = atlas
        icon.filter_clip = true
        icon.region = Rect2(width * index, 0, width, atlas.get_height())
        tile.icon = icon
    if tile.icon == null:
        tile.text = "✦"
    tile.tooltip_text = spell_name
    tile.tooltip_heading = spell_name
    tile.tooltip_meta = "%s · %s" % [school, status]
    tile.tooltip_body.append(description)
    if not controls.is_empty():
        tile.tooltip_body.append(controls)
    Finish.style_button(tile, Finish.RECESS, Finish.BRASS, 6)
    row.add_child(tile)
    var labels := VBoxContainer.new()
    labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(labels)
    var heading := Label.new()
    ElderwoodType.heading(heading)
    heading.text = spell_name
    heading.add_theme_font_size_override("font_size", 19)
    labels.add_child(heading)
    var state := Label.new()
    state.text = status
    state.add_theme_color_override("font_color", Finish.GOLD)
    labels.add_child(state)
