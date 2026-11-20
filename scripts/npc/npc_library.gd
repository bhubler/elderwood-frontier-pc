extends RefCounted
## Appearance choices for placing reusable NPCs without preloading the whole roster.

const NPC_SCENE := preload("res://scenes/npc/animated_npc.tscn")
const WARDROBE := preload("res://scripts/npc/wardrobe.gdshader")
const ART := "res://art/characters/stonehaven/"

const SHADES := [
	Color("#716047"), Color("#777744"), Color("#6d5249"), Color("#5f626c"),
	Color("#526d66"), Color("#786545"), Color("#634e64"), Color("#625b4d"),
	Color("#778078"),
]

# Each entry is a base SpriteFrames resource and the number of wardrobe versions.
const ROSTER := {
	"blacksmith": [["blacksmith", 5], ["blacksmith_apprentice", 5]],
	"alchemist": [["alchemist", 5], ["alchemist_apprentice", 5]],
	"shopkeeper": [["shopkeeper", 5], ["shopkeeper_quartermaster", 5]],
	"merchant_mage": [["merchant_mage", 5], ["merchant_mage_binder", 5]],
	"guard": [["guard_sword", 1], ["guard_spear", 1]],
	"noble": [["noble", 5], ["noble_reeve", 5]],
	"bandit": [["bandit", 1], ["bandit_archer", 1], ["bandit_spear", 1], ["bandit_chief", 1]],
	"goblin": [["goblin", 1], ["goblin_spear", 1], ["goblin_hewer", 1], ["goblin_chief", 1]],
	"black_hand": [["black_hand_guard", 1], ["black_hand_duelist", 1], ["black_hand_weaver", 1],
		["sanctuary_leader", 1], ["veiled_agent", 1]],
	"priest": [["priest", 5], ["priest_cantor", 5]],
	"monk": [["monk", 3]],
	"townsperson": [["townswoman", 9], ["townsman", 9], ["sweeper", 8],
		["scribe", 8], ["dockhand", 8], ["elder", 8]],
}

const ATTACK_STYLES := {
	"bandit_archer": "bow",
	"bandit_spear": "spear",
	"bandit_chief": "maul",
	"goblin_spear": "spear",
	"goblin_chief": "stomp",
	"guard_spear": "spear",
	"black_hand_weaver": "hex",
	"sanctuary_leader": "hex",
}

static func appearances(role: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in ROSTER.get(role, []):
		var path := ART + str(entry[0]) + ".tres"
		if not ResourceLoader.exists(path, "SpriteFrames"):
			continue
		for wardrobe in range(int(entry[1])):
			result.append({"sheet": entry[0], "wardrobe": wardrobe})
	return result

static func create(sheet: String, wardrobe := 0) -> Node2D:
	var path := ART + sheet + ".tres"
	if not ResourceLoader.exists(path, "SpriteFrames"):
		return null
	var npc := NPC_SCENE.instantiate() as Node2D
	npc.frames = load(path)
	if wardrobe > 0:
		var dye := ShaderMaterial.new()
		dye.shader = WARDROBE
		var shade_index := posmod(wardrobe - 1 + sheet.hash(), SHADES.size())
		dye.set_shader_parameter("shade", SHADES[shade_index])
		dye.set_shader_parameter("amount", 0.78)
		npc.get_node("Sprite").material = dye
	return npc
