extends Node2D

signal return_to_gate
var linked_from_gate := false

const Fireball := preload("res://scripts/pinewood_fireball.gd")
const FIREBALL_COST := 30.0
const WayfindingArt := preload("res://scripts/wayfinding_art.gd")
const PanelHeader := preload("res://scripts/panel_header.gd")
const AreaTransition := preload("res://scripts/area_transition.gd")
const Prop := preload("res://scripts/interior_prop.gd")
const WorldCollision := preload("res://scripts/world_collision.gd")
const State = preload("res://scripts/frontier/adventure_state.gd")
const Mentorship = preload("res://scripts/frontier/mentorship.gd")
const Layouts = preload("res://scripts/frontier/chapter_regions.gd")
const Overworld := preload("res://scripts/frontier/overworld_layout.gd")
const ForestLayout := preload("res://scripts/forest_layout.gd")
const WildernessTerrain := preload("res://scripts/wilderness_terrain.gd")
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
var outdoor_terrain: WildernessTerrain
var terrain_window := Rect2()
var terrain_patches: Array[Rect2] = []
var retired_tiles: Array[Vector2i] = []
const TERRAIN_PATCH_SIZE := Vector2(240, 144)
const STONEHAVEN_BUILDING_SCALE := 1.32
var points: Array[Point] = []
var enemy: Enemy
var crypt_defeated_this_visit: Array[String] = []
var emissary: Point
var emissary_actor: Node2D
var emissary_seen_this_session := false
var ritual_altar: Sprite2D
var grimoire_art: Sprite2D
var grimoire_replay := false
var grimoire_dialog: CenterContainer
var grimoire_heading: Label
var grimoire_details: Label
var mentor_dialog: CenterContainer
var mentor_heading: Label
var mentor_details: Label
var mentor_choices: VBoxContainer
var pending_mentor := ""
var veiled_agent: Node2D
var local_npcs: Dictionary = {}
var local_dialogue: Dictionary = {}
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
var fireball: Fireball
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
    # Earlier builds taught the spell without giving the studied book.
    if state.grimoire_choice == "study" and State.GRIMOIRE not in state.quest_items:
        if inventory.grant_item(State.GRIMOIRE, Layouts.ITEMS[State.GRIMOIRE]):
            state.quest_items.append(State.GRIMOIRE)
            _save()
    var journal_content := VBoxContainer.new()
    journal_panel.remove_child(journal_text)
    journal_panel.add_child(journal_content)
    var journal_title := Label.new()
    journal_title.text = "Quest Journal"
    PanelHeader.add_title(journal_content, journal_title, journal_panel.hide)
    journal_content.add_child(journal_text)
    _build_grimoire_dialog()
    _build_mentor_dialog()
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
    local_dialogue.clear()
    enemy = null
    fireball = null
    emissary = null
    emissary_actor = null
    grimoire_art = null
    grimoire_replay = false
    veiled_agent = null

    var layout: Dictionary = Layouts.REGIONS[region]
    floor_art.ground = Color(layout["ground"])
    floor_art.region_id = region
    player.position = Vector2(0, 145)
    for definition in layout["points"]:
        var action: String = definition[0]
        var marker_position: Vector2 = definition[2]
        if action == previous:
            player.position = marker_position.move_toward(Vector2.ZERO, 100)
        if action == "cellar_gate" and region == "stonehaven" and not _cellar_known():
            continue
        if action == "grimoire" and not state.grimoire_choice.is_empty():
            _add_point("replay_grimoire", "Replay grimoire choice", marker_position)
            continue
        _add_point(action, definition[1], marker_position)
    if linked_from_gate and region == "stonehaven":
        _add_point("main_gate", "South Gate · Pinewood road", Vector2(0, 448))
        if previous.is_empty():
            player.position = Vector2(0, 397)
    if region == "east_pinewood" and previous.is_empty():
        player.position = Overworld.FOREST_WEST + Vector2(105, 0)
    _dress_region()
    if region == "stonehaven":
        _add_point("adventurers_guild", "Adventurer's Guild", Vector2(-260, 360))
        _add_point("city_lord", "Stonehaven Lord", Vector2(-264, -155))
        _add_point("church_mentor", "Church of Stonehaven", Vector2(232, -155))
    if region == "east_pinewood" and not state.guild_rank.is_empty():
        for index in range(10):
            if ("herb_%d" % index) not in state.quest_items:
                _add_point("herb_%d" % index, "Gather woodland herb", Overworld.CARAVAN + Vector2(-250 + (index % 5) * 105, 220 + int(index / 5) * 95), false)
    if not state.mentorship_faction.is_empty() and state.mentorship_year < 5 and not state.mentorship_focus.is_empty():
        var assignment: Array = Mentorship.mission(state.mentorship_faction, state.mentorship_year)
        if not assignment.is_empty() and region == str(assignment[0]) and not ("mentor_task_%d" % state.mentorship_year) in state.quest_items:
            _add_point("mentor_task", str(assignment[2]), assignment[1])
    if region == "northern_watch" and state.guild_provisions and not state.guild_watch_supplied:
        _add_point("deliver_provisions", "Deliver guild provisions", Vector2(70, -85))
    if region == "ancient_ruin" and "ruin_warden" in state.defeated:
        _add_point("ancient_stone", "Recover inscribed magic stone", Vector2(0, -170))
    _load_outdoor_terrain()
    floor_art.queue_redraw()
    if region == "ancient_ruin" and state.lord_stage == "ruin" and "ruin_warden" not in state.defeated:
        _add_enemy(["ruin_warden", "The Waking Sentinel", 78, 16, 65, "#ae9fd0", "vault_warden"], Vector2(0, -60))
    if region == "east_pinewood" and "blackbriar_bandit" not in state.defeated:
        _add_enemy(["blackbriar_bandit", "Blackbriar Bandit", 33, 11, 24, "#bd8061", "bandit"],
            Overworld.CARAVAN + Vector2(125, 135))
    if layout.has("enemy"):
        var definition: Array = layout["enemy"]
        var encounter_id: String = definition[0]
        var cleared := encounter_id in state.defeated
        if encounter_id in ["ossuary_skeleton", "bonecaller"]:
            cleared = encounter_id in crypt_defeated_this_visit
        if not cleared and not (region == "cellar_gate" and state.entry_method == "grimoire"):
            _add_enemy(definition)
    if state.emissary_pending:
        _bring_emissary()
    summon.position = player.position + Vector2(34, 24)
    player.get_node("Camera2D").reset_smoothing()

func _load_outdoor_terrain() -> void:
    outdoor_terrain = null
    terrain_window = Rect2()
    terrain_patches.clear()
    retired_tiles.clear()
    floor_art.show()
    floor_art.grass_backing = false
    floor_art.tiled_ground = false
    floor_art.z_index = -10
    if not ResourceLoader.exists(WildernessTerrain.TILESET_PATH):
        return
    var city := region == "stonehaven"
    var forest := region == "east_pinewood"
    var interior := Floor.is_interior(region)
    var terrain := WildernessTerrain.new()
    terrain.name = "WildernessTerrain"
    terrain.z_index = -10
    if city:
        terrain.roads = Overworld.CITY_ROADS
    elif forest:
        terrain.roads = Overworld.FOREST_ROADS
    elif region == "graveyard":
        terrain.roads = Floor.GRAVEYARD_ROADS
    elif interior:
        terrain.roads = []
    else:
        terrain.roads = [[Vector2(0, 300), Vector2(0, -110)]]
    terrain.trails = []
    terrain.road_half_width = 55.0
    terrain.cobble_radius = 650.0 if interior else 0.0
    terrain.paved_roads = city or region == "graveyard"
    terrain.populate_on_ready = not forest
    terrain.streamed = forest
    if city:
        terrain.ground_bounds = Overworld.CITY.grow(740)
    elif not forest:
        terrain.ground_bounds = Floor.BOUNDS if interior else Floor.BOUNDS.grow(590)
        terrain.modulate = Color("#bbb2a6") if interior else Color.WHITE
    if region == "graveyard":
        terrain.modulate = Color("#8f9c97")
    props.add_child(terrain)
    if terrain.tile_set == null:
        terrain.queue_free()
        return
    outdoor_terrain = terrain
    if forest:
        terrain_window = _forest_terrain_bounds()
        terrain.paint_ground(terrain_window)
    if not terrain.ground_cells().is_empty():
        if city:
            floor_art.hide()
        elif forest:
            floor_art.grass_backing = true
            floor_art.z_index = -12
        else:
            floor_art.tiled_ground = true
            floor_art.z_index = -9
    else:
        floor_art.z_index = -10

func _forest_terrain_bounds() -> Rect2:
    var snapped := (Vector2(player.position) / 360.0).floor() * 360.0
    return Rect2(snapped - Vector2(960, 720), Vector2(2400, 1872))

func _update_forest_terrain() -> void:
    var bounds := _forest_terrain_bounds()
    if bounds != terrain_window:
        # Keep overlap visible and schedule the approaching edge in small patches.
        var previous := terrain_window if terrain_patches.is_empty() else Rect2()
        terrain_window = bounds
        terrain_patches.clear()
        var columns := int(bounds.size.x / TERRAIN_PATCH_SIZE.x)
        var rows := int(bounds.size.y / TERRAIN_PATCH_SIZE.y)
        for x in range(columns):
            for y in range(rows):
                var patch := Rect2(bounds.position + Vector2(x, y) * TERRAIN_PATCH_SIZE, TERRAIN_PATCH_SIZE)
                if not previous.encloses(patch):
                    terrain_patches.append(patch)
        var player_position: Vector2 = player.position
        terrain_patches.sort_custom(func(a: Rect2, b: Rect2) -> bool:
            return a.get_center().distance_squared_to(player_position) > b.get_center().distance_squared_to(player_position))
        retired_tiles.clear()
        for cell in outdoor_terrain.ground_cells():
            if not bounds.has_point(outdoor_terrain.map_to_local(cell)):
                retired_tiles.append(cell)
    for i in range(mini(2, terrain_patches.size())):
        outdoor_terrain.paint_ground(terrain_patches.pop_back(), true)
    for i in range(mini(96, retired_tiles.size())):
        outdoor_terrain.erase_ground_cell(retired_tiles.pop_back())

func _add_point(action: String, title: String, where: Vector2, show_caption := true) -> Point:
    var point := POINT_SCENE.instantiate() as Point
    point.action_id = action
    point.title = title
    point.show_caption = show_caption and action not in ["veiled_agent", "quiet_finn", "emissary"]
    point.position = where
    if action == "cellar_gate" and region == "stonehaven":
        point.show_caption = false
        point.show_disc = false
        point.radius = 95.0
    elif action in ["grimoire", "replay_grimoire"]:
        point.show_disc = false
        point.radius = 120.0
        point.z_index = 12
    elif action == "crypt_approach" and region == "graveyard":
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
            for where in [Vector2(-490, -105), Vector2(477, -124), Vector2(-460, 255), Vector2(500, 245)]:
                _add_landmark("pine_grove", where, 175)
        "stonehaven":
            _dress_stonehaven()
        "east_pinewood":
            _dress_east_pinewood()
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
        "crypt_ritual":
            ritual_altar = Prop.place(props, "../landmarks/ritual_altar", Vector2(0, -166),
                Vector2(110, 44), player)
            var used_altar := Prop.place(props, "crypts/altar_empty_ritual", Vector2(278, -105),
                Vector2(113, 48), player)
            Prop.loop(used_altar, "drip", Vector2(-18, -28), 5.0)
            var candles := Prop.place(used_altar, "crypts/wax_candles", Vector2(13, -63),
                Vector2.ZERO, null, 0)
            Prop.loop(candles, "candle", Vector2(-8, -49), 6.0)
            var rune := Prop.loop(props, "rune", Vector2(288, 115), 4.0)
            rune.z_index = -5
            Prop.place(props, "crypts/cage_rusted", Vector2(-293, -95), Vector2(61, 46), player)
            Prop.place(props, "crypts/blood_pool_fresh", Vector2(263, -49), Vector2.ZERO, null, -5)
            Prop.place(props, "crypts/blood_trail_fresh", Vector2(-234, 112), Vector2.ZERO, null, -5)
            Prop.place(props, "crypts/chains", Vector2(-364, -139))
            if state.grimoire_choice.is_empty():
                _place_grimoire()
        "ancient_ruin":
            _add_landmark("ritual_altar", Vector2(0, -200), 190)
            for where in [Vector2(-350, -140), Vector2(350, -140), Vector2(-260, 95), Vector2(260, 95)]:
                _add_landmark("grave_markers", where, 120)
        "northern_watch":
            WorldCollision.box(props, "WatchTable", Floor.WATCH_TABLE)
            for bounds in Floor.WATCH_CRATES:
                WorldCollision.box(props, "WatchCrates", bounds)
        "crypt_approach":
            Prop.place(props, "crypts/sarcophagus_cracked", Vector2(-271, -85), Vector2(138, 55), player)
            Prop.place(props, "crypts/altar_clean", Vector2(286, -96), Vector2(115, 49), player)
            Prop.place(props, "crypts/web_left", Vector2(-414, -138))
            Prop.place(props, "crypts/web_doorway", Vector2(0, -154))
            Prop.place(props, "crypts/blood_smear_dried", Vector2(219, 92), Vector2.ZERO, null, -5)
        "crypt_ossuary":
            Prop.place(props, "crypts/altar_abandoned", Vector2(-278, -90), Vector2(112, 46), player)
            Prop.place(props, "crypts/sarcophagus_cracked", Vector2(274, -76), Vector2(138, 55), player)
            Prop.place(props, "crypts/bone_pile", Vector2(-238, 90), Vector2.ZERO, null, -4)
            Prop.place(props, "crypts/web_right", Vector2(414, -142))
            Prop.place(props, "crypts/blood_pool_dried", Vector2(242, 128), Vector2.ZERO, null, -5)
        "cellar_gate":
            _add_art(LANDMARK_ROOT + "drainage_hatch.png", Vector2(0, 258), 105.0, -2)
        "oath_vault":
            _add_art(LANDMARK_ROOT + "ritual_altar.png", Vector2(0, -202), 112.0)
        "bandit_camp", "goblin_hollow":
            for where in [Vector2(-440, -98), Vector2(442, -70), Vector2(-425, 139), Vector2(436, 156)]:
                _add_landmark("pine_grove", where, 170)
        "old_cabin":
            _add_landmark("cabin", Vector2(-60, -91), 226)
            _add_landmark("smugglers_door", Vector2(319, -87), 163)
        "hideout":
            veiled_agent = _add_npc("veiled_agent", Vector2(0, -70))
            if is_instance_valid(veiled_agent):
                veiled_agent.autonomous_patrol = false

func _place_grimoire() -> void:
    if is_instance_valid(grimoire_art):
        return
    var book := Sprite2D.new()
    book.texture = WayfindingArt._texture(LANDMARK_ROOT + "forbidden_grimoire.png")
    book.position = Vector2(2, -73)
    book.rotation = -0.10
    ritual_altar.add_child(book)
    grimoire_art = book

func _dress_stonehaven() -> void:
    _add_art(LANDMARK_ROOT + "drainage_hatch.png", Layouts.STONEHAVEN_DRAIN + Vector2(0, 12), 105.0, -2)
    var finn := _add_npc("elder", Vector2(-646, 390), 5)
    if is_instance_valid(finn):
        finn.autonomous_patrol = false
    _add_local_vendor("blacksmith", "forge", Vector2(-708, 14))
    _add_local_vendor("alchemist", "alch_shop", Vector2(-270, 14))
    _add_local_vendor("shopkeeper", "goods_shop", Vector2(247, 14))
    _add_local_vendor("merchant_mage", "mage_shop", Vector2(650, 14))
    _add_landmark("barracks", Vector2(-686, -243), 205)
    _add_landmark("civic", Vector2(-264, -243), 326)
    _add_landmark("temple", Vector2(232, -243), 314)
    _add_landmark("residence", Vector2(698, -243), 195)
    _add_landmark("civic", Vector2(-258, 285), 201) # Guildhall: temporary existing civic art
    _add_landmark("residence", Vector2(252, 285), 196)
    _add_landmark("residence", Vector2(694, 285), 187)
    _add_landmark("way_shrine", Vector2(658, 440), 76)
    _add_local_npc("guard_sword", Vector2(-610, -178))
    _add_local_npc("guard_spear", Vector2(722, 115))
    _add_npc("priest", Vector2(238, -178))
    _add_local_npc("monk", Vector2(354, -118), 2)
    _add_npc("noble", Vector2(-255, -178))
    _add_local_npc("sweeper", Vector2(-212, 131), 2)
    _add_local_npc("dockhand", Vector2(403, 145), 5)
    _add_npc("noble", Vector2(-260, 360), 2) # Guild Master
    for guest in [
        ["townswoman", "Herb grower", "The chapel keeps a garden behind the square.", Vector2(438, -82), 2],
        ["townsman", "Carter", "Wagons take the east entrance when the road is dry.", Vector2(623, 338), 4],
        ["scribe", "Court scribe", "The court's records go back to the first wall.", Vector2(-391, -127), 1],
        ["elder", "Retired mason", "The east arch still has the old stonemasons’ marks.", Vector2(550, -335), 3],
        ["townswoman", "Stonehaven resident", "The forge opens early. You can hear it from here.", Vector2(-340, 348), 6],
        ["townsman", "Stonehaven resident", "The houses here share a courtyard in the south.", Vector2(230, 350), 7],
    ]:
        _add_local_npc(guest[0], guest[3], guest[4], guest[1], guest[2])
    var wall := "res://art/stonehaven/curtain_wall.png"
    var gate := "res://art/stonehaven/gatehouse.png"
    for x in [-710, -355, 0, 355, 710]:
        _add_art(wall, Vector2(x, -451), 360, -3)
    for x in [-710, -354, 354, 710]:
        _add_art(wall, Vector2(x, 493), 357)
    _add_art(gate, Vector2(0, 503), 355)
    _add_east_rampart(wall, gate)
    for x in [-955, 952]:
        for y in range(-430, 470, 112):
            if x > 0 and absi(y - 80) < 166:
                continue
            _add_landmark("pine_grove", Vector2(x, y), 196)
    for x in [-104, 104]:
        WorldCollision.circle(props, "SouthGateTower", Vector2(x, 484), 18.0)
    WorldCollision.box(props, "NorthRampart", Rect2(-900, -470, 1800, 28))
    for x in [-900, 66]:
        WorldCollision.box(props, "SouthRampart", Rect2(x, 470, 834, 29))

func _add_east_rampart(wall: String, gate: String) -> void:
    # Turn the ground axis along the east edge and keep the masonry upright.
    var wall_texture := load(wall) as Texture2D
    var gate_texture := load(gate) as Texture2D
    if wall_texture == null or gate_texture == null:
        return
    for section in [Vector2(-451, -13), Vector2(173, 493)]:
        var count := ceili((section.y - section.x) / 150.0)
        var length: float = (section.y - section.x) / count
        for i in range(count):
            _add_side_masonry(wall_texture, section.x + (i + 0.5) * length, length + 2.0, 68.0, -3)
    _add_side_masonry(gate_texture, 80.0, 195.0, 125.0, -2)
    for section in [Vector2(-451, 45), Vector2(115, 493)]:
        var upper := _east_wall_base(section.x)
        var lower := _east_wall_base(section.y)
        WorldCollision.polygon(props, "EastRampart", PackedVector2Array([
            upper - Vector2(12, 0), upper + Vector2(12, 0),
            lower + Vector2(12, 0), lower - Vector2(12, 0)
        ]))

func _east_wall_base(y: float) -> Vector2:
    return Vector2(864.0 + (y - 80.0) * 0.055, y)

func _add_side_masonry(texture: Texture2D, y: float, length: float, height: float, layer: int) -> void:
    var sprite := Sprite2D.new()
    sprite.texture = texture
    sprite.offset.y = -float(texture.get_height()) * 0.5
    var along := length / texture.get_width()
    # A slight diagonal exposes the front face of the side-on arch.
    sprite.transform = Transform2D(Vector2(along * 0.055, along),
        Vector2(-0.32, 1.0) * (height / texture.get_height()), _east_wall_base(y))
    sprite.z_index = layer
    props.add_child(sprite)

func _dress_east_pinewood() -> void:
    _add_art("res://art/wayfinding/trail_gate.png", Overworld.FOREST_WEST + Vector2(0, 27), 225)
    _add_art("res://art/wayfinding/stonehaven_sign.png", Overworld.FOREST_WEST + Vector2(-132, 53), 88)
    _add_landmark("caravan", Overworld.CARAVAN, 350)
    _add_landmark("watchtower", Overworld.WATCH, 229)
    _add_landmark("crypt", Overworld.CRYPT, 260)
    _add_landmark("cabin", Overworld.CABIN, 265)
    _add_landmark("way_shrine", Overworld.SHRINE, 111)
    for offset in [Vector2(-185, 31), Vector2(172, 23), Vector2(-222, -79), Vector2(158, -94)]:
        _add_landmark("grave_markers", Overworld.CRYPT + offset, 125)
    var woodland := load("res://scripts/frontier/pinewood_woodland.gd").new() as Node2D
    woodland.player = player
    props.add_child(woodland)

func _add_local_vendor(key: String, shop: String, where: Vector2) -> void:
    _add_landmark(shop, where, 195)
    _add_local_npc(key, where + Vector2(0, 65))

func _add_local_npc(key: String, where: Vector2, wardrobe := 0, title := "", line := "") -> void:
    var npc := _add_npc(key, where, wardrobe)
    if npc == null:
        return
    var action := key if title.is_empty() else "%s_%d" % [key, wardrobe]
    var dialogue: Array = LOCAL_DIALOGUE[key] if title.is_empty() else [title, line]
    local_npcs[action] = npc
    local_dialogue[action] = dialogue
    var point := _add_point(action, dialogue[0], where, false)
    point.show_disc = false
    point.radius = 76.0

func _add_landmark(key: String, where: Vector2, width: float) -> void:
    var city_building := region == "stonehaven" and key in [
        "forge", "alch_shop", "goods_shop", "mage_shop", "barracks", "civic", "temple", "residence"
    ]
    var art_width := width * STONEHAVEN_BUILDING_SCALE if city_building else width
    var footprint_width := 255.0 if region == "stonehaven" and key == "civic" else width
    if region == "stonehaven" and key == "temple":
        footprint_width = 249.0
    if _add_art(LANDMARK_ROOT + key + ".png", where, art_width) and key not in ["grave_markers", "pine_grove"]:
        var footprint := Vector2(footprint_width * 0.62, 25.0)
        WorldCollision.box(props, key, Rect2(where - Vector2(footprint.x * 0.5, 25.0), footprint))

func _add_art(path: String, where: Vector2, width: float, layer := -1) -> bool:
    var texture := WayfindingArt._texture(path)
    if texture == null:
        return false
    var art := Sprite2D.new()
    art.texture = texture
    art.scale = Vector2.ONE * (width / float(texture.get_width()))
    art.offset.y = -texture.get_height() * 0.5
    art.position = where
    art.z_index = layer
    props.add_child(art)
    return true

func _add_npc(key: String, where: Vector2, wardrobe := 0) -> Node2D:
    var npc := NpcLibrary.create(key, wardrobe)
    if npc == null:
        return null
    npc.position = where
    props.add_child(npc)
    return npc

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventMouseButton or not event.pressed:
        return
    if player.choosing_race or inventory.inventory_open or journal_panel.visible or grimoire_dialog.visible or mentor_dialog.visible or health <= 0:
        return
    var cursor: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
    if event.button_index == MOUSE_BUTTON_RIGHT:
        _cast_fireball(cursor)
        get_viewport().set_input_as_handled()
        return
    if event.button_index != MOUSE_BUTTON_LEFT:
        return
    for point in points:
        if player.position.distance_to(point.position) > point.radius:
            continue
        var hit := Rect2(point.position - Vector2(65, 54), Vector2(130, 66))
        if region == "graveyard" and point.action_id == "crypt_approach":
            hit = Rect2(point.position - Vector2(68, 105), Vector2(136, 116))
        if point.action_id == "cellar_gate" and region == "stonehaven":
            hit = Rect2(point.position - Vector2(58, 66), Vector2(116, 82))
        if point.action_id in ["grimoire", "replay_grimoire"]:
            hit = Rect2(point.position - Vector2(76, 125), Vector2(152, 131))
        if hit.has_point(cursor):
            _interact(point.action_id)
            get_viewport().set_input_as_handled()
            return
    _attack(cursor)
    get_viewport().set_input_as_handled()

func _add_enemy(definition: Array, where := Vector2.ZERO) -> void:
    enemy = ENEMY_SCENE.instantiate() as Enemy
    enemy.position = where
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
    emissary.show_disc = false
    emissary_actor = _add_npc("black_hand_duelist", emissary.position)
    if is_instance_valid(emissary_actor):
        emissary_actor.autonomous_patrol = false

func _remove_emissary() -> void:
    if is_instance_valid(emissary):
        points.erase(emissary)
        emissary.queue_free()
        emissary = null
    if is_instance_valid(emissary_actor):
        emissary_actor.queue_free()
        emissary_actor = null

func _process(_delta: float) -> void:
    if region == "east_pinewood" and is_instance_valid(outdoor_terrain):
        _update_forest_terrain()
    if inventory.inventory_open:
        journal_panel.hide()
    var blocked: bool = player.choosing_race or inventory.inventory_open or journal_panel.visible or grimoire_dialog.visible or mentor_dialog.visible
    player.set_physics_process(not blocked)
    if is_instance_valid(enemy):
        enemy.target = null if blocked or health <= 0 else player
    inventory.update_resource_bars(health, MAX_HEALTH, mana, State.MAX_MANA)
    var point := _nearest_point()
    var prompt := "Move to a marker and press E." if point == null else "E  %s" % point.title
    hud.text = "%s  |  HP %d/%d  |  Mana %d/%d  |  Level %d\n%s\nLMB / Space attack  ·  RMB / F Fireball  ·  L grimoire  ·  Q summon  ·  J journal  ·  I inventory\n%s" % [
        Layouts.REGIONS[region]["title"], health, MAX_HEALTH, floori(mana), State.MAX_MANA, state.level(), prompt, notice
    ]
    journal_text.text = "%s\n%d XP  ·  %d unspent character points  ·  Conjuration rank %d (%d casts)\nBlack Hand reputation %d%s\n\nJ or Esc to close" % [
        state.journal() + "\n\nAdventurer's Guild\n" + state.guild_journal(), state.experience, state.training_points(),
        state.conjuration_rank(), state.conjuration_uses, state.black_hand_reputation(),
        "  ·  Entry by %s" % state.entry_method if not state.entry_method.is_empty() else ""
    ]

func _physics_process(delta: float) -> void:
    player.position = _bounded(player.position)
    if player.choosing_race or inventory.inventory_open or journal_panel.visible or grimoire_dialog.visible or health <= 0:
        return
    mana = minf(State.MAX_MANA, mana + 8.0 * delta)
    attack_wait = maxf(0.0, attack_wait - delta)
    _update_fireball(delta)
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
    var bounds := Overworld.bounds(region, Floor.BOUNDS)
    return where.clamp(bounds.position + Vector2(20, 28), bounds.end - Vector2(20, 20))

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if player.choosing_race or inventory.inventory_open or health <= 0:
        return
    if mentor_dialog.visible:
        if event.keycode == KEY_ESCAPE:
            mentor_dialog.hide()
        get_viewport().set_input_as_handled()
        return
    if grimoire_dialog.visible:
        if event.keycode == KEY_ESCAPE:
            grimoire_dialog.hide()
        get_viewport().set_input_as_handled()
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
        KEY_F:
            _cast_fireball(player.position + player.facing * 100.0)
        KEY_L:
            if State.GRIMOIRE in state.quest_items and state.grimoire_choice.is_empty():
                _show_grimoire_dialog(false)
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
        notice = "%s — %s" % local_dialogue[action]
        return
    if action == "mentor_task":
        if state.mentorship_faction.is_empty() or state.mentorship_year >= 5:
            return
        var assignment: Array = Mentorship.mission(state.mentorship_faction, state.mentorship_year)
        if assignment.is_empty() or region != str(assignment[0]):
            return
        var task_key := "mentor_task_%d" % state.mentorship_year
        if task_key not in state.quest_items:
            state.quest_items.append(task_key)
            notice = "%s — %s Return to %s for review." % [str(assignment[2]), str(assignment[3]), Mentorship.mentor(state.mentorship_faction)]
            _save()
        return
    if action == "deliver_provisions":
        if state.guild_provisions and not state.guild_watch_supplied:
            state.guild_provisions = false
            state.guild_watch_supplied = true
            notice = "The watch captain accepts the guild provisions. The guards will have enough to last another week. Return to the Guild Master."
            _save()
        else:
            notice = "The watchtower has already received its supplies."
        return
    if action == "ancient_stone":
        if "ruin_warden" not in state.defeated:
            notice = "The Waking Sentinel stands between you and the stone."
        elif state.lord_stage == "ruin":
            state.lord_stage = "report"
            if inventory.grant_item("ancient_magic_stone", Layouts.ITEMS["ancient_magic_stone"]):
                state.quest_items.append("ancient_magic_stone")
            inventory.grant_item("sentinel_sword", Layouts.ITEMS["sentinel_sword"])
            notice = "You recover a magic stone and the Sentinel's Longsword. The engraving reads: Magic is our hope. It has the power to set us free. As it awakens, the world will change. Return to Stonehaven's lord."
            _save()
        else:
            notice = "You have already taken the ancient stone."
        return
    if action == "adventurers_guild":
        if state.guild_rank.is_empty():
            state.guild_rank = "D"
            state.guild_provisions = true
            notice = "Guild Master — Welcome to the Adventurer's Guild! Registered: D-rank. Three assignments: investigate the raided caravan and its bandits, deliver this parcel to the eastern watchtower, and gather ten herbs in East Pinewood. Your provisions are issued."
        elif state.guild_assignments_complete() and state.lord_stage == "locked":
            state.lord_stage = "summoned"
            notice = "Guild Master — All three assignments complete. Excellent work. The Lord of Stonehaven requests an audience at his manor. He heard about the bandits."
        else:
            notice = "Guild Master — %s" % state.guild_journal()
        _save()
        return
    if action.begins_with("herb_"):
        if region != "east_pinewood" or state.guild_rank.is_empty():
            return
        var herb_key := action
        if herb_key in state.quest_items:
            notice = "You have already gathered these herbs."
        else:
            state.quest_items.append(herb_key)
            state.guild_herbs = mini(10, state.guild_herbs + 1)
            notice = "Collected woodland herb (%d/10)." % state.guild_herbs
            for point in points:
                if point.action_id == action:
                    points.erase(point)
                    point.queue_free()
                    break
            _save()
        return
    if action == "city_lord":
        if state.lord_stage == "summoned":
            state.lord_stage = "ruin"
            notice = "Lord of Stonehaven — We are desperately short of capable hands. I have no right to demand this of you, but I heard you defeated the Blackbriar bandits. A strange ruin is drawing people to it. Will you investigate and return with what you discover?"
        elif state.lord_stage == "report":
            state.lord_stage = "share"
            inventory.gold += 50
            inventory._refresh_inventory()
            notice = "Lord of Stonehaven — Magic is our hope, and may set us free as the world awakens? Troubling words. Take this knowledge to the church. In gratitude, our swordmasters and mages will train you without an oath to my army. Speak with me again to accept."
        elif state.lord_stage == "share" or state.mentorship_faction == "lord":
            _offer_mentor("lord")
            return
        else:
            notice = "Lord of Stonehaven — The city has burdens enough. Earn the Guild Master's trust and return."
        _save()
        return
    if action == "church_mentor":
        if state.lord_stage == "share" or state.mentorship_faction == "church":
            _offer_mentor("church")
        else:
            notice = "Priest — May you find wisdom in your journeys. Bring the ancient stone's prophecy to us if you learn more."
        return
    match action:
        "main_gate":
            return_to_gate.emit()
        "inspect_caravan":
            if not state.guild_rank.is_empty():
                state.guild_caravan_inspected = true
                _save()
            notice = "Broken crates and a snapped axle litter the road. You search for survivors, but find only tracks toward the Blackbriar raider camp."
        "woodland_shrine":
            notice = "Travelers have left pine cones and copper coins at the shrine."
        "grave_marker":
            notice = "Someone has scratched a warning into the stone. The dead below answer to a caller."
        "quiet_finn":
            if not state.finn_contact:
                state.finn_contact = true
                if not _cellar_marker_visible():
                    _add_point("cellar_gate", "Hidden Drainage Door", Layouts.STONEHAVEN_DRAIN)
                _save()
            notice = "Quiet Finn whispers about a scratched black hand on a low hatch tucked behind the forge."
        "emissary":
            if not is_instance_valid(emissary):
                return
            emissary_seen_this_session = true
            if state.enter_black_hand("grimoire"):
                if region == "stonehaven" and not _cellar_marker_visible():
                    _add_point("cellar_gate", "Hidden Drainage Door", Layouts.STONEHAVEN_DRAIN)
                if region == "cellar_gate" and is_instance_valid(enemy):
                    enemy.queue_free()
                    enemy = null
                notice = "Emissary — You dared to study the Bonecaller’s rites. Look for the hatch behind Stonehaven’s forge. You may pass."
            else:
                notice = "Emissary — The Black Hand remembers you. The way beneath Stonehaven is still open."
            state.emissary_pending = false
            _remove_emissary()
            _save()
        "veiled_agent":
            _speak_to_agent()
        "grimoire", "replay_grimoire":
            if is_instance_valid(enemy) or "bonecaller" not in state.defeated:
                notice = "The Bonecaller bars the way to the lectern."
            else:
                if action == "replay_grimoire":
                    grimoire_replay = true
                    _place_grimoire()
                _show_grimoire_dialog(false)
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
    if destination == "ancient_ruin" and state.lord_stage not in ["ruin", "report", "share"] and state.mentorship_faction.is_empty():
        notice = "The ruin is sealed. The Lord of Stonehaven may know more."
    elif destination == "crypt_ritual" and (is_instance_valid(enemy) or "ossuary_skeleton" not in state.defeated):
        notice = "Defeat the Restless Skeleton to reach the ritual chamber."
    elif destination == "hideout" and region == "cellar_gate" and state.entry_method.is_empty():
        notice = "The Black Hand Guard bars the way. Defeat him to enter."
    elif destination == "oath_vault" and state.initiation not in ["active", "complete"]:
        notice = "Speak to the Veiled Agent before entering the oath vault."
    elif destination == "cellar_gate" and not _cellar_known():
        notice = "You have yet to find a way into the cellar."
    else:
        notice = ""
        AreaTransition.run(get_tree(), _load_region.bind(destination))

func _speak_to_agent() -> void:
    if (state.lord_stage == "share" or state.mentorship_faction == "black_hand") and not state.entry_method.is_empty():
        _offer_mentor("black_hand")
        return
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

func _build_mentor_dialog() -> void:
    mentor_dialog = CenterContainer.new()
    $HUD.add_child(mentor_dialog)
    mentor_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 570
    mentor_dialog.add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    panel.add_child(content)
    mentor_heading = Label.new()
    PanelHeader.add_title(content, mentor_heading, mentor_dialog.hide)
    mentor_details = Label.new()
    mentor_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(mentor_details)
    mentor_choices = VBoxContainer.new()
    content.add_child(mentor_choices)
    mentor_dialog.hide()

func _offer_mentor(faction: String) -> void:
    if not state.mentorship_faction.is_empty() and state.mentorship_faction != faction:
        notice = "Your apprenticeship is already pledged to %s. You may still study other disciplines later." % Mentorship.mentor(state.mentorship_faction)
        return
    if state.mentorship_year >= 5:
        notice = "%s — Five years have passed. You are twenty now. Your apprenticeship is complete, but the world still has much to teach." % Mentorship.mentor(faction)
        return
    var task_key := "mentor_task_%d" % state.mentorship_year
    if task_key in state.quest_items:
        state.quest_items.erase(task_key)
        state.mentorship_year += 1
        state.player_age += 1
        state.experience += 60
        state.mentorship_history.append(state.mentorship_focus)
        state.mentorship_focus = ""
        _save()
        if state.mentorship_year >= 5:
            state.lord_stage = "prologue_complete"
            notice = "Five years have passed. You are now twenty years old. %s has trained you through five assignments. Your journey truly begins. (+60 XP)" % Mentorship.mentor(faction)
            _save()
            return
        notice = "Year %d complete. A year passes in training under %s. (+60 XP) Choose your focus for your next year." % [state.mentorship_year, Mentorship.mentor(faction)]
    elif not state.mentorship_focus.is_empty():
        var mission: Array = Mentorship.mission(faction, state.mentorship_year)
        notice = "%s — Your assignment: %s. %s" % [Mentorship.mentor(faction), str(mission[2]), str(mission[3])]
        return
    pending_mentor = faction
    mentor_heading.text = Mentorship.mentor(faction)
    mentor_details.text = "Year %d of five. Choose a discipline to emphasize this year. Training will advance your character without locking away other schools. Complete the assigned field quest and return to your mentor for the next time skip." % [state.mentorship_year + 1]
    for child in mentor_choices.get_children():
        child.queue_free()
    for focus in Mentorship.focuses(faction):
        var button := Button.new()
        button.text = str(focus)
        button.pressed.connect(_choose_mentor_focus.bind(str(focus)))
        mentor_choices.add_child(button)
    mentor_dialog.show()

func _choose_mentor_focus(focus: String) -> void:
    if state.mentorship_faction.is_empty():
        state.mentorship_faction = pending_mentor
    if state.mentorship_faction != pending_mentor or state.mentorship_year >= 5:
        mentor_dialog.hide()
        return
    state.mentorship_focus = focus
    state.lord_stage = "mentoring"
    mentor_dialog.hide()
    var mission: Array = Mentorship.mission(state.mentorship_faction, state.mentorship_year)
    notice = "%s takes you as an apprentice. Year %d focus: %s. First task: %s. %s" % [Mentorship.mentor(state.mentorship_faction), state.mentorship_year + 1, focus, str(mission[2]), str(mission[3])]
    _save()

func _build_grimoire_dialog() -> void:
    grimoire_dialog = CenterContainer.new()
    grimoire_dialog.visibility_changed.connect(func() -> void:
        inventory.set_process_unhandled_key_input(not grimoire_dialog.visible)
    )
    $HUD.add_child(grimoire_dialog)
    grimoire_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 600
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#1c1721")
    style.border_color = Color("#b09364")
    style.set_border_width_all(2)
    style.set_content_margin_all(18)
    panel.add_theme_stylebox_override("panel", style)
    grimoire_dialog.add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 14)
    panel.add_child(content)
    grimoire_heading = Label.new()
    grimoire_heading.add_theme_font_size_override("font_size", 25)
    PanelHeader.add_title(content, grimoire_heading, grimoire_dialog.hide)
    grimoire_details = Label.new()
    grimoire_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(grimoire_details)
    var actions := HBoxContainer.new()
    content.add_child(actions)
    for choice in [["Destroy", "destroy"], ["Take", "take"], ["Study", "study"], ["Decide later", "later"]]:
        var button := Button.new()
        button.text = choice[0]
        button.custom_minimum_size.y = 35
        button.pressed.connect(_choose_grimoire.bind(choice[1]))
        actions.add_child(button)
    grimoire_dialog.hide()

func _show_grimoire_dialog(victory: bool) -> void:
    if not state.grimoire_choice.is_empty() and not grimoire_replay:
        return
    grimoire_heading.text = "The Bonecaller is defeated" if victory else "The Forbidden Grimoire"
    grimoire_details.text = "The Forbidden Grimoire lies open on the altar. Destroy it, take it without reading, or study its rites."
    if grimoire_replay:
        grimoire_details.text += "\nYour previous choice stays saved until you confirm a new one. Learned spells and faction progress are kept."
    grimoire_dialog.show()

func _choose_grimoire(choice: String) -> void:
    if not grimoire_dialog.visible or (not state.grimoire_choice.is_empty() and not grimoire_replay):
        return
    if choice == "later":
        grimoire_dialog.hide()
        return
    if choice in ["take", "study"] and State.GRIMOIRE not in state.quest_items:
        if not inventory.grant_item(State.GRIMOIRE, Layouts.ITEMS[State.GRIMOIRE]):
            grimoire_details.text = "Your backpack is full. Make room before keeping the book."
            return
        state.quest_items.append(State.GRIMOIRE)
    match choice:
        "take":
            state.grimoire_choice = "take"
            notice = "You put the unread grimoire in your backpack."
        "destroy":
            state.grimoire_choice = "destroy"
            state.quest_items.erase(State.GRIMOIRE)
            inventory.remove_item(State.GRIMOIRE)
            notice = "You destroy the Forbidden Grimoire."
        "study":
            _learn_spell()
        _:
            return
    if choice != "study":
        state.emissary_pending = false
        _remove_emissary()
    if is_instance_valid(grimoire_art):
        grimoire_art.hide()
        grimoire_art.queue_free()
        grimoire_art = null
    for point in points:
        if point.action_id in ["grimoire", "replay_grimoire"]:
            points.erase(point)
            point.queue_free()
            break
    grimoire_replay = false
    grimoire_dialog.hide()
    _save()

func _learn_spell() -> void:
    var newly_learned := state.learn_summon()
    notice = "Learned Summon Skeleton. Press Q to cast for 45 mana." if newly_learned else "You study the Bonecaller’s rites again."
    emissary_seen_this_session = false
    _bring_emissary()
    notice += " A Black Hand emissary approaches. Speak to them with E."

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
        if region == "crypt_ritual" and state.grimoire_choice == "study" and not emissary_seen_this_session:
            state.emissary_pending = true
            _bring_emissary()
            notice += " Speak to the Black Hand emissary with E."
        _save()

func _summon_effect(clip: StringName, where: Vector2) -> void:
    SpellEffects.play(props, "summon", clip, where)

func _attack(cursor := Vector2.INF) -> void:
    if attack_wait > 0.0:
        return
    attack_wait = 0.32
    var aim: Vector2 = player.facing if cursor == Vector2.INF else player.position.direction_to(cursor)
    if is_instance_valid(enemy) and enemy.position.distance_to(player.position) <= 84:
        aim = player.position.direction_to(enemy.position)
    player.play_strike(aim, true)
    if is_instance_valid(enemy) and enemy.position.distance_to(player.position) <= 72:
        enemy.take_hit(9 + player.attack_bonus)
        if is_instance_valid(enemy):
            notice = "You strike %s." % enemy.title
    else:
        notice = "Move closer to your target."

func _cast_fireball(cursor: Vector2) -> void:
    if is_instance_valid(fireball):
        return
    if mana < FIREBALL_COST:
        notice = "Fireball needs %d mana." % FIREBALL_COST
        return
    var direction: Vector2 = player.position.direction_to(cursor)
    if direction == Vector2.ZERO:
        direction = player.facing
    if is_instance_valid(enemy) and player.position.distance_to(enemy.position) < 460:
        var target_direction: Vector2 = player.position.direction_to(enemy.position)
        if direction.dot(target_direction) > 0.8:
            direction = target_direction
    mana -= FIREBALL_COST
    player.play_cast(direction, 0.20)
    fireball = Fireball.new()
    fireball.position = player.position
    fireball.direction = direction
    fireball.z_index = 11
    props.add_child(fireball)

func _update_fireball(delta: float) -> void:
    if not is_instance_valid(fireball):
        return
    if fireball.burst > 0.0:
        fireball.burst -= delta
        if fireball.burst <= 0.0:
            fireball.queue_free()
            fireball = null
        return
    fireball.remaining -= delta
    var start: Vector2 = fireball.global_position
    var finish := start + fireball.direction * Fireball.SPEED * delta
    var ray := PhysicsRayQueryParameters2D.create(start, finish, 1, [player.get_rid()])
    var wall := get_world_2d().direct_space_state.intersect_ray(ray)
    if not wall.is_empty():
        finish = wall.position
    fireball.global_position = finish
    if is_instance_valid(enemy):
        var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, finish)
        if closest.distance_to(enemy.global_position) <= 22.0 and (wall.is_empty() or closest != finish):
            enemy.take_hit(17)
            fireball.detonate()
            return
    if not wall.is_empty() or fireball.remaining <= 0.0:
        fireball.detonate()

func _on_victory(encounter_id: String, reward_xp: int) -> void:
    var already_rewarded := encounter_id in state.defeated
    notice = "%s defeated." % enemy.title
    if not already_rewarded:
        notice += " +%d XP" % reward_xp
    enemy = null
    if encounter_id in ["ossuary_skeleton", "bonecaller"]:
        crypt_defeated_this_visit.append(encounter_id)
    state.record_victory(encounter_id, reward_xp)
    if encounter_id == "ruin_warden" and region == "ancient_ruin":
        _add_point("ancient_stone", "Recover inscribed magic stone", Vector2(0, -170))
        notice += " The ancient stone lies exposed beside the altar."
    if encounter_id == "bonecaller":
        if state.grimoire_choice.is_empty():
            _show_grimoire_dialog(true)
        else:
            notice += " Use Replay grimoire choice at the altar to try a different outcome."
    if encounter_id == "cellar_guard":
        state.enter_black_hand("guard")
        _remove_emissary()
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
