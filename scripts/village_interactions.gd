extends CanvasLayer
## Frontier village interactions: NPCs, inn interior, dialogue, and starter inventory.
const INTERACT_DISTANCE := 115.0
const BACKPACK_CAPACITY := 24
@export var inventory_only := false
var player: CharacterBody2D
var ui: PanelContainer
var message: Label
var inventory_panel: PanelContainer
var notice_timer: Timer
var inventory_grid: GridContainer
var equipment_grid: GridContainer
var gold_label: Label
var item_details: Label
var equipment: Dictionary = {"weapon": "", "armor": "cloak", "accessory": ""}
var backpack: Array[String] = ["rusty_sword", "old_map", "bread", "healing_potion"]
var item_data: Dictionary = {
    "rusty_sword": {"name": "Worn Iron Sword", "kind": "weapon", "icon": "⚔", "rarity": "Common", "description": "A battered but reliable blade.", "attack": 3},
    "cloak": {"name": "Traveler\u0027s Cloak", "kind": "armor", "icon": "◈", "rarity": "Common", "description": "A weathered cloak for the long road.", "defense": 1},
    "old_map": {"name": "Old Frontier Map", "kind": "quest", "icon": "▤", "rarity": "Uncommon", "description": "A faded map marking the old forest trails."},
    "bread": {"name": "Bread x2", "kind": "consumable", "icon": "●", "rarity": "Common", "description": "Simple provisions for a journey."},
    "healing_potion": {"name": "Minor Healing Potion", "kind": "consumable", "icon": "◆", "rarity": "Uncommon", "description": "A crimson restorative draught."}
}
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
    if not inventory_only:
        _make_interface()
    _make_inventory_window()
    if player.has_method("set_equipment"):
        player.set_equipment(equipment)
    if inventory_only:
        return
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
    ui.position = Vector2(22, 568)
    ui.custom_minimum_size = Vector2(410, 0)
    holder.add_child(ui)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.075, 0.09, 0.09, 0.95)
    style.border_color = Color("#9a774b")
    style.set_border_width_all(2)
    style.set_corner_radius_all(6)
    style.set_content_margin_all(12)
    ui.add_theme_stylebox_override("panel", style)
    message = Label.new()
    message.custom_minimum_size = Vector2(382, 0)
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.add_theme_font_size_override("font_size", 15)
    message.add_theme_color_override("font_color", Color("#f4e8ce"))
    ui.add_child(message)
    ui.hide()
    notice_timer = Timer.new()
    notice_timer.one_shot = true
    notice_timer.timeout.connect(_on_notice_timeout)
    add_child(notice_timer)

func _make_inventory_window() -> void:
    inventory_panel = PanelContainer.new()
    inventory_panel.position = Vector2(220, 65)
    inventory_panel.custom_minimum_size = Vector2(835, 0)
    inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(inventory_panel)
    var frame := StyleBoxFlat.new()
    frame.bg_color = Color("#171b1b")
    frame.border_color = Color("#b18b51")
    frame.set_border_width_all(3)
    frame.set_corner_radius_all(8)
    frame.set_content_margin_all(18)
    inventory_panel.add_theme_stylebox_override("panel", frame)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 9)
    inventory_panel.add_child(layout)
    var top := HBoxContainer.new()
    layout.add_child(top)
    var heading := Label.new()
    heading.text = "ELDERWOOD  /  THE ADVENTURER"
    heading.add_theme_font_size_override("font_size", 22)
    heading.add_theme_color_override("font_color", Color("#e7c589"))
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(heading)
    gold_label = Label.new()
    gold_label.add_theme_color_override("font_color", Color("#e7c589"))
    top.add_child(gold_label)
    var rule := HSeparator.new()
    layout.add_child(rule)
    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation", 22)
    layout.add_child(columns)
    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(330, 0)
    left.add_theme_constant_override("separation", 9)
    columns.add_child(left)
    var equipment_title := Label.new()
    equipment_title.text = "EQUIPMENT  /  WANDERER"
    equipment_title.add_theme_color_override("font_color", Color("#dfc08a"))
    left.add_child(equipment_title)
    var character_info := Label.new()
    character_info.text = "LEVEL 1   /   FRONTIER WANDERER"
    character_info.add_theme_font_size_override("font_size", 12)
    character_info.add_theme_color_override("font_color", Color("#a99b84"))
    left.add_child(character_info)
    var equipment_hint := Label.new()
    equipment_hint.text = "EQUIPPED GEAR"
    equipment_hint.add_theme_font_size_override("font_size", 13)
    equipment_hint.add_theme_color_override("font_color", Color("#e7c589"))
    left.add_child(equipment_hint)
    equipment_grid = GridContainer.new()
    equipment_grid.columns = 1
    equipment_grid.add_theme_constant_override("v_separation", 9)
    left.add_child(equipment_grid)
    var preview_note := Label.new()
    preview_note.text = "Character preview unlocks with animated sprites."
    preview_note.add_theme_font_size_override("font_size", 12)
    preview_note.add_theme_color_override("font_color", Color("#998d79"))
    left.add_child(preview_note)
    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(420, 0)
    right.add_theme_constant_override("separation", 9)
    columns.add_child(right)
    var bag_title := Label.new()
    bag_title.text = "BACKPACK  /  24 SLOTS"
    bag_title.add_theme_color_override("font_color", Color("#dfc08a"))
    right.add_child(bag_title)
    inventory_grid = GridContainer.new()
    inventory_grid.columns = 6
    inventory_grid.add_theme_constant_override("h_separation", 5)
    inventory_grid.add_theme_constant_override("v_separation", 5)
    right.add_child(inventory_grid)
    var details_frame := PanelContainer.new()
    details_frame.custom_minimum_size = Vector2(420, 106)
    details_frame.add_theme_stylebox_override("panel", _slot_style())
    right.add_child(details_frame)
    item_details = Label.new()
    item_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    item_details.add_theme_color_override("font_color", Color("#e6d4b0"))
    details_frame.add_child(item_details)
    var footer := Label.new()
    footer.text = "CLICK AN ITEM TO INSPECT / EQUIP   •   I OR ESC TO CLOSE"
    footer.add_theme_font_size_override("font_size", 13)
    footer.add_theme_color_override("font_color", Color("#ad9c80"))
    layout.add_child(footer)
    _refresh_inventory()
    inventory_panel.hide()

func _slot_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#292d2b")
    style.border_color = Color("#64533b")
    style.set_border_width_all(1)
    style.set_corner_radius_all(3)
    style.set_content_margin_all(5)
    return style

func _refresh_inventory() -> void:
    gold_label.text = "%d GOLD" % gold
    for child in equipment_grid.get_children():
        equipment_grid.remove_child(child)
        child.queue_free()
    for kind in ["weapon", "armor", "accessory"]:
        var item_id: String = equipment[kind]
        var button := Button.new()
        button.custom_minimum_size = Vector2(320, 84)
        button.add_theme_stylebox_override("normal", _slot_style())
        button.add_theme_font_size_override("font_size", 16)
        button.add_theme_color_override("font_color", Color("#e7d2a7"))
        var slot_label := "EMPTY SLOT" if item_id == "" else str(item_data[item_id]["icon"]) + "  " + str(item_data[item_id]["name"])
        button.text = kind.to_upper() + "     /     " + slot_label
        button.clip_text = true
        button.pressed.connect(_unequip.bind(kind))
        equipment_grid.add_child(button)
    for child in inventory_grid.get_children():
        inventory_grid.remove_child(child)
        child.queue_free()
    for i in range(BACKPACK_CAPACITY):
        var button := Button.new()
        button.custom_minimum_size = Vector2(63, 61)
        button.add_theme_stylebox_override("normal", _slot_style())
        button.add_theme_font_size_override("font_size", 22)
        if i < backpack.size():
            var item_id: String = backpack[i]
            button.text = str(item_data[item_id]["icon"])
            button.tooltip_text = str(item_data[item_id]["name"])
            button.pressed.connect(_select_item.bind(item_id))
        inventory_grid.add_child(button)
    item_details.text = "SELECT AN ITEM\nInspect its properties and equip weapons or armor."

func grant_item(item_id: String, definition: Dictionary) -> bool:
    if item_id in backpack:
        return true
    if backpack.size() >= BACKPACK_CAPACITY:
        return false
    item_data[item_id] = definition
    backpack.append(item_id)
    _refresh_inventory()
    return true

func remove_item(item_id: String) -> void:
    if item_id in backpack:
        backpack.erase(item_id)
        _refresh_inventory()

func _select_item(item_id: String) -> void:
    var data: Dictionary = item_data[item_id]
    var stats := ""
    if data.has("attack"):
        stats = "  |  ATTACK +%d" % int(data["attack"])
    if data.has("defense"):
        stats = "  |  DEFENSE +%d" % int(data["defense"])
    item_details.text = "%s  [%s]%s\n%s" % [data["name"], data["rarity"], stats, data["description"]]
    var kind: String = data["kind"]
    if kind in ["weapon", "armor", "accessory"]:
        _equip(item_id, kind)

func _equip(item_id: String, kind: String) -> void:
    var old_id: String = equipment[kind]
    equipment[kind] = item_id
    backpack.erase(item_id)
    if old_id != "":
        backpack.append(old_id)
    if player.has_method("set_equipment"):
        player.set_equipment(equipment)
    _refresh_inventory()
    item_details.text = "EQUIPPED: %s\n%s" % [item_data[item_id]["name"], item_data[item_id]["description"]]

func _unequip(kind: String) -> void:
    var item_id: String = equipment[kind]
    if item_id == "" or backpack.size() >= BACKPACK_CAPACITY:
        return
    equipment[kind] = ""
    backpack.append(item_id)
    if player.has_method("set_equipment"):
        player.set_equipment(equipment)
    _refresh_inventory()
    item_details.text = "UNEQUIPPED: %s" % item_data[item_id]["name"]

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
    get_parent().call_deferred("add_child", interior)

func _process(_delta: float) -> void:
    if player == null or inventory_only:
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
    if inventory_only:
        if player == null or player.choosing_race:
            return
        if event.keycode == KEY_I or (inventory_open and event.keycode == KEY_ESCAPE):
            inventory_open = not inventory_open
            inventory_panel.visible = inventory_open
            get_viewport().set_input_as_handled()
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
