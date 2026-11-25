extends RefCounted

const Ruins := preload("res://scripts/frontier/awakening_ruins.gd")

const CITY_SIZE := Vector2(1800, 1100)
const CITY := Rect2(-CITY_SIZE / 2, CITY_SIZE)
const FOREST := Rect2(-CITY_SIZE * 3.5, CITY_SIZE * 7)
const CITY_EAST := Vector2(820, 80)
const FOREST_WEST := Vector2(-6110, 80)
const CARAVAN := Vector2(-3900, 490)
const WATCH := Vector2(-1250, -1870)
const CRYPT := Vector2(2130, 1210)
const CABIN := Vector2(4420, -1340)
const SHRINE := Vector2(-1850, 180)
const JUNCTION := Vector2(1200, -280)

const FOREST_ROADS := [
    [FOREST_WEST, Vector2(-5150, 180), Vector2(-4350, 670), CARAVAN + Vector2(0, 140),
        Vector2(-3100, 390), SHRINE + Vector2(0, 100), Vector2(-850, -160), JUNCTION,
        Vector2(2750, -480), CABIN + Vector2(0, 130), Vector2(5420, -2150), Vector2(3760, -2950),
        Vector2(300, -2800), WATCH + Vector2(0, 145), Vector2(-3280, -1550), Vector2(-5150, 180)],
    [JUNCTION, Vector2(1570, 810), CRYPT + Vector2(0, 143), Vector2(3080, 2270),
        Vector2(4550, 2480), Vector2(5500, 1130), CABIN + Vector2(0, 130)],
    [Vector2(-3100, 390), Vector2(-3540, 1730), Vector2(-2000, 2590), Vector2(210, 2640),
        Vector2(1570, 810)],
    [Vector2(-850, -160), Vector2(-1650, -712), WATCH + Vector2(0, 145)],
    [SHRINE + Vector2(0, 100), Vector2(-1780, 152), Ruins.ENTRANCE + Vector2(0, 32)]
]
const CITY_ROADS := [
    [Vector2(-870, 80), CITY_EAST],
    [Vector2(-515, -432), Vector2(-515, 485)],
    [Vector2(0, -475), Vector2(0, 488)],
    [Vector2(495, -444), Vector2(495, 485)],
    [Vector2(-790, -190), Vector2(790, -190)],
    [Vector2(-795, 327), Vector2(795, 327)]
]

static func bounds(region: String, default: Rect2) -> Rect2:
    match region:
        "stonehaven": return CITY
        "east_pinewood": return FOREST
    return default
