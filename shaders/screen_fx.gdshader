shader_type canvas_item;
// Full-screen overlay: soft dusk vignette, a red edge flash when hurt and a
// subtle, non-gory blood-spatter rim that fades (stronger at low health).
uniform float hurt : hint_range(0.0, 1.0) = 0.0;
uniform float blood : hint_range(0.0, 1.0) = 0.0;
uniform float low_health : hint_range(0.0, 1.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.38;
uniform float seed = 0.0;
uniform float pulse = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.13) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.07; a *= 0.5; }
	return v;
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.0, 0.8));
	float edge = smoothstep(0.32, 0.78, d);
	vec3 col = mix(vec3(0.05, 0.02, 0.0), vec3(0.8, 0.03, 0.0), clamp(hurt, 0.0, 1.0));
	float a = edge * (vignette + hurt * 0.7);
	// Spatter: distance to the nearest screen edge, broken up by noise.
	vec2 e2 = min(UV, vec2(1.0) - UV);
	float rim = min(e2.x * 1.78, e2.y);
	float amount = clamp(blood * 0.8 + low_health * (0.55 + 0.25 * pulse), 0.0, 1.0);
	float n = fbm(UV * vec2(9.0, 5.0)) * 0.75 + fbm(UV * vec2(31.0, 18.0)) * 0.25;
	float reach = 0.035 + 0.16 * amount;
	float spatter = smoothstep(reach, reach * 0.55, rim + (n - 0.5) * 0.12) * step(0.001, amount);
	float drops = smoothstep(0.78, 0.86, fbm(UV * vec2(26.0, 15.0) + 3.1)) * smoothstep(reach * 2.2, reach, rim) * amount;
	float s = clamp(max(spatter, drops) * (0.35 + 0.4 * amount), 0.0, 0.72);
	vec3 blood_col = vec3(0.36, 0.015, 0.01) * (0.8 + 0.4 * n);
	vec3 outc = mix(col, blood_col, s / max(0.001, a + s));
	COLOR = vec4(outc, clamp(a + s, 0.0, 0.92));
}
