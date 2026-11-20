extends CharacterBody2D

const MAX_HEALTH := 6
const NOTICE_DISTANCE := 210.0
const BITE_DISTANCE := 49.0
const LEASH_DISTANCE := 310.0
const SPEED := 109.0

var home: Vector2
var player: CharacterBody2D
var variant := 0
var health := MAX_HEALTH
var engaged := false
var targeted := false
const WINDUP_TIME := 0.32
var bite_cooldown := 0.0
var bite_windup := 0.0
var bite_lunge := 0.0
var hit_flash := 0.0
var facing_left := true
var art: Texture2D

func _ready() -> void:
	home = position
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 0
	z_index = 9
	var feet := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	feet.shape = circle
	add_child(feet)

func tick(delta: float) -> bool:
	bite_cooldown = maxf(0.0, bite_cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	bite_lunge = maxf(0.0, bite_lunge - delta)
	var target := (get_parent() as Node2D).to_local(player.global_position) + Vector2(0, 16)
	var distance := position.distance_to(target)
	if target.distance_to(home) > LEASH_DISTANCE:
		engaged = false
	elif distance < NOTICE_DISTANCE:
		engaged = true

	velocity = Vector2.ZERO
	if bite_windup > 0.0:
		bite_windup -= delta
		queue_redraw()
		if bite_windup <= 0.0:
			bite_lunge = 0.18
			bite_cooldown = 1.15
			return engaged and distance <= BITE_DISTANCE + 13.0
		return false

	var goal := target if engaged else home
	if position.distance_to(goal) > (BITE_DISTANCE if engaged else 3.0):
		velocity = (goal - position).limit_length(SPEED * delta) / delta
		if absf(velocity.x) > 5.0:
			facing_left = velocity.x < 0.0
		move_and_slide()

	queue_redraw()
	if engaged and distance <= BITE_DISTANCE and bite_cooldown <= 0.0:
		bite_windup = WINDUP_TIME
	return false

func strike(damage: int) -> void:
	health = maxi(0, health - damage)
	engaged = true
	hit_flash = 0.18
	bite_windup = 0.0
	bite_cooldown = maxf(bite_cooldown, 0.34)
	queue_redraw()

func reset_position() -> void:
	position = home
	engaged = false
	velocity = Vector2.ZERO
	bite_cooldown = 0.0
	bite_windup = 0.0
	bite_lunge = 0.0
	targeted = false
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 27.0, Color(0, 0, 0, 0.30))
	draw_set_transform(Vector2.ZERO)
	if targeted:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_arc(Vector2.ZERO, 33.0, 0.0, TAU, 30, Color("#ebb26d"), 2.0, true)
		draw_set_transform(Vector2.ZERO)
	var tint := Color("#ffaaa0") if hit_flash > 0.0 else Color.WHITE
	var bob := 1.8 * sin(Time.get_ticks_msec() * 0.014) if velocity.length_squared() > 1.0 else 0.0
	var advance := bite_lunge / 0.18 * 10.0
	if bite_windup > 0.0:
		advance = -4.0
		bob += 4.0
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 20, Color("#f5a85e"), 2.0, true)
	var pose := Vector2(-advance if facing_left else advance, bob)
	if art != null:
		var size := art.get_size() * minf(88.0 / art.get_width(), 67.0 / art.get_height())
		draw_set_transform(pose, 0.0, Vector2(1 if facing_left else -1, 1))
		draw_texture_rect(art, Rect2(Vector2(-size.x * 0.5, -size.y + 3.0), size), false, tint)
		draw_set_transform(Vector2.ZERO)
	else:
		var fur := (Color("#576052") if variant == 0 else Color("#78634d")) * tint
		draw_set_transform(pose, 0.0, Vector2(1 if facing_left else -1, 1))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-41, -19), Vector2(-31, -31), Vector2(-24, -47), Vector2(-17, -35),
			Vector2(15, -36), Vector2(29, -24), Vector2(45, -32), Vector2(31, -15),
			Vector2(23, 0), Vector2(16, 0), Vector2(16, -14), Vector2(-12, -13),
			Vector2(-18, 2), Vector2(-24, 2), Vector2(-23, -17)
		]), fur)
		draw_circle(Vector2(-30, -27), 2.5, Color("#f4bd66"))
		draw_set_transform(Vector2.ZERO)
	if engaged or health < MAX_HEALTH:
		draw_rect(Rect2(-23, -76, 46, 5), Color("#252024"))
		draw_rect(Rect2(-23, -76, 46.0 * health / MAX_HEALTH, 5), Color("#bd5950"))
