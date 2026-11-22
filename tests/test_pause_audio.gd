extends SceneTree
## Pause audio (0.3.1): pausing freezes every gameplay sound and the stage
## music, plays the calm pause-menu track, the music toggle still works while
## paused, and resuming brings the stage music and effects back.
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await process_frame

func busy(players: Array) -> int:
	var n := 0
	for p in players:
		if p.playing and not p.stream_paused: n += 1
	return n

func run() -> void:
	check(ResourceLoader.exists("res://assets/audio/music_pause.ogg"), "pause-menu music file is shipped")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	var a = main.audio
	main.set_music_on(true)
	main.start_stage(1)
	await frames(20)
	# Make sure every kind of channel is busy before the pause.
	a.play("fire"); a.play("explosion"); a.voice("rayan_fire_in_the_hole", 0.0, true)
	await frames(2)
	a.loop_on("helicopter_rotor")   # same frame as the pause: the game loop would switch it off with no helicopter near
	check(a.music_player.playing, "stage music plays before the pause")
	check(a.ambience_player.playing, "ambience plays before the pause")
	check(a.is_looping("helicopter_rotor"), "rotor loop plays before the pause")
	check(busy(a.players) > 0, "one-shot effects play before the pause")
	var stage_track: AudioStream = a.music_player.stream
	main.pause_game()
	await frames(5)
	check(a.paused and main.mode == "paused", "audio enters the paused state")
	check(busy(a.sfx_channels()) == 0, "no gameplay sound keeps playing while paused (SFX, loops, ambience, voice)")
	check(a.ambience_player.stream_paused and a.loops["helicopter_rotor"].stream_paused, "ambience and loops are frozen, not lost")
	check(a.music_player.stream_paused, "stage music is paused")
	check(a.is_pause_music_playing() and a.pause_player.stream == a.find_stream("music_pause"), "the pause-menu track plays")
	# New gameplay sounds are ignored while paused; menu sounds still play.
	var before := busy(a.players)
	a.play("fire"); a.play("explosion"); a.play("enemy_rifle"); a.play_first(["helicopter_mg", "enemy_mg"])
	a.loop_on("heartbeat"); a.play_ambience("ambience_river")
	check(busy(a.players) == before and not a.is_looping("heartbeat"), "gunfire, explosions, enemy fire and loops cannot start while paused")
	check(not a.voice("rayan_care_package", 0.0, true), "voice lines cannot start while paused")
	main.sim.event.emit("explosion", {"radius": 400.0, "pos": Vector2(900, 500)})
	main.sim.event.emit("airstrike", {})
	await frames(40)
	check(busy(a.sfx_channels()) == 0, "sim events during pause stay silent")
	check(main.pending_sounds.size() > 0, "delayed sounds wait for the resume instead of playing")
	a.play("ui_move")
	check(busy(a.ui_players) == 1, "menu sounds still play while paused")
	# Music toggle in the pause menu.
	main.set_music_on(false)
	check(not a.is_pause_music_playing() and not a.music_player.playing, "music OFF in the pause menu stops the pause track")
	main.set_music_on(true)
	check(a.is_pause_music_playing(), "music ON in the pause menu brings the pause track back")
	check(not a.music_player.playing or a.music_player.stream_paused, "the stage music stays silent while paused")
	# Resume.
	main.resume_game()
	await frames(5)
	check(not a.paused and not a.is_pause_music_playing(), "resume stops the pause track")
	check(a.music_player.playing and not a.music_player.stream_paused and a.music_player.stream == stage_track, "resume brings back the stage music")
	check(a.ambience_player.playing and not a.ambience_player.stream_paused, "resume brings back the ambience")
	a.play("fire")
	check(busy(a.players) > 0, "effects play again after the resume")
	# Pause with music off: no pause track, toggle after resume still fine.
	main.set_music_on(false)
	main.pause_game(); await frames(3)
	check(not a.is_pause_music_playing(), "no pause track when music is off")
	main.resume_game(); await frames(3)
	check(not a.music_player.playing, "music stays off after resuming")
	main.set_music_on(true); await frames(2)
	check(a.music_player.playing, "music can be turned back on in play")
	# Track change while paused takes effect on resume.
	main.pause_game(); await frames(3)
	main.set_music_track(3)
	check(a.is_pause_music_playing() and not (a.music_player.playing and not a.music_player.stream_paused), "a track change while paused keeps the pause track")
	main.resume_game(); await frames(3)
	check(a.current_music == "music_bg_03" and a.music_player.playing and a.music_player.stream == a.find_stream("music_bg_03"), "the new track starts on resume")
	main.set_music_track(1)
	# Quit to title from pause clears the paused state.
	main.pause_game(); await frames(3)
	main.show_title(true); await frames(3)
	check(not a.paused and not a.is_pause_music_playing(), "quitting to title ends the pause audio")
	# Restart from pause.
	main.start_stage(1); await frames(5)
	main.pause_game(); await frames(3)
	main.start_stage(1); await frames(5)
	check(not a.paused and not a.is_pause_music_playing() and a.music_player.playing, "restarting from pause plays the stage music again")
	print("Pause audio: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
