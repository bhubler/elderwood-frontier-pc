extends Node2D

const Layout := preload("res://scripts/frontier/overworld_layout.gd")
const ForestLayout := preload("res://scripts/forest_layout.gd")
const WorldCollision := preload("res://scripts/world_collision.gd")
const Vegetation := preload("res://scripts/wilderness_vegetation.gd")
const Ruins := preload("res://scripts/frontier/awakening_ruins.gd")
const CHUNK_SIZE := 880
const LANDMARKS := [Layout.CARAVAN, Layout.WATCH, Layout.CRYPT, Layout.CABIN, Layout.SHRINE, Ruins.ENTRANCE + Vector2(0, -110)]
const GROVE_PATH := "res://art/landmarks/pine_grove.png"

var player: Node2D
var grove: Texture2D
var vegetation: Vegetation
var chunks: Dictionary = {}
var center := Vector2i(9999, 9999)
var active_chunks: Array[Vector2i] = []
var pending_chunks: Array[Vector2i] = []
var unfinished: Dictionary = {}

func _ready() -> void:
    if DirAccess.dir_exists_absolute(Vegetation.PACK_ROOT):
        vegetation = Vegetation.new()
        vegetation.use_authored_layout = true
        add_child(vegetation)
    grove = load(GROVE_PATH)
    resume_at_player()

func resume_at_player() -> void:
    _set_center(Vector2i((player.position / CHUNK_SIZE).floor()))
    # Finish the nearby landing area before the transition releases the player.
    for key in pending_chunks:
        _grow_chunk(key, 16)
    pending_chunks.clear()

func _process(_delta: float) -> void:
    var current := Vector2i((player.position / CHUNK_SIZE).floor())
    if current != center:
        _set_center(current)
    if not pending_chunks.is_empty() and _grow_chunk(pending_chunks.back(), 4):
        pending_chunks.pop_back()

func _set_center(current: Vector2i) -> void:
    center = current
    pending_chunks.clear()
    var nearby: Array[Vector2i] = []
    for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
        Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
        var key: Vector2i = center + offset
        if not Rect2(Vector2(key) * CHUNK_SIZE, Vector2.ONE * CHUNK_SIZE).intersects(Layout.FOREST.grow(710)):
            continue
        nearby.append(key)
        if not chunks.has(key) or unfinished.has(key):
            pending_chunks.push_front(key)
        if chunks.has(key) and key not in active_chunks:
            var chunk: Node2D = chunks[key]
            chunk.process_mode = Node.PROCESS_MODE_INHERIT
            chunk.show()
    for key in active_chunks:
        if key in nearby or not chunks.has(key):
            continue
        var chunk: Node2D = chunks[key]
        chunk.hide()
        chunk.process_mode = Node.PROCESS_MODE_DISABLED
    active_chunks = nearby

func _grow_chunk(key: Vector2i, slots: int) -> bool:
    if not chunks.has(key):
        var node := Node2D.new()
        node.position = Vector2(key) * CHUNK_SIZE
        add_child(node)
        chunks[key] = node
        var generator := RandomNumberGenerator.new()
        generator.seed = hash(key) + 937721
        unfinished[key] = [0, generator]
    var chunk: Node2D = chunks[key]
    var progress: Array = unfinished[key]
    var rng: RandomNumberGenerator = progress[1]
    var end := mini(int(progress[0]) + slots, 16)
    for index in range(int(progress[0]), end):
        var column := index >> 2
        var row := index % 4
        var p := Vector2(column, row) * 220 + Vector2(rng.randf_range(35, 174), rng.randf_range(35, 174))
        var world_point := p + chunk.position
        if not Layout.FOREST.grow(710).has_point(world_point):
            continue
        if world_point.distance_to(Layout.FOREST_WEST) < 210.0 or _near_landmark(world_point):
            continue
        if ForestLayout.near_route(world_point, Layout.FOREST_ROADS, 112.0) \
            or ForestLayout.near_route(world_point - Vector2(0, 90), Layout.FOREST_ROADS, 113.0):
            continue
        var selection := rng.randi()
        var bundled := is_instance_valid(vegetation) and vegetation.place_tree(chunk, p, selection)
        if not bundled:
            var sprite := Sprite2D.new()
            sprite.texture = grove
            sprite.position = p
            sprite.offset.y = -grove.get_height() * 0.5
            sprite.z_index = -2
            chunk.add_child(sprite)
        if Layout.FOREST.has_point(world_point):
            if bundled:
                WorldCollision.circle(chunk, "TreeTrunk", p, 12.0)
            else:
                WorldCollision.box(chunk, "Roots", Rect2(p - Vector2(45, 30), Vector2(90, 25)))
    if end == 16:
        unfinished.erase(key)
        return true
    progress[0] = end
    return false

func _near_landmark(where: Vector2) -> bool:
    for landmark in LANDMARKS:
        if where.distance_to(landmark) < 240.0:
            return true
    return false
