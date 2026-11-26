extends PanelContainer

const ElderwoodType := preload("res://scripts/elderwood_type.gd")
## Shared illustrated layout for NPC conversations, quest boards, and choice dialogs.

const Finish := preload("res://scripts/inventory_finish.gd")
const Portrait := preload("res://scripts/dialogue_portrait.gd")
const PanelHeader := preload("res://scripts/panel_header.gd")

var portrait: Portrait
var header: VBoxContainer
var title: Label
var content: VBoxContainer
var details: Label

func build(close: Callable) -> void:
    custom_minimum_size.x = 850
    Finish.style_dialog(self)
    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation", 18)
    add_child(columns)

    var portrait_frame := PanelContainer.new()
    portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    portrait_frame.add_theme_stylebox_override("panel",
        Finish.surface(Finish.RECESS, Finish.BRASS, 9, true, true))
    columns.add_child(portrait_frame)
    portrait = Portrait.new()
    portrait.custom_minimum_size = Vector2(196, 196)
    portrait_frame.add_child(portrait)

    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 9)
    columns.add_child(content)
    var header_frame := PanelContainer.new()
    Finish.style_dialog(header_frame)
    content.add_child(header_frame)
    header = VBoxContainer.new()
    header_frame.add_child(header)
    var title_row := HBoxContainer.new()
    header.add_child(title_row)
    var balance := Control.new()
    balance.custom_minimum_size.x = 34
    title_row.add_child(balance)
    title = Label.new()
    ElderwoodType.heading(title)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 23)
    title.add_theme_color_override("font_color", Finish.GOLD)
    title_row.add_child(title)
    PanelHeader.add_close_button(title_row, close)
    Finish.style_dialog_action(title_row.get_node("CloseButton"))

    var details_frame := PanelContainer.new()
    details_frame.add_theme_stylebox_override("panel",
        Finish.surface(Finish.RECESS, Finish.BRASS, 12, true))
    content.add_child(details_frame)
    details = Label.new()
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.add_theme_font_size_override("font_size", 16)
    details.add_theme_color_override("font_color", Finish.INK)
    details_frame.add_child(details)
