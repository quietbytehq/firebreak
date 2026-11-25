extends SceneTree
## Civilians walk only on land, facing the way they move. Killing 3 fails any stage.
const StageSim := preload("res://scripts/stage_sim.gd")
const StageData := preload("res://scripts/stage_data.gd")
const Ground := preload("res://scripts/stage_ground.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")

func fresh(stage: int, seed: int = 5):
	var sim = StageSim.new()
	sim.setup(stage, seed)
	sim.stage.ambient = []
	sim.stage.waves = []
	return sim

func run() -> void:
	for n in [1, 2, 3]:
		_spawns_on_land(n)
		_paths_stay_on_land(n)
	_facing_matches_velocity()
	_fail_on_three()
	_warning_counts()
	print("Civilians: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)

func _spawns_on_land(n: int) -> void:
	var s := StageData.load_stage(n)
	var sim = fresh(n)
	var max_x := float(s.get("world_width", 3840)) - 1920.0
	var ok := 0
	var tried := 0
	var cam := 0.0
	while cam <= max_x + 1.0:
		sim.camera_x = cam
		for band in ["far", "mid"]:
			var p: Vector2 = sim.pick_point(band, 140.0)
			if p.x < 0.0:
				continue
			tried += 1
			var e: Dictionary = sim.spawn("villager", band, {"world_x": p.x})
			if e.is_empty():
				continue
			if Ground.on_land(s, str(e.band), e.x) and not bool(e.get("wading", false)):
				ok += 1
			sim.entities.erase(e)
		cam += 240.0
	check(tried >= 6, "stage %d produced civilian spawns across the scroll (%d)" % [n, tried])
	check(ok == tried and tried > 0, "stage %d: every civilian spawn sits on land (%d/%d)" % [n, ok, tried])

func _paths_stay_on_land(n: int) -> void:
	var sim = fresh(n, 9)
	sim.camera_x = 0.0
	var e: Dictionary = sim.spawn("villager", "mid")
	if e.is_empty():
		sim.camera_x = 200.0
		e = sim.spawn("villager", "near")
	check(not e.is_empty(), "stage %d can spawn a civilian to walk" % n)
	if e.is_empty():
		return
	var wet := 0
	for i in 240:
		sim.step(1.0 / 60.0)
		if not sim.entities.has(e):
			break
		if not Ground.on_land(sim.stage, str(e.band), e.x):
			wet += 1
	check(wet == 0, "stage %d civilian path stays on land (%d off-land samples)" % [n, wet])

func _facing_matches_velocity() -> void:
	for n in [1, 2, 3]:
		var sim = fresh(n, 3)
		sim.camera_x = 0.0
		var e: Dictionary = sim.spawn("villager", "mid")
		if e.is_empty():
			continue
		var bad := 0
		for i in 180:
			sim.step(1.0 / 60.0)
			if not sim.entities.has(e):
				break
			if absf(e.vx) > 1.0:
				var expect := -1.0 if e.vx < 0.0 else 1.0
				if e.facing != expect:
					bad += 1
		check(bad == 0, "stage %d civilian facing matches velocity (%d mismatches)" % [n, bad])

func _fail_on_three() -> void:
	for n in [1, 2, 3]:
		var sim = fresh(n)
		sim.camera_x = 0.0
		var hits := []
		sim.event.connect(func(name, data):
			if name == "villager_hit":
				hits.append(data)
			)
		for i in 3:
			var v: Dictionary = sim.spawn("villager", "mid")
			if v.is_empty():
				v = sim.spawn("villager", "near")
			check(not v.is_empty(), "stage %d spawned civilian %d" % [n, i + 1])
			if v.is_empty():
				return
			sim.damage_entity(v, 99.0, Vector2(v.x - sim.camera_x, v.y - 40.0))
			if i < 2:
				check(sim.state == "playing", "stage %d still plays after %d civilian(s)" % [n, i + 1])
		check(sim.state == "failed", "stage %d fails after 3 civilian kills" % n)
		check(sim.end_reason == "civilians", "stage %d end reason is civilians" % n)
		check(int(sim.stats.villagers_hit) == 3, "stage %d counted 3 civilian hits" % n)
		check(hits.size() == 3, "stage %d emitted 3 villager_hit events" % n)

func _warning_counts() -> void:
	var sim = fresh(3)
	var counts := []
	sim.event.connect(func(name, data):
		if name == "villager_hit":
			counts.append(int(data.get("count", -1)))
		)
	for i in 2:
		var v: Dictionary = sim.spawn("villager", "mid")
		if v.is_empty():
			v = sim.spawn("villager", "near")
		sim.damage_entity(v, 99.0, Vector2(v.x - sim.camera_x, v.y - 40.0))
	check(counts == [1, 2], "warnings carry the 1/3 and 2/3 counts %s" % str(counts))
	check(sim.state == "playing", "two civilian kills do not fail the stage")
