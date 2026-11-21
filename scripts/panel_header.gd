extends RefCounted

static func add_close_button(header: HBoxContainer, close: Callable) -> void:
    var button := Button.new()
    button.name = "CloseButton"
    button.text = "X"
    button.tooltip_text = "Close"
    button.custom_minimum_size = Vector2(34, 32)
    button.pressed.connect(close)
    header.add_child(button)

static func add_title(content: VBoxContainer, title: Label, close: Callable) -> void:
    var header := HBoxContainer.new()
    content.add_child(header)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    add_close_button(header, close)
