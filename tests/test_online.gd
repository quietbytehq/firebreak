extends SceneTree
## Global scoreboard client, campaign run totals, accuracy bonus rounding,
## and the online opt-out setting.
const Scores := preload("res://scripts/scores.gd")
const Online := preload("res://scripts/online.gd")
const StageSim := preload("res://scripts/stage_sim.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")

func finish_clear(sim, hits: int, shots: int, health: float, time_left: float) -> void:
	sim.stats.hits = hits
	sim.stats.shots = shots
	sim.health = health
	sim.time = sim.duration - time_left
	sim._finish("cleared", "quota")

func run() -> void:
	# Online payload: only the allowed fields, integer score.
	check(Online.SITE == "firebreak.quietbytehq.uk", "site is firebreak.quietbytehq.uk")
	check(Online.MODE == "campaign" and Online.MIN_SCORE == 2000, "campaign mode and min 2000")
	var body: Dictionary = JSON.parse_string(Online.body_json("Rayan", 6230, 1, "0.3.3"))
	check(body is Dictionary, "body is JSON")
	var keys := body.keys()
	keys.sort()
	check(keys == ["mode", "name", "score", "stages", "version"], "POST sends only name, score, mode, version, stages")
	var st: int = typeof(body.score)
	check(int(body.score) == 6230 and (st == TYPE_FLOAT or st == TYPE_INT), "score is numeric")
	# Godot JSON may decode numbers as float; the string must not look like 6230.0 if we stringify an int.
	check(Online.body_json("ACE", 2000, 1, "0.3.3").contains("\"score\":2000"), "JSON score is a whole number, not 2000.0")
	check(str(body.mode) == "campaign" and int(body.stages) == 1 and str(body.version) == "0.3.3", "mode, stages and version are set")
	check(str(body.name) == "Rayan", "typed name is sent")

	# Settings: online defaults to on and is remembered.
	var s := Scores.load_settings()
	check(bool(s.get("online", false)) == true, "online posting defaults to on")
	s.online = false
	Scores.save_settings(s)
	check(not bool(Scores.load_settings().online), "online opt-out is saved")
	s.online = true
	Scores.save_settings(s)
	check(bool(Scores.load_settings().online), "online opt-in is saved")

	# Accuracy bonus is rounded to a multiple of 10, so every final score is too.
	var sim = StageSim.new(); sim.setup(1, 1); sim.stage.ambient = []; sim.stage.waves = []
	finish_clear(sim, 2, 3, 100.0, 40.0)
	# 2/3 accuracy: int(round(200*2/3))*10 = 1330 (the old int(acc*2000) would be 1333)
	var expected := 100 * 20 + 40 * 25 + 1330
	check(sim.clear_bonus == expected, "2/3 accuracy bonus is 1330 plus health and time, not 1333")
	check(sim.clear_bonus % 10 == 0 and sim.score % 10 == 0, "clear bonus and score are multiples of 10")
	sim = StageSim.new(); sim.setup(1, 1); sim.stage.ambient = []; sim.stage.waves = []
	finish_clear(sim, 1, 1, 100.0, 81.0)
	check(sim.clear_bonus % 10 == 0, "an odd number of seconds left still yields a multiple of 10")
	check(sim.clear_bonus == 100 * 20 + 10 * int(round(81.0 * 2.5)) + 2000, "81s time bonus is 25 points a second rounded to 10")
	sim = StageSim.new(); sim.setup(1, 1); sim.stage.ambient = []; sim.stage.waves = []
	var r: Dictionary = sim.spawn("rifleman", "mid")
	r.rise = 1.0; r.state = "aim"; r.timer = 10.0
	sim.fire(sim.hitbox(r).get_center() - Vector2(sim.camera_x, 0))
	var kill_score: int = sim.score
	finish_clear(sim, 1, 1, 80.0, 10.0)
	check(sim.clear_bonus == 80 * 20 + 10 * 25 + 2000, "perfect accuracy gives a 2000 point accuracy bonus")
	check((kill_score + sim.clear_bonus) == sim.score, "clear bonus is added to the stage score")
	check(sim.score % 10 == 0, "a scored clear is a multiple of 10")
	# A few more accuracy fractions.
	for pair in [[1, 7], [5, 6], [8, 9], [9, 11], [0, 4]]:
		sim = StageSim.new(); sim.setup(1, 1)
		finish_clear(sim, int(pair[0]), int(pair[1]), 50.0, 0.0)
		check(sim.clear_bonus % 10 == 0, "accuracy %d/%d still yields a multiple of 10" % [pair[0], pair[1]])

	# Campaign run: later stages add to the total; a new run starts from zero.
	# Stage 2 is not playable, so the second stage reuses stage 1 as a stand-in.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.begin_run()
	main.start_stage(1)
	await process_frame
	check(main.run_score == 0 and main.run_live and not main.run_banked, "a new run starts at zero")
	main.sim.kills = main.sim.quota
	main.sim.step(0.016)
	check(main.sim.state == "cleared", "forced quota clear finishes the stage")
	main.show_result()
	var first: int = main.run_score
	check(first == main.sim.score and first > 0 and main.run_banked, "the first stage score is banked as the run total")
	check(main.run_stages == 1, "last stage reached is 1")
	check(main.displayed_score() == first, "displayed score matches the banked total")
	main.bank_run_score()
	check(main.run_score == first, "banking twice does not double the score")
	main.continue_run_to(1)
	await process_frame
	check(main.run_live and not main.run_banked and main.run_score == first, "continue keeps the earlier total")
	check(main.hud.run_base == first, "HUD shows earlier stages under the current stage score")
	main.sim.kills = main.sim.quota
	main.sim.step(0.016)
	main.show_result()
	check(main.run_score == first + main.sim.score and main.run_score > first, "the next stage is added to the campaign total")
	var combined: int = main.run_score
	main.begin_run()
	main.start_stage(1)
	await process_frame
	main.sim.damage_player(500.0)
	main.sim.step(0.016)
	main.show_result()
	check(main.run_score == main.sim.score and main.run_score != combined, "Start mission / begin_run starts a fresh total")
	main.queue_free()
	await process_frame

	print("Online and campaign scores: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
