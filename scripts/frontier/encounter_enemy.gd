extends Node2D
## One reusable melee opponent with leash, attack windup and defeat signal.
signal defeated(encounter_id: String, reward_xp: int)
signal attack_landed(damage: int)

@export var encounter_id := ""
@export var title := ""
@export var max_health := 40
@export var damage := 12
@export var reward_xp := 30
@export var tint := Color("#bd846c")
const AnimatedNPC := preload("res://scenes/npc/animated_npc.tscn")

@export var frames: SpriteFrames
var presentation: Node2D
var target: Node2D
var health: int
var home: Vector2
var windup := 0.0
var cooldown := 0.0
var caption: Label

func _ready() -> void:
    health = max_health
    home = position
    caption = Label.new()
    caption.position = Vector2(-130, -71)
    caption.custom_minimum_size.x = 260
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(caption)
    _update_caption()
    if frames != null:
        presentation = AnimatedNPC.instantiate()
        presentation.frames = frames
        presentation.autonomous_patrol = false
        presentation.attack_contact.connect(_on_sprite_contact)
        presentation.defeated.connect(queue_free)
        add_child(presentation)

func _on_sprite_contact() -> void:
    if health > 0 and is_instance_valid(target) and position.distance_to(target.position) <= 55.0:
        attack_landed.emit(damage)

func _physics_process(delta: float) -> void:
    if health <= 0:
        return
    if not is_instance_valid(target):
        if presentation != null:
            presentation.locomotion(Vector2.ZERO)
        return
    var distance := position.distance_to(target.position)
    cooldown = maxf(0.0, cooldown - delta)
    if presentation != null:
        _tick_animated_opponent(delta, distance)
        return
    if windup > 0.0:
        windup -= delta
        if windup <= 0.0:
            cooldown = 0.85
            if distance <= 51:
                attack_landed.emit(damage)
        queue_redraw()
        return
    if distance > 260 or target.position.distance_to(home) > 340:
        position = position.move_toward(home, delta * 135)
    elif distance > 42:
        position = position.move_toward(target.position, delta * 115)
    elif cooldown <= 0.0:
        windup = 0.48
        queue_redraw()

func _tick_animated_opponent(delta: float, distance: float) -> void:
    if presentation.busy():
        return
    var destination: Vector2 = position
    if distance > 260.0 or target.position.distance_to(home) > 340.0:
        destination = home
    elif distance > 42.0:
        destination = target.position
    elif cooldown <= 0.0:
        presentation.face(position.direction_to(target.position))
        presentation.attack()
        cooldown = 1.2
        return
    presentation.locomotion(position.direction_to(destination))
    position = position.move_toward(destination, delta * 110.0)

func take_hit(amount: int) -> void:
    if health <= 0 or amount <= 0:
        return
    health = maxi(0, health - amount)
    if health == 0:
        defeated.emit(encounter_id, reward_xp)
        if presentation != null:
            caption.hide()
            presentation.react_to_hit(true)
        else:
            queue_free()
    else:
        _update_caption()
        if presentation != null:
            presentation.react_to_hit(false)

func _update_caption() -> void:
    caption.text = "%s  %d/%d" % [title, health, max_health]

func _draw() -> void:
    if frames != null:
        return
    draw_circle(Vector2(0, 7), 20, Color(0, 0, 0, 0.4))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-20, 5), Vector2(-12, -27), Vector2(12, -27), Vector2(20, 5)
    ]), tint.darkened(0.36))
    draw_circle(Vector2(0, -32), 10, tint)
    draw_line(Vector2(22, 1), Vector2(26, -49), tint.lightened(0.28), 4)
    if windup > 0.0:
        draw_arc(Vector2.ZERO, 51, 0, TAU, 32, Color("#ee8753"), 3, true)
