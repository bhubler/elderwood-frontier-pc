extends CharacterBody2D
## Four fixed male adventurer designs. No customization dependencies or paid character assets.
const SPEED: float = 235.0
const RACES := ["Human", "High Elf", "Dark Elf", "Orc"]
const LOOKS := {
    "Human": {"skin": Color("#d8a477"), "hair": Color("#493322"), "coat": Color("#506c65"), "trim": Color("#bfa16b"), "ear": 0.0},
    "High Elf": {"skin": Color("#e8c9a3"), "hair": Color("#e6d18c"), "coat": Color("#355e78"), "trim": Color("#d6c27b"), "ear": 1.0},
    "Dark Elf": {"skin": Color("#827d9b"), "hair": Color("#d7d7e5"), "coat": Color("#443a60"), "trim": Color("#b59acb"), "ear": 1.0},
    "Orc": {"skin": Color("#82996b"), "hair": Color("#292d28"), "coat": Color("#655142"), "trim": Color("#a98b5d"), "ear": 0.0}
}
var race: String = "Human"
var choosing_race := true
var selection_layer: CanvasLayer
var facing: Vector2 = Vector2.DOWN
var stride: float = 0.0
var equipped_weapon := ""
var equipped_armor := "cloak"
var attack_bonus := 0
var defense_bonus := 1

func _ready() -> void:
    _build_race_selection()

func set_equipment(gear: Dictionary) -> void:
    equipped_weapon = str(gear.get("weapon", ""))
    equipped_armor = str(gear.get("armor", ""))
    attack_bonus = 3 if equipped_weapon == "rusty_sword" else 0
    defense_bonus = 1 if equipped_armor == "cloak" else 0
    queue_redraw()

func _build_race_selection() -> void:
    selection_layer = CanvasLayer.new()
    selection_layer.layer = 30
    add_child(selection_layer)
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.045, 0.055, 0.055, 0.95)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    selection_layer.add_child(backdrop)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    selection_layer.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(630, 0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#1c2425")
    style.border_color = Color("#ae8b55")
    style.set_border_width_all(3)
    style.set_content_margin_all(24)
    panel.add_theme_stylebox_override("panel", style)
    center.add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    panel.add_child(column)
    var title := Label.new()
    title.text = "ELDERWOOD FRONTIER"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("#e6c68c"))
    column.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "CHOOSE YOUR ADVENTURER  •  FOUR FIXED CHARACTER DESIGNS"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 13)
    subtitle.add_theme_color_override("font_color", Color("#bcb19b"))
    column.add_child(subtitle)
    var descriptions := {
        "Human": "Frontier traveler  /  weathered leather and forest cloak",
        "High Elf": "Ancient wanderer  /  silver-blue robes and golden hair",
        "Dark Elf": "Twilight scout  /  violet mantle and pale hair",
        "Orc": "Wilderness warrior  /  sturdy build and rugged gear"
    }
    for race_name in RACES:
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 70)
        button.text = race_name.to_upper() + "\n" + descriptions[race_name]
        button.add_theme_font_size_override("font_size", 17)
        button.add_theme_color_override("font_color", LOOKS[race_name]["trim"])
        button.pressed.connect(_choose_race.bind(race_name))
        column.add_child(button)
    var note := Label.new()
    note.text = "Choose once to begin exploring. Character art can be upgraded later."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 12)
    column.add_child(note)

func _choose_race(chosen: String) -> void:
    race = chosen
    choosing_race = false
    selection_layer.hide()
    queue_redraw()

func _physics_process(delta: float) -> void:
    if choosing_race:
        velocity = Vector2.ZERO
        return
    var input_vector := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        input_vector.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        input_vector.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        input_vector.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        input_vector.y += 1.0
    velocity = input_vector.normalized() * SPEED
    if input_vector.length_squared() > 0.0:
        facing = input_vector.normalized()
        stride += delta * 10.0
    move_and_slide()
    queue_redraw()

func _draw() -> void:
    var look: Dictionary = LOOKS[race]
    var moving := velocity.length_squared() > 0.0
    var swing: float = sin(stride) * 6.0 if moving else 0.0
    var bob: float = absf(sin(stride)) * 2.0 if moving else 0.0
    var scale_factor: float = 1.14 if race == "Orc" else 1.0
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_factor)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-19, 14), Vector2(-12, 20), Vector2(12, 20), Vector2(19, 14)
    ]), Color(0.02, 0.02, 0.02, 0.38))
    # Alternating boots create a readable walk cycle.
    draw_rect(Rect2(-11, 5 + swing * 0.35, 8, 14), Color("#302c2b"))
    draw_rect(Rect2(3, 5 - swing * 0.35, 8, 14), Color("#302c2b"))
    var cloak: Color = look["coat"] if equipped_armor == "cloak" else Color("#77664c")
    draw_colored_polygon(PackedVector2Array([
        Vector2(-13, -14 - bob), Vector2(13, -14 - bob),
        Vector2(17, 13 - bob), Vector2(-17, 13 - bob)
    ]), cloak.darkened(0.3))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-10, -14 - bob), Vector2(10, -14 - bob),
        Vector2(11, 7 - bob), Vector2(-11, 7 - bob)
    ]), cloak)
    draw_line(Vector2(-10, -3 - bob), Vector2(10, -3 - bob), look["trim"], 2.0)
    # Animated arms, distinct skin tones and pointed elven ears.
    draw_line(Vector2(-12, -10 - bob), Vector2(-16, 5 + swing - bob), look["skin"], 6.0)
    draw_line(Vector2(12, -10 - bob), Vector2(16, 5 - swing - bob), look["skin"], 6.0)
    if float(look["ear"]) > 0.0:
        draw_colored_polygon(PackedVector2Array([
            Vector2(-10, -24 - bob), Vector2(-19, -30 - bob), Vector2(-11, -18 - bob)
        ]), look["skin"])
        draw_colored_polygon(PackedVector2Array([
            Vector2(10, -24 - bob), Vector2(19, -30 - bob), Vector2(11, -18 - bob)
        ]), look["skin"])
    draw_circle(Vector2(0, -23 - bob), 11.0, look["skin"])
    draw_arc(Vector2(0, -25 - bob), 11.5, PI, TAU, 18, look["hair"], 5.0)
    if race == "Orc":
        draw_circle(Vector2(-6, -15 - bob), 2.5, Color("#f0dfbd"))
        draw_circle(Vector2(6, -15 - bob), 2.5, Color("#f0dfbd"))
    if facing.y > -0.2:
        draw_circle(Vector2(-4, -23 - bob), 1.1, Color("#282b2b"))
        draw_circle(Vector2(4, -23 - bob), 1.1, Color("#282b2b"))
    if equipped_weapon == "rusty_sword":
        draw_line(Vector2(16, 2 - swing - bob), Vector2(23, -27 - swing - bob), Color("#c1c6c6"), 4.0)
        draw_line(Vector2(15, -1 - swing - bob), Vector2(28, 1 - swing - bob), Color("#7a5637"), 3.0)
    else:
        draw_line(Vector2(16, 2 - swing - bob), Vector2(20, 13 - swing - bob), Color("#a8b7b9"), 3.0)
    draw_set_transform(Vector2.ZERO)
