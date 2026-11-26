extends RefCounted

const Overworld := preload("res://scripts/frontier/overworld_layout.gd")
const Ruins := preload("res://scripts/frontier/awakening_ruins.gd")
const Village := preload("res://scripts/forest_layout.gd")
const REGIONS := {
    "village": ["Elderwood Village", Rect2(-950, -740, 1900, 1460), 100],
    "pinewood": ["Pinewood Road", Rect2(-900, -920, 1800, 1790), 100],
    "stonehaven": ["Stonehaven", Overworld.CITY, 100],
    "east_pinewood": ["East Pinewood", Overworld.FOREST, 280],
    "graveyard": ["Forsaken Graveyard", Rect2(-510, -290, 1020, 580), 80],
}
# Region, caption, map location, arrival on the walkable side.
const LANDMARKS := {
    "elderwood": ["village", "Elderwood Village", Vector2(-65, 0), Vector2(-65, 0)],
    "inn": ["village", "Wayfarer Inn", Vector2(-390, -190), Vector2(-390, -115)],
    "pinewood_gate": ["village", "Pinewood Gate", Vector2(4, -670), Vector2(4, -615)],
    "trailhead": ["pinewood", "Pinewood Trailhead", Vector2(0, 765), Vector2(0, 704)],
    "stonehaven_approach": ["pinewood", "Stonehaven Approach", Vector2(0, -640), Vector2(0, -584)],
    "stonehaven": ["stonehaven", "Stonehaven South Gate", Vector2(0, 448), Vector2(0, 397)],
    "guild": ["stonehaven", "Adventurer’s Guild", Vector2(-260, 360), Vector2(-260, 398)],
    "manor": ["stonehaven", "Lord’s Manor", Vector2(-264, -155), Vector2(-264, -110)],
    "church": ["stonehaven", "Church of Stonehaven", Vector2(232, -155), Vector2(232, -112)],
    "east_gate": ["stonehaven", "Stonehaven East Gate", Overworld.CITY_EAST, Overworld.CITY_EAST - Vector2(92, 0)],
    "east_trail": ["east_pinewood", "East Pinewood Trailhead", Overworld.FOREST_WEST, Overworld.FOREST_WEST + Vector2(105, 0)],
    "caravan": ["east_pinewood", "Raided Caravan", Overworld.CARAVAN + Vector2(0, 145), Overworld.CARAVAN + Vector2(0, 145)],
    "raider_trail": ["east_pinewood", "Blackbriar Raider Trail", Overworld.CARAVAN + Vector2(-265, -85), Overworld.CARAVAN + Vector2(-265, -34)],
    "watchtower": ["east_pinewood", "Northern Watchtower", Overworld.WATCH + Vector2(0, 120), Overworld.WATCH + Vector2(0, 168)],
    "shrine": ["east_pinewood", "Roadside Shrine", Overworld.SHRINE + Vector2(0, 77), Overworld.SHRINE + Vector2(0, 110)],
    "ruins": ["east_pinewood", "Awakening Ruins", Ruins.ENTRANCE, Ruins.ENTRANCE + Vector2(0, 62)],
    "cabin": ["east_pinewood", "Old Woodland Cabin", Overworld.CABIN + Vector2(0, 112), Overworld.CABIN + Vector2(0, 159)],
    "cemetery": ["east_pinewood", "Forsaken Graveyard Approach", Overworld.CRYPT + Vector2(0, 123), Overworld.CRYPT + Vector2(0, 172)],
    "graveyard": ["graveyard", "Forsaken Graveyard", Vector2(0, 145), Vector2(0, 145)],
    "crypt": ["graveyard", "Crypt of the Bonecaller", Vector2(0, -225), Vector2(0, -133)],
}

static func roads(region: String) -> Array:
    match region:
        "village": return Village.ROADS + Village.TRAILS
        "pinewood": return [Village.PINEWOOD_ROAD, Village.PINEWOOD_CLEARING]
        "stonehaven": return Overworld.CITY_ROADS
        "east_pinewood": return Overworld.FOREST_ROADS
        "graveyard": return [[Vector2(0, -225), Vector2(0, 140), Vector2(344, 225)],
            [Vector2(0, 140), Vector2(408, 115)]]
    return []

static func cells(file: ConfigFile, region: String) -> Dictionary:
    return file.get_value("map", "fog_" + region, {})

static func discovered(file: ConfigFile) -> Dictionary:
    return file.get_value("map", "landmarks", {})

static func reveal(file: ConfigFile, region: String, position: Vector2) -> void:
    if not REGIONS.has(region):
        return
    var step: int = REGIONS[region][2]
    var center := Vector2i((position / step).floor())
    var revealed := cells(file, region)
    for x in range(-2, 3):
        for y in range(-2, 3):
            if x * x + y * y <= 5:
                revealed[center + Vector2i(x, y)] = true
    file.set_value("map", "fog_" + region, revealed)
    var visited := discovered(file)
    for key: String in LANDMARKS:
        var entry: Array = LANDMARKS[key]
        if entry[0] == region and not visited.has(key) and position.distance_to(entry[2]) < maxf(145.0, step * 0.8):
            visited[key] = true
    file.set_value("map", "landmarks", visited)
