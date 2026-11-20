extends Node2D

signal player_fell
signal wolf_defeated

const WorldCollision := preload("res://scripts/world_collision.gd")
const Wolf := preload("res://scripts/pinewood_wolf.gd")
const Fireball := preload("res://scripts/pinewood_fireball.gd")
const Layout := preload("res://scripts/forest_layout.gd")
const MONSTER_ART := "res://art/pinewood/briar_wolves.png"
const VILLAGE_ENTRANCE := Vector2(4, -670)
const SOUTH_ENTRY := Vector2(0, 704)
const SOUTH_EXIT := Vector2(0, 795)
const MAX_HEALTH := 14
const MAX_MANA := 6.0
const FIREBALL_COST := 2.0
const FIREBALL_DAMAGE := 4
const CAST_WINDUP_TIME := 0.18
const AIM_RANGE := 460.0
const AIM_CONE := 0.80
const TRACKING_SPEED := 4.5
const ROAD := [
	Vector2(0, 855), Vector2(0, 664), Vector2(-184, 453), Vector2(-153, 231),
	Vector2(100, 55), Vector2(201, -146), Vector2(115, -380),
	Vector2(0, -566), Vector2(0, -820)
]
const CLEARING := [
	Vector2(-153, 231), Vector2(-315, 181), Vector2(-412, 61)
]

var player: CharacterBody2D
var wolves: Array[Wolf] = []
var trees: Array[Vector2] = []
var health := MAX_HEALTH
var mana := MAX_MANA
var cast_cooldown := 0.0
var cast_windup := 0.0
var cast_direction := Vector2.UP
var cast_target: Wolf
var preview_target: Wolf
var fireballs: Array[Fireball] = []
var active := false
var combat_paused := false
var swing_cooldown := 0.0
const STRIKE_WINDUP := 0.10
var windup := 0.0
var pending_damage := 0
var swing_effect := 0.0
var swing_direction := Vector2.UP
var armor := 0
var swing_overlay: Node2D

func _ready() -> void:
	WorldCollision.polygon(self, "ForestEdge", PackedVector2Array([
		Vector2(-900, -920), Vector2(900, -920), Vector2(900, 870), Vector2(-900, 870)
	]), CollisionPolygon2D.BUILD_SEGMENTS)
	WorldCollision.box(self, "StonehavenWestWall", Rect2(-900, -666, 800, 42))
	WorldCollision.box(self, "StonehavenEastWall", Rect2(100, -666, 800, 42))
	swing_overlay = Node2D.new()
	swing_overlay.name = "SwingOverlay"
	swing_overlay.z_index = 11
	swing_overlay.draw.connect(_draw_swing)
	add_child(swing_overlay)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41072
	for i in range(390):
		var p := Vector2(rng.randf_range(-875.0, 875.0), rng.randf_range(-585.0, 852.0))
		if Layout.near_route(p, [ROAD], 91.0) or Layout.near_route(p, [CLEARING], 74.0):
			continue
		if p.distance_to(Vector2(170, -250)) < 93.0 or not Layout.has_trunk_clearance(p, trees):
			continue
		trees.append(p)
		WorldCollision.circle(self, "PineTrunk", p, 12.0)
	trees.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	_spawn_wolf(Vector2(-357, 127), 0)
	_spawn_wolf(Vector2(170, -250), 1)

func _spawn_wolf(at: Vector2, variant: int) -> void:
	var wolf := Wolf.new()
	wolf.position = at
	wolf.player = player
	wolf.variant = variant
	# The transparent atlas contains one creature centered in each half.
	if ResourceLoader.exists(MONSTER_ART):
		var atlas := load(MONSTER_ART) as Texture2D
		if atlas != null:
			var half := atlas.get_width() / 2.0
			var image := atlas.get_image()
			var area := Rect2i(roundi(variant * half), 0, floori(half), atlas.get_height())
			var sprite := image.get_region(area)
			var tight := sprite.get_used_rect()
			if tight.has_area():
				wolf.art = ImageTexture.create_from_image(sprite.get_region(tight))
	add_child(wolf)
	wolves.append(wolf)

func _physics_process(delta: float) -> void:
	if not active:
		return
	swing_cooldown = maxf(0.0, swing_cooldown - delta)
	if swing_effect > 0.0:
		swing_effect = maxf(0.0, swing_effect - delta)
		swing_overlay.queue_redraw()
	if combat_paused or in_stonehaven():
		pending_damage = 0
		if cast_windup > 0.0:
			cast_windup = 0.0
			swing_overlay.queue_redraw()
		_set_preview_target(null)
		return
	var cursor := get_local_mouse_position()
	_set_preview_target(_select_spell_target(cursor_aim(cursor), cursor))
	mana = minf(MAX_MANA, mana + delta * 0.70)
	cast_cooldown = maxf(0.0, cast_cooldown - delta)
	if cast_windup > 0.0:
		cast_windup -= delta
		swing_overlay.queue_redraw()
		if cast_windup <= 0.0:
			_launch_fireball()
	_tick_fireballs(delta)
	if pending_damage > 0:
		windup -= delta
		if windup <= 0.0:
			_resolve_strike()
	for wolf in wolves:
		if wolf.tick(delta):
			health = maxi(0, health - maxi(1, 4 - armor))
			player.play_hurt()
			if health == 0:
				recover_at_trailhead()
				player_fell.emit()
				return

func attack(damage: int, facing: Vector2, auto_aim := true) -> void:
	if not active or combat_paused or in_stonehaven() or swing_cooldown > 0.0 or cast_windup > 0.0:
		return
	swing_cooldown = 0.38
	windup = STRIKE_WINDUP
	pending_damage = damage
	swing_direction = facing
	if auto_aim:
		var nearest := _nearby_wolf()
		if nearest != null:
			swing_direction = _player_feet().direction_to(nearest.position)
	player.play_strike(swing_direction)

func _player_feet() -> Vector2:
	return to_local(player.global_position) + Vector2(0, 16)

func _nearby_wolf(facing := Vector2.ZERO) -> Wolf:
	var feet := _player_feet()
	var nearest: Wolf
	var reach := 91.0
	for wolf in wolves:
		var distance := feet.distance_to(wolf.position)
		var direction := feet.direction_to(wolf.position)
		if distance < reach and (facing == Vector2.ZERO or direction == Vector2.ZERO or direction.dot(facing) > 0.35):
			if facing != Vector2.ZERO and not _wall_hit(feet, wolf.position).is_empty():
				continue
			nearest = wolf
			reach = distance
	return nearest

func _resolve_strike() -> void:
	var damage := pending_damage
	pending_damage = 0
	swing_effect = 0.16
	var nearest := _nearby_wolf(swing_direction)
	if nearest != null:
		_damage_wolf(nearest, damage)
	swing_overlay.queue_redraw()

func _damage_wolf(wolf: Wolf, damage: int) -> void:
	wolf.strike(damage)
	if wolf.health == 0:
		wolves.erase(wolf)
		wolf.queue_free()
		wolf_defeated.emit()

func cast_fireball(facing: Vector2, cursor := Vector2.INF) -> bool:
	if not active or combat_paused or in_stonehaven() or cast_cooldown > 0.0 or pending_damage > 0:
		return false
	if mana < FIREBALL_COST:
		return false
	cast_direction = facing.normalized()
	cast_target = _select_spell_target(cast_direction, cursor if cursor != Vector2.INF else get_local_mouse_position())
	if is_instance_valid(cast_target):
		cast_direction = _player_feet().direction_to(cast_target.position)
	cast_windup = CAST_WINDUP_TIME
	cast_cooldown = 0.8
	player.play_strike(cast_direction)
	swing_overlay.queue_redraw()
	return true

func cursor_aim(cursor: Vector2, melee := false) -> Vector2:
	var feet := _player_feet()
	if melee:
		for wolf in wolves:
			if feet.distance_to(wolf.position) < 91.0 and _cursor_over_wolf(cursor, wolf):
				cursor = wolf.position
				break
	var aim := feet.direction_to(cursor)
	return player.facing if aim == Vector2.ZERO else aim

func _cursor_over_wolf(cursor: Vector2, wolf: Wolf) -> bool:
	return Rect2(wolf.position + Vector2(-37, -59), Vector2(74, 68)).has_point(cursor)

func _select_spell_target(facing: Vector2, cursor: Vector2) -> Wolf:
	var feet := _player_feet()
	var best: Wolf
	var best_score := -INF
	for wolf in wolves:
		var offset := wolf.position - feet
		var distance := offset.length()
		if distance > AIM_RANGE:
			continue
		var hovered := _cursor_over_wolf(cursor, wolf)
		var alignment := offset.normalized().dot(facing)
		if not hovered and alignment < AIM_CONE:
			continue
		var score := (2.0 if hovered else alignment) - distance / AIM_RANGE * 0.35
		if score > best_score and _wall_hit(feet, wolf.position).is_empty():
			best = wolf
			best_score = score
	return best

func _set_preview_target(wolf: Wolf) -> void:
	if preview_target == wolf:
		return
	if is_instance_valid(preview_target):
		preview_target.targeted = false
		preview_target.queue_redraw()
	preview_target = wolf
	if is_instance_valid(preview_target):
		preview_target.targeted = true
		preview_target.queue_redraw()

func _wall_hit(start: Vector2, finish: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(to_global(start), to_global(finish), 1, [player.get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query)

func _launch_fireball() -> void:
	mana -= FIREBALL_COST
	var ball := Fireball.new()
	ball.position = _player_feet()
	ball.direction = cast_direction
	if is_instance_valid(cast_target) and cast_target.health > 0:
		ball.target = cast_target
		ball.direction = ball.position.direction_to(cast_target.position)
	ball.z_index = 11
	add_child(ball)
	fireballs.append(ball)

func _tick_fireballs(delta: float) -> void:
	for i in range(fireballs.size() - 1, -1, -1):
		var ball := fireballs[i]
		if ball.burst > 0.0:
			ball.burst -= delta
			if ball.burst <= 0.0:
				ball.queue_free()
				fireballs.remove_at(i)
			else:
				ball.queue_redraw()
			continue
		ball.remaining -= delta
		var start := ball.position
		if is_instance_valid(ball.target) and ball.target.health > 0:
			ball.direction = Vector2.from_angle(rotate_toward(
				ball.direction.angle(), start.angle_to_point(ball.target.position), TRACKING_SPEED * delta
			))
			ball.queue_redraw()
		var finish := start + ball.direction * Fireball.SPEED * delta
		var obstacle := _wall_hit(start, finish)
		if not obstacle.is_empty():
			finish = to_local(obstacle["position"])
		var target: Wolf
		var nearest_distance := INF
		for wolf in wolves:
			var hit_at := Geometry2D.get_closest_point_to_segment(wolf.position, start, finish)
			if wolf.position.distance_squared_to(hit_at) <= 22.0 * 22.0:
				var distance := start.distance_squared_to(hit_at)
				if distance < nearest_distance and (obstacle.is_empty() or hit_at != finish):
					nearest_distance = distance
					target = wolf
					ball.position = hit_at
		if target != null:
			_damage_wolf(target, FIREBALL_DAMAGE)
			ball.detonate()
		else:
			ball.position = finish
			if not obstacle.is_empty() or ball.remaining <= 0.0:
				ball.detonate()

func clear_fireballs() -> void:
	cast_windup = 0.0
	cast_cooldown = 0.0
	cast_target = null
	_set_preview_target(null)
	for ball in fireballs:
		ball.queue_free()
	fireballs.clear()

func recover_at_trailhead() -> void:
	health = MAX_HEALTH
	mana = MAX_MANA
	clear_fireballs()
	swing_cooldown = 0.0
	pending_damage = 0
	swing_effect = 0.0
	swing_overlay.queue_redraw()
	for wolf in wolves:
		wolf.reset_position()
	player.global_position = to_global(SOUTH_ENTRY)
	player.get_node("Camera2D").reset_smoothing()

func in_stonehaven() -> bool:
	return to_local(player.global_position).y < -679.0

func _draw() -> void:
	draw_rect(Rect2(-1010, -1020, 2020, 1990), Color("#243b33"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 712
	for i in range(2800):
		var p := Vector2(rng.randf_range(-990.0, 990.0), rng.randf_range(-585.0, 920.0))
		var tint := Color("#385043") if i % 3 == 0 else Color("#30473b")
		draw_circle(p, rng.randf_range(2.0, 27.0), tint)
		if i % 6 == 0:
			draw_line(p, p + Vector2(3, -7), Color("#65805b"), 1.0)
	_draw_track(CLEARING, 76.0)
	_draw_track(ROAD, 112.0)
	for i in range(240):
		var at := rng.randi_range(0, ROAD.size() - 2)
		var start: Vector2 = ROAD[at]
		var end: Vector2 = ROAD[at + 1]
		var p := start.lerp(end, rng.randf()) + (end - start).normalized().orthogonal() * rng.randf_range(-46.0, 46.0)
		draw_circle(p, rng.randf_range(1.3, 4.2), Color("#94856b") if i % 2 == 0 else Color("#55493b"))
	for p in trees:
		_draw_pine(p)
	_draw_waypost(Vector2(86, 731), "PINEWOOD FOREST")
	_draw_waypost(Vector2(-226, 269), "STONEHAVEN ↑")
	_draw_gate()

func _draw_swing() -> void:
	var center := to_local(player.global_position) + Vector2(0, -2)
	if cast_windup > 0.0:
		var orb := center + cast_direction * 18.0
		var radius := lerpf(11.0, 4.0, cast_windup / CAST_WINDUP_TIME)
		swing_overlay.draw_circle(orb, radius, Color(1.0, 0.38, 0.08, 0.6))
		swing_overlay.draw_circle(orb, radius * 0.45, Color("#ffd68c"))
	if swing_effect > 0.0:
		var angle := swing_direction.angle()
		var opacity := swing_effect / 0.16
		var armed: bool = not player.equipped_weapon.is_empty()
		var sweep := lerpf(0.8, -0.75, opacity)
		var blade := Vector2.from_angle(angle + sweep)
		var tint := Color(1.0, 0.84, 0.52, opacity)
		var radius := 55.0 if armed else 37.0
		swing_overlay.draw_arc(center, radius, angle + sweep - 0.62, angle + sweep, 14, tint, 4.0, true)
		if armed:
			swing_overlay.draw_line(center + blade * 18.0, center + blade * radius,
				Color(0.85, 0.91, 0.95, opacity), 4.0, true)

func _draw_track(points: Array, width: float) -> void:
	var route := PackedVector2Array(points)
	draw_polyline(route, Color("#514939"), width, true)
	draw_polyline(route, Color("#6d5b43"), width * 0.86, true)
	draw_polyline(route, Color("#7d694e"), width * 0.63, true)

func _draw_pine(p: Vector2) -> void:
	var height := 86.0 + absf(sin(p.x + p.y) * 42.0)
	draw_set_transform(p)
	draw_rect(Rect2(-5, -35, 10, 36), Color("#503f33"))
	for i in range(3):
		var y := -27.0 - i * height * 0.26
		var width := height * (0.31 - i * 0.061)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-width, y), Vector2(0, y - height * 0.48),
			Vector2(width, y), Vector2(0, y + 8.0)
		]), [Color("#1b3833"), Color("#23443a"), Color("#315241")][i])
	draw_set_transform(Vector2.ZERO)

func _draw_waypost(p: Vector2, title: String) -> void:
	draw_rect(Rect2(p + Vector2(-4, -74), Vector2(8, 74)), Color("#614a33"))
	draw_rect(Rect2(p + Vector2(-79, -72), Vector2(158, 26)), Color("#483626"))
	draw_string(ThemeDB.fallback_font, p + Vector2(-71, -54), title,
		HORIZONTAL_ALIGNMENT_CENTER, 142, 14, Color("#ffe1a5"))

func _draw_gate() -> void:
	draw_rect(Rect2(-900, -920, 1800, 254), Color("#454c4e"))
	for row in range(10):
		for column in range(40):
			var p := Vector2(-900 + column * 46 - (row % 2) * 23, -920 + row * 29)
			draw_rect(Rect2(p, Vector2(43, 26)), Color("#565957") if (row + column) % 3 == 0 else Color("#4d514f"))
	for x in [-900, 100]:
		draw_rect(Rect2(x, -713, 800, 89), Color("#525a5b"))
		for i in range(16):
			draw_rect(Rect2(x + i * 51, -721, 35, 17), Color("#79807b"))
	for x in [-130, 100]:
		draw_rect(Rect2(x, -751, 30, 123), Color("#717974"))
		draw_circle(Vector2(x + 15, -692), 8.0, Color("#f1b765"))
	draw_arc(Vector2(0, -718), 114.0, PI, TAU, 24, Color("#727b76"), 22.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(-96, -811), "STONEHAVEN",
		HORIZONTAL_ALIGNMENT_CENTER, 192, 24, Color("#f2d7a6"))
