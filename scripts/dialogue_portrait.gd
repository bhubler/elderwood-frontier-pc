extends TextureRect
## Displays the speaker's in-world artwork, including their wardrobe variant.

func _init() -> void:
    custom_minimum_size = Vector2(112, 128)
    size_flags_vertical = Control.SIZE_SHRINK_CENTER
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_speaker(actor: Node, fallback: Texture2D = null) -> void:
    texture = fallback
    material = null
    flip_h = false
    if is_instance_valid(actor):
        var art := actor.get_node_or_null("Artwork") as Sprite2D
        var animator := actor.get_node_or_null("Sprite") as AnimatedSprite2D
        if art != null:
            texture = art.texture
            flip_h = art.flip_h
        elif animator != null and animator.sprite_frames != null and animator.sprite_frames.has_animation(&"idle"):
            texture = animator.sprite_frames.get_frame_texture(&"idle", 0)
            material = animator.material
            flip_h = animator.flip_h
    visible = texture != null
