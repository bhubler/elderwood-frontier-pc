extends Node2D
## A proximity prompt with a stable action ID. The enclosing region owns outcomes.
@export var action_id := ""
@export var title := ""
@export var radius := 70.0
@export var show_caption := true
@export var show_disc := true
@export var marker_color := Color("#d3b982")

func _ready() -> void:
    if not show_caption:
        return
    var caption := Label.new()
    caption.text = title
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.position = Vector2(-125, -52)
    caption.custom_minimum_size.x = 250
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(caption)

func _draw() -> void:
    if not show_disc:
        return
    draw_circle(Vector2.ZERO, 12, marker_color)
    draw_arc(Vector2.ZERO, 17, 0, TAU, 24, marker_color, 2, true)
