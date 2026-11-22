shader_type canvas_item;
// Metallic, fiery fill for the live "FIREBREAK" title text: a vertical
// gradient (hot white-gold top, orange middle, deep red base) per text line,
// plus a slow diagonal glint sweeping across.
uniform float line_height = 186.0;
uniform float top0 = 88.0;   // top of the first line's capitals
uniform float cap = 140.0;    // capital height
varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float a = COLOR.a;
	float y = clamp(fract((local_pos.y - top0) / line_height) * line_height / cap, 0.0, 1.0);
	vec3 top = vec3(1.0, 0.97, 0.82);
	vec3 mid = vec3(1.0, 0.62, 0.12);
	vec3 low = vec3(0.62, 0.08, 0.02);
	vec3 c = y < 0.5 ? mix(top, mid, smoothstep(0.08, 0.5, y)) : mix(mid, low, smoothstep(0.5, 0.95, y));
	// Horizon line of a chrome-style letter: a thin bright band just above centre.
	c += vec3(0.35, 0.25, 0.1) * smoothstep(0.03, 0.0, abs(y - 0.47));
	float sweep = fract(TIME * 0.12);
	float d = (local_pos.x + local_pos.y * 0.5) / 1400.0 - (sweep * 1.8 - 0.4);
	c += vec3(1.0, 0.9, 0.7) * smoothstep(0.05, 0.0, abs(d)) * 0.8;
	COLOR = vec4(c, a);
}
