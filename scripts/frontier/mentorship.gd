extends RefCounted
## Five-year prologue training paths. Each year is a compact mission, not a forced class selection.
const PATHS := {
    "lord": {
        "mentor": "Captain Ser Aldric — Lord's Swordmaster",
        "focus": ["Swordsmanship", "Elemental Magic", "Wardcraft"],
        "missions": [
            ["east_pinewood", Vector2(-150, 110), "Patrol the eastern trade road", "Your mentor assigns a patrol to protect caravans. Search the route for signs of trouble."],
            ["northern_watch", Vector2(0, -95), "Train with the frontier watch", "Help the watch captain prepare defenses and drill with the guard."],
            ["old_cabin", Vector2(45, 70), "Scout the abandoned woodlands", "Your mentor sends you to investigate suspicious movements around the old cabin."],
            ["graveyard", Vector2(100, 92), "Hold the cemetery perimeter", "Protect travelers at the graveyard road without disturbing the dead."],
            ["ancient_ruin", Vector2(60, 60), "Final examination at the ruins", "Return to the site of your first great discovery and test what you have learned."],
        ],
    },
    "church": {
        "mentor": "Sister Elowen — Keeper of the Light",
        "focus": ["Healing", "Sacred Wards", "Paladin Combat"],
        "missions": [
            ["east_pinewood", Vector2(150, 110), "Carry aid to forest travelers", "Visit the woodland shrine and aid those who cannot reach the city."],
            ["graveyard", Vector2(-50, 85), "Tend the forgotten graves", "Search for lost pilgrims and learn the responsibility of protecting the vulnerable."],
            ["crypt_approach", Vector2(0, 50), "Sanctify a troubled threshold", "Practice warding rites near the Bonecaller's abandoned crypt."],
            ["northern_watch", Vector2(40, 30), "Heal the wounded watch", "Bring care and protective blessings to soldiers on the frontier."],
            ["ancient_ruin", Vector2(60, 60), "Discern the waking magic", "Complete your final pilgrimage to the ruin and test your discernment."],
        ],
    },
    "black_hand": {
        "mentor": "The Veiled Tutor — Black Hand Arcanist",
        "focus": ["Necromancy", "Blood Magic", "Forbidden Wards"],
        "missions": [
            ["hideout", Vector2(95, 60), "Learn the hidden oath", "Study the oaths and coded signs of the Black Hand."],
            ["cellar_gate", Vector2(55, 40), "Move unseen beneath Stonehaven", "Practice stealth and protect the secrecy of the cellar."],
            ["graveyard", Vector2(-70, 70), "Study restless echoes", "Record the difference between a lingering soul and a summoned servant."],
            ["crypt_ossuary", Vector2(-30, 75), "Recover forbidden inscriptions", "Investigate old necromantic writings without awakening the crypt."],
            ["ancient_ruin", Vector2(60, 60), "Confront the source of the awakening", "Return to the forgotten ruin for your final examination."],
        ],
    },
}

static func mission(faction: String, year: int) -> Array:
    if not PATHS.has(faction) or year < 0 or year >= 5:
        return []
    return PATHS[faction]["missions"][year]

static func mentor(faction: String) -> String:
    return str(PATHS[faction]["mentor"]) if PATHS.has(faction) else ""

static func focuses(faction: String) -> Array:
    return PATHS[faction]["focus"] if PATHS.has(faction) else []
