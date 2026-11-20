shader_type canvas_item;

// Shift cloth midtones. Preserve the outline, brightest highlights and skin.
uniform vec3 shade : source_color = vec3(0.52, 0.44, 0.31);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 pixel = COLOR;
	float lightness = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	float chroma = max(pixel.r, max(pixel.g, pixel.b)) - min(pixel.r, min(pixel.g, pixel.b));
	float warm_skin = smoothstep(0.15, 0.28, pixel.r - pixel.b)
		* smoothstep(0.52, 0.68, lightness);
	float cloth = smoothstep(0.12, 0.27, lightness)
		* (1.0 - smoothstep(0.72, 0.85, lightness))
		* (1.0 - warm_skin) * smoothstep(0.035, 0.15, chroma);
	vec3 dyed = clamp(shade * (lightness / max(dot(shade, vec3(0.299, 0.587, 0.114)), 0.1)), vec3(0.0), vec3(1.0));
	COLOR = vec4(mix(pixel.rgb, dyed, cloth * amount), pixel.a);
}
