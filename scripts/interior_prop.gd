extends Sprite2D
## A room-local sprite anchored at the bottom of its ground footprint.

const ROOT := "res://art/interiors/"
const Collision := preload("res://scripts/world_collision.gd")

var actor: CharacterBody2D
var actor_feet: CollisionShape2D

static func place(parent: Node2D, asset: String, ground: Vector2,
        footprint := Vector2.ZERO, sort_actor: CharacterBody2D = null, layer := 2) -> Sprite2D:
    var prop := new()
    prop.name = asset.get_file()
    prop.texture = load((ROOT + asset + ".png").simplify_path()) as Texture2D
    if prop.texture == null:
        return null
    prop.position = ground
    prop.offset.y = -prop.texture.get_height() * 0.5
    prop.z_index = layer
    prop.actor = sort_actor
    if sort_actor != null:
        prop.actor_feet = sort_actor.get_node("Feet") as CollisionShape2D
    parent.add_child(prop, true)
    if footprint != Vector2.ZERO:
        Collision.box(prop, "Footprint", Rect2(Vector2(-footprint.x * 0.5, -footprint.y), footprint))
    return prop

func _ready() -> void:
    set_process(actor != null)
    if actor != null:
        _process(0.0)

func _process(_delta: float) -> void:
    # The player uses a fixed layer shared with the outdoor scenes.
    z_index = actor.z_index + (1 if actor_feet.global_position.y < global_position.y else -1)

static func loop(parent: Node2D, effect: String, center: Vector2, fps: float) -> AnimatedSprite2D:
    var frames := SpriteFrames.new()
    frames.set_animation_speed(&"default", fps)
    for i in range(4):
        frames.add_frame(&"default", load(ROOT + "effects/%s_%d.png" % [effect, i]) as Texture2D)
    var sprite := AnimatedSprite2D.new()
    sprite.sprite_frames = frames
    sprite.position = center
    parent.add_child(sprite)
    sprite.play()
    return sprite
