extends SceneTree
## Player name at start, automatic high-score saves, per-stage and run tables.
const Scores := preload("res://scripts/scores.gd")
const Online := preload("res://scripts/online.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await process_frame
func find_line_edit(n: Node) -> LineEdit:
	if n == null: return null
	if n is LineEdit: return n
	for c in n.get_children():
		var f := find_line_edit(c)
		if f: return f
	return null
func has_line_edit(n: Node) -> bool:
	return find_line_edit(n) != null
func collect_button_text(n: Node, out: Array) -> void:
	if n == null: return
	if n is Button: out.append(n.text)
	for c in n.get_children():
		collect_button_text(c, out)
func collect_labels(n: Node, out: Array) -> void:
	if n == null: return
	if n is Label: out.append(n.text)
	for c in n.get_children():
		collect_labels(c, out)

func run() -> void:
	# Name helpers and settings.
	check(Scores.clean_name("  ACE  ") == "ACE", "clean_name trims")
	check(Scores.clean_name("ABCDEFGHIJKLMNOP") == "ABCDEFGHIJKL", "clean_name caps at 12 characters")
	check(Scores.clean_name("   ") == "PLAYER" and Scores.clean_name("") == "PLAYER", "blank name becomes PLAYER")
	var s := Scores.load_settings()
	check(str(s.get("player_name", "")) == "PLAYER", "player name defaults to PLAYER")
	check(Scores.player_name() == "PLAYER", "player_name() uses the default")
	check(Scores.save_player_name("  Rayan  ") == "Rayan", "save_player_name returns the cleaned name")
	check(Scores.player_name() == "Rayan", "player name is remembered")
	check(str(Scores.load_settings().player_name) == "Rayan", "player name lives in settings")
	Scores.save_player_name("")
	check(Scores.player_name() == "PLAYER", "saving a blank name stores PLAYER")

	# Old scores.json arrays still load as the overall run table.
	var f := FileAccess.open(Scores.SCORES_PATH, FileAccess.WRITE)
	f.store_string('[{"name":"OLD","score":4242,"stage":1,"date":"2026-11-01"}]')
	f.close()
	var migrated := Scores.load_scores()
	check(migrated.size() == 1 and str(migrated[0].name) == "OLD" and int(migrated[0].score) == 4242, "a legacy scores array is the run table")
	check(Scores.load_stage_scores(1).is_empty(), "legacy scores do not appear on a stage table")
	check(Scores.add_score("ACE", 5000, 2) == 1, "a new run best ranks first")
	var run_list := Scores.load_scores()
	check(run_list.size() == 2 and int(run_list[0].score) == 5000 and int(run_list[1].score) == 4242, "run table keeps the migrated score")
	check(Scores.add_stage_score("ACE", 2100, 1) == 1, "stage 1 table accepts a score")
	check(Scores.add_stage_score("ACE", 1800, 2) == 1, "stage 2 table accepts a score")
	check(Scores.load_stage_scores(1).size() == 1 and int(Scores.load_stage_scores(1)[0].score) == 2100, "stage 1 keeps its own score")
	check(Scores.load_stage_scores(2).size() == 1 and int(Scores.load_stage_scores(2)[0].score) == 1800, "stage 2 keeps its own score")
	check(Scores.load_scores().size() == 2, "stage saves do not change the run table")
	check(Scores.qualifies_stage(1, 1) and not Scores.qualifies_stage(0, 1), "a positive unused stage slot qualifies, zero does not")
	for i in 10:
		Scores.add_stage_score("P%d" % i, 3000 + i, 1)
	check(Scores.load_stage_scores(1).size() == 10, "each stage keeps a top ten")
	check(not Scores.qualifies_stage(2100, 1) and Scores.qualifies_stage(4000, 1), "stage qualification uses that stage's tenth score")

	# Online payload is unchanged and uses whatever name it is given.
	var body: Dictionary = JSON.parse_string(Online.body_json("Rayan", 6230, 2, "0.4.0"))
	var keys := body.keys(); keys.sort()
	check(keys == ["mode", "name", "score", "stages", "version"], "POST still sends only name, score, mode, version, stages")
	check(str(body.name) == "Rayan" and int(body.score) == 6230, "the stored name is what the client would send")

	# Title chrome: tabs, change-name target, GLOBAL SCORES stays clickable.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	check(main.mode == "title", "starts on the title")
	main.title_screen.refresh_scores()
	check(main.title_screen.player_label == "PLAYER", "title shows the stored player name")
	check(main.title_screen.score_tab == "run", "the run table is the default tab")
	check(main.title_screen.tab_defs().size() >= 3, "tabs include RUN and each playable stage")
	check(str(main.title_screen.tab_defs()[0].id) == "run", "first tab is the overall run table")
	check(main.title_screen.name_hit(Vector2(1600, 566)) and not main.title_screen.name_hit(Vector2(200, 200)), "CHANGE NAME has a click target")
	check(main.title_screen.global_hit(Vector2(1650, 980)), "GLOBAL SCORES click target is unchanged")
	main.title_screen.select_tab("1")
	check(main.title_screen.score_tab == "1" and main.title_screen.current_scores().size() == 10, "stage 1 tab shows that stage's table")
	main.title_screen.select_tab("run")
	check(int(main.title_screen.current_scores()[0].score) == 5000, "run tab shows the overall table")

	# Start asks for a name once; confirming with Enter's equivalent starts the briefing.
	main.show_title(true)
	await frames(2)
	var labels: Array = []
	collect_button_text(main.menu_root, labels)
	var has_name_btn := false
	for t in labels:
		if str(t).begins_with("Name:") or str(t).contains("Change name") or str(t).begins_with("PLAYER"):
			has_name_btn = true
	check(has_name_btn, "the title menu has a way to change the name")
	main.start_mission()
	await frames(3)
	check(main.mode == "player_name", "Start opens the player-name prompt")
	var edit := find_line_edit(main.menu_root)
	check(edit != null and str(edit.text) == "PLAYER", "the prompt is prefilled with the last name")
	main.confirm_player_name("ACE")
	await frames(3)
	check(Scores.player_name() == "ACE" and main.settings.player_name == "ACE", "confirming writes the name to settings")
	check(main.mode == "briefing" and main.briefing.visible, "the first start continues to the briefing after the name")
	main.briefing.skip()
	main._on_briefing_finished()
	await frames(4)
	check(main.mode == "playing", "the mission starts after the name and briefing")

	# A later start still shows the prefilled prompt, never a mid-run name box.
	main.settings.seen_briefing = true
	main.show_title(true)
	await frames(2)
	main.start_mission()
	await frames(3)
	check(main.mode == "player_name", "later starts still confirm the name")
	edit = find_line_edit(main.menu_root)
	check(edit != null and str(edit.text) == "ACE", "later starts prefill the last name")
	main.confirm_player_name()
	await frames(4)
	check(main.mode == "playing", "Enter on the saved name starts the stage")

	# Change name from the title, then return to the menu without starting.
	main.show_title(true)
	await frames(2)
	main.show_name_prompt("change")
	await frames(2)
	check(main.mode == "player_name", "the title can open the name prompt to change it")
	main.confirm_player_name("BOB")
	await frames(2)
	check(main.mode == "title" and main.title_menu_open, "changing the name returns to the title menu")
	check(Scores.player_name() == "BOB" and main.title_screen.player_label == "BOB", "the title shows the new name")

	# Result screens never ask for a name; scores are stored under the saved name.
	main.settings.seen_briefing = true
	main.confirm_player_name("BOB")
	# confirm_player_name with reason "" after change already cleared reason; start a run directly.
	main.begin_run()
	main.start_stage(1)
	await frames(3)
	main.sim.kills = main.sim.quota
	main.sim.step(0.016)
	check(main.sim.state == "cleared", "forced clear finishes stage 1")
	var stage1: int = main.sim.score
	main.show_result()
	await frames(2)
	check(main.mode == "result", "result screen opens")
	check(not has_line_edit(main.menu_root), "the result screen has no name field")
	var result_text: Array = []
	collect_labels(main.menu_root, result_text)
	var asked := false
	for t in result_text:
		if str(t).to_lower().contains("enter your name"):
			asked = true
	check(not asked, "the result screen does not ask for a name")
	var s1 := Scores.load_stage_scores(1)
	check(s1.size() >= 1 and int(s1[0].score) >= stage1 and str(s1[0].name) == "BOB", "a cleared stage is saved under the stored name")
	var run_before := Scores.load_scores().duplicate(true)
	var run_has_stage1 := false
	for e in run_before:
		if int(e.get("score", 0)) == stage1 and str(e.get("name", "")) == "BOB":
			run_has_stage1 = true
	check(not run_has_stage1, "a mid-campaign clear does not write the overall run table")
	# Leaving for the title ends the run and records the total.
	main._quit_run_to_title()
	await frames(2)
	var run_after := Scores.load_scores()
	var found_run := false
	for e in run_after:
		if int(e.get("score", 0)) == stage1 and str(e.get("name", "")) == "BOB":
			found_run = true
	check(found_run, "going to the title after a mid-run clear saves the overall score")
	check(main.mode == "title", "quit to title returns to the title")

	# A failed run records the overall total automatically, still with no name box.
	main.begin_run()
	main.start_stage(1)
	await frames(3)
	main.sim.damage_player(500.0)
	main.sim.step(0.016)
	main.show_result()
	await frames(2)
	check(main.mode == "result" and not has_line_edit(main.menu_root), "a failed run has no name field")
	# Score may be 0 after an immediate death; a forced qualifying total still saves.
	main.run_score = 3330
	main.run_score_saved = false
	main._record_run_score()
	var found_fail := false
	for e in Scores.load_scores():
		if int(e.get("score", 0)) == 3330 and str(e.get("name", "")) == "BOB":
			found_fail = true
	check(found_fail, "a finished run is saved under the stored name")
	main._record_run_score()
	var count_3330 := 0
	for e in Scores.load_scores():
		if int(e.get("score", 0)) == 3330:
			count_3330 += 1
	check(count_3330 == 1, "a run score is not written twice")

	# Source: start asks for the name, results do not.
	var src := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(src.contains("func show_name_prompt") and src.contains("func confirm_player_name"), "main has the start-of-run name prompt")
	check(not src.contains("Enter your name"), "main no longer asks for a name on the result screen")
	check(src.contains("Online.submit(self, Scores.player_name()") or src.contains("Online.submit(self, name"), "the online post uses the stored player name")

	main.queue_free()
	await frames(2)
	print("Player name and scores: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
