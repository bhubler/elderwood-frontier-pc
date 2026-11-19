extends RefCounted
## Shared ground-plane collision for village props, rooms and region edges.

static func box(parent: Node2D, label: String, bounds: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	_add_shape(parent, label, bounds.get_center(), shape)

static func circle(parent: Node2D, label: String, center: Vector2, radius: float) -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	_add_shape(parent, label, center, shape)

static func polygon(
	parent: Node2D,
	label: String,
	points: PackedVector2Array,
	build_mode: int = CollisionPolygon2D.BUILD_SOLIDS
) -> void:
	var body := _body(parent, label)
	var collider := CollisionPolygon2D.new()
	collider.build_mode = build_mode
	collider.polygon = points
	body.add_child(collider)

static func _add_shape(parent: Node2D, label: String, center: Vector2, shape: Shape2D) -> void:
	var body := _body(parent, label)
	body.position = center
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)

static func _body(parent: Node2D, label: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = label
	body.collision_mask = 0
	parent.add_child(body, true)
	return body
