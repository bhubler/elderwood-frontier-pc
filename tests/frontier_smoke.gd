extends SceneTree
## Run with godot --headless --script res://tests/frontier_smoke.gd.
const CHAPTER := preload("res://scenes/frontier/forsaken_chapter.tscn")
const VILLAGE := preload("res://scenes/world.tscn")
const State := preload("res://scripts/frontier/adventure_state.gd")
var chapter
var failures := 0
var test_prefix := "user://frontier_smoke_%d" % OS.get_process_id()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    await _start_chapter("magic")
    _check(not chapter.state.spell_learned, "New chapter starts without the spell")
    _press(KEY_Q)
    _check(chapter.state.conjuration_uses == 0, "Unknown spell cannot cast")
    _at("crypt_approach")
    _at("crypt_ossuary")
    _at("crypt_ritual")
    _check(chapter.region == "crypt_ossuary", "Skeleton blocks the ritual chamber")
    _fight()
    _at("crypt_ritual")
    _at("grimoire")
    _check(chapter.state.quest_items.is_empty(), "Living Bonecaller protects grimoire")
    _fight()
    _at("grimoire")
    _at("grimoire")
    _check(chapter.inventory.backpack.count(State.GRIMOIRE) == 1, "Grimoire appears once in inventory")
    _press(KEY_L)
    chapter.mana = 44.0
    _press(KEY_Q)
    _check(chapter.state.conjuration_uses == 0, "Casting requires enough mana")
    chapter.mana = 100.0
    _check(chapter.state.spell_learned and not chapter.state.emissary_pending, "Learning alone does not call emissary")
    _press(KEY_Q)
    _press(KEY_Q)
    _check(chapter.state.emissary_pending and chapter.state.conjuration_uses == 1, "A valid cast calls emissary once")
    _check(is_equal_approx(chapter.mana, 55.0) and chapter.summon_remaining == 35.0, "Summon consumes 45 mana for 35 seconds")
    _at("emissary")
    _check(chapter.state.entry_method == "grimoire" and not chapter.state.emissary_pending, "Emissary grants cemetery admission")
    _at("crypt_ossuary")
    _at("crypt_approach")
    _at("graveyard")
    _at("stonehaven")
    _at("cellar_gate")
    _check(chapter.enemy == null, "Guard stands down after emissary admission")
    _at("hideout")
    _finish_shared_quest()
    await _reload_and_check("magic", "grimoire")
    await _start_chapter("guard")
    _at("stonehaven")
    _check(not chapter._cellar_marker_visible(), "Drainage door is hidden before discovery")
    _at("quiet_finn")
    _at("cellar_gate")
    _at("hideout")
    _check(chapter.region == "cellar_gate", "Interacting with the guarded door cannot bypass the trial")
    _fight()
    _check(chapter.state.entry_method == "guard", "Guard death grants trial admission")
    _at("hideout")
    _finish_shared_quest()
    await _reload_and_check("guard", "guard")
    await _check_village()
    if failures == 0:
        print("Frontier smoke passed for both routes, reloads and village.")
    quit(0 if failures == 0 else 1)

func _start_chapter(route: String) -> void:
    var path := test_prefix + "_" + route + ".cfg"
    DirAccess.remove_absolute(path)
    await _open(path)

func _open(path: String) -> void:
    chapter = CHAPTER.instantiate()
    chapter.save_path = path
    root.add_child(chapter)
    chapter.player._choose_race("High Elf")
    await process_frame

func _reload_and_check(route: String, method: String) -> void:
    var path := test_prefix + "_" + route + ".cfg"
    var xp: int = chapter.state.experience
    chapter.queue_free()
    await process_frame
    await _open(path)
    _check(chapter.state.entry_method == method, "Admission route survives reload")
    _check(chapter.state.initiation == "complete" and chapter.state.experience == xp, "Initiation and XP survive reload")
    _check(chapter.state.spell_learned == (route == "magic"), "Spell unlock survives reload")
    _check(chapter.inventory.backpack.has(State.GRIMOIRE) == (route == "magic"), "Quest inventory survives reload")
    _check(not chapter.state.emissary_pending and chapter.state.black_hand_reputation() == 10, "Completed route stays resolved")
    chapter.queue_free()
    await process_frame
    DirAccess.remove_absolute(path)

func _finish_shared_quest() -> void:
    _check(chapter.state.initiation == "available" and chapter.state.black_hand_reputation() == 0, "Access is separate from membership")
    _at("oath_vault")
    _check(chapter.region == "hideout", "Vault is locked before accepting initiation")
    _at("veiled_agent")
    _check(chapter.state.initiation == "active", "Agent starts shared initiation")
    _at("oath_vault")
    _at("ledger")
    _check(State.LEDGER not in chapter.state.quest_items, "Warden protects ledger")
    if chapter.summon_remaining > 0.0 and is_instance_valid(chapter.enemy):
        var enemy_health: int = chapter.enemy.health
        chapter.player.position = chapter.enemy.position
        chapter.summon.position = chapter.enemy.position
        chapter._physics_process(0.1)
        _check(chapter.enemy.health < enemy_health, "Summoned skeleton damages the active enemy")
        chapter._physics_process(35.0)
        _check(not chapter.summon.visible, "Summon expires")
    _fight()
    _at("ledger")
    _at("hideout")
    _at("veiled_agent")
    var xp: int = chapter.state.experience
    _at("veiled_agent")
    _check(chapter.state.initiation == "complete" and chapter.state.black_hand_reputation() == 10, "Delivery grants membership and reputation")
    _check(chapter.state.experience == xp and State.LEDGER not in chapter.inventory.backpack, "Delivery consumes ledger and rewards only once")

func _fight() -> void:
    _check(is_instance_valid(chapter.enemy), "Encounter spawns")
    if not is_instance_valid(chapter.enemy):
        return
    chapter.player.position = chapter.enemy.position
    for strike in range(12):
        if not is_instance_valid(chapter.enemy):
            return
        chapter._physics_process(0.33)
        _press(KEY_SPACE)
    _check(false, "Repeated in-range attacks defeat the enemy")

func _at(action: String) -> void:
    for point in chapter.points:
        if point.action_id == action:
            chapter.player.position = point.position
            _press(KEY_E)
            return
    _check(false, "Expected interaction marker %s in %s" % [action, chapter.region])

func _press(key: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = key
    event.pressed = true
    chapter._unhandled_key_input(event)

func _check_village() -> void:
    var village := VILLAGE.instantiate()
    root.add_child(village)
    await process_frame
    var player = village.get_node("Player")
    var interactions = village.get_node("VillageInteractions")
    _check(player.choosing_race and player.RACES.size() == 4, "Village retains four race choices")
    player._choose_race("Orc")
    interactions._select_item("rusty_sword")
    _check(player.race == "Orc" and player.attack_bonus == 3, "Village inventory still equips the sword")
    _check(village.has_node("InnInterior"), "Inn interior is attached to the village scene")
    interactions._enter_inn()
    _check(interactions.inside_inn, "The inn still opens")
    interactions._leave_inn()
    _check(not interactions.inside_inn, "The inn still returns to Elderwood Village")
    village.queue_free()
    await process_frame

func _check(condition: bool, detail: String) -> void:
    if not condition:
        failures += 1
        push_error(detail)
