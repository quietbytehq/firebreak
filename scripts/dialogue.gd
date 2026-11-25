extends RefCounted
## On-screen radio and Rayan lines. Text only: never blocks play, never
## uses voice, and never sits on the score / civilian banners at y=280.

const PATH := "res://data/dialogue.json"
const LINE_LIFE := 3.4
const CHATTER_EVERY := 22.0
## Radio plate sits under the top HUD, left of the stage title, and above the y=280 banners.
## Width stays left of the longest title ("River Village" at 86px + outline).
const PLATE := Rect2(36, 118, 620, 88)

var data: Dictionary = {}
var current: Dictionary = {}
var queue: Array = []
var stage_number := 1
var chatter_in := 7.0
var story_index := 0
var said_low_health := false
var said_low_ammo := false
var said_boss := false
var said_boss_down := false
var hint_pending := false

func load_data() -> void:
	var raw = StageData_load()
	data = raw if raw is Dictionary else {}

func StageData_load() -> Variant:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

func reset(number: int) -> void:
	if data.is_empty():
		load_data()
	stage_number = number
	current = {}
	queue.clear()
	chatter_in = 7.0
	story_index = 0
	said_low_health = false
	said_low_ammo = false
	said_boss = false
	said_boss_down = false
	var start := _rayan_map("stage_start")
	if start != "":
		push_line("Rayan", start, "start")
		if current.is_empty() and not queue.is_empty():
			current = queue.pop_front()
			current.life = LINE_LIFE
	# First story beat at t=0 is rare; others wait on time.

func _rayan_map(key: String) -> String:
	var block: Dictionary = data.get("rayan", {})
	var v = block.get(key, "")
	if v is Dictionary:
		return str(v.get(str(stage_number), v.get(str(stage_number), "")))
	if v is Array and not v.is_empty():
		return str(v[0])
	return str(v) if v is String else ""

func _rayan_pick(key: String, rng: RandomNumberGenerator) -> String:
	var block: Dictionary = data.get("rayan", {})
	var v = block.get(key, "")
	if v is Dictionary:
		return str(v.get(str(stage_number), ""))
	if v is Array and not v.is_empty():
		return str(v[rng.randi() % v.size()])
	return str(v) if v is String else ""

func push_line(speaker: String, text: String, kind: String = "radio") -> void:
	text = text.strip_edges()
	if text == "":
		return
	var line := {"speaker": speaker, "text": text, "kind": kind, "life": LINE_LIFE}
	# Event lines jump the queue ahead of chatter.
	if kind in ["start", "event", "hint"]:
		if not current.is_empty() and str(current.get("kind", "")) == "chatter":
			current = {}
		queue.push_front(line)
	else:
		queue.append(line)

func on_event(name: String, _d: Dictionary, sim) -> void:
	if sim == null:
		return
	var rng: RandomNumberGenerator = sim.fx_rng
	match name:
		"villager_hit":
			push_line("Rayan", _rayan_pick("civilian_hit", rng), "event")
		"player_hit":
			if not said_low_health and sim.health <= sim.max_health * 0.35 and sim.health > 0.0:
				said_low_health = true
				push_line("Rayan", _rayan_pick("low_health", rng), "event")
		"empty":
			if not said_low_ammo:
				said_low_ammo = true
				push_line("Rayan", _rayan_pick("low_ammo", rng), "event")
		"airstrike":
			var t := str(data.get("rayan", {}).get("airstrike_called", ""))
			if t != "":
				push_line("Rayan", t, "event")
		"spawn":
			var e: Dictionary = _d.get("entity", {})
			if str(e.get("type", "")) == "gunboat" and not said_boss:
				said_boss = true
				var t := _rayan_map("boss_appears")
				if t != "":
					push_line("Rayan", t, "event")
		"kill":
			var e2: Dictionary = _d.get("entity", {})
			if str(e2.get("type", "")) == "gunboat" and not said_boss_down:
				said_boss_down = true
				var t2 := _rayan_map("boss_down")
				if t2 != "":
					push_line("Rayan", t2, "event")

func offer_airstrike_hint() -> void:
	var t := str(data.get("rayan", {}).get("airstrike_ready", ""))
	if t != "":
		push_line("Rayan", t, "hint")

func offer_airstrike_empty() -> void:
	var t := str(data.get("rayan", {}).get("airstrike_empty", ""))
	if t != "":
		push_line("Rayan", t, "hint")

func step(dt: float, sim, hold_display: bool = false) -> void:
	if sim == null or sim.state != "playing" or sim.paused:
		return
	# Hold the current line (and the chatter clock) while the stage title
	# card is up, so the plate never shares the screen with the name.
	if hold_display:
		return
	if not current.is_empty():
		current.life = float(current.life) - dt
		if float(current.life) <= 0.0:
			current = {}
	# Story beats, timed, one shot each.
	var beats: Array = data.get("story", {}).get(str(stage_number), [])
	while story_index < beats.size() and float(beats[story_index].get("t", 0.0)) <= sim.time:
		var beat: Dictionary = beats[story_index]
		story_index += 1
		var raw := str(beat.get("text", ""))
		var sp: String = "Command" if raw.begins_with("Command:") else "Rayan"
		var body: String = raw
		var cut := raw.find(":")
		if cut >= 0 and cut < 12:
			sp = raw.substr(0, cut)
			body = raw.substr(cut + 1).strip_edges()
		push_line(sp, body, "story")
	# Radio chatter on a slow clock.
	chatter_in -= dt
	if chatter_in <= 0.0:
		chatter_in = CHATTER_EVERY + sim.fx_rng.randf_range(-4.0, 6.0)
		var pool: Array = data.get("radio", {}).get(str(stage_number), [])
		if not pool.is_empty():
			var raw2 := str(pool[sim.fx_rng.randi() % pool.size()])
			var sp2: String = "Command"
			var body2: String = raw2
			var cut2 := raw2.find(":")
			if cut2 >= 0 and cut2 < 12:
				sp2 = raw2.substr(0, cut2)
				body2 = raw2.substr(cut2 + 1).strip_edges()
			push_line(sp2, body2, "chatter")
	if current.is_empty() and not queue.is_empty():
		current = queue.pop_front()
		current.life = LINE_LIFE

func text() -> String:
	if current.is_empty():
		return ""
	return str(current.get("text", ""))

func speaker() -> String:
	if current.is_empty():
		return ""
	return str(current.get("speaker", ""))

func kind() -> String:
	if current.is_empty():
		return ""
	return str(current.get("kind", ""))
