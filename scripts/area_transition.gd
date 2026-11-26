extends CanvasLayer

const GROUP := &"area_transition"
const POSTER_PATH := "res://art/ui/frontier_loading.webp"
const VIDEO_PATH := "res://art/ui/frontier_loading.ogv"
const MINIMUM_VISIBLE_SECONDS := 0.4

var video: VideoStreamPlayer

static func run(tree: SceneTree, change_area: Callable) -> void:
    if tree.get_first_node_in_group(GROUP) != null:
        return
    var screen := new()
    screen.add_to_group(GROUP)
    tree.root.add_child(screen)
    var started := Time.get_ticks_msec()
    # Give the loading artwork a rendered frame before scene construction.
    await tree.process_frame
    await tree.process_frame
    if change_area.is_valid():
        change_area.call()
    var elapsed := float(Time.get_ticks_msec() - started) / 1000.0
    await tree.create_timer(maxf(0.0, MINIMUM_VISIBLE_SECONDS - elapsed)).timeout
    screen.queue_free()

func _ready() -> void:
    layer = 120
    process_mode = Node.PROCESS_MODE_ALWAYS
    var black := ColorRect.new()
    black.color = Color.BLACK
    add_child(black)
    black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    black.clip_contents = true
    var poster := TextureRect.new()
    poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    black.add_child(poster)
    poster.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if ResourceLoader.exists(POSTER_PATH, "Texture2D"):
        poster.texture = load(POSTER_PATH) as Texture2D
    else:
        var image := Image.new()
        if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(POSTER_PATH)) == OK:
            poster.texture = ImageTexture.create_from_image(image)

    var stream := load(VIDEO_PATH) as VideoStream
    if stream == null:
        return
    var aspect := AspectRatioContainer.new()
    aspect.ratio = 16.0 / 9.0
    aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
    black.add_child(aspect)
    aspect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    video = VideoStreamPlayer.new()
    video.stream = stream
    video.expand = true
    video.loop = true
    video.modulate.a = 0.0
    aspect.add_child(video)
    video.play()

func _process(_delta: float) -> void:
    if video != null and video.stream_position > 0.0:
        video.modulate.a = 1.0
        set_process(false)

func _input(_event: InputEvent) -> void:
    get_viewport().set_input_as_handled()
