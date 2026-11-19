extends CharacterBody2D
const ART := {
    &"Mara": preload("res://art/characters/original/mara.png"),
    &"Elden": preload("res://art/characters/original/elden.png"),
    &"Pip": preload("res://art/characters/original/pip.png"),
    &"Rowan": preload("res://art/characters/original/rowan.png"),
}
const TALK_RADIUS := 94.0

var artwork_height: float
var player: CharacterBody2D
var route: PackedVector2Array
var walk_speed := 45.0
var pause_time := 0.0
var talking := false

var artwork: Sprite2D
var next_stop := 0
var animation_phase := 0.0

func _ready() -> void:
    motion_mode = MOTION_MODE_FLOATING
    collision_layer = 0
    var feet := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 9.0
    feet.shape = shape
    feet.position.y = 15.0
    add_child(feet)

    var texture: Texture2D = ART.get(name)
    if texture == null:
        return
    var sprite := Sprite2D.new()
    sprite.name = "Artwork"
    sprite.texture = texture
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var height := artwork_height
    sprite.scale = Vector2.ONE * (height / texture.get_height())
    sprite.position = Vector2(0, 15.0 - height / 2.0)
    add_child(sprite)
    artwork = sprite

func _physics_process(delta: float) -> void:
    velocity = Vector2.ZERO
    var player_near := is_instance_valid(player) and position.distance_to(player.position) < TALK_RADIUS
    if player_near and artwork != null:
        _face_horizontally(player.position.x - position.x)
    if not talking and not player_near and not route.is_empty():
        _walk_route(delta)

    if artwork != null:
        var walking := velocity.length_squared() > 1.0 and get_real_velocity().length_squared() > 1.0
        var animation_speed := 14.0 if walking else 2.8
        var lift := 2.6 if walking else 0.8
        animation_phase = fmod(animation_phase + delta * animation_speed, TAU)
        artwork.position.y = 15.0 - artwork_height / 2.0 - lift * (0.5 + 0.5 * sin(animation_phase))

func _walk_route(delta: float) -> void:
    if pause_time > 0.0:
        pause_time -= delta
        return

    var to_stop := route[next_stop] - position
    if to_stop.length() < 3.0:
        next_stop = (next_stop + 1) % route.size()
        pause_time = 3.5 if next_stop == 0 else 1.4
        return
    velocity = to_stop.limit_length(walk_speed * delta) / delta
    _face_horizontally(velocity.x)
    move_and_slide()

func _face_horizontally(horizontal: float) -> void:
    if artwork != null and absf(horizontal) > 2.0:
        artwork.flip_h = horizontal < 0.0


func _draw() -> void:
    draw_ellipse_shadow()
    if ART.has(name):
        return
    draw_circle(Vector2(0, -19), 11.0, Color("#c99a71"))
    draw_colored_polygon(PackedVector2Array([Vector2(-11,-9),Vector2(11,-9),Vector2(14,13),Vector2(-14,13)]), Color("#805b46"))
    draw_arc(Vector2(0,-22),12.0,PI,TAU,16,Color("#302b27"),4.0)
func draw_ellipse_shadow() -> void:
    draw_circle(Vector2(0,15),12.0,Color(0,0,0,0.35))
