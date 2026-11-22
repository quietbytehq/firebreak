extends Node2D
## Draws a running stage: panorama background, painted sprites in depth layers
## (each layer lit for its band by shaders/entity_light.gdshader), then effects:
## muzzle flashes, dust, explosions, air strike jets and bombs, pop-ups and
## screen shake. Particles use one soft texture so they batch cheaply.

const Art := preload("res://scripts/art.gd")
const SpriteArt := preload("res://scripts/sprite_art.gd")
const LightShader := preload("res://shaders/entity_light.gdshader")
const LAYERS := ["far", "mid", "sky", "near", "pickups"]
const MAX_PARTICLES := 420

var sim
var bg: Texture2D
var t := 0.0
var particles: Array = []
var popups: Array = []
var tracers: Array = []
## Enemy shots travelling out of the screen toward the player (0.2.1).
var incoming: Array = []
## Red edge markers showing which side a hit came from.
var hit_marks: Array = []
var flashes: Array = []
var blasts: Array = []
var rings: Array = []
var bombs: Array = []
var shake := 0.0
var shake_offset := Vector2.ZERO
var hurt := 0.0
var blood := 0.0
var screen_flash := 0.0
var layer_nodes := {}
var fx_node: Node2D
var soft: Texture2D
var strike_t := -1.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for name in LAYERS:
		var n := Node2D.new(); n.name = "Layer_" + name
		if name != "pickups":
			var m := ShaderMaterial.new(); m.shader = LightShader; n.material = m
		n.draw.connect(_draw_layer.bind(n, name))
		add_child(n); layer_nodes[name] = n
	fx_node = Node2D.new(); fx_node.name = "Fx"; fx_node.draw.connect(_draw_fx); add_child(fx_node)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.75))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.width = 64; gt.height = 64
	gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(1.0, 0.5)
	soft = gt

func bind(s, background: Texture2D) -> void:
	sim = s; bg = background
	particles.clear(); popups.clear(); tracers.clear(); incoming.clear(); hit_marks.clear(); flashes.clear(); blasts.clear(); rings.clear(); bombs.clear()
	shake = 0.0; hurt = 0.0; blood = 0.0; screen_flash = 0.0; strike_t = -1.0
	sim.event.connect(_on_event)
	_apply_light()

func _apply_light() -> void:
	var light: Dictionary = sim.stage.get("light", {})
	var tint: Array = light.get("tint", [1, 1, 1])
	var hz: Array = light.get("haze", [0.8, 0.56, 0.4])
	for name in ["far", "mid", "sky", "near"]:
		var m: ShaderMaterial = layer_nodes[name].material
		m.set_shader_parameter("tint", Vector3(tint[0], tint[1], tint[2]))
		m.set_shader_parameter("haze_color", Vector3(hz[0], hz[1], hz[2]))
		var amt := float(light.get("haze_" + name, 0.0)) if name != "sky" else float(light.get("haze_mid", 0.0)) * 0.6
		m.set_shader_parameter("haze", amt)

func _on_event(name: String, d: Dictionary) -> void:
	match name:
		"shot":
			for p in d.points:
				tracers.append({"to": p, "life": 0.06})
		"miss":
			dust(d.pos, 5, Color(0.55, 0.45, 0.3))
		"hit":
			var e: Dictionary = d.entity
			if e.type in ["food", "powerup"]:
				sparkle(d.pos, Color(0.6, 1, 0.5) if e.type == "food" else Color(1, 0.85, 0.3))
			elif e.type in ["mg", "truck", "heli"] and not d.get("gunner", false):
				sparks(d.pos, 6)
			else:
				dust(d.pos, 4, Color(0.5, 0.45, 0.35))
		"explosion":
			explosion(d.pos, d.radius, d.get("big", false))
		"enemy_fire":
			var e: Dictionary = d.entity
			var from := SpriteArt.muzzle_point(e, Vector2(e.x - sim.camera_x, e.y))
			var dur := 0.14 + 0.1 * (1.0 - clampf(float(e.scale), 0.0, 1.0))
			incoming.append({"from": from, "to": d.get("to", Vector2(960, 1040)), "life": dur, "max": dur,
				"hit": d.hit, "mg": e.type in ["mg", "heli"], "side": float(d.get("side", 0.0))})
		"player_hit":
			hurt = minf(1.0, hurt + 0.45)
			blood = minf(1.0, blood + 0.3 + float(d.amount) * 0.02)
			shake = maxf(shake, minf(24.0, 9.0 + float(d.amount) * 0.9))
		"villager_hit":
			popups.append({"pos": d.pos + Vector2(0, -40), "text": "CIVILIAN!  -%d" % sim.VILLAGER_PENALTY_SCORE, "life": 1.6, "col": Color(1, 0.35, 0.3), "size": 40})
		"score":
			popups.append({"pos": d.pos, "text": "+%d" % d.amount, "life": 1.0, "col": Color(1, 0.95, 0.6), "size": 30})
		"gunner_down":
			popups.append({"pos": d.pos + Vector2(0, -50), "text": "GUNNER DOWN!", "life": 1.4, "col": Color(1, 0.85, 0.35), "size": 36})
		"heli_down":
			popups.append({"pos": d.pos + Vector2(0, -60), "text": "CHOPPER DOWN!", "life": 1.8, "col": Color(1, 0.7, 0.3), "size": 44})
			shake = maxf(shake, 16.0)
		"airstrike":
			strike_t = 0.0
			bombs.clear()
			for i in 8:
				var x1 := 120.0 + i * 240.0 + randf_range(-50, 50)
				var t0 := 0.5 + i * 0.05
				bombs.append({"x0": x1 - 520.0, "y0": 150.0 + (i % 2) * 90.0, "x1": x1, "y1": randf_range(640.0, 960.0), "t0": t0, "t1": sim.AIRSTRIKE_IMPACT})
			popups.append({"pos": Vector2(960, 420), "text": "AIR STRIKE INBOUND!", "life": 1.6, "col": Color(1, 0.85, 0.3), "size": 56})
		"airstrike_impact":
			screen_flash = 1.0
			shake = maxf(shake, 34.0)
			for p in d.points:
				blasts.append({"p": p, "k": randf_range(0.75, 1.05), "life": 1.1, "max": 1.1, "rot": randf_range(-0.3, 0.3)})
				if particles.size() < MAX_PARTICLES - 20:
					for i in 6:
						particles.append({"p": p, "v": Vector2(randf_range(-160, 160), randf_range(-260, -60)), "life": randf_range(1.0, 1.8), "max": 1.8, "size": randf_range(30, 60), "col": Color(0.16, 0.14, 0.12, 0.8), "grow": 50.0, "drag": 1.0, "grav": -30.0})

func _add(p: Dictionary) -> void:
	if particles.size() < MAX_PARTICLES:
		particles.append(p)

func dust(pos: Vector2, n: int, col: Color) -> void:
	for i in n:
		_add({"p": pos, "v": Vector2(randf_range(-90, 90), randf_range(-160, -40)), "life": randf_range(0.35, 0.6), "max": 0.6, "size": randf_range(8, 16), "col": col, "grow": 22.0, "drag": 2.5, "grav": 120.0})

func sparks(pos: Vector2, n: int) -> void:
	for i in n:
		_add({"p": pos, "v": Vector2.from_angle(randf() * TAU) * randf_range(150, 380), "life": 0.25, "max": 0.25, "size": 6.0, "col": Color(1, 0.85, 0.4), "grow": -10.0, "drag": 1.0, "grav": 400.0})

func sparkle(pos: Vector2, col: Color) -> void:
	for i in 12:
		_add({"p": pos, "v": Vector2.from_angle(TAU * i / 12.0) * 220.0, "life": 0.5, "max": 0.5, "size": 10.0, "col": col, "grow": -12.0, "drag": 3.0, "grav": 0.0})

func explosion(pos: Vector2, radius: float, big: bool = false) -> void:
	shake = maxf(shake, 26.0 if big or radius > 300.0 else 18.0)
	flashes.append({"p": pos, "r": radius * 0.9, "life": 0.16, "max": 0.16})
	blasts.append({"p": pos, "k": clampf(radius * 1.7 / 420.0, 0.35, 2.2), "life": 0.9, "max": 0.9, "rot": randf_range(-0.3, 0.3)})
	if radius > 300.0:
		rings.append({"p": pos, "r": radius, "life": 0.45, "max": 0.45})
	for i in 14:
		_add({"p": pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)), "v": Vector2.from_angle(randf() * TAU) * randf_range(80, radius * 1.6), "life": randf_range(0.3, 0.6), "max": 0.6, "size": randf_range(22, 40), "col": Color(1, randf_range(0.45, 0.8), 0.15), "grow": 30.0, "drag": 3.5, "grav": -60.0})
	for i in 10:
		_add({"p": pos + Vector2(randf_range(-40, 40), randf_range(-30, 10)), "v": Vector2(randf_range(-80, 80), randf_range(-150, -40)), "life": randf_range(1.0, 1.6), "max": 1.6, "size": randf_range(30, 52), "col": Color(0.2, 0.17, 0.15, 0.45), "grow": 40.0, "drag": 1.2, "grav": -20.0})
	for i in 8:
		_add({"p": pos, "v": Vector2(randf_range(-420, 420), randf_range(-620, -200)), "life": 1.0, "max": 1.0, "size": randf_range(6, 10), "col": Color(0.15, 0.12, 0.08), "grow": 0.0, "drag": 0.4, "grav": 900.0})

func _process(delta: float) -> void:
	t += delta
	var i := 0
	while i < particles.size():
		var p: Dictionary = particles[i]
		p.life -= delta
		if p.life <= 0.0:
			particles[i] = particles[particles.size() - 1]; particles.pop_back(); continue
		p.v *= maxf(0.0, 1.0 - p.drag * delta)
		p.v.y += p.grav * delta
		p.p += p.v * delta
		p.size = maxf(0.5, p.size + p.grow * delta)
		i += 1
	for list in [popups, tracers, flashes, blasts, rings]:
		var j := 0
		while j < list.size():
			list[j].life -= delta
			if list[j].life <= 0.0: list.remove_at(j)
			else: j += 1
	for q in popups: q.pos.y -= 60.0 * delta
	_update_incoming(delta)
	if sim != null and sim.state == "playing" and not sim.paused:
		_emit_vehicle_smoke(delta)
	if strike_t >= 0.0:
		strike_t += delta
		if strike_t > 3.0: strike_t = -1.0
	shake = maxf(0.0, shake - delta * 45.0)
	hurt = maxf(0.0, hurt - delta * 1.6)
	blood = maxf(0.0, blood - delta * 0.28)
	screen_flash = maxf(0.0, screen_flash - delta * 3.0)
	shake_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake if shake > 0.1 else Vector2.ZERO
	position = shake_offset
	queue_redraw()
	for n in layer_nodes.values(): n.queue_redraw()
	fx_node.queue_redraw()

func _update_incoming(delta: float) -> void:
	var j := 0
	while j < incoming.size():
		var q: Dictionary = incoming[j]
		q.life -= delta
		if q.life <= 0.0:
			# The round arrives: a flash at the screen edge on a hit, dirt on a miss.
			if q.hit:
				flashes.append({"p": q.to, "r": 70.0, "life": 0.12, "max": 0.12})
				sparks(q.to, 5)
				hit_marks.append({"side": q.side, "life": 0.8, "max": 0.8})
			else:
				dust(q.to, 4, Color(0.5, 0.42, 0.3))
			incoming.remove_at(j)
		else:
			j += 1
	var k := 0
	while k < hit_marks.size():
		hit_marks[k].life -= delta
		if hit_marks[k].life <= 0.0: hit_marks.remove_at(k)
		else: k += 1

func _emit_vehicle_smoke(delta: float) -> void:
	for e in sim.entities:
		if e.type != "heli": continue
		var pos := Vector2(e.x - sim.camera_x, e.y)
		if e.state == "crash":
			if randf() < 0.5: _add({"p": pos + Vector2(randf_range(-40, 40), randf_range(-20, 20)), "v": Vector2(randf_range(-40, 40), randf_range(-120, -40)), "life": 1.2, "max": 1.2, "size": randf_range(28, 44), "col": Color(0.17, 0.15, 0.13, 0.5), "grow": 36.0, "drag": 1.0, "grav": -30.0})
			_add({"p": pos + Vector2(randf_range(-30, 30), randf_range(-10, 10)), "v": Vector2(randf_range(-60, 60), randf_range(-160, -60)), "life": 0.4, "max": 0.4, "size": randf_range(16, 28), "col": Color(1, randf_range(0.4, 0.7), 0.1), "grow": 10.0, "drag": 2.0, "grav": -80.0})
		elif e.get("smoking", false) and randf() < delta * 22.0:
			var tail := pos + Vector2(-140.0 * e.scale * e.facing, -10.0)
			_add({"p": tail, "v": Vector2(randf_range(-30, 30) - e.vx * 0.3, randf_range(-70, -20)), "life": 1.4, "max": 1.4, "size": randf_range(18, 30), "col": Color(0.17, 0.15, 0.14, 0.7), "grow": 34.0, "drag": 0.8, "grav": -25.0})

func _layer_of(e: Dictionary) -> String:
	if e.type in ["food", "powerup"]: return "pickups"
	if e.type == "heli": return "sky"
	return str(e.band) if e.band in ["far", "mid", "near"] else "mid"

func _draw() -> void:
	if sim == null: return
	if bg:
		var scale := 1080.0 / float(bg.get_height())
		draw_rect(Rect2(-60, -60, 2040, 1200), Color(0.08, 0.06, 0.05))
		draw_texture_rect(bg, Rect2(Vector2(-sim.camera_x, 0), Vector2(bg.get_width() * scale, 1080)), false)

func _draw_layer(ci: Node2D, layer: String) -> void:
	if sim == null: return
	var cam: float = sim.camera_x
	var order: Array = []
	for e in sim.entities:
		if _layer_of(e) == layer: order.append(e)
	order.sort_custom(func(a, b): return float(a.scale) + float(a.y) * 0.0001 < float(b.scale) + float(b.y) * 0.0001)
	for e in order:
		var pos := Vector2(e.x - cam, e.y)
		match e.type:
			"rifleman": SpriteArt.soldier(ci, e, pos, t)
			"paratrooper": SpriteArt.paratrooper(ci, e, pos, t)
			"mg": SpriteArt.mg_nest(ci, e, pos, t)
			"villager": SpriteArt.villager(ci, e, pos, t)
			"heli": SpriteArt.heli(ci, e, pos, t)
			"food", "powerup": SpriteArt.pickup(ci, e, pos, t)
			"truck":
				# Still procedural (no painted truck sprite); light comes from the layer shader.
				Art.tint = Color(1, 1, 1); Art.haze = 0.0
				Art.begin(ci, pos, e.scale, e.facing, 0.0, e.flash, e.alpha)
				Art.truck(ci, e, t)
				Art.end(ci)

func _draw_fx() -> void:
	if sim == null: return
	var ci := fx_node
	for g in sim.grenades_in_flight:
		var f: float = g.t / g.dur
		var start := Vector2(1500, 1100)
		var target: Vector2 = g.to - Vector2(sim.camera_x, 0)
		var p := start.lerp(target, f) + Vector2(0, -sin(f * PI) * 300.0)
		ci.draw_circle(p, lerpf(24.0, 11.0, f), Color(0.2, 0.24, 0.14))
		ci.draw_circle(p + Vector2(-4, -4), lerpf(8.0, 4.0, f), Color(0.42, 0.47, 0.3))
		# Faint aim marker where it will land.
		ci.draw_arc(target, 26.0 + 6.0 * sin(t * 18.0), 0, TAU, 24, Color(1, 0.6, 0.2, 0.6), 3.0)
	_draw_strike(ci)
	for q in flashes:
		var a: float = q.life / q.max
		ci.draw_texture_rect(soft, Rect2(q.p - Vector2(q.r, q.r) * 1.3, Vector2(q.r, q.r) * 2.6), false, Color(1, 0.9, 0.6, 0.7 * a))
	for q in rings:
		var a: float = q.life / q.max
		var rr: float = q.r * (1.0 - a * 0.6)
		ci.draw_arc(q.p, rr, 0, TAU, 64, Color(1, 0.85, 0.55, 0.5 * a), 10.0 * a + 2.0)
	for p in particles:
		var a: float = clampf(p.life / p.max, 0.0, 1.0)
		var col: Color = p.col
		var s: float = p.size * 1.5
		ci.draw_texture_rect(soft, Rect2(p.p - Vector2(s, s), Vector2(s, s) * 2.0), false, Color(col.r, col.g, col.b, col.a * a))
	for b in blasts:
		var a: float = clampf(b.life / b.max, 0.0, 1.0)
		var grow: float = clampf((1.0 - a) / 0.25, 0.0, 1.0)
		var k: float = b.k * (0.45 + 0.55 * grow)
		SpriteArt.draw(ci, "explosion_big", b.p, k, 1.0, Color(1, 1, 1, clampf(a * 1.6, 0.0, 1.0)), b.rot)
	for q in tracers:
		var a: float = q.life / 0.06
		ci.draw_line(Vector2(1620, 1090), q.to, Color(1, 0.9, 0.55, 0.5 * a), 3.0)
		ci.draw_circle(q.to, 12.0 * a + 4.0, Color(1, 0.95, 0.7, 0.8 * a))
	_draw_incoming(ci)
	var font := ThemeDB.fallback_font
	for q in popups:
		var a: float = clampf(q.life / 0.4, 0.0, 1.0)
		var w := font.get_string_size(q.text, HORIZONTAL_ALIGNMENT_LEFT, -1, q.size).x
		ci.draw_string_outline(font, q.pos - Vector2(w * 0.5, 0), q.text, HORIZONTAL_ALIGNMENT_LEFT, -1, q.size, 8, Color(0, 0, 0, 0.8 * a))
		ci.draw_string(font, q.pos - Vector2(w * 0.5, 0), q.text, HORIZONTAL_ALIGNMENT_LEFT, -1, q.size, Color(q.col, a))
	if screen_flash > 0.0:
		ci.draw_rect(Rect2(-80, -80, 2080, 1240), Color(1, 0.85, 0.6, 0.45 * screen_flash))

func _draw_strike(ci: Node2D) -> void:
	if strike_t < 0.0: return
	var st := strike_t
	# Two jets streak across low over the treeline.
	for j in 2:
		var tt := st - 0.1 - j * 0.22
		if tt < 0.0 or tt > 1.6: continue
		var x := -600.0 + tt * 2700.0
		var y := 150.0 + j * 95.0 - tt * 20.0
		SpriteArt.draw(ci, "jet_a" if j == 0 else "jet_b", Vector2(x, y), 1.15 - j * 0.12, 1.0, Color(0.95, 0.88, 0.8))
	for b in bombs:
		if st < b.t0 or st > b.t1: continue
		var f: float = (st - b.t0) / maxf(0.01, b.t1 - b.t0)
		var p := Vector2(lerpf(b.x0, b.x1, f), lerpf(b.y0, b.y1, f * f))
		var dir := Vector2(b.x1 - b.x0, (b.y1 - b.y0) * 2.0 * f + 1.0).normalized()
		SpriteArt.draw(ci, "bomb", p, 0.42, 1.0, Color(1, 1, 1), dir.angle())

## Enemy rounds come OUT of the screen at the player: a bright streak that
## widens as it nears the camera, from the barrel to the lower screen edge.
func _draw_incoming(ci: Node2D) -> void:
	for q in incoming:
		var f: float = 1.0 - q.life / q.max
		var head: Vector2 = q.from.lerp(q.to, f)
		var tail: Vector2 = q.from.lerp(q.to, maxf(0.0, f - 0.2))
		var w := lerpf(2.0, 13.0 if q.mg else 10.0, f)
		ci.draw_line(tail, head, Color(1.0, 0.7, 0.3, 0.35), w * 2.2)
		ci.draw_line(tail, head, Color(1.0, 0.93, 0.7, 0.9), w)
		ci.draw_texture_rect(soft, Rect2(head - Vector2(w, w) * 2.0, Vector2(w, w) * 4.0), false, Color(1, 0.9, 0.6, 0.8))
	for m in hit_marks:
		var a: float = m.life / m.max
		var side: float = m.side
		# Chevron at the lower edge, slid toward the side the shot came from.
		var cx := 960.0 + side * 760.0
		var base := Vector2(cx, 1062.0)
		var pts := PackedVector2Array([base + Vector2(-70, 0), base + Vector2(0, -46), base + Vector2(70, 0), base + Vector2(0, -18)])
		ci.draw_colored_polygon(pts, Color(1, 0.12, 0.08, 0.75 * a))
		var col := Color(0.9, 0.05, 0.03, 0.42 * a)
		var clear := Color(0.9, 0.05, 0.03, 0.0)
		if side < -0.35:
			ci.draw_polygon(PackedVector2Array([Vector2(0, 260), Vector2(70, 300), Vector2(70, 1080), Vector2(0, 1080)]), PackedColorArray([col, clear, clear, col]))
		elif side > 0.35:
			ci.draw_polygon(PackedVector2Array([Vector2(1920, 260), Vector2(1850, 300), Vector2(1850, 1080), Vector2(1920, 1080)]), PackedColorArray([col, clear, clear, col]))
		ci.draw_polygon(PackedVector2Array([Vector2(cx - 420, 1080), Vector2(cx - 300, 1010), Vector2(cx + 300, 1010), Vector2(cx + 420, 1080)]), PackedColorArray([col, clear, clear, col]))
