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
## Villager walk and hit frames are painted facing left, so they are flipped
## when the figure walks right (the opposite of the usual facing=1 convention).
const VILLAGER_NATIVE := -1.0
## Hitbox height each reference frame is scaled to (matches StageSim.SIZES).
const TARGET_H := {"rifleman": 360.0, "kneel": 250.0, "villager": 340.0, "mg": 240.0, "paratrooper": 350.0}
## On-screen height of the whole descending paratrooper (canopy to boots) at scale 1.
const PARA_TOTAL_H := 712.0
## Every frame an enemy uses while aiming or firing: all face the player.
const FRONT_FRAMES := ["rifleman_front_aim", "rifleman_front_fire", "rifleman_tq_aim", "rifleman_tq_fire",
	"rifleman_kneel_front", "rifleman_kneel_front_flash", "mg_front", "mg_front_flash",
	"paratrooper_front", "paratrooper_front_flash"]
const PICKUP_ITEM := {
	"rice": "food_rice", "fruit": "food_crate", "canteen": "food_canteen", "ration": "food_medkit",
	"ammo": "power_ammo", "grenade": "power_grenade", "rapid": "power_weapon", "spread": "power_weapon",
	"power": "power_weapon", "airstrike": "power_weapon", "cash": "power_cash", "cash_small": "power_cash", "cash_large": "power_cash",
}
const PICKUP_LABEL := {
	"rice": "RICE", "fruit": "FRUIT", "canteen": "WATER", "ration": "MEDKIT", "ammo": "AMMO", "grenade": "GRENADES",
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

static func flash_mod(e: Dictionary) -> Color:
	var f: float = 1.0 + 1.6 * float(e.flash)
	return Color(f, f, f, float(e.alpha))

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
	return float(e.facing) * VILLAGER_NATIVE

static func _soldier_frame(e: Dictionary) -> String:
	var kneel: bool = e.get("pose", "") == "kneel"
	if e.state == "dying":
		return "rifleman_hit" if e.timer > 0.45 and not kneel else "rifleman_fall"
	if kneel:
		return "rifleman_kneel_front_flash" if e.muzzle > 0.0 else "rifleman_kneel_front"
	if e.muzzle > 0.0:
		return "rifleman_tq_fire" if int(e.variant) % 2 == 1 else "rifleman_front_fire"
	return "rifleman_front_aim"

static func _soldier_k(e: Dictionary, kneel: bool) -> float:
	return scale_for(e, "rifleman_kneel_front" if kneel else "rifleman_front_aim", TARGET_H.kneel if kneel else TARGET_H.rifleman)

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
			return pos + Vector2(mz.x * k * front_flip(e), mz.y * k)
		"mg":
			var km := scale_for(e, "mg_front", TARGET_H.mg)
			return pos + Vector2(MUZZLE.mg.x * km * front_flip(e), MUZZLE.mg.y * km)
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
		# Death frames are the side-view falls; sized from the side reference.
		var kd := scale_for(e, "rifleman_kneel" if kneel else "rifleman_aim", TARGET_H.kneel if kneel else TARGET_H.rifleman)
		var fade: float = clampf(e.timer / 0.5, 0.0, 1.0)
		draw(ci, frame, pos, kd, e.facing, Color(mod.r, mod.g, mod.b, fade))
		return
	var k := _soldier_k(e, kneel)
	var f := front_flip(e)
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

static func villager(ci: CanvasItem, e: Dictionary, pos: Vector2, t: float) -> void:
	var kind: String = str(e.get("kind", "farmer"))
	if not (kind in ["farmer", "woman", "elder"]): kind = "farmer"
	var ref := "villager_%s_walk_01" % kind
	var k := scale_for(e, ref, TARGET_H.villager)
	var frame := ref
	if e.state == "dying":
		frame = "villager_%s_hit" % kind
		k = float(e.scale) * TARGET_H.villager * 0.95 / fig_h(frame)
	else:
		frame = "villager_%s_walk_0%d" % [kind, 1 + int(e.age * 6.0 + e.id) % 4]
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
