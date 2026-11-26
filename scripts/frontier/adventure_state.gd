extends RefCounted
## Progress for the standalone frontier chapter. Stable IDs are saved with the chapter.
const VERSION := 1
const SPELL_ID := "summon_skeleton"
const SPELL_COST := 45
const SUMMON_SECONDS := 35.0
const MAX_MANA := 100
const GRIMOIRE := "forbidden_grimoire"
const LEDGER := "sealed_ledger"
const INITIATION := "black_hand_initiation"

var defeated: Array[String] = []
var quest_items: Array[String] = []
var entry_method := ""
var finn_contact := false
var emissary_pending := false
var spell_learned := false
var grimoire_choice := ""
var initiation := "locked"
var experience := 0
var conjuration_uses := 0
const GUILD_CONTRACTS := {
    "caravan": ["Raided Caravan", "Search the wreck and defeat the Blackbriar bandit and chief."],
    "provisions": ["Watchtower Provisions", "Take the guild parcel to the captain inside the eastern watchtower."],
    "herbs": ["Herbalist Requisition", "Gather ten woodland herbs in East Pinewood."],
}
var guild_accepted: Array[String] = []
var guild_rank := ""
var guild_provisions := false
var guild_caravan_inspected := false
var guild_watch_supplied := false
var guild_herbs := 0
var lord_stage := "locked"
var mentorship_faction := ""
var mentorship_year := 0
var mentorship_focus := ""
var mentorship_history: Array[String] = []
var player_age := 15
func caravan_assignment_complete() -> bool:
    return guild_caravan_inspected and "blackbriar_bandit" in defeated and "blackbriar_chief" in defeated

func guild_assignments_complete() -> bool:
    return not guild_rank.is_empty() and guild_accepted.size() == GUILD_CONTRACTS.size() \
        and caravan_assignment_complete() and guild_watch_supplied and guild_herbs >= 10

func guild_contract_status(contract: String) -> String:
    if contract not in guild_accepted:
        return "Available"
    match contract:
        "caravan":
            return "Complete" if caravan_assignment_complete() else "In progress"
        "provisions":
            return "Delivered" if guild_watch_supplied else "In progress"
        "herbs":
            return "%d / 10 collected" % guild_herbs
    return ""

func guild_contracts() -> String:
    var entries: PackedStringArray = []
    for contract: String in GUILD_CONTRACTS:
        entries.append("%s — %s" % [GUILD_CONTRACTS[contract][0], guild_contract_status(contract)])
    return "\n".join(entries)

func guild_journal() -> String:
    if guild_rank.is_empty():
        return "Register at Stonehaven's Adventurer's Guild as a D-rank adventurer."
    if lord_stage == "locked":
        var next_step := "Return to the Guild Master." if guild_assignments_complete() else "Accept and complete the three assignments in any order."
        return "%s\n%s" % [guild_contracts(), next_step]
    if lord_stage == "summoned":
        return "The Lord of Stonehaven requests your presence at his manor."
    if lord_stage in ["ruin", "report"]:
        return "Explore the mysterious ruin and report its ancient magic stone to the lord."
    if lord_stage == "share":
        return "Bring the prophecy to the church or a Black Hand contact and choose your mentor."
    if not mentorship_faction.is_empty():
        return "Apprenticeship year %d/5: %s, studying %s." % [mentorship_year, mentorship_faction, mentorship_focus]
    return "Continue your studies and quests."


func record_victory(encounter_id: String, reward_xp: int) -> void:
    if encounter_id in defeated:
        return
    defeated.append(encounter_id)
    experience += reward_xp

func enter_black_hand(method: String) -> bool:
    if not entry_method.is_empty():
        return false
    if method != "grimoire" and method != "guard":
        return false
    entry_method = method
    emissary_pending = false
    initiation = "available"
    return true

func learn_summon() -> bool:
    var newly_learned := not spell_learned
    grimoire_choice = "study"
    spell_learned = true
    emissary_pending = true
    return newly_learned

func record_summon() -> void:
    conjuration_uses += 1

func start_initiation() -> void:
    if initiation == "available":
        initiation = "active"

func finish_initiation() -> bool:
    if initiation != "active" or LEDGER not in quest_items:
        return false
    quest_items.erase(LEDGER)
    initiation = "complete"
    experience += 60
    return true

func level() -> int:
    return 1 + floori(experience / 100.0)

func training_points() -> int:
    return level() - 1

func conjuration_rank() -> int:
    return 1 + floori(conjuration_uses / 5.0)

func black_hand_reputation() -> int:
    return 10 if initiation == "complete" else 0

func journal() -> String:
    var graveyard := "Search the Crypt of the Bonecaller in the Forsaken Graveyard."
    if grimoire_choice == "destroy":
        graveyard = "You destroyed the forbidden grimoire."
    elif grimoire_choice == "take":
        graveyard = "You took the grimoire without studying it."
    elif GRIMOIRE in quest_items:
        graveyard = "Study the forbidden grimoire."
    if spell_learned:
        graveyard = "Cast Summon Skeleton to put the grimoire's teaching into practice."
    if conjuration_uses > 0:
        graveyard = "Complete. Summon Skeleton has been cast."
    var hand := "Ask Quiet Finn about the cellar, or investigate forbidden magic."
    if emissary_pending:
        hand = "Speak to the emissary who appeared after your study of the grimoire."
    match initiation:
        "available":
            hand = "Speak with the Veiled Agent beneath Stonehaven."
        "active":
            hand = "Recover the sealed ledger from the oath vault and return to the Veiled Agent."
            if LEDGER in quest_items:
                hand = "Bring the sealed ledger to the Veiled Agent."
        "complete":
            hand = "Complete. You are a Black Hand member."
    return "The Bonecaller's Grimoire\n%s\n\nBlack Hand Initiation\n%s" % [graveyard, hand]

func save_progress(path: String) -> Error:
    var file := ConfigFile.new()
    write_progress(file)
    return write_file(file, path)

func write_progress(file: ConfigFile) -> void:
    file.set_value("chapter", "version", VERSION)
    file.set_value("chapter", "defeated", defeated)
    file.set_value("chapter", "quest_items", quest_items)
    file.set_value("chapter", "entry_method", entry_method)
    file.set_value("chapter", "finn_contact", finn_contact)
    file.set_value("chapter", "emissary_pending", emissary_pending)
    file.set_value("chapter", "spell_learned", spell_learned)
    file.set_value("chapter", "grimoire_choice", grimoire_choice)
    file.set_value("chapter", INITIATION, initiation)
    file.set_value("chapter", "experience", experience)
    file.set_value("chapter", "conjuration_uses", conjuration_uses)
    file.set_value("chapter", "guild_rank", guild_rank)
    file.set_value("chapter", "guild_accepted", guild_accepted)
    file.set_value("chapter", "guild_provisions", guild_provisions)
    file.set_value("chapter", "guild_caravan_inspected", guild_caravan_inspected)
    file.set_value("chapter", "guild_watch_supplied", guild_watch_supplied)
    file.set_value("chapter", "guild_herbs", guild_herbs)
    file.set_value("chapter", "lord_stage", lord_stage)
    file.set_value("chapter", "mentorship_faction", mentorship_faction)
    file.set_value("chapter", "mentorship_year", mentorship_year)
    file.set_value("chapter", "mentorship_focus", mentorship_focus)
    file.set_value("chapter", "mentorship_history", mentorship_history)
    file.set_value("chapter", "player_age", player_age)

static func write_file(file: ConfigFile, path: String) -> Error:
    var temporary_path := path + ".tmp"
    var result := file.save(temporary_path)
    if result == OK:
        result = DirAccess.rename_absolute(temporary_path, path)
    if result != OK:
        DirAccess.remove_absolute(temporary_path)
    return result

func load_progress(path: String) -> Error:
    var file := ConfigFile.new()
    var result := file.load(path)
    if result != OK:
        return result
    return read_progress(file)

func read_progress(file: ConfigFile) -> Error:
    if file.get_value("chapter", "version", 0) != VERSION:
        return ERR_FILE_UNRECOGNIZED
    defeated.assign(file.get_value("chapter", "defeated", []))
    quest_items.assign(file.get_value("chapter", "quest_items", []))
    entry_method = file.get_value("chapter", "entry_method", "")
    finn_contact = file.get_value("chapter", "finn_contact", false)
    emissary_pending = file.get_value("chapter", "emissary_pending", false)
    spell_learned = file.get_value("chapter", "spell_learned", false)
    grimoire_choice = file.get_value("chapter", "grimoire_choice", "study" if spell_learned else "")
    if grimoire_choice == "study" and entry_method.is_empty():
        emissary_pending = true
    initiation = file.get_value("chapter", INITIATION, "locked")
    experience = file.get_value("chapter", "experience", 0)
    conjuration_uses = file.get_value("chapter", "conjuration_uses", 0)
    guild_rank = file.get_value("chapter", "guild_rank", "")
    guild_accepted.assign(file.get_value("chapter", "guild_accepted", [] if guild_rank.is_empty() else GUILD_CONTRACTS.keys()))
    guild_provisions = file.get_value("chapter", "guild_provisions", false)
    guild_caravan_inspected = file.get_value("chapter", "guild_caravan_inspected", false)
    guild_watch_supplied = file.get_value("chapter", "guild_watch_supplied", false)
    guild_herbs = file.get_value("chapter", "guild_herbs", 0)
    lord_stage = file.get_value("chapter", "lord_stage", "locked")
    mentorship_faction = file.get_value("chapter", "mentorship_faction", "")
    mentorship_year = file.get_value("chapter", "mentorship_year", 0)
    mentorship_focus = file.get_value("chapter", "mentorship_focus", "")
    mentorship_history.assign(file.get_value("chapter", "mentorship_history", []))
    player_age = file.get_value("chapter", "player_age", 15)
    return OK
