shader_type canvas_item;
// Dusk light for one depth band: rgb *= tint; rgb = mix(rgb, haze_color, haze).
// Sprites brighter than 1.0 (hit flash via modulate) keep their extra light.
uniform vec3 tint = vec3(1.0);
uniform vec3 haze_color = vec3(0.8, 0.56, 0.4);
uniform float haze : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 c = COLOR.rgb * tint;
	COLOR.rgb = mix(c, haze_color, haze);
}
