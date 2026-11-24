extends SceneTree
## Captures Coral Coast start, mid, pier, boss arena and result, and samples fps.
const Scores := preload("res://scripts/scores.gd")
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
	# Skip just before the beat, then step a few seconds so nearby waves appear.
	sim.skip_to(maxf(0.0, at - 8.0))
	var need: float = at - float(sim.time)
	while need > 0.0 and sim.state == "playing":
		var dt := minf(0.05, need)
		sim.health = sim.max_health
		sim.step(dt)
		need -= dt
func run() -> void:
	var out := OS.get_environment("FIREBREAK_SHOT_DIR")
	if out == "":
		printerr("FIREBREAK_SHOT_DIR is not set")
		quit(1)
		return
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
	main.qa = {"stage": 3, "seed": 21}
	main.begin_run()
	main.start_stage(3)
	await frames(12)
	var fps_all: Array = []
	# Start (open bay).
	populate(main.sim, 10.0)
	main.sim.health = main.sim.max_health
	await frames(8)
	fps_all.append(await sample_fps(main, "start"))
	await capture(main, out.path_join("start.png"))
	# Mid beach / town (jeep beat).
	populate(main.sim, 62.0)
	main.sim.health = main.sim.max_health
	await frames(8)
	fps_all.append(await sample_fps(main, "mid"))
	await capture(main, out.path_join("mid.png"))
	# Pier.
	populate(main.sim, 108.0)
	main.sim.health = main.sim.max_health
	await frames(8)
	fps_all.append(await sample_fps(main, "pier"))
	await capture(main, out.path_join("pier.png"))
	# Boss arena. No autopilot, so the gunboat stays up for the shot.
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
		main.sim.spawn("gunboat", "mid")
	await frames(8)
	fps_all.append(await sample_fps(main, "boss"))
	await capture(main, out.path_join("boss.png"))
	# Wreck and result.
	var gun := {}
	for e in main.sim.entities:
		if e.type == "gunboat":
			gun = e
			break
	if not gun.is_empty():
		var pos := Vector2(gun.x - main.sim.camera_x, gun.y - 40.0)
		main.sim.damage_entity(gun, 999.0, pos, true)
	for i in 50:
		if main.sim.state == "playing":
			main.sim.step(0.05)
	await frames(20)
	if main.has_method("show_result") and main.sim.state != "playing":
		main.show_result()
	await frames(16)
	await capture(main, out.path_join("result.png"))
	var meds := []
	for d in fps_all:
		meds.append("%s=%.1f" % [d.label, d.median])
	print("FPS SUMMARY ", " ".join(meds))
	print("SHOTS OK")
	quit(0)
