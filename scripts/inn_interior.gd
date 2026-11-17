extends Node2D
## Separate off-map inn room; no modifications to the exterior village art.
func _draw() -> void:
    draw_rect(Rect2(-420,-270,840,540), Color("#201c1b"))
    draw_rect(Rect2(-390,-240,780,480), Color("#76553a"))
    for x in range(-380,390,65):
        draw_line(Vector2(x,-230),Vector2(x,230),Color("#61442f"),2.0)
    for y in range(-230,240,65):
        draw_line(Vector2(-380,y),Vector2(380,y),Color("#61442f"),2.0)
    draw_rect(Rect2(-375,-225,750,18),Color("#372c2a"))
    draw_rect(Rect2(-375,207,750,18),Color("#372c2a"))
    draw_rect(Rect2(-375,-220,18,440),Color("#372c2a"))
    draw_rect(Rect2(357,-220,18,440),Color("#372c2a"))
    draw_rect(Rect2(-305,-190,145,80),Color("#3c2b27"))
    draw_rect(Rect2(-289,-173,110,46),Color("#e78d3c"))
    draw_circle(Vector2(-235,-149),26.0,Color("#f5ba60"))
    draw_rect(Rect2(115,-155,185,80),Color("#4a3024"))
    draw_rect(Rect2(135,-140,145,48),Color("#966d46"))
    draw_rect(Rect2(-120,-25,220,110),Color("#3a281f"))
    draw_rect(Rect2(-104,-12,188,80),Color("#a67b51"))
    for p in [Vector2(-150,100),Vector2(120,110),Vector2(-140,-90)]:
        draw_circle(p,25.0,Color("#5d3b28"))
        draw_circle(p,17.0,Color("#a88052"))
    draw_rect(Rect2(-65,203,130,22),Color("#bd9567"))
    draw_string(ThemeDB.fallback_font,Vector2(-110,-245),"WAYFARER INN",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("#f3dba9"))
    draw_string(ThemeDB.fallback_font,Vector2(-75,195),"EXIT  ↓",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#f3dba9"))
