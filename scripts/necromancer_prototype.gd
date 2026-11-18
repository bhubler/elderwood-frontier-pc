extends Node2D
## Standalone necromancer prototype. Open scenes/necromancer_prototype.tscn and press F6.
## Original procedural art; no external asset or paid pack required.
const WALK_SPEED: float = 170.0
const STAGE_SIZE := Vector2(1280, 720)
var hero_position := Vector2(640, 390)
var facing := Vector2(0, 1)
var walk_clock := 0.0
var world_clock := 0.0
var cast_time := 0.0
var cast_cooldown := 0.0
var particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()

func _process(delta: float) -> void:
    world_clock += delta
    cast_time = maxf(0.0, cast_time - delta)
    cast_cooldown = maxf(0.0, cast_cooldown - delta)
    var move := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        move.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        move.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        move.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        move.y += 1.0
    if move.length_squared() > 0.0:
        facing = move.normalized()
        hero_position += facing * WALK_SPEED * delta
        hero_position.x = clampf(hero_position.x, 80.0, 1200.0)
        hero_position.y = clampf(hero_position.y, 180.0, 630.0)
        walk_clock += delta * 10.0
    if Input.is_key_pressed(KEY_SPACE) and cast_cooldown <= 0.0:
        cast_time = 0.75
        cast_cooldown = 1.0
        for i in range(20):
            var angle := rng.randf_range(0.0, TAU)
            var speed := rng.randf_range(35.0, 125.0)
            particles.append({"p": hero_position + Vector2(22, -67), "v": Vector2.from_angle(angle) * speed, "life": rng.randf_range(0.35, 0.85), "max_life": 0.85})
    for i in range(particles.size() - 1, -1, -1):
        particles[i]["life"] = float(particles[i]["life"]) - delta
        particles[i]["p"] = Vector2(particles[i]["p"]) + Vector2(particles[i]["v"]) * delta
        if float(particles[i]["life"]) <= 0.0:
            particles.remove_at(i)
    queue_redraw()

func _draw() -> void:
    _draw_stage()
    _draw_necromancer()
    for p in particles:
        var alpha: float = clampf(float(p["life"]) / float(p["max_life"]), 0.0, 1.0)
        draw_circle(p["p"], 4.0 * alpha + 1.0, Color(0.72, 0.35, 1.0, alpha))
    draw_string(ThemeDB.fallback_font, Vector2(28, 38), "ELDERWOOD FRONTIER  /  NECROMANCER STUDY", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#e4d3b4"))
    draw_string(ThemeDB.fallback_font, Vector2(28, 65), "WASD / arrows: move     SPACE: cast bone-staff spell     F6: run this scene", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b5a8a9"))
    draw_string(ThemeDB.fallback_font, Vector2(28, 688), "Experimental animated character study - village gameplay remains unchanged", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#998c91"))

func _draw_stage() -> void:
    draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), Color("#15171d"))
    draw_rect(Rect2(40, 100, 1200, 550), Color("#22242a"))
    for x in range(70, 1250, 80):
        draw_line(Vector2(x, 120), Vector2(x, 630), Color("#35313a"), 1.0)
    for y in range(130, 650, 55):
        draw_line(Vector2(60, y), Vector2(1220, y), Color("#35313a"), 1.0)
    draw_circle(Vector2(640, 390), 190, Color(0.37, 0.18, 0.45, 0.055))
    draw_arc(Vector2(640, 390), 175, 0, TAU, 96, Color("#51405a"), 3.0)
    for i in range(12):
        var a := float(i) / 12.0 * TAU
        var pt := Vector2(640, 390) + Vector2.from_angle(a) * 175.0
        draw_line(pt - Vector2(7, 0), pt + Vector2(7, 0), Color("#72558a"), 2.0)

func _draw_necromancer() -> void:
    var moving := Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_DOWN)
    var stride := sin(walk_clock) if moving else 0.0
    var bob := absf(stride) * 2.8 if moving else sin(world_clock * 2.2) * 1.5
    draw_set_transform(hero_position + Vector2(0, -bob), 0.0, Vector2.ONE)
    var bone := Color("#d7c7a6")
    var shadow := Color("#100f19")
    var robe := Color("#28202e")
    var red := Color("#6f273d")
    var gold := Color("#99805e")
    var violet := Color("#a35df1")
    # Ground shadow and articulated boots.
    _draw_prototype_ellipse(Vector2(0, 16), 37, 10, Color(0, 0, 0, 0.38))
    draw_rect(Rect2(-19, 0 + stride * 4, 12, 19), Color("#201a20"))
    draw_rect(Rect2(7, 0 - stride * 4, 12, 19), Color("#201a20"))
    draw_rect(Rect2(-21, 13 + stride * 4, 15, 6), Color("#695649"))
    draw_rect(Rect2(7, 13 - stride * 4, 15, 6), Color("#695649"))
    # Tattered robe silhouette, with distinct burgundy inner panels.
    draw_colored_polygon(PackedVector2Array([Vector2(-17, -59), Vector2(17, -59), Vector2(29, 12), Vector2(12, 8), Vector2(0, 17), Vector2(-15, 9), Vector2(-31, 15)]), shadow)
    draw_colored_polygon(PackedVector2Array([Vector2(-19, -57), Vector2(17, -57), Vector2(23, 8), Vector2(8, 3), Vector2(0, 13), Vector2(-9, 3), Vector2(-24, 10)]), robe)
    draw_colored_polygon(PackedVector2Array([Vector2(-8, -48), Vector2(9, -48), Vector2(12, 8), Vector2(0, 2), Vector2(-12, 8)]), red)
    draw_line(Vector2(0, -43), Vector2(0, 4), gold, 2.0)
    # Shoulder pauldrons, bone spines and armored arms.
    draw_colored_polygon(PackedVector2Array([Vector2(-18, -60), Vector2(-33, -56), Vector2(-38, -42), Vector2(-18, -46)]), gold)
    draw_colored_polygon(PackedVector2Array([Vector2(18, -60), Vector2(33, -56), Vector2(38, -42), Vector2(18, -46)]), gold)
    for side in [-1.0, 1.0]:
        draw_line(Vector2(side * 23, -54), Vector2(side * 33, -64), bone, 4.0)
        draw_line(Vector2(side * 30, -47), Vector2(side * 41, -54), bone, 3.0)
    draw_line(Vector2(-30, -46), Vector2(-34 + stride * 3, -18), Color("#514153"), 11.0)
    draw_line(Vector2(30, -46), Vector2(31 - stride * 3, -20), Color("#514153"), 11.0)
    # Ribbed breastplate and belt skull.
    for j in range(3):
        draw_line(Vector2(-12, -42 + j * 7), Vector2(12, -42 + j * 7), gold.darkened(0.12), 2.0)
    draw_line(Vector2(-18, -23), Vector2(18, -23), gold, 5.0)
    draw_circle(Vector2(0, -23), 6.5, bone)
    draw_circle(Vector2(-2, -24), 1.2, shadow)
    draw_circle(Vector2(2, -24), 1.2, shadow)
    # Skull helm, antler-like crown and glowing eyes.
    draw_colored_polygon(PackedVector2Array([Vector2(-15, -78), Vector2(-12, -97), Vector2(0, -103), Vector2(12, -97), Vector2(15, -78), Vector2(0, -65)]), bone)
    draw_colored_polygon(PackedVector2Array([Vector2(-9, -83), Vector2(0, -70), Vector2(9, -83), Vector2(0, -77)]), Color("#7b6e62"))
    for side in [-1.0, 1.0]:
        draw_line(Vector2(side * 9, -92), Vector2(side * 20, -116), bone, 4.0)
        draw_line(Vector2(side * 20, -116), Vector2(side * 22, -130), bone, 3.0)
        draw_line(Vector2(side * 17, -108), Vector2(side * 30, -117), bone, 3.0)
        draw_circle(Vector2(side * 6, -88), 3.2, violet)
        draw_circle(Vector2(side * 6, -88), 1.5, Color.WHITE)
    # Bone staff: silhouette remains clear at game scale.
    draw_line(Vector2(31, -20), Vector2(37, -127), Color("#9c8a70"), 6.0)
    draw_line(Vector2(37, -127), Vector2(25, -139), bone, 4.0)
    draw_line(Vector2(37, -127), Vector2(49, -139), bone, 4.0)
    draw_line(Vector2(25, -139), Vector2(24, -148), bone, 3.0)
    draw_line(Vector2(49, -139), Vector2(50, -148), bone, 3.0)
    var pulse := 7.0 + sin(world_clock * 4.8) * 1.8
    draw_circle(Vector2(37, -142), pulse + 5.0, Color(0.5, 0.18, 0.8, 0.16))
    draw_circle(Vector2(37, -142), pulse, violet)
    draw_circle(Vector2(35, -144), 3.0, Color("#f3d8ff"))
    if cast_time > 0.0:
        var t := 1.0 - cast_time / 0.75
        draw_arc(Vector2(36, -142), 13.0 + t * 65.0, 0, TAU, 64, Color(0.72, 0.35, 1.0, 1.0 - t), 4.0)
        draw_circle(Vector2(-35, -30), 8.0 + sin(world_clock * 18.0) * 2.0, violet)
    draw_set_transform(Vector2.ZERO)

func _draw_prototype_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
    draw_set_transform(center, 0.0, Vector2(1.0, ry / rx))
    draw_circle(Vector2.ZERO, rx, color)
    draw_set_transform(Vector2.ZERO)
