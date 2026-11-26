extends PanelContainer

signal close_requested

func _input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_I, KEY_ESCAPE]:
        get_viewport().set_input_as_handled()
        close_requested.emit()
