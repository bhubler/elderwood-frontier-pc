extends Node2D

const ElderwoodType := preload("res://scripts/elderwood_type.gd")

signal return_to_gate
var linked_from_gate := false
var rite_completed := false
var guild_referral_accepted := false
var playthrough_progress: ConfigFile
var resume_region := ""
var resume_position := Vector2.INF

const Fireball := preload("res://scripts/pinewood_fireball.gd")
const FIREBALL_COST := 30.0
const InteractionArt := preload("res://scripts/interaction_art.gd")
const WayfindingArt := preload("res://scripts/wayfinding_art.gd")
const DialoguePanel := preload("res://scripts/dialogue_panel.gd")
const DialoguePortrait := preload("res://scripts/dialogue_portrait.gd")
const InventoryFinish := preload("res://scripts/inventory_finish.gd")
const PanelHeader := preload("res://scripts/panel_header.gd")
const AreaTransition := preload("res://scripts/area_transition.gd")
const Prop := preload("res://scripts/interior_prop.gd")
const WorldCollision := preload("res://scripts/world_collision.gd")
const State = preload("res://scripts/frontier/adventure_state.gd")
const Mentorship = preload("res://scripts/frontier/mentorship.gd")
const Ruins := preload("res://scripts/frontier/awakening_ruins.gd")
const RUIN_TREASURE := {
    "ancient_ruin": [Vector2(-596, -293), "ruin_ward_clasp"],
    "ruin_lower": [Vector2(592, -245), "ruin_watch_mantle"],
}
var ruin_walls: Array[Rect2] = []
const Layouts = preload("res://scripts/frontier/chapter_regions.gd")
const PinewoodWoodland := preload("res://scripts/frontier/pinewood_woodland.gd")
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
var stonehaven_terrain: WildernessTerrain
var forest_terrain: WildernessTerrain
var forest_woodland: PinewoodWoodland
var terrain_center := Vector2i(9999, 9999)
var terrain_patches: Array[Vector2i] = []
var terrain_patch_offsets: Array[Vector2i] = []
var painted_patches: Dictionary = {}
var forest_cache_dirty := false
const FOREST_PATCH_CACHE := "user://east_pinewood_explored_v1.cache"
const TERRAIN_PATCH_SIZE := Vector2(240, 144)
const STONEHAVEN_BUILDING_SCALE := 1.32
var points: Array[Point] = []
var enemy: Enemy
var crypt_defeated_this_visit: Array[String] = []
var sentinel_defeated_this_visit := false
var emissary: Point
var emissary_actor: Node2D
var emissary_seen_this_session := false
var ritual_altar: Sprite2D
var grimoire_art: Sprite2D
var grimoire_replay := false
var grimoire_dialog: CenterContainer
var grimoire_heading: Label
var grimoire_details: Label
var guild_dialog: CenterContainer
var guild_details: Label
var guild_rank_label: Label
var guild_cards: VBoxContainer
var guild_status: Dictionary = {}
var guild_accept_buttons: Dictionary = {}
var guild_confirm: Button
var guild_portrait: DialoguePortrait
var mentor_portrait: DialoguePortrait
var city_lord: Node2D
var church_priest: Node2D
var quiet_finn: Node2D
var guild_master: Node2D
var watch_captain: Node2D
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
    var result := ERR_FILE_NOT_FOUND
    if playthrough_progress == null:
        result = state.load_progress(save_path)
    elif playthrough_progress.has_section("chapter"):
        result = state.read_progress(playthrough_progress)
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
    InventoryFinish.style_dialog(journal_panel)
    journal_panel.remove_child(journal_text)
    journal_panel.add_child(journal_content)
    var journal_title := Label.new()
    ElderwoodType.heading(journal_title)
    journal_title.text = "Quest Journal"
    PanelHeader.add_title(journal_content, journal_title, journal_panel.hide)
    InventoryFinish.style_dialog_action(journal_content.get_child(0).get_node("CloseButton"))
    journal_content.add_child(journal_text)
    _build_grimoire_dialog()
    _build_mentor_dialog()
    _build_guild_dialog()
    summon = Node2D.new()
    summon.z_index = 6
    summon.hide()
    add_child(summon)
    if Layouts.REGIONS.has(resume_region):
        _load_region(resume_region)
    else:
        _load_region("stonehaven" if linked_from_gate else "graveyard")

func _load_region(destination: String) -> void:
    var previous := region
    if previous == "east_pinewood" and destination != previous:
        _save_forest_patch_cache()
    region = destination
    ruin_walls.clear()
    if is_instance_valid(stonehaven_terrain):
        stonehaven_terrain.collision_enabled = false
        stonehaven_terrain.navigation_enabled = false
    for child in props.get_children():
        if child == stonehaven_terrain or child == forest_terrain or child == forest_woodland:
            child.hide()
            child.process_mode = Node.PROCESS_MODE_DISABLED
            continue
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
    guild_master = null
    city_lord = null
    church_priest = null
    quiet_finn = null
    watch_captain = null

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
    if resume_position != Vector2.INF:
        player.position = _bounded(resume_position)
        resume_position = Vector2.INF
    _dress_region()
    if region == "stonehaven":
        _add_point("adventurers_guild", "Adventurer's Guild", Vector2(-260, 360))
        _add_point("city_lord", "Stonehaven Lord", Vector2(-264, -155))
        _add_point("church_mentor", "Church of Stonehaven", Vector2(232, -155))
    if region == "east_pinewood" and "herbs" in state.guild_accepted:
        for index in range(10):
            if ("herb_%d" % index) not in state.quest_items:
                var herb_position := Overworld.CARAVAN + Vector2(-250 + (index % 5) * 105, 220 + int(index / 5) * 95)
                var herb := _add_point("herb_%d" % index, "Gather woodland herb", herb_position)
                _add_herb_art(herb)
                herb.radius = 58.0
    if not state.mentorship_faction.is_empty() and state.mentorship_year < 5 and not state.mentorship_focus.is_empty():
        var assignment: Array = Mentorship.mission(state.mentorship_faction, state.mentorship_year)
        if not assignment.is_empty() and region == str(assignment[0]) and ("mentor_task_%d" % state.mentorship_year) not in state.quest_items:
            _add_point("mentor_task", str(assignment[2]), assignment[1])

    if region == "ruin_sanctum" and sentinel_defeated_this_visit and state.lord_stage == "ruin":
        _add_point("ancient_stone", "Recover the stone and longsword", Ruins.RELIC)
    _update_quest_markers()
    _load_outdoor_terrain()
    floor_art.queue_redraw()
    if region == "east_pinewood" and "blackbriar_bandit" not in state.defeated:
        _add_enemy(["blackbriar_bandit", "Blackbriar Bandit", 33, 11, 24, "#bd8061", "bandit"],
            Overworld.CARAVAN + Vector2(125, 135))
    if layout.has("enemy"):
        var definition: Array = layout["enemy"]
        var encounter_id: String = definition[0]
        var cleared := encounter_id in state.defeated
        if encounter_id in ["ossuary_skeleton", "bonecaller"]:
            cleared = encounter_id in crypt_defeated_this_visit
        elif encounter_id == "ruin_warden":
            # Old saves may already have awarded XP for the original one-room fight.
            cleared = sentinel_defeated_this_visit
        if not cleared and not (region == "cellar_gate" and state.entry_method == "grimoire"):
            _add_enemy(definition, layout.get("enemy_position", Vector2.ZERO))
    if state.emissary_pending:
        _bring_emissary()
    summon.position = player.position + Vector2(34, 24)
    player.get_node("Camera2D").reset_smoothing()

func _load_outdoor_terrain() -> void:
    outdoor_terrain = null
    terrain_center = Vector2i(9999, 9999)
    terrain_patches.clear()
    floor_art.show()
    floor_art.grass_backing = false
    floor_art.tiled_ground = false
    floor_art.z_index = -10
    if not ResourceLoader.exists(WildernessTerrain.TILESET_PATH):
        return
    var city := region == "stonehaven"
    var forest := region == "east_pinewood"
    if city and is_instance_valid(stonehaven_terrain):
        outdoor_terrain = stonehaven_terrain
        outdoor_terrain.collision_enabled = true
        outdoor_terrain.navigation_enabled = true
        outdoor_terrain.process_mode = Node.PROCESS_MODE_INHERIT
        outdoor_terrain.show()
        floor_art.hide()
        return
    if forest and is_instance_valid(forest_terrain):
        outdoor_terrain = forest_terrain
        outdoor_terrain.show()
        outdoor_terrain.process_mode = Node.PROCESS_MODE_INHERIT
        _prime_forest_terrain()
        return
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
    if forest:
        # Trunks and map boundaries use dedicated world collision, not ground tiles.
        # Rebuild smaller rendering batches when a streamed patch changes.
        terrain.rendering_quadrant_size = 8
        terrain.collision_enabled = false
        terrain.navigation_enabled = false
    if city:
        terrain.ground_bounds = Overworld.CITY.grow(740)
    elif not forest:
        if Ruins.ROOMS.has(region):
            terrain.ground_bounds = Ruins.bounds(region)
            terrain.cobble_radius = 1200.0
        else:
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
        forest_terrain = terrain
        _restore_forest_patch_cache()
        _prime_forest_terrain()
    elif not terrain.ground_cells().is_empty():
        if city:
            stonehaven_terrain = terrain
            floor_art.hide()
        else:
            floor_art.tiled_ground = true
            floor_art.z_index = -9

func _forest_patch_cache_signature() -> Array:
    return [
        Engine.get_version_info()["hex"],
        FileAccess.get_sha256(WildernessTerrain.TILESET_PATH),
        FileAccess.get_sha256("res://scripts/wilderness_terrain.gd"),
        Overworld.FOREST, Overworld.FOREST_ROADS, forest_terrain.road_half_width, TERRAIN_PATCH_SIZE,
    ]

func _restore_forest_patch_cache() -> void:
    if not FileAccess.file_exists(FOREST_PATCH_CACHE):
        return
    var file := FileAccess.open(FOREST_PATCH_CACHE, FileAccess.READ)
    if file == null or file.get_var() != _forest_patch_cache_signature():
        return
    var keys: Variant = file.get_var()
    var ground: Variant = file.get_var()
    var underlay: Variant = file.get_var()
    if file.get_error() != OK or not keys is Array or keys.is_empty() \
            or not ground is PackedByteArray or ground.is_empty() \
            or not underlay is PackedByteArray:
        return
    for key in keys:
        if not key is Vector2i:
            return
    if forest_terrain.grass_source >= 0 and underlay.is_empty():
        return
    forest_terrain.tile_map_data = ground
    forest_terrain.grass_underlay.tile_map_data = underlay
    for key in keys:
        painted_patches[key] = true

func _save_forest_patch_cache() -> void:
    if not forest_cache_dirty or not is_instance_valid(forest_terrain):
        return
    var pending := "%s.%d.tmp" % [FOREST_PATCH_CACHE, OS.get_process_id()]
    var file := FileAccess.open(pending, FileAccess.WRITE)
    if file == null:
        return
    file.store_var(_forest_patch_cache_signature())
    file.store_var(painted_patches.keys())
    file.store_var(forest_terrain.tile_map_data)
    file.store_var(forest_terrain.grass_underlay.tile_map_data)
    var written := file.get_error() == OK
    file.close()
    if written and DirAccess.rename_absolute(pending, FOREST_PATCH_CACHE) == OK:
        forest_cache_dirty = false
    elif FileAccess.file_exists(pending):
        DirAccess.remove_absolute(pending)

func _prime_forest_terrain() -> void:
    floor_art.grass_backing = true
    floor_art.z_index = -12
    if terrain_patch_offsets.is_empty():
        for x in range(-6, 7):
            for y in range(-8, 9):
                terrain_patch_offsets.append(Vector2i(x, y))
        terrain_patch_offsets.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
            return (Vector2(a) * TERRAIN_PATCH_SIZE).length_squared() > (Vector2(b) * TERRAIN_PATCH_SIZE).length_squared())
    var center := Vector2i((Vector2(player.position) / TERRAIN_PATCH_SIZE).floor())
    var first := center - Vector2i(4, 5)
    var size := Vector2i(9, 11)
    if painted_patches.is_empty():
        forest_cache_dirty = true
        # Paint the landing area in one pass while the transition is covered.
        outdoor_terrain.paint_ground(Rect2(Vector2(first) * TERRAIN_PATCH_SIZE,
            Vector2(size) * TERRAIN_PATCH_SIZE))
        for x in range(first.x, first.x + size.x):
            for y in range(first.y, first.y + size.y):
                painted_patches[Vector2i(x, y)] = true
    else:
        for x in range(first.x, first.x + size.x):
            for y in range(first.y, first.y + size.y):
                _paint_forest_patch(Vector2i(x, y))

func _paint_forest_patch(key: Vector2i) -> void:
    if painted_patches.has(key):
        return
    outdoor_terrain.paint_ground(Rect2(Vector2(key) * TERRAIN_PATCH_SIZE, TERRAIN_PATCH_SIZE), true)
    painted_patches[key] = true
    forest_cache_dirty = true

func _queue_forest_terrain() -> void:
    var center := Vector2i((Vector2(player.position) / TERRAIN_PATCH_SIZE).floor())
    if center != terrain_center:
        terrain_center = center
        terrain_patches.clear()
        for offset in terrain_patch_offsets:
            var key := center + offset
            if not painted_patches.has(key):
                terrain_patches.append(key)
func _stream_east_pinewood() -> void:
    if is_instance_valid(outdoor_terrain):
        _queue_forest_terrain()
    forest_woodland.update_player_chunk()
    # Tile updates and attaching tree scenes can both do work at frame end.
    # When both queues have work, give each its own frame.
    if not terrain_patches.is_empty() and (forest_woodland.pending_chunks.is_empty() or Engine.get_process_frames() % 2 == 0):
        _paint_forest_patch(terrain_patches.pop_back())
    else:
        forest_woodland.stream_next_trees()

func _add_point(action: String, title: String, where: Vector2) -> Point:
    var point := POINT_SCENE.instantiate() as Point
    point.action_id = action
    point.title = title
    point.position = where
    if action == "ancient_ruin" and region == "east_pinewood":
        point.radius = 145.0
    elif action == "cellar_gate" and region == "stonehaven":
        point.radius = 95.0
    elif action in ["grimoire", "replay_grimoire"]:
        point.radius = 120.0
        point.z_index = 12
    elif action == "crypt_approach" and region == "graveyard":
        point.radius = 115.0
    props.add_child(point)
    points.append(point)
    if action != "cellar_gate" and (Layouts.REGIONS.has(action) or action == "main_gate"):
        var hidden := action in ["hideout", "oath_vault", "goblin_hollow"] or region in ["cellar_gate", "hideout", "oath_vault"]
        var glow := InteractionArt.add_entrance_glow(point, Vector2.ZERO, hidden)
        glow.z_as_relative = false
    return point

func _add_herb_art(herb: Point) -> void:
    var leaves := Sprite2D.new()
    leaves.texture = WayfindingArt._texture("res://art/items/guild_herbs.png")
    if leaves.texture != null:
        leaves.scale = Vector2.ONE * (28.0 / leaves.texture.get_height())
    leaves.position.y = -5
    herb.add_child(leaves)

func _update_quest_markers() -> void:
    var guild_turn_in := state.lord_stage == "locked" and state.guild_assignments_complete()
    var guild_offer := (state.guild_rank.is_empty() and ((rite_completed and guild_referral_accepted) or not linked_from_gate)) \
        or (not state.guild_rank.is_empty() and state.guild_accepted.size() < State.GUILD_CONTRACTS.size())
    InteractionArt.update_quest_marker(guild_master, guild_offer, guild_turn_in)
    var mentor_ready := state.mentorship_year < 5 and state.mentorship_focus.is_empty()
    var mentor_turn_in := ("mentor_task_%d" % state.mentorship_year) in state.quest_items
    InteractionArt.update_quest_marker(city_lord, state.lord_stage in ["summoned", "share_offer", "share"]
        or (state.mentorship_faction == "lord" and mentor_ready),
        state.lord_stage == "report" or (state.mentorship_faction == "lord" and mentor_turn_in))
    InteractionArt.update_quest_marker(church_priest, state.lord_stage == "share"
        or (state.mentorship_faction == "church" and mentor_ready),
        state.mentorship_faction == "church" and mentor_turn_in)
    InteractionArt.update_quest_marker(watch_captain, false, state.guild_provisions and not state.guild_watch_supplied)
    InteractionArt.update_quest_marker(emissary_actor, state.emissary_pending)
    var ledger_ready := state.initiation == "active" and State.LEDGER in state.quest_items
    InteractionArt.update_quest_marker(veiled_agent, state.initiation == "available" or state.lord_stage == "share"
        or (state.mentorship_faction == "black_hand" and mentor_ready),
        ledger_ready or (state.mentorship_faction == "black_hand" and mentor_turn_in))

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
        "ancient_ruin", "ruin_lower", "ruin_sanctum":
            _dress_ruins()
        "northern_watch":
            var captain_position := Vector2(95, -43)
            watch_captain = _add_npc("guard_sword", captain_position, 1)
            if is_instance_valid(watch_captain):
                watch_captain.autonomous_patrol = false
            _add_point("deliver_provisions", "Watch Captain", captain_position)
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
    InteractionArt.add_entrance_glow(props, Layouts.STONEHAVEN_DRAIN, true)
    quiet_finn = _add_npc("elder", Vector2(-646, 390), 5)
    if is_instance_valid(quiet_finn):
        quiet_finn.autonomous_patrol = false
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
    church_priest = _add_npc("priest", Vector2(238, -178))
    _add_local_npc("monk", Vector2(354, -118), 2)
    city_lord = _add_npc("noble", Vector2(-255, -178))
    _add_local_npc("sweeper", Vector2(-212, 131), 2)
    _add_local_npc("dockhand", Vector2(403, 145), 5)
    guild_master = _add_npc("noble", Vector2(-260, 360), 2)
    if is_instance_valid(guild_master):
        guild_master.autonomous_patrol = false
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

func _dress_ruins() -> void:
    ruin_walls = Ruins.walls(region)
    for wall in ruin_walls:
        WorldCollision.box(props, "RuinMasonry", wall)
    if RUIN_TREASURE.has(region):
        var treasure: Array = RUIN_TREASURE[region]
        var where: Vector2 = treasure[0]
        var opened: bool = treasure[1] in state.quest_items
        var chest := Prop.place(props, "inns/chest", where, Vector2(52, 26), player)
        if opened and chest != null:
            chest.modulate = Color("#8d8880")
        _add_point("ruin_chest", "Search the old chest", where + Vector2(0, 12))
    match region:
        "ancient_ruin":
            Prop.place(props, "crypts/sarcophagus_cracked", Vector2(-470, 310), Vector2(100, 42), player)
            Prop.place(props, "crypts/web_left", Vector2(-715, -340))
            Prop.place(props, "crypts/altar_clean", Vector2(0, -311), Vector2(90, 34), player)
        "ruin_lower":
            Prop.place(props, "crypts/cage_rusted", Vector2(-617, 301), Vector2(62, 43), player)
            Prop.place(props, "crypts/bone_pile", Vector2(-372, -308), Vector2.ZERO, null, -4)
            Prop.place(props, "crypts/sarcophagus_cracked", Vector2(18, -277), Vector2(100, 42), player)
        "ruin_sanctum":
            Prop.place(props, "crypts/altar_clean", Ruins.RELIC - Vector2(0, 8), Vector2(96, 38), player)
            for at in [Vector2(-205, -193), Vector2(205, -193), Vector2(-335, 158), Vector2(335, 158)]:
                Prop.place(props, "crypts/wax_candles", at)
                Prop.loop(props, "candle", at - Vector2(0, 24), 5.0)
            var seal := Prop.place(props, "crypts/rune_decal", Vector2(0, 43), Vector2.ZERO, null, -5)
            if seal != null:
                seal.modulate = Color("#9290b3")

func _dress_east_pinewood() -> void:
    if _add_art(LANDMARK_ROOT + "awakening_ruins.png", Ruins.ENTRANCE + Vector2(0, 15), 330):
        for x in [-99, 99]:
            WorldCollision.box(props, "RuinButtress", Rect2(Ruins.ENTRANCE + Vector2(x - 30, -48), Vector2(60, 57)))
        WorldCollision.box(props, "RuinBackWall", Rect2(Ruins.ENTRANCE + Vector2(-129, -90), Vector2(258, 34)))
    _add_art("res://art/wayfinding/trail_gate.png", Overworld.FOREST_WEST + Vector2(0, 27), 225)
    _add_art("res://art/wayfinding/stonehaven_sign.png", Overworld.FOREST_WEST + Vector2(-132, 53), 88)
    _add_landmark("caravan", Overworld.CARAVAN, 350)
    _add_landmark("watchtower", Overworld.WATCH, 229)
    _add_landmark("crypt", Overworld.CRYPT, 260)
    _add_landmark("cabin", Overworld.CABIN, 265)
    _add_landmark("way_shrine", Overworld.SHRINE, 111)
    for offset in [Vector2(-185, 31), Vector2(172, 23), Vector2(-222, -79), Vector2(158, -94)]:
        _add_landmark("grave_markers", Overworld.CRYPT + offset, 125)
    if is_instance_valid(forest_woodland):
        forest_woodland.process_mode = Node.PROCESS_MODE_INHERIT
        forest_woodland.resume_at_player()
        forest_woodland.show()
    else:
        forest_woodland = PinewoodWoodland.new()
        forest_woodland.player = player
        props.add_child(forest_woodland)

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
    var point := _add_point(action, dialogue[0], where)
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
    if player.choosing_race or inventory.quest_offer.visible or inventory.inventory_open or journal_panel.visible or grimoire_dialog.visible or mentor_dialog.visible or guild_dialog.visible or health <= 0:
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
        if point.action_id == "ancient_ruin" and region == "east_pinewood":
            hit = Rect2(point.position - Vector2(160, 270), Vector2(320, 289))
        if point.action_id.begins_with("herb_"):
            hit = Rect2(point.position - Vector2(24, 24), Vector2(48, 48))
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
    if enemy.encounter_id == "ruin_warden":
        enemy.sprite_scale = 1.42
        enemy.sprite_tint = Color("#bdc9dc")
    enemy.defeated.connect(_on_victory)
    enemy.attack_landed.connect(_take_damage)
    props.add_child(enemy)

func _bring_emissary() -> void:
    if is_instance_valid(emissary):
        return
    var where: Vector2 = player.position.move_toward(Vector2.ZERO, 36) + Vector2(50, 0)
    emissary = _add_point("emissary", "Black Hand Emissary", _bounded(where))
    emissary.radius = 96
    emissary_actor = _add_npc("black_hand_duelist", emissary.position)
    if is_instance_valid(emissary_actor):
        emissary_actor.autonomous_patrol = false
        InteractionArt.update_quest_marker(emissary_actor, true)

func _remove_emissary() -> void:
    if is_instance_valid(emissary):
        points.erase(emissary)
        emissary.queue_free()
        emissary = null
    if is_instance_valid(emissary_actor):
        emissary_actor.queue_free()
        emissary_actor = null

func _process(_delta: float) -> void:
    if region == "east_pinewood":
        _stream_east_pinewood()
    if inventory.inventory_open:
        journal_panel.hide()
    var blocked: bool = player.choosing_race or inventory.quest_offer.visible or inventory.inventory_open or journal_panel.visible or grimoire_dialog.visible or mentor_dialog.visible or guild_dialog.visible
    player.set_physics_process(not blocked)
    if is_instance_valid(enemy):
        enemy.target = null if blocked or health <= 0 or not _can_reach_enemy() else player
    inventory.update_resource_bars(health, _effective_max_health(), mana, State.MAX_MANA)
    var point := _nearest_point()
    var prompt := "Approach a doorway or person to interact." if point == null else "E  %s" % point.title
    hud.text = "%s  |  HP %d/%d  |  Mana %d/%d  |  Level %d\n%s\nLMB / Space attack  ·  RMB / F Fireball  ·  L grimoire  ·  Q summon  ·  J journal  ·  I inventory\n%s" % [
        Layouts.REGIONS[region]["title"], health, _effective_max_health(), floori(mana), State.MAX_MANA, state.level(), prompt, notice
    ]
    if journal_panel.visible:
        journal_text.text = "%s\n%d XP  ·  %d unspent character points  ·  Conjuration rank %d (%d casts)\nBlack Hand reputation %d%s\n\nJ or Esc to close" % [
            state.journal() + "\n\nAdventurer's Guild\n" + state.guild_journal(), state.experience, state.training_points(),
            state.conjuration_rank(), state.conjuration_uses, state.black_hand_reputation(),
            "  ·  Entry by %s" % state.entry_method if not state.entry_method.is_empty() else ""
        ]

func _physics_process(delta: float) -> void:
    player.position = _bounded(player.position)
    if player.choosing_race or inventory.quest_offer.visible or inventory.inventory_open or journal_panel.visible or grimoire_dialog.visible or health <= 0:
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
    if _can_reach_enemy() and enemy.position.distance_to(player.position) <= 210.0:
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
        enemy.take_hit(9 + 3 * state.mentorship_history.count("Necromancy"))

func _bounded(where: Vector2) -> Vector2:
    var bounds := Ruins.bounds(region) if Ruins.ROOMS.has(region) else Overworld.bounds(region, Floor.BOUNDS)
    return where.clamp(bounds.position + Vector2(20, 28), bounds.end - Vector2(20, 20))

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if player.choosing_race or inventory.quest_offer.visible or inventory.inventory_open or health <= 0:
        return
    if guild_dialog.visible:
        if event.keycode == KEY_ESCAPE:
            guild_dialog.hide()
        get_viewport().set_input_as_handled()
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
        var lines: Array = local_dialogue[action]
        inventory.show_person_dialogue(lines[0], lines[1], local_npcs[action])
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
        if is_instance_valid(watch_captain):
            watch_captain.interact()
        if state.guild_provisions and not state.guild_watch_supplied and "watch_provisions" in inventory.backpack:
            state.guild_provisions = false
            state.guild_watch_supplied = true
            state.quest_items.erase("watch_provisions")
            inventory.remove_item("watch_provisions")
            notice = "The watch captain accepts the guild provisions. The guards will have enough to last another week. Return to the Guild Master."
            _save()
        elif state.guild_watch_supplied:
            notice = "The watchtower has already received its supplies."
        else:
            notice = "Watch Captain — Speak with the Guild Master if you're here about our provisions."
        _show_speaker("Watch Captain", watch_captain)
        return
    if action == "ruin_chest" and RUIN_TREASURE.has(region):
        var item_id: String = RUIN_TREASURE[region][1]
        _take_item(item_id, "Found %s in the old chest." % Layouts.ITEMS[item_id]["name"])
        return
    if action == "ancient_stone":
        if not sentinel_defeated_this_visit:
            notice = "The Waking Sentinel stands between you and the stone."
        elif state.lord_stage == "ruin":
            var needed := int("ancient_magic_stone" not in inventory.backpack) + int("sentinel_sword" not in inventory.backpack)
            if inventory.backpack.size() + needed > inventory.BACKPACK_CAPACITY:
                notice = "Make room for the inscribed stone and longsword before taking them."
                return
            state.lord_stage = "report"
            if inventory.grant_item("ancient_magic_stone", Layouts.ITEMS["ancient_magic_stone"]):
                state.quest_items.append("ancient_magic_stone")
            if inventory.grant_item("sentinel_sword", Layouts.ITEMS["sentinel_sword"]):
                state.quest_items.append("sentinel_sword")
            notice = "You recover a magic stone and the Sentinel's Longsword. The engraving reads: Magic is our hope. It has the power to set us free. As it awakens, the world will change. Return to Stonehaven's lord."
            _save()
        else:
            notice = "You have already taken the ancient stone."
        return
    if action == "adventurers_guild":
        if is_instance_valid(guild_master):
            guild_master.interact()
        _show_guild_dialog()
        return
    if action.begins_with("herb_"):
        if region != "east_pinewood" or "herbs" not in state.guild_accepted:
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
            inventory.show_quest_handoff("Investigate the Awakening Ruins",
                "We’re short of capable hands. A strange ruin in East Pinewood is drawing travelers to it. Will you investigate and return with what you discover?",
                city_lord, _accept_ruins_quest)
            return
        elif state.lord_stage == "report":
            state.lord_stage = "share_offer"
            inventory.gold += 50
            inventory._refresh_inventory()
            _save()
            _show_prophecy_referral(true)
            return
        elif state.lord_stage == "share_offer":
            _show_prophecy_referral()
            return
        elif state.lord_stage == "share" or state.mentorship_faction == "lord":
            _offer_mentor("lord")
            return
        else:
            notice = "Lord of Stonehaven — The city has burdens enough. Earn the Guild Master's trust and return."
        _save()
        _show_speaker("Lord of Stonehaven", city_lord)
        return
    if action == "church_mentor":
        if state.lord_stage == "share" or state.mentorship_faction == "church":
            _offer_mentor("church")
        else:
            notice = "Priest — May you find wisdom in your journeys. Bring the ancient stone's prophecy to us if you learn more."
            _show_speaker("Priest", church_priest)
        return
    match action:
        "main_gate":
            return_to_gate.emit()
        "inspect_caravan":
            if "caravan" in state.guild_accepted:
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
            _show_speaker("Quiet Finn", quiet_finn)
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
            _show_speaker("Emissary", emissary_actor)
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
    if destination == "ancient_ruin" and state.lord_stage not in ["ruin", "report", "share_offer", "share"] and state.mentorship_faction.is_empty():
        notice = "The ruin is sealed. The Lord of Stonehaven may know more."
    elif destination == "ruin_sanctum" and "ruin_seal_guard" not in state.defeated and "ruin_warden" not in state.defeated:
        notice = "The Sealkeeper bars the sanctum. Defeat it to break the seal."
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

func _accept_ruins_quest() -> void:
    if state.lord_stage == "summoned":
        state.lord_stage = "ruin"
        _save()

func _show_prophecy_referral(reward_just_claimed := false) -> void:
    var coin: Dictionary = inventory.GOLD_REWARD.duplicate()
    coin["name"] = "50 gold"
    inventory.show_quest_handoff("Share the Prophecy",
        "You’ve done Stonehaven a service. The inscription says magic may set us free as the world awakens. Take this knowledge to the church. Our swordmasters and mages can also train you without an oath to my army.",
        city_lord, _accept_prophecy_referral, null, {"quest_gold": coin} if reward_just_claimed else {})

func _accept_prophecy_referral() -> void:
    if state.lord_stage == "share_offer":
        state.lord_stage = "share"
        _save()

func _accept_black_hand_initiation() -> void:
    state.start_initiation()
    _save()

func _speak_to_agent() -> void:
    if (state.lord_stage == "share" or state.mentorship_faction == "black_hand") and not state.entry_method.is_empty():
        _offer_mentor("black_hand")
        return
    if is_instance_valid(veiled_agent):
        veiled_agent.interact()
    match state.initiation:
        "available":
            var words := "The guard was your trial. A guard who cannot survive has no place here." if state.entry_method == "guard" else "No banners. No sermons. We work in the spaces between kingdoms."
            inventory.show_quest_handoff("Black Hand Initiation",
                words + "\n\nRecover the sealed ledger from the oath vault and bring it back unopened to earn membership.",
                veiled_agent, _accept_black_hand_initiation)
            return
        "active":
            if state.finish_initiation():
                inventory.remove_item(State.LEDGER)
                notice = "Veiled Agent — You kept it sealed. You are Black Hand now. (+10 reputation)"
                _save()
            else:
                notice = "Veiled Agent — The ledger is still in the oath vault."
        "complete":
            notice = "Veiled Agent — Welcome back, Black Hand."
        _:
            return
    _show_speaker("Veiled Agent", veiled_agent)

func _show_speaker(title: String, actor: Node) -> void:
    inventory.show_person_dialogue(title, notice.trim_prefix(title + " — "), actor)

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

func _build_guild_dialog() -> void:
    guild_dialog = CenterContainer.new()
    $HUD.add_child(guild_dialog)
    guild_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    guild_dialog.visibility_changed.connect(func() -> void:
        inventory.set_process_unhandled_key_input(not guild_dialog.visible)
    )
    var panel := DialoguePanel.new()
    guild_dialog.add_child(panel)
    panel.build(guild_dialog.hide)
    panel.title.text = "Adventurer's Guild"
    guild_portrait = panel.portrait
    guild_details = panel.details
    guild_rank_label = Label.new()
    guild_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    panel.header.add_child(guild_rank_label)
    guild_cards = VBoxContainer.new()
    guild_cards.add_theme_constant_override("separation", 6)
    panel.content.add_child(guild_cards)
    var icons := {
        "caravan": "res://art/landmarks/caravan.png",
        "provisions": "res://art/interiors/shops/sacks.png",
        "herbs": "res://art/items/guild_herbs.png",
    }
    for contract: String in State.GUILD_CONTRACTS:
        _add_guild_card(contract, icons[contract])
    guild_confirm = Button.new()
    InventoryFinish.style_dialog_action(guild_confirm)
    guild_confirm.pressed.connect(_confirm_guild_dialog)
    panel.content.add_child(guild_confirm)
    guild_dialog.hide()

func _add_guild_card(contract: String, icon_path: String) -> void:
    var frame := PanelContainer.new()
    frame.add_theme_stylebox_override("panel",
        InventoryFinish.surface(InventoryFinish.RECESS, InventoryFinish.BRASS, 8, true))
    guild_cards.add_child(frame)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    frame.add_child(row)
    var illustration := TextureRect.new()
    illustration.texture = WayfindingArt._texture(icon_path)
    illustration.custom_minimum_size = Vector2(64, 60)
    illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    row.add_child(illustration)
    var text := VBoxContainer.new()
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(text)
    var title := Label.new()
    ElderwoodType.heading(title)
    title.text = State.GUILD_CONTRACTS[contract][0]
    title.add_theme_font_size_override("font_size", 17)
    title.add_theme_color_override("font_color", InventoryFinish.GOLD)
    text.add_child(title)
    var objective := Label.new()
    objective.text = State.GUILD_CONTRACTS[contract][1]
    objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text.add_child(objective)
    var status := Label.new()
    status.add_theme_font_size_override("font_size", 13)
    text.add_child(status)
    guild_status[contract] = status
    var accept := Button.new()
    accept.text = "Accept"
    accept.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    accept.custom_minimum_size.x = 86
    InventoryFinish.style_dialog_action(accept)
    accept.pressed.connect(_accept_guild_contract.bind(contract))
    row.add_child(accept)
    guild_accept_buttons[contract] = accept

func _show_guild_dialog() -> void:
    guild_portrait.show_speaker(guild_master, null, true)
    var registered := not state.guild_rank.is_empty()
    guild_rank_label.text = "%s-Rank Adventurer" % state.guild_rank if registered else "Registration"
    guild_cards.visible = registered
    guild_confirm.hide()
    if not registered:
        if linked_from_gate and (not rite_completed or not guild_referral_accepted):
            guild_details.text = "Speak with Elder Elden in Elderwood Village and accept his referral. Then I’ll put your name on the roll."
        else:
            guild_details.text = "Register as a D-rank adventurer to take on three contracts in East Pinewood."
            guild_confirm.text = "Register as D-rank"
            guild_confirm.show()
    else:
        for contract: String in State.GUILD_CONTRACTS:
            guild_status[contract].text = state.guild_contract_status(contract)
            var accept: Button = guild_accept_buttons[contract]
            accept.disabled = contract in state.guild_accepted
            accept.text = "Accepted" if accept.disabled else "Accept"
        guild_details.text = "Accept and complete the contracts in any order."
        if state.lord_stage != "locked":
            guild_details.text = state.guild_journal()
        elif state.guild_assignments_complete():
            guild_details.text = "All three contracts are complete. The Lord of Stonehaven requests an audience at his manor."
            guild_confirm.text = "Accept Audience"
            guild_confirm.show()
        elif state.guild_provisions and "watch_provisions" not in inventory.backpack:
            guild_confirm.text = "Collect watchtower provisions"
            guild_confirm.show()
    guild_dialog.show()

func _issue_guild_parcel() -> bool:
    if not inventory.grant_item("watch_provisions", Layouts.ITEMS["watch_provisions"]):
        guild_details.text = "Make room in your backpack for the watchtower parcel."
        return false
    if "watch_provisions" not in state.quest_items:
        state.quest_items.append("watch_provisions")
    return true

func _accept_guild_contract(contract: String) -> void:
    if not guild_dialog.visible or state.guild_rank.is_empty() or not State.GUILD_CONTRACTS.has(contract) or contract in state.guild_accepted:
        return
    if contract == "provisions":
        if not _issue_guild_parcel():
            return
        state.guild_provisions = true
    state.guild_accepted.append(contract)
    _save()
    _show_guild_dialog()

func _confirm_guild_dialog() -> void:
    if not guild_dialog.visible or not guild_confirm.visible:
        return
    if state.guild_rank.is_empty():
        if linked_from_gate and (not rite_completed or not guild_referral_accepted):
            return
        state.guild_rank = "D"
    elif state.lord_stage == "locked" and state.guild_assignments_complete():
        state.lord_stage = "summoned"
    elif not _issue_guild_parcel():
        return
    _save()
    _show_guild_dialog()

func _build_mentor_dialog() -> void:
    mentor_dialog = CenterContainer.new()
    $HUD.add_child(mentor_dialog)
    mentor_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := DialoguePanel.new()
    mentor_dialog.add_child(panel)
    panel.build(mentor_dialog.hide)
    mentor_heading = panel.title
    mentor_details = panel.details
    mentor_portrait = panel.portrait
    mentor_choices = VBoxContainer.new()
    panel.content.add_child(mentor_choices)
    mentor_dialog.hide()

func _mentor_actor(faction: String) -> Node2D:
    match faction:
        "church": return church_priest
        "black_hand": return veiled_agent
        _: return city_lord

func _offer_mentor(faction: String) -> void:
    var actor := _mentor_actor(faction)
    var title := Mentorship.mentor(faction)
    if not state.mentorship_faction.is_empty() and state.mentorship_faction != faction:
        notice = "Your apprenticeship is already pledged to %s. You may still study other disciplines later." % Mentorship.mentor(state.mentorship_faction)
        _show_speaker(title, actor)
        return
    if state.mentorship_year >= 5:
        notice = "%s — Five years have passed. You are twenty now. Your apprenticeship is complete, but the world still has much to teach." % Mentorship.mentor(faction)
        _show_speaker(title, actor)
        return
    var task_key := "mentor_task_%d" % state.mentorship_year
    if task_key in state.quest_items:
        state.quest_items.erase(task_key)
        state.mentorship_year += 1
        state.player_age += 1
        state.experience += 60
        state.mentorship_history.append(state.mentorship_focus)
        if state.mentorship_focus == "Healing":
            health += 5
        state.mentorship_focus = ""
        _save()
        if state.mentorship_year >= 5:
            state.lord_stage = "prologue_complete"
            notice = "Five years have passed. You are now twenty years old. %s has trained you through five assignments. Your journey truly begins. (+60 XP)" % Mentorship.mentor(faction)
            _save()
            _show_speaker(title, actor)
            return
        notice = "Year %d complete. A year passes in training under %s. (+60 XP) Choose your focus for your next year." % [state.mentorship_year, Mentorship.mentor(faction)]
    elif not state.mentorship_focus.is_empty():
        var mission: Array = Mentorship.mission(faction, state.mentorship_year)
        notice = "%s — Your assignment: %s. %s" % [Mentorship.mentor(faction), str(mission[2]), str(mission[3])]
        _show_speaker(title, actor)
        return
    pending_mentor = faction
    mentor_heading.text = Mentorship.mentor(faction)
    mentor_details.text = "Year %d of five. Choose a discipline to emphasize this year. Training will advance your character without locking away other schools. Complete the assigned field quest and return to your mentor for the next time skip." % [state.mentorship_year + 1]
    for child in mentor_choices.get_children():
        child.queue_free()
    for focus in Mentorship.focuses(faction):
        var button := Button.new()
        InventoryFinish.style_dialog_action(button)
        button.text = str(focus)
        button.pressed.connect(_preview_mentor_assignment.bind(str(focus)))
        mentor_choices.add_child(button)
    mentor_portrait.show_speaker(actor, null, true)
    mentor_dialog.show()

func _preview_mentor_assignment(focus: String) -> void:
    var mission: Array = Mentorship.mission(pending_mentor, state.mentorship_year)
    if mission.is_empty():
        return
    mentor_dialog.hide()
    inventory.show_quest_handoff(str(mission[2]), "Training focus: %s\n\n%s" % [focus, str(mission[3])],
        _mentor_actor(pending_mentor), _choose_mentor_focus.bind(focus))

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
    _show_speaker(Mentorship.mentor(state.mentorship_faction), _mentor_actor(state.mentorship_faction))

func _build_grimoire_dialog() -> void:
    grimoire_dialog = CenterContainer.new()
    grimoire_dialog.visibility_changed.connect(func() -> void:
        inventory.set_process_unhandled_key_input(not grimoire_dialog.visible)
    )
    $HUD.add_child(grimoire_dialog)
    grimoire_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := DialoguePanel.new()
    grimoire_dialog.add_child(panel)
    panel.build(grimoire_dialog.hide)
    panel.portrait.show_speaker(null, WayfindingArt._texture("res://art/interiors/crypts/grimoire_open.png"))
    grimoire_heading = panel.title
    grimoire_details = panel.details
    var actions := HBoxContainer.new()
    actions.alignment = BoxContainer.ALIGNMENT_END
    panel.content.add_child(actions)
    for choice in [["Destroy", "destroy"], ["Take", "take"], ["Study", "study"], ["Decide later", "later"]]:
        var button := Button.new()
        InventoryFinish.style_dialog_action(button)
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

func _can_reach_enemy() -> bool:
    if not is_instance_valid(enemy):
        return false
    if not Ruins.ROOMS.has(region):
        return true
    var origin: Vector2 = player.position
    for wall in ruin_walls:
        if Geometry2D.segment_intersects_segment(origin, enemy.position, wall.position, Vector2(wall.end.x, wall.position.y)) != null \
            or Geometry2D.segment_intersects_segment(origin, enemy.position, wall.end, Vector2(wall.position.x, wall.end.y)) != null \
            or Geometry2D.segment_intersects_segment(origin, enemy.position, wall.position, Vector2(wall.position.x, wall.end.y)) != null \
            or Geometry2D.segment_intersects_segment(origin, enemy.position, wall.end, Vector2(wall.end.x, wall.position.y)) != null:
            return false
    return true

func _attack(cursor := Vector2.INF) -> void:
    if attack_wait > 0.0:
        return
    attack_wait = 0.32
    var aim: Vector2 = player.facing if cursor == Vector2.INF else player.position.direction_to(cursor)
    if _can_reach_enemy() and enemy.position.distance_to(player.position) <= 84:
        aim = player.position.direction_to(enemy.position)
    player.play_strike(aim, true)
    if _can_reach_enemy() and enemy.position.distance_to(player.position) <= 72:
        enemy.take_hit(9 + player.attack_bonus + state.mentorship_history.count("Swordsmanship") + state.mentorship_history.count("Paladin Combat"))
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
    if _can_reach_enemy() and player.position.distance_to(enemy.position) < 460:
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
            enemy.take_hit(17 + 2 * (state.mentorship_history.count("Elemental Magic") + state.mentorship_history.count("Radiance") + state.mentorship_history.count("Blood Magic")))
            health = mini(_effective_max_health(), health + state.mentorship_history.count("Blood Magic"))
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
    if encounter_id == "ruin_warden":
        sentinel_defeated_this_visit = true
    state.record_victory(encounter_id, reward_xp)
    if encounter_id == "ruin_warden" and region == "ruin_sanctum" and state.lord_stage == "ruin":
        _add_point("ancient_stone", "Recover the stone and longsword", Ruins.RELIC)
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

func _effective_max_health() -> int:
    return MAX_HEALTH + 5 * state.mentorship_history.count("Healing")

func _take_damage(amount: int) -> void:
    var wards := state.mentorship_history.count("Wardcraft") + state.mentorship_history.count("Sacred Wards") + state.mentorship_history.count("Forbidden Wards")
    health = maxi(0, health - maxi(1, amount - player.defense_bonus - wards))
    if health == 0:
        call_deferred("_recover_at_graveyard")

func _recover_at_graveyard() -> void:
    health = _effective_max_health()
    mana = State.MAX_MANA
    summon_remaining = 0.0
    summon_windup = 0.0
    summon.hide()
    player.cancel_cast_pose()
    _load_region("graveyard")
    notice = "You recover at the graveyard entrance. Your quest progress is intact."

func _save() -> void:
    _update_quest_markers()
    if playthrough_progress != null:
        state.write_progress(playthrough_progress)
    elif can_save and state.save_progress(save_path) != OK:
        notice += " Chapter progress could not be saved."
