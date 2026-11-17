extends Node2D
## Places licensed Wilderness Bundle scenes locally without committing their assets.
## Looks for standalone tree/bush scenes. Demo scenes are deliberately excluded.
const PACK_ROOT := "res://art/10_Wilderness_Bundle/Trees_and_Bushes"
const SEED := 77139

var tree_scenes: Array[PackedScene] = []
var bush_scenes: Array[PackedScene] = []

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(PACK_ROOT):
		push_warning("Wilderness vegetation folder missing; leaving village clear.")
		return
	_discover(PACK_ROOT)
	if tree_scenes.is_empty() and bush_scenes.is_empty():
		push_warning("No standalone vegetation scenes found. Share the Trees_and_Bushes folder structure to wire exact assets.")
		return
	_populate()

func _discover(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not item.begins_with("."):
			var full_path := path.path_join(item)
			if dir.current_is_dir():
				_discover(full_path)
			elif item.ends_with(".tscn"):
				var lower := item.to_lower()
				if not ("demo" in lower or "example" in lower or "test" in lower):
					var is_tree := "tree" in lower or "pine" in lower or "oak" in lower
					var is_bush := "bush" in lower or "shrub" in lower
					if is_tree or is_bush:
						var scene := load(full_path) as PackedScene
						if scene != null:
							if is_tree:
								tree_scenes.append(scene)
							else:
								bush_scenes.append(scene)
		item = dir.get_next()
	dir.list_dir_end()

func _populate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# Keep the starting settlement open; thicken forest towards its perimeter.
	for i in range(250):
		var pos := Vector2(rng.randf_range(-1600.0, 1600.0), rng.randf_range(-1050.0, 1050.0))
		if _reserved(pos):
			continue
		var is_tree := rng.randf() < 0.7
		var candidates := tree_scenes if is_tree else bush_scenes
		if candidates.is_empty():
			continue
		var scene := candidates[rng.randi_range(0, candidates.size() - 1)]
		var instance := scene.instantiate()
		if not (instance is Node2D):
			instance.queue_free()
			continue
		var decoration := instance as Node2D
		decoration.position = pos
		decoration.z_index = 0
		add_child(decoration)

func _reserved(pos: Vector2) -> bool:
	# Wide open village square, inn entrance, merchant stand, hall and cottages.
	if absf(pos.x) < 650.0 and absf(pos.y) < 475.0:
		return true
	if pos.distance_to(Vector2(-390, -290)) < 310.0:
		return true
	if pos.distance_to(Vector2(380, -230)) < 210.0:
		return true
	if pos.distance_to(Vector2(210, -15)) < 200.0:
		return true
	# Keep roads and approaches traversable.
	var paths: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-760, 50), Vector2(640, 65)]),
		PackedVector2Array([Vector2(0, -610), Vector2(-40, 720)]),
		PackedVector2Array([Vector2(-95, 35), Vector2(-480, 225)]),
		PackedVector2Array([Vector2(80, 30), Vector2(380, -230)]),
		PackedVector2Array([Vector2(80, 65), Vector2(410, 280)])
	]
	for path in paths:
		if _distance_to_segment(pos, path[0], path[1]) < 110.0:
			return true
	return false

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var delta := b - a
	var t := clampf((point - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
	return point.distance_to(a + delta * t)
