extends RefCounted
## Room layouts specify entrances, NPCs, encounter IDs and landmark positions.
const Overworld := preload("res://scripts/frontier/overworld_layout.gd")
const EXIT := Vector2(0, 236)
const NORTH := Vector2(0, -225)
const STONEHAVEN_DRAIN := Vector2(-796, -64)
const REGIONS := {
    "graveyard": {
        "title": "Forsaken Graveyard", "ground": "#282f2b",
        "points": [
            ["east_pinewood", "East Pinewood Forest", Vector2(344, 225)], ["crypt_approach", "Crypt of the Bonecaller", NORTH],
            ["stonehaven", "Road to Stonehaven", Vector2(408, 115)],
            ["grave_marker", "Weathered grave marker", Vector2(-352, 40)],
            ["old_cabin", "Old woodland trail", Vector2(-402, 193)],
        ],
    },
    "crypt_approach": {
        "title": "Crypt of the Bonecaller — Antechamber", "ground": "#292926",
        "points": [["graveyard", "Forsaken Graveyard", EXIT], ["crypt_ossuary", "Ossuary", NORTH]],
    },
    "crypt_ossuary": {
        "title": "Crypt of the Bonecaller — Ossuary", "ground": "#302c2b",
        "points": [["crypt_approach", "Antechamber", EXIT], ["crypt_ritual", "Ritual chamber", NORTH]],
        "enemy": ["ossuary_skeleton", "Restless Skeleton", 32, 11, 25, "#b9b298", "skeleton"],
    },
    "crypt_ritual": {
        "title": "Crypt of the Bonecaller — Ritual Chamber", "ground": "#302734",
        "points": [["crypt_ossuary", "Ossuary", EXIT], ["grimoire", "Forbidden Grimoire", Vector2(0, -168)]],
        "enemy": ["bonecaller", "The Bonecaller", 64, 17, 60, "#b58ccd", "black_hand_weaver"],
    },
    "stonehaven": {
        "title": "Stonehaven", "ground": "#3a3930",
        "points": [
            ["graveyard", "Old cemetery road", Vector2(-770, -190)],
            ["quiet_finn", "Quiet Finn", Vector2(-646, 390)],
            ["east_pinewood", "East Gate · Pinewood Forest", Overworld.CITY_EAST],
            ["cellar_gate", "Hidden Drainage Door", STONEHAVEN_DRAIN],
        ],
    },
    "east_pinewood": {
        "title": "Pinewood Forest", "ground": "#293b30",
        "points": [
            ["stonehaven", "Stonehaven · East Gate", Overworld.FOREST_WEST],
            ["inspect_caravan", "Inspect the raided caravan", Overworld.CARAVAN + Vector2(0, 100)],
            ["bandit_camp", "Raider camp trail", Overworld.CARAVAN + Vector2(-265, -85)],
            ["northern_watch", "Enter the watchtower", Overworld.WATCH + Vector2(0, 120)],
            ["graveyard", "Enter Forsaken Graveyard", Overworld.CRYPT + Vector2(0, 123)],
            ["old_cabin", "Explore the old cabin", Overworld.CABIN + Vector2(0, 112)],
            ["ancient_ruin", "Investigate the awakening ruins", Overworld.SHRINE + Vector2(170, -170)],
            ["woodland_shrine", "Roadside shrine", Overworld.SHRINE + Vector2(0, 77)],
        ],
    },
    "ancient_ruin": {
        "title": "The Awakening Ruins — Inner Sanctum", "ground": "#2c2d35",
        "points": [["east_pinewood", "Return to the eastern forest", EXIT]],
    },
    "town_court": {
        "title": "Stonehaven — Civic Court", "ground": "#41403d",
        "points": [["stonehaven", "Eastward Quarter", EXIT],
            ["northern_watch", "Enter the watchtower", Vector2(416, 87)]],
    },
    "northern_watch": {
        "title": "Northern Frontier Watchtower — Interior", "ground": "#332e27",
        "points": [["east_pinewood", "Back outside the watchtower", EXIT]],
    },
    "bandit_camp": {
        "title": "Blackbriar Raider Camp", "ground": "#38312b",
        "points": [["east_pinewood", "Back to the caravan trail", EXIT]],
        "enemy": ["blackbriar_chief", "Blackbriar Chief", 66, 18, 55, "#b07b55", "bandit_chief"],
    },
    "goblin_hollow": {
        "title": "Goblin Hollow", "ground": "#303522",
        "points": [["old_cabin", "Back to the cabin", EXIT]],
        "enemy": ["goblin_chief", "Goblin Chief", 60, 16, 48, "#738857", "goblin_chief"],
    },
    "old_cabin": {
        "title": "Old Cabin in the Woods", "ground": "#2c3428",
        "points": [["east_pinewood", "East Pinewood Forest", Vector2(344, 225)], ["graveyard", "Forsaken Graveyard", EXIT], ["goblin_hollow", "Goblin Hollow trail", Vector2(390, -134)]],
        "enemy": ["cabin_goblin", "Cabin Goblin", 27, 9, 21, "#849659", "goblin"],
    },
    "cellar_gate": {
        "title": "Stonehaven — Cellar Stair", "ground": "#2c2a28",
        "points": [["stonehaven", "Eastward Quarter", EXIT], ["hideout", "Black Hand cellar", NORTH]],
        "enemy": ["cellar_guard", "Black Hand Guard", 52, 15, 45, "#c38772", "black_hand_guard"],
    },
    "hideout": {
        "title": "Black Hand Hideout", "ground": "#2a2931",
        "points": [
            ["cellar_gate", "Cellar stair", EXIT],
            ["veiled_agent", "The Veiled Agent", Vector2(0, -70)],
            ["oath_vault", "Oath vault", NORTH],
        ],
    },
    "oath_vault": {
        "title": "Black Hand — Oath Vault", "ground": "#2e2934",
        "points": [["hideout", "Black Hand hideout", EXIT], ["ledger", "Sealed ledger", NORTH]],
        "enemy": ["vault_warden", "Vault Warden", 50, 14, 35, "#a4a4be", "black_hand_guard"],
    },
}

const ITEMS := {
    "forbidden_grimoire": {
        "name": "Forbidden Grimoire", "kind": "quest", "icon": "▤", "rarity": "Rare",
        "description": "The Bonecaller's notes. A forbidden record of the Bonecaller’s rites.",
    },
    "sealed_ledger": {
        "name": "Sealed Ledger", "kind": "quest", "icon": "◇", "rarity": "Quest",
        "description": "Return this unopened to the Veiled Agent.",
    },
}
