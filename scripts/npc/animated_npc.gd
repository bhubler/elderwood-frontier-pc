extends Node2D
## Foot-aligned NPC presentation shared by civilians and combatants.
signal attack_contact
signal defeated

@export var frames: SpriteFrames
@export var patrol_offset := Vector2(43, 0)
@export var autonomous_patrol := true
@export var walk_speed := 24.0

@onready var sprite: AnimatedSprite2D = $Sprite
var home: Vector2
var returning := false
var wait := 1.2
var contact_pending := false
var down := false

func _ready() -> void:
	home = position
	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_finish_action)
	sprite.frame_changed.connect(_check_contact)
	sprite.play(&"idle")

func _physics_process(delta: float) -> void:
	if not autonomous_patrol or busy():
		return
	if wait > 0.0:
		wait -= delta
		return
	var destination := home if returning else home + patrol_offset
	if position.distance_squared_to(destination) < 1.0:
		returning = not returning
		wait = 4.0
		sprite.play(&"idle")
		return
	sprite.flip_h = destination.x < position.x
	position = position.move_toward(destination, walk_speed * delta)
	sprite.play(&"walk")

func busy() -> bool:
	return down or sprite.animation in [&"interact", &"attack", &"hit", &"defeat"]

func locomotion(direction: Vector2) -> void:
	if busy():
		return
	if absf(direction.x) > 0.1:
		sprite.flip_h = direction.x < 0.0
	sprite.play(&"idle" if direction.is_zero_approx() else &"walk")

func face(direction: Vector2) -> void:
	if absf(direction.x) > 0.1:
		sprite.flip_h = direction.x < 0.0

func interact() -> void:
	_play_action(&"interact")

func attack() -> void:
	if _play_action(&"attack"):
		contact_pending = true

func react_to_hit(lethal: bool) -> void:
	if down:
		return
	contact_pending = false
	if lethal and _play_action(&"defeat"):
		down = true
	elif not lethal:
		_play_action(&"hit")

func _play_action(action: StringName) -> bool:
	if down or not frames.has_animation(action):
		return false
	if sprite.animation == action and sprite.is_playing():
		return false
	sprite.play(action)
	sprite.set_frame_and_progress(0, 0.0)
	return true

func _check_contact() -> void:
	if contact_pending and sprite.animation == &"attack" and sprite.frame == 2:
		contact_pending = false
		attack_contact.emit()

func _finish_action() -> void:
	if down:
		defeated.emit()
	else:
		contact_pending = false
		wait = 2.0
		sprite.play(&"idle")

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 16.0, Color(0.06, 0.045, 0.03, 0.32))
