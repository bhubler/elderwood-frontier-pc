extends RefCounted

static func draw_ground(canvas: CanvasItem, camera_bounds: Rect2, roads: Array, urban: bool) -> void:
    canvas.draw_rect(camera_bounds, Color("#3c3a32") if urban else Color("#283d30"))
    var rng := RandomNumberGenerator.new()
    rng.seed = 9368
    for x in range(int(camera_bounds.position.x), int(camera_bounds.end.x), 96):
        for y in range(int(camera_bounds.position.y), int(camera_bounds.end.y), 68):
            var p := Vector2(x + rng.randf_range(4, 70), y + rng.randf_range(4, 50))
            var tint := Color("#424038") if urban else Color("#354b38")
            canvas.draw_colored_polygon(PackedVector2Array([
                p + Vector2(-49, 0), p + Vector2(0, -27), p + Vector2(49, 0), p + Vector2(0, 27)
            ]), tint.lightened(rng.randf_range(0, 0.035)))
    for road in roads:
        var route := PackedVector2Array(road)
        canvas.draw_polyline(route, Color("#34312b") if urban else Color("#414031"), 121, true)
        canvas.draw_polyline(route, Color("#665d4f") if urban else Color("#60513a"), 103, true)
        canvas.draw_polyline(route, Color("#746b5a") if urban else Color("#6d5b40"), 72, true)
        for i in range(1, route.size()):
            var a: Vector2 = route[i - 1]
            var b: Vector2 = route[i]
            var normal := a.direction_to(b).orthogonal()
            var steps := maxi(1, roundi(a.distance_to(b) / (18.0 if urban else 28.0)))
            for step in range(steps):
                var p := a.lerp(b, float(step) / steps)
                for lane in range(-2, 3):
                    var center := p + normal * (lane * 17 + rng.randf_range(-4, 4))
                    var size := Vector2(rng.randf_range(12, 22), rng.randf_range(6, 10)) if urban else Vector2(rng.randf_range(2, 7), rng.randf_range(2, 5))
                    canvas.draw_rect(Rect2(center - size / 2, size), Color("#4c493e") if step % 3 == 0 else Color("#807361"))
