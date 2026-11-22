extends SceneTree
## 0.4.0 story screens, one START button, local scores and the title call.
const StageData := preload("res://scripts/stage_data.gd")
const Scores := preload("res://scripts/scores.gd")
const UiStyle := preload("res://scripts/ui_style.gd")
const BriefingScreen := preload("res://scripts/briefing_screen.gd")
const TravelMapScreen := preload("res://scripts/travel_map_screen.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func collect_button_text(n: Node, out: Array) -> void:
	if n == null: return
	if n is Button: out.append(n.text)
	for c in n.get_children():
		collect_button_text(c, out)
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await process_frame
func run() -> void:
	var names := ["River Village", "Dune Sea", "Coral Coast", "Iron Harbour", "Night Market", "High Pass", "Broken Dam", "Red Quarry", "Blackout City", "Honour Gate", "Storm Jetty", "Ember Yard"]
	var stages: Array = StageData.campaign().get("stages", [])
	check(stages.size() == 12, "campaign lists 12 named stages")
	for i in names.size():
		var s: Dictionary = stages[i]
		check(str(s.get("name", "")) == names[i], "stage %d is %s" % [i + 1, names[i]])
		check(str(s.get("brief", "")) != "", "stage %d has a one-line brief" % (i + 1))
		var m: Array = s.get("map", [])
		check(m.size() == 2 and float(m[0]) > 0.0 and float(m[0]) < 1.0 and float(m[1]) > 0.0 and float(m[1]) < 1.0, "stage %d has a map pin" % (i + 1))
		if i <= 1:
			check(bool(s.get("playable", false)), "stage %d is playable" % (i + 1))
		else:
			check(not bool(s.get("playable", false)), "stage %d is not playable yet" % (i + 1))
	check(str(StageData.campaign().get("version", "")) == "0.4.0", "campaign version is 0.4.0")
	for path in ["res://assets/ui/briefing_bg.jpg", "res://assets/ui/travel_map.jpg",
			"res://assets/ui/hud/plate.png", "res://assets/ui/hud/icon_score.png",
			"res://assets/ui/hud/icon_cash.png", "res://assets/ui/hud/icon_clock.png",
			"res://assets/ui/hud/icon_enemies.png",
			"res://assets/fonts/BarlowCondensed-Regular.ttf", "res://assets/fonts/BarlowCondensed-Bold.ttf",
			"res://assets/fonts/OFL-BarlowCondensed.txt", "res://LICENSES/OFL-BarlowCondensed.txt",
			"res://assets/audio/title_call.ogg"]:
		check(ResourceLoader.exists(path) or FileAccess.file_exists(path), "asset exists: " + path)
	var brief_tex: Texture2D = load("res://assets/ui/briefing_bg.jpg")
	var map_tex: Texture2D = load("res://assets/ui/travel_map.jpg")
	check(brief_tex != null and brief_tex.get_width() == 1920 and brief_tex.get_height() == 1080, "briefing art is 1920x1080")
	check(map_tex != null and map_tex.get_width() == 1920 and map_tex.get_height() == 1080, "travel map art is 1920x1080")
	var ofl := FileAccess.get_file_as_string("res://LICENSES/OFL-BarlowCondensed.txt")
	check(ofl.contains("SIL Open Font License") and ofl.contains("Barlow"), "OFL licence is bundled with Barlow Condensed")
	var f := UiStyle.font("bold")
	check(f != null and f.get_string_size("SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x > 10.0, "Barlow Condensed Bold loads")
	var s := Scores.load_settings()
	check(s.has("seen_briefing") and not bool(s.seen_briefing), "briefing is unseen on a fresh profile")
	# Briefing types and skips.
	var b := BriefingScreen.new(); root.add_child(b); await frames(3)
	check(b.shown == 0 and not b.done, "briefing starts empty")
	b.chars = 20; await frames(2)
	check(b.shown == 0 and int(b.chars) > 0, "briefing types the first paragraph")
	b.skip()
	check(b.done and b.shown == BriefingScreen.LINES.size(), "skip reveals the full briefing")
	check(BriefingScreen.LINES[2].contains("Lock and load"), "briefing ends on the mission orders")
	# Travel map after stage 1.
	var mscr := TravelMapScreen.new(); root.add_child(mscr); await frames(2)
	mscr.setup(1, false)
	check(mscr.current_number() == 1, "after stage 1 the current pin is River Village")
	check(str(mscr.next_entry().get("name", "")) == "Dune Sea", "next stage is Dune Sea")
	check(mscr.hint_text().contains("DUNE SEA") and not mscr.hint_text().contains("COMING SOON"), "after stage 1 the map offers Dune Sea as the next playable stage")
	mscr.setup(2, false)
	check(mscr.current_number() == 2, "after stage 2 the current pin is Dune Sea")
	check(str(mscr.next_entry().get("name", "")) == "Coral Coast", "next stage after Dune Sea is Coral Coast")
	check(mscr.hint_text().contains("CORAL COAST") and mscr.hint_text().contains("COMING SOON"), "map says Next: Coral Coast — coming soon")
	mscr.setup(0, true)
	check(mscr.preview and mscr.hint_text().contains("EMBER RING"), "preview map names the Ember Ring route")
	# Main scene wiring: a single START button; first play opens the briefing.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	check(main.mode == "title", "main starts on the title")
	check(str(main.title_screen.subtitle).contains("EMBER RING"), "title subtitle mentions the Ember Ring")
	check(main.briefing != null and main.travel_map != null, "briefing and travel map screens exist")
	check(main.theme != null and main.theme.default_font == UiStyle.font("semibold"), "menus use Barlow Condensed")
	check(main.title_screen.GLOBAL_URL == "https://firebreak.quietbytehq.uk", "global scores URL is the public board")
	check(main.title_screen.global_hit(Vector2(1650, 980)) and not main.title_screen.global_hit(Vector2(200, 200)), "GLOBAL SCORES has a click target")
	var src := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(src.contains("func open_global_scores") and src.contains("OS.shell_open(\"https://firebreak.quietbytehq.uk\")"), "GLOBAL SCORES opens the site in the system browser")
	check(not src.contains("_button(box, \"Story\""), "the title has no separate Story button")
	Scores.add_score("TESTER", 12500, 1)
	main.title_screen.refresh_scores()
	check(main.title_screen.local_scores.size() >= 1 and int(main.title_screen.local_scores[0].score) == 12500, "title shows local high scores")
	main.show_title(true)
	await frames(2)
	var labels: Array = []
	collect_button_text(main.menu_root, labels)
	check("START" in labels, "the only start option is labelled START")
	check(not ("Story" in labels) and not ("Start mission" in labels), "Story and Start mission are not title buttons")
	main.start_mission()
	await frames(3)
	check(main.mode == "briefing" and main.briefing.visible, "first start opens the briefing")
	main.briefing.skip()
	main._on_briefing_finished()
	await frames(4)
	check(main.mode == "playing", "finishing the first briefing starts stage 1")
	# seen_briefing is not saved under QA, but a direct start after marking should skip.
	main.settings.seen_briefing = true
	main.show_title(true)
	await frames(2)
	main.start_mission()
	await frames(4)
	check(main.mode == "playing", "later starts skip the briefing")
	main.show_briefing("story")
	await frames(2)
	check(main.mode == "briefing", "F1 / show_briefing(story) opens the briefing")
	main.briefing.skip()
	main._on_briefing_finished()
	await frames(3)
	check(main.mode == "travel_map" and main.travel_map.visible, "story rewatch continues to the travel map")
	check(main.travel_map.preview, "story map is a preview")
	main._on_travel_map_finished()
	await frames(2)
	check(main.mode == "title" and main.title_menu_open, "leaving the preview map returns to the title menu")
	# Rewatch from pause returns to the pause menu, not the map.
	main.settings.seen_briefing = true
	main.start_mission()
	await frames(4)
	check(main.mode == "playing", "can start a stage to test the pause rewatch")
	main.pause_game()
	await frames(2)
	check(main.mode == "paused", "pause menu opens")
	main.show_briefing("pause")
	await frames(2)
	check(main.mode == "briefing", "pause Story briefing opens the briefing")
	main.briefing.skip()
	main._on_briefing_finished()
	await frames(3)
	check(main.mode == "paused", "finishing a pause briefing returns to pause")
	main.show_travel_map("after_clear", 1)
	await frames(2)
	check(main.travel_map.hint_text().contains("DUNE SEA") and not main.travel_map.hint_text().contains("COMING SOON"), "clearing stage 1 offers Dune Sea next")
	main._on_travel_map_finished()
	await frames(2)
	check(main.mode == "store", "continuing after a clear opens the store")
	print("Story: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
