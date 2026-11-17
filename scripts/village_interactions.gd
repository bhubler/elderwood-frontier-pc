extends CanvasLayer
## Frontier village interactions: NPCs, inn interior, dialogue, and starter inventory.
const INTERACT_DISTANCE := 115.0
var player: CharacterBody2D
var ui: PanelContainer
var message: Label
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
    ui.position = Vector2(22, 480)
    ui.custom_minimum_size = Vector2(480, 0)
    holder.add_child(ui)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.075, 0.09, 0.09, 0.93)
    style.border_color = Color("#9a774b")
    style.set_border_width_all(2)
    style.set_content_margin_all(14)
    ui.add_theme_stylebox_override("panel", style)
    message = Label.new()
    message.custom_minimum_size = Vector2(450, 70)
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.add_theme_font_size_override("font_size", 17)
    message.add_theme_color_override("font_color", Color("#f4e8ce"))
    ui.add_child(message)
    ui.hide()

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
        if nearby >= 0:
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
            _show_inventory()
        else:
            ui.hide()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_ESCAPE and (conversation_open or inventory_open):
        conversation_open = false
        inventory_open = false
        ui.hide()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_E:
        if inventory_open:
            inventory_open = false
            ui.hide()
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
            if nearest >= 0:
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
    message.text = value
    ui.show()
