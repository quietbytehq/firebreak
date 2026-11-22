extends Node2D
## First-person weapon view (0.3.4): the selected weapon held in Rayan's arms,
## drawn from behind at the bottom centre of the screen, under the HUD layer so
## the weapon bar and the reticle always stay on top. It sways, turns toward the
## aim point, kicks on every shot, shows a muzzle flash with sparks (guns) or a
## launch puff and back-blast (launchers), lowers and raises on a weapon switch,
## dips during a reload (and, for magazine guns, switches to a side reload pose),
## and briefly shows the special or the radio when a grenade, rocket or air strike
## is used from another slot. Belt-fed and launcher weapons dip without a pose change.

const Weapons := preload("res://scripts/weapons.gd")
const DATA_PATH := "res://data/fp_weapons.json"
const DIR := "res://assets/sprites/fp/"
const SIZE := 600.0             # on-screen size of the square picture
const BASE := Vector2(960.0, 1092.0)   # bottom centre of the picture at rest (fade sits under the HUD)
const LOWER_TIME := 0.15        # switch: seconds to lower the old weapon
const RAISE_TIME := 0.2         # switch: seconds to raise the new one
const KICK_DECAY := 13.0
const FLASH_TIME := 0.07
const OVERRIDE_TIME := {"special": 0.75, "air_strike": 1.5}

var sim
var crosshair := Vector2(960, 540)
var active := true              # false hides the view (menus, result screen)
var data := {}
var textures := {}
var masks := {}                 # id -> 64x64 alpha mask (Image) for the reticle fade
var shown_id := ""              # weapon currently drawn
var target_id := ""             # weapon that should be drawn
var phase := "idle"             # idle | lower | raise
var phase_t := 0.0
var lower := 1.0                # 0 = up, 1 = fully lowered out of view
var kick := 0.0
var kick_scale := 1.0
var dip := 0.0
var flash := 0.0
var flash_kind := ""            # gun | launch
var sparks: Array = []          # {p, v, life, max}
var puffs: Array = []           # {p, v, r, life, max, hot}
var override_id := ""
var override_t := 0.0
var t := 0.0
var shots := 0                  # counted for tests
var last_rect := Rect2()

var glow: Node2D                # additive layer for the flash, sparks and fire

func _ready() -> void:
	glow = Node2D.new()
	var mat := CanvasItemMaterial.new(); mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.draw.connect(_draw_glow)
	add_child(glow)
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f: data = JSON.parse_string(f.get_as_text())
	if data == null: data = {}

static func load_data() -> Dictionary:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null: return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

func view_info(id: String) -> Dictionary:
	return data.get("views", {}).get(id, {})

func texture_for(id: String) -> Texture2D:
	if not textures.has(id):
		var path := DIR + id + ".png"
		textures[id] = load(path) if ResourceLoader.exists(path) else null
	return textures[id]

## True when this weapon has a side-on reload picture. Thunder M60, the
## launchers and the radio do not — they keep the rear view and only dip.
func has_reload_art(id: String) -> bool:
	var listed: Array = data.get("reload_poses", [])
	if listed:
		return id in listed
	return ResourceLoader.exists(DIR + id + "_reload.png")

func is_reloading() -> bool:
	if sim == null or sim.loadout.is_empty() or override_t > 0.0:
		return false
	return sim.reload_timer > 0.0 if sim.slot != 2 else sim.special_reload > 0.0

## Picture currently drawn: the side reload pose while a magazine gun reloads,
## otherwise the rear firing view.
func draw_id() -> String:
	if shown_id == "":
		return ""
	if is_reloading() and has_reload_art(shown_id):
		return shown_id + "_reload"
	return shown_id

## The weapon the view should show right now (the special or the radio briefly
## replace the selected weapon when they are used from another slot).
func wanted_id() -> String:
	if override_id != "" and override_t > 0.0: return override_id
	if sim == null or sim.loadout.is_empty(): return ""
	return str(sim.loadout[sim.slot].id)

func is_launcher(id: String) -> bool:
	return str(Weapons.get_weapon(id).get("kind", "")) in ["rocket", "lobbed"]

func bind(s) -> void:
	sim = s
	sparks.clear(); puffs.clear(); kick = 0.0; dip = 0.0; flash = 0.0
	override_id = ""; override_t = 0.0
	shown_id = wanted_id(); target_id = shown_id
	phase = "raise"; phase_t = 0.0; lower = 1.0

## Called by main.gd for every StageSim event.
func on_event(name: String, d: Dictionary) -> void:
	match name:
		"shot":
			var id := str(d.get("weapon", ""))
			shots += 1
			_kick(id)
			flash = FLASH_TIME; flash_kind = "gun"
			_spawn_sparks(id)
		"grenade_throw":
			var id := str(d.get("weapon", ""))
			if sim != null and sim.slot != 2:
				override_id = id; override_t = OVERRIDE_TIME.special
			shots += 1
			_kick(id)
			if str(d.get("kind", "thrown")) != "thrown":
				flash = 0.08; flash_kind = "launch"
				_spawn_launch(id)
		"airstrike":
			override_id = "air_strike"; override_t = OVERRIDE_TIME.air_strike

func _kick(id: String) -> void:
	var w := Weapons.get_weapon(id)
	var cat := str(w.get("category", ""))
	var k := 1.0
	match cat:
		"pistol": k = 0.9 + 0.25 * clampf(float(w.get("damage", 1.0)) - 1.0, 0.0, 1.5)
		"smg": k = 0.55
		"rifle": k = 0.8 if float(w.get("fire_rate", 8.0)) >= 5.0 else 1.25
		"special": k = 1.5 if is_launcher(id) else 0.6
	kick_scale = k
	kick = 1.0

## Current transform of the picture: bottom-centre anchor and rotation.
func anchor() -> Vector2:
	var aim := crosshair - Vector2(960, 540)
	var sway := Vector2(sin(t * 1.3) * 6.0, absf(sin(t * 2.6)) * 4.0)
	var p := BASE + Vector2(aim.x * 0.16, aim.y * 0.05) + sway
	p.y += kick * 26.0 * kick_scale + dip * 95.0 + lower * SIZE * 0.85
	return p

func angle() -> float:
	var aim_x := (crosshair.x - 960.0) / 960.0
	return aim_x * 0.11 - kick * 0.035 * kick_scale + dip * 0.14

func local_to_screen(frac: Vector2) -> Vector2:
	var s := SIZE * (1.0 + 0.025 * kick * kick_scale)
	var local := Vector2((frac.x - 0.5) * s, (frac.y - 1.0) * s)
	return anchor() + local.rotated(angle())

func muzzle_screen(id: String = "") -> Vector2:
	if id == "": id = shown_id
	var m: Array = view_info(id).get("muzzle", [0.5, 0.2])
	return local_to_screen(Vector2(float(m[0]), float(m[1])))

## True when the reticle is over a solid part of the picture (arms or weapon);
## the view then turns see-through so the target under it stays visible.
func reticle_over_arms() -> bool:
	var m := mask_for(draw_id())
	if m == null: return false
	var s := SIZE * (1.0 + 0.025 * kick * kick_scale)
	var local := (crosshair - anchor()).rotated(-angle())
	var u := local.x / s + 0.5
	var v := local.y / s + 1.0
	if u < 0.0 or u >= 1.0 or v < 0.0 or v >= 1.0: return false
	return m.get_pixel(int(u * 64.0), int(v * 64.0)).a > 0.3

func mask_for(id: String) -> Image:
	if not masks.has(id):
		var tex := texture_for(id)
		var img: Image = tex.get_image() if tex != null else null
		if img != null:
			if img.is_compressed(): img.decompress()
			img.resize(64, 64, Image.INTERPOLATE_BILINEAR)
		masks[id] = img
	return masks[id]

func _spawn_sparks(id: String) -> void:
	var m := muzzle_screen(id)
	var n := 10 + int(kick_scale * 8.0)
	var dir := (crosshair - m).normalized() if crosshair.distance_to(m) > 1.0 else Vector2.UP
	for i in n:
		var a := dir.angle() + randf_range(-0.9, 0.9)
		var sp := randf_range(300.0, 900.0)
		var life := randf_range(0.1, 0.26)
		sparks.append({"p": m, "v": Vector2.from_angle(a) * sp, "life": life, "max": life})
	if sparks.size() > 160: sparks = sparks.slice(sparks.size() - 160)

func _spawn_launch(id: String) -> void:
	var m := muzzle_screen(id)
	for i in 7:
		var life := randf_range(0.35, 0.75)
		puffs.append({"p": m + Vector2(randf_range(-10, 10), randf_range(-10, 10)), "v": Vector2(randf_range(-80, 80), randf_range(-110, -20)), "r": randf_range(16, 30), "life": life, "max": life, "hot": i < 3})
	var info := view_info(id)
	if info.has("rear"):
		var r := local_to_screen(Vector2(float(info.rear[0]), float(info.rear[1])))
		for i in 9:
			var life := randf_range(0.4, 0.9)
			puffs.append({"p": r, "v": Vector2(randf_range(120, 380), randf_range(-160, -10)), "r": randf_range(24, 46), "life": life, "max": life, "hot": i < 4})

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	t += dt
	var paused: bool = sim != null and sim.paused
	if paused:
		queue_redraw(); return
	if override_t > 0.0:
		override_t -= dt
		if override_t <= 0.0: override_id = ""
	var want := wanted_id()
	if want != target_id:
		target_id = want
		if phase != "lower": phase = "lower"; phase_t = 0.0
	match phase:
		"lower":
			phase_t += dt
			lower = maxf(lower, clampf(phase_t / LOWER_TIME, 0.0, 1.0))
			if phase_t >= LOWER_TIME:
				shown_id = target_id; phase = "raise"; phase_t = 0.0
		"raise":
			phase_t += dt
			var k := clampf(phase_t / RAISE_TIME, 0.0, 1.0)
			lower = minf(lower, 1.0 - (1.0 - pow(1.0 - k, 2.0)))
			if k >= 1.0: phase = "idle"; lower = 0.0
	var reloading := false
	if sim != null and not sim.loadout.is_empty() and override_t <= 0.0:
		reloading = sim.reload_timer > 0.0 if sim.slot != 2 else sim.special_reload > 0.0
	dip = move_toward(dip, 1.0 if reloading else 0.0, dt * 6.0)
	kick = kick * exp(-KICK_DECAY * dt)
	flash = maxf(0.0, flash - dt)
	for s in sparks:
		s.life -= dt; s.p += s.v * dt; s.v.y += 900.0 * dt; s.v *= 0.96
	sparks = sparks.filter(func(s): return s.life > 0.0)
	for p in puffs:
		p.life -= dt; p.p += p.v * dt; p.r += 60.0 * dt; p.v *= 0.97
	puffs = puffs.filter(func(p): return p.life > 0.0)
	queue_redraw()

func _draw() -> void:
	last_rect = Rect2()
	if not active or sim == null or shown_id == "": return
	var tex := texture_for(draw_id())
	if tex == null: return
	var s := SIZE * (1.0 + 0.025 * kick * kick_scale)
	var a := anchor()
	var rect := Rect2(-s * 0.5, -s, s, s)
	# Fade the arms a little when the reticle sits over them so targets stay visible.
	var screen_rect := Rect2(a + rect.position, rect.size)
	last_rect = screen_rect
	var alpha := 0.6 if reticle_over_arms() else 1.0
	draw_set_transform(a, angle(), Vector2.ONE)
	draw_texture_rect(tex, rect, false, Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Smoke (normal blend); fire, flash and sparks go on the additive glow layer.
	for p in puffs:
		var k: float = p.life / p.max
		var r: float = p.r
		draw_circle(p.p, r, Color(0.5, 0.48, 0.45, 0.22 * k))
		draw_circle(p.p, r * 0.7, Color(0.58, 0.56, 0.52, 0.28 * k))
	glow.queue_redraw()

func _draw_glow() -> void:
	if not active or sim == null or shown_id == "": return
	if flash > 0.0 and flash_kind == "gun":
		_draw_flash(muzzle_screen(), flash / FLASH_TIME)
	for p in puffs:
		var k: float = p.life / p.max
		if p.hot and k > 0.45:
			var h := (k - 0.45) / 0.55
			glow.draw_circle(p.p, p.r * 1.3, Color(0.9, 0.35, 0.05, 0.5 * h))
			glow.draw_circle(p.p, p.r * 0.7, Color(1.0, 0.75, 0.3, 0.8 * h))
	for sp in sparks:
		var k: float = sp.life / sp.max
		var tail: Vector2 = sp.p - sp.v * 0.045
		glow.draw_line(tail, sp.p, Color(1.0, 0.55 * k + 0.2, 0.15 * k, k), 4.0)
		glow.draw_line(sp.p - sp.v * 0.015, sp.p, Color(1.0, 0.95, 0.75, k), 2.0)

func _draw_flash(c: Vector2, k: float) -> void:
	var r := 72.0 * (0.65 + 0.35 * k) * clampf(kick_scale, 0.6, 1.4)
	glow.draw_circle(c, r * 1.5, Color(0.8, 0.35, 0.05, 0.35 * k))
	glow.draw_circle(c, r * 0.9, Color(1.0, 0.55, 0.12, 0.45 * k))
	var pts := PackedVector2Array()
	var n := 9
	var rot := randf() * TAU
	for i in n * 2:
		var rr := r * randf_range(0.85, 1.2) if i % 2 == 0 else r * 0.32
		pts.append(c + Vector2.from_angle(rot + i * PI / n) * rr)
	glow.draw_colored_polygon(pts, Color(1.0, 0.72, 0.25, 0.95 * k))
	glow.draw_circle(c, r * 0.38, Color(1.0, 0.95, 0.8, k))
