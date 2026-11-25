extends RefCounted
## Painted sprites for Firebreak (0.2.0, front-facing enemies 0.2.1). Draws characters, pickups and
## vehicles from the masters in assets/sprites/, sized so each figure fills its
## gameplay hitbox. Feet-anchored figures sit on the ground point; pickups, FX
## and vehicles are centre-anchored. Light (tint/haze) is applied per depth
## band by shaders/entity_light.gdshader on the layer that draws the sprite.
## Child villager art is never loaded: the game only spawns adults.

const Meta := preload("res://scripts/sprite_meta.gd")
const UNIT_DIR := "res://assets/sprites/units/"
const VEHICLE_DIR := "res://assets/sprites/vehicles/"
## Barrel tips, in master pixels relative to the sprite anchor. Side poses
## (death frames, heli) face right; the 0.2.1 front poses aim out of the
## screen at the player with the barrel drawn left of the body (see FRONT_NATIVE).
const MUZZLE := {
	"stand": Vector2(-13, -345), "stand_tq": Vector2(-24, -338), "kneel": Vector2(-26, -250),
	"mg": Vector2(1, -210), "descend": Vector2(-24, -411), "heli": Vector2(250, 47),
}
## Front/three-quarter sprites are painted turned slightly to the viewer's
## left. They are mirrored for enemies left of centre so every gun turns in
## toward the player, never along the battlefield at other soldiers.
const FRONT_NATIVE := -1.0
## Stage 1 villager walk and hit frames are painted facing left, so they are
## flipped when the figure walks right. Dune Sea robes are painted facing right.
const VILLAGER_NATIVE := -1.0
const VILLAGER_NATIVE_KIND := {
	"farmer": -1.0, "woman": -1.0, "elder": -1.0,
	"robe_man": 1.0, "robe_woman": 1.0,
	"town_man": 1.0, "town_woman": 1.0,
}

static func villager_native(e: Dictionary) -> float:
	return float(VILLAGER_NATIVE_KIND.get(str(e.get("kind", "farmer")), VILLAGER_NATIVE))
## Hitbox height each reference frame is scaled to (matches StageSim.SIZES).
const TARGET_H := {"rifleman": 360.0, "kneel": 250.0, "villager": 340.0, "mg": 240.0, "paratrooper": 350.0, "sniper": 240.0, "camel": 360.0, "pier_gunner": 250.0}
## On-screen height of the whole descending paratrooper (canopy to boots) at scale 1.
const PARA_TOTAL_H := 712.0
## Every frame an enemy uses while aiming or firing: all face the player.
const FRONT_FRAMES := ["rifleman_front_aim", "rifleman_front_fire", "rifleman_tq_aim", "rifleman_tq_fire",
	"rifleman_kneel_front", "rifleman_kneel_front_flash", "mg_front", "mg_front_flash",
	"paratrooper_front", "paratrooper_front_flash",
	"dune_rifleman_front_aim", "dune_rifleman_front_fire", "dune_rifleman_tq_aim", "dune_rifleman_tq_fire",
	"dune_rifleman_kneel_front", "dune_rifleman_kneel_front_flash", "dune_sniper", "dune_sniper_flash",
	"coral_rifleman_front_aim", "coral_rifleman_front_fire", "coral_rifleman_tq_aim", "coral_rifleman_tq_fire",
	"coral_rifleman_kneel_front", "coral_rifleman_kneel_front_flash", "coast_pier_gunner"]
const PICKUP_ITEM := {
	"rice": "food_rice", "fruit": "food_crate", "canteen": "food_canteen", "ration": "food_medkit",
	"dates": "food_dates", "bread": "food_bread", "waterskin": "food_waterskin",
	"mango": "food_mango", "coconut": "food_coconut", "water": "food_water",
	"ammo": "power_ammo", "grenade": "power_grenade", "rapid": "power_weapon", "spread": "power_weapon",
	"power": "power_weapon", "airstrike": "power_weapon", "cash": "power_cash", "cash_small": "power_cash", "cash_large": "power_cash",
}
const PICKUP_LABEL := {
	"rice": "RICE", "fruit": "FRUIT", "canteen": "WATER", "ration": "MEDKIT", "dates": "DATES", "bread": "BREAD", "waterskin": "WATER",
	"mango": "MANGO", "coconut": "COCONUT", "water": "WATER", "ammo": "AMMO", "grenade": "GRENADES",
	"rapid": "RAPID", "spread": "SPREAD", "power": "POWER", "airstrike": "AIR STRIKE",
	"cash": "$150", "cash_small": "$150", "cash_large": "$400",
}

static var cache := {}

static func meta(name: String) -> Array:
	if Meta.UNITS.has(name): return Meta.UNITS[name]
	return Meta.VEHICLES.get(name, [])

static func tex(name: String) -> Texture2D:
	if cache.has(name): return cache[name]
	if name.contains("child"):
		return null   # adults only
	var path := (UNIT_DIR if Meta.UNITS.has(name) else VEHICLE_DIR) + name + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	cache[name] = t
	return t

## Loads every sprite up front so the first appearance of a figure never stalls a frame.
static func preload_all() -> int:
	var n := 0
	for name in Meta.UNITS.keys() + Meta.VEHICLES.keys():
		if tex(str(name)) != null: n += 1
	return n

static func loaded_names() -> Array:
	var out := []
	for k in cache.keys():
		if cache[k] != null: out.append(k)
	return out

## Height of the opaque figure between its top and the anchor (feet).

## Stage-2 militia use dune_rifleman_* frames; missing names fall back to stage 1.
static func _skinned(e: Dictionary, name: String) -> String:
	var skin := str(e.get("skin", ""))
	if skin != "" and name.begins_with("rifleman"):
		var alt := skin + name.substr(8)
		if tex(alt) != null:
			return alt
	return name

static func fig_h(name: String) -> float:
	var m := meta(name)
	return float(m[3] - m[5]) if not m.is_empty() else 1.0

## Draws a sprite with its anchor at pos. k = uniform scale, facing flips x.
static func draw(ci: CanvasItem, name: String, pos: Vector2, k: float, facing: float = 1.0, mod: Color = Color(1, 1, 1), rot: float = 0.0) -> void:
	var t := tex(name)
	if t == null: return
	var m := meta(name)
	ci.draw_set_transform(pos, rot, Vector2(k * facing, k))
	ci.draw_texture(t, Vector2(-m[2], -m[3]), mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Draws only the top `frac` of a feet-anchored figure with the cut on the
## ground line, so soldiers rise from (and sink behind) cover.
static func draw_rising(ci: CanvasItem, name: String, pos: Vector2, k: float, facing: float, mod: Color, frac: float) -> void:
	var t := tex(name)
	if t == null or frac <= 0.0: return
	var m := meta(name)
	var cut: float = float(m[5]) + clampf(frac, 0.0, 1.0) * float(m[3] - m[5])
	ci.draw_set_transform(pos, 0.0, Vector2(k * facing, k))
	ci.draw_texture_rect_region(t, Rect2(-m[2], -cut, m[0], cut), Rect2(0, 0, m[0], cut), mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Splash ring at the waterline. `pos` is the water surface under the figure.
static func ripple(ci: CanvasItem, pos: Vector2, scale: float, alpha: float, t: float, id: int) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 4.2 + float(id))
	var rx := (42.0 + 10.0 * pulse) * scale
	var ry := (10.0 + 3.0 * pulse) * scale
	var col := Color(0.75, 0.92, 0.95, 0.55 * alpha)
	for i in 2:
		var k := 1.0 + float(i) * 0.28
		ci.draw_arc(pos, rx * k, 0.0, TAU, 28, Color(col, col.a * (1.0 - float(i) * 0.35)), 2.0 + (1.0 - float(i)))
	ci.draw_set_transform(pos, 0.0, Vector2(1.0, 0.28))
	ci.draw_arc(Vector2.ZERO, rx, 0.0, TAU, 28, Color(0.55, 0.78, 0.85, 0.35 * alpha), 3.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## True when this figure should be drawn waist-deep, clipped at the waterline.
static func is_wading(e: Dictionary) -> bool:
	return bool(e.get("wading", false)) and e.state != "dying"

static func flash_mod(e: Dictionary) -> Color:
	# Lift toward a warm highlight. A 1.6 multiplier (peak 2.6) clipped desert
	# camo — and even darker uniforms — to a flat white, which read as a bug.
	var f: float = clampf(float(e.flash), 0.0, 1.0)
	return Color(1.0 + 0.50 * f, 1.0 + 0.42 * f, 1.0 + 0.28 * f, float(e.alpha))

static func scale_for(e: Dictionary, ref: String, target: float) -> float:
	return float(e.scale) * target / fig_h(ref)

static func muzzle_fx(ci: CanvasItem, at: Vector2, k: float, facing: float, mg: bool, id: int, alpha: float) -> void:
	var name := ("fx_muzzle_mg_0%d" if mg else "fx_muzzle_rifle_0%d") % (1 + (id + Engine.get_process_frames() / 3) % 2)
	draw(ci, name, at, k, facing, Color(1.4, 1.3, 1.1, alpha))

static func shadow(ci: CanvasItem, pos: Vector2, w: float, alpha: float) -> void:
	ci.draw_set_transform(pos, 0.0, Vector2(1.0, 0.16))
	ci.draw_circle(Vector2.ZERO, w, Color(0, 0, 0, 0.28 * alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Pulsing red ring at the barrel while an enemy is about to fire.
static func warn_ring(ci: CanvasItem, at: Vector2, amount: float, t: float, s: float) -> void:
	if amount <= 0.0: return
	var pulse := 0.5 + 0.5 * sin(t * 30.0)
	var r := (46.0 + 8.0 * pulse) * clampf(s * 1.3, 0.45, 1.2)
	ci.draw_arc(at, r, 0, TAU, 32, Color(1, 0.15, 0.08, (0.45 + 0.5 * pulse) * amount), 5.0)
	ci.draw_circle(at, 6.0, Color(1, 0.95, 0.7, amount * pulse))

# ------------------------------------------------------------------ soldiers
## Mirror factor for a front pose so the barrel turns toward the player.
static func front_flip(e: Dictionary) -> float:
	return float(e.facing) * FRONT_NATIVE

## Mirror factor for a villager so the painted (left-facing) walk cycle
## travels in the same direction as e.vx / e.facing.
static func villager_flip(e: Dictionary) -> float:
	return float(e.facing) * villager_native(e)

static func _soldier_frame(e: Dictionary) -> String:
	var kneel: bool = e.get("pose", "") == "kneel"
	var name := "rifleman_front_aim"
	if e.state == "dying":
		# dune_rifleman_fall is the kneel pose, so standing deaths stay on the
		# hit / aim body and slump around the feet instead of popping to a kneel.
		name = "rifleman_kneel_front" if kneel else "rifleman_hit"
	elif kneel:
		name = "rifleman_kneel_front_flash" if e.muzzle > 0.0 else "rifleman_kneel_front"
	elif e.muzzle > 0.0:
		name = "rifleman_tq_fire" if int(e.variant) % 2 == 1 else "rifleman_front_fire"
	return _skinned(e, name)

static func _soldier_k(e: Dictionary, kneel: bool) -> float:
	var ref := _skinned(e, "rifleman_kneel_front" if kneel else "rifleman_front_aim")
	return scale_for(e, ref, TARGET_H.kneel if kneel else TARGET_H.rifleman)

## Public wrapper so tests and the death path share the living pose scale.
static func soldier_draw_k(e: Dictionary) -> float:
	return _soldier_k(e, str(e.get("pose", "")) == "kneel")

## Screen position of the barrel tip for any enemy (used for flashes, the
## warning ring and the start of the shot toward the player).
static func muzzle_point(e: Dictionary, pos: Vector2) -> Vector2:
	match e.type:
		"rifleman", "paratrooper":
			if e.type == "paratrooper" and (e.state == "descend"):
				var kp := float(e.scale) * PARA_TOTAL_H / fig_h("paratrooper_front")
				return pos + Vector2(MUZZLE.descend.x * kp * front_flip(e), MUZZLE.descend.y * kp)
			var kneel: bool = e.get("pose", "") == "kneel"
			var k := _soldier_k(e, kneel)
			var mz: Vector2 = MUZZLE.kneel if kneel else (MUZZLE.stand_tq if int(e.variant) % 2 == 1 else MUZZLE.stand)
			var feet := pos
			if is_wading(e):
				var frame := _soldier_frame(e)
				feet = pos + Vector2(0.0, float(e.get("submerge", 0.48)) * k * fig_h(frame))
			return feet + Vector2(mz.x * k * front_flip(e), mz.y * k)
		"mg":
			var km := scale_for(e, "mg_front", TARGET_H.mg)
			return pos + Vector2(MUZZLE.mg.x * km * front_flip(e), MUZZLE.mg.y * km)
		"sniper":
			var ks: float = scale_for(e, "dune_sniper", TARGET_H.sniper) if tex("dune_sniper") != null else float(e.scale)
			return pos + Vector2(8.0 * ks * front_flip(e), -170.0 * ks)
		"camel":
			return pos + Vector2(40.0 * e.scale * e.facing, -280.0 * e.scale)
		"technical", "convoy", "jeep":
			return pos + Vector2(-80.0 * e.scale * e.facing, -200.0 * e.scale)
		"speedboat":
			return pos + Vector2(70.0 * e.scale * e.facing, -110.0 * e.scale)
		"gunboat":
			return pos + Vector2(140.0 * e.scale * e.facing, -160.0 * e.scale)
		"pier_gunner":
			var kp: float = scale_for(e, "coast_pier_gunner", TARGET_H.pier_gunner) if tex("coast_pier_gunner") != null else float(e.scale)
			return pos + Vector2(40.0 * kp * front_flip(e), -150.0 * kp)
		"heli":
			var kh: float = e.scale
			return pos + Vector2(MUZZLE.heli.x * kh * e.facing, MUZZLE.heli.y * kh)
	return pos

## Star-shaped flash pointing out of the screen at the player.
static func front_flash(ci: CanvasItem, at: Vector2, size: float, alpha: float, id: int) -> void:
	var spin := float((id * 37 + Engine.get_process_frames()) % 12) * 0.26
	ci.draw_circle(at, size * 0.9, Color(1.0, 0.55, 0.15, 0.35 * alpha))
	for i in 6:
		var ang := spin + TAU * i / 6.0
		var len := size * (1.6 if i % 2 == 0 else 1.0)
		var d := Vector2.from_angle(ang)
		var n := d.orthogonal() * size * 0.22
		ci.draw_colored_polygon(PackedVector2Array([at + n, at + d * len, at - n]), Color(1.0, 0.85, 0.4, 0.85 * alpha))
	ci.draw_circle(at, size * 0.45, Color(1.0, 0.97, 0.8, alpha))

static func soldier(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	var kneel: bool = e.get("pose", "") == "kneel"
	var frame := _soldier_frame(e)
	var mod := flash_mod(e)
	if e.state == "dying":
		# Keep the same on-screen height as the living pose and slump around
		# the feet. Sizing from the stage-1 side-view refs (rifleman_aim /
		# rifleman_kneel) blew the taller dune skins up 2-4x, so a mid
		# militiaman looked like a near one floating over the dunes.
		var kd := _soldier_k(e, kneel)
		var fade: float = clampf(e.timer / 0.5, 0.0, 1.0)
		var rot: float = float(e.get("fall_rot", 0.0)) * 1.1 * (1.0 if float(e.facing) >= 0.0 else -1.0)
		draw(ci, frame, pos, kd, e.facing, Color(mod.r, mod.g, mod.b, fade), rot)
		return
	var k := _soldier_k(e, kneel)
	var f := front_flip(e)
	if is_wading(e):
		var wet: float = float(e.get("submerge", 0.48))
		ripple(ci, pos, k, e.alpha, t, int(e.get("id", 0)))
		draw_rising(ci, frame, pos, k, f, mod, 1.0 - wet)
	else:
		shadow(ci, pos, 60.0 * k, e.alpha * float(e.rise))
		if e.state in ["rise", "duck"] or e.rise < 1.0:
			draw_rising(ci, frame, pos, k, f, mod, e.rise)
		else:
			draw(ci, frame, pos, k, f, mod)
	var at := muzzle_point(e, pos)
	if e.muzzle > 0.0:
		front_flash(ci, at, 34.0 * float(e.scale) + 6.0, e.alpha, e.id)
	if e.state == "aim" and e.timer < 0.6:
		warn_ring(ci, at, clampf(1.0 - e.timer / 0.6, 0.0, 1.0), t, e.scale)

static func paratrooper(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	if e.state == "descend" or (e.state == "dying" and not e.get("landed", false)):
		if e.state == "dying":
			# Mid-air death: centre-anchored tumble, no extra rotation.
			var kd := float(e.scale) * 300.0 / 520.0
			draw(ci, "paratrooper_death", pos + Vector2(0, -175.0 * e.scale), kd, e.facing, Color(1, 1, 1, clampf(e.timer / 0.5, 0.0, 1.0)))
			return
		var k := float(e.scale) * PARA_TOTAL_H / fig_h("paratrooper_front")
		var sway: float = sin(t * 1.4 + e.id) * 0.04
		draw(ci, "paratrooper_front_flash" if e.muzzle > 0.0 else "paratrooper_front", pos, k, front_flip(e), flash_mod(e), sway)
		var at := muzzle_point(e, pos)
		if e.muzzle > 0.0:
			front_flash(ci, at, 30.0 * float(e.scale) + 6.0, e.alpha, e.id)
		if e.timer < 0.6:
			warn_ring(ci, at, clampf(1.0 - e.timer / 0.6, 0.0, 1.0), t, e.scale)
		return
	# Landed: the collapsed canopy fades behind him, then he fights like a rifleman.
	var since: float = e.age - float(e.get("landed_at", e.age))
	var col := clampf(1.0 - since / 2.5, 0.0, 1.0)
	if col > 0.0:
		var kc := scale_for(e, "paratrooper_body", TARGET_H.paratrooper) * 0.55
		draw(ci, "parachute_collapsed", pos + Vector2(-150.0 * e.scale * e.facing, 0), kc, e.facing, Color(1, 1, 1, col * e.alpha))
	soldier(ci, e, pos, t)

static func mg_nest(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	var k := scale_for(e, "mg_front", TARGET_H.mg)
	var mod := flash_mod(e)
	if e.state == "dying":
		var fade: float = clampf(e.timer / 0.6, 0.0, 1.0)
		mod = Color(0.45, 0.4, 0.38, fade)
	var firing: bool = e.state == "burst" and e.muzzle > 0.0
	draw(ci, "mg_front_flash" if firing else "mg_front", pos, k, front_flip(e), mod)
	var at := muzzle_point(e, pos)
	if firing:
		front_flash(ci, at, 46.0 * float(e.scale) + 8.0, e.alpha, e.id)
	if e.state == "aim" and e.timer < 0.7:
		warn_ring(ci, at, clampf(1.0 - e.timer / 0.7, 0.0, 1.0), t, e.scale)

static func _villager_frame(kind: String, pose: String) -> String:
	if kind.begins_with("robe_"):
		return "dune_%s_%s" % [kind, pose]
	if kind.begins_with("town_"):
		return "%s_%s" % [kind, pose]
	return "villager_%s_%s" % [kind, pose]

static func villager(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	var kind: String = str(e.get("kind", "farmer"))
	if not (kind in ["farmer", "woman", "elder", "robe_man", "robe_woman", "town_man", "town_woman"]):
		kind = "farmer"
	var ref := _villager_frame(kind, "walk_01")
	if tex(ref) == null:
		ref = "villager_farmer_walk_01"
	var k := scale_for(e, ref, TARGET_H.villager)
	var frame := ref
	if e.state == "dying":
		frame = _villager_frame(kind, "hit")
		if tex(frame) == null:
			frame = "villager_farmer_hit"
		k = float(e.scale) * TARGET_H.villager * 0.95 / fig_h(frame)
	else:
		frame = _villager_frame(kind, "walk_0%d" % (1 + int(e.age * 6.0 + e.id) % 4))
		if tex(frame) == null:
			frame = ref
	if is_wading(e):
		var wet: float = float(e.get("submerge", 0.48))
		ripple(ci, pos, k, e.alpha, t, int(e.get("id", 0)))
		draw_rising(ci, frame, pos, k, villager_flip(e), flash_mod(e), 1.0 - wet)
	else:
		shadow(ci, pos, 50.0 * k, e.alpha)
		draw(ci, frame, pos, k, villager_flip(e), flash_mod(e))

static func pickup(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	var is_food: bool = e.type == "food"
	var kind: String = str(e.kind)
	var item: String = PICKUP_ITEM.get(kind, "power_ammo")
	var m := meta(item)
	var used: float = maxf(float(m[6] - m[4]), float(m[7] - m[5])) if not m.is_empty() else 128.0
	var k := (104.0 if is_food else 118.0) / used
	var mod := flash_mod(e)
	if e.state == "fall":
		var sway := sin(t * 1.3 + e.id) * 0.06
		draw(ci, "food_parachute", pos + Vector2(0, -92), 0.62, 1.0, Color(1, 1, 1, e.alpha), sway)
	var glow := Color(0.4, 1.0, 0.45) if is_food else (Color(1.0, 0.35, 0.25) if kind == "airstrike" else Color(1.0, 0.82, 0.25))
	if kind.begins_with("cash"): glow = Color(0.5, 1.0, 0.4)
	var pulse := 0.5 + 0.5 * sin(t * 6.0 + e.id)
	ci.draw_arc(pos, 62 + pulse * 6, 0, TAU, 32, Color(glow, (0.35 + 0.4 * pulse) * e.alpha), 5.0)
	draw(ci, item, pos, k, 1.0, mod)
	if kind in ["rapid", "spread", "power", "airstrike"]:
		ci.draw_circle(pos + Vector2(34, -30), 15, Color(glow, e.alpha))
	var font := ThemeDB.fallback_font
	var txt: String = PICKUP_LABEL.get(kind, "")
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	ci.draw_string_outline(font, pos + Vector2(-w * 0.5, 82), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color(0, 0, 0, 0.85 * e.alpha))
	ci.draw_string(font, pos + Vector2(-w * 0.5, 82), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, e.alpha))

# ------------------------------------------------------------------ helicopter
static func heli(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	var k: float = e.scale
	var f: float = e.facing
	if e.state == "crash":
		var rot: float = f * minf(0.9, float(e.crash_t) * 0.6)
		draw(ci, "heli_crash", pos, k * 1.25, f, Color(1, 1, 1), rot)
		return
	var firing: bool = e.gunner_alive and e.muzzle > 0.0
	var mod := flash_mod(e)
	if e.get("smoking", false):
		mod = Color(mod.r * 0.78, mod.g * 0.74, mod.b * 0.72, mod.a)
	var tilt := -0.05 * f if e.state in ["fly", "leave"] else 0.0
	draw(ci, "heli_gunner" if firing else "heli_idle", pos, k, f, mod, tilt)
	if not e.gunner_alive:
		# Empty doorway once the door gunner is down.
		ci.draw_set_transform(pos, tilt, Vector2(k * f, k))
		ci.draw_rect(Rect2(28, 2, 66, 90), Color(0.09, 0.08, 0.06, 0.92))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var at := muzzle_point(e, pos)
	if firing:
		muzzle_fx(ci, at, k * 0.5, f, true, e.id, 1.0)
		front_flash(ci, at, 22.0, 1.0, e.id)
	if e.gunner_alive and e.burst <= 0.0 and e.aim < 0.6:
		warn_ring(ci, at, clampf(1.0 - e.aim / 0.6, 0.0, 1.0), t, 0.8)

static func sniper(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	var frame := "dune_sniper_flash" if e.muzzle > 0.0 and tex("dune_sniper_flash") != null else "dune_sniper"
	if tex(frame) == null:
		mg_nest(ci, e, pos, t)
		return
	var k := scale_for(e, "dune_sniper", TARGET_H.sniper)
	shadow(ci, pos, 140.0 * k, 0.28 * e.alpha)
	draw(ci, frame, pos, k, front_flip(e), flash_mod(e))
	if e.state == "aim" and e.timer < 0.8:
		warn_ring(ci, pos + Vector2(0, -160.0 * k), clampf(1.0 - e.timer / 0.8, 0.0, 1.0), t, k)

static func camel(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	var k: float = scale_for(e, "dune_camel", TARGET_H.camel) if tex("dune_camel") != null else float(e.scale)
	shadow(ci, pos, 200.0 * k, 0.3 * e.alpha)
	if tex("dune_camel") == null:
		return
	draw(ci, "dune_camel", pos, k, e.facing, flash_mod(e))
	if e.muzzle > 0.0:
		muzzle_fx(ci, muzzle_point(e, pos), k, e.facing, false, e.id, e.muzzle)

static func technical(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	_vehicle_sprite(ci, e, pos, t, "dune_technical")

static func convoy(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	_vehicle_sprite(ci, e, pos, t, "dune_convoy")

static func _vehicle_sprite(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float, name: String) -> void:
	if tex(name) == null:
		return
	var m := meta(name)
	var fig := float(m[7] - m[5]) if not m.is_empty() else 300.0
	var k: float = e.size.y * e.scale / maxf(1.0, fig)
	shadow(ci, pos, 280.0 * k, 0.32 * e.alpha)
	var bounce := sin(t * 14.0) * 2.0 if e.state == "drive" else 0.0
	draw(ci, name, pos + Vector2(0, bounce), k, e.facing, flash_mod(e))
	if e.muzzle > 0.0:
		muzzle_fx(ci, muzzle_point(e, pos), k, e.facing, true, e.id, e.muzzle)

static func jeep(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	_vehicle_sprite(ci, e, pos, t, "coast_jeep")

static func speedboat(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	_vehicle_sprite(ci, e, pos, t, "coast_speedboat")

static func gunboat(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	_vehicle_sprite(ci, e, pos, t, "coast_gunboat")
	if e.get("gunner2_alive", false) and e.state != "dying":
		var s: float = e.scale
		var ox: float = (e.size.x * s * -0.06) * (1.0 if e.facing > 0.0 else -1.0)
		var gp := pos + Vector2(ox, -18.0 * s)
		var frame := "coral_rifleman_aim_front"
		if tex(frame) == null:
			frame = "rifleman_aim_front"
		if tex(frame) != null:
			var gk := 0.42 * s
			draw(ci, frame, gp, gk, -1.0 if e.facing < 0.0 else 1.0, flash_mod(e))
		if e.muzzle > 0.0:
			front_flash(ci, gp + Vector2(20.0 * s * e.facing, -70.0 * s), 22.0 * s, e.alpha, int(e.get("id", 0)) + 17)

static func pier_gunner(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	var frame := "coast_pier_gunner"
	if tex(frame) == null:
		frame = "coral_rifleman_kneel_front"
	if tex(frame) == null:
		mg_nest(ci, e, pos, t)
		return
	var k := scale_for(e, frame, TARGET_H.pier_gunner)
	if e.muzzle > 0.0 and tex("coral_rifleman_kneel_front_flash") != null:
		frame = "coral_rifleman_kneel_front_flash"
	shadow(ci, pos, 120.0 * k, 0.28 * e.alpha)
	draw(ci, frame, pos, k, front_flip(e), flash_mod(e))
	if e.state == "aim" and e.timer < 0.8:
		warn_ring(ci, muzzle_point(e, pos), clampf(1.0 - e.timer / 0.8, 0.0, 1.0), t, k)
