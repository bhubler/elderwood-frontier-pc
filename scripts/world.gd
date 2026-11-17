extends Node2D
## Prototype-only procedural isometric tiles and decorative props.
## Art is drawn in code for now; later replaced by licensed sprite sheets.
const TILE_W: float = 96.0
const TILE_H: float = 48.0
const EXTENT: int = 24
var props: Array[Dictionary] = []

func _ready() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 17361
    for i in range(180):
        var tx := rng.randi_range(-EXTENT + 2, EXTENT - 2)
        var ty := rng.randi_range(-EXTENT + 2, EXTENT - 2)
        if abs(tx) + abs(ty) < 6:
            continue
        props.append({
            "pos": iso(tx, ty),
            "type": rng.randi_range(0, 2),
            "scale": rng.randf_range(0.8, 1.35)
        })
    props.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return a["pos"].y < b["pos"].y)
    queue_redraw()

func iso(tx: int, ty: int) -> Vector2:
    return Vector2((tx - ty) * TILE_W * 0.5, (tx + ty) * TILE_H * 0.5)

func _draw() -> void:
    for ty in range(-EXTENT, EXTENT + 1):
        for tx in range(-EXTENT, EXTENT + 1):
            var c := iso(tx, ty)
            var path_tile := abs(tx - ty) < 2 or abs(tx + ty) < 2
            var tint := Color("#786c50") if path_tile else Color("#314b37")
            if not path_tile and posmod(tx * 7 + ty * 13, 9) < 3:
                tint = Color("#3b563c")
            var diamond := PackedVector2Array([
                c + Vector2(0, -TILE_H * 0.5),
                c + Vector2(TILE_W * 0.5, 0),
                c + Vector2(0, TILE_H * 0.5),
                c + Vector2(-TILE_W * 0.5, 0)
            ])
            draw_colored_polygon(diamond, tint)
            draw_polyline(PackedVector2Array([
                diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]
            ]), Color(0.1, 0.17, 0.12, 0.16), 1.0)
    for prop in props:
        var at: Vector2 = prop["pos"]
        var s: float = prop["scale"]
        match int(prop["type"]):
            0:
                draw_line(at, at + Vector2(0, -42 * s), Color("#594734"), 8 * s)
                draw_circle(at + Vector2(0, -50 * s), 23 * s, Color("#1d382f"))
                draw_circle(at + Vector2(-8 * s, -58 * s), 15 * s, Color("#2d5944"))
            1:
                draw_circle(at, 10 * s, Color("#65716a"))
                draw_circle(at + Vector2(-3 * s, -4 * s), 5 * s, Color("#85938a"))
            2:
                draw_circle(at, 5 * s, Color("#7a6947"))
                draw_line(at, at + Vector2(0, -14 * s), Color("#466c4c"), 2 * s)
                draw_circle(at + Vector2(0, -14 * s), 4 * s, Color("#b9a16b"))
