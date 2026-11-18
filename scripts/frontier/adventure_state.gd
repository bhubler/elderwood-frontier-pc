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
var initiation := "locked"
var experience := 0
var conjuration_uses := 0

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
    if GRIMOIRE not in quest_items or spell_learned:
        return false
    spell_learned = true
    return true

func record_summon() -> void:
    conjuration_uses += 1
    if entry_method.is_empty():
        emissary_pending = true

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
    if GRIMOIRE in quest_items:
        graveyard = "Study the forbidden grimoire."
    if spell_learned:
        graveyard = "Cast Summon Skeleton to put the grimoire's teaching into practice."
    if conjuration_uses > 0:
        graveyard = "Complete. Summon Skeleton has been cast."
    var hand := "Ask Quiet Finn about the cellar, or investigate forbidden magic."
    if emissary_pending:
        hand = "Speak to the emissary who appeared after your first summon."
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
    file.set_value("chapter", "version", VERSION)
    file.set_value("chapter", "defeated", defeated)
    file.set_value("chapter", "quest_items", quest_items)
    file.set_value("chapter", "entry_method", entry_method)
    file.set_value("chapter", "finn_contact", finn_contact)
    file.set_value("chapter", "emissary_pending", emissary_pending)
    file.set_value("chapter", "spell_learned", spell_learned)
    file.set_value("chapter", INITIATION, initiation)
    file.set_value("chapter", "experience", experience)
    file.set_value("chapter", "conjuration_uses", conjuration_uses)
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
    if file.get_value("chapter", "version", 0) != VERSION:
        return ERR_FILE_UNRECOGNIZED
    defeated.assign(file.get_value("chapter", "defeated", []))
    quest_items.assign(file.get_value("chapter", "quest_items", []))
    entry_method = file.get_value("chapter", "entry_method", "")
    finn_contact = file.get_value("chapter", "finn_contact", false)
    emissary_pending = file.get_value("chapter", "emissary_pending", false)
    spell_learned = file.get_value("chapter", "spell_learned", false)
    initiation = file.get_value("chapter", INITIATION, "locked")
    experience = file.get_value("chapter", "experience", 0)
    conjuration_uses = file.get_value("chapter", "conjuration_uses", 0)
    return OK
