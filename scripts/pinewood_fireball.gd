extends Node2D

const FRAMES := preload("res://art/effects/fireball.tres")
const Wolf := preload("res://scripts/pinewood_wolf.gd")
const SPEED := 520.0
const LIFETIME := 0.95
const IMPACT_DURATION := 0.22

var target: Wolf
var direction := Vector2.UP
var remaining := LIFETIME
var burst := 0.0

var effect: AnimatedSprite2D

func _ready() -> void:
	effect = AnimatedSprite2D.new()
	effect.sprite_frames = FRAMES
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.rotation = direction.angle()
	add_child(effect)
	effect.play(&"flight")

func detonate() -> void:
	burst = IMPACT_DURATION
	effect.rotation = 0.0
	effect.play(&"impact")

func point_along_flight() -> void:
	effect.rotation = direction.angle()
