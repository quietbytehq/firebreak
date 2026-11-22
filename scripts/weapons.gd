extends RefCounted
## Weapon catalogue (data/weapons.json), the player's saved profile (cash,
## owned weapons, loadout, ammo) and the store rules. Pure data and static
## functions, so the headless tests drive exactly what the game uses.
## All weapon names and art are original; none refer to a real maker or model.

const DATA_PATH := "res://data/weapons.json"
const PROFILE_PATH := "user://profile.json"
const PROFILE_VERSION := 1
const SLOT_COUNT := 3

static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.get_file_as_string(DATA_PATH)
		var parsed = JSON.parse_string(f)
		_data = parsed if parsed is Dictionary else {}
	return _data

static func all() -> Array:
	return data().get("weapons", [])

static func ids() -> Array:
	return all().map(func(w): return str(w.id))

static func get_weapon(id: String) -> Dictionary:
	for w in all():
		if str(w.id) == id: return w
	return {}

static func in_category(cat: String) -> Array:
	return all().filter(func(w): return str(w.category) == cat)

static func categories() -> Array:
	return data().get("categories", [])

static func economy() -> Dictionary:
	return data().get("economy", {})

static func support(id: String = "air_strike") -> Dictionary:
	for s in data().get("support", []):
		if str(s.id) == id: return s
	return {}

static func starter() -> Dictionary:
	return data().get("starter", {})

## Slot index (0-based) a weapon goes into.
static func slot_of(id: String) -> int:
	return int(get_weapon(id).get("slot", 1)) - 1

static func is_infinite(id: String) -> bool:
	return int(get_weapon(id).get("reserve", 0)) < 0

## Field issue: what a weapon is topped up to at the start of every stage.
static func issue_reserve(w: Dictionary) -> int:
	if int(w.get("reserve", 0)) < 0: return -1
	return mini(int(w.get("issue_mags", 0)) * int(w.mag), _max_reserve(w))

static func _max_reserve(w: Dictionary) -> int:
	var m := int(w.get("max_reserve", -1))
	return m if m >= 0 else 1 << 30

static func fresh_ammo(id: String) -> Dictionary:
	var w := get_weapon(id)
	return {"mag": int(w.get("mag", 0)), "reserve": int(w.get("reserve", 0))}

# ------------------------------------------------------------------ profile
static func default_profile() -> Dictionary:
	var s := starter()
	var p := {"version": PROFILE_VERSION, "cash": int(s.get("cash", 0)), "owned": [], "loadout": [], "ammo": {},
		"airstrikes": int(support().get("issue", 1)), "earned_total": 0, "stages_cleared": 0}
	for k in ["slot1", "slot2", "slot3"]:
		var id := str(s.get(k, ""))
		p.owned.append(id); p.loadout.append(id); p.ammo[id] = fresh_ammo(id)
	return p

## Repairs a loaded profile so it always has a valid weapon in every slot.
static func sanitize(p: Dictionary) -> Dictionary:
	var d := default_profile()
	var out := d.duplicate(true)
	out.cash = maxi(0, int(p.get("cash", d.cash)))
	out.earned_total = int(p.get("earned_total", 0))
	out.stages_cleared = int(p.get("stages_cleared", 0))
	out.airstrikes = clampi(int(p.get("airstrikes", d.airstrikes)), 0, int(support().get("max", 3)))
	for id in p.get("owned", []):
		if not get_weapon(str(id)).is_empty() and not out.owned.has(str(id)): out.owned.append(str(id))
	var lo: Array = p.get("loadout", [])
	for i in SLOT_COUNT:
		if i < lo.size():
			var id := str(lo[i])
			if out.owned.has(id) and slot_of(id) == i: out.loadout[i] = id
	var ammo: Dictionary = p.get("ammo", {})
	for id in out.owned:
		var w := get_weapon(id)
		var a: Dictionary = ammo.get(id, fresh_ammo(id))
		var mag := clampi(int(a.get("mag", w.mag)), 0, int(w.mag))
		var res := -1 if is_infinite(id) else clampi(int(a.get("reserve", 0)), 0, _max_reserve(w))
		out.ammo[id] = {"mag": mag, "reserve": res}
	return out

static func load_profile(path: String = PROFILE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path): return default_profile()
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return sanitize(parsed if parsed is Dictionary else {})

static func save_profile(p: Dictionary, path: String = PROFILE_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(p, " ")); f.close()
	return true

static func reset_profile() -> Dictionary:
	var p := default_profile(); save_profile(p); return p

# ------------------------------------------------------------------ store
## Returns "" when allowed, otherwise the reason shown in the store.
static func can_buy(p: Dictionary, id: String) -> String:
	var w := get_weapon(id)
	if w.is_empty(): return "Unknown item"
	if p.owned.has(id): return "Owned"
	if int(p.cash) < int(w.price): return "Not enough cash"
	return ""

## Buys a weapon and equips it in its slot. Returns true on success.
static func buy(p: Dictionary, id: String) -> bool:
	if can_buy(p, id) != "": return false
	var w := get_weapon(id)
	p.cash = int(p.cash) - int(w.price)
	p.owned.append(id)
	var a := fresh_ammo(id)
	if not is_infinite(id): a.reserve = maxi(int(a.reserve), issue_reserve(w))
	p.ammo[id] = a
	equip(p, id)
	return true

static func equip(p: Dictionary, id: String) -> bool:
	if not p.owned.has(id): return false
	p.loadout[slot_of(id)] = id
	return true

static func ammo_full(p: Dictionary, id: String) -> bool:
	var w := get_weapon(id)
	if is_infinite(id): return true
	var a: Dictionary = p.ammo.get(id, {})
	return int(a.get("reserve", 0)) >= _max_reserve(w)

static func can_buy_ammo(p: Dictionary, id: String) -> String:
	var w := get_weapon(id)
	if w.is_empty() or not p.owned.has(id): return "Not owned"
	if is_infinite(id): return "Unlimited"
	if ammo_full(p, id): return "Full"
	if int(p.cash) < int(w.ammo_price): return "Not enough cash"
	return ""

static func buy_ammo(p: Dictionary, id: String) -> bool:
	if can_buy_ammo(p, id) != "": return false
	var w := get_weapon(id)
	p.cash = int(p.cash) - int(w.ammo_price)
	var a: Dictionary = p.ammo[id]
	a.reserve = mini(int(a.reserve) + int(w.ammo_pack), _max_reserve(w))
	return true

static func can_buy_airstrike(p: Dictionary) -> String:
	var s := support()
	if int(p.airstrikes) >= int(s.get("max", 3)): return "Full"
	if int(p.cash) < int(s.get("price", 0)): return "Not enough cash"
	return ""

static func buy_airstrike(p: Dictionary) -> bool:
	if can_buy_airstrike(p) != "": return false
	p.cash = int(p.cash) - int(support().price)
	p.airstrikes = int(p.airstrikes) + 1
	return true
