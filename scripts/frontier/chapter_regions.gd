extends RefCounted
## Room layouts specify entrances, NPCs, encounter IDs and landmark positions.
const EXIT := Vector2(0, 236)
const NORTH := Vector2(0, -225)
const REGIONS := {
    "graveyard": {
        "title": "Forsaken Graveyard", "ground": "#282f2b",
        "points": [
            ["crypt_approach", "Crypt of the Bonecaller", NORTH],
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
        "enemy": ["ossuary_skeleton", "Restless Skeleton", 32, 11, 25, "#b9b298"],
    },
    "crypt_ritual": {
        "title": "Crypt of the Bonecaller — Ritual Chamber", "ground": "#302734",
        "points": [["crypt_ossuary", "Ossuary", EXIT], ["grimoire", "Ritual lectern", NORTH]],
        "enemy": ["bonecaller", "The Bonecaller", 64, 17, 60, "#b58ccd"],
    },
    "stonehaven": {
        "title": "Stonehaven — Eastward Quarter", "ground": "#34312c",
        "points": [
            ["graveyard", "Road to the graveyard", EXIT],
            ["quiet_finn", "Quiet Finn", Vector2(-420, 39)],
            ["raided_caravan", "Blackbriar caravan road", Vector2(408, 167)],
            ["town_court", "Stonehaven civic court", Vector2(424, -180)],
            ["cellar_gate", "Hidden Drainage Door", NORTH],
        ],
    },
    "town_court": {
        "title": "Stonehaven — Civic Court", "ground": "#41403d",
        "points": [["stonehaven", "Eastward Quarter", EXIT],
            ["northern_watch", "Northern watch road", Vector2(416, 87)]],
    },
    "northern_watch": {
        "title": "Northern Frontier Watchtower", "ground": "#32372d",
        "points": [["town_court", "Road to Stonehaven", EXIT]],
    },
    "raided_caravan": {
        "title": "Blackbriar Caravan Wreck", "ground": "#373228",
        "points": [["stonehaven", "Road to Stonehaven", EXIT]],
        "enemy": ["blackbriar_bandit", "Blackbriar Bandit", 33, 11, 24, "#bd8061", "bandit"],
    },
    "old_cabin": {
        "title": "Old Cabin in the Woods", "ground": "#2c3428",
        "points": [["graveyard", "Forsaken Graveyard", EXIT]],
        "enemy": ["cabin_goblin", "Cabin Goblin", 27, 9, 21, "#849659", "goblin"],
    },
    "cellar_gate": {
        "title": "Stonehaven — Cellar Stair", "ground": "#2c2a28",
        "points": [["stonehaven", "Eastward Quarter", EXIT], ["hideout", "Black Hand cellar", NORTH]],
        "enemy": ["cellar_guard", "Black Hand Guard", 52, 15, 45, "#c38772"],
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
        "enemy": ["vault_warden", "Vault Warden", 50, 14, 35, "#a4a4be"],
    },
}

const ITEMS := {
    "forbidden_grimoire": {
        "name": "Forbidden Grimoire", "kind": "quest", "icon": "▤", "rarity": "Rare",
        "description": "The Bonecaller's notes. Press L in the chapter to learn Summon Skeleton.",
    },
    "sealed_ledger": {
        "name": "Sealed Ledger", "kind": "quest", "icon": "◇", "rarity": "Quest",
        "description": "Return this unopened to the Veiled Agent.",
    },
}
