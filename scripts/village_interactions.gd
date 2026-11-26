extends CanvasLayer
## Frontier village interactions: NPCs, inn interior, dialogue, and starter inventory.
@export var inventory_only := false

const PanelHeader := preload("res://scripts/panel_header.gd")
const AreaTransition := preload("res://scripts/area_transition.gd")
const BACKPACK_CAPACITY := 24
const INTERACT_DISTANCE := 115.0
const FORSAKEN_CHAPTER := "res://scenes/frontier/forsaken_chapter.tscn"
const PINEWOOD_SCRIPT := "res://scripts/pinewood_forest.gd"
const PINEWOOD_ENTRANCE := Vector2(4, -670)
const PINEWOOD_APPROACH_DISTANCE := 440.0
const PINEWOOD_RELEASE_DISTANCE := 580.0
const PINEWOOD_MAX_HEALTH := 14
const PINEWOOD_MAX_MANA := 6.0
const PINEWOOD_ENTRY_DISTANCE := 175.0
const ROAD_REWARD := 35
const RITE_WOLF_COUNT := 4
enum RoadQuest { OFFERED, ACTIVE, COMPLETE }

const VillageNPC := preload("res://scripts/village_npc.gd")
var player: CharacterBody2D
var ui: PanelContainer
var message: Label
var quest_offer: CenterContainer
var accept_quest: Button
var quest_title: Label
var quest_details: Label
var decline_quest: Button
var turning_in_quest := false
var health_bar: ProgressBar
var mana_bar: ProgressBar
var health_text: Label
var mana_text: Label
var travel_button: Button
var offered_route: Dictionary = {}
const InventorySlot := preload("res://scripts/inventory_slot.gd")
const InventoryPortrait := preload("res://scripts/inventory_portrait.gd")
var inventory_portrait: InventoryPortrait
var inventory_stats: Label
var item_action: Button
var inspected_item := ""
var inventory_panel: PanelContainer
var pinewood_script: GDScript
var notice_timer: Timer
var inventory_grid: GridContainer
var equipment_grid: GridContainer
var gold_label: Label
var item_details: Label
var equipment: Dictionary = {"weapon": "rusty_sword", "armor": "cloak", "accessory": ""}
var backpack: Array[String] = ["old_map", "bread", "healing_potion"]
var item_data: Dictionary = {
    "rusty_sword": {"name": "Worn Iron Sword", "kind": "weapon", "icon": "⚔", "rarity": "Common", "description": "A battered but reliable blade.", "attack": 3},
    "cloak": {"name": "Traveler\u0027s Cloak", "kind": "armor", "icon": "◈", "rarity": "Common", "description": "A weathered cloak for the long road.", "defense": 1},
    "old_map": {"name": "Old Frontier Map", "kind": "quest", "icon": "▤", "rarity": "Uncommon", "description": "A faded map marking the old forest trails."},
    "bread": {"name": "Bread x2", "kind": "consumable", "icon": "●", "rarity": "Common", "description": "Simple provisions for a journey."},
    "healing_potion": {"name": "Minor Healing Potion", "kind": "consumable", "icon": "◆", "rarity": "Uncommon", "description": "A crimson restorative draught."}
}
var prompt: Label
var forest: Node2D
var pinewood_requested := false
var chapter: Node2D
var gate_resources := Vector2.ZERO
var playthrough_progress := ConfigFile.new()
var defeated_wolves: Array[int] = []
var road_quest := RoadQuest.OFFERED
var opening_greeting_shown := false

var inventory_open := false
var inside_inn := false
var conversation_open := false
var gold := 25
var items := ["Traveler's Cloak", "Old Map", "Bread x2"]
var people := [
    {"name": "Mara", "role": "Innkeeper", "pos": Vector2(-285, -165),
        "route": [Vector2(-240, -107), Vector2(-330, -115)], "wait": 2.5, "speed": 39.0,
        "words": "Welcome to the Wayfarer Inn! Travelers are always welcome. Come inside and rest by the hearth."},
    {"name": "Elden", "role": "Village Elder", "pos": Vector2(40, -80),
        "route": [Vector2(40, -80), Vector2(65, -104)], "wait": 5.0, "speed": 31.0,
        "words": "You have taken your first steps into adulthood. There is much more for you to discover in Stonehaven."},
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
        player.set_equipment(equipment, item_data)
    if inventory_only:
        return
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
    holder.add_child(ui)
    ui.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    ui.offset_left = 22
    ui.offset_right = 432
    ui.offset_top = -24
    ui.offset_bottom = -24
    ui.grow_vertical = Control.GROW_DIRECTION_BEGIN
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
    _make_status_bars(holder, style)
    travel_button = Button.new()
    travel_button.focus_mode = Control.FOCUS_NONE
    travel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    travel_button.pressed.connect(_activate_offered_route)
    holder.add_child(travel_button)
    travel_button.hide()
    _make_quest_offer(holder, style)
    notice_timer = Timer.new()
    notice_timer.one_shot = true
    notice_timer.timeout.connect(_on_notice_timeout)
    add_child(notice_timer)

func _make_status_bars(holder: Control, style: StyleBoxFlat) -> void:
    var panel := PanelContainer.new()
    holder.add_child(panel)
    panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    panel.offset_left = -248
    panel.offset_right = -24
    panel.offset_top = 18
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", style)
    var bars := VBoxContainer.new()
    bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(bars)
    health_text = Label.new()
    bars.add_child(health_text)
    health_bar = _make_bar(bars, Color("#a84144"), PINEWOOD_MAX_HEALTH)
    mana_text = Label.new()
    bars.add_child(mana_text)
    mana_bar = _make_bar(bars, Color("#486dbb"), PINEWOOD_MAX_MANA)

func update_resource_bars(health: float, max_health: float, mana: float, max_mana: float) -> void:
    health_bar.max_value = max_health
    mana_bar.max_value = max_mana
    health_bar.value = health
    mana_bar.value = mana
    health_text.text = "Health   %d / %d" % [health, max_health]
    mana_text.text = "Mana     %d / %d" % [mana, max_mana]

func _make_bar(parent: Control, color: Color, maximum: float) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.max_value = maximum
    bar.step = 0
    bar.show_percentage = false
    bar.custom_minimum_size.y = 10
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    fill.set_corner_radius_all(3)
    bar.add_theme_stylebox_override("fill", fill)
    parent.add_child(bar)
    return bar

func _make_quest_offer(holder: Control, style: StyleBoxFlat) -> void:
    quest_offer = CenterContainer.new()
    holder.add_child(quest_offer)
    quest_offer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 560
    panel.add_theme_stylebox_override("panel", style)
    quest_offer.add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 14)
    panel.add_child(content)
    quest_title = Label.new()
    quest_title.add_theme_font_size_override("font_size", 26)
    quest_title.add_theme_color_override("font_color", Color("#ffe5ad"))
    PanelHeader.add_title(content, quest_title, _close_quest_offer)
    quest_details = Label.new()
    quest_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quest_details.add_theme_font_size_override("font_size", 18)
    content.add_child(quest_details)
    var actions := HBoxContainer.new()
    actions.alignment = BoxContainer.ALIGNMENT_END
    content.add_child(actions)
    decline_quest = Button.new()
    decline_quest.pressed.connect(_close_quest_offer)
    actions.add_child(decline_quest)
    accept_quest = Button.new()
    accept_quest.custom_minimum_size.y = 36
    accept_quest.pressed.connect(_confirm_road_quest)
    actions.add_child(accept_quest)
    quest_offer.hide()

func _show_quest_offer(turn_in := false) -> void:
    turning_in_quest = turn_in
    quest_title.text = "Rite of Manhood — Complete" if turn_in else "Your Fifteenth Birthday — Rite of Manhood"
    quest_details.text = ("Elden — Village Elder:\n\nYou have returned safely and protected our sheep. You have passed your rite of manhood, and I am proud of you. Take %d gold, two health potions, and two mana potions.\n\nYour next journey is to Stonehaven City. Seek out the Adventurer's Guild and register there." if turn_in else "Elden — Village Elder:\n\nHappy fifteenth birthday! We have trained you for this day. You have become a young man, proficient with the sword and skilled with magic, and now you are ready to set out on your own.\n\nFour wolves in Pinewood Forest have been threatening our sheep. Go into the forest, defeat all four, and return to me. This will be your first quest, and your rite of manhood.\n\nReward: %d gold, two health potions, and two mana potions.") % ROAD_REWARD
    accept_quest.text = "Claim reward" if turn_in else "Accept quest"
    decline_quest.text = "Later" if turn_in else "Decline"
    notice_timer.stop()
    ui.hide()
    quest_offer.show()
    accept_quest.grab_focus()

func _close_quest_offer() -> void:
    quest_offer.hide()
    conversation_open = false

func _confirm_road_quest() -> void:
    if not turning_in_quest:
        _accept_road_quest()
    elif quest_offer.visible and _road_ready_to_turn_in():
        road_quest = RoadQuest.COMPLETE
        gold += ROAD_REWARD
        gold_label.text = "%d GOLD" % gold
        grant_item("rite_health_potions", {"name": "Health Potion x2", "kind": "consumable", "icon": "◆", "rarity": "Common", "description": "Two health potions, a gift from Elder Elden.", "charges": 2})
        grant_item("rite_mana_potions", {"name": "Mana Potion x2", "kind": "consumable", "icon": "✦", "rarity": "Common", "description": "Two mana potions, a gift from Elder Elden.", "charges": 2})
        _update_pip_marker()
        _close_quest_offer()
        _show_message("Rite of Manhood completed! Received %d gold, 2 health potions and 2 mana potions. Next: Stonehaven Adventurer's Guild." % ROAD_REWARD, 7.0)

func _accept_road_quest() -> void:
    if not quest_offer.visible or road_quest != RoadQuest.OFFERED:
        return
    road_quest = RoadQuest.ACTIVE
    _update_pip_marker()
    _close_quest_offer()
    var already_clear := defeated_wolves.size() >= RITE_WOLF_COUNT
    var objective := "Return to Elder Elden for your reward." if already_clear else "Defeat four wolves threatening the village sheep in Pinewood Forest."
    _show_message("Quest accepted — Rite of Manhood\n" + objective, 5.0)

func _make_inventory_window() -> void:
    inventory_panel = PanelContainer.new()
    var inventory_center := CenterContainer.new()
    add_child(inventory_center)
    inventory_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    inventory_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inventory_panel.custom_minimum_size.x = 866
    inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    inventory_center.add_child(inventory_panel)
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
    heading.text = "Character & Inventory"
    heading.add_theme_font_size_override("font_size", 22)
    heading.add_theme_color_override("font_color", Color("#e7c589"))
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(heading)
    gold_label = Label.new()
    gold_label.add_theme_color_override("font_color", Color("#e7c589"))
    top.add_child(gold_label)
    PanelHeader.add_close_button(top, _close_inventory)
    var rule := HSeparator.new()
    layout.add_child(rule)
    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation", 22)
    layout.add_child(columns)
    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(330, 0)
    left.add_theme_constant_override("separation", 9)
    columns.add_child(left)
    inventory_portrait = InventoryPortrait.new()
    inventory_portrait.custom_minimum_size = Vector2(330, 220)
    inventory_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    left.add_child(inventory_portrait)
    inventory_stats = Label.new()
    inventory_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inventory_stats.add_theme_color_override("font_color", Color("#dfc08a"))
    left.add_child(inventory_stats)
    equipment_grid = GridContainer.new()
    equipment_grid.columns = 3
    equipment_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    equipment_grid.add_theme_constant_override("h_separation", 18)
    equipment_grid.add_theme_constant_override("v_separation", 5)
    left.add_child(equipment_grid)
    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(420, 0)
    right.add_theme_constant_override("separation", 9)
    columns.add_child(right)
    var bag_title := Label.new()
    bag_title.text = "Backpack"
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
    item_action = Button.new()
    item_action.pressed.connect(_apply_inspected_item)
    right.add_child(item_action)
    var footer := Label.new()
    footer.text = "Select gear to compare. Press I or Esc to close."
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
    if is_instance_valid(player):
        inventory_portrait.show_character(player, equipment.get("weapon", ""))
        inventory_stats.text = "%s  ·  Attack +%d  ·  Defense +%d" % [
            player.race, player.attack_bonus, player.defense_bonus]
    var kinds := ["weapon", "armor", "accessory"]
    if equipment_grid.get_child_count() == 0:
        for kind in kinds:
            var slot := InventorySlot.new()
            slot.pressed.connect(_inspect_equipped.bind(kind))
            equipment_grid.add_child(slot)
        for kind in kinds:
            var title := Label.new()
            title.text = kind.capitalize()
            title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            title.add_theme_font_size_override("font_size", 13)
            equipment_grid.add_child(title)
    for i in range(kinds.size()):
        var kind: String = kinds[i]
        var item_id: String = equipment[kind]
        var slot := equipment_grid.get_child(i) as InventorySlot
        slot.show_item(item_id, item_data.get(item_id, {}), "Empty %s slot" % kind)
    if inventory_grid.get_child_count() == 0:
        for i in range(BACKPACK_CAPACITY):
            var button := InventorySlot.new()
            button.pressed.connect(_select_backpack_slot.bind(i))
            inventory_grid.add_child(button)
    for i in range(BACKPACK_CAPACITY):
        var button := inventory_grid.get_child(i) as InventorySlot
        var item_id := backpack[i] if i < backpack.size() else ""
        button.show_item(item_id, item_data.get(item_id, {}))
    _select_item(inspected_item)

func copy_items_from(source: CanvasLayer) -> void:
    equipment = source.equipment.duplicate()
    backpack.assign(source.backpack)
    item_data = source.item_data.duplicate(true)
    gold = source.gold
    if is_instance_valid(player):
        player.set_equipment(equipment, item_data)
        _refresh_inventory()

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

func _select_backpack_slot(index: int) -> void:
    if index < backpack.size():
        _select_item(backpack[index])

func _inspect_equipped(kind: String) -> void:
    _select_item(equipment.get(kind, ""))

func _select_item(item_id: String) -> void:
    var equipped: bool = item_id in equipment.values() and not item_id.is_empty()
    if not item_data.has(item_id) or (not equipped and item_id not in backpack):
        inspected_item = ""
        item_details.text = "Select an item to inspect it."
        item_action.hide()
        return
    inspected_item = item_id
    var data: Dictionary = item_data[item_id]
    var kind: String = data["kind"]
    item_details.text = "%s  ·  %s\n%s" % [data["name"], data["rarity"], data["description"]]
    item_action.hide()
    if kind in equipment:
        var current: Dictionary = item_data.get(equipment[kind], {})
        for stat in ["attack", "defense"]:
            if data.has(stat) or current.has(stat):
                var value := int(data.get(stat, 0))
                var change := value - int(current.get(stat, 0))
                item_details.text += "\n%s +%d" % [stat.capitalize(), value]
                if not equipped:
                    item_details.text += " (%+d vs. equipped)" % change
        item_action.text = "Unequip" if equipped else "Equip"
        item_action.show()
    elif item_id in ["rite_health_potions", "rite_mana_potions"]:
        item_action.text = "Drink potion"
        item_action.show()

func _apply_inspected_item() -> void:
    if inspected_item.is_empty():
        return
    if inspected_item in ["rite_health_potions", "rite_mana_potions"]:
        _drink_rite_potion(inspected_item)
        return
    var kind: String = item_data[inspected_item]["kind"]
    if equipment.get(kind) == inspected_item:
        if backpack.size() >= BACKPACK_CAPACITY:
            item_details.text = "Your backpack is full. Make room before unequipping this item."
            return
        _unequip(kind)
    elif inspected_item in backpack:
        _equip(inspected_item, kind)

func _drink_rite_potion(item_id: String) -> void:
    var is_health := item_id == "rite_health_potions"
    var key := "health" if is_health else "mana"
    var charges := int(item_data[item_id].get("charges", 0))
    if charges <= 0:
        return
    var restored := 0.0
    if inventory_only:
        var chapter := get_parent()
        var cap := float(chapter.call("_effective_max_health")) if is_health else 100.0
        var old := float(chapter.get(key))
        var now := minf(cap, old + (25.0 if is_health else 30.0))
        chapter.set(key, int(now) if is_health else now)
        restored = now - old
    elif is_instance_valid(forest) and forest.active:
        var maximum := float(PINEWOOD_MAX_HEALTH) if is_health else PINEWOOD_MAX_MANA
        var old := float(forest.get(key))
        var now := minf(maximum, old + (6.0 if is_health else 3.0))
        forest.set(key, int(now) if is_health else now)
        restored = now - old
    else:
        item_details.text = "Save this potion for when you need to recover during an adventure."
        return
    if restored <= 0.0:
        item_details.text = "Already at full %s." % key
        return
    charges -= 1
    if charges == 0:
        backpack.erase(item_id)
    else:
        item_data[item_id]["charges"] = charges
        item_data[item_id]["name"] = ("%s Potion x%d" % ["Health" if is_health else "Mana", charges])
    _refresh_inventory()
    item_details.text = "Restored %d %s. %d potion(s) remaining." % [int(ceilf(restored)), key, charges]

func _equip(item_id: String, kind: String) -> void:
    var old_id: String = equipment[kind]
    equipment[kind] = item_id
    backpack.erase(item_id)
    if old_id != "":
        backpack.append(old_id)
    if player.has_method("set_equipment"):
        player.set_equipment(equipment, item_data)
    _refresh_inventory()
    item_details.text = "EQUIPPED: %s\n%s" % [item_data[item_id]["name"], item_data[item_id]["description"]]

func _unequip(kind: String) -> void:
    var item_id: String = equipment[kind]
    if item_id == "" or backpack.size() >= BACKPACK_CAPACITY:
        return
    equipment[kind] = ""
    backpack.append(item_id)
    if player.has_method("set_equipment"):
        player.set_equipment(equipment, item_data)
    _refresh_inventory()
    item_details.text = "UNEQUIPPED: %s" % item_data[item_id]["name"]

func _on_notice_timeout() -> void:
    ui.hide()
    conversation_open = false

func _make_villagers() -> void:
    for person in people:
        var npc := VillageNPC.new()
        npc.name = str(person["name"])
        npc.quest_available = npc.name == &"Elden" and road_quest == RoadQuest.OFFERED
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
    interior.set("player", player)
    get_parent().add_child(interior)

func _process(_delta: float) -> void:
    if player == null or inventory_only:
        return
    _update_pinewood_loading()
    if not opening_greeting_shown and not player.choosing_race and road_quest == RoadQuest.OFFERED:
        opening_greeting_shown = true
        _show_quest_offer()
    if is_instance_valid(speaker) and not conversation_open:
        speaker.talking = false
        speaker = null
    var in_forest: bool = is_instance_valid(forest) and forest.active
    if in_forest:
        forest.combat_paused = inventory_open or conversation_open
        forest.armor = player.defense_bonus
        var gate_position: Vector2 = forest.to_local(player.global_position)
        if not forest.combat_paused and gate_position.y < -846.0 and absf(gate_position.x) < 95.0:
            _enter_stonehaven_district()

    update_resource_bars(forest.health if in_forest else PINEWOOD_MAX_HEALTH, PINEWOOD_MAX_HEALTH,
        forest.mana if in_forest else PINEWOOD_MAX_MANA, PINEWOOD_MAX_MANA)
    _update_travel_button()

    if inventory_open:
        prompt.text = "Inventory open — press I to close"
    elif quest_offer.visible:
        prompt.text = "Elden — Village Elder"
    elif conversation_open:
        prompt.text = "Press E or Esc to close dialogue"
    elif in_forest:
        prompt.text = _pinewood_prompt()
    elif inside_inn:
        prompt.text = "Wayfarer Inn — E near the doorway to leave | I inventory"
    else:
        var nearby := _nearest_person()
        if _near_pinewood_entrance():
            prompt.text = "Click the gate or press E — Pinewood Forest | I inventory"
        elif player.position.distance_to(Vector2(-390, -190)) < 105.0:
            prompt.text = "E — Enter the Wayfarer Inn | I inventory"
        elif nearby >= 0:
            prompt.text = "E — Talk to %s (%s) | I inventory" % [people[nearby]["name"], people[nearby]["role"]]
        elif player.position.distance_to(Vector2(-390, -190)) < 155.0:
            prompt.text = "E — Enter the Wayfarer Inn | I inventory"
        else:
            prompt.text = "WASD move | E interact | I inventory"

func _route(anchor: Vector2, hit: Rect2, destination: String, action: Callable) -> Dictionary:
    return {"anchor": anchor, "hit": hit, "destination": destination, "action": action}

func _nearby_route() -> Dictionary:
    if player.choosing_race or inventory_open or conversation_open:
        return {}
    if is_instance_valid(forest) and forest.active:
        if forest.in_stonehaven():
            var district_sign: Vector2 = forest.to_global(forest.STONEHAVEN_DISTRICT_SIGN)
            return _route(forest.to_global(Vector2(0, -826)),
                Rect2(forest.to_global(Vector2(-280, -988)), Vector2(560, 364)).merge(
                    Rect2(district_sign - Vector2(55, 158), Vector2(110, 167))),
                "Enter Stonehaven", _enter_stonehaven_district)
        if _near_forest_exit():
            return _route(forest.to_global(forest.SOUTH_GATE),
                Rect2(forest.to_global(forest.SOUTH_GATE - Vector2(114, 178)), Vector2(228, 178)), "Elderwood Village", _leave_pinewood)
        if forest.to_local(player.global_position).distance_to(Vector2(0, -666)) < 178.0:
            return _route(forest.to_global(Vector2(0, -624)),
                Rect2(forest.to_global(Vector2(-280, -962)), Vector2(560, 338)),
                "Enter Stonehaven", _enter_stonehaven_district)
    elif inside_inn:
        if player.position.distance_to(Vector2(4200, 120)) < 190.0:
            return _route(Vector2(4200, 205), Rect2(4125, 156, 150, 75), "Elderwood Village", _leave_inn)
    elif _near_pinewood_entrance():
        return _route(PINEWOOD_ENTRANCE, Rect2(PINEWOOD_ENTRANCE - Vector2(114, 178), Vector2(228, 178)), "Pinewood Forest", _enter_pinewood)
    elif player.position.distance_to(Vector2(-390, -190)) < 155.0:
        return _route(Vector2(-390, -145), Rect2(-443, -263, 111, 122), "Wayfarer Inn", _enter_inn)
    return {}

func _update_travel_button() -> void:
    offered_route = _nearby_route()
    travel_button.visible = not offered_route.is_empty()
    if not travel_button.visible:
        return
    var keyboard_hint := "   [E]"
    if offered_route.destination == "Wayfarer Inn" and _nearest_person() >= 0 \
            and player.position.distance_to(Vector2(-390, -190)) >= 105.0:
        keyboard_hint = ""
    travel_button.text = "➜  %s%s" % [offered_route.destination, keyboard_hint]
    travel_button.reset_size()
    var screen_position: Vector2 = player.get_canvas_transform() * offered_route.anchor
    travel_button.position = screen_position + Vector2(-travel_button.size.x * 0.5, 13)

func _activate_offered_route() -> void:
    var route := _nearby_route()
    if not route.is_empty():
        route.action.call()

func _enter_stonehaven_district() -> void:
    AreaTransition.run(get_tree(), _enter_stonehaven_district_now)

func _enter_stonehaven_district_now() -> void:
    if is_instance_valid(chapter):
        return
    var scene := load(FORSAKEN_CHAPTER) as PackedScene
    if scene == null:
        return
    chapter = scene.instantiate()
    _mount_chapter()

func _mount_chapter() -> void:
    var world := get_parent() as Node2D
    if is_instance_valid(forest):
        gate_resources = Vector2(forest.health, forest.mana)
        forest.queue_free()
        forest = null
    world.hide()
    world.process_mode = Node.PROCESS_MODE_DISABLED
    hide()
    chapter.linked_from_gate = true
    chapter.playthrough_progress = playthrough_progress
    chapter.rite_completed = road_quest == RoadQuest.COMPLETE
    chapter.return_to_gate.connect(_restore_stonehaven_gate, CONNECT_DEFERRED)
    chapter.get_node("Inventory").copy_items_from(self)
    get_tree().root.add_child(chapter)
    chapter.player.necromancer_appearance_enabled = player.necromancer_appearance_enabled
    chapter.player._choose_race(player.race)
    chapter.player.get_node("Camera2D").make_current()

func _restore_stonehaven_gate() -> void:
    AreaTransition.run(get_tree(), _restore_stonehaven_gate_now)

func _restore_stonehaven_gate_now() -> void:
    if not is_instance_valid(chapter):
        return
    chapter.state.write_progress(playthrough_progress)
    copy_items_from(chapter.inventory)
    player.necromancer_appearance_enabled = chapter.player.necromancer_appearance_enabled
    player._choose_race(chapter.player.race)
    chapter.queue_free()
    chapter = null
    var world := get_parent() as Node2D
    _prepare_pinewood(load(PINEWOOD_SCRIPT) as GDScript)
    forest.health = int(gate_resources.x)
    forest.mana = gate_resources.y
    forest.active = true
    forest.show()
    player.global_position = forest.to_global(forest.STONEHAVEN_DISTRICT_SIGN + Vector2(-55, 14))
    world.process_mode = Node.PROCESS_MODE_INHERIT
    world.show()
    show()
    var camera := player.get_node("Camera2D") as Camera2D
    camera.make_current()
    camera.reset_smoothing()

func _unhandled_input(event: InputEvent) -> void:
    if inventory_only or not event is InputEventMouseButton or not event.pressed:
        return
    if event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
        return
    if event.button_index == MOUSE_BUTTON_LEFT:
        var route := _nearby_route()
        var world_cursor: Vector2 = player.get_canvas_transform().affine_inverse() * event.position
        if not route.is_empty() and route.hit.has_point(world_cursor):
            route.action.call()
            get_viewport().set_input_as_handled()
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
    elif not forest.cast_fireball(aim, cursor) and not forest.in_stonehaven() and forest.mana < forest.FIREBALL_COST:
        _show_message("Not enough mana. Give it a moment to recover.", 3.0)

func _close_inventory() -> void:
    inventory_open = false
    inventory_panel.hide()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if quest_offer.visible:
        if event.keycode == KEY_ESCAPE:
            _close_quest_offer()
        get_viewport().set_input_as_handled()
        return
    if event.keycode == KEY_I:
        inventory_open = not inventory_open
        conversation_open = false
        if inventory_open:
            _refresh_inventory()
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
    elif inventory_only:
        return
    elif event.keycode in [KEY_SPACE, KEY_F] and is_instance_valid(forest) and forest.active:
        if not inventory_open and not conversation_open:
            _pinewood_combat_input(event.keycode == KEY_SPACE, player.facing)
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_E:
        if inventory_open:
            _close_inventory()
        elif conversation_open:
            conversation_open = false
            ui.hide()
        elif is_instance_valid(forest) and forest.active:
            _activate_offered_route()
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
                var road_dialogue := speaker.name == &"Elden" and road_quest != RoadQuest.COMPLETE
                if road_dialogue and (road_quest == RoadQuest.OFFERED or _road_ready_to_turn_in()):
                    _show_quest_offer(_road_ready_to_turn_in())
                    get_viewport().set_input_as_handled()
                    return
                if road_dialogue:
                    words = _pip_road_dialogue()
                _show_message("%s — %s:\n%s\n\n[E] Continue" % [people[nearest]["name"], people[nearest]["role"], words], 0.0)
                if road_dialogue:
                    notice_timer.stop()
            elif player.position.distance_to(Vector2(-390, -190)) < 155.0:
                _enter_inn()
        get_viewport().set_input_as_handled()

func _road_ready_to_turn_in() -> bool:
    return road_quest == RoadQuest.ACTIVE and defeated_wolves.size() >= RITE_WOLF_COUNT

func _update_pip_marker() -> void:
    for npc in villagers:
        if npc.name == &"Elden":
            npc.quest_available = road_quest == RoadQuest.OFFERED
            npc.quest_ready = _road_ready_to_turn_in()
            return

func _pip_road_dialogue() -> String:
    var remaining := maxi(0, RITE_WOLF_COUNT - defeated_wolves.size())
    return "%d %s still threatening our sheep in Pinewood Forest. Return when the village is safe." % [
        remaining, "wolf is" if remaining == 1 else "wolves are"
    ]

func _near_pinewood_entrance() -> bool:
    return player.position.distance_to(PINEWOOD_ENTRANCE) < PINEWOOD_ENTRY_DISTANCE

func _near_forest_exit() -> bool:
    return forest.to_local(player.global_position).distance_to(forest.SOUTH_EXIT) < 135.0

func _update_pinewood_loading() -> void:
    if is_instance_valid(forest) and forest.active:
        return
    var distance := player.position.distance_to(PINEWOOD_ENTRANCE)
    if is_instance_valid(forest) and distance > PINEWOOD_RELEASE_DISTANCE:
        forest.queue_free()
        forest = null
    if distance < PINEWOOD_APPROACH_DISTANCE and not inside_inn and not player.choosing_race \
            and not is_instance_valid(forest) and pinewood_script == null and not pinewood_requested:
        pinewood_requested = ResourceLoader.load_threaded_request(PINEWOOD_SCRIPT, "GDScript") == OK
    if not pinewood_requested:
        return
    var status := ResourceLoader.load_threaded_get_status(PINEWOOD_SCRIPT)
    if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        return
    pinewood_requested = false
    if status == ResourceLoader.THREAD_LOAD_LOADED:
        pinewood_script = ResourceLoader.load_threaded_get(PINEWOOD_SCRIPT) as GDScript

func _prepare_pinewood(script: GDScript) -> void:
    forest = script.new()
    forest.name = "PinewoodForest"
    forest.position = Vector2(7800, 0)
    forest.player = player
    forest.defeated_wolves.assign(defeated_wolves)
    forest.hide()
    forest.player_fell.connect(_on_pinewood_fall)
    forest.wolf_defeated.connect(_on_wolf_defeated)
    get_parent().add_child(forest)

func _enter_pinewood() -> void:
    AreaTransition.run(get_tree(), _enter_pinewood_now)

func _enter_pinewood_now() -> void:
    if not is_instance_valid(forest):
        if pinewood_requested:
            pinewood_script = ResourceLoader.load_threaded_get(PINEWOOD_SCRIPT) as GDScript
            pinewood_requested = false
        if pinewood_script == null:
            pinewood_script = load(PINEWOOD_SCRIPT) as GDScript
        if pinewood_script == null:
            _show_message("Pinewood Forest could not be loaded.", 3.0)
            return
        _prepare_pinewood(pinewood_script)
    forest.show()
    forest.active = true
    forest.recover_at_trailhead()
    _show_message("Pinewood Forest. Follow the road north to Stonehaven. Left click to swing. Right click to cast Fireball.", 5.0)

func _leave_pinewood() -> void:
    AreaTransition.run(get_tree(), _leave_pinewood_now)

func _leave_pinewood_now() -> void:
    forest.active = false
    forest.clear_fireballs()
    forest.hide()
    player.position = PINEWOOD_ENTRANCE + Vector2(0, 49)
    player.get_node("Camera2D").reset_smoothing()
    _show_message("You return to Elderwood Village.", 3.0)

func _on_pinewood_fall() -> void:
    _show_message("You recover at the trailhead. Defeated wolves stay down.", 5.0)

func _on_wolf_defeated(variant: int) -> void:
    if not defeated_wolves.has(variant):
        defeated_wolves.append(variant)
    _update_pip_marker()
    if _road_ready_to_turn_in():
        _show_message("Rite of Manhood — return to Elder Elden for your reward.", 5.0)
    else:
        _show_message("Briar wolf defeated.", 3.0)

func _pinewood_prompt() -> String:
    if forest.in_stonehaven():
        return "Stonehaven Gate | Walk north, click the gate, or press E to enter"
    var status := "LMB swing | RMB Fireball | I inventory"
    if _near_forest_exit():
        return "Click the gate or press E — Elderwood Village | " + status
    if forest.to_local(player.global_position).distance_to(Vector2(0, -666)) < 178.0:
        return "Click the gate, press E, or walk through — Stonehaven"
    if road_quest == RoadQuest.ACTIVE:
        if forest.wolves.is_empty():
            return "Return to Elder Elden | " + status
        return "Rite of Manhood (%d/4) | %s" % [RITE_WOLF_COUNT - forest.wolves.size(), status]
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
    AreaTransition.run(get_tree(), _enter_inn_now)

func _enter_inn_now() -> void:
    _make_interior()
    inside_inn = true
    return_position = player.position
    player.position = Vector2(4200, 105)
    _show_message("The Wayfarer Inn — a warm refuge on the frontier. Walk south to the doorway and press E to leave.", 5.0)

func _leave_inn() -> void:
    AreaTransition.run(get_tree(), _leave_inn_now)

func _leave_inn_now() -> void:
    inside_inn = false
    interior.queue_free()
    interior = null
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
