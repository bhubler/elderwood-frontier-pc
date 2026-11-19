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

const RACE_ART := {
    "Human": preload("res://art/characters/original/human.png"),
    "Dark Elf": preload("res://art/characters/original/dark_elf.png"),
}
const SWORD_ART_REFERENCE_HEIGHT := 50.0
const DEFAULT_CHARACTER_ART_HEIGHT := 68.0
const RACE_ART_FEET_Y := 18.0

var character_art_height := DEFAULT_CHARACTER_ART_HEIGHT
var race_sprite: Sprite2D
var animated_sprite: Sprite2D
var necromancer_sprite: Sprite2D
var necromancer_appearance_enabled: bool = true
var necromancer_idle_clock: float = 0.0
@export_range(0.15, 0.50, 0.01) var necromancer_scale: float = 0.27
const NECROMANCER_ART := "res://art/characters/necromancer/elderwood_necromancer_player.png"
var animation_sheets: Dictionary = {}
var animation_name: String = ""
var animation_frame: int = 0
var animation_elapsed: float = 0.0
const ANIMATION_COLUMNS: int = 4
const ANIMATION_COLUMNS_BY_TYPE := {"idle": 8, "walk": 8, "run": 4}
const ANIMATION_ROWS: int = 5
const RUN_MULTIPLIER: float = 1.55

func _load_character_animation() -> void:
    var root: String = "res://art/characters/penzilla/"
    var filenames: Dictionary = {
        "idle": "Character0_Idle.png",
        "walk": "Character0_Walk.png",
        "run": "Character0_Run.png"
    }
    for kind in filenames:
        var path: String = root + str(filenames[kind])
        if ResourceLoader.exists(path):
            var texture: Texture2D = load(path) as Texture2D
            if texture != null:
                animation_sheets[kind] = texture
    if animation_sheets.is_empty():
        return
    animated_sprite = Sprite2D.new()
    animated_sprite.name = "PenzillaAnimatedCharacter"
    animated_sprite.centered = true
    animated_sprite.region_enabled = true
    animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    animated_sprite.scale = Vector2(0.14, 0.14)
    animated_sprite.position = Vector2(0, -13)
    add_child(animated_sprite)
    _set_animation("idle")
    _update_animation_frame()

func _set_animation(next_name: String) -> void:
    if not animation_sheets.has(next_name):
        if animation_sheets.has("walk"):
            next_name = "walk"
        elif animation_sheets.has("idle"):
            next_name = "idle"
        elif animation_sheets.has("run"):
            next_name = "run"
        else:
            return
    if animation_name == next_name:
        return
    animation_name = next_name
    animation_frame = 0
    animation_elapsed = 0.0
    animated_sprite.texture = animation_sheets[animation_name]
    _update_animation_frame()

func _update_animation_frame() -> void:
    if animated_sprite == null or animated_sprite.texture == null:
        return
    var tex: Texture2D = animated_sprite.texture
    var columns: int = int(ANIMATION_COLUMNS_BY_TYPE.get(animation_name, ANIMATION_COLUMNS))
    var cell_width: int = int(tex.get_width() / columns)
    var cell_height: int = int(tex.get_height() / ANIMATION_ROWS)
    if cell_width <= 0 or cell_height <= 0:
        return
    var direction_row: int = 0
    if absf(facing.x) > absf(facing.y):
        direction_row = 1 if facing.x > 0.0 else 2
    elif facing.y < 0.0:
        direction_row = 3
    animated_sprite.region_rect = Rect2(
        animation_frame * cell_width,
        direction_row * cell_height,
        cell_width,
        cell_height
    )

func _advance_animation(delta: float, moving: bool, running: bool) -> void:
    if animated_sprite == null:
        return
    _set_animation("run" if running else ("walk" if moving else "idle"))
    animation_elapsed += delta
    var seconds_per_frame: float = 0.105 if running else (0.17 if moving else 0.28)
    if animation_elapsed >= seconds_per_frame:
        animation_elapsed = fmod(animation_elapsed, seconds_per_frame)
        animation_frame = (animation_frame + 1) % int(ANIMATION_COLUMNS_BY_TYPE.get(animation_name, ANIMATION_COLUMNS))
    _update_animation_frame()


func _ready() -> void:
    _load_character_animation()
    _load_necromancer_appearance()
    race_sprite = Sprite2D.new()
    race_sprite.name = "OriginalRaceArtwork"
    race_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(race_sprite)
    _refresh_character_appearance()
    _build_race_selection()

func _load_necromancer_appearance() -> void:
    # Optional, locally installed original illustration. Other races keep existing art.
    if not ResourceLoader.exists(NECROMANCER_ART):
        return
    var tex: Texture2D = load(NECROMANCER_ART) as Texture2D
    if tex == null:
        return
    # Use the opaque bounds so padding in the local PNG does not affect size matching.
    var image := tex.get_image()
    if image != null:
        var visible_height := image.get_used_rect().size.y
        if visible_height > 0:
            character_art_height = visible_height * necromancer_scale
    necromancer_sprite = Sprite2D.new()
    necromancer_sprite.name = "PlayableNecromancer"
    necromancer_sprite.texture = tex
    necromancer_sprite.centered = true
    necromancer_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    necromancer_sprite.scale = Vector2.ONE * necromancer_scale
    necromancer_sprite.position = Vector2(0, -35)
    add_child(necromancer_sprite)

func _refresh_character_appearance() -> void:
    var necromancer_active: bool = necromancer_sprite != null and race == "Human" and necromancer_appearance_enabled
    if necromancer_sprite != null:
        necromancer_sprite.visible = necromancer_active
    var race_texture: Texture2D = RACE_ART.get(race)
    race_sprite.texture = race_texture
    race_sprite.visible = not necromancer_active and race_texture != null
    if race_sprite.visible:
        var height := character_art_height
        race_sprite.scale = Vector2.ONE * (height / race_texture.get_height())
        race_sprite.position = Vector2(0, RACE_ART_FEET_Y - height / 2.0)
        race_sprite.flip_h = facing.x < 0.0
    if animated_sprite != null:
        animated_sprite.visible = not necromancer_active and not race_sprite.visible
    queue_redraw()

func _animate_race_art(moving: bool) -> void:
    if not race_sprite.visible:
        return
    var bob := absf(sin(stride)) * 2.0 if moving else 0.0
    var height := race_sprite.texture.get_height() * race_sprite.scale.y
    race_sprite.position.y = RACE_ART_FEET_Y - height / 2.0 - bob
    if moving and absf(facing.x) > 0.15:
        race_sprite.flip_h = facing.x < 0.0

func _animate_necromancer(delta: float, moving: bool) -> void:
    if necromancer_sprite == null or not necromancer_sprite.visible:
        return
    necromancer_idle_clock += delta
    # A subtle living idle and step motion, not a fabricated directional sprite sheet.
    var motion: float = sin(stride) * 2.1 if moving else sin(necromancer_idle_clock * 2.1) * 0.75
    necromancer_sprite.position = Vector2(0, -35 + motion)
    necromancer_sprite.rotation = sin(stride) * 0.012 if moving else 0.0
    necromancer_sprite.scale = Vector2.ONE * necromancer_scale
    if moving and absf(facing.x) > 0.15:
        necromancer_sprite.flip_h = facing.x < 0.0

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N and not choosing_race:
        necromancer_appearance_enabled = not necromancer_appearance_enabled
        _refresh_character_appearance()
        get_viewport().set_input_as_handled()

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
    note.text = "Press N to switch between Human and necromancer artwork."
    note.visible = necromancer_sprite != null
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 12)
    column.add_child(note)

func _choose_race(chosen: String) -> void:
    race = chosen
    choosing_race = false
    selection_layer.hide()
    _refresh_character_appearance()

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
    var moving: bool = input_vector.length_squared() > 0.0
    var running: bool = moving and Input.is_key_pressed(KEY_SHIFT)
    velocity = input_vector.normalized() * SPEED * (RUN_MULTIPLIER if running else 1.0)
    if input_vector.length_squared() > 0.0:
        facing = input_vector.normalized()
        stride += delta * 10.0
    move_and_slide()
    if animated_sprite != null and animated_sprite.visible:
        _advance_animation(delta, moving, running)
    _animate_race_art(moving)
    _animate_necromancer(delta, moving)
    queue_redraw()

func _draw() -> void:
    if race_sprite != null and race_sprite.visible:
        draw_circle(Vector2(0, RACE_ART_FEET_Y - 2.0), 12.0, Color(0, 0, 0, 0.3))
        if equipped_weapon == "rusty_sword":
            var hand_side := -1.0 if race_sprite.flip_h else 1.0
            var height := race_sprite.texture.get_height() * race_sprite.scale.y
            var size_ratio := height / SWORD_ART_REFERENCE_HEIGHT
            var feet := race_sprite.position + Vector2(0, height / 2.0)
            var hand := feet + Vector2(12.0 * hand_side, -15.0) * size_ratio
            draw_line(hand, hand + Vector2(7.0 * hand_side, -25.0) * size_ratio, Color("#c1c6c6"), 3.0)
            draw_line(hand + Vector2(-4, -1) * size_ratio, hand + Vector2(4, 1) * size_ratio, Color("#7a5637"), 2.0)
        return
    if (animated_sprite != null and animated_sprite.visible) or (necromancer_sprite != null and necromancer_sprite.visible):
        return
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
