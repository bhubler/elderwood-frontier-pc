extends Node2D
## Editor playtest scene for reviewing each catalog appearance beside the player.

const Spells := preload("res://scripts/npc/spell_effects.gd")
const Library := preload("res://scripts/npc/npc_library.gd")

@onready var player: CharacterBody2D = $Player
@onready var caption: Label = $HUD/Caption

var roles := Library.ROSTER.keys()
var role_index := 0
var appearance_index := 0
var npc: Node2D
var active_effect: AnimatedSprite2D

func _ready() -> void:
	player._choose_race("Human")
	roles.append("spell_effects")
	_show_appearance()

func _show_appearance() -> void:
	if is_instance_valid(npc):
		npc.queue_free()
		npc = null
	_clear_effect()
	var role: String = roles[role_index]
	if role == "spell_effects":
		appearance_index = posmod(appearance_index, Spells.EFFECTS.size())
		var spell: String = Spells.EFFECTS.keys()[appearance_index]
		caption.text = "%s  ·  %s\nTab: role   Q/E: effect   1: wind-up   2: active   3: finish" % [
			spell.capitalize(), Spells.EFFECTS[spell],
		]
		return
	var list := Library.appearances(role)
	if list.is_empty():
		caption.text = "%s   |   No sheets installed\nTab: role" % role.capitalize()
		return
	appearance_index = posmod(appearance_index, list.size())
	var entry := list[appearance_index]
	npc = Library.create(entry.sheet, entry.wardrobe)
	npc.position = Vector2(75, 33)
	add_child(npc)
	caption.text = "%s  %d/%d  ·  %s  ·  Outfit %d\nTab: role   V: spells   Q/E: appearance   1: interact   2: attack   3: hit   4: defeat   R: reset" % [
		role.capitalize(), appearance_index + 1, list.size(), entry.sheet.capitalize(), entry.wardrobe + 1,
	]

func _clear_effect() -> void:
	if is_instance_valid(active_effect):
		active_effect.queue_free()
		active_effect = null

func _play_spell_phase(index: int) -> void:
	var spell: String = Spells.EFFECTS.keys()[appearance_index]
	var source := Spells.frames(spell)
	if source == null:
		return
	_clear_effect()
	var stages: Array[StringName] = [&"windup"]
	for choices in [[&"flight", &"arrival", &"sustain", &"transfer", &"glow"], [&"impact", &"expire", &"activate"]]:
		for clip in choices:
			if source.has_animation(clip):
				stages.append(clip)
				break
	if index >= 0 and index < stages.size():
		active_effect = Spells.play(self, spell, stages[index], player.position + Vector2(75, -20))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_TAB:
			role_index = posmod(role_index + (-1 if event.shift_pressed else 1), roles.size())
			appearance_index = 0
			_show_appearance()
		KEY_V:
			role_index = roles.size() - 1
			appearance_index = 0
			_show_appearance()
		KEY_Q, KEY_E:
			appearance_index += 1 if event.keycode == KEY_E else -1
			_show_appearance()
		KEY_R:
			_show_appearance()
		KEY_1, KEY_2, KEY_3, KEY_4:
			if roles[role_index] == "spell_effects":
				_play_spell_phase(event.keycode - KEY_1)
			elif is_instance_valid(npc):
				match event.keycode:
					KEY_1: npc.interact()
					KEY_2: npc.attack()
					KEY_3: npc.react_to_hit(false)
					KEY_4: npc.react_to_hit(true)
		_:
			return
	get_viewport().set_input_as_handled()
