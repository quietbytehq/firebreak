shader_type canvas_item;
// Subtle UV warp, only across the distant horizon band. Near sand, the
// village and the sky stay still so the stage does not wobble.
uniform float strength : hint_range(0.0, 0.02) = 0.0008;
uniform float time_scale = 0.7;

void fragment() {
	float y = UV.y;
	float n = sin(y * 54.0 + TIME * time_scale * 2.4) * 0.6
		+ sin(y * 23.0 - TIME * time_scale * 1.3) * 0.4;
	// Distant mid-horizon only (about 28–50% of the way down the panorama).
	float band = smoothstep(0.26, 0.34, y) * (1.0 - smoothstep(0.48, 0.56, y));
	vec2 uv = UV + vec2(n * strength * band, 0.0);
	COLOR = texture(TEXTURE, uv);
}
