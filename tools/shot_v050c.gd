extends SceneTree
## Captures Coral Coast wading, beach civilians, the civilian warning, the
## continue screen and the bigger harbour boss, and samples fps.
const Scores := preload("res://scripts/scores.gd")
const Ground := preload("res://scripts/stage_ground.gd")
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
func sample_fps(main: Node, label: String, n: int = 90) -> Dictionary:
	var times: Array = []
	var samples: Array = []
	var last := Time.get_ticks_usec()
	for i in n:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000000.0)
		last = now
		samples.append(Engine.get_frames_per_second())
	times.sort()
	var mid: float = float(times[times.size() / 2])
	var fps_med := (1.0 / mid) if mid > 0.0 else 0.0
	var eng := 0.0
	for s in samples:
		eng += float(s)
	eng /= maxf(1.0, float(samples.size()))
	print("FPS ", label, " median_frame=", snapped(fps_med, 0.1), " engine_avg=", snapped(eng, 0.1))
	return {"label": label, "median": fps_med, "engine_avg": eng}
func populate(sim, at: float) -> void:
	sim.skip_to(maxf(0.0, at - 8.0))
	var need: float = at - float(sim.time)
	while need > 0.0 and sim.state == "playing":
		var dt := minf(0.05, need)
		sim.health = sim.max_health
		sim.step(dt)
		need -= dt
func run() -> void:
	var out := str(OS.get_environment("FIREBREAK_SHOT_DIR"))
	if out == "":
		out = "/tmp/firebreak_v050c"
	DirAccess.make_dir_recursive_absolute(out)
	Scores.save_player_name("ACE")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(16)
	main.settings.fullscreen = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	main.qa = {"seed": 17}  # no autopilot
	main.begin_run()
	main.start_stage(3)
	await frames(12)
	var fps_all: Array = []
	# Beach civilians, early in the stage, on the mid sand.
	main.sim.camera_x = 0.0
	for i in 5:
		var v: Dictionary = main.sim.spawn("villager", "mid")
		if v.is_empty():
			break
		v.vx = 50.0
		v.facing = 1.0
	for i in 20:
		main.sim.step(1.0 / 60.0)
	await frames(8)
	fps_all.append(await sample_fps(main, "beach", 60))
	await capture(main, out.path_join("civilians_beach.png"))
	# Civilian warning after the first kill.
	var civ := {}
	for e in main.sim.entities:
		if e.type == "villager" and e.state != "dying":
			civ = e
			break
	if civ.is_empty():
		civ = main.sim.spawn("villager", "mid")
	if not civ.is_empty():
		main.sim.damage_entity(civ, 99.0, Vector2(civ.x - main.sim.camera_x, civ.y - 80.0))
	await frames(10)
	await capture(main, out.path_join("civilian_warning.png"))
	# Continue screen after two more civilian kills.
	for i in 2:
		var v2: Dictionary = main.sim.spawn("villager", "mid")
		if v2.is_empty():
			v2 = main.sim.spawn("villager", "near")
		if not v2.is_empty():
			main.sim.damage_entity(v2, 99.0, Vector2(v2.x - main.sim.camera_x, v2.y - 80.0))
	if main.sim.state == "failed":
		main.show_result()
	await frames(16)
	await capture(main, out.path_join("continue.png"))
	# Fresh playing stage for the wading and boss shots.
	main.begin_run()
	main.start_stage(3)
	await frames(8)
	# Wading enemies in the mid bay, camera at the pier approach.
	populate(main.sim, 90.0)
	main.sim.health = main.sim.max_health
	var waders := 0
	var p: Vector2 = main.sim.pick_water_point("mid", 200.0)
	if p.x >= 0.0:
		for k in 4:
			var wx := p.x - 80.0 + k * 70.0
			if Ground.in_water(main.sim.stage, "mid", wx, "rifleman"):
				var e: Dictionary = main.sim.spawn("rifleman", "mid", {"world_x": wx})
				if not e.is_empty() and bool(e.get("wading", false)):
					waders += 1
	print("wading_spawned=", waders, " camera_x=", int(main.sim.camera_x))
	await frames(8)
	fps_all.append(await sample_fps(main, "wading", 60))
	await capture(main, out.path_join("wading.png"))
	# Boss, no autopilot.
	populate(main.sim, 146.0)
	main.sim.health = main.sim.max_health
	var found := false
	for i in 60:
		if main.sim.state != "playing":
			break
		for e in main.sim.entities:
			if e.type == "gunboat" and e.state != "dying":
				found = true
				break
		if found:
			break
		main.sim.step(0.05)
	if not found:
		main.sim.spawn("gunboat", "mid", {"scale": 0.95})
	# Near figures in the harbour must wade at the shore, never stand on the bags.
	var removed := 0
	var kept: Array = []
	for e in main.sim.entities:
		if e.type == "rifleman" and str(e.get("band", "")) in ["near", "mid"] and e.state != "dying":
			if Ground.water_under_or_behind(main.sim.stage, str(e.band), float(e.x), "rifleman") and not bool(e.get("wading", false)):
				removed += 1
				continue
		kept.append(e)
	main.sim.entities = kept
	var near_waders := 0
	for wx in [2280.0, 2680.0, 3100.0]:
		if Ground.water_under_or_behind(main.sim.stage, "near", wx, "rifleman"):
			var e2: Dictionary = main.sim.spawn("rifleman", "near", {"world_x": wx})
			if not e2.is_empty() and bool(e2.get("wading", false)):
				near_waders += 1
	print("boss_removed_dry_on_water=", removed, " near_waders=", near_waders, " camera_x=", int(main.sim.camera_x))
	await frames(8)
	fps_all.append(await sample_fps(main, "boss"))
	await capture(main, out.path_join("boss.png"))
	var meds := []
	for d in fps_all:
		meds.append("%s=%.1f" % [d.label, d.median])
	print("FPS SUMMARY ", " ".join(meds))
	print("SHOTS OK")
	quit(0)
