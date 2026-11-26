shader_type canvas_item;
render_mode unshaded;

void fragment() {
    // Small, overlapping waves make the light shimmer without moving the threshold.
    vec2 uv = UV;
    uv.x += 0.018 * sin(TIME * 2.2 + UV.y * 7.0);
    uv.y += 0.024 * sin(TIME * 2.9 + UV.x * 9.0);
    vec4 glow = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
    float flicker = 0.88 + 0.07 * sin(TIME * 3.0 + UV.x * 6.0)
        + 0.04 * sin(TIME * 6.2 + UV.y * 5.0);
    COLOR = vec4(glow.rgb, glow.a * flicker);
}
