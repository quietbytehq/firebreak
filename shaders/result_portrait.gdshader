shader_type canvas_item;
// Grades the cut-out bust and softens its cropped edges so it sits in the scene.
uniform vec4 grade : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float contrast : hint_range(0.6, 1.4) = 1.0;
uniform float fade_bottom : hint_range(0.0, 0.5) = 0.20;
uniform float fade_right : hint_range(0.0, 0.4) = 0.08;
uniform float fade_left : hint_range(0.0, 0.4) = 0.02;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float fb = 1.0;
	if (fade_bottom > 0.0 && UV.y > 1.0 - fade_bottom) {
		float t = (UV.y - (1.0 - fade_bottom)) / fade_bottom;
		fb = 1.0 - t * t;
	}
	float fl = fade_left <= 0.001 ? 1.0 : smoothstep(0.0, fade_left, UV.x);
	float fr = fade_right <= 0.001 ? 1.0 : smoothstep(1.0, 1.0 - fade_right, UV.x);
	c.a *= fb * fl * fr;
	c.rgb = mix(vec3(0.18, 0.12, 0.10), c.rgb, contrast);
	c.rgb *= grade.rgb;
	COLOR = c;
}
