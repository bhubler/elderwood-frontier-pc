extends RefCounted

const Art := preload("res://scripts/wayfinding_art.gd")
const QUEST_PATH := "res://art/ui/quest_markers.png"
static var quest_icons: Dictionary = {}
static var glows: Dictionary = {}

static func add_entrance_glow(parent: Node2D, where: Vector2, hidden := false) -> Sprite2D:
    if not glows.has(hidden):
        var color := Color("#d76559") if hidden else Color("#efbb63")
        var stops := Gradient.new()
        stops.offsets = PackedFloat32Array([0.0, 0.38, 0.72, 1.0])
        stops.colors = PackedColorArray([
            Color(color, 0.21 if hidden else 0.42),
            Color(color, 0.10 if hidden else 0.25),
            Color(color, 0.025 if hidden else 0.07),
            Color(color, 0.0),
        ])
        var texture := GradientTexture2D.new()
        texture.gradient = stops
        texture.fill = GradientTexture2D.FILL_RADIAL
        texture.fill_from = Vector2(0.5, 0.5)
        texture.fill_to = Vector2(1.0, 0.5)
        texture.width = 64
        texture.height = 64
        glows[hidden] = texture
    var glow := Sprite2D.new()
    glow.name = "HiddenEntranceGlow" if hidden else "EntranceGlow"
    glow.texture = glows[hidden]
    glow.position = where
    glow.scale = Vector2(1.05, 0.38) if hidden else Vector2(1.5, 0.58)
    glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    glow.z_index = 2
    parent.add_child(glow, true)
    return glow

static func quest_icon(turn_in: bool) -> Texture2D:
    if not quest_icons.has(turn_in):
        var source := Art._texture(QUEST_PATH)
        if source == null:
            return null
        var icon := AtlasTexture.new()
        icon.atlas = source
        icon.region = Rect2(64 if turn_in else 0, 0, 64, 64)
        icon.filter_clip = true
        quest_icons[turn_in] = icon
    return quest_icons[turn_in]

static func update_quest_marker(actor: Node2D, available: bool, turn_in := false) -> void:
    if not is_instance_valid(actor):
        return
    var marker := actor.get_node_or_null("QuestMarker") as Sprite2D
    if marker == null and (available or turn_in):
        marker = Sprite2D.new()
        marker.name = "QuestMarker"
        marker.position = Vector2(0, -88)
        marker.scale = Vector2.ONE * 0.5
        marker.z_index = 11
        actor.add_child(marker)
    if marker != null:
        marker.visible = available or turn_in
        if marker.visible:
            marker.texture = quest_icon(turn_in)
