shader_type canvas_item;
// Cheap UV warp on the panorama only (not a full-screen pass). Strength is
// small so the 60 fps cap stays intact on the Compatibility renderer.
uniform float strength : hint_range(0.0, 0.02) = 0.0036;
uniform float time_scale = 1.15;

void fragment() {
	float y = UV.y;
	float n = sin(y * 92.0 + TIME * time_scale * 5.4) * 0.55
		+ sin(y * 41.0 - TIME * time_scale * 2.7) * 0.45
		+ sin(y * 17.0 + TIME * time_scale * 1.1) * 0.15;
	// Stronger over the mid dunes, weaker on the sky and the near sandbags.
	float band = smoothstep(0.12, 0.42, y) * (1.0 - smoothstep(0.80, 0.96, y));
	vec2 uv = UV + vec2(n * strength * band, 0.0);
	COLOR = texture(TEXTURE, uv);
}
