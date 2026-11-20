extends Node2D

signal return_to_gate
var linked_from_gate := false

const WorldCollision := preload("res://scripts/world_collision.gd")
const State = preload("res://scripts/frontier/adventure_state.gd")
const Layouts = preload("res://scripts/frontier/chapter_regions.gd")
const Floor = preload("res://scripts/frontier/region_floor.gd")
const Point = preload("res://scripts/frontier/interaction_point.gd")
const Enemy = preload("res://scripts/frontier/encounter_enemy.gd")
const POINT_SCENE := preload("res://scenes/frontier/interaction_point.tscn")
const ENEMY_SCENE := preload("res://scenes/frontier/encounter_enemy.tscn")
const SAVE_PATH := "user://forsaken_chapter_v1.cfg"
const NpcLibrary := preload("res://scripts/npc/npc_library.gd")
const NPC_ART := "res://art/characters/stonehaven/"
const LANDMARK_ROOT := "res://art/landmarks/"
const SpellEffects := preload("res://scripts/npc/spell_effects.gd")
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
var veiled_agent: Node2D
var local_npcs: Dictionary = {}
const LOCAL_DIALOGUE := {
    "blacksmith": ["Garrik — Blacksmith", "Mind the sparks. I'm drawing the last of the heat out of this iron."],
    "shopkeeper": ["General Goods Merchant", "The dry supplies came in this morning. Here, check this parcel."],
    "alchemist": ["Alchemist", "The order matters. Add the tincture after it settles."],
    "merchant_mage": ["Merchant Mage", "Watch the charm. A steady glow tells you the binding will hold."],
    "guard_sword": ["Stonehaven Sword Guard", "Keep outside sword reach. I'll show you the drill."],
    "guard_spear": ["Stonehaven Spear Guard", "See how the point leads? Give it room."],
    "priest": ["Stonehaven Priest", "May you find your way home, whatever road you take."],
    "monk": ["Stonehaven Monk", "I keep a record of travelers who leave offerings on the north road."],
    "noble": ["Stonehaven Councillor", "The quarter is open again now that the road watch has returned."],
    "sweeper": ["Market Sweeper", "If you're waiting for the next wagon, stand clear of the doorway."],
    "dockhand": ["Porter", "Keep the parcels marked for the chapel on this side."],
}
var summon: Node2D
var summon_actor: Node2D
var summon_windup := 0.0
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
    summon = Node2D.new()
    summon.z_index = 6
    summon.hide()
    add_child(summon)
    _load_region("stonehaven" if linked_from_gate else "graveyard")

func _load_region(destination: String) -> void:
    var previous := region
    region = destination
    for child in props.get_children():
        props.remove_child(child)
        child.queue_free()
    points.clear()
    local_npcs.clear()
    enemy = null
    emissary = null
    veiled_agent = null

    var layout: Dictionary = Layouts.REGIONS[region]
    floor_art.ground = Color(layout["ground"])
    floor_art.region_id = region
    floor_art.queue_redraw()
    _dress_region()
    player.position = Vector2(0, 145)
    for definition in layout["points"]:
        var action: String = definition[0]
        var marker_position: Vector2 = definition[2]
        if action == previous:
            player.position = marker_position.move_toward(Vector2.ZERO, 100)
        if action == "cellar_gate" and region == "stonehaven" and not _cellar_known():
            continue
        _add_point(action, definition[1], marker_position)
    if linked_from_gate and region == "stonehaven":
        _add_point("main_gate", "Stonehaven Gate — Pinewood", Vector2(-416, 200))
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
    if action == "crypt_approach" and region == "graveyard":
        point.show_disc = false
        point.radius = 115.0
    elif action == "veiled_agent":
        point.show_disc = false
    props.add_child(point)
    points.append(point)
    return point

func _dress_region() -> void:
    match region:
        "graveyard":
            _add_landmark("crypt", Layouts.NORTH + Vector2(-38, 5), 230.0)
            for where in [Vector2(-290, -112), Vector2(210, -110), Vector2(-161, 99), Vector2(253, 26), Vector2(345, 188)]:
                _add_landmark("grave_markers", where, 118)
        "stonehaven":
            _add_local_vendor("blacksmith", "forge", Vector2(-327, -142))
            _add_local_vendor("alchemist", "alch_shop", Vector2(-110, -142))
            _add_local_vendor("shopkeeper", "goods_shop", Vector2(110, -142))
            _add_local_vendor("merchant_mage", "mage_shop", Vector2(327, -142))
            _add_local_npc("sweeper", Vector2(-212, 73), 2)
            _add_local_npc("dockhand", Vector2(246, 54), 5)
        "town_court":
            _add_landmark("barracks", Vector2(-355, -124), 199)
            _add_landmark("civic", Vector2(-111, -124), 218)
            _add_landmark("temple", Vector2(130, -124), 212)
            _add_landmark("residence", Vector2(371, -124), 172)
            _add_local_npc("guard_sword", Vector2(-219, 14))
            _add_local_npc("guard_spear", Vector2(228, 32))
            _add_local_npc("priest", Vector2(118, -57))
            _add_local_npc("monk", Vector2(373, -31), 2)
            _add_local_npc("noble", Vector2(-104, -50))
        "northern_watch":
            _add_landmark("watchtower", Vector2(0, -96), 180)
        "raided_caravan":
            _add_landmark("caravan", Vector2(22, -57), 290)
            _add_landmark("way_shrine", Vector2(-340, 50), 85)
        "old_cabin":
            _add_landmark("cabin", Vector2(-60, -91), 226)
            _add_landmark("smugglers_door", Vector2(319, -87), 163)
        "hideout":
            veiled_agent = _add_npc("veiled_agent", Vector2(0, -70))
            if is_instance_valid(veiled_agent):
                veiled_agent.autonomous_patrol = false

func _add_local_vendor(key: String, shop: String, where: Vector2) -> void:
    _add_landmark(shop, where, 195)
    _add_local_npc(key, where + Vector2(0, 65))

func _add_local_npc(key: String, where: Vector2, wardrobe := 0) -> void:
    var npc := _add_npc(key, where, wardrobe)
    if npc == null:
        return
    local_npcs[key] = npc
    var point := _add_point(key, LOCAL_DIALOGUE[key][0], where)
    point.show_disc = false
    point.radius = 76.0

func _add_landmark(key: String, where: Vector2, width: float) -> void:
    var path := LANDMARK_ROOT + key + ".png"
    if not ResourceLoader.exists(path):
        return
    var art := Sprite2D.new()
    art.texture = load(path)
    art.scale = Vector2.ONE * (width / float(art.texture.get_width()))
    art.offset.y = -art.texture.get_height() * 0.5
    art.position = where
    art.z_index = -1
    props.add_child(art)
    if key != "grave_markers":
        var footprint := Vector2(width * 0.62, 25.0)
        WorldCollision.box(props, key, Rect2(where - Vector2(footprint.x * 0.5, 25.0), footprint))

func _add_npc(key: String, where: Vector2, wardrobe := 0) -> Node2D:
    var npc := NpcLibrary.create(key, wardrobe)
    if npc == null:
        return null
    npc.position = where
    props.add_child(npc)
    return npc

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
        return
    if player.choosing_race or inventory.inventory_open or journal_panel.visible:
        return
    var cursor := get_local_mouse_position()
    for point in points:
        if player.position.distance_to(point.position) > point.radius:
            continue
        var hit := Rect2(point.position - Vector2(65, 54), Vector2(130, 66))
        if region == "graveyard" and point.action_id == "crypt_approach":
            hit = Rect2(point.position - Vector2(68, 105), Vector2(136, 116))
        if hit.has_point(cursor):
            _interact(point.action_id)
            get_viewport().set_input_as_handled()
            return

func _add_enemy(definition: Array) -> void:
    enemy = ENEMY_SCENE.instantiate() as Enemy
    enemy.encounter_id = definition[0]
    enemy.title = definition[1]
    enemy.max_health = definition[2]
    enemy.damage = definition[3]
    enemy.reward_xp = definition[4]
    enemy.tint = Color(definition[5])
    if definition.size() > 6:
        var sheet := str(definition[6])
        var path := NPC_ART + sheet + ".tres"
        if ResourceLoader.exists(path):
            enemy.frames = load(path)
            enemy.attack_style = NpcLibrary.ATTACK_STYLES.get(sheet, "melee")
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
    if summon_windup > 0.0:
        summon_windup = maxf(0.0, summon_windup - delta)
        if summon_windup > 0.0:
            return
        summon.position = player.position + Vector2(34, 24)
        _summon_effect(&"arrival", summon.position)
        summon.show()
    summon_remaining = maxf(0.0, summon_remaining - delta)
    if summon_remaining <= 0.0:
        summon.hide()
        _summon_effect(&"expire", summon.position)
        return
    summon_attack_wait = maxf(0.0, summon_attack_wait - delta)
    var destination: Vector2 = player.position + Vector2(34, 24)
    if is_instance_valid(enemy) and enemy.position.distance_to(player.position) <= 210.0:
        destination = enemy.position
        if summon.position.distance_to(destination) <= 46 and summon_attack_wait <= 0.0:
            summon_attack_wait = 1.15
            summon_actor.face(summon.position.direction_to(destination))
            summon_actor.attack()
    if not summon_actor.busy():
        var next := summon.position.move_toward(destination, 200.0 * delta)
        summon_actor.locomotion(summon.position.direction_to(next))
        summon.position = next

func _on_summon_contact() -> void:
    if summon.visible and is_instance_valid(enemy) and summon.position.distance_to(enemy.position) <= 49:
        enemy.take_hit(9)

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
        var npc: Node2D = local_npcs.get(point.action_id)
        if is_instance_valid(npc):
            point.position = npc.position
        var candidate := point.position.distance_to(player.position)
        if candidate <= point.radius and candidate < distance:
            nearest = point
            distance = candidate
    return nearest

func _interact(action: String) -> void:
    if local_npcs.has(action):
        if action.begins_with("guard_"):
            local_npcs[action].attack()
        else:
            local_npcs[action].interact()
        notice = "%s — %s" % LOCAL_DIALOGUE[action]
        return
    match action:
        "main_gate":
            return_to_gate.emit()
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
    if is_instance_valid(veiled_agent):
        veiled_agent.interact()
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
        summon_windup = 0.22
        player.play_cast(player.facing, summon_windup)
        if summon_actor == null:
            summon_actor = NpcLibrary.create("skeleton")
            summon_actor.autonomous_patrol = false
            summon_actor.attack_contact.connect(_on_summon_contact)
            summon.add_child(summon_actor)
        _summon_effect(&"windup", player.position + Vector2(0, -18))
        state.record_summon()
        notice = "A skeleton rises for 35 seconds."
        if state.emissary_pending:
            _bring_emissary()
            notice += " A Black Hand emissary approaches. Speak to the emissary with E."
        _save()

func _summon_effect(clip: StringName, where: Vector2) -> void:
    SpellEffects.play(props, "summon", clip, where)

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
    summon_windup = 0.0
    summon.hide()
    player.cancel_cast_pose()
    _load_region("graveyard")
    notice = "You recover at the graveyard entrance. Your quest progress is intact."

func _save() -> void:
    if can_save and state.save_progress(save_path) != OK:
        notice += " Chapter progress could not be saved."
