extends CanvasLayer
## Frontier village interactions: NPCs, inn interior, dialogue, and starter inventory.
const INTERACT_DISTANCE := 115.0
const PinewoodForest := preload("res://scripts/pinewood_forest.gd")
const PINEWOOD_ENTRY_DISTANCE := 75.0
const ROAD_REWARD := 20
enum RoadQuest { OFFERED, ACTIVE, COMPLETE }

const VillageNPC := preload("res://scripts/village_npc.gd")
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
var forest: PinewoodForest
var road_quest := RoadQuest.OFFERED

var inventory_open := false
var inside_inn := false
var conversation_open := false
var gold := 25
var items := ["Traveler's Cloak", "Old Map", "Bread x2"]
var people := [
    {"name": "Mara", "role": "Innkeeper", "pos": Vector2(-285, -165),
        "route": [Vector2(-240, -107), Vector2(-330, -115)], "wait": 2.5, "speed": 39.0,
        "words": "Welcome to the Wayfarer Inn! Travelers are always welcome. Come inside and rest by the hearth."},
    {"name": "Elden", "role": "Village Elder", "pos": Vector2(315, -165),
        "route": [Vector2(247, -150), Vector2(215, -92)], "wait": 5.0, "speed": 31.0,
        "words": "Our little frontier settlement is growing. The roads beyond the woods are not always safe."},
    {"name": "Pip", "role": "Merchant", "pos": Vector2(290, 30),
        "route": [Vector2(347, 30), Vector2(221, 35)], "wait": 1.0, "speed": 44.0,
        "words": "Fresh supplies! The wilderness rewards those who come prepared."},
    {"name": "Rowan", "role": "Villager", "pos": Vector2(-360, 250),
        "route": [Vector2(-285, 173), Vector2(-141, 83), Vector2(-245, 104)],
        "wait": 3.5, "speed": 53.0,
        "words": "The forest is beautiful, but I wouldn't wander too far after dusk."}
]
var villagers: Array[VillageNPC] = []
var speaker: VillageNPC
var interior: Node2D
var return_position := Vector2.ZERO
var previous_camera_zoom := Vector2.ONE

func _ready() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody2D
    if player == null:
        return
    _make_interface()
    _make_inventory_window()
    if player.has_method("set_equipment"):
        player.set_equipment(equipment)
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
    for i in range(24):
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
    if item_id == "" or backpack.size() >= 24:
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
        var npc := VillageNPC.new()
        npc.name = str(person["name"])
        npc.position = person["pos"]
        npc.z_index = 8
        npc.artwork_height = player.character_art_height
        npc.player = player
        npc.route = PackedVector2Array(person["route"])
        npc.route.append(npc.position)
        npc.pause_time = person["wait"]
        npc.walk_speed = person["speed"]
        villagers.append(npc)
        get_parent().call_deferred("add_child", npc)

func _make_interior() -> void:
    interior = Node2D.new()
    interior.name = "InnInterior"
    interior.position = Vector2(4200, 0)
    interior.z_index = 0
    interior.set_script(load("res://scripts/inn_interior.gd"))
    # The parent is still assembling its scene tree during _ready().
    get_parent().call_deferred("add_child", interior)

func _process(_delta: float) -> void:
    if player == null:
        return
    if is_instance_valid(speaker) and not conversation_open:
        speaker.talking = false
        speaker = null
    var in_forest := is_instance_valid(forest) and forest.active
    if in_forest:
        forest.combat_paused = inventory_open or conversation_open
        forest.armor = player.defense_bonus

    if inventory_open:
        prompt.text = "Inventory open — press I to close"
    elif conversation_open:
        prompt.text = "Press E or Esc to close dialogue"
    elif in_forest:
        prompt.text = _pinewood_prompt()
    elif inside_inn:
        prompt.text = "Wayfarer Inn — E near the doorway to leave | I inventory"
    else:
        var nearby := _nearest_person()
        if _near_pinewood_entrance():
            prompt.text = "E — Follow the road into Pinewood Forest | I inventory"
        elif player.position.distance_to(Vector2(-390, -190)) < 105.0:
            prompt.text = "E — Enter the Wayfarer Inn | I inventory"
        elif nearby >= 0:
            prompt.text = "E — Talk to %s (%s) | I inventory" % [people[nearby]["name"], people[nearby]["role"]]
        elif player.position.distance_to(Vector2(-390, -190)) < 155.0:
            prompt.text = "E — Enter the Wayfarer Inn | I inventory"
        else:
            prompt.text = "WASD move | E interact | I inventory"

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventMouseButton or not event.pressed:
        return
    if event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
        return
    if not is_instance_valid(forest) or not forest.active or inventory_open or conversation_open:
        return
    var cursor: Vector2 = forest.get_global_transform_with_canvas().affine_inverse() * event.position
    var melee: bool = event.button_index == MOUSE_BUTTON_LEFT
    _pinewood_combat_input(melee, forest.cursor_aim(cursor, melee), cursor)
    get_viewport().set_input_as_handled()

func _pinewood_combat_input(melee: bool, aim: Vector2, cursor := Vector2.INF) -> void:
    if melee:
        forest.attack(2 + player.attack_bonus, aim, cursor == Vector2.INF)
    elif not forest.cast_fireball(aim, cursor) and not forest.in_stonehaven() and forest.mana < PinewoodForest.FIREBALL_COST:
        _show_message("Not enough mana. Give it a moment to recover.", 3.0)

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
    elif event.keycode in [KEY_SPACE, KEY_F] and is_instance_valid(forest) and forest.active:
        if not inventory_open and not conversation_open:
            _pinewood_combat_input(event.keycode == KEY_SPACE, player.facing)
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_E:
        if inventory_open:
            inventory_open = false
            inventory_panel.hide()
        elif conversation_open:
            conversation_open = false
            ui.hide()
        elif is_instance_valid(forest) and forest.active:
            if _near_forest_exit():
                _leave_pinewood()
        elif inside_inn:
            if player.position.distance_to(Vector2(4200, 120)) < 190.0:
                _leave_inn()
            else:
                conversation_open = true
                _show_message("Mara: Make yourself at home. The fire is warm and the road can wait.", 0.0)
        else:
            var nearest := _nearest_person()
            if _near_pinewood_entrance() and not player.choosing_race:
                _enter_pinewood()
            elif player.position.distance_to(Vector2(-390, -190)) < 105.0:
                _enter_inn()
            elif nearest >= 0:
                speaker = villagers[nearest]
                speaker.talking = true
                conversation_open = true
                var words: String = people[nearest]["words"]
                var road_dialogue := speaker.name == &"Pip" and road_quest != RoadQuest.COMPLETE
                if road_dialogue:
                    words = _pip_road_dialogue()
                _show_message("%s — %s:\n%s\n\n[E] Continue" % [people[nearest]["name"], people[nearest]["role"], words], 0.0)
                if road_dialogue:
                    notice_timer.stop()
            elif player.position.distance_to(Vector2(-390, -190)) < 155.0:
                _enter_inn()
        get_viewport().set_input_as_handled()

func _pip_road_dialogue() -> String:
    var remaining := forest.wolves.size() if is_instance_valid(forest) else 2
    if remaining == 0:
        road_quest = RoadQuest.COMPLETE
        gold += ROAD_REWARD
        _refresh_inventory()
        return "The road is open again. Here’s %d gold for your trouble. Follow the road north to Stonehaven." % ROAD_REWARD
    if road_quest == RoadQuest.OFFERED:
        road_quest = RoadQuest.ACTIVE
        return "Two briar wolves have been stalking the Stonehaven road. Take the north trail into Pinewood Forest. One wolf is in the clearing where the road forks. The other is farther north along the main road. Clear them out and come see me.\n\nQuest started — Clear the Pinewood Road"
    return "%d briar %s still on the Pinewood road. I’ll be here when the road is clear." % [
        remaining, "wolf is" if remaining == 1 else "wolves are"
    ]

func _near_pinewood_entrance() -> bool:
    return player.position.distance_to(PinewoodForest.VILLAGE_ENTRANCE) < PINEWOOD_ENTRY_DISTANCE

func _near_forest_exit() -> bool:
    return forest.to_local(player.global_position).distance_to(PinewoodForest.SOUTH_EXIT) < 79.0

func _enter_pinewood() -> void:
    if not is_instance_valid(forest):
        forest = PinewoodForest.new()
        forest.name = "PinewoodForest"
        forest.position = Vector2(7800, 0)
        forest.player = player
        forest.player_fell.connect(_on_pinewood_fall)
        forest.wolf_defeated.connect(_on_wolf_defeated)
        get_parent().add_child(forest)
    forest.show()
    forest.active = true
    forest.recover_at_trailhead()
    _show_message("Pinewood Forest. Follow the road north to Stonehaven. Left click to swing. Right click to cast Fireball.", 5.0)

func _leave_pinewood() -> void:
    forest.active = false
    forest.clear_fireballs()
    forest.hide()
    player.position = PinewoodForest.VILLAGE_ENTRANCE + Vector2(0, 49)
    player.get_node("Camera2D").reset_smoothing()
    _show_message("You return to Elderwood Village.", 3.0)

func _on_pinewood_fall() -> void:
    _show_message("You recover at the trailhead. Defeated wolves stay down.", 5.0)

func _on_wolf_defeated() -> void:
    if road_quest == RoadQuest.ACTIVE and forest.wolves.is_empty():
        _show_message("Clear the Pinewood Road — return to Pip for your reward.", 5.0)
    else:
        _show_message("Briar wolf defeated.", 3.0)

func _pinewood_prompt() -> String:
    if forest.in_stonehaven():
        return "Stonehaven Gate | Follow the road south to Pinewood"
    var status := "%d/%d HP | %d/%d mana | LMB swing | RMB Fireball | I inventory" % [
        forest.health, PinewoodForest.MAX_HEALTH, int(forest.mana), int(PinewoodForest.MAX_MANA)
    ]
    if _near_forest_exit():
        return "E — Return to Elderwood Village | " + status
    if road_quest == RoadQuest.ACTIVE:
        if forest.wolves.is_empty():
            return "Return to Pip | " + status
        return "Clear the Pinewood Road (%d/2) | %s" % [2 - forest.wolves.size(), status]
    return "Pinewood Forest | " + status

func _nearest_person() -> int:
    if inside_inn:
        return -1
    var best := -1
    var distance := INTERACT_DISTANCE
    for i in range(villagers.size()):
        var d := player.position.distance_to(villagers[i].position)
        if d < distance:
            distance = d
            best = i
    return best

func _enter_inn() -> void:
    inside_inn = true
    return_position = player.position
    player.position = Vector2(4200, 105)
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
