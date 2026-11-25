extends RefCounted
## Firebreak stage simulation: timer, scrolling camera, spawning, enemy AI,
## player weapon, pickups and scoring. No nodes or rendering here, so the
## headless tests drive exactly the same rules the game uses.

signal event(name: String, data: Dictionary)

const StageData := preload("res://scripts/stage_data.gd")
const Weapons := preload("res://scripts/weapons.gd")
const Ground := preload("res://scripts/stage_ground.gd")
const VIEW_W := 1920.0
const VIEW_H := 1080.0
const ENEMY_TYPES := ["rifleman", "mg", "paratrooper", "truck", "heli", "camel", "technical", "sniper", "convoy", "speedboat", "jeep", "pier_gunner", "gunboat", "rusher", "grenadier"]
const SIZES := {
	"rifleman": Vector2(130, 360), "paratrooper": Vector2(130, 350), "mg": Vector2(200, 240),
	"villager": Vector2(120, 340), "truck": Vector2(560, 300), "food": Vector2(96, 96), "powerup": Vector2(110, 110),
	"heli": Vector2(650, 256), "camel": Vector2(420, 360), "technical": Vector2(620, 280), "sniper": Vector2(280, 240), "convoy": Vector2(640, 300),
	"speedboat": Vector2(360, 140), "jeep": Vector2(420, 200), "pier_gunner": Vector2(150, 250), "gunboat": Vector2(620, 280),
	"rusher": Vector2(130, 360), "grenadier": Vector2(150, 250),
}
const BASE_HP := {"rifleman": 1.0, "paratrooper": 1.0, "mg": 3.0, "truck": 14.0, "heli": 16.0, "villager": 1.0, "food": 1.0, "powerup": 1.0, "camel": 1.0, "technical": 11.0, "sniper": 2.0, "convoy": 17.0, "speedboat": 8.0, "jeep": 11.0, "pier_gunner": 3.0, "gunboat": 30.0, "rusher": 2.0, "grenadier": 2.0}
const BASE_SCORE := {"rifleman": 100, "paratrooper": 200, "mg": 400, "truck": 1500, "heli": 2500, "food": 50, "powerup": 50, "camel": 200, "technical": 1800, "sniper": 500, "convoy": 2000, "speedboat": 800, "jeep": 1800, "pier_gunner": 400, "gunboat": 2500, "rusher": 200, "grenadier": 300}
const GUNNER_SCORE := 300
const GUNNER_HP := 2.0
const HELI_SCALE := 0.75
const AIM_TIME := {"far": 1.7, "mid": 1.35, "near": 1.1}
const FOOD_HEAL := {"rice": 15.0, "fruit": 10.0, "canteen": 8.0, "ration": 25.0, "dates": 12.0, "bread": 10.0, "waterskin": 8.0, "mango": 12.0, "coconut": 12.0, "water": 8.0}
const POWERUP_KINDS := ["ammo", "grenade", "rapid", "spread", "power", "airstrike"]
## Adults only. Child villagers are never spawned (their art is not loaded either).
const VILLAGER_KINDS := ["farmer", "woman", "elder"]
const VILLAGER_PENALTY_HEALTH := 10.0
const VILLAGER_PENALTY_SCORE := 500
## Bonus added on a killing headshot (already a multiple of 10, and applied
## after the band multiplier so the total score stays a multiple of 10).
const HEADSHOT_BONUS := 50
const HEADSHOT_TYPES := ["rifleman", "paratrooper", "mg", "camel", "sniper", "pier_gunner", "rusher", "grenadier"]
## RAPID power-up multiplies the carried weapon's fire rate.
const RAPID_MULT := 1.6
const SWITCH_TIME := 0.18   # seconds after a weapon swap before it can fire
const POWER_TIMER := 20.0
## Blast radius whose circle covers about 30% of the 1920x1080 screen:
## r = sqrt(0.30 * 1920 * 1080 / PI) = 445.4 px.
const GRENADE_AREA_FRACTION := 0.30
const GRENADE_RADIUS := 445.4
const GRENADE_DAMAGE := 6.0
const START_GRENADES := 5
const START_AIRSTRIKES := 1
const AIRSTRIKE_IMPACT := 1.25   # seconds from the call to the bombs landing
const AIRSTRIKE_DURATION := 2.6
const PICKUP_GROUND_Y := 900.0
## Bottom HUD (health + weapon bar) starts here; near feet stay above it.
const HUD_BAND_TOP := 940.0
## Killing this many civilians fails the stage on every map.
const CIVILIAN_LIMIT := 3
## Infantry that can stand waist-deep in water (boats stay on their paths).
const WADING_TYPES := ["rifleman", "paratrooper", "rusher"]
const WADING_SUBMERGE := 0.48
## Fraction of the view width where the harbour gunboat holds.
const GUNBOAT_HOLD := 0.82

var stage: Dictionary = {}
var stage_number := 1
var diff: Dictionary = {}
var rng := RandomNumberGenerator.new()
## Cosmetic randomness (where enemy shots land on screen) kept apart from the
## gameplay RNG so visuals never change spawns, hits or scores.
var fx_rng := RandomNumberGenerator.new()

var time := 0.0
var duration := 180.0
var camera_x := 0.0
var entities: Array = []
var next_id := 1
var wave_index := 0
var pending: Array = []
var ambient_next: Array = []
var grenades_in_flight: Array = []
var enemy_nades: Array = []

var state := "playing"   # playing | cleared | failed
var end_reason := ""
## Coral Coast harbour arena: the stage does not clear on quota or time
## while the gunboat is still to be destroyed.
var arena_done := false
var arena_sink := 0.0
var paused := false
var score := 0
var clear_bonus := 0
var health := 100.0
var max_health := 100.0
## Three carried weapons (pistol, primary, special), each with its own ammo:
## [{"id": String, "mag": int, "reserve": int (-1 = unlimited)}]. Weapons
## stats come from data/weapons.json. `slot` is the one the trigger fires.
var loadout: Array = []
var slot := 1
var cash := 0
var cash_earned := 0
var cash_lost := 0
var bloom := 0.0             # spread grows while the trigger is held
var reload_duration := 1.0
var special_reload := 0.0
var special_cooldown := 0.0
var airstrikes := START_AIRSTRIKES

## Rounds in the selected weapon's magazine.
var ammo: int:
	get: return int(loadout[slot].mag) if slot < loadout.size() else 0
	set(v): if slot < loadout.size(): loadout[slot].mag = clampi(v, 0, int(weapon().get("mag", 0)))
## Spare magazines of the selected weapon (rounds in reserve / magazine size, rounded up).
var mags: int:
	get:
		if slot >= loadout.size(): return 0
		var r := int(loadout[slot].reserve)
		if r < 0: return 99
		return int(ceil(float(r) / maxf(1.0, float(weapon().get("mag", 1)))))
	set(v): if slot < loadout.size() and int(loadout[slot].reserve) >= 0: loadout[slot].reserve = maxi(0, v) * int(weapon().get("mag", 1))
## Rounds of the special weapon (grenades, rockets...) left in total.
var grenades: int:
	get: return special_total()
	set(v):
		if loadout.size() < 3: return
		var m := mini(maxi(0, v), int(weapon_in(2).get("mag", 1)))
		loadout[2].mag = m; loadout[2].reserve = maxi(0, v - m)
var strike := {}   # active air strike: {"t": seconds, "hit": bool, "targets": [screen points]}
var reload_timer := 0.0
var fire_cooldown := 0.0
var rapid_timer := 0.0
var spread_timer := 0.0
var weapon_level := 1
var kills := 0
var quota := 55
var stats := {"shots": 0, "hits": 0, "villagers_hit": 0, "food": 0, "powerups": 0, "damage_taken": 0.0}

func setup(number: int = 1, seed: int = 1, data: Dictionary = {}, profile: Dictionary = {}) -> bool:
	stage_number = number
	stage = data if not data.is_empty() else StageData.load_stage(number)
	if stage.is_empty():
		return false
	diff = StageData.difficulty(number)
	var boost = stage.get("diff_mult", {})
	if boost is Dictionary:
		for k in boost:
			if diff.has(k):
				diff[k] = float(diff[k]) * float(boost[k])
	rng.seed = seed
	fx_rng.seed = seed * 7919 + 13
	duration = minf(float(stage.get("duration", 180.0)), 180.0)
	quota = maxi(1, int(round(float(stage.get("enemy_quota", 55)) * float(diff.get("quota", 1.0)))))
	time = 0.0; camera_x = 0.0; entities.clear(); pending.clear(); grenades_in_flight.clear(); enemy_nades.clear()
	next_id = 1; wave_index = 0; state = "playing"; end_reason = ""; paused = false
	arena_done = false; arena_sink = 0.0
	score = 0; clear_bonus = 0; health = max_health
	airstrikes = START_AIRSTRIKES; strike = {}
	apply_profile(profile if not profile.is_empty() else Weapons.default_profile())
	reload_timer = 0.0; fire_cooldown = 0.0; rapid_timer = 0.0; spread_timer = 0.0; weapon_level = 1; kills = 0
	stats = {"shots": 0, "hits": 0, "villagers_hit": 0, "food": 0, "powerups": 0, "damage_taken": 0.0, "cash_drops": 0}
	ambient_next.clear()
	for rule in stage.get("ambient", []):
		ambient_next.append(float(rule.get("from", 0.0)) + _rand_every(rule))
	camera_x = camera_at(0.0)
	return true

# ---------------------------------------------------------------- helpers
func band_info(band: String) -> Dictionary:
	return stage.get("bands", {}).get(band, {})

func band_scale(band: String) -> float:
	return float(band_info(band).get("scale", 1.0))

func grounded_offenders(out: Array = []) -> int:
	var n := 0
	for e in entities:
		var off := Ground.feet_off(stage, e)
		if off < 0.0:
			continue
		var slack := Ground.feet_slack(e)
		if off > slack:
			n += 1
			if out.size() < 24:
				out.append({
					"id": e.get("id", 0), "type": e.type, "band": e.get("band", ""),
					"state": e.get("state", ""), "pose": e.get("pose", ""),
					"x": e.x, "y": e.y, "ground_y": e.get("ground_y", 0.0),
					"off": off, "time": time
				})
	return n

func enemies_remaining() -> int:
	return maxi(0, quota - kills)

func time_left() -> float:
	return maxf(0.0, duration - time)

func camera_at(t: float) -> float:
	var keys: Array = stage.get("scroll", [])
	if keys.is_empty():
		return 0.0
	if t <= float(keys[0][0]):
		return float(keys[0][1])
	for i in range(1, keys.size()):
		var a = keys[i - 1]; var b = keys[i]
		if t <= float(b[0]):
			var span := maxf(0.0001, float(b[0]) - float(a[0]))
			var f := clampf((t - float(a[0])) / span, 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)   # ease in and out of each combat beat
			return lerpf(float(a[1]), float(b[1]), f)
	return float(keys[keys.size() - 1][1])

# ---------------------------------------------------------------- weapons and loadout
## Loads the carried weapons, ammo, cash and air strikes from a profile and
## applies the field issue: every weapon starts the stage with a full magazine
## and at least its issue reserve (so the 5 starter grenades come back each stage).
func apply_profile(p: Dictionary) -> void:
	var prof := Weapons.sanitize(p)
	loadout.clear()
	for i in Weapons.SLOT_COUNT:
		var id: String = prof.loadout[i]
		var w := Weapons.get_weapon(id)
		var a: Dictionary = prof.ammo.get(id, Weapons.fresh_ammo(id))
		var res := int(a.reserve)
		if res >= 0: res = maxi(res, Weapons.issue_reserve(w))
		loadout.append({"id": id, "mag": int(w.mag), "reserve": res})
	cash = int(prof.cash)
	airstrikes = maxi(int(prof.airstrikes), int(Weapons.support().get("issue", START_AIRSTRIKES)))
	slot = 1; bloom = 0.0; special_reload = 0.0; special_cooldown = 0.0; cash_earned = 0; cash_lost = 0

## Writes ammo, cash and air strikes back into the profile (end of a stage).
func write_profile(p: Dictionary) -> Dictionary:
	for e in loadout:
		p.ammo[e.id] = {"mag": int(e.mag), "reserve": int(e.reserve)}
	p.cash = cash
	p.airstrikes = clampi(airstrikes, 0, int(Weapons.support().get("max", 3)))
	p.earned_total = int(p.get("earned_total", 0)) + cash_earned
	return p

func weapon() -> Dictionary:
	return weapon_in(slot)

func weapon_in(i: int) -> Dictionary:
	if i < 0 or i >= loadout.size(): return {}
	return Weapons.get_weapon(str(loadout[i].id))

func mag_size() -> int:
	return int(weapon().get("mag", 0))

func special_total() -> int:
	if loadout.size() < 3: return 0
	return int(loadout[2].mag) + maxi(0, int(loadout[2].reserve))

func slot_empty(i: int) -> bool:
	if i < 0 or i >= loadout.size(): return true
	return int(loadout[i].mag) <= 0 and int(loadout[i].reserve) == 0

## Selects slot 0 (pistol), 1 (primary) or 2 (special). A swap cancels a
## reload in progress and costs a short moment before the next shot.
func select_slot(i: int) -> bool:
	if state != "playing" or paused or i < 0 or i >= loadout.size() or i == slot: return false
	slot = i; reload_timer = 0.0; bloom = 0.0
	fire_cooldown = maxf(fire_cooldown, SWITCH_TIME)
	event.emit("weapon_switch", {"slot": i, "weapon": str(loadout[i].id)})
	return true

func cycle_slot(dir: int) -> bool:
	return select_slot(posmod(slot + (1 if dir >= 0 else -1), loadout.size()))

func fire_interval() -> float:
	var rate := float(weapon().get("fire_rate", 8.0))
	return 1.0 / (rate * (RAPID_MULT if rapid_timer > 0.0 else 1.0))

func shot_damage() -> float:
	return float(weapon().get("damage", 1.0)) * [1.0, 1.0, 1.5, 2.0][clampi(weapon_level, 0, 3)]

# ---------------------------------------------------------------- cash
func cash_for(e: Dictionary) -> int:
	var eco := Weapons.economy()
	var base := int(eco.get("kill_cash", {}).get(e.type, 0))
	var mult := float(eco.get("band_cash_mult", {}).get(e.band, 1.0))
	return int(round(base * mult))

func add_cash(amount: int, pos: Vector2, reason: String) -> void:
	if amount <= 0: return
	cash += amount; cash_earned += amount
	event.emit("cash", {"amount": amount, "pos": pos, "reason": reason})

func lose_cash(amount: int, pos: Vector2, reason: String) -> void:
	var lost := mini(cash, amount)
	cash -= lost; cash_lost += lost
	event.emit("cash_lost", {"amount": lost, "wanted": amount, "pos": pos, "reason": reason})

func _rand_every(rule: Dictionary) -> float:
	var e: Array = rule.get("every", [3.0, 3.0])
	var dens := float(diff.get("density", 1.0))
	return rng.randf_range(float(e[0]), float(e[1])) / maxf(0.1, dens)

func _weighted(weights: Dictionary) -> String:
	var total := 0.0
	for k in weights: total += float(weights[k])
	var r := rng.randf() * total
	for k in weights:
		r -= float(weights[k])
		if r <= 0.0: return str(k)
	return str(weights.keys()[0])

## Picks a spawn point for a band inside the current view and that band's
## walkable ground spans. Y comes from the stage ground map (panorama art).
## Returns Vector2(world_x, ground_y) or Vector2(-1, -1).
func pick_point(band: String, margin: float = 120.0, frac: float = -1.0) -> Vector2:
	var lo := camera_x + margin
	var hi := camera_x + VIEW_W - margin
	var spans := []
	var total := 0.0
	for z in Ground.ground_spans(stage, band):
		var a := maxf(lo, float(z[0])); var b := minf(hi, float(z[1]))
		if b - a > 20.0:
			spans.append([a, b]); total += b - a
	if spans.is_empty():
		return Vector2(-1, -1)
	var x: float
	if frac >= 0.0:
		var want := lerpf(lo, hi, frac)
		var best = spans[0]; var bd := INF
		for s in spans:
			var cx := clampf(want, s[0], s[1])
			if absf(cx - want) < bd: bd = absf(cx - want); best = s
		x = clampf(want, best[0], best[1])
	else:
		var r := rng.randf() * total
		x = spans[spans.size() - 1][1]
		for s in spans:
			r -= s[1] - s[0]
			if r <= 0.0:
				x = rng.randf_range(s[0], s[1])
				break
	return Vector2(x, Ground.ground_y(stage, band, x))

## Water combat point inside the current view, or Vector2(-1, -1).
func pick_water_point(band: String, margin: float = 140.0, frac: float = -1.0) -> Vector2:
	if not Ground.has_water(stage):
		return Vector2(-1, -1)
	var lo := camera_x + margin
	var hi := camera_x + VIEW_W - margin
	var spans := []
	var total := 0.0
	for z in Ground.water_spans(stage, band):
		var a := maxf(lo, float(z[0])); var b := minf(hi, float(z[1]))
		if b - a > 20.0:
			spans.append([a, b]); total += b - a
	if spans.is_empty():
		return Vector2(-1, -1)
	var x: float
	if frac >= 0.0:
		var want := lerpf(lo, hi, frac)
		var best = spans[0]; var bd := INF
		for s in spans:
			var cx := clampf(want, s[0], s[1])
			if absf(cx - want) < bd: bd = absf(cx - want); best = s
		x = clampf(want, best[0], best[1])
	else:
		var r := rng.randf() * total
		x = spans[spans.size() - 1][1]
		for s in spans:
			r -= s[1] - s[0]
			if r <= 0.0:
				x = rng.randf_range(s[0], s[1])
				break
	var y := Ground.water_y(stage, x, band)
	if y <= 0.0:
		return Vector2(-1, -1)
	return Vector2(x, y)

## Land, or sometimes water, for combat infantry. Villagers must use pick_point.
## Water combat spawns are opt-in per stage so river and oasis gaps stay empty
## unless a figure is planted there (in which case they wade).
func pick_combat_point(band: String, margin: float = 140.0, frac: float = -1.0) -> Vector2:
	if not bool(stage.get("water_combat", false)):
		return pick_point(band, margin, frac)
	var land := pick_point(band, margin, frac)
	var wet := pick_water_point(band, margin, frac)
	if wet.x < 0.0:
		return land
	if land.x < 0.0:
		return wet
	if rng.randf() < 0.35:
		return wet
	return land

func count_alive(type: String) -> int:
	var n := 0
	for e in entities:
		if e.type == type and e.state != "dying": n += 1
	return n

# ---------------------------------------------------------------- spawning
func spawn(type: String, band: String = "mid", opts: Dictionary = {}) -> Dictionary:
	var e := {"id": next_id, "type": type, "band": band, "age": 0.0, "timer": 0.0, "state": "", "flash": 0.0,
		"rise": 1.0, "alpha": 1.0, "vx": 0.0, "vy": 0.0, "muzzle": 0.0, "shots_left": 0, "kind": "", "variant": rng.randi() % 4,
		"facing": 1.0, "ground_y": 0.0, "fall_rot": 0.0, "escaped": false, "planted": false, "path": ""}
	var s := float(opts.get("scale", band_scale(band)))
	e.scale = s
	var size: Vector2 = SIZES.get(type, Vector2(100, 100))
	e.size = size
	e.max_hp = maxf(1.0, round(float(BASE_HP.get(type, 1.0)) * (float(diff.get("enemy_hp", 1.0)) if type in ENEMY_TYPES else 1.0)))
	e.hp = e.max_hp
	var p := Vector2(float(opts.get("world_x", -1)), float(opts.get("world_y", -1)))
	if type == "heli":
		e.scale = float(opts.get("scale", HELI_SCALE)); e.band = "sky"
		var from_right := rng.randf() < 0.6 if not opts.has("from") else str(opts.get("from")) == "right"
		e.sx = VIEW_W + 420.0 if from_right else -420.0
		e.vx = -260.0 if from_right else 260.0
		e.facing = -1.0 if from_right else 1.0
		e.hover_x = rng.randf_range(VIEW_W * 0.38, VIEW_W * 0.62)
		var wy := float(opts.get("world_y", -1.0))
		e.base_y = wy if wy > 0.0 else rng.randf_range(230.0, 320.0)
		e.y = e.base_y; e.x = camera_x + e.sx
		e.state = "fly"; e.hovered = false; e.timer = 0.0; e.gunner_alive = true
		e.gunner_hp = GUNNER_HP; e.burst = 0.0; e.tick = 0.0; e.crash_t = 0.0
		e.aim = 1.6 * float(diff.get("telegraph", 1.0)) + 0.6
	elif type in ["food", "powerup"]:
		if p.x < 0: p.x = camera_x + rng.randf_range(260.0, VIEW_W - 260.0)
		e.scale = 1.0; e.band = "sky"
		e.x = p.x; e.y = -80.0; e.ground_y = _pickup_land_y(p.x); e.vy = 105.0; e.state = "fall"
		e.kind = str(opts.get("kind", ""))
		if e.kind == "":
			var rule := _ambient_rule(type)
			e.kind = _weighted(rule.get("kinds", {"ammo": 1.0})) if not rule.is_empty() else ("rice" if type == "food" else "ammo")
	else:
		if p.x < 0:
			# Boats, jeeps and other path vehicles are placed on their road,
			# so they must not hop bands just because no land is in view
			# (the harbour has no mid sand, which used to shove the gunboat
			# onto the far water line).
			if Ground.road_for(type, band) != "":
				p = Vector2(camera_x + VIEW_W * 0.5, 1.0)
			elif type == "villager":
				p = pick_point(band, 140.0, float(opts.get("frac", -1.0)))
			elif type in WADING_TYPES:
				p = pick_combat_point(band, 140.0, float(opts.get("frac", -1.0)))
			else:
				p = pick_point(band, 140.0, float(opts.get("frac", -1.0)))
			if p.x < 0:
				for alt in ["mid", "far", "near"]:
					if type == "villager":
						p = pick_point(alt)
					elif type in WADING_TYPES:
						p = pick_combat_point(alt)
					else:
						p = pick_point(alt)
					if p.x >= 0:
						band = alt; e.band = alt; e.scale = band_scale(alt); break
			if p.x < 0:
				return {}
		e.planted = opts.has("world_y") and float(opts.get("world_y", -1.0)) > 0.0
		if not e.planted:
			# ground_y interpolates the polyline even past a band's land
			# spans, which used to plant harbour infantry on the sandbag
			# lip with only sea behind them. Prefer the waterline when wet.
			if Ground.water_under_or_behind(stage, band, p.x, type):
				var wy := Ground.water_y(stage, p.x, band)
				if wy > 0.0:
					p.y = wy
			else:
				var gy := Ground.ground_y(stage, band, p.x)
				if gy > 0.0:
					p.y = gy
		e.x = p.x; e.ground_y = p.y; e.y = p.y
		e.facing = -1.0 if e.x > camera_x + VIEW_W * 0.5 else 1.0
		match type:
			"rifleman":
				e.state = "rise"; e.rise = 0.0; e.shots_left = 2 + rng.randi() % 2
				if e.variant == 3:
					e.pose = "kneel"; e.size = Vector2(150, 250)
			"mg":
				e.state = "aim"; e.timer = 1.4 * float(diff.telegraph) + 0.6
			"paratrooper":
				e.state = "descend"; e.y = 650.0 * e.scale - 30.0 + rng.randf_range(0.0, 60.0); e.vy = 70.0 + 90.0 * e.scale
				e.timer = 1.2 + rng.randf() ; e.shots_left = 3
			"villager":
				e.state = "walk"; var dir := 1.0 if rng.randf() < 0.5 else -1.0
				e.vx = dir * rng.randf_range(42.0, 62.0) * e.scale; e.facing = dir
				e.kind = VILLAGER_KINDS[rng.randi() % VILLAGER_KINDS.size()]
			"truck", "convoy":
				e.state = "drive"; e.x = camera_x + VIEW_W + 320.0; e.vx = -70.0; e.facing = -1.0
				e.target_x = truck_stop_x(e); e.timer = 0.0
				if type == "convoy":
					e.gunner_alive = true; e.gunner_hp = GUNNER_HP; e.burst = 0.0; e.tick = 0.0; e.aim = 1.4
			"technical":
				e.state = "drive"; e.x = camera_x + VIEW_W + 360.0; e.vx = -150.0; e.facing = -1.0
				e.target_x = camera_x - 400.0
				e.gunner_alive = true; e.gunner_hp = GUNNER_HP; e.burst = 0.0; e.tick = 0.0; e.aim = 0.8
			"sniper":
				e.state = "aim"; e.timer = 2.2 * float(diff.telegraph) + 0.8
			"camel":
				e.state = "ride"
				var cdir := -1.0 if e.x > camera_x + VIEW_W * 0.5 else 1.0
				e.facing = cdir
				e.vx = cdir * rng.randf_range(95.0, 140.0) * e.scale
				e.shots_left = 1; e.timer = _aim_time(e) * 0.85
			"jeep":
				e.state = "drive"; e.x = camera_x + VIEW_W + 360.0; e.vx = -140.0; e.facing = -1.0
				e.target_x = camera_x - 400.0
				e.gunner_alive = true; e.gunner_hp = GUNNER_HP; e.burst = 0.0; e.tick = 0.0; e.aim = 0.8
			"speedboat":
				e.state = "ride"
				var sdir := -1.0 if e.x > camera_x + VIEW_W * 0.5 else 1.0
				e.facing = sdir
				e.vx = sdir * rng.randf_range(150.0, 210.0) * e.scale
				e.shots_left = 2; e.timer = _aim_time(e) * 0.7
				e.gunner_alive = true; e.gunner_hp = GUNNER_HP; e.burst = 0.0; e.tick = 0.0; e.aim = 0.9
			"pier_gunner":
				e.state = "aim"; e.timer = 2.0 * float(diff.telegraph) + 0.6
				e.pose = "kneel"
			"rusher":
				e.state = "charge"; e.rise = 1.0; e.timer = 0.15
				e.melee = false
			"grenadier":
				e.state = "aim"; e.timer = 1.4 * float(diff.telegraph) + 0.5
				e.pose = "kneel"
			"gunboat":
				e.state = "hold"; e.vx = 0.0; e.facing = -1.0
				e.gunner_alive = true; e.gunner_hp = GUNNER_HP; e.burst = 0.0; e.tick = 0.0
				e.aim = 1.2 * float(diff.get("telegraph", 1.0))
				e.gunner2_alive = true; e.gunner2_hp = GUNNER_HP
				e.burst2 = 0.0; e.tick2 = 0.0
				e.aim2 = 1.6 * float(diff.get("telegraph", 1.0))
		_place_on_path(e)
		if type == "grenadier":
			_place_on_pier(e)
		if type == "gunboat":
			var hold := camera_x + VIEW_W * GUNBOAT_HOLD
			var path_name := str(e.get("path", "water"))
			var b := Ground.road_bounds(stage, path_name)
			if b.x >= 0.0:
				e.x = clampf(hold, b.x + 80.0, b.y - 80.0)
			else:
				e.x = hold
			e.y = Ground.road_y(stage, path_name, e.x) if path_name != "" else e.y
			e.ground_y = e.y
			e.facing = -1.0
			e.vx = 0.0
	if type == "rifleman":
		e.skin = str(stage.get("soldier_prefix", ""))
	if type == "villager":
		var kinds: Array = stage.get("villager_kinds", VILLAGER_KINDS)
		if kinds.is_empty():
			kinds = VILLAGER_KINDS
		e.kind = str(opts.get("kind", kinds[rng.randi() % kinds.size()]))
	if opts.has("hp"):
		e.max_hp = maxf(1.0, float(opts.hp))
	e.hp = e.max_hp
	_apply_wading(e)
	next_id += 1
	entities.append(e)
	event.emit("spawn", {"entity": e})
	return e

## Where a truck parks: right of centre, inside its band's zones and never on
## top of a vehicle painted into the background ("truck_avoid" spans in the
## stage file), so the game truck does not stop beside the painted one.
func truck_stop_x(e: Dictionary) -> float:
	var half: float = e.size.x * e.scale * 0.5
	var lo := camera_x + half + 40.0
	var hi := camera_x + VIEW_W - half - 40.0
	var want := clampf(camera_x + VIEW_W * 0.62, lo, hi)
	var avoid: Array = stage.get("truck_avoid", [])
	var candidates := [want]
	for span in avoid:
		candidates.append(float(span[1]) + half + 30.0)
		candidates.append(float(span[0]) - half - 30.0)
	var best := want
	var best_d := INF
	for c in candidates:
		if c < lo or c > hi or not _in_zone(e.band, c) or _overlaps_avoid(c, half): continue
		var d := absf(c - want)
		if d < best_d: best_d = d; best = c
	return best

func _in_zone(band: String, x: float) -> bool:
	return Ground.on_ground(stage, band, x)

func _pickup_land_y(x: float) -> float:
	for band in ["near", "mid", "far"]:
		if Ground.on_ground(stage, band, x):
			return Ground.ground_y(stage, band, x)
	return PICKUP_GROUND_Y

## Put a vehicle or camel on its road / sand track, entering from the side
## they will travel from, and clamp any parking target onto that path.
func _place_on_path(e: Dictionary) -> void:
	var name := Ground.road_for(str(e.type), str(e.band))
	if name == "":
		return
	var b := Ground.road_bounds(stage, name)
	if b.x < 0.0:
		return
	e.path = name
	var off := 360.0 if e.type in ["technical", "jeep"] else (220.0 if e.type in ["camel", "speedboat"] else 320.0)
	if e.type == "gunboat":
		e.x = clampf(camera_x + VIEW_W * GUNBOAT_HOLD, b.x + 80.0, b.y - 80.0)
		e.facing = -1.0
	elif e.vx < 0.0:
		e.x = clampf(camera_x + VIEW_W + off, b.x, b.y)
		e.facing = -1.0
	else:
		e.x = clampf(camera_x - off, b.x, b.y)
		e.facing = 1.0
	e.y = Ground.road_y(stage, name, e.x)
	e.ground_y = e.y
	if e.type in ["truck", "convoy"]:
		e.target_x = clampf(float(e.get("target_x", e.x)), b.x, b.y)
	elif e.type in ["technical", "jeep"]:
		e.target_x = b.x - 40.0

func _place_on_pier(e: Dictionary) -> void:
	var b := Ground.road_bounds(stage, "pier")
	if b.x < 0.0:
		return
	e.path = "pier"
	if not e.get("planted", false) or float(e.get("x", -1.0)) < 0.0:
		var lo := maxf(b.x + 20.0, camera_x + 80.0)
		var hi := minf(b.y - 20.0, camera_x + VIEW_W - 80.0)
		if hi <= lo:
			lo = b.x + 20.0
			hi = b.y - 20.0
		e.x = rng.randf_range(lo, hi) if hi > lo else clampf(camera_x + VIEW_W * 0.55, b.x, b.y)
	else:
		e.x = clampf(float(e.x), b.x, b.y)
	e.y = Ground.road_y(stage, "pier", e.x)
	e.ground_y = e.y
	e.planted = true
	e.wading = false
	e.submerge = 0.0

func _follow_path(e: Dictionary, dt: float) -> void:
	e.x += e.vx * dt
	var name := str(e.get("path", ""))
	if name == "":
		return
	var b := Ground.road_bounds(stage, name)
	if b.x < 0.0:
		return
	e.x = clampf(e.x, b.x, b.y)
	e.y = Ground.road_y(stage, name, e.x)
	e.ground_y = e.y
	if absf(e.vx) > 1.0:
		e.facing = -1.0 if e.vx < 0.0 else 1.0

func _path_ended(e: Dictionary) -> bool:
	var name := str(e.get("path", ""))
	if name == "":
		return false
	var b := Ground.road_bounds(stage, name)
	if b.x < 0.0:
		return false
	if e.vx < 0.0 and e.x <= b.x + 2.0:
		return true
	if e.vx > 0.0 and e.x >= b.y - 2.0:
		return true
	return false

func _overlaps_avoid(x: float, half: float) -> bool:
	for span in stage.get("truck_avoid", []):
		if x + half > float(span[0]) and x - half < float(span[1]): return true
	return false

func _ambient_rule(type: String) -> Dictionary:
	for r in stage.get("ambient", []):
		if r.get("type", "") == type: return r
	return {}

func _spawn_from_wave(w: Dictionary) -> void:
	var opts := {}
	for k in ["world_x", "world_y", "scale", "kind", "frac", "from", "hp"]:
		if w.has(k): opts[k] = w[k]
	var typ := str(w.type)
	var caps := {"camel": 2, "technical": 1, "sniper": 2, "speedboat": 2, "jeep": 1, "pier_gunner": 2, "gunboat": 1, "rusher": 3, "grenadier": 2}
	if caps.has(typ) and count_alive(typ) >= int(caps[typ]):
		return
	spawn(typ, str(w.get("band", "mid")), opts)

func _update_spawns() -> void:
	var waves: Array = stage.get("waves", [])
	while wave_index < waves.size() and float(waves[wave_index].t) <= time:
		var w: Dictionary = waves[wave_index]
		var count := int(w.get("count", 1))
		for i in count:
			var copy := w.duplicate()
			copy.t = float(w.t) + i * float(w.get("interval", 0.5))
			if count > 1 and not copy.has("frac") and not copy.has("world_x"):
				copy.frac = (i + 0.5) / count * 0.9 + 0.05 + rng.randf_range(-0.04, 0.04)
			pending.append(copy)
		wave_index += 1
	var i := 0
	while i < pending.size():
		if float(pending[i].t) <= time:
			_spawn_from_wave(pending[i]); pending.remove_at(i)
		else:
			i += 1
	var rules: Array = stage.get("ambient", [])
	for r in rules.size():
		var rule: Dictionary = rules[r]
		if time >= ambient_next[r]:
			ambient_next[r] = time + _rand_every(rule)
			if time > float(rule.get("until", duration)): continue
			if count_alive(str(rule.type)) >= int(rule.get("max_alive", 4)): continue
			var band := _weighted(rule.get("bands", {"mid": 1.0}))
			spawn(str(rule.type), band)
	# Never leave the player stuck: the starter pistol never runs dry, and an
	# ammo drop is sent whenever the primary weapon is completely empty.
	if slot_empty(1) and reload_timer <= 0.0:
		var has_ammo := false
		for e in entities:
			if e.type == "powerup" and e.kind == "ammo" and e.state != "dying": has_ammo = true
		if not has_ammo:
			spawn("powerup", "sky", {"kind": "ammo"})

# ---------------------------------------------------------------- update
func has_arena() -> bool:
	var a: Dictionary = stage.get("arena", {})
	return not a.is_empty() and str(a.get("type", "")) != ""

func arena_boss_alive() -> bool:
	if arena_done:
		return false
	for e in entities:
		if e.type == "gunboat" and e.state != "dying":
			return true
	return false

func step(dt: float) -> void:
	if paused or state != "playing":
		return
	if has_arena() and not arena_done:
		time += dt
	else:
		time = minf(time + dt, duration)
	camera_x = camera_at(time)
	fire_cooldown = maxf(0.0, fire_cooldown - dt)
	rapid_timer = maxf(0.0, rapid_timer - dt)
	spread_timer = maxf(0.0, spread_timer - dt)
	special_cooldown = maxf(0.0, special_cooldown - dt)
	bloom = maxf(0.0, bloom - dt * 2.5)
	if reload_timer > 0.0:
		reload_timer -= dt
		if reload_timer <= 0.0:
			reload_timer = 0.0; _refill(slot)
			event.emit("reload_done", {"slot": slot})
	if special_reload > 0.0:
		special_reload -= dt
		if special_reload <= 0.0:
			special_reload = 0.0; _refill(2)
			event.emit("reload_done", {"slot": 2})
	_update_spawns()
	for e in entities.duplicate():
		_update_entity(e, dt)
	_update_grenades(dt)
	_update_enemy_nades(dt)
	_update_strike(dt)
	if arena_sink > 0.0:
		arena_sink = maxf(0.0, arena_sink - dt)
		if arena_sink <= 0.0 and state == "playing":
			arena_done = true
			_finish("cleared", "boss")
			return
	if state == "playing":
		if health <= 0.0:
			_finish("failed", "health")
		elif has_arena() and not arena_done:
			pass
		elif kills >= quota:
			_finish("cleared", "quota")
		elif time >= duration:
			_finish("cleared", "time")

func _finish(new_state: String, reason: String) -> void:
	if state != "playing":
		return
	state = new_state; end_reason = reason
	if new_state == "cleared":
		var acc := float(stats.hits) / maxf(1.0, float(stats.shots))
		# v0.3.3: round the time and accuracy terms each to a multiple of 10
		# so every campaign score stays legal for the online board.
		var time_pts := 10 * int(round(float(int(time_left())) * 2.5))
		clear_bonus = int(health) * 20 + time_pts + int(round(acc * 200.0)) * 10
		score += clear_bonus
	event.emit(new_state, {"reason": reason, "bonus": clear_bonus})

func _update_entity(e: Dictionary, dt: float) -> void:
	e.age += dt
	e.flash = maxf(0.0, e.flash - dt * 6.0)
	e.muzzle = maxf(0.0, e.muzzle - dt)
	if e.type == "heli" and e.state == "crash":
		_update_heli(e, dt); return
	if e.state == "dying":
		e.timer -= dt; e.fall_rot = minf(1.0, e.fall_rot + dt * 2.2)
		if e.type in ["food", "powerup"]: e.y -= 40.0 * dt
		e.alpha = clampf(e.timer / 0.5, 0.0, 1.0)
		if e.timer <= 0.0: entities.erase(e)
		return
	face_player(e)
	if e.type in WADING_TYPES:
		_apply_wading(e)
	# Left behind by the scrolling camera or walked off: remove quietly.
	if e.type == "heli":
		_update_heli(e, dt); return
	var half_w: float = e.size.x * e.scale * 0.5
	if e.type != "gunboat" and (e.x + half_w < camera_x - 60.0 or (e.type == "villager" and (e.x - half_w > camera_x + VIEW_W + 60.0))):
		entities.erase(e); return
	match e.type:
		"rifleman": _update_rifleman(e, dt)
		"paratrooper": _update_para(e, dt)
		"mg": _update_mg(e, dt)
		"sniper": _update_sniper(e, dt)
		"truck", "convoy": _update_truck(e, dt)
		"technical": _update_technical(e, dt)
		"camel": _update_camel(e, dt)
		"jeep": _update_jeep(e, dt)
		"speedboat": _update_speedboat(e, dt)
		"pier_gunner": _update_sniper(e, dt)
		"rusher": _update_rusher(e, dt)
		"grenadier": _update_grenadier(e, dt)
		"gunboat": _update_gunboat(e, dt)
		"villager": _update_villager(e, dt)
		"food", "powerup": _update_pickup(e, dt)

func _update_rusher(e: Dictionary, dt: float) -> void:
	e.rise = 1.0
	if e.get("melee", false):
		return
	if not e.has("target_x"):
		var land := pick_point("near", 80.0)
		if land.x < 0.0:
			land = pick_point("mid", 80.0)
		if land.x < 0.0:
			land = Vector2(camera_x + VIEW_W * 0.5, HUD_BAND_TOP - 80.0)
		e.target_x = land.x
		e.target_y = land.y
	var tx := float(e.target_x)
	var ty := float(e.target_y)
	var speed := 190.0 * float(e.scale)
	var dx := tx - float(e.x)
	var step := speed * dt
	if absf(dx) > 4.0:
		e.x += clampf(dx, -step, step)
	_apply_wading(e)
	if not e.get("wading", false):
		var gy := Ground.ground_y(stage, str(e.band), e.x)
		if gy > 0.0:
			# Move down toward the near band if the ground allows it.
			var want := minf(ty, HUD_BAND_TOP - 70.0)
			if gy > e.y and gy <= want + 40.0:
				e.y = minf(gy, e.y + step * 0.85)
			else:
				e.y = gy
			e.ground_y = e.y
			if e.y >= 820.0:
				e.band = "near"
				e.scale = band_scale("near")
	e.charge_t = float(e.get("charge_t", 0.0)) + dt
	var close := absf(float(e.x) - (camera_x + VIEW_W * 0.5)) < 400.0
	var on_screen: bool = (e.x + e.size.x * e.scale * 0.5 > camera_x - 40.0) and (e.x - e.size.x * e.scale * 0.5 < camera_x + VIEW_W + 40.0)
	if (e.y >= HUD_BAND_TOP - 110.0) or (str(e.band) == "near" and e.y >= 820.0 and close) or (e.get("wading", false) and close and e.age > 3.6) or (on_screen and float(e.charge_t) >= 2.2):
		e.melee = true
		damage_player(14.0, e)
		event.emit("rusher_melee", {"entity": e, "pos": Vector2(e.x - camera_x, e.y - 80.0)})
		e.state = "dying"
		e.timer = 0.45
		e.fall_rot = 0.0

func _update_grenadier(e: Dictionary, dt: float) -> void:
	if e.get("path", "") == "pier":
		var ry := Ground.road_y(stage, "pier", e.x)
		if ry > 0.0:
			e.y = ry
			e.ground_y = ry
	e.timer -= dt
	match e.state:
		"aim":
			if e.timer <= 0.0:
				_throw_enemy_nade(e)
				e.state = "recover"
				e.timer = 1.7 + rng.randf_range(0.0, 0.5)
		"recover":
			if e.timer <= 0.0:
				e.state = "aim"
				e.timer = _aim_time(e) * 1.15 + 0.4

func _throw_enemy_nade(e: Dictionary) -> void:
	var dest := fire_target(e, true)
	var hand := Vector2(e.x, e.y - e.size.y * e.scale * 0.62)
	enemy_nades.append({
		"from": hand, "to_screen": dest, "t": 0.0, "dur": 1.15,
		"hp": 1, "state": "fly", "arc": 200.0,
	})
	e.muzzle = 0.22
	event.emit("enemy_grenade", {"entity": e, "to": dest, "from": Vector2(hand.x - camera_x, hand.y)})

func nade_screen_pos(g: Dictionary) -> Vector2:
	var u := clampf(float(g.t) / maxf(0.05, float(g.dur)), 0.0, 1.0)
	var from_s := Vector2(float(g.from.x) - camera_x, float(g.from.y))
	var to_s: Vector2 = g.to_screen
	var p := from_s.lerp(to_s, u)
	p.y -= sin(u * PI) * float(g.get("arc", 200.0))
	return p

func nade_at(screen_pos: Vector2) -> Dictionary:
	for g in enemy_nades:
		if str(g.get("state", "")) != "fly":
			continue
		if nade_screen_pos(g).distance_to(screen_pos) <= 32.0:
			return g
	return {}

func _shoot_down_nade(g: Dictionary) -> void:
	g.state = "shot"
	g.t = float(g.dur)
	event.emit("nade_shot", {"pos": nade_screen_pos(g)})

func _update_enemy_nades(dt: float) -> void:
	for g in enemy_nades.duplicate():
		if str(g.get("state", "")) != "fly":
			enemy_nades.erase(g)
			continue
		g.t = float(g.t) + dt
		if float(g.t) >= float(g.dur):
			var dest: Vector2 = g.to_screen
			damage_player(16.0, g)
			event.emit("enemy_grenade_land", {"pos": dest})
			enemy_nades.erase(g)

func _aim_time(e: Dictionary) -> float:
	return float(AIM_TIME.get(e.band, 1.3)) * float(diff.get("telegraph", 1.0)) / float(diff.get("fire_rate", 1.0)) * rng.randf_range(0.85, 1.2)

func _update_rifleman(e: Dictionary, dt: float) -> void:
	match e.state:
		"rise":
			e.rise = minf(1.0, e.rise + dt / 0.35)
			if e.rise >= 1.0:
				e.state = "aim"; e.timer = _aim_time(e) + 0.1
		"aim":
			e.timer -= dt
			if e.timer <= 0.0:
				_enemy_fire(e, 1.0)
				e.shots_left -= 1
				e.state = "recover"; e.timer = 0.45
		"recover":
			e.timer -= dt
			if e.timer <= 0.0:
				if e.shots_left > 0:
					e.state = "aim"; e.timer = _aim_time(e)
				else:
					e.state = "duck"
		"duck":
			e.rise = maxf(0.0, e.rise - dt / 0.35)
			if e.rise <= 0.0:
				e.escaped = true; entities.erase(e)

func _update_para(e: Dictionary, dt: float) -> void:
	if e.state == "descend":
		var gy := Ground.ground_y(stage, e.band, e.x)
		if gy > 0.0:
			e.ground_y = gy
		e.y = minf(e.ground_y, e.y + e.vy * dt)
		e.x += sin(e.age * 0.9 + e.id) * 10.0 * e.scale * dt
		e.timer -= dt
		if e.timer <= 0.0:
			_enemy_fire(e, 0.7)
			e.timer = 2.4 * float(diff.get("telegraph", 1.0)) / float(diff.get("fire_rate", 1.0)) + rng.randf() * 0.8
		if e.y >= e.ground_y:
			e.state = "aim"; e.landed = true; e.landed_at = e.age; e.timer = _aim_time(e); e.shots_left = 2 + rng.randi() % 2
			event.emit("landed", {"entity": e})
	else:
		_update_rifleman(e, dt)

func _update_mg(e: Dictionary, dt: float) -> void:
	e.timer -= dt
	match e.state:
		"aim":
			if e.timer <= 0.0:
				e.state = "burst"; e.timer = 1.4; e.tick = 0.0
		"burst":
			e.tick = e.get("tick", 0.0) - dt
			if e.tick <= 0.0:
				e.tick = 0.12; _enemy_fire(e, 0.45, 2.0)
			if e.timer <= 0.0:
				e.state = "cool"; e.timer = 1.8 / float(diff.get("fire_rate", 1.0))
		"cool":
			if e.timer <= 0.0:
				e.state = "aim"; e.timer = 1.1 * float(diff.get("telegraph", 1.0))

func _update_truck(e: Dictionary, dt: float) -> void:
	if e.state == "drive":
		_follow_path(e, dt)
		if (e.vx <= 0.0 and e.x <= e.target_x) or (e.vx > 0.0 and e.x >= e.target_x):
			e.x = e.target_x
			if str(e.get("path", "")) != "":
				e.y = Ground.road_y(stage, e.path, e.x)
				e.ground_y = e.y
			e.state = "aim"; e.timer = 1.6
	else:
		_update_mg(e, dt)
	if e.type == "convoy":
		_update_vehicle_gunner(e, dt)

func _update_technical(e: Dictionary, dt: float) -> void:
	_follow_path(e, dt)
	_update_vehicle_gunner(e, dt)
	if _path_ended(e) or e.x < camera_x - 480.0:
		e.escaped = true; entities.erase(e)

func _update_jeep(e: Dictionary, dt: float) -> void:
	_follow_path(e, dt)
	_update_vehicle_gunner(e, dt)
	if _path_ended(e) or e.x < camera_x - 480.0:
		e.escaped = true; entities.erase(e)

func _update_speedboat(e: Dictionary, dt: float) -> void:
	_follow_path(e, dt)
	e.path_x = e.x
	var weave := sin(e.age * TAU / 2.8) * 110.0
	var name := str(e.get("path", ""))
	if name != "":
		var b := Ground.road_bounds(stage, name)
		e.x = clampf(e.path_x + weave, b.x, b.y)
	else:
		e.x = e.path_x + weave
	e.y = float(e.get("ground_y", e.y)) + sin(e.age * TAU / 1.6) * 8.0 * e.scale
	if e.get("gunner_alive", false):
		_update_vehicle_gunner(e, dt)
	elif e.state == "ride":
		e.timer -= dt
		if e.timer <= 0.0 and e.shots_left > 0:
			_enemy_fire(e, 1.0)
			e.shots_left -= 1
			e.timer = _aim_time(e)
	if _path_ended(e) or e.x + e.size.x * e.scale * 0.5 < camera_x - 80.0 or e.x - e.size.x * e.scale * 0.5 > camera_x + VIEW_W + 80.0:
		e.escaped = true; entities.erase(e)

func _update_gunboat(e: Dictionary, dt: float) -> void:
	var name := str(e.get("path", "water"))
	var hold := camera_x + VIEW_W * GUNBOAT_HOLD
	var weave := sin(e.age * TAU / 4.0) * 40.0
	var b := Ground.road_bounds(stage, name)
	e.x = hold + weave
	if b.x >= 0.0:
		e.x = clampf(e.x, b.x + 40.0, b.y - 40.0)
	e.facing = -1.0
	var gy := Ground.road_y(stage, name, e.x)
	if gy > 0.0:
		e.ground_y = gy
		e.y = gy + sin(e.age * 1.8) * 5.0 * e.scale
	_update_vehicle_gunner(e, dt)

func _update_vehicle_gunner(e: Dictionary, dt: float) -> void:
	_update_one_gunner(e, dt, "gunner_alive", "gunner_hp", "burst", "tick", "aim")
	if e.type == "gunboat":
		_update_one_gunner(e, dt, "gunner2_alive", "gunner2_hp", "burst2", "tick2", "aim2")

func _update_one_gunner(e: Dictionary, dt: float, alive_k: String, _hp_k: String, burst_k: String, tick_k: String, aim_k: String) -> void:
	if not e.get(alive_k, false):
		return
	var sx: float = e.x - camera_x
	if sx < 80.0 or sx > VIEW_W - 80.0:
		return
	if float(e.get(burst_k, 0.0)) > 0.0:
		e[burst_k] = float(e[burst_k]) - dt
		e[tick_k] = float(e.get(tick_k, 0.0)) - dt
		if float(e[tick_k]) <= 0.0:
			e[tick_k] = 0.14; _enemy_fire(e, 0.5, 2.2)
	else:
		e[aim_k] = float(e.get(aim_k, 1.0)) - dt
		if float(e[aim_k]) <= 0.0:
			e[burst_k] = 1.1; e[tick_k] = 0.0
			e[aim_k] = (2.0 + rng.randf()) * float(diff.get("telegraph", 1.0)) / float(diff.get("fire_rate", 1.0))

func _update_sniper(e: Dictionary, dt: float) -> void:
	e.timer -= dt
	match e.state:
		"aim":
			if e.timer <= 0.0:
				_enemy_fire(e, 1.15)
				e.state = "cool"; e.timer = 1.8 / float(diff.get("fire_rate", 1.0))
		"cool":
			if e.timer <= 0.0:
				e.state = "aim"; e.timer = 2.0 * float(diff.get("telegraph", 1.0))

func _update_camel(e: Dictionary, dt: float) -> void:
	_follow_path(e, dt)
	e.y = e.ground_y + sin(e.age * 6.0) * 3.0 * e.scale
	if e.state == "ride":
		e.timer -= dt
		if e.timer <= 0.0 and e.shots_left > 0:
			_enemy_fire(e, 1.0)
			e.shots_left -= 1
			e.state = "leave"
			var dir: float = e.facing if absf(e.facing) > 0.0 else (-1.0 if e.vx < 0.0 else 1.0)
			e.vx = dir * maxf(absf(e.vx) * 1.35, 150.0 * e.scale)
	var half: float = e.size.x * e.scale * 0.5
	if _path_ended(e) or e.x + half < camera_x - 80.0 or e.x - half > camera_x + VIEW_W + 80.0:
		e.escaped = true; entities.erase(e)

## Huey-style helicopter: flies in, hovers while the door gunner fires bursts,
## then leaves. Position is screen-relative (sx) so it stays with the camera.
func _update_heli(e: Dictionary, dt: float) -> void:
	if e.state == "crash":
		e.crash_t += dt
		e.sx += e.vx * 0.55 * dt
		e.vy += 520.0 * dt
		e.y += e.vy * dt
		e.x = camera_x + e.sx
		if e.y > 900.0 or e.crash_t > 2.2:
			event.emit("explosion", {"pos": Vector2(e.sx, minf(e.y, 900.0)), "radius": 320.0, "harmless": true, "big": true})
			entities.erase(e)
		return
	e.sx += e.vx * dt
	e.x = camera_x + e.sx
	e.y = e.base_y + sin(e.age * 1.7) * 14.0
	match e.state:
		"fly":
			if not e.hovered and ((e.vx < 0.0 and e.sx <= e.hover_x) or (e.vx > 0.0 and e.sx >= e.hover_x)):
				e.hovered = true; e.state = "hover"; e.timer = 7.0 + rng.randf() * 2.0
				e.speed = absf(e.vx); e.vx = 0.0
		"hover":
			e.timer -= dt
			if e.timer <= 0.0:
				e.state = "leave"; e.vx = e.facing * maxf(240.0, float(e.get("speed", 260.0)))
		"leave":
			if e.sx < -520.0 or e.sx > VIEW_W + 520.0:
				e.escaped = true; entities.erase(e); return
	# Door gunner: aims, then fires short bursts while on screen.
	if e.gunner_alive and e.sx > 80.0 and e.sx < VIEW_W - 80.0:
		if e.burst > 0.0:
			e.burst -= dt; e.tick -= dt
			if e.tick <= 0.0:
				e.tick = 0.14; _enemy_fire(e, 0.5, 2.5)
		else:
			e.aim -= dt
			if e.aim <= 0.0:
				e.burst = 1.2; e.tick = 0.0
				e.aim = (2.2 + rng.randf()) * float(diff.get("telegraph", 1.0)) / float(diff.get("fire_rate", 1.0))

## Door gunner hit area in screen space (the open doorway of the painted heli).
func gunner_rect(e: Dictionary) -> Rect2:
	var s: float = e.scale
	if e.type in ["technical", "convoy", "jeep", "speedboat", "gunboat"]:
		var w := 90.0 * s; var h := 90.0 * s
		if e.type == "gunboat":
			w = 110.0 * s; h = 90.0 * s
		var ox: float = (-e.size.x * s * 0.28) if e.facing < 0.0 else (e.size.x * s * 0.12)
		if e.type == "speedboat":
			ox = (e.size.x * s * 0.22) * (1.0 if e.facing > 0.0 else -1.0)
		if e.type == "gunboat":
			ox = (e.size.x * s * 0.32) * (1.0 if e.facing > 0.0 else -1.0)
		return Rect2(e.x - camera_x + ox - w * 0.5, e.y - h - 20.0 * s, w, h)
	var x0 := 20.0 * s; var x1 := 95.0 * s
	var r := Rect2(e.x - camera_x + (x0 if e.facing > 0 else -x1), e.y - 10.0 * s, x1 - x0, 105.0 * s)
	return r

## Second deck gunner, midships, used only on the harbour gunboat.
func gunner2_rect(e: Dictionary) -> Rect2:
	var s: float = e.scale
	var w := 100.0 * s; var h := 90.0 * s
	var ox: float = (e.size.x * s * -0.06) * (1.0 if e.facing > 0.0 else -1.0)
	return Rect2(e.x - camera_x + ox - w * 0.5, e.y - h - 16.0 * s, w, h)

func _update_villager(e: Dictionary, dt: float) -> void:
	var nx: float = e.x + e.vx * dt
	if not Ground.on_land(stage, e.band, nx):
		# Turn around at the water or the edge of the path; never step off land.
		e.vx = -e.vx
		nx = e.x + e.vx * dt
		if not Ground.on_land(stage, e.band, nx):
			e.alpha -= dt * 4.0
			if e.alpha <= 0.0: entities.erase(e)
			return
	e.x = nx
	if absf(e.vx) > 1.0:
		e.facing = -1.0 if e.vx < 0.0 else 1.0
	var gy := Ground.ground_y(stage, e.band, e.x)
	if gy > 0.0:
		e.y = gy
		e.ground_y = gy
	if not Ground.on_land(stage, e.band, e.x):
		e.alpha -= dt * 4.0
		if e.alpha <= 0.0: entities.erase(e)

func _update_pickup(e: Dictionary, dt: float) -> void:
	if e.state == "fall":
		e.y += e.vy * dt
		e.x += sin(e.age * 1.3 + e.id) * 18.0 * dt
		if e.y >= e.ground_y:
			e.y = e.ground_y; e.state = "landed"; e.timer = 3.5
	else:
		e.timer -= dt
		if e.timer < 1.0: e.alpha = clampf(e.timer, 0.0, 1.0)
		if e.timer <= 0.0: entities.erase(e)

func _enemy_fire(e: Dictionary, chance_mult: float, damage_override: float = -1.0) -> void:
	var info := band_info(e.band)
	if e.type in ["mg", "truck", "technical", "convoy", "sniper", "jeep", "speedboat", "pier_gunner", "gunboat"]:
		info = band_info("mid") if e.scale < 0.75 else band_info("near")
	elif e.type == "heli":
		info = band_info("mid")
	e.muzzle = 0.09
	var chance := float(info.get("hit_chance", 0.7)) * float(diff.get("accuracy", 0.4)) * chance_mult
	var hit := rng.randf() < chance
	event.emit("enemy_fire", {"entity": e, "hit": hit, "to": fire_target(e, hit), "side": fire_side(e)})
	if hit:
		var dmg := (damage_override if damage_override > 0.0 else float(info.get("damage", 5.0))) * float(diff.get("damage", 1.0))
		damage_player(dmg, e)

# ---------------------------------------------------------------- facing the player
## Ground enemies always turn toward the player, who stands behind the screen:
## a figure left of centre aims right/out, one right of centre aims left/out.
## Inside the dead zone near the centre the front pose already points straight
## at the camera, so the last facing is kept (no flicker while the camera scrolls).
const FACE_DEADZONE := 80.0
const FACING_TYPES := ["rifleman", "paratrooper", "mg", "sniper", "pier_gunner", "rusher", "grenadier"]

func face_player(e: Dictionary) -> void:
	if not (e.type in FACING_TYPES) or e.state == "dying": return
	var sx: float = e.x - camera_x
	if sx < VIEW_W * 0.5 - FACE_DEADZONE: e.facing = 1.0
	elif sx > VIEW_W * 0.5 + FACE_DEADZONE: e.facing = -1.0

## -1 = shot comes from the left of the screen, 0 = centre, 1 = right.
func fire_side(e: Dictionary) -> float:
	var sx: float = (e.sx if e.type == "heli" else e.x - camera_x)
	return clampf((sx - VIEW_W * 0.5) / (VIEW_W * 0.5), -1.0, 1.0)

## Screen point an enemy shot travels to. The player is behind the bottom of
## the screen: hits land at the lower screen edge on the shooter's side, misses
## kick up dirt in the near foreground. Always below and toward the player.
func fire_target(e: Dictionary, hit: bool) -> Vector2:
	var side := fire_side(e)
	# Land in the lower playfield, just above the bottom HUD, so tracers stay
	# visible and still travel down out of the screen toward the player.
	var y0 := HUD_BAND_TOP - 40.0
	var y1 := HUD_BAND_TOP - 8.0
	if hit:
		return Vector2(clampf(VIEW_W * 0.5 + side * VIEW_W * 0.32 + fx_rng.randf_range(-140.0, 140.0), 60.0, VIEW_W - 60.0),
			fx_rng.randf_range(y0, y1))
	return Vector2(clampf(VIEW_W * 0.5 + side * VIEW_W * 0.22 + fx_rng.randf_range(-320.0, 320.0), 40.0, VIEW_W - 40.0),
		fx_rng.randf_range(y0, y1))

func damage_player(amount: float, source = null) -> void:
	if state != "playing": return
	health = maxf(0.0, health - amount)
	stats.damage_taken += amount
	event.emit("player_hit", {"amount": amount, "source": source})

# ---------------------------------------------------------------- player
## Head region of a standing or kneeling person, in world space. Empty if
## this type has no head zone (vehicles, pickups).
func headbox(e: Dictionary) -> Rect2:
	if not (e.type in HEADSHOT_TYPES or e.type == "villager"):
		return Rect2()
	var box := hitbox(e)
	if box.size.y <= 1.0:
		return Rect2()
	var frac := 0.28
	if e.type == "mg":
		frac = 0.34
	elif str(e.get("pose", "")) == "kneel":
		frac = 0.32
	return Rect2(box.position, Vector2(box.size.x, box.size.y * frac))

func is_headshot(e: Dictionary, screen_pos: Vector2) -> bool:
	var box := headbox(e)
	if box.size.x <= 0.0:
		return false
	return box.has_point(screen_pos + Vector2(camera_x, 0.0))

func hitbox(e: Dictionary) -> Rect2:
	var w: float = e.size.x * e.scale
	var h: float = e.size.y * e.scale
	match e.type:
		"food", "powerup":
			return Rect2(e.x - w * 0.5, e.y - h * 0.5, w, h)
		"mg", "sniper", "pier_gunner", "grenadier":
			return Rect2(e.x - w * 0.4, e.y - h, w * 0.8, h * 0.62)
		"truck", "technical", "convoy", "jeep", "speedboat", "gunboat":
			return Rect2(e.x - w * 0.5, e.y - h, w, h * 0.92)
		"heli":
			# Centre-anchored; the fuselage, not the rotor disc or tail boom tip.
			return Rect2(e.x - w * 0.42, e.y - h * 0.22, w * 0.84, h * 0.6)
		_:
			if e.get("wading", false):
				var dry: float = 1.0 - float(e.get("submerge", WADING_SUBMERGE))
				return Rect2(e.x - w * 0.5, e.y - h * dry, w, h * dry)
			var drop: float = (1.0 - e.rise) * h
			return Rect2(e.x - w * 0.5, e.y - h + drop, w, h - drop)

func is_hittable(e: Dictionary) -> bool:
	if e.state == "dying" or e.state == "crash": return false
	if e.type == "rifleman" and e.rise < 0.25: return false
	return true

## Finds the entity under a screen point. Falling pickups are checked first,
## then the nearest depth band (drawn on top) before farther ones.
func entity_at(screen_pos: Vector2, skip: Array = []) -> Dictionary:
	var world := screen_pos + Vector2(camera_x, 0.0)
	var best := {}
	var best_key := -INF
	for e in entities:
		if not is_hittable(e) or skip.has(e): continue
		if not hitbox(e).has_point(world): continue
		var key: float = e.scale * 10.0 + e.y * 0.001
		if e.type in ["food", "powerup"]: key += 100.0
		if key > best_key:
			best_key = key; best = e
	return best

func can_fire() -> bool:
	return state == "playing" and not paused and reload_timer <= 0.0 and fire_cooldown <= 0.0 and loadout.size() == Weapons.SLOT_COUNT

## Fires the selected weapon at a screen position. Returns true if a round
## was used. With the special slot selected the trigger fires the special.
func fire(screen_pos: Vector2) -> bool:
	if slot == 2: return fire_special(screen_pos)
	if not can_fire(): return false
	var w := weapon()
	if ammo <= 0:
		if int(loadout[slot].reserve) != 0:
			reload()
		else:
			fire_cooldown = 0.25
			event.emit("empty", {"slot": slot, "weapon": str(w.get("id", ""))})
			# Out of everything on the primary: fall back to the pistol.
			if slot == 1 and not slot_empty(0): select_slot(0)
		return false
	ammo -= 1
	fire_cooldown = fire_interval()
	stats.shots += 1
	var aim := screen_pos + spread_offset(w)
	bloom = minf(1.0, bloom + 0.18)
	var points := [aim]
	if spread_timer > 0.0:
		points = [aim + Vector2(-46, 10), aim, aim + Vector2(46, 10)]
	var any_hit := false
	for p in points:
		if shoot_point(p, int(w.get("pierce", 1))): any_hit = true
	if any_hit: stats.hits += 1
	event.emit("shot", {"pos": aim, "aim": screen_pos, "points": points, "hit": any_hit, "weapon": str(w.get("id", "")), "slot": slot})
	if ammo == 0 and int(loadout[slot].reserve) != 0:
		reload()
	return true

## Random aim offset: a quarter of the weapon's spread for a first shot,
## growing to the full spread while the trigger is held.
func spread_offset(w: Dictionary) -> Vector2:
	var sp := float(w.get("spread", 0.0)) * (0.25 + 0.75 * bloom)
	if sp <= 0.0: return Vector2.ZERO
	return Vector2.from_angle(rng.randf() * TAU) * sp * sqrt(rng.randf())

## Applies one bullet at a screen point. A piercing round (marksman rifle)
## passes through up to `pierce` targets, nearest first. Returns true on a hit.
func shoot_point(screen_pos: Vector2, pierce: int = 1) -> bool:
	var nade := nade_at(screen_pos)
	if not nade.is_empty():
		_shoot_down_nade(nade)
		return true
	var e := entity_at(screen_pos)
	if e.is_empty():
		event.emit("miss", {"pos": screen_pos})
		return false
	damage_entity(e, shot_damage(), screen_pos)
	if pierce > 1 and e.type != "villager":
		var done := [e]
		for i in pierce - 1:
			var nxt := entity_at(screen_pos, done)
			if nxt.is_empty() or nxt.type in ["food", "powerup"]: break
			done.append(nxt)
			damage_entity(nxt, shot_damage(), screen_pos)
			event.emit("pierce", {"entity": nxt, "pos": screen_pos})
	return true

func damage_entity(e: Dictionary, amount: float, screen_pos: Vector2, blast: bool = false) -> void:
	if not is_hittable(e): return
	e.flash = 1.0
	# A bullet in the doorway hits only the door gunner; a blast hits him and the hull.
	if e.get("gunner_alive", false) and e.type in ["heli", "technical", "convoy", "jeep", "speedboat", "gunboat"] and (blast or gunner_rect(e).grow(2.0).has_point(screen_pos)):
		e.gunner_hp -= amount
		event.emit("hit", {"entity": e, "pos": screen_pos, "gunner": true})
		if e.gunner_hp <= 0.0:
			e.gunner_alive = false; e.burst = 0.0
			_add_score(int(GUNNER_SCORE * float(band_info("mid").get("score_mult", 1.0))), screen_pos)
			add_cash(int(Weapons.economy().get("gunner_cash", 0)), screen_pos, "gunner")
			event.emit("gunner_down", {"entity": e, "pos": screen_pos})
		if not blast: return
	if e.get("gunner2_alive", false) and e.type == "gunboat" and (blast or gunner2_rect(e).grow(2.0).has_point(screen_pos)):
		e.gunner2_hp -= amount
		event.emit("hit", {"entity": e, "pos": screen_pos, "gunner": true})
		if e.gunner2_hp <= 0.0:
			e.gunner2_alive = false; e.burst2 = 0.0
			_add_score(int(GUNNER_SCORE * float(band_info("mid").get("score_mult", 1.0))), screen_pos)
			add_cash(int(Weapons.economy().get("gunner_cash", 0)), screen_pos, "gunner")
			event.emit("gunner_down", {"entity": e, "pos": screen_pos, "which": 2})
		if not blast: return
	e.hp -= amount
	event.emit("hit", {"entity": e, "pos": screen_pos})
	if e.type == "heli":
		if e.hp <= e.max_hp * 0.5 and not e.get("smoking", false):
			e.smoking = true; event.emit("heli_smoking", {"entity": e})
		if e.hp > 0.0: return
		e.state = "crash"; e.gunner_alive = false; e.crash_t = 0.0
		e.vy = 40.0; e.vx = e.facing * 220.0
		kills += 1
		_add_score(int(BASE_SCORE.heli), screen_pos)
		add_cash(cash_for(e), screen_pos, "kill")
		event.emit("kill", {"entity": e, "pos": screen_pos})
		event.emit("heli_down", {"entity": e, "pos": screen_pos})
		return
	if e.hp > 0.0: return
	e.state = "dying"; e.timer = 0.7
	match e.type:
		"villager":
			stats.villagers_hit += 1
			score = maxi(0, score - VILLAGER_PENALTY_SCORE)
			lose_cash(int(Weapons.economy().get("civilian_penalty", 0)), screen_pos, "civilian")
			event.emit("villager_hit", {"entity": e, "pos": screen_pos, "count": int(stats.villagers_hit), "limit": CIVILIAN_LIMIT})
			damage_player(VILLAGER_PENALTY_HEALTH, e)
			if int(stats.villagers_hit) >= CIVILIAN_LIMIT:
				_finish("failed", "civilians")
		"food":
			stats.food += 1
			health = minf(max_health, health + float(FOOD_HEAL.get(e.kind, 10.0)))
			_add_score(int(BASE_SCORE.food), screen_pos)
			event.emit("pickup", {"entity": e, "kind": e.kind, "pos": screen_pos})
		"powerup":
			stats.powerups += 1
			if str(e.kind).begins_with("cash"): stats.cash_drops += 1
			apply_powerup(str(e.kind), screen_pos)
			_add_score(int(BASE_SCORE.powerup), screen_pos)
			event.emit("pickup", {"entity": e, "kind": e.kind, "pos": screen_pos})
		_:
			kills += 1
			var mult := float(band_info(e.band).get("score_mult", 1.0))
			var pts := float(BASE_SCORE.get(e.type, 100))
			if e.type == "paratrooper" and not e.get("landed", false): pts += 100.0
			var award := int(pts * mult)
			var head := is_headshot(e, screen_pos)
			if head and (e.type in HEADSHOT_TYPES):
				award += HEADSHOT_BONUS
				event.emit("headshot", {"entity": e, "pos": screen_pos, "bonus": HEADSHOT_BONUS})
			_add_score(award, screen_pos)
			add_cash(cash_for(e), screen_pos, "kill")
			event.emit("kill", {"entity": e, "pos": screen_pos, "headshot": head})
			if e.type in ["truck", "mg", "technical", "convoy", "sniper", "jeep", "speedboat", "pier_gunner", "gunboat"]:
				event.emit("explosion", {"pos": Vector2(e.x - camera_x, e.y - e.size.y * e.scale * 0.4), "radius": 160.0 * e.scale + 60.0, "harmless": true})
			if e.type == "gunboat":
				arena_sink = 1.5
				event.emit("gunboat_down", {"entity": e, "pos": screen_pos})

func _add_score(pts: int, pos: Vector2) -> void:
	score += pts
	event.emit("score", {"amount": pts, "pos": pos})

## Ammo drops refill the selected gun (the primary when the unlimited pistol
## or the special is selected); grenade drops refill the special slot.
func ammo_drop_slot(kind: String) -> int:
	if kind == "grenade": return 2
	if slot == 2 or Weapons.is_infinite(str(loadout[slot].id)): return 1
	return slot

func apply_powerup(kind: String, pos: Vector2 = Vector2.ZERO) -> void:
	match kind:
		"ammo", "grenade":
			var i := ammo_drop_slot(kind)
			var w := weapon_in(i)
			if int(loadout[i].reserve) >= 0:
				var cap := int(w.get("max_reserve", -1))
				var add := int(w.get("drop_mags", 2)) * int(w.get("mag", 1))
				loadout[i].reserve = mini(int(loadout[i].reserve) + add, cap if cap >= 0 else 1 << 30)
				if i == 2 and int(loadout[2].mag) == 0 and special_reload <= 0.0: _start_special_reload()
		"rapid": rapid_timer = POWER_TIMER
		"spread": spread_timer = POWER_TIMER
		"power": weapon_level = mini(3, weapon_level + 1)
		"airstrike": airstrikes += 1
		"cash", "cash_small": add_cash(int(Weapons.economy().get("cash_drop", {}).get("small", 150)), pos, "drop")
		"cash_large": add_cash(int(Weapons.economy().get("cash_drop", {}).get("large", 400)), pos, "drop")

## Moves rounds from reserve into the magazine of slot i.
func _refill(i: int) -> void:
	var e: Dictionary = loadout[i]
	var size := int(weapon_in(i).get("mag", 0))
	var need := size - int(e.mag)
	if need <= 0: return
	if int(e.reserve) < 0:
		e.mag = size
	else:
		var take := mini(need, int(e.reserve))
		e.mag = int(e.mag) + take; e.reserve = int(e.reserve) - take

func reload() -> bool:
	if slot == 2: return _start_special_reload()
	if state != "playing" or paused or reload_timer > 0.0 or int(loadout[slot].reserve) == 0 or ammo >= mag_size():
		return false
	reload_duration = maxf(0.05, float(weapon().get("reload", 1.0)))
	reload_timer = reload_duration
	event.emit("reload_start", {"slot": slot, "weapon": str(loadout[slot].id)})
	return true

func _start_special_reload() -> bool:
	if special_reload > 0.0 or int(loadout[2].reserve) == 0 or int(loadout[2].mag) >= int(weapon_in(2).get("mag", 1)): return false
	var t := float(weapon_in(2).get("reload", 0.0))
	if t <= 0.0:
		_refill(2); return true
	special_reload = t
	event.emit("reload_start", {"slot": 2, "weapon": str(loadout[2].id)})
	return true

## Fires the special weapon (frag grenade, rocket or launcher grenade) at the
## aim point. Space / right click always do this, whichever slot is selected.
func fire_special(screen_pos: Vector2) -> bool:
	if state != "playing" or paused or loadout.size() < 3: return false
	if special_cooldown > 0.0 or special_reload > 0.0: return false
	var w := weapon_in(2)
	if int(loadout[2].mag) <= 0:
		if not _start_special_reload():
			special_cooldown = 0.25
			event.emit("empty", {"slot": 2, "weapon": str(w.get("id", ""))})
		return false
	loadout[2].mag = int(loadout[2].mag) - 1
	special_cooldown = 1.0 / maxf(0.1, float(w.get("fire_rate", 1.0)))
	grenades_in_flight.append({"to": screen_pos + Vector2(camera_x, 0.0), "t": 0.0, "dur": float(w.get("flight", 0.55)),
		"radius": float(w.get("radius", GRENADE_RADIUS)), "damage": float(w.get("blast_damage", GRENADE_DAMAGE)),
		"weapon": str(w.id), "kind": str(w.get("kind", "thrown"))})
	event.emit("grenade_throw", {"pos": screen_pos, "weapon": str(w.id), "kind": str(w.get("kind", "thrown"))})
	if int(loadout[2].mag) == 0: _start_special_reload()
	return true

func throw_grenade(screen_pos: Vector2) -> bool:
	return fire_special(screen_pos)

func _update_grenades(dt: float) -> void:
	for g in grenades_in_flight.duplicate():
		g.t += dt
		if g.t >= g.dur:
			grenades_in_flight.erase(g)
			explode(g.to - Vector2(camera_x, 0.0), float(g.get("radius", GRENADE_RADIUS)), float(g.get("damage", GRENADE_DAMAGE)), str(g.get("weapon", "frag_grenades")))

## Grenade blast at a screen point: damages everything inside the radius,
## including villagers (with the usual penalty). Pickups are not affected.
func explode(screen_pos: Vector2, radius: float = GRENADE_RADIUS, damage: float = GRENADE_DAMAGE, source: String = "frag_grenades") -> int:
	var world := screen_pos + Vector2(camera_x, 0.0)
	var hit := 0
	event.emit("explosion", {"pos": screen_pos, "radius": radius, "weapon": source})
	for e in entities.duplicate():
		if not is_hittable(e) or e.type in ["food", "powerup"]: continue
		var r := hitbox(e)
		var closest := Vector2(clampf(world.x, r.position.x, r.end.x), clampf(world.y, r.position.y, r.end.y))
		if closest.distance_to(world) <= radius:
			damage_entity(e, damage, closest - Vector2(camera_x, 0.0), true); hit += 1
	return hit

## Calls an air strike: jets cross the screen and, AIRSTRIKE_IMPACT seconds
## later, every enemy, vehicle and helicopter on screen is destroyed.
## Civilians (and drops) are never harmed.
func call_airstrike() -> bool:
	if state != "playing" or paused or airstrikes <= 0 or not strike.is_empty(): return false
	airstrikes -= 1
	strike = {"t": 0.0, "hit": false, "targets": []}
	event.emit("airstrike", {})
	return true

func _update_strike(dt: float) -> void:
	if strike.is_empty(): return
	strike.t += dt
	if not strike.hit and strike.t >= AIRSTRIKE_IMPACT:
		strike.hit = true
		strike.targets = airstrike_impact()
	if strike.t >= AIRSTRIKE_DURATION:
		strike = {}

## Destroys every enemy on screen. Returns the screen points that were hit.
func airstrike_impact() -> Array:
	var points := []
	for e in entities.duplicate():
		if not (e.type in ENEMY_TYPES): continue
		if e.type in ["rifleman", "paratrooper"] and e.state != "dying" and e.rise < 0.25: e.rise = 0.25
		if not is_hittable(e): continue
		var r := hitbox(e)
		var c := r.get_center() - Vector2(camera_x, 0.0)
		if c.x < -40.0 or c.x > VIEW_W + 40.0: continue
		if e.get("gunner_alive", false) and e.type in ["heli", "technical", "convoy", "jeep", "speedboat", "gunboat"]:
			e.gunner_alive = false
		damage_entity(e, 999.0, c)
		points.append(c)
	# A carpet of bombs along the ground so the strike reads even on an empty screen.
	for i in 6:
		points.append(Vector2(160.0 + i * 320.0 + rng.randf_range(-60.0, 60.0), rng.randf_range(640.0, 980.0)))
	event.emit("airstrike_impact", {"points": points})
	return points

# ---------------------------------------------------------------- QA helpers
## Jumps the timeline forward (used by QA captures). Skipped waves are not spawned.
func skip_to(t: float) -> void:
	time = clampf(t, 0.0, duration)
	camera_x = camera_at(time)
	var waves: Array = stage.get("waves", [])
	while wave_index < waves.size() and float(waves[wave_index].t) < time:
		wave_index += 1
	for r in ambient_next.size():
		ambient_next[r] = maxf(ambient_next[r], time)

## 0..1 while a timed dust beat is active (on top of the standing heat shimmer).
func dust_amount() -> float:
	var d: Dictionary = stage.get("dust", {})
	if d.is_empty():
		return 0.0
	var a := float(d.get("from", 0.0))
	var b := float(d.get("until", 0.0))
	if time < a or time > b:
		return 0.0
	var fade := 1.6
	var u := minf(time - a, b - time)
	return clampf(u / fade, 0.0, 1.0)

## Keep a wading figure waist-deep on the waterline, or clear the flag on land.
func _apply_wading(e: Dictionary) -> void:
	if not (e.type in WADING_TYPES):
		e.wading = false
		return
	if e.state in ["descend", "crash"]:
		e.wading = false
		return
	var wet := Ground.water_under_or_behind(stage, str(e.get("band", "mid")), float(e.x), str(e.type))
	e.wading = wet
	if not wet:
		e.submerge = 0.0
		return
	var wy := Ground.water_y(stage, float(e.x), str(e.get("band", "mid")))
	if wy > 0.0:
		e.ground_y = wy
		e.y = wy + sin(float(e.get("age", 0.0)) * 2.4) * 3.0 * float(e.scale)
	e.submerge = WADING_SUBMERGE
	e.rise = 1.0
	if str(e.get("pose", "")) == "kneel":
		e.pose = ""
		e.size = SIZES.get("rifleman", e.size)
	if e.type == "rifleman" and e.state == "rise":
		e.state = "aim"
		e.timer = _aim_time(e)

