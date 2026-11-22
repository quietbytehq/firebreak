extends RefCounted
## Loads campaign and stage definitions from data/ and computes the
## per-stage difficulty multipliers. Pure data: no nodes, safe for tests.

const CAMPAIGN_PATH := "res://data/campaign.json"
const STAGE_COUNT := 12
const KNOWN_TYPES := ["rifleman", "mg", "paratrooper", "villager", "food", "powerup", "truck", "heli", "camel", "technical", "sniper", "convoy"]
const BANDS := ["far", "mid", "near"]

static func load_json(path: String) -> Variant:
	if path == "" or not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	return parsed

static func campaign() -> Dictionary:
	var c = load_json(CAMPAIGN_PATH)
	return c if c is Dictionary else {}

static func stage_entry(number: int) -> Dictionary:
	for s in campaign().get("stages", []):
		if int(s.get("number", 0)) == number:
			return s
	return {}

static func load_stage(number: int) -> Dictionary:
	var entry := stage_entry(number)
	if entry.is_empty() or not entry.get("playable", false):
		return {}
	var d = load_json(str(entry.get("file", "")))
	if not (d is Dictionary):
		return {}
	var waves: Array = d.get("waves", [])
	waves.sort_custom(func(a, b): return float(a.get("t", 0.0)) < float(b.get("t", 0.0)))
	d["waves"] = waves
	return d

## Difficulty multipliers for a stage number (1..12). Values rise with the stage.
static func difficulty(number: int) -> Dictionary:
	var curve: Dictionary = campaign().get("difficulty", {})
	var n := float(clampi(number, 1, STAGE_COUNT) - 1)
	var out := {}
	for key in curve:
		var c: Dictionary = curve[key]
		if c.has("shrink"):
			out[key] = maxf(float(c.get("min", 0.3)), float(c.get("base", 1.0)) / (1.0 + float(c["shrink"]) * n))
		else:
			var v := float(c.get("base", 1.0)) * (1.0 + float(c.get("growth", 0.0)) * n)
			if c.has("max"):
				v = minf(v, float(c["max"]))
			out[key] = v
	for key in ["accuracy", "damage", "density", "fire_rate", "enemy_hp", "quota", "telegraph"]:
		if not out.has(key):
			out[key] = 1.0
	return out


## First playable stage after `after` (1-based). 0 if none remain.
static func next_playable(after: int) -> int:
	for s in campaign().get("stages", []):
		if int(s.get("number", 0)) > after and bool(s.get("playable", false)):
			return int(s["number"])
	return 0

## Validates a stage dictionary; returns a list of problems (empty = valid).
static func validate(d: Dictionary) -> Array:
	var problems := []
	if d.is_empty():
		return ["empty stage"]
	if float(d.get("duration", 999)) > 180.0:
		problems.append("duration over 180 s")
	var bands: Dictionary = d.get("bands", {})
	for b in BANDS:
		if not bands.has(b):
			problems.append("missing band " + b)
		elif (bands[b].get("zones", []) as Array).is_empty():
			problems.append("band without zones " + b)
	var last := -1.0
	for w in d.get("waves", []):
		if not (str(w.get("type", "")) in KNOWN_TYPES):
			problems.append("unknown wave type " + str(w.get("type", "")))
		if float(w.get("t", -1)) < last:
			problems.append("waves not sorted")
		last = float(w.get("t", -1))
		if float(w.get("t", 0)) > float(d.get("duration", 180)):
			problems.append("wave after stage end")
		if w.has("band") and not (str(w["band"]) in BANDS or str(w["band"]) == "sky"):
			problems.append("bad band " + str(w["band"]))
	var prev_t := -1.0
	var prev_x := -1.0
	var max_x := float(d.get("world_width", 1920)) - 1920.0
	for k in d.get("scroll", []):
		if float(k[0]) < prev_t or float(k[1]) < prev_x:
			problems.append("scroll keyframes must not go backwards")
		if float(k[1]) > max_x + 0.01:
			problems.append("scroll beyond panorama")
		prev_t = float(k[0]); prev_x = float(k[1])
	return problems
