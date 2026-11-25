extends SceneTree
## 0.5.1 review shots: Stage 1 mid/far outlines, and both stage starts
## with the title card and with the radio plate (never overlapping).
const Scores := preload("res://scripts/scores.gd")
const StageData := preload("res://scripts/stage_data.gd")

func _initialize() -> void:
	call_deferred("run")

func frames(n: int) -> void:
	for i in n:
		await process_frame

func capture(main: Node, path: String) -> void:
	await frames(6)
	var img := main.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("wrote ", path, " ", img.get_width(), "x", img.get_height())

func pose_soldiers(main: Node) -> void:
	main.sim.stage.ambient = []
	main.sim.stage.waves = []
	main.sim.camera_x = 0.0
	# A far, a mid and a near rifleman plus an MG, fully risen, in view.
	var spots: Array = []
	var pfar: Vector2 = main.sim.pick_point("far", 120.0, 0.22)
	if pfar.x >= 0.0:
		spots.append(["rifleman", "far", pfar.x, pfar.y])
	var pmid: Vector2 = main.sim.pick_point("mid", 120.0, 0.32)
	if pmid.x >= 0.0:
		spots.append(["rifleman", "mid", pmid.x, pmid.y])
	var pnear: Vector2 = main.sim.pick_point("near", 120.0, 0.50)
	if pnear.x >= 0.0:
		spots.append(["rifleman", "near", pnear.x, pnear.y])
	var pmg: Vector2 = main.sim.pick_point("mid", 120.0, 0.68)
	if pmg.x >= 0.0:
		spots.append(["mg", "mid", pmg.x, pmg.y])
	# Fall back to the known v050d placements if a band has no land in view.
	if spots.size() < 4:
		spots = [["rifleman", "mid", 620.0, 752.0], ["rifleman", "near", 980.0, 900.0], ["mg", "mid", 1280.0, 760.0]]
		var fb: Vector2 = main.sim.pick_point("far", 80.0)
		if fb.x >= 0.0:
			spots.append(["rifleman", "far", fb.x, fb.y])
	for item in spots:
		var e: Dictionary = main.sim.spawn(str(item[0]), str(item[1]), {"world_x": item[2], "world_y": item[3]})
		if not e.is_empty():
			e.rise = 1.0
			e.state = "aim"
			e.timer = 8.0
			e.wading = false
			e.submerge = 0.0
	print("posed ", spots.size(), " stage 1 figures")

func start_line_for(stage: int) -> String:
	# Use whatever reset() would have queued, or a known opening line.
	return ""

func run() -> void:
	var out := str(OS.get_environment("FIREBREAK_SHOT_DIR"))
	if out == "":
		out = "/tmp/firebreak_v051"
	DirAccess.make_dir_recursive_absolute(out)
	Scores.save_player_name("ACE")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(16)
	main.settings.fullscreen = false
	main.settings.airstrike_hint_seen = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	main.qa = {"seed": 17}

	# --- Stage 1 start: title card, then the radio plate after it fades ---
	main.begin_run()
	main.start_stage(1)
	await frames(8)
	# Mid-title: the plate must not cover the letters.
	if main.view:
		main.view.title_card = main.view.title_card_max * 0.55
	await capture(main, out.path_join("stage1_title.png"))
	print("s1 title_card=", main.view.title_card if main.view else -1, " radio='", main.dialogue.text() if main.dialogue else "", "'")
	# After the title is gone, show the opening line.
	if main.view:
		main.view.title_card = 0.0
	if main.dialogue:
		if main.dialogue.text() == "":
			main.dialogue.reset(1)
		main.dialogue.current.life = 8.0
	await capture(main, out.path_join("stage1_dialogue.png"))
	print("s1 dialogue='", main.dialogue.text() if main.dialogue else "", "'")

	# --- Stage 1 outlines ---
	pose_soldiers(main)
	if main.view:
		main.view.title_card = 0.0
	if main.dialogue:
		main.dialogue.current = {}
		main.dialogue.queue.clear()
	await frames(10)
	await capture(main, out.path_join("stage1_outlines.png"))

	# --- Coral Coast start: title, then radio ---
	main.begin_run()
	main.settings.airstrike_hint_seen = true
	main.start_stage(3)
	await frames(8)
	if main.view:
		main.view.title_card = main.view.title_card_max * 0.55
	await capture(main, out.path_join("coral_title.png"))
	print("coral title_card=", main.view.title_card if main.view else -1, " radio='", main.dialogue.text() if main.dialogue else "", "'")
	if main.view:
		main.view.title_card = 0.0
	if main.dialogue:
		if main.dialogue.text() == "":
			main.dialogue.reset(3)
		main.dialogue.current.life = 8.0
	await capture(main, out.path_join("coral_dialogue.png"))
	print("coral dialogue='", main.dialogue.text() if main.dialogue else "", "'")

	# A far wader in the opening bay, plus a mid rifleman on the sand, for review.
	main.sim.stage.ambient = []
	main.sim.stage.waves = []
	main.sim.camera_x = 0.0
	var far: Dictionary = main.sim.spawn("rifleman", "far", {"world_x": 409.0})
	var far2: Dictionary = main.sim.spawn("rifleman", "far", {"world_x": 524.0})
	print("far_wading=", int(bool(far.get("wading", false))), ",", int(bool(far2.get("wading", false))),
		" y=", int(float(far.get("y", 0))), ",", int(float(far2.get("y", 0))))
	await capture(main, out.path_join("coral_far_waders.png"))

	print("shot_v051 done")
	quit(0)
