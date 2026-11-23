extends SceneTree
## Ground contact along the panorama, moving-sprite facing vs velocity,
## and vehicles / camels staying on their paths.
const StageSim := preload("res://scripts/stage_sim.gd")
const StageData := preload("res://scripts/stage_data.gd")
const Ground := preload("res://scripts/stage_ground.gd")
const SpriteArt := preload("res://scripts/sprite_art.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")

func fresh(stage: int):
	var sim = StageSim.new()
	sim.setup(stage, 7)
	sim.stage.ambient = []
	sim.stage.waves = []
	return sim

func run() -> void:
	for n in [1, 2]:
		var s := StageData.load_stage(n)
		check(StageData.validate(s).is_empty(), "stage %d still validates with the ground map" % n)
		_ground_contact(n, s)
		_no_water(n, s)
	_paratrooper_lands()
	_facing_vs_velocity()
	_vehicles_on_path()
	_camels_on_sand()
	_snipers_stay_planted()
	_near_body_visible()
	print("Ground: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)

func _ground_contact(stage_n: int, s: Dictionary) -> void:
	var sim = fresh(stage_n)
	# Walk the camera along the scroll and spawn each ground band in view.
	var max_x := float(s.get("world_width", 3840)) - 1920.0
	var ok := 0
	var tried := 0
	var cam := 0.0
	while cam <= max_x + 1.0:
		sim.camera_x = cam
		for band in ["far", "mid", "near"]:
			var p: Vector2 = sim.pick_point(band, 140.0)
			if p.x < 0.0:
				continue
			tried += 1
			var e: Dictionary = sim.spawn("rifleman", band, {"world_x": p.x})
			var gy := Ground.ground_y(s, band, e.x)
			if absf(e.y - gy) <= 1.5 and Ground.on_ground(s, band, e.x):
				ok += 1
			sim.entities.erase(e)
		cam += 240.0
	check(tried >= 8, "stage %d produced ground spawns across the scroll (%d)" % [stage_n, tried])
	check(ok == tried and tried > 0, "stage %d: every unplanted spawn sits on its band ground (%d/%d)" % [stage_n, ok, tried])

func _no_water(stage_n: int, s: Dictionary) -> void:
	# Mid and far spans must not cover the known water: river village 1350-2300,
	# Dune Sea oasis 1550-2180.
	var lo: float
	var hi: float
	if stage_n == 1:
		lo = 1350.0; hi = 2280.0
	else:
		lo = 1550.0; hi = 2180.0
	var wet := 0
	for band in ["mid", "far"]:
		var x := lo
		while x <= hi:
			if Ground.on_ground(s, band, x):
				wet += 1
			x += 40.0
	check(wet == 0, "stage %d mid/far ground skips the water (%d hits)" % [stage_n, wet])
	# Near must also skip the river village river gap.
	if stage_n == 1:
		var nwet := 0
		var x2 := 1300.0
		while x2 <= 2000.0:
			if Ground.on_ground(s, "near", x2):
				nwet += 1
			x2 += 40.0
		check(nwet == 0, "River Village near band skips the river fence gap")

func _paratrooper_lands() -> void:
	var sim = fresh(1)
	sim.camera_x = 0.0
	var p: Vector2 = sim.pick_point("mid", 140.0)
	check(p.x >= 0.0, "a mid landing site exists at the start of River Village")
	var e: Dictionary = sim.spawn("paratrooper", "mid", {"world_x": p.x})
	check(e.state == "descend" and e.y < e.ground_y, "paratrooper starts in the air")
	for i in 60 * 12:
		sim.step(1.0 / 60.0)
		if e.get("landed", false):
			break
	check(e.get("landed", false), "paratrooper lands")
	var gy := Ground.ground_y(sim.stage, "mid", e.x)
	check(absf(e.y - gy) <= 2.0, "paratrooper lands on the mid ground line")

func _facing_vs_velocity() -> void:
	# Stage 1 villagers (left-facing art) and Dune Sea robes (right-facing art).
	var sim = fresh(1)
	var v: Dictionary = sim.spawn("villager", "mid", {"kind": "farmer"})
	v.vx = 50.0; v.facing = 1.0
	check(SpriteArt.villager_flip(v) < 0.0, "stage 1 villager walking right is flipped")
	sim.step(0.2)
	check(v.facing > 0.0 and v.vx > 0.0, "stage 1 villager facing matches +vx")
	var sim2 = fresh(2)
	var r: Dictionary = sim2.spawn("villager", "mid", {"kind": "robe_man"})
	r.vx = 50.0; r.facing = 1.0
	check(SpriteArt.villager_native(r) == 1.0, "robe native facing is right")
	check(SpriteArt.villager_flip(r) > 0.0, "robe villager walking right is unflipped (faces right)")
	r.vx = -50.0; r.facing = -1.0
	check(SpriteArt.villager_flip(r) < 0.0, "robe villager walking left is flipped (faces left)")
	sim2.step(0.2)
	check(r.facing < 0.0 and r.vx < 0.0, "robe villager facing follows -vx")

func _vehicles_on_path() -> void:
	for stage_n in [1, 2]:
		var sim = fresh(stage_n)
		# Put the camera where the track is in view (the right half of each panorama).
		sim.camera_x = 1920.0
		var typ := "truck" if stage_n == 1 else "technical"
		var e: Dictionary = sim.spawn(typ, "mid")
		check(str(e.get("path", "")) == "track", "stage %d %s is assigned the track" % [stage_n, typ])
		check(Ground.on_road(sim.stage, "track", e.x), "stage %d %s spawns on the track" % [stage_n, typ])
		var off := 0
		for i in 60 * 8:
			sim.step(1.0 / 60.0)
			if e.get("escaped", false) or not (e in sim.entities):
				break
			if Ground.dist_to_road(sim.stage, "track", e.x, e.ground_y) > 3.0:
				off += 1
			if absf(e.vx) > 1.0 and ((e.vx < 0.0 and e.facing >= 0.0) or (e.vx > 0.0 and e.facing <= 0.0)):
				off += 1
		check(off == 0, "stage %d %s stays on the track and faces its travel (%d slips)" % [stage_n, typ, off])
		if typ == "technical":
			# Must not cross the oasis: track starts around x 2220.
			check(Ground.road_bounds(sim.stage, "track").x > 2000.0, "Dune Sea track starts after the oasis")

func _camels_on_sand() -> void:
	var sim = fresh(2)
	sim.camera_x = 0.0
	var e: Dictionary = sim.spawn("camel", "mid")
	check(str(e.get("path", "")) == "sand", "mid camel uses the sand track")
	check(Ground.on_road(sim.stage, "sand", e.x), "camel spawns on the sand track")
	var off := 0
	for i in 60 * 10:
		sim.step(1.0 / 60.0)
		if e.get("escaped", false) or not (e in sim.entities):
			break
		# Bounce is a few pixels; compare against ground_y (pre-bounce).
		if Ground.dist_to_road(sim.stage, "sand", e.x, e.ground_y) > 3.0:
			off += 1
		if e.x > 1550.0:
			off += 1  # walked into the oasis
		if absf(e.vx) > 1.0 and ((e.vx < 0.0 and e.facing >= 0.0) or (e.vx > 0.0 and e.facing <= 0.0)):
			off += 1
	check(off == 0, "camel stays on the sand, faces its travel, and skips the oasis (%d slips)" % off)
	# Far camel uses the far sand path on the village approach.
	sim = fresh(2)
	sim.camera_x = 1920.0
	var f: Dictionary = sim.spawn("camel", "far")
	check(str(f.get("path", "")) == "sand_far", "far camel uses the far sand track")

func _snipers_stay_planted() -> void:
	var sim = fresh(2)
	sim.camera_x = 1920.0
	var e: Dictionary = sim.spawn("sniper", "mid", {"world_x": 3380, "world_y": 700})
	check(e.planted and is_equal_approx(e.y, 700.0), "a rooftop sniper keeps its planted y")
	sim.step(1.0)
	check(is_equal_approx(e.y, 700.0), "a rooftop sniper is not snapped down to the road")

func _near_body_visible() -> void:
	# A near rifleman standing on the sandbags must still show above the HUD.
	for stage_n in [1, 2]:
		var sim = fresh(stage_n)
		sim.camera_x = 0.0 if stage_n == 2 else 0.0
		var p: Vector2 = sim.pick_point("near", 140.0)
		if p.x < 0.0:
			sim.camera_x = 2500.0
			p = sim.pick_point("near", 140.0)
		check(p.x >= 0.0, "stage %d has a near standing site" % stage_n)
		var e: Dictionary = sim.spawn("rifleman", "near", {"world_x": p.x})
		var top: float = e.y - e.size.y * e.scale
		check(top < sim.HUD_BAND_TOP - 120.0, "stage %d near soldier body shows above the HUD (top %.0f, feet %.0f)" % [stage_n, top, e.y])
		check(Ground.on_ground(sim.stage, "near", e.x), "stage %d near soldier is on a near span" % stage_n)
