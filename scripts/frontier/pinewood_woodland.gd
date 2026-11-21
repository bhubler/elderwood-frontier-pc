extends Node2D

const Layout := preload("res://scripts/frontier/overworld_layout.gd")
const ForestLayout := preload("res://scripts/forest_layout.gd")
const WorldCollision := preload("res://scripts/world_collision.gd")
const CHUNK_SIZE := 880
const LANDMARKS := [Layout.CARAVAN, Layout.WATCH, Layout.CRYPT, Layout.CABIN, Layout.SHRINE]
const GROVE_PATH := "res://art/landmarks/pine_grove.png"

var player: Node2D
var grove: Texture2D
var chunks: Dictionary = {}
var center := Vector2i(9999, 9999)

func _ready() -> void:
    grove = load(GROVE_PATH)
    _update_chunks()

func _process(_delta: float) -> void:
    _update_chunks()

func _update_chunks() -> void:
    var current := Vector2i((player.position / CHUNK_SIZE).floor())
    if center == current:
        return
    center = current
    for key in chunks.keys():
        var offset: Vector2i = key - center
        if absi(offset.x) > 1 or absi(offset.y) > 1:
            var chunk: Node2D = chunks[key]
            remove_child(chunk)
            chunk.queue_free()
            chunks.erase(key)
    for x in range(center.x - 1, center.x + 2):
        for y in range(center.y - 1, center.y + 2):
            var key := Vector2i(x, y)
            if not chunks.has(key):
                _add_chunk(key)

func _add_chunk(key: Vector2i) -> void:
    var chunk := Node2D.new()
    chunk.position = Vector2(key) * CHUNK_SIZE
    add_child(chunk)
    chunks[key] = chunk
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(key) + 937721
    for column in range(4):
        for row in range(4):
            var p := Vector2(column, row) * 220 + Vector2(rng.randf_range(35, 174), rng.randf_range(35, 174))
            var world_point := p + chunk.position
            if not Layout.FOREST.grow(710).has_point(world_point):
                continue
            if world_point.distance_to(Layout.FOREST_WEST) < 210.0 or _near_landmark(world_point):
                continue
            if ForestLayout.near_route(world_point, Layout.FOREST_ROADS, 112.0) \
            or ForestLayout.near_route(world_point - Vector2(0, 90), Layout.FOREST_ROADS, 113.0):
                continue
            var sprite := Sprite2D.new()
            sprite.texture = grove
            sprite.position = p
            sprite.scale = Vector2.ONE * rng.randf_range(0.75, 1.22)
            sprite.offset.y = -grove.get_height() * 0.5
            sprite.flip_h = rng.randf() < 0.5
            sprite.modulate = Color(0.84, 0.92, 0.84).lerp(Color.WHITE, rng.randf())
            sprite.z_index = -2
            chunk.add_child(sprite)
            if Layout.FOREST.has_point(world_point):
                WorldCollision.box(chunk, "Roots", Rect2(p - Vector2(45, 30), Vector2(90, 25)))

func _near_landmark(where: Vector2) -> bool:
    for landmark in LANDMARKS:
        if where.distance_to(landmark) < 240.0:
            return true
    return false
