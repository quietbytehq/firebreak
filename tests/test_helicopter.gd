extends SceneTree
## Enemy Huey-style helicopter: flies in, door gunner fires, shooting the
## gunner silences it, enough hits make it smoke then crash in flames.
const StageSim := preload("res://scripts/stage_sim.gd")
const StageData := preload("res://scripts/stage_data.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func fresh():
	var sim = StageSim.new(); sim.setup(1, 21); sim.stage.ambient = []; sim.stage.waves = []
	return sim
func run() -> void:
	var sim = fresh()
	var h: Dictionary = sim.spawn("heli", "sky", {"from": "right"})
	check(not h.is_empty() and h.type == "heli", "helicopter spawns")
	check(h.sx > 1920.0 and h.vx < 0.0 and h.facing < 0.0, "enters from the right, flying left")
	check(h.gunner_alive and h.max_hp >= 16.0, "has a door gunner and a tough airframe")
	var cnt := {"fire": 0, "after": 0, "silenced": false, "explosions": 0, "smoke": 0, "down": 0}
	sim.event.connect(func(n, d):
		if n == "enemy_fire" and d.entity == h:
			cnt.fire += 1
			if cnt.silenced: cnt.after += 1
		if n == "explosion": cnt.explosions += 1
		if n == "heli_smoking": cnt.smoke += 1
		if n == "heli_down": cnt.down += 1)
	for i in 60 * 8: sim.step(1.0 / 60.0)
	check(h.state == "hover", "slows to hover over the battlefield")
	check(h.sx > 300.0 and h.sx < 1620.0, "hovers on screen (%.0f)" % h.sx)
	check(cnt.fire > 3, "door gunner fires bursts (%d shots)" % cnt.fire)
	# Shoot the gunner.
	var gr: Rect2 = sim.gunner_rect(h)
	check(sim.entity_at(gr.get_center()) == h, "crosshair over the doorway targets the helicopter")
	var hp0: float = h.hp
	var shots := 0
	while h.gunner_alive and shots < 10:
		sim.fire_cooldown = 0.0; sim.reload_timer = 0.0; sim.ammo = 30
		sim.fire(sim.gunner_rect(h).get_center()); shots += 1
	check(not h.gunner_alive, "shooting the door gunner takes him out (%d shots)" % shots)
	check(h.hp == hp0, "gunner hits don't damage the airframe")
	cnt.silenced = true
	for i in 60 * 4: sim.step(1.0 / 60.0)
	check(cnt.after == 0, "a silenced helicopter stops firing")
	# Shoot the body until it smokes, then crashes.
	var body_pt := Vector2(h.x - sim.camera_x - 150.0 * h.facing * h.scale, h.y + 20.0)
	check(not sim.gunner_rect(h).has_point(body_pt), "body aim point is away from the doorway")
	var kills0: int = sim.kills
	var guard := 0
	while h.state != "crash" and guard < 60:
		sim.fire_cooldown = 0.0; sim.reload_timer = 0.0; sim.ammo = 30
		body_pt = Vector2(h.x - sim.camera_x - 150.0 * h.facing * h.scale, h.y + 20.0)
		sim.fire(body_pt); guard += 1
		if h.hp <= h.max_hp * 0.5 and h.hp > 0.0 and not cnt.has("smoke_checked"):
			cnt.smoke_checked = true
			check(h.get("smoking", false), "smokes once badly damaged")
	check(cnt.smoke == 1, "smoking event fired once")
	check(h.state == "crash", "enough hits bring it down (%d hits)" % guard)
	check(sim.kills == kills0 + 1 and cnt.down == 1, "a downed helicopter counts as one kill")
	check(not sim.is_hittable(h), "a crashing helicopter cannot be shot again")
	var y0: float = h.y
	for i in 60 * 3: sim.step(1.0 / 60.0)
	check(not sim.entities.has(h), "crashed helicopter is removed")
	check(cnt.explosions >= 1, "the crash ends in an explosion")
	# Unharmed helicopter eventually leaves.
	sim = fresh(); sim.diff.accuracy = 0.0
	var h2: Dictionary = sim.spawn("heli", "sky", {"from": "left"})
	check(h2.vx > 0.0 and h2.facing > 0.0, "can also enter from the left")
	for i in 60 * 30: sim.step(1.0 / 60.0)
	check(not sim.entities.has(h2) and h2.escaped, "an untouched helicopter flies away")
	# Stage and difficulty data.
	var stage := StageData.load_stage(1)
	var passes := 0
	for w in stage.waves:
		if w.type == "heli": passes += 1
	check(passes >= 1 and passes <= 2, "stage 1 has 1-2 helicopter passes (%d)" % passes)
	check(StageData.validate(stage).is_empty(), "stage with helicopter waves validates")
	var s12 = StageSim.new(); s12.setup(1, 1, stage.duplicate(true)); s12.stage_number = 12; s12.diff = StageData.difficulty(12)
	var h12: Dictionary = s12.spawn("heli", "sky")
	check(h12.max_hp > h.max_hp, "helicopters are tougher in later stages (%d vs %d)" % [int(h12.max_hp), int(h.max_hp)])
	check(float(s12.diff.accuracy) > float(StageData.difficulty(1).accuracy), "door gunner accuracy scales with the stage")
	print("Helicopter: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
