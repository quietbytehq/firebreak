extends RefCounted
## Local top-ten scores and settings, stored under user://.

const SCORES_PATH := "user://scores.json"
const SETTINGS_PATH := "user://settings.cfg"
const MAX_SCORES := 10

static func load_scores() -> Array:
	if not FileAccess.file_exists(SCORES_PATH): return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SCORES_PATH))
	if not (parsed is Array): return []
	var out := []
	for s in parsed:
		if s is Dictionary and s.has("score"): out.append(s)
	out.sort_custom(func(a, b): return int(a.score) > int(b.score))
	return out.slice(0, MAX_SCORES)

static func qualifies(score: int) -> bool:
	if score <= 0: return false
	var list := load_scores()
	return list.size() < MAX_SCORES or score > int(list[list.size() - 1].score)

## Adds an entry, keeps the best ten and saves. Returns the 1-based rank or 0.
static func add_score(name: String, score: int, stage: int) -> int:
	var clean := name.strip_edges().substr(0, 12)
	if clean == "": clean = "PLAYER"
	var entry := {"name": clean, "score": score, "stage": stage, "date": Time.get_date_string_from_system()}
	var list := load_scores()
	list.append(entry)
	list.sort_custom(func(a, b): return int(a.score) > int(b.score))
	list = list.slice(0, MAX_SCORES)
	var f := FileAccess.open(SCORES_PATH, FileAccess.WRITE)
	if f == null: return 0
	f.store_string(JSON.stringify(list, " "))
	f.close()
	var rank := list.find(entry)
	return rank + 1 if rank >= 0 else 0

static func load_settings() -> Dictionary:
	var s := {"fullscreen": true, "music_volume": 0.8, "sfx_volume": 0.9, "aim_speed": 1.0, "music_on": true, "music_track": 1, "online": true, "seen_briefing": false}
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
	return s

static func save_settings(s: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for k in s.keys():
		cfg.set_value("settings", k, s[k])
	cfg.save(SETTINGS_PATH)
