extends Node2D
## Draws a running stage: panorama background, painted sprites in depth layers
## (each layer lit for its band by shaders/entity_light.gdshader), then effects:
## muzzle flashes, dust, explosions, air strike jets and bombs, pop-ups and
## screen shake. Particles use one soft texture so they batch cheaply.

const Art := preload("res://scripts/art.gd")
const SpriteArt := preload("res://scripts/sprite_art.gd")
const LightShader := preload("res://shaders/entity_light.gdshader")
const HeatShader := preload("res://shaders/heat_shimmer.gdshader")
const LAYERS := ["far", "mid", "sky", "near", "pickups"]
const MAX_PARTICLES := 420
const VIEW_WIDTH := 1920.0
const VIEW_HEIGHT := 1080.0
## Bottom edge of the top HUD plates (Rect2(16/760/1524, 12, …, 62)).
const HUD_TOP_EDGE := 74.0
## Top edge of the bottom HUD plates.
const HUD_BOTTOM_EDGE := 940.0
const CALLOUT_MARGIN := 28.0
const CALLOUT_OUTLINE := 8.0

## Keeps a baseline-positioned, centred callout fully on screen and out of the
## top HUD band (the plates are see-through, so drawing under them still shows).
static func clamp_callout(text: String, pos: Vector2, size: int, font: Font = null) -> Vector2:
	if font == null:
		font = ThemeDB.fallback_font
	var sz := maxi(8, size)
	var w: float = 0.0
	var ascent := float(sz)
	var descent := float(sz) * 0.25
	if font != null:
		w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		ascent = font.get_ascent(sz)
		descent = font.get_descent(sz)
	var half := w * 0.5 + CALLOUT_OUTLINE
	var x := clampf(pos.x, CALLOUT_MARGIN + half, VIEW_WIDTH - CALLOUT_MARGIN - half)
	var y_min := HUD_TOP_EDGE + CALLOUT_MARGIN + ascent + CALLOUT_OUTLINE
	var y_max := VIEW_HEIGHT - CALLOUT_MARGIN - descent - CALLOUT_OUTLINE
	# Prefer staying above the bottom HUD when there is room.
	var above_bottom := HUD_BOTTOM_EDGE - CALLOUT_MARGIN - descent - CALLOUT_OUTLINE
	if above_bottom > y_min:
		y_max = minf(y_max, above_bottom)
	var y := clampf(pos.y, y_min, maxf(y_min, y_max))
	return Vector2(x, y)


var sim
var dialogue
var bg: Texture2D
var bg_sprite: Sprite2D
var dust_fade := 0.0
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
var near_layer: CanvasLayer
var near_fx: Node2D
var soft: Texture2D
var strike_t := -1.0
var fp = null                  # optional first-person view, for tracer origin
var title_card := 0.0          # seconds left on the stage name card
var title_card_max := 2.6
var streak := 0
var streak_gap := 0.0          # time since last kill
const STREAK_WINDOW := 1.8

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg_sprite = Sprite2D.new(); bg_sprite.name = "HeatBg"; bg_sprite.centered = false
	bg_sprite.z_index = 0; add_child(bg_sprite)
	for name in LAYERS:
		var n := Node2D.new(); n.name = "Layer_" + name
		if name != "pickups":
			var m := ShaderMaterial.new(); m.shader = LightShader; n.material = m
		n.draw.connect(_draw_layer.bind(n, name))
		add_child(n); layer_nodes[name] = n
	fx_node = Node2D.new(); fx_node.name = "Fx"; fx_node.draw.connect(_draw_fx); add_child(fx_node)
	# Near soldiers and pickups sit above the first-person gun (canvas 1) and
	# below the HUD (canvas 3), so close enemies are not hidden by the weapon.
	near_layer = CanvasLayer.new(); near_layer.layer = 2; near_layer.name = "NearLayer"
	add_child(near_layer)
	remove_child(layer_nodes["near"]); near_layer.add_child(layer_nodes["near"])
	remove_child(layer_nodes["pickups"]); near_layer.add_child(layer_nodes["pickups"])
	near_fx = Node2D.new(); near_fx.name = "NearFx"; near_fx.draw.connect(_draw_near_fx)
	near_layer.add_child(near_fx)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.75))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.width = 64; gt.height = 64
	gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(1.0, 0.5)
	soft = gt

func bind(s, background: Texture2D) -> void:
	sim = s; bg = background
	if bg_sprite:
		bg_sprite.texture = background
		var sh := float(sim.stage.get("shimmer", 0.0)) if sim and sim.stage else 0.0
		if sh > 0.0:
			var mat := ShaderMaterial.new(); mat.shader = HeatShader
			mat.set_shader_parameter("strength", sh)
			bg_sprite.material = mat
		else:
			bg_sprite.material = null
	particles.clear(); popups.clear(); tracers.clear(); incoming.clear(); hit_marks.clear(); flashes.clear(); blasts.clear(); rings.clear(); bombs.clear()
	shake = 0.0; hurt = 0.0; blood = 0.0; screen_flash = 0.0; strike_t = -1.0
	streak = 0; streak_gap = 0.0
	title_card = title_card_max
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

func muzzle_origin() -> Vector2:
	if fp != null and fp.has_method("muzzle_screen"):
		var m: Vector2 = fp.muzzle_screen()
		if m.y > 0.0:
			return m
	return Vector2(960, 980)

func banner(text: String, pos: Vector2, col: Color, size: int = 48, life: float = 1.5) -> void:
	popups.append({"pos": pos, "text": text, "life": life, "max": life, "col": col, "size": size, "pop": 1.0})

## Drop stage-name and callout text so they cannot sit on the result screen.
func clear_announcements() -> void:
	popups.clear()
	title_card = 0.0

func _on_event(name: String, d: Dictionary) -> void:
	match name:
		"shot":
			pass  # Bullet tracers were removed in 0.3.5; muzzle fire and smoke live on the FP view.
		"miss":
			dust(d.pos, 5, Color(0.55, 0.45, 0.3))
		"hit":
			var e: Dictionary = d.entity
			if e.type in ["food", "powerup"]:
				sparkle(d.pos, Color(0.6, 1, 0.5) if e.type == "food" else Color(1, 0.85, 0.3))
			elif e.type in ["mg", "truck", "heli", "technical", "convoy", "sniper", "jeep", "speedboat", "pier_gunner", "gunboat", "rusher", "grenadier"] and not d.get("gunner", false):
				sparks(d.pos, 6)
			else:
				dust(d.pos, 4, Color(0.5, 0.45, 0.35))
		"explosion":
			explosion(d.pos, d.radius, d.get("big", false))
		"enemy_fire":
			var e: Dictionary = d.entity
			var from := SpriteArt.muzzle_point(e, Vector2(e.x - sim.camera_x, e.y))
			var dur := 0.14 + 0.1 * (1.0 - clampf(float(e.scale), 0.0, 1.0))
			incoming.append({"from": from, "to": d.get("to", Vector2(960, 880)), "life": dur, "max": dur,
				"hit": d.hit, "mg": e.type in ["mg", "heli", "jeep", "speedboat", "gunboat", "pier_gunner"], "side": float(d.get("side", 0.0)),
				"band": str(e.get("band", ""))})
		"player_hit":
			hurt = minf(1.0, hurt + 0.45)
			blood = minf(1.0, blood + 0.3 + float(d.amount) * 0.02)
			shake = maxf(shake, minf(24.0, 9.0 + float(d.amount) * 0.9))
		"villager_hit":
			var n := int(d.get("count", sim.stats.villagers_hit))
			var lim := int(d.get("limit", sim.CIVILIAN_LIMIT))
			var msg := "CIVILIAN DOWN  %d/%d" % [n, lim]
			if n >= lim:
				msg = "TOO MANY CIVILIANS"
			banner(msg, Vector2(960, 280), Color(1, 0.28, 0.22), 64, 2.2)
			banner("-%d" % sim.VILLAGER_PENALTY_SCORE, d.pos + Vector2(0, -40), Color(1, 0.35, 0.3), 36, 1.4)
		"score":
			banner("+%d" % d.amount, d.pos + Vector2(0, -20), Color(1, 0.95, 0.55), 36, 1.05)
		"headshot":
			banner("CLEAN SHOT", d.pos + Vector2(0, -70), Color(1.0, 0.92, 0.45), 52, 1.3)
		"kill":
			_on_kill(d)
		"gunner_down":
			banner("GUNNER DOWN!", d.pos + Vector2(0, -50), Color(1, 0.85, 0.35), 40, 1.4)
		"heli_down":
			banner("CHOPPER DOWN!", d.pos + Vector2(0, -60), Color(1, 0.7, 0.3), 48, 1.8)
			shake = maxf(shake, 16.0)
		"pickup":
			if not str(d.get("kind", "")).begins_with("cash"):
				banner("PACKAGE", d.pos + Vector2(0, -40), Color(0.7, 1.0, 0.55), 40, 1.2)
		"grenade_throw":
			if not sim.grenades_in_flight.is_empty():
				sim.grenades_in_flight[-1]["from_screen"] = muzzle_origin()
		"airstrike":
			strike_t = 0.0
			bombs.clear()
			for i in 8:
				var x1 := 120.0 + i * 240.0 + randf_range(-50, 50)
				var t0 := 0.5 + i * 0.05
				bombs.append({"x0": x1 - 520.0, "y0": 150.0 + (i % 2) * 90.0, "x1": x1, "y1": randf_range(640.0, 960.0), "t0": t0, "t1": sim.AIRSTRIKE_IMPACT})
			banner("AIR STRIKE INBOUND!", Vector2(960, 420), Color(1, 0.85, 0.3), 56, 1.6)
		"enemy_grenade_land":
			explosion(d.pos, 90.0, false)
			shake = maxf(shake, 10.0)
		"nade_shot":
			sparkle(d.pos, Color(1.0, 0.85, 0.35))
		"airstrike_impact":
			screen_flash = 1.0
			shake = maxf(shake, 34.0)
			for p in d.points:
				blasts.append({"p": p, "k": randf_range(0.75, 1.05), "life": 1.1, "max": 1.1, "rot": randf_range(-0.3, 0.3)})
				if particles.size() < MAX_PARTICLES - 20:
					for i in 6:
						particles.append({"p": p, "v": Vector2(randf_range(-160, 160), randf_range(-260, -60)), "life": randf_range(1.0, 1.8), "max": 1.8, "size": randf_range(30, 60), "col": Color(0.16, 0.14, 0.12, 0.8), "grow": 50.0, "drag": 1.0, "grav": -30.0})

func _on_kill(d: Dictionary) -> void:
	var e: Dictionary = d.entity
	var pos: Vector2 = d.pos
	if e.type == "mg":
		banner("NEST SILENCED", pos + Vector2(0, -90), Color(1.0, 0.82, 0.35), 46, 1.5)
	elif e.type == "sniper":
		banner("SNIPER DOWN", pos + Vector2(0, -90), Color(1.0, 0.82, 0.35), 46, 1.5)
	elif e.type == "truck" or e.type == "convoy":
		banner("TRUCK WRECKED", pos + Vector2(0, -90), Color(1.0, 0.75, 0.3), 46, 1.5)
	elif e.type == "technical":
		banner("TECHNICAL DOWN", pos + Vector2(0, -90), Color(1.0, 0.75, 0.3), 46, 1.5)
	elif e.type == "camel":
		banner("SCOUT DOWN", pos + Vector2(0, -90), Color(1.0, 0.82, 0.35), 40, 1.3)
	elif e.type == "jeep":
		banner("JEEP DOWN", pos + Vector2(0, -90), Color(1.0, 0.75, 0.3), 46, 1.5)
	elif e.type == "speedboat":
		banner("BOAT DOWN", pos + Vector2(0, -90), Color(1.0, 0.75, 0.3), 46, 1.5)
	elif e.type == "pier_gunner":
		banner("PIER SILENCED", pos + Vector2(0, -90), Color(1.0, 0.82, 0.35), 46, 1.5)
	elif e.type == "rusher":
		banner("RUSHER DOWN", pos + Vector2(0, -90), Color(1.0, 0.82, 0.35), 40, 1.3)
	elif e.type == "grenadier":
		banner("GRENADIER DOWN", pos + Vector2(0, -90), Color(1.0, 0.82, 0.35), 40, 1.3)
	elif e.type == "gunboat":
		banner("GUNBOAT DOWN!", pos + Vector2(0, -90), Color(1.0, 0.7, 0.3), 52, 1.8)
		shake = maxf(shake, 16.0)
	streak_gap = 0.0
	streak += 1
	if streak == 3:
		banner("STREAK 3", Vector2(960, 280), Color(1.0, 0.9, 0.4), 64, 1.4)
	elif streak == 5:
		banner("ON A ROLL", Vector2(960, 280), Color(1.0, 0.82, 0.3), 70, 1.5)
	elif streak == 8:
		banner("UNSTOPPABLE", Vector2(960, 260), Color(1.0, 0.7, 0.25), 76, 1.7)

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
	for q in popups:
		q.pos.y -= 70.0 * delta
		q.pos = clamp_callout(str(q.text), q.pos, int(q.get("size", 40)))
	if sim != null and sim.state == "playing" and not sim.paused:
		streak_gap += delta
		if streak_gap > STREAK_WINDOW:
			streak = 0
		if title_card > 0.0:
			title_card = maxf(0.0, title_card - delta)
	_update_incoming(delta)
	if sim != null and sim.state == "playing" and not sim.paused:
		_emit_vehicle_smoke(delta)
		_emit_flight_smoke(delta)
	if strike_t >= 0.0:
		strike_t += delta
		if strike_t > 3.0: strike_t = -1.0
	shake = maxf(0.0, shake - delta * 45.0)
	hurt = maxf(0.0, hurt - delta * 1.6)
	blood = maxf(0.0, blood - delta * 0.28)
	screen_flash = maxf(0.0, screen_flash - delta * 3.0)
	shake_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake if shake > 0.1 else Vector2.ZERO
	position = shake_offset
	if near_fx:
		layer_nodes["near"].position = shake_offset
		layer_nodes["pickups"].position = shake_offset
		near_fx.position = shake_offset
	queue_redraw()
	for n in layer_nodes.values(): n.queue_redraw()
	fx_node.queue_redraw()
	if near_fx: near_fx.queue_redraw()

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
		if not (e.type in ["heli", "technical", "convoy", "jeep", "gunboat"]): continue
		var pos := Vector2(e.x - sim.camera_x, e.y)
		if e.state == "crash":
			if randf() < 0.5: _add({"p": pos + Vector2(randf_range(-40, 40), randf_range(-20, 20)), "v": Vector2(randf_range(-40, 40), randf_range(-120, -40)), "life": 1.2, "max": 1.2, "size": randf_range(28, 44), "col": Color(0.17, 0.15, 0.13, 0.5), "grow": 36.0, "drag": 1.0, "grav": -30.0})
			_add({"p": pos + Vector2(randf_range(-30, 30), randf_range(-10, 10)), "v": Vector2(randf_range(-60, 60), randf_range(-160, -60)), "life": 0.4, "max": 0.4, "size": randf_range(16, 28), "col": Color(1, randf_range(0.4, 0.7), 0.1), "grow": 10.0, "drag": 2.0, "grav": -80.0})
		elif e.get("smoking", false) and randf() < delta * 22.0:
			var tail := pos + Vector2(-140.0 * e.scale * e.facing, -10.0)
			_add({"p": tail, "v": Vector2(randf_range(-30, 30) - e.vx * 0.3, randf_range(-70, -20)), "life": 1.4, "max": 1.4, "size": randf_range(18, 30), "col": Color(0.17, 0.15, 0.14, 0.7), "grow": 34.0, "drag": 0.8, "grav": -25.0})

func _emit_flight_smoke(delta: float) -> void:
	for g in sim.grenades_in_flight:
		var f: float = g.t / maxf(0.05, float(g.dur))
		var start: Vector2 = g.get("from_screen", muzzle_origin())
		var target: Vector2 = g.to - Vector2(sim.camera_x, 0)
		var arc := 220.0 if str(g.get("kind", "thrown")) == "rocket" else 300.0
		var p := start.lerp(target, f) + Vector2(0, -sin(f * PI) * arc)
		var n := 2 if str(g.get("kind", "")) == "rocket" else 1
		if randf() < delta * (10.0 if n > 1 else 6.0):
			for i in n:
				_add({"p": p + Vector2(randf_range(-5, 5), randf_range(-5, 5)), "v": Vector2(randf_range(-16, 16), randf_range(-24, 8)), "life": randf_range(0.35, 0.65), "max": 0.65, "size": randf_range(8, 16), "col": Color(0.48, 0.46, 0.42, 0.26), "grow": 28.0, "drag": 1.6, "grav": -16.0})

func _draw_title_card(ci: Node2D, font: Font) -> void:
	if title_card <= 0.0 or sim == null:
		return
	var mx := title_card_max
	var u: float = 1.0 - title_card / mx
	var a := 1.0
	if u < 0.18:
		a = u / 0.18
	elif title_card < 0.55:
		a = title_card / 0.55
	var name := str(sim.stage.get("name", ""))
	var sub := str(sim.stage.get("subtitle", ""))
	if name == "":
		return
	var ns := 86
	var nw := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, ns).x
	var pos := Vector2(960 - nw * 0.5, 200)
	ci.draw_string_outline(font, pos, name, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, 12, Color(0, 0, 0, 0.85 * a))
	ci.draw_string(font, pos, name, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, Color(1, 0.93, 0.72, a))
	if sub != "":
		var ss := 32
		var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
		var sp := Vector2(960 - sw * 0.5, 268)
		ci.draw_string_outline(font, sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, 8, Color(0, 0, 0, 0.8 * a))
		ci.draw_string(font, sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, Color(0.95, 0.85, 0.65, a))

func _layer_of(e: Dictionary) -> String:
	if e.type in ["food", "powerup"]: return "pickups"
	if e.type == "heli": return "sky"
	return str(e.band) if e.band in ["far", "mid", "near"] else "mid"

func _draw() -> void:
	if sim == null: return
	if bg:
		var scale := 1080.0 / float(bg.get_height())
		draw_rect(Rect2(-60, -60, 2040, 1200), Color(0.12, 0.14, 0.16) if float(sim.stage.get("shimmer", 0.0)) > 0.0 else Color(0.08, 0.06, 0.05))
		if bg_sprite and bg_sprite.texture:
			bg_sprite.position = Vector2(-sim.camera_x, 0)
			bg_sprite.scale = Vector2(scale, scale)
		else:
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
			"sniper": SpriteArt.sniper(ci, e, pos, t)
			"camel": SpriteArt.camel(ci, e, pos, t)
			"villager": SpriteArt.villager(ci, e, pos, t)
			"heli": SpriteArt.heli(ci, e, pos, t)
			"food", "powerup": SpriteArt.pickup(ci, e, pos, t)
			"technical": SpriteArt.technical(ci, e, pos, t)
			"convoy": SpriteArt.convoy(ci, e, pos, t)
			"jeep": SpriteArt.jeep(ci, e, pos, t)
			"speedboat": SpriteArt.speedboat(ci, e, pos, t)
			"gunboat": SpriteArt.gunboat(ci, e, pos, t)
			"pier_gunner": SpriteArt.pier_gunner(ci, e, pos, t)
			"rusher": SpriteArt.rusher(ci, e, pos, t)
			"grenadier": SpriteArt.grenadier(ci, e, pos, t)
			"truck":
				Art.tint = Color(1, 1, 1); Art.haze = 0.0
				Art.begin(ci, pos, e.scale, e.facing, 0.0, e.flash, e.alpha)
				Art.truck(ci, e, t)
				Art.end(ci)

func _draw_fx() -> void:
	if sim == null: return
	var ci := fx_node
	_draw_enemy_nades(ci)
	var dust := 0.0
	if sim.has_method("dust_amount"):
		dust = float(sim.dust_amount())
	if dust > 0.0:
		var a := 0.16 * dust
		ci.draw_rect(Rect2(-40, -40, 2000, 1160), Color(0.86, 0.74, 0.52, a))
		# A few wind streaks, cheap (no extra entities).
		for i in 8:
			var y := 120.0 + fmod(t * 90.0 + i * 97.0, 820.0)
			var x := fmod(t * (220.0 + i * 30.0) + i * 240.0, 2100.0) - 80.0
			ci.draw_rect(Rect2(x, y, 180.0 + i * 10.0, 3.0), Color(0.95, 0.88, 0.7, 0.12 * dust))
	for g in sim.grenades_in_flight:
		var f: float = g.t / g.dur
		var start: Vector2 = g.get("from_screen", muzzle_origin())
		var target: Vector2 = g.to - Vector2(sim.camera_x, 0)
		var arc := 220.0 if str(g.get("kind", "thrown")) == "rocket" else 300.0
		var p := start.lerp(target, f) + Vector2(0, -sin(f * PI) * arc)
		var kind: String = str(g.get("kind", "thrown"))
		if kind == "rocket":
			# Slim rocket body pointing along the path.
			var prev := start.lerp(target, maxf(0.0, f - 0.06)) + Vector2(0, -sin(maxf(0.0, f - 0.06) * PI) * arc)
			var ang := (p - prev).angle()
			ci.draw_set_transform(p, ang, Vector2.ONE)
			ci.draw_rect(Rect2(-18, -5, 36, 10), Color(0.28, 0.32, 0.2))
			ci.draw_rect(Rect2(10, -4, 12, 8), Color(0.45, 0.4, 0.28))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			ci.draw_circle(p, lerpf(22.0, 11.0, f), Color(0.2, 0.24, 0.14))
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
		var mx: float = float(q.get("max", 0.16))
		var a: float = clampf(q.life / maxf(0.04, mx), 0.0, 1.0)
		var origin: Vector2 = q.get("from", Vector2(960, 980))
		# Fade the streak along its length: a bright core and a softer glow.
		ci.draw_line(origin, q.to, Color(1, 0.75, 0.3, 0.28 * a), 6.0)
		ci.draw_line(origin, q.to, Color(1, 0.95, 0.7, 0.75 * a), 2.0)
		ci.draw_circle(q.to, 12.0 * a + 4.0, Color(1, 0.95, 0.7, 0.8 * a))
	# Incoming fire is drawn on near_fx, above the first-person gun.
	var font := ThemeDB.fallback_font
	for q in popups:
		var mx: float = float(q.get("max", 1.0))
		var age: float = 1.0 - clampf(q.life / maxf(0.05, mx), 0.0, 1.0)
		var a: float = clampf(q.life / 0.35, 0.0, 1.0)
		# Pop: start small, overshoot, settle.
		var pop: float = 1.0
		if age < 0.18:
			pop = lerpf(0.45, 1.22, age / 0.18)
		elif age < 0.32:
			pop = lerpf(1.22, 1.0, (age - 0.18) / 0.14)
		var sz: int = maxi(12, int(round(float(q.size) * pop)))
		var at := clamp_callout(str(q.text), q.pos, sz, font)
		var w := font.get_string_size(q.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		ci.draw_string_outline(font, at - Vector2(w * 0.5, 0), q.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 8, Color(0, 0, 0, 0.8 * a))
		ci.draw_string(font, at - Vector2(w * 0.5, 0), q.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(q.col, a))
	_draw_title_card(ci, font)
	_draw_radio(ci, font)
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
func _draw_near_fx() -> void:
	if sim == null or near_fx == null:
		return
	_draw_incoming(near_fx)

func _draw_incoming(ci: Node2D, _near_only: bool = false) -> void:
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

func _draw_enemy_nades(ci: Node2D) -> void:
	if not sim.has_method("nade_screen_pos"):
		return
	for g in sim.enemy_nades:
		if str(g.get("state", "")) != "fly":
			continue
		var pos: Vector2 = sim.nade_screen_pos(g)
		var dest: Vector2 = g.to_screen
		var u := clampf(float(g.t) / maxf(0.05, float(g.dur)), 0.0, 1.0)
		SpriteArt.enemy_grenade(ci, pos, dest, u, 1.0)

func _draw_radio(ci: Node2D, font: Font) -> void:
	if dialogue == null or dialogue.text() == "":
		return
	# Stay under the top HUD and well clear of the y=280 banners.
	var plate := Rect2(36, 118, 720, 88)
	ci.draw_rect(plate, Color(0.06, 0.05, 0.04, 0.72))
	ci.draw_rect(plate.grow(-1.0), Color(1.0, 0.78, 0.42, 0.45), false, 1.5)
	var a := clampf(float(dialogue.current.get("life", 1.0)) / 0.4, 0.0, 1.0)
	var sp: String = dialogue.speaker()
	var body: String = dialogue.text()
	ci.draw_string_outline(font, plate.position + Vector2(16, 30), sp, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 5, Color(0, 0, 0, 0.8 * a))
	ci.draw_string(font, plate.position + Vector2(16, 30), sp, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.82, 0.45, a))
	ci.draw_string_outline(font, plate.position + Vector2(16, 62), body, HORIZONTAL_ALIGNMENT_LEFT, plate.size.x - 28, 24, 5, Color(0, 0, 0, 0.8 * a))
	ci.draw_string(font, plate.position + Vector2(16, 62), body, HORIZONTAL_ALIGNMENT_LEFT, plate.size.x - 28, 24, Color(1, 0.93, 0.82, a))
