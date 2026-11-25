extends SceneTree
## Coral Coast (stage 3): data, new enemies, arena boss, quota and campaign hooks.
const StageData := preload("res://scripts/stage_data.gd")
const StageSim := preload("res://scripts/stage_sim.gd")
const Ground := preload("res://scripts/stage_ground.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s := StageData.load_stage(3)
	check(not s.is_empty(), "Coral Coast loads")
	check(StageData.validate(s).is_empty(), "Coral Coast validates: " + str(StageData.validate(s)))
	check(float(s.duration) == 180.0, "Coral Coast is 3 minutes")
	check(str(s.music) == "music_coral_coast", "Coral Coast uses Caribbean Steel Drums 2")
	check(str(s.ambience) == "ambience_coral", "Coral Coast uses the bay ambience")
	check(float(s.get("shimmer", 0.0)) == 0.0, "heat shimmer is off")
	check(s.has("arena") and str(s.arena.get("type", "")) == "gunboat", "arena block names the gunboat")
	check(float(s.arena.get("t", 0.0)) == 140.0, "arena starts at 2:20")
	check(ResourceLoader.exists(str(s.background)) or FileAccess.file_exists(str(s.background)), "Coral Coast background file exists")
	var tex: Texture2D = load(str(s.background))
	check(tex != null and tex.get_width() == 3840 and tex.get_height() == 1080, "Coral Coast background is 3840x1080")
	check(s.has("ground") and (s.ground.near.points as Array).size() >= 2, "Coral Coast has a near ground map")
	check(s.has("roads") and (s.roads.track.points as Array).size() >= 2, "Coral Coast has a coast track")
	check((s.roads.water.points as Array).size() >= 2, "Coral Coast has a water path")
	check((s.roads.pier.points as Array).size() >= 2, "Coral Coast has a pier path")
	var g1: Array = s.ground.near.points[0]
	check(float(g1[1]) <= 940.0, "near ground stays above the HUD lip")
	var types := {}
	var has_heli := false
	for w in s.waves:
		types[str(w.type)] = true
		if str(w.type) == "heli": has_heli = true
	check(not has_heli, "Coral Coast has no helicopter")
	for typ in ["rifleman", "speedboat", "jeep", "pier_gunner", "gunboat", "food", "villager"]:
		var in_waves := types.has(typ)
		var in_amb := false
		for r in s.ambient:
			if str(r.type) == typ: in_amb = true
		check(in_waves or in_amb, "Coral Coast uses " + typ)
	check(FileAccess.file_exists("res://assets/audio/music_coral_coast.ogg"), "Steel Drums 2 is shipped")
	check(FileAccess.file_exists("res://assets/audio/ambience_coral.ogg"), "coral ambience is shipped")
	check(FileAccess.file_exists("res://assets/audio/speedboat_loop.ogg"), "speedboat loop is shipped")
	check(FileAccess.file_exists("res://assets/audio/jeep_idle.ogg"), "jeep idle is shipped")
	check(FileAccess.file_exists("res://assets/audio/gunboat_engine.ogg"), "gunboat engine is shipped")

	var sim := StageSim.new()
	check(sim.setup(3, 7), "sim starts Coral Coast")
	check(sim.quota == 128, "computed quota is 128 (116 x 1.10, rounded)")
	check(sim.stage_number == 3, "stage number is 3")
	check(sim.has_arena(), "sim sees the arena")
	check(sim.diff.fire_rate > StageData.difficulty(3).fire_rate, "Coral Coast fire rate is boosted on top of the campaign curve")
	check(is_equal_approx(float(sim.diff.fire_rate) / float(StageData.difficulty(3).fire_rate), 1.15), "fire rate boost is +15%")

	var boat: Dictionary = sim.spawn("speedboat", "mid")
	check(not boat.is_empty(), "speedboat spawns")
	check(boat.max_hp == 9.0, "speedboat HP is 8 x 1.10, rounded to 9")
	check(int(StageSim.BASE_SCORE.speedboat) % 10 == 0, "speedboat score is a multiple of 10")
	check(Ground.road_for("speedboat", "mid") == "water", "speedboats use the water path")
	var b2: Dictionary = sim.spawn("speedboat", "mid")
	check(not b2.is_empty() and sim.count_alive("speedboat") == 2, "two speedboats can be alive")

	var jeep: Dictionary = sim.spawn("jeep", "mid")
	check(not jeep.is_empty(), "jeep spawns")
	check(jeep.max_hp == 12.0, "jeep HP is 11 x 1.10, rounded to 12")
	check(jeep.get("gunner_alive", false), "jeep has a bed gunner")
	check(Ground.road_for("jeep", "mid") == "track", "jeeps use the coast track")
	check(int(StageSim.BASE_SCORE.jeep) % 10 == 0, "jeep score is a multiple of 10")

	var pier: Dictionary = sim.spawn("pier_gunner", "mid", {"world_x": 2280.0, "world_y": 800.0, "scale": 0.50})
	check(not pier.is_empty() and pier.max_hp == 3.0, "pier gunner has 3 HP after difficulty")
	check(pier.get("planted", false), "pier gunner is planted on the planks")
	check(int(StageSim.BASE_SCORE.pier_gunner) % 10 == 0, "pier gunner score is a multiple of 10")

	var civ: Dictionary = sim.spawn("villager", "mid")
	check(not civ.is_empty(), "town civilian spawns")
	check(str(civ.kind).begins_with("town_"), "civilian uses a town kind")
	var food: Dictionary = sim.spawn("food", "sky", {"kind": "mango"})
	check(not food.is_empty() and food.kind == "mango", "mango pickup spawns")

	# Quota and time must not clear the stage before the gunboat is down.
	sim.kills = sim.quota
	sim.step(0.05)
	check(sim.state == "playing", "meeting the quota does not clear the harbour arena")
	sim.time = 180.0
	sim.step(0.05)
	check(sim.state == "playing", "reaching 3:00 does not clear the harbour arena")
	sim.kills = 0
	sim.time = 0.0
	sim.camera_x = 0.0

	# Boss: skip to the harbour hold, spawn, wreck, clear.
	var boss_sim := StageSim.new()
	check(boss_sim.setup(3, 11), "second sim starts Coral Coast")
	boss_sim.skip_to(140.0)
	for i in 80:
		boss_sim.step(0.05)
	var gun := {}
	for e in boss_sim.entities:
		if e.type == "gunboat":
			gun = e
			break
	check(not gun.is_empty(), "gunboat spawns at the harbour hold")
	if not gun.is_empty():
		check(gun.max_hp == 33.0, "gunboat HP is 30 x 1.10, rounded to 33")
		check(gun.get("gunner_alive", false), "gunboat has a bow gunner")
		check(gun.get("gunner2_alive", false), "gunboat has a second deck gunner")
		check(str(gun.get("band", "")) == "mid", "gunboat stays on the mid water path, not the far shore")
		check(str(gun.get("path", "")) == "water", "gunboat path is the close harbour water")
		check(gun.y >= 740.0, "gunboat sits in the deep basin (y=%.1f)" % gun.y)
		check(gun.scale >= 0.9, "gunboat is the larger close scale")
		check(int(StageSim.BASE_SCORE.gunboat) % 10 == 0, "gunboat score is a multiple of 10")
		# Time running past the planned 180 s still does not clear while it lives.
		boss_sim.time = 180.0
		boss_sim.step(0.1)
		check(boss_sim.state == "playing", "time past 3:00 does not clear while the gunboat lives")
		# Wreck the hull with a blast so the bow gunner does not soak the shot.
		var pos := Vector2(gun.x - boss_sim.camera_x, gun.y - 40.0)
		boss_sim.damage_entity(gun, 999.0, pos, true)
		check(boss_sim.arena_sink > 0.0, "destroying the gunboat starts the wreck delay")
		check(boss_sim.state == "playing", "the stage holds during the wreck")
		for i in 40:
			boss_sim.step(0.05)
		check(boss_sim.state == "cleared", "stage clears after the gunboat wrecks")
		check(boss_sim.end_reason == "boss", "clear reason is the boss")
	check(StageData.next_playable(2) == 3, "campaign offers Coral Coast after Dune Sea")
	print("Coral Coast: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
