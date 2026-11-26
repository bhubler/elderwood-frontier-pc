extends CenterContainer

const Chapter := preload("res://scripts/frontier/forsaken_chapter.gd")
const Terrain := preload("res://scripts/wilderness_terrain.gd")
const Overworld := preload("res://scripts/frontier/overworld_layout.gd")
const CHECKPOINT_INTERVAL := 16

@onready var status: Label = $Content/Status
@onready var progress: ProgressBar = $Content/Progress
@onready var action: Button = $Content/Action

var chapter: Chapter
var patches: Array[Vector2i] = []
var next_patch := 0
var running := false

func _ready() -> void:
    if not OS.has_feature("editor"):
        return
    var terrain := Terrain.new()
    Chapter.configure_forest_terrain(terrain)
    terrain.hide()
    add_child(terrain)
    if terrain.tile_set == null:
        status.text = "The Wilderness Bundle tileset is missing."
        return

    # Reuse the game's terrain and cache logic without starting a playthrough.
    chapter = Chapter.new()
    chapter.forest_terrain = terrain
    chapter.outdoor_terrain = terrain
    chapter._restore_forest_patch_cache()

    var corridor: Dictionary = {}
    var road: Array = Overworld.FOREST_ROADS[0]
    for segment in range(3):
        var start: Vector2 = road[segment]
        var end: Vector2 = road[segment + 1]
        var steps := ceili(start.distance_to(end) / (Chapter.TERRAIN_PATCH_SIZE.y * 0.5))
        for step in range(steps + 1):
            var center := Vector2i((start.lerp(end, float(step) / steps) / Chapter.TERRAIN_PATCH_SIZE).floor())
            for x in range(-Chapter.FOREST_LOOKAHEAD.x, Chapter.FOREST_LOOKAHEAD.x + 1):
                for y in range(-Chapter.FOREST_LOOKAHEAD.y, Chapter.FOREST_LOOKAHEAD.y + 1):
                    corridor[center + Vector2i(x, y)] = true
    for key in corridor:
        if not chapter.painted_patches.has(key):
            patches.append(key)
    progress.max_value = corridor.size()
    progress.value = corridor.size() - patches.size()
    action.pressed.connect(_toggle_preparation)
    action.disabled = false
    _update_status()

func _process(_delta: float) -> void:
    if not running:
        return
    chapter._paint_forest_patch(patches[next_patch])
    next_patch += 1
    progress.value += 1
    if next_patch % CHECKPOINT_INTERVAL == 0 or next_patch == patches.size():
        chapter._save_forest_patch_cache()
        if chapter.forest_cache_dirty:
            running = false
            status.text = "Could not write the terrain cache. Click Retry Save."
            action.text = "Retry Save"
            return
    running = next_patch < patches.size()
    _update_status()

func _toggle_preparation() -> void:
    if chapter.forest_cache_dirty:
        chapter._save_forest_patch_cache()
        if chapter.forest_cache_dirty:
            running = false
            status.text = "Could not write the terrain cache. Click Retry Save."
            action.text = "Retry Save"
            return
    running = not running and next_patch < patches.size()
    _update_status()

func _update_status() -> void:
    if next_patch == patches.size():
        status.text = "Corridor ready. Stop this scene and run the game with F5."
        action.disabled = true
        return
    status.text = "%d / %d corridor patches ready" % [progress.value, progress.max_value]
    action.text = "Pause and Save" if running else "Prepare Corridor"

func _exit_tree() -> void:
    if is_instance_valid(chapter):
        chapter.free()
