extends RefCounted

const State := preload("res://scripts/frontier/adventure_state.gd")
const Layouts := preload("res://scripts/frontier/chapter_regions.gd")
const SLOT_COUNT := 3
const VERSION := 1

static func read_slot(slot: int) -> ConfigFile:
    var file := ConfigFile.new()
    if file.load(slot_path(slot)) != OK or file.get_value("save", "version", 0) != VERSION:
        return null
    var location: String = file.get_value("world", "location", "")
    if location not in ["village", "inn", "pinewood"] and not Layouts.REGIONS.has(location):
        return null
    if file.has_section("chapter") and State.new().read_progress(file) != OK:
        return null
    return file

static func slot_path(slot: int) -> String:
    return "user://elderwood_slot_%d.cfg" % slot

static func write_slot(village: Node, slot: int) -> Error:
    var file: ConfigFile = village.playthrough_progress
    var actor: Node = village.player
    var inventory := village
    var location := "inn" if village.inside_inn else "village"
    var resources: Vector2 = village.gate_resources
    var chapter: Node = village.chapter
    if is_instance_valid(chapter):
        chapter.state.write_progress(file)
        actor = chapter.player
        inventory = chapter.inventory
        location = chapter.region
        resources = Vector2(chapter.health, chapter.mana)
        file.set_value("world", "crypt_defeats", chapter.crypt_defeated_this_visit)
        file.set_value("world", "sentinel_defeated", chapter.sentinel_defeated_this_visit)
    elif is_instance_valid(village.forest) and village.forest.active:
        location = "pinewood"
        resources = Vector2(village.forest.health, village.forest.mana)
    file.set_value("save", "version", VERSION)
    file.set_value("save", "timestamp", Time.get_unix_time_from_system())
    file.set_value("world", "location", location)
    file.set_value("world", "position", actor.position)
    file.set_value("world", "resources", resources)
    file.set_value("world", "gate_resources", village.gate_resources)
    file.set_value("world", "race", actor.race)
    file.set_value("world", "necromancer_art", actor.necromancer_appearance_enabled)
    file.set_value("world", "road_quest", village.road_quest)
    file.set_value("world", "wolves", village.defeated_wolves)
    file.set_value("inventory", "gold", inventory.gold)
    file.set_value("inventory", "equipment", inventory.equipment)
    file.set_value("inventory", "backpack", inventory.backpack)
    file.set_value("inventory", "item_data", inventory.item_data)
    return State.write_file(file, slot_path(slot))

static func restore(village: Node, file: ConfigFile) -> void:
    village.playthrough_progress = file
    village.road_quest = file.get_value("world", "road_quest", 0)
    village.defeated_wolves.assign(file.get_value("world", "wolves", []))
    village.opening_greeting_shown = village.road_quest != village.RoadQuest.OFFERED
    village._update_pip_marker()
    village.gold = file.get_value("inventory", "gold", village.gold)
    village.equipment = file.get_value("inventory", "equipment", village.equipment)
    village.backpack.assign(file.get_value("inventory", "backpack", village.backpack))
    village.item_data = file.get_value("inventory", "item_data", village.item_data)
    village._refresh_inventory()
    var actor: Node = village.player
    actor.necromancer_appearance_enabled = file.get_value("world", "necromancer_art", false)
    actor._choose_race(file.get_value("world", "race", "Human"))
    actor.set_equipment(village.equipment)
    var location: String = file.get_value("world", "location", "village")
    var resources: Vector2 = file.get_value("world", "resources", Vector2.ZERO)
    village.gate_resources = file.get_value("world", "gate_resources", Vector2.ZERO)
    match location:
        "inn":
            village._enter_inn_now()
        "pinewood":
            village._enter_pinewood_now()
            village.forest.health = int(resources.x)
            village.forest.mana = resources.y
        "village":
            pass
        _:
            var scene := load(village.FORSAKEN_CHAPTER) as PackedScene
            var chapter := scene.instantiate()
            chapter.resume_region = location
            chapter.resume_position = file.get_value("world", "position", Vector2.INF)
            chapter.crypt_defeated_this_visit.assign(file.get_value("world", "crypt_defeats", []))
            chapter.sentinel_defeated_this_visit = file.get_value("world", "sentinel_defeated", false)
            village.chapter = chapter
            village._mount_chapter()
            actor = chapter.player
            chapter.health = int(resources.x)
            chapter.mana = resources.y
    if not Layouts.REGIONS.has(location):
        actor.position = file.get_value("world", "position", actor.position)
    actor.get_node("Camera2D").reset_smoothing()
