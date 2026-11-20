extends Node2D

const Wolf := preload("res://scripts/pinewood_wolf.gd")
const SPEED := 520.0
const LIFETIME := 0.95
const IMPACT_DURATION := 0.22

var target: Wolf
var direction := Vector2.UP
var remaining := LIFETIME
var burst := 0.0

func detonate() -> void:
	burst = IMPACT_DURATION
	queue_redraw()

func _draw() -> void:
	if burst > 0.0:
		var fade := burst / IMPACT_DURATION
		var radius := lerpf(11.0, 38.0, 1.0 - fade)
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.31, 0.06, fade * 0.35))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 30, Color(1.0, 0.72, 0.28, fade), 4.0, true)
		return
	for i in range(6, 0, -1):
		var offset := -direction * float(i * 6)
		draw_circle(offset, 8.0 - i * 0.8, Color(0.94, 0.34, 0.12, 0.8 - i * 0.10))
	draw_circle(Vector2.ZERO, 12.0, Color(0.95, 0.30, 0.07, 0.55))
	draw_circle(Vector2.ZERO, 8.0, Color("#f88823"))
	draw_circle(Vector2.ZERO, 4.5, Color("#fff0a9"))
