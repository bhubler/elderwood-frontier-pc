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

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target) or health <= 0:
        return
    var distance := position.distance_to(target.position)
    cooldown = maxf(0.0, cooldown - delta)
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

func take_hit(amount: int) -> void:
    if health <= 0 or amount <= 0:
        return
    health = maxi(0, health - amount)
    if health == 0:
        defeated.emit(encounter_id, reward_xp)
        queue_free()
    else:
        _update_caption()

func _update_caption() -> void:
    caption.text = "%s  %d/%d" % [title, health, max_health]

func _draw() -> void:
    draw_circle(Vector2(0, 7), 20, Color(0, 0, 0, 0.4))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-20, 5), Vector2(-12, -27), Vector2(12, -27), Vector2(20, 5)
    ]), tint.darkened(0.36))
    draw_circle(Vector2(0, -32), 10, tint)
    draw_line(Vector2(22, 1), Vector2(26, -49), tint.lightened(0.28), 4)
    if windup > 0.0:
        draw_arc(Vector2.ZERO, 51, 0, TAU, 32, Color("#ee8753"), 3, true)
