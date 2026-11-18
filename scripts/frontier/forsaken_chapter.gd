extends Node2D

const State = preload("res://scripts/frontier/adventure_state.gd")
const Layouts = preload("res://scripts/frontier/chapter_regions.gd")
const Floor = preload("res://scripts/frontier/region_floor.gd")
const Point = preload("res://scripts/frontier/interaction_point.gd")
const Enemy = preload("res://scripts/frontier/encounter_enemy.gd")
const POINT_SCENE := preload("res://scenes/frontier/interaction_point.tscn")
const ENEMY_SCENE := preload("res://scenes/frontier/encounter_enemy.tscn")
const SAVE_PATH := "user://forsaken_chapter_v1.cfg"
const MAX_HEALTH := 100

@onready var player = $Player
@onready var inventory = $Inventory
@onready var floor_art: Node2D = $Floor
@onready var props: Node2D = $Props
@onready var hud: Label = $HUD/Status
@onready var journal_panel: PanelContainer = $HUD/Journal
@onready var journal_text: Label = $HUD/Journal/Entries

var state := State.new()
var region := ""
var points: Array[Point] = []
var enemy: Enemy
var emissary: Point
var summon: Polygon2D
var summon_remaining := 0.0
var summon_attack_wait := 0.0
var health := MAX_HEALTH
var mana := float(State.MAX_MANA)
var attack_wait := 0.0
var notice := "The old road ends at the Forsaken Graveyard."
var can_save := true
var save_path := SAVE_PATH

func _ready() -> void:
    var result := state.load_progress(save_path)
    if result != OK and result != ERR_FILE_NOT_FOUND:
        can_save = false
        notice = "Chapter save could not be loaded. This session will not overwrite it."
    for item_id in state.quest_items:
        if Layouts.ITEMS.has(item_id):
            inventory.grant_item(item_id, Layouts.ITEMS[item_id])
    summon = Polygon2D.new()
    summon.polygon = PackedVector2Array([Vector2(0, -27), Vector2(12, -13), Vector2(9, 7), Vector2(-9, 7), Vector2(-12, -13)])
    summon.color = Color("#acdec5")
    summon.z_index = 6
    summon.hide()
    add_child(summon)
    _load_region("graveyard")

func _load_region(destination: String) -> void:
    var previous := region
    region = destination
    for child in props.get_children():
        props.remove_child(child)
        child.queue_free()
    points.clear()
    enemy = null
    emissary = null

    var layout: Dictionary = Layouts.REGIONS[region]
    floor_art.ground = Color(layout["ground"])
    floor_art.region_id = region
    floor_art.queue_redraw()
    player.position = Vector2(0, 145)
    for definition in layout["points"]:
        var action: String = definition[0]
        var marker_position: Vector2 = definition[2]
        if action == previous:
            player.position = marker_position.move_toward(Vector2.ZERO, 100)
        if action == "cellar_gate" and region == "stonehaven" and not _cellar_known():
            continue
        _add_point(action, definition[1], marker_position)
    if layout.has("enemy"):
        var definition: Array = layout["enemy"]
        if definition[0] not in state.defeated and not (region == "cellar_gate" and state.entry_method == "grimoire"):
            _add_enemy(definition)
    if state.emissary_pending:
        _bring_emissary()
    summon.position = player.position + Vector2(34, 24)
    player.get_node("Camera2D").reset_smoothing()

func _add_point(action: String, title: String, where: Vector2) -> Point:
    var point := POINT_SCENE.instantiate() as Point
    point.action_id = action
    point.title = title
    point.position = where
    props.add_child(point)
    points.append(point)
    return point

func _add_enemy(definition: Array) -> void:
    enemy = ENEMY_SCENE.instantiate() as Enemy
    enemy.encounter_id = definition[0]
    enemy.title = definition[1]
    enemy.max_health = definition[2]
    enemy.damage = definition[3]
    enemy.reward_xp = definition[4]
    enemy.tint = Color(definition[5])
    enemy.defeated.connect(_on_victory)
    enemy.attack_landed.connect(_take_damage)
    props.add_child(enemy)

func _bring_emissary() -> void:
    if is_instance_valid(emissary):
        return
    var where: Vector2 = player.position.move_toward(Vector2.ZERO, 36) + Vector2(50, 0)
    emissary = _add_point("emissary", "Black Hand Emissary", _bounded(where))
    emissary.radius = 96

func _process(_delta: float) -> void:
    if inventory.inventory_open:
        journal_panel.hide()
    var blocked: bool = player.choosing_race or inventory.inventory_open or journal_panel.visible
    player.set_physics_process(not blocked)
    if is_instance_valid(enemy):
        enemy.target = null if blocked or health <= 0 else player
    var point := _nearest_point()
    var prompt := "Move to a marker and press E." if point == null else "E  %s" % point.title
    hud.text = "%s  |  HP %d/%d  |  Mana %d/%d  |  Level %d\n%s\nSpace attack  ·  L study  ·  Q summon  ·  J journal  ·  I inventory\n%s" % [
        Layouts.REGIONS[region]["title"], health, MAX_HEALTH, floori(mana), State.MAX_MANA, state.level(), prompt, notice
    ]
    journal_text.text = "%s\n\n%s\n%d XP  ·  %d unspent character points  ·  Conjuration rank %d (%d casts)\nBlack Hand reputation %d%s\n\nJ or Esc to close" % [
        "Quest Journal", state.journal(), state.experience, state.training_points(),
        state.conjuration_rank(), state.conjuration_uses, state.black_hand_reputation(),
        "  ·  Entry by %s" % state.entry_method if not state.entry_method.is_empty() else ""
    ]

func _physics_process(delta: float) -> void:
    player.position = _bounded(player.position)
    if player.choosing_race or inventory.inventory_open or journal_panel.visible or health <= 0:
        return
    mana = minf(State.MAX_MANA, mana + 8.0 * delta)
    attack_wait = maxf(0.0, attack_wait - delta)
    if summon_remaining <= 0.0:
        return
    summon_remaining = maxf(0.0, summon_remaining - delta)
    summon.visible = summon_remaining > 0.0
    if not summon.visible:
        return
    summon_attack_wait = maxf(0.0, summon_attack_wait - delta)
    var destination: Vector2 = player.position + Vector2(34, 24)
    if is_instance_valid(enemy) and enemy.position.distance_to(player.position) <= 210.0:
        destination = enemy.position
        if summon.position.distance_to(destination) <= 46 and summon_attack_wait <= 0.0:
            summon_attack_wait = 1.15
            enemy.take_hit(9)
    summon.position = summon.position.move_toward(destination, 200 * delta)

func _bounded(where: Vector2) -> Vector2:
    return where.clamp(Floor.BOUNDS.position + Vector2(20, 28), Floor.BOUNDS.end - Vector2(20, 20))

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if player.choosing_race or inventory.inventory_open or health <= 0:
        return
    if journal_panel.visible:
        if event.keycode in [KEY_J, KEY_ESCAPE, KEY_I]:
            journal_panel.hide()
            if event.keycode == KEY_I:
                return
        get_viewport().set_input_as_handled()
        return
    match event.keycode:
        KEY_E:
            var point := _nearest_point()
            if point != null:
                _interact(point.action_id)
        KEY_SPACE:
            _attack()
        KEY_L:
            _learn_spell()
        KEY_Q:
            _cast_summon()
        KEY_J:
            journal_panel.show()
        _:
            return
    get_viewport().set_input_as_handled()

func _nearest_point() -> Point:
    var nearest: Point
    var distance := INF
    for point in points:
        var candidate := point.position.distance_to(player.position)
        if candidate <= point.radius and candidate < distance:
            nearest = point
            distance = candidate
    return nearest

func _interact(action: String) -> void:
    match action:
        "grave_marker":
            notice = "Someone has scratched a warning into the stone. The dead below answer to a caller."
        "quiet_finn":
            if not state.finn_contact:
                state.finn_contact = true
                if not _cellar_marker_visible():
                    _add_point("cellar_gate", "Hidden Drainage Door", Layouts.NORTH)
                _save()
            notice = "Quiet Finn whispers about a scratched black hand on the drainage door north of here."
        "emissary":
            if state.enter_black_hand("grimoire"):
                points.erase(emissary)
                emissary.queue_free()
                emissary = null
                if region == "stonehaven" and not _cellar_marker_visible():
                    _add_point("cellar_gate", "Hidden Drainage Door", Layouts.NORTH)
                if region == "cellar_gate" and is_instance_valid(enemy):
                    enemy.queue_free()
                    enemy = null
                notice = "Emissary — You dared to raise the dead. Find the drainage door in Stonehaven. You may pass."
                _save()
        "veiled_agent":
            _speak_to_agent()
        "grimoire":
            if "bonecaller" not in state.defeated:
                notice = "The Bonecaller bars the way to the lectern."
            else:
                _take_item(State.GRIMOIRE, "You recover the Forbidden Grimoire. Press L to study it.")
        "ledger":
            if "vault_warden" not in state.defeated:
                notice = "The Warden guards the ledger."
            elif state.initiation == "active":
                _take_item(State.LEDGER, "You recover the sealed ledger. Take it to the Veiled Agent.")
            else:
                notice = "The ledger has already been delivered."
        _:
            _try_travel(action)

func _cellar_known() -> bool:
    return state.finn_contact or not state.entry_method.is_empty()

func _cellar_marker_visible() -> bool:
    for point in points:
        if point.action_id == "cellar_gate":
            return true
    return false

func _try_travel(destination: String) -> void:
    if not Layouts.REGIONS.has(destination):
        return
    if destination == "crypt_ritual" and "ossuary_skeleton" not in state.defeated:
        notice = "Defeat the Restless Skeleton to reach the ritual chamber."
    elif destination == "hideout" and region == "cellar_gate" and state.entry_method.is_empty():
        notice = "The Black Hand Guard bars the way. Defeat him to enter."
    elif destination == "oath_vault" and state.initiation not in ["active", "complete"]:
        notice = "Speak to the Veiled Agent before entering the oath vault."
    elif destination == "cellar_gate" and not _cellar_known():
        notice = "You have yet to find a way into the cellar."
    else:
        notice = ""
        _load_region(destination)

func _speak_to_agent() -> void:
    match state.initiation:
        "available":
            state.start_initiation()
            if state.entry_method == "guard":
                notice = "Veiled Agent — The guard was your trial. A guard who cannot survive has no place here.\nRecover the sealed ledger from the oath vault to earn membership."
            else:
                notice = "Veiled Agent — No banners. No sermons. We work in the spaces between kingdoms.\nRecover the sealed ledger from the oath vault to earn membership."
            _save()
        "active":
            if state.finish_initiation():
                inventory.remove_item(State.LEDGER)
                notice = "Veiled Agent — You kept it sealed. You are Black Hand now. (+10 reputation)"
                _save()
            else:
                notice = "Veiled Agent — The ledger is still in the oath vault."
        "complete":
            notice = "Veiled Agent — Welcome back, Black Hand."

func _take_item(item_id: String, message: String) -> void:
    if item_id in state.quest_items:
        notice = "You already recovered this item."
        return
    if not inventory.grant_item(item_id, Layouts.ITEMS[item_id]):
        notice = "Your backpack is full. Free a slot before taking this item."
        return
    state.quest_items.append(item_id)
    notice = message
    _save()

func _learn_spell() -> void:
    if state.learn_summon():
        notice = "Learned Summon Skeleton. Press Q to cast for 45 mana."
        _save()
    else:
        notice = "You already know Summon Skeleton." if state.spell_learned else "Find the Forbidden Grimoire first."

func _cast_summon() -> void:
    if not state.spell_learned:
        notice = "You haven't learned Summon Skeleton."
    elif summon_remaining > 0.0:
        notice = "Your skeleton is already active."
    elif mana < State.SPELL_COST:
        notice = "Summon Skeleton needs 45 mana."
    else:
        mana -= State.SPELL_COST
        summon_remaining = State.SUMMON_SECONDS
        summon_attack_wait = 0.0
        summon.position = player.position + Vector2(34, 24)
        summon.show()
        state.record_summon()
        notice = "A skeleton rises for 35 seconds."
        if state.emissary_pending:
            _bring_emissary()
            notice += " A Black Hand emissary approaches. Speak to the emissary with E."
        _save()

func _attack() -> void:
    if attack_wait > 0.0:
        return
    attack_wait = 0.32
    if is_instance_valid(enemy) and enemy.position.distance_to(player.position) <= 72:
        enemy.take_hit(9 + player.attack_bonus)
        if is_instance_valid(enemy):
            notice = "You strike %s." % enemy.title
    else:
        notice = "Move closer to your target."

func _on_victory(encounter_id: String, reward_xp: int) -> void:
    notice = "%s defeated. +%d XP" % [enemy.title, reward_xp]
    enemy = null
    state.record_victory(encounter_id, reward_xp)
    if encounter_id == "cellar_guard":
        state.enter_black_hand("guard")
        if is_instance_valid(emissary):
            points.erase(emissary)
            emissary.queue_free()
            emissary = null
        notice += " The guard's defeat grants access to the cellar."
    _save()

func _take_damage(amount: int) -> void:
    health = maxi(0, health - maxi(1, amount - player.defense_bonus))
    if health == 0:
        call_deferred("_recover_at_graveyard")

func _recover_at_graveyard() -> void:
    health = MAX_HEALTH
    mana = State.MAX_MANA
    summon_remaining = 0.0
    summon.hide()
    _load_region("graveyard")
    notice = "You recover at the graveyard entrance. Your quest progress is intact."

func _save() -> void:
    if can_save and state.save_progress(save_path) != OK:
        notice += " Chapter progress could not be saved."
