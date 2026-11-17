extends CanvasLayer
## Frontier village interactions: NPCs, inn interior, dialogue, and starter inventory.
const INTERACT_DISTANCE := 115.0
var player: CharacterBody2D
var ui: PanelContainer
var message: Label
var inventory_panel: PanelContainer
var notice_timer: Timer
var prompt: Label
var inventory_open := false
var inside_inn := false
var conversation_open := false
var gold := 25
var items := ["Traveler's Cloak", "Old Map", "Bread x2"]
var people := [
    {"name": "Mara", "role": "Innkeeper", "pos": Vector2(-285, -165), "words": "Welcome to the Wayfarer Inn! Travelers are always welcome. Come inside and rest by the hearth."},
    {"name": "Elden", "role": "Village Elder", "pos": Vector2(315, -165), "words": "Our little frontier settlement is growing. The roads beyond the woods are not always safe."},
    {"name": "Pip", "role": "Merchant", "pos": Vector2(290, 20), "words": "Fresh supplies! The wilderness rewards those who come prepared."},
    {"name": "Rowan", "role": "Villager", "pos": Vector2(-360, 250), "words": "The forest is beautiful, but I wouldn't wander too far after dusk."}
]
var interior: Node2D
var return_position := Vector2.ZERO
var previous_camera_zoom := Vector2.ONE

func _ready() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody2D
    if player == null:
        return
    _make_interface()
    _make_inventory_window()
    _make_interior()
    _make_villagers()
    _show_message("Welcome to Elderwood Village. WASD to move, E to interact, I for inventory.", 5.0)

func _make_interface() -> void:
    var holder := Control.new()
    holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(holder)
    prompt = Label.new()
    prompt.position = Vector2(24, 18)
    prompt.add_theme_font_size_override("font_size", 18)
    prompt.add_theme_color_override("font_color", Color("#ffe5ad"))
    holder.add_child(prompt)
    ui = PanelContainer.new()
    ui.position = Vector2(22, 615)
    ui.custom_minimum_size = Vector2(0, 0)
    holder.add_child(ui)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.075, 0.09, 0.09, 0.93)
    style.border_color = Color("#9a774b")
    style.set_border_width_all(2)
    style.set_content_margin_all(14)
    ui.add_theme_stylebox_override("panel", style)
    message = Label.new()
    message.custom_minimum_size = Vector2(0, 0)
    message.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.add_theme_font_size_override("font_size", 17)
    message.add_theme_color_override("font_color", Color("#f4e8ce"))
    ui.add_child(message)
    ui.hide()
    notice_timer = Timer.new()
    notice_timer.one_shot = true
    notice_timer.timeout.connect(_on_notice_timeout)
    add_child(notice_timer)

func _make_inventory_window() -> void:
    inventory_panel = PanelContainer.new()
    inventory_panel.position = Vector2(365, 95)
    inventory_panel.custom_minimum_size = Vector2(550, 515)
    add_child(inventory_panel)
    var frame := StyleBoxFlat.new()
    frame.bg_color = Color("#171b1b")
    frame.border_color = Color("#a8854c")
    frame.set_border_width_all(3)
    frame.set_corner_radius_all(8)
    frame.set_content_margin_all(18)
    inventory_panel.add_theme_stylebox_override("panel", frame)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 12)
    inventory_panel.add_child(layout)
    var heading := Label.new()
    heading.text = "✦  ADVENTURER INVENTORY"
    heading.add_theme_font_size_override("font_size", 23)
    heading.add_theme_color_override("font_color", Color("#e7c589"))
    layout.add_child(heading)
    var subtitle := Label.new()
    subtitle.text = "EQUIPMENT                                     %d GOLD" % gold
    subtitle.add_theme_font_size_override("font_size", 16)
    subtitle.add_theme_color_override("font_color", Color("#cbbda1"))
    layout.add_child(subtitle)
    var equipment := HBoxContainer.new()
    equipment.add_theme_constant_override("separation", 10)
    layout.add_child(equipment)
    for entry in ["WEAPON\\nEmpty", "ARMOR\\nTraveler\u0027s Cloak", "ACCESSORY\\nEmpty"]:
        var equip := Label.new()
        equip.text = entry.replace("\\n", "\n")
        equip.custom_minimum_size = Vector2(155, 65)
        equip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        equip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        equip.add_theme_stylebox_override("normal", _slot_style())
        equip.add_theme_color_override("font_color", Color("#dfd3b7"))
        equipment.add_child(equip)
    var bag_title := Label.new()
    bag_title.text = "BACKPACK  •  24 SLOTS"
    bag_title.add_theme_color_override("font_color", Color("#e7c589"))
    layout.add_child(bag_title)
    var grid := GridContainer.new()
    grid.columns = 6
    grid.add_theme_constant_override("h_separation", 7)
    grid.add_theme_constant_override("v_separation", 7)
    layout.add_child(grid)
    for i in range(24):
        var slot := PanelContainer.new()
        slot.custom_minimum_size = Vector2(77, 66)
        slot.add_theme_stylebox_override("panel", _slot_style())
        grid.add_child(slot)
        var label := Label.new()
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.add_theme_font_size_override("font_size", 12)
        label.add_theme_color_override("font_color", Color("#e7d7b7"))
        if i == 0:
            label.text = "🗺\\nOld Map".replace("\\n", "\n")
        elif i == 1:
            label.text = "🍞\\nBread ×2".replace("\\n", "\n")
        slot.add_child(label)
    var footer := Label.new()
    footer.text = "I / ESC  CLOSE     •     More equipment and loot coming soon"
    footer.add_theme_color_override("font_color", Color("#aa9b82"))
    layout.add_child(footer)
    inventory_panel.hide()

func _slot_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#292d2b")
    style.border_color = Color("#64533b")
    style.set_border_width_all(1)
    style.set_corner_radius_all(3)
    return style

func _on_notice_timeout() -> void:
    ui.hide()
    conversation_open = false

func _make_villagers() -> void:
    for person in people:
        var npc := Node2D.new()
        npc.name = str(person["name"])
        npc.position = person["pos"]
        npc.z_index = 8
        npc.set_script(load("res://scripts/village_npc.gd"))
        get_parent().call_deferred("add_child", npc)

func _make_interior() -> void:
    interior = Node2D.new()
    interior.name = "InnInterior"
    interior.position = Vector2(4200, 0)
    interior.z_index = 0
    interior.set_script(load("res://scripts/inn_interior.gd"))
    get_parent().add_child(interior)

func _process(_delta: float) -> void:
    if player == null:
        return
    if inventory_open:
        prompt.text = "Inventory open — press I to close"
    elif conversation_open:
        prompt.text = "Press E or Esc to close dialogue"
    elif inside_inn:
        prompt.text = "Wayfarer Inn — E near the doorway to leave | I inventory"
    else:
        var nearby := _nearest_person()
        if player.position.distance_to(Vector2(-390, -190)) < 105.0:
            prompt.text = "E — Enter the Wayfarer Inn | I inventory"
        elif nearby >= 0:
            prompt.text = "E — Talk to %s (%s) | I inventory" % [people[nearby]["name"], people[nearby]["role"]]
        elif player.position.distance_to(Vector2(-390, -190)) < 155.0:
            prompt.text = "E — Enter the Wayfarer Inn | I inventory"
        else:
            prompt.text = "WASD move | E interact | I inventory"

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_I:
        inventory_open = not inventory_open
        conversation_open = false
        if inventory_open:
            notice_timer.stop()
            ui.hide()
            inventory_panel.show()
        else:
            inventory_panel.hide()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_ESCAPE and (conversation_open or inventory_open):
        conversation_open = false
        inventory_open = false
        ui.hide()
        inventory_panel.hide()
        notice_timer.stop()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_E:
        if inventory_open:
            inventory_open = false
            inventory_panel.hide()
        elif conversation_open:
            conversation_open = false
            ui.hide()
        elif inside_inn:
            if player.position.distance_to(Vector2(4200, 120)) < 190.0:
                _leave_inn()
            else:
                conversation_open = true
                _show_message("Mara: Make yourself at home. The fire is warm and the road can wait.", 0.0)
        else:
            var nearest := _nearest_person()
            if player.position.distance_to(Vector2(-390, -190)) < 105.0:
                _enter_inn()
            elif nearest >= 0:
                conversation_open = true
                _show_message("%s — %s:\n%s\n\n[E] Continue" % [people[nearest]["name"], people[nearest]["role"], people[nearest]["words"]], 0.0)
            elif player.position.distance_to(Vector2(-390, -190)) < 155.0:
                _enter_inn()
        get_viewport().set_input_as_handled()

func _nearest_person() -> int:
    if inside_inn:
        return -1
    var best := -1
    var distance := INTERACT_DISTANCE
    for i in range(people.size()):
        var d: float = player.position.distance_to(people[i]["pos"])
        if d < distance:
            distance = d
            best = i
    return best

func _enter_inn() -> void:
    inside_inn = true
    return_position = player.position
    player.position = Vector2(4200, 20)
    _show_message("The Wayfarer Inn — a warm refuge on the frontier. Walk south to the doorway and press E to leave.", 5.0)

func _leave_inn() -> void:
    inside_inn = false
    player.position = Vector2(-390, -140)
    _show_message("You step back into Elderwood Village.", 3.0)

func _show_inventory() -> void:
    _show_message("INVENTORY   •   %d gold\n\nEquipment: Traveler's Cloak\n%s\n\n[I] Close" % [gold, "\n".join(items)], 0.0)

func _show_message(value: String, _seconds: float) -> void:
    if inventory_open:
        return
    message.text = value
    ui.show()
    notice_timer.start(5.0)
