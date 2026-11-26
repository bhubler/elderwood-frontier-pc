extends Control

const PlayerArt := preload("res://scripts/player.gd")

var portrait: Texture2D
var weapon_id := ""
var sword_pose := false

func show_character(actor: Node, weapon: String) -> void:
    weapon_id = weapon
    var art: Sprite2D = actor.race_sprite
    if is_instance_valid(actor.necromancer_sprite) and actor.necromancer_sprite.visible:
        art = actor.necromancer_sprite
    portrait = art.texture if is_instance_valid(art) else null
    sword_pose = actor.race == "Human" and art == actor.race_sprite and weapon in ["rusty_sword", "sentinel_sword"]
    queue_redraw()

func _draw() -> void:
    var center := Vector2(size.x * 0.5, size.y * 0.5)
    var border := Color("#6b5438")
    var outer := Rect2(Vector2(6, 6), size - Vector2(12, 12))
    draw_rect(outer, Color("#141b19"))
    draw_rect(outer.grow(-5), border, false)
    var available := size - Vector2(24, 24)
    if sword_pose:
        var frame := PlayerArt.SWORD_FRAME_SIZE
        var crop := Rect2(19, 8, 71, 96)
        var zoom := minf(available.x / crop.size.x, available.y / crop.size.y)
        var destination := Rect2(center - crop.size * zoom * 0.5, crop.size * zoom)
        draw_texture_rect_region(PlayerArt.SWORD_SWING_ART, destination,
            Rect2(Vector2(frame * 3, 0) + crop.position, crop.size))
        if weapon_id == "sentinel_sword":
            draw_set_transform(destination.position - crop.position * zoom, 0.0, Vector2.ONE * zoom)
            # The front recovery pose holds the grip around (42, 64).
            draw_line(Vector2(41, 64), Vector2(64, 96), Color("#292e37"), 5.0)
            draw_colored_polygon(PackedVector2Array([
                Vector2(42, 66), Vector2(47, 69), Vector2(66, 98), Vector2(61, 96)
            ]), Color("#a2c5db"))
            draw_line(Vector2(44, 67), Vector2(64, 96), Color("#d5e3e8"), 1.4)
            draw_line(Vector2(39, 70), Vector2(48, 64), Color("#b59256"), 2.5)
    elif portrait != null:
        var source := portrait.get_size()
        var fitted := source * minf(available.x / source.x, available.y / source.y)
        draw_texture_rect(portrait, Rect2(center - fitted * 0.5, fitted), false)
