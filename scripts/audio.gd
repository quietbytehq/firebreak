extends Node
## Loads sounds by base name from res://assets/audio/ or from an "audio"
## folder next to the game executable (.ogg, .wav or .mp3). Missing files are
## fine: the game simply stays silent for that sound.
## Channels: a pool of one-shot SFX players, one music player (with an
## intro-then-loop sequence), an ambience loop, named SFX loops (helicopter
## rotor, heartbeat) and one voice player with rate limiting.
## Pause (0.3.1): pause_all() freezes every SFX, loop, ambience, voice and the
## stage music, and plays a calm pause-menu track instead; resume_all() undoes
## it. While paused only menu sounds (ui_*, store_*) can start.

const EXTS := ["ogg", "wav", "mp3"]
const VOICE_GAP := 2.5   # minimum seconds between two voice lines
const PAUSE_MUSIC := "music_pause"
const UI_PREFIXES := ["ui_", "store_"]
var cache := {}
var players: Array = []
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var loops := {}          # name -> AudioStreamPlayer
var sfx_volume := 0.9
var music_volume := 0.8
var music_on := true
var enabled := true
var music_next := ""     # loop to start when a one-shot intro finishes
var current_music := ""
var voice_cooldowns := {}
var last_voice_ms := -100000
var duck_left := 0.0
var duck_db := 0.0
var paused := false
var pause_player: AudioStreamPlayer
var ui_players: Array = []

func _ready() -> void:
	for i in 14:
		var p := AudioStreamPlayer.new(); add_child(p); players.append(p)
	music_player = AudioStreamPlayer.new(); add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	ambience_player = AudioStreamPlayer.new(); add_child(ambience_player)
	voice_player = AudioStreamPlayer.new(); add_child(voice_player)
	pause_player = AudioStreamPlayer.new(); add_child(pause_player)
	for i in 3:
		var p := AudioStreamPlayer.new(); add_child(p); ui_players.append(p)

static func external_dir() -> String:
	return OS.get_executable_path().get_base_dir().path_join("audio")

func has_sound(base: String) -> bool:
	return find_stream(base) != null

func find_stream(base: String) -> AudioStream:
	if cache.has(base): return cache[base]
	var stream: AudioStream = null
	for ext in EXTS:
		var path := "res://assets/audio/%s.%s" % [base, ext]
		if ResourceLoader.exists(path):
			stream = load(path); break
	if stream == null and not OS.has_feature("editor"):
		for ext in EXTS:
			var path := external_dir().path_join("%s.%s" % [base, ext])
			if FileAccess.file_exists(path):
				stream = _load_external(path, ext)
				if stream != null: break
	cache[base] = stream
	return stream

func _load_external(path: String, ext: String) -> AudioStream:
	match ext:
		"ogg": return AudioStreamOggVorbis.load_from_file(path)
		"wav": return AudioStreamWAV.load_from_file(path)
		"mp3":
			var s := AudioStreamMP3.new()
			s.data = FileAccess.get_file_as_bytes(path)
			return s
	return null

func _sfx_db(volume_db: float) -> float:
	return volume_db + linear_to_db(maxf(0.001, sfx_volume))

static func is_ui_sound(base: String) -> bool:
	for pre in UI_PREFIXES:
		if base.begins_with(pre): return true
	return false

func play(base: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not enabled: return
	var ui := is_ui_sound(base)
	if paused and not ui: return   # gameplay sounds never start while paused
	var stream := find_stream(base)
	if stream == null: return
	for p in (ui_players if ui else []) + players:
		if not p.playing and not p.stream_paused:
			p.stream = stream; p.volume_db = _sfx_db(volume_db); p.pitch_scale = pitch; p.play()
			return

## Plays the first base name that exists (e.g. a specific sound, then a generic fallback).
func play_first(bases: Array, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	for b in bases:
		if has_sound(str(b)):
			play(str(b), volume_db, pitch); return

# ------------------------------------------------------------------ music
func _set_loop(stream: AudioStream, on: bool) -> void:
	if stream != null and "loop" in stream: stream.set("loop", on)

func _music_db() -> float:
	return linear_to_db(maxf(0.001, music_volume)) - 4.0

func _process(delta: float) -> void:
	if duck_left <= 0.0:
		return
	duck_left = maxf(0.0, duck_left - delta)
	_apply_music_vol()

## Briefly lower the music (for the title call), then ease back.
func duck_music(db: float, seconds: float) -> void:
	duck_db = db
	duck_left = seconds
	_apply_music_vol()

func _apply_music_vol() -> void:
	var extra := 0.0
	if duck_left > 0.0:
		var fade := 0.25
		var scale := 1.0 if duck_left > fade else duck_left / fade
		extra = duck_db * scale
	if music_player:
		music_player.volume_db = _music_db() + extra
	if pause_player:
		pause_player.volume_db = _music_db()

## Loops a track. With `intro`, the intro plays once first, then the loop.
func play_music(base: String, intro: String = "") -> void:
	current_music = base
	if paused:
		# Remember the track for resume_all(); a different track replaces the paused one.
		var want := find_stream(intro if intro != "" else base)
		if music_player.stream != want:
			music_player.stop(); music_player.stream_paused = false; music_next = ""
			if intro != "": music_next = base
		return
	if not enabled or not music_on:
		music_player.stop(); return
	if intro != "" and find_stream(intro) != null:
		var si := find_stream(intro)
		if music_player.stream == si and music_player.playing: return
		_set_loop(si, false)
		music_next = base
		music_player.stream = si; _apply_music_vol(); music_player.play()
		return
	music_next = ""
	var stream := find_stream(base)
	if stream == null:
		music_player.stop(); return
	if music_player.stream == stream and music_player.playing: return
	_set_loop(stream, true)
	music_player.stream = stream
	_apply_music_vol()
	music_player.play()

func _on_music_finished() -> void:
	if music_next != "":
		var n := music_next; music_next = ""
		play_music(n)

func stop_music() -> void:
	music_next = ""; current_music = ""
	if music_player: music_player.stop(); music_player.stream_paused = false

func set_music_on(on: bool) -> void:
	music_on = on
	if paused:
		# The toggle in the pause menu drives the pause track; the stage music
		# follows the setting on resume.
		if on: _start_pause_music()
		else:
			pause_player.stop()
			music_player.stop(); music_player.stream_paused = false; music_next = ""
		return
	if not on:
		music_next = ""
		if music_player: music_player.stop()
	elif current_music != "":
		play_music(current_music)

func set_volumes(sfx: float, music: float) -> void:
	sfx_volume = sfx; music_volume = music
	_apply_music_vol()
	if ambience_player: ambience_player.volume_db = _sfx_db(-10.0)

# ------------------------------------------------------------------ loops
func play_ambience(base: String) -> void:
	if not enabled or paused: return
	var stream := find_stream(base)
	if stream == null:
		ambience_player.stop(); return
	_set_loop(stream, true)
	ambience_player.stream = stream
	ambience_player.volume_db = _sfx_db(-10.0)
	ambience_player.play()

func stop_ambience() -> void:
	if ambience_player: ambience_player.stop()

## Starts (or keeps) a named looping SFX, e.g. the rotor or the heartbeat.
func loop_on(base: String, volume_db: float = 0.0) -> void:
	if not enabled or paused: return
	var stream := find_stream(base)
	if stream == null: return
	var p: AudioStreamPlayer = loops.get(base)
	if p == null:
		p = AudioStreamPlayer.new(); add_child(p); loops[base] = p
	p.volume_db = _sfx_db(volume_db)
	if p.playing: return
	_set_loop(stream, true)
	p.stream = stream; p.play()

func loop_off(base: String) -> void:
	var p: AudioStreamPlayer = loops.get(base)
	if p and p.playing: p.stop()

func is_looping(base: String) -> bool:
	var p: AudioStreamPlayer = loops.get(base)
	return p != null and p.playing

func stop_loops() -> void:
	for p in loops.values(): p.stop()

# ------------------------------------------------------------------ voice
## Plays a Rayan line unless another line played very recently or this line
## is still on its own cooldown. `force` skips the shared gap (key moments).
func voice(base: String, cooldown: float = 6.0, force: bool = false) -> bool:
	if not enabled or paused or not has_sound(base): return false
	var now := Time.get_ticks_msec()
	if now < int(voice_cooldowns.get(base, -100000)): return false
	if not force and (now - last_voice_ms < int(VOICE_GAP * 1000.0) or voice_player.playing): return false
	voice_cooldowns[base] = now + int(cooldown * 1000.0)
	last_voice_ms = now
	voice_player.stream = find_stream(base)
	voice_player.volume_db = _sfx_db(1.0)
	voice_player.play()
	return true

# ------------------------------------------------------------------ pause
## Every gameplay channel: one-shot SFX, named loops, ambience, voice.
func sfx_channels() -> Array:
	return players + loops.values() + [ambience_player, voice_player]

## Freezes all gameplay sound and the stage music where they are, then plays
## the pause-menu track (if music is on).
func pause_all() -> void:
	if paused: return
	paused = true
	for p in sfx_channels() + [music_player]:
		if p.playing: p.stream_paused = true
	_start_pause_music()

func _start_pause_music() -> void:
	if not enabled or not music_on: return
	var stream := find_stream(PAUSE_MUSIC)
	if stream == null: return
	if pause_player.playing and pause_player.stream == stream: return
	_set_loop(stream, true)
	pause_player.stream = stream; pause_player.volume_db = _music_db(); pause_player.play()

## Stops the pause track and lets everything continue from where it froze.
func resume_all() -> void:
	if not paused: return
	paused = false
	pause_player.stop()
	for p in sfx_channels():
		if p.stream_paused: p.stream_paused = false
	if music_player.stream_paused:
		music_player.stream_paused = false
		if not music_on: music_player.stop()
	if music_on and current_music != "" and not music_player.playing:
		music_next = ""
		play_music(current_music)

## Ends a pause without resuming the frozen sounds (restart / quit to title).
func clear_pause() -> void:
	paused = false
	pause_player.stop()
	for p in sfx_channels() + [music_player]:
		if p.stream_paused: p.stream_paused = false; p.stop()

func is_pause_music_playing() -> bool:
	return pause_player != null and pause_player.playing
