extends RefCounted
## Shared floor plans for rendered walls and world collision.

const ENTRANCE := Vector2(-1680, 10)
const HALL_BOUNDS := Rect2(-760, -440, 1520, 880)
const SANCTUM_BOUNDS := Rect2(-560, -350, 1120, 700)
const RELIC := Vector2(0, -218)
const ROOMS := {
    "ancient_ruin": {
        "title": "Awakening Ruins — Entrance Halls", "ground": "#34332d",
        "points": [
            ["east_pinewood", "Return to Pinewood Forest", Vector2(0, 384)],
            ["ruin_lower", "Descend to the lower halls", Vector2(565, -345)],
        ],
        "enemy": ["ruin_hall_guard", "Ruin Spearman", 42, 11, 32, "#8c986e", "goblin_spear"],
        "enemy_position": Vector2(466, -205),
    },
    "ruin_lower": {
        "title": "Awakening Ruins — Lower Halls", "ground": "#2c3032",
        "points": [
            ["ancient_ruin", "Climb to the entrance halls", Vector2(575, 346)],
            ["ruin_sanctum", "Enter the Sentinel's sanctum", Vector2(-560, -346)],
        ],
        "enemy": ["ruin_seal_guard", "Restless Sealkeeper", 54, 14, 42, "#b9b298", "skeleton"],
        "enemy_position": Vector2(-460, -216),
    },
    "ruin_sanctum": {
        "title": "Awakening Ruins — Sentinel's Sanctum", "ground": "#312b35",
        "points": [["ruin_lower", "Return to the lower halls", Vector2(0, 295)]],
        "enemy": ["ruin_warden", "The Waking Sentinel", 78, 16, 65, "#ae9fd0", "black_hand_guard"],
        "enemy_position": Vector2(0, -65),
    },
}
const PARTITIONS := {
    "ancient_ruin": [
        Rect2(-240, -440, 24, 174), Rect2(-240, -135, 24, 245), Rect2(-240, 240, 24, 200),
        Rect2(240, -440, 24, 174), Rect2(240, -135, 24, 245), Rect2(240, 240, 24, 200),
        Rect2(-760, -38, 205, 24), Rect2(-420, -38, 180, 24),
        Rect2(-216, -38, 155, 24), Rect2(61, -38, 179, 24),
        Rect2(264, -38, 142, 24), Rect2(545, -38, 215, 24),
    ],
    "ruin_lower": [
        Rect2(-760, 56, 160, 24), Rect2(-465, 56, 399, 24),
        Rect2(68, 56, 385, 24), Rect2(588, 56, 172, 24),
        Rect2(-225, -440, 24, 210), Rect2(-225, -94, 24, 150),
        Rect2(215, -440, 24, 135), Rect2(215, -165, 24, 221),
        Rect2(-66, 80, 24, 126), Rect2(-66, 345, 24, 95),
    ],
    "ruin_sanctum": [],
}

static func bounds(id: String) -> Rect2:
    return SANCTUM_BOUNDS if id == "ruin_sanctum" else HALL_BOUNDS

static func walls(id: String) -> Array[Rect2]:
    var area := bounds(id)
    var result: Array[Rect2] = [
        Rect2(area.position, Vector2(area.size.x, 22)),
        Rect2(area.position, Vector2(22, area.size.y)),
        Rect2(Vector2(area.end.x - 22, area.position.y), Vector2(22, area.size.y)),
        Rect2(Vector2(area.position.x, area.end.y - 22), Vector2(area.size.x, 22)),
    ]
    for wall in PARTITIONS[id]:
        result.append(wall)
    return result
