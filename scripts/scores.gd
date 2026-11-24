extends RefCounted
## Local high scores and settings, stored under user://.
## scores.json holds an overall run table plus a top ten for each stage.

const SCORES_PATH := "user://scores.json"
const SETTINGS_PATH := "user://settings.cfg"
const MAX_SCORES := 10
const NAME_MAX := 12

static func clean_name(name: String) -> String:
	var out := ""
	for i in name.strip_edges().length():
		var c := name.strip_edges().substr(i, 1)
		var code := c.unicode_at(0)
		# Printable characters only; no ASCII controls or DEL.
		if code >= 32 and code != 127:
			out += c
		if out.length() >= NAME_MAX:
			break
	out = out.strip_edges()
	return "PLAYER" if out == "" else out

static func _blank_store() -> Dictionary:
	return {"runs": [], "stages": {}}

static func _read_store() -> Dictionary:
	var store := _blank_store()
	if not FileAccess.file_exists(SCORES_PATH):
		return store
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SCORES_PATH))
	# Older builds saved a bare array of run entries.
	if parsed is Array:
		store.runs = _clean_list(parsed)
		return store
	if parsed is Dictionary:
		store.runs = _clean_list(parsed.get("runs", parsed.get("run", [])))
		var stages = parsed.get("stages", {})
		if stages is Dictionary:
			for k in stages.keys():
				store.stages[str(k)] = _clean_list(stages[k])
	return store

static func _clean_list(raw) -> Array:
	var out := []
	if not (raw is Array):
		return out
	for s in raw:
		if s is Dictionary and s.has("score"):
			out.append(s)
	out.sort_custom(func(a, b): return int(a.score) > int(b.score))
	return out.slice(0, MAX_SCORES)

static func _write_store(store: Dictionary) -> void:
	var f := FileAccess.open(SCORES_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(store, " "))
	f.close()

static func load_scores() -> Array:
	return _read_store().runs

static func load_stage_scores(stage: int) -> Array:
	var stages: Dictionary = _read_store().stages
	var list = stages.get(str(stage), [])
	return list if list is Array else []

static func _qualifies_in(list: Array, score: int) -> bool:
	if score <= 0:
		return false
	return list.size() < MAX_SCORES or score > int(list[list.size() - 1].score)

static func qualifies(score: int) -> bool:
	return _qualifies_in(load_scores(), score)

static func qualifies_stage(score: int, stage: int) -> bool:
	return _qualifies_in(load_stage_scores(stage), score)

static func _insert(list: Array, entry: Dictionary) -> Array:
	list.append(entry)
	list.sort_custom(func(a, b): return int(a.score) > int(b.score))
	return list.slice(0, MAX_SCORES)

static func _rank_of(list: Array, entry: Dictionary) -> int:
	var rank := list.find(entry)
	return rank + 1 if rank >= 0 else 0

## Adds a campaign-run entry, keeps the best ten and saves. Returns the 1-based rank or 0.
static func add_score(name: String, score: int, stage: int) -> int:
	if not qualifies(score):
		return 0
	var entry := {"name": clean_name(name), "score": score, "stage": stage, "date": Time.get_date_string_from_system()}
	var store := _read_store()
	store.runs = _insert(store.runs, entry)
	_write_store(store)
	return _rank_of(store.runs, entry)

## Adds a single-stage entry to that stage's top ten. Returns the 1-based rank or 0.
static func add_stage_score(name: String, score: int, stage: int) -> int:
	if stage < 1 or not qualifies_stage(score, stage):
		return 0
	var entry := {"name": clean_name(name), "score": score, "stage": stage, "date": Time.get_date_string_from_system()}
	var store := _read_store()
	var key := str(stage)
	var list: Array = store.stages.get(key, [])
	if not (list is Array):
		list = []
	store.stages[key] = _insert(list, entry)
	_write_store(store)
	return _rank_of(store.stages[key], entry)

static func load_settings() -> Dictionary:
	var s := {"fullscreen": true, "music_volume": 0.8, "sfx_volume": 0.9, "aim_speed": 1.0, "music_on": true, "music_track": 1, "online": true, "seen_briefing": false, "player_name": "PLAYER"}
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for k in s.keys():
			s[k] = cfg.get_value("settings", k, s[k])
	s.music_track = clampi(int(s.music_track), 1, 3)
	s.music_volume = clampf(float(s.music_volume), 0.0, 1.0)
	s.sfx_volume = clampf(float(s.sfx_volume), 0.0, 1.0)
	s.music_on = bool(s.music_on)
	s.online = bool(s.online)
	s.seen_briefing = bool(s.seen_briefing)
	s.player_name = clean_name(str(s.player_name))
	return s

static func save_settings(s: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for k in s.keys():
		cfg.set_value("settings", k, s[k])
	cfg.save(SETTINGS_PATH)

static func saved_name(s: Dictionary = {}) -> String:
	if s.is_empty():
		s = load_settings()
	var n := str(s.get("player_name", "")).strip_edges()
	return clean_name(n) if n != "" else "PLAYER"

static func player_name() -> String:
	return saved_name()

static func save_player_name(name: String) -> String:
	var s := load_settings()
	s.player_name = clean_name(name)
	save_settings(s)
	return s.player_name

