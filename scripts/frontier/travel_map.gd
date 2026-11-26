extends CanvasLayer

signal travel_requested(id: String)
const Chart := preload("res://scripts/frontier/travel_map_chart.gd")
const Finish := preload("res://scripts/inventory_finish.gd")
const Type := preload("res://scripts/elderwood_type.gd")
const PanelHeader := preload("res://scripts/panel_header.gd")

var panel: PanelContainer
var chart: Chart
var status: Label
var travel: Button
var travel_block := ""

func _ready() -> void:
    layer = 61
    process_mode = Node.PROCESS_MODE_ALWAYS
    panel = PanelContainer.new()
    add_child(panel)
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Finish.style_dialog(panel)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 10)
    panel.add_child(layout)
    var title := Label.new()
    title.text = "Frontier Map"
    title.add_theme_font_size_override("font_size", 26)
    Type.heading(title)
    PanelHeader.add_title(layout, title, close)
    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 12)
    layout.add_child(body)
    chart = Chart.new()
    chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    chart.landmark_selected.connect(_select_landmark)
    body.add_child(chart)
    var side := VBoxContainer.new()
    side.custom_minimum_size.x = 286
    body.add_child(side)
    var legend := Label.new()
    legend.text = "Travel"
    Type.heading(legend)
    side.add_child(legend)
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    side.add_child(spacer)
    status = Label.new()
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    side.add_child(status)
    travel = Button.new()
    travel.text = "Fast Travel"
    Finish.style_dialog_action(travel)
    travel.pressed.connect(func() -> void: travel_requested.emit(chart.selected))
    side.add_child(travel)
    hide()

func open(file: ConfigFile, region: String, position: Vector2, blocked: String) -> void:
    chart.progress = file
    chart.current_region = region
    chart.current_position = position
    travel_block = blocked
    _select_landmark("")
    show()
    get_tree().paused = true

func close() -> void:
    if not visible:
        return
    hide()
    get_tree().paused = false

func _input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_M, KEY_ESCAPE]:
        get_viewport().set_input_as_handled()
        close()

func _select_landmark(id: String) -> void:
    chart.selected = id
    travel.disabled = id.is_empty() or not travel_block.is_empty()
    if not travel_block.is_empty():
        status.text = travel_block
    elif id.is_empty():
        status.text = "Click a discovered landmark on the map to travel there."
    else:
        status.text = Chart.PLACES[id][1]
    chart.queue_redraw()
