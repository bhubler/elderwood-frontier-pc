extends CharacterBody2D
## Prototype movement is in screen-space. Later versions can add terrain collision.
const SPEED: float = 235.0
var facing: Vector2 = Vector2.DOWN
var stride: float = 0.0
var equipped_weapon := ""
var equipped_armor := "cloak"
var attack_bonus := 0
var defense_bonus := 1

func set_equipment(gear: Dictionary) -> void:
    equipped_weapon = str(gear.get("weapon", ""))
    equipped_armor = str(gear.get("armor", ""))
    attack_bonus = 3 if equipped_weapon == "rusty_sword" else 0
    defense_bonus = 1 if equipped_armor == "cloak" else 0
    queue_redraw()


func _physics_process(delta: float) -> void:
    var input_vector := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        input_vector.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        input_vector.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        input_vector.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        input_vector.y += 1.0
    velocity = input_vector.normalized() * SPEED
    if input_vector.length_squared() > 0.0:
        facing = input_vector.normalized()
        stride += delta * 11.0
    move_and_slide()
    queue_redraw()

func _draw() -> void:
    var bob := sin(stride) * 2.0 if velocity.length_squared() > 0.0 else 0.0
    draw_ellipse_shadow()
    draw_colored_polygon(PackedVector2Array([
        Vector2(-12, -7 + bob), Vector2(12, -7 + bob),
        Vector2(17, 16 + bob), Vector2(-17, 16 + bob)
    ]), Color("#294d63") if equipped_armor == "cloak" else Color("#70583f"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-10, -13 + bob), Vector2(10, -13 + bob),
        Vector2(12, 2 + bob), Vector2(-12, 2 + bob)
    ]), Color("#a58a59"))
    draw_circle(Vector2(0, -22 + bob), 11.0, Color("#dfb88d"))
    draw_arc(Vector2(0, -24 + bob), 12.0, PI, TAU, 16, Color("#3b2929"), 5.0)
    if equipped_weapon == "rusty_sword":
        draw_line(Vector2(14, -9 + bob), Vector2(23, -34 + bob), Color("#c2c7c6"), 5.0)
        draw_line(Vector2(16, -13 + bob), Vector2(30, -10 + bob), Color("#76532d"), 4.0)
    else:
        draw_line(Vector2(14, -9 + bob), Vector2(20, 10 + bob), Color("#aeb5bc"), 3.0)
        draw_circle(Vector2(20, 10 + bob), 3.0, Color("#61c5ee"))

func draw_ellipse_shadow() -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(-18, 14), Vector2(-11, 19),
        Vector2(11, 19), Vector2(18, 14)
    ]), Color(0.02, 0.02, 0.02, 0.35))
