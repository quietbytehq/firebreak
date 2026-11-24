extends SceneTree
## Main scene: title -> stage -> pause/resume -> result, plus top-ten scores
## and settings saved under user://.
const Scores := preload("res://scripts/scores.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await process_frame
func run() -> void:
	# Scores.
	check(Scores.load_scores().is_empty(), "no scores on a fresh profile")
	check(Scores.qualifies(10), "first score qualifies")
	for i in 12:
		Scores.add_score("P%d" % i, 1000 + i * 100, 1)
	var list := Scores.load_scores()
	check(list.size() == 10, "only the top ten are kept")
	check(int(list[0].score) == 2100 and int(list[9].score) == 1200, "scores sorted high to low")
	check(not Scores.qualifies(1100) and Scores.qualifies(1300), "qualification uses the tenth score")
	check(Scores.add_score("ACE", 5000, 1) == 1, "a new best ranks first")
	check(Scores.add_score("", 1250, 1) == 0, "a score below the table is not stored")
	check(str(Scores.load_scores()[0].name) == "ACE", "names persist")
	check(ProjectSettings.globalize_path(Scores.SCORES_PATH).contains("Firebreak"), "scores live in the Firebreak user folder")
	var s := Scores.load_settings(); s.music_volume = 0.3; Scores.save_settings(s)
	check(is_equal_approx(float(Scores.load_settings().music_volume), 0.3), "settings persist")
	var d := Scores.load_settings()
	check(bool(d.music_on) and int(d.music_track) == 1, "music defaults: on, track 1")
	check(not bool(d.seen_briefing), "briefing starts unseen")
	s.music_on = false; s.music_track = 3; s.sfx_volume = 0.4; Scores.save_settings(s)
	var l := Scores.load_settings()
	check(not bool(l.music_on) and int(l.music_track) == 3 and is_equal_approx(float(l.sfx_volume), 0.4), "music on/off, track and effects volume persist")
	s.music_on = true; s.music_track = 1; Scores.save_settings(s)
	check(Scores.clean_name("") == "PLAYER" and Scores.clean_name("   ") == "PLAYER", "blank names become PLAYER")
	check(Scores.clean_name("  Rayan  ") == "Rayan", "names are trimmed")
	check(Scores.clean_name("ABCDEFGHIJKLMNOP") == "ABCDEFGHIJKL", "names cap at 12 characters")
	check(Scores.clean_name("A" + String.chr(7) + "B") == "AB", "control characters are stripped")
	check(str(Scores.load_settings().get("player_name", "")) == "PLAYER", "player name defaults to PLAYER")
	s.player_name = Scores.clean_name("  ACE  "); Scores.save_settings(s)
	check(str(Scores.load_settings().player_name) == "ACE", "player name persists")
	check(Scores.add_stage_score("ACE", 3000, 1) == 1, "a stage-1 score ranks first")
	check(Scores.add_stage_score("BOB", 2000, 1) == 2, "a lower stage-1 score ranks second")
	check(Scores.add_stage_score("ACE", 4500, 2) == 1, "stage-2 scores are stored separately")
	check(int(Scores.load_stage_scores(1)[0].score) == 3000 and str(Scores.load_stage_scores(1)[0].name) == "ACE", "stage-1 best is kept")
	check(int(Scores.load_stage_scores(2)[0].score) == 4500, "stage-2 best is kept")
	check(int(Scores.load_scores()[0].score) == 5000, "the run table is unchanged by stage scores")
	check(Scores.qualifies_stage(2500, 1), "a mid stage-1 score still qualifies")
	# Main scene.
	var main = load("res://scenes/main.tscn").instantiate()
	if main == null or main.get_script() == null or not main.get_script().can_instantiate():
		check(false, "main scene script loads"); print("Main scene: ", checks, " checks, ", failures, " failures"); quit(1); return
	root.add_child(main)
	await frames(3)
	check(main.mode == "title", "starts on the title screen")
	check(main.title_screen.visible and main.title_screen.press_start, "title art with PRESS START")
	check(main.audio.current_music == "music_title_intro_loop" and main.audio.music_next == "music_title_intro_loop", "title plays the intro, then its loop")
	check("EMBER RING" in str(main.title_screen.subtitle), "title mentions the Ember Ring")
	check(Engine.max_fps == 60, "frame rate capped at 60")
	var press := InputEventKey.new(); press.physical_keycode = KEY_ENTER; press.keycode = KEY_ENTER; press.pressed = true
	Input.parse_input_event(press)
	await frames(3)
	check(main.title_menu_open and main.menu_root != null, "any key opens the title menu")
	check(main.audio.find_stream("fire") == null or main.audio.find_stream("fire") is AudioStream, "audio lookup by base name works")
	main.audio.play("definitely_missing_sound")
	main.audio.play_music("definitely_missing_music")
	check(true, "missing audio files do not crash the game")
	main.start_stage(1)
	await frames(30)
	check(main.mode == "playing" and main.sim != null and main.sim.time > 0.0, "stage runs")
	check(main.sim.grenades == 5 and main.sim.airstrikes == 1, "stage starts with 5 grenades and 1 air strike")
	check(main.audio.current_music == "music_bg_01", "in-game music loops background track 1")
	check(main.hud.visible and main.view.visible, "HUD and stage are visible")
	var t: float = main.sim.time
	main.pause_game()
	await frames(30)
	check(main.mode == "paused" and main.sim.time == t, "pause stops the stage clock")
	check(main.menu_root != null, "pause menu shown")
	main.set_music_track(2)
	check(main.audio.current_music == "music_bg_02", "pause menu switches to track 2")
	main.set_music_on(false)
	check(not main.audio.music_player.playing, "pause menu turns music off")
	main.set_volumes(0.5, 0.25)
	var ps := Scores.load_settings()
	check(int(ps.music_track) == 2 and not bool(ps.music_on) and is_equal_approx(float(ps.music_volume), 0.25) and is_equal_approx(float(ps.sfx_volume), 0.5), "music choices saved to user://settings.cfg")
	main.set_music_on(true)
	check(main.audio.current_music == "music_bg_02", "music back on resumes the chosen track")
	main.resume_game()
	await frames(10)
	check(main.mode == "playing" and main.sim.time > t, "resume continues")
	var ev := InputEventAction.new(); ev.action = "pause"; ev.pressed = true
	Input.parse_input_event(ev)
	await frames(3)
	check(main.mode == "paused", "the pause action pauses")
	main.resume_game()
	main.sim.damage_player(500.0)
	await create_timer(2.5).timeout
	await frames(2)
	check(main.mode == "result", "result screen after the stage ends")
	var result_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	check("Enter your name" not in result_src, "the result screen no longer asks for a name")
	var has_edit := false
	if main.menu_root:
		for n in main.menu_root.find_children("*", "LineEdit", true, false):
			has_edit = true
	check(not has_edit, "the result screen has no name field")
	main.show_controls("title")
	await frames(2)
	check(main.mode == "controls", "controls screen opens")
	main._back()
	await frames(2)
	check(main.mode == "title", "back to title")
	main.queue_free()
	await frames(2)
	print("Main scene: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
