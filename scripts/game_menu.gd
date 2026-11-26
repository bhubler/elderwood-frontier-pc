extends CanvasLayer

const ElderwoodType := preload("res://scripts/elderwood_type.gd")

const AreaTransition := preload("res://scripts/area_transition.gd")
const Saves := preload("res://scripts/playthrough_save.gd")
const PanelHeader := preload("res://scripts/panel_header.gd")
const WORLD_PATH := "res://scenes/world.tscn"

var world: Node2D
var content: VBoxContainer
var overlay: ColorRect
var page := "title"
var confirm_slot := 0

func _ready() -> void:
    layer = 110
    process_mode = Node.PROCESS_MODE_ALWAYS
    overlay = ColorRect.new()
    add_child(overlay)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var center := CenterContainer.new()
    overlay.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 430
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#1b1d1b")
    style.border_color = Color("#917044")
    style.set_border_width_all(1)
    style.content_margin_left = 26
    style.content_margin_right = 26
    style.content_margin_top = 22
    style.content_margin_bottom = 22
    panel.add_theme_stylebox_override("panel", style)
    center.add_child(panel)
    content = VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    panel.add_child(content)
    _show_title()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event.is_action_pressed("ui_cancel") or event.is_echo() or not is_instance_valid(world):
        return
    if get_tree().get_first_node_in_group(&"area_transition") != null:
        return
    if overlay.visible and page != "pause":
        _show_pause()
    elif overlay.visible:
        _resume()
    else:
        _show_pause()
    get_viewport().set_input_as_handled()

func _heading(title: String, close := Callable()) -> void:
    for child in content.get_children():
        content.remove_child(child)
        child.queue_free()
    var heading := Label.new()
    ElderwoodType.heading(heading)
    heading.text = title
    heading.add_theme_font_size_override("font_size", 28)
    heading.add_theme_color_override("font_color", Color("#e5cda0"))
    if close.is_valid():
        PanelHeader.add_title(content, heading, close)
    else:
        content.add_child(heading)

func _button(label: String, action: Callable, enabled := true) -> Button:
    var button := Button.new()
    button.text = label
    button.custom_minimum_size.y = 38
    button.disabled = not enabled
    button.pressed.connect(action)
    content.add_child(button)
    return button

func _status(message: String) -> void:
    var label := Label.new()
    label.text = message
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(label)

func _show_title() -> void:
    page = "title"
    overlay.color = Color("#101713")
    overlay.show()
    _heading("Elderwood Frontier")
    _button("New Game", _start_game.bind(null)).grab_focus()
    var latest := _latest_slot()
    _button("Continue", _load_slot.bind(latest), latest > 0)
    _button("Load Game", _show_slots.bind(false), latest > 0)
    _button("Quit", get_tree().quit)

func _show_pause() -> void:
    page = "pause"
    get_tree().paused = true
    overlay.color = Color(0.04, 0.06, 0.05, 0.84)
    overlay.show()
    _heading("Paused", _resume)
    _button("Resume", _resume).grab_focus()
    _button("Save Game", _show_slots.bind(true), not world.get_node("Player").choosing_race)
    _button("Load Game", _show_slots.bind(false), _latest_slot() > 0)
    _button("Return to Title", _confirm_return_to_title)

func _resume() -> void:
    overlay.hide()
    get_tree().paused = false

func _confirm_return_to_title() -> void:
    page = "confirm"
    _heading("Return to Title", _show_pause)
    _status("Progress since your last save will be lost.")
    _button("Return to Title", _return_to_title)
    _button("Cancel", _show_pause).grab_focus()

func _return_to_title() -> void:
    _clear_world()
    get_tree().paused = false
    _show_title()

func _back() -> void:
    if is_instance_valid(world):
        _show_pause()
    else:
        _show_title()

func _show_slots(saving: bool) -> void:
    page = "slots"
    confirm_slot = 0
    _heading("Save Game" if saving else "Load Game", _back)
    for slot in range(1, Saves.SLOT_COUNT + 1):
        var file := Saves.read_slot(slot)
        var detail := "Empty"
        if file != null:
            var location: String = file.get_value("world", "location", "village")
            var name := str(Saves.Layouts.REGIONS[location]["title"]) if Saves.Layouts.REGIONS.has(location) else location.capitalize()
            if location == "village":
                name = "Elderwood Village"
            elif location == "inn":
                name = "Wayfarer Inn"
            var timestamp := int(file.get_value("save", "timestamp", 0)) + int(Time.get_time_zone_from_system()["bias"]) * 60
            var saved_at := Time.get_datetime_string_from_unix_time(timestamp, true).substr(0, 16)
            detail = "%s\n%s" % [name, saved_at]
        var action := _save_slot.bind(slot) if saving else _load_slot.bind(slot)
        _button("Slot %d  ·  %s" % [slot, detail], action, saving or file != null)

func _latest_slot() -> int:
    var latest := 0
    var timestamp := -1.0
    for slot in range(1, Saves.SLOT_COUNT + 1):
        var file := Saves.read_slot(slot)
        if file == null:
            continue
        var modified := float(file.get_value("save", "timestamp", 0))
        if modified > timestamp:
            latest = slot
            timestamp = modified
    return latest

func _save_slot(slot: int) -> void:
    if FileAccess.file_exists(Saves.slot_path(slot)) and confirm_slot != slot:
        confirm_slot = slot
        _heading("Overwrite Slot %d?" % slot, _show_slots.bind(true))
        _status("This replaces the previous save in this slot.")
        _button("Overwrite Save", _save_slot.bind(slot))
        _button("Cancel", _show_slots.bind(true)).grab_focus()
        return
    var result := Saves.write_slot(world.get_node("VillageInteractions"), slot)
    _show_slots(true)
    _status("Saved to slot %d." % slot if result == OK else "Could not save slot %d. %s" % [slot, error_string(result)])

func _load_slot(slot: int) -> void:
    var file := Saves.read_slot(slot)
    if file == null:
        _status("This save could not be loaded.")
        return
    if is_instance_valid(world):
        page = "confirm"
        _heading("Load Slot %d?" % slot, _show_slots.bind(false))
        _status("Progress since your last save will be lost.")
        _button("Load Save", _start_game.bind(file))
        _button("Cancel", _show_slots.bind(false)).grab_focus()
    else:
        _start_game(file)

func _start_game(file: ConfigFile) -> void:
    AreaTransition.run(get_tree(), _load_world.bind(file))

func _load_world(file: ConfigFile) -> void:
    _clear_world()
    get_tree().paused = false
    var scene := load(WORLD_PATH) as PackedScene
    world = scene.instantiate()
    get_tree().root.add_child(world)
    if file != null:
        Saves.restore(world.get_node("VillageInteractions"), file)
    overlay.hide()

func _clear_world() -> void:
    if not is_instance_valid(world):
        return
    var chapter: Node = world.get_node("VillageInteractions").chapter
    if is_instance_valid(chapter):
        chapter.get_parent().remove_child(chapter)
        chapter.queue_free()
    world.get_parent().remove_child(world)
    world.queue_free()
    world = null
