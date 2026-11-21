extends CanvasLayer

const GROUP := &"area_transition"

static func run(tree: SceneTree, change_area: Callable) -> void:
    if tree.get_first_node_in_group(GROUP) != null:
        return
    var screen := new()
    screen.add_to_group(GROUP)
    tree.root.add_child(screen)
    # Let the current frame finish and give the cover a frame to draw before loading.
    await tree.process_frame
    await tree.process_frame
    if change_area.is_valid():
        change_area.call()
    await tree.create_timer(0.15).timeout
    screen.queue_free()

func _ready() -> void:
    layer = 100
    process_mode = Node.PROCESS_MODE_ALWAYS
    var black := ColorRect.new()
    black.color = Color.BLACK
    add_child(black)
    black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var center := CenterContainer.new()
    black.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var title := Label.new()
    title.text = "Elderwood Frontier"
    title.add_theme_font_size_override("font_size", 34)
    center.add_child(title)

func _input(_event: InputEvent) -> void:
    get_viewport().set_input_as_handled()
