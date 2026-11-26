extends CanvasLayer

signal travel_requested(id: String)
const Data := preload("res://scripts/frontier/travel_map_data.gd")
const Chart := preload("res://scripts/frontier/travel_map_chart.gd")
const Finish := preload("res://scripts/inventory_finish.gd")
const Type := preload("res://scripts/elderwood_type.gd")
const PanelHeader := preload("res://scripts/panel_header.gd")

var panel: PanelContainer
var chart: Chart
var locations: VBoxContainer
var region_picker: OptionButton
var status: Label
var travel: Button
var progress: ConfigFile
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
    region_picker = OptionButton.new()
    for id: String in Data.REGIONS:
        region_picker.add_item(Data.REGIONS[id][0])
    region_picker.item_selected.connect(_select_region)
    Finish.style_dialog_action(region_picker)
    layout.add_child(region_picker)
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
    legend.text = "Discovered landmarks"
    Type.heading(legend)
    side.add_child(legend)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.follow_focus = true
    side.add_child(scroll)
    locations = VBoxContainer.new()
    locations.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(locations)
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
    progress = file
    chart.progress = file
    chart.current_region = region
    chart.current_position = position
    travel_block = blocked
    var index := Data.REGIONS.keys().find(region)
    if index < 0:
        index = Data.REGIONS.keys().find(file.get_value("map", "last_region", "village"))
    region_picker.select(maxi(index, 0))
    _select_region(region_picker.selected)
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

func _select_region(index: int) -> void:
    chart.region = Data.REGIONS.keys()[index]
    for child in locations.get_children():
        locations.remove_child(child)
        child.queue_free()
    var visited := Data.discovered(progress)
    for id: String in Data.LANDMARKS:
        var entry: Array = Data.LANDMARKS[id]
        if entry[0] == chart.region and visited.has(id):
            var pin := Button.new()
            pin.text = entry[1]
            Finish.style_dialog_action(pin)
            pin.pressed.connect(_select_landmark.bind(id))
            locations.add_child(pin)
    _select_landmark("")

func _select_landmark(id: String) -> void:
    chart.selected = id
    travel.disabled = id.is_empty() or not travel_block.is_empty()
    if not travel_block.is_empty():
        status.text = travel_block
    elif id.is_empty():
        status.text = "Explore to uncover the map and discover places to travel."
    else:
        status.text = Data.LANDMARKS[id][1]
    chart.queue_redraw()
