extends SceneTree
## Water clip: wading infantry sit on the waterline, never on the surface
## with visible feet. Boat crews stay dry. Stages 1-3 are audited.
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
	sim.setup(stage, 11)
	sim.stage.ambient = []
	sim.stage.waves = []
	return sim

func run() -> void:
	for n in [1, 2, 3]:
		var s := StageData.load_stage(n)
		check(Ground.has_water(s), "stage %d has a water body to audit" % n)
		_land_not_flagged_wet(n, s)
	_wading_on_coral()
	_boats_stay_dry()
	_river_and_dune_audit()
	print("Water: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)

func _land_not_flagged_wet(n: int, s: Dictionary) -> void:
	var wet_on_land := 0
	for band in ["far", "mid", "near"]:
		for z in Ground.ground_spans(s, band):
			var x := float(z[0]) + 8.0
			while x <= float(z[1]) - 8.0:
				if Ground.in_water(s, band, x, "rifleman"):
					wet_on_land += 1
				x += 40.0
	check(wet_on_land == 0, "stage %d land spans are not treated as water (%d)" % [n, wet_on_land])

func _wading_on_coral() -> void:
	var sim = fresh(3)
	# Mid bay water is in view once the camera has scrolled to the pier.
	sim.camera_x = 800.0
	var p: Vector2 = sim.pick_water_point("mid")
	check(p.x >= 0.0, "Coral Coast mid water has a spawn in view at the pier")
	if p.x < 0.0:
		return
	var e: Dictionary = sim.spawn("rifleman", "mid", {"world_x": p.x, "world_y": p.y})
	check(not e.is_empty() and bool(e.get("wading", false)), "a mid-bay rifleman is marked wading")
	check(float(e.get("submerge", 0.0)) >= 0.4, "wading submerges the legs (waist-deep)")
	var wy := Ground.water_y(sim.stage, e.x, "mid")
	check(absf(e.y - wy) <= 8.0, "wading feet contact is the waterline, not a dry ground line")
	var off := Ground.feet_off(sim.stage, e)
	check(off >= 0.0 and off <= Ground.feet_slack(e), "wading contact is within slack (%.2f)" % off)
	var box := sim.hitbox(e)
	check(box.end.y <= e.y + 2.0, "the wading hitbox does not include legs under the water")
	check(box.position.y < e.y, "the dry torso stays above the waterline")
	check(SpriteArt.is_wading(e), "art treats the rifleman as wading")
	# A planted land spawn on the mid beach stays dry.
	sim.camera_x = 0.0
	var land: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 400.0})
	check(not land.is_empty() and not bool(land.get("wading", false)), "a beach rifleman is not wading")

func _boats_stay_dry() -> void:
	var sim = fresh(3)
	sim.camera_x = 800.0
	var boat: Dictionary = sim.spawn("speedboat", "mid")
	check(not boat.is_empty() and not bool(boat.get("wading", false)), "speedboat crew is not a wading figure")
	check(str(boat.get("path", "")) == "water", "the speedboat stays on the water path")
	sim.camera_x = 1920.0
	var gun: Dictionary = sim.spawn("gunboat", "mid", {"scale": 0.95})
	check(not gun.is_empty() and not bool(gun.get("wading", false)), "the gunboat is not a wading figure")
	var pier: Dictionary = sim.spawn("pier_gunner", "mid", {"world_x": 2280.0, "world_y": 800.0, "scale": 0.5})
	check(not pier.is_empty() and not bool(pier.get("wading", false)), "a pier gunner stays on the planks")

func _river_and_dune_audit() -> void:
	# Anyone placed in the known water gaps must wade, not stand on the surface.
	var river = fresh(1)
	var e: Dictionary = river.spawn("rifleman", "mid", {"world_x": 1800.0, "world_y": 800.0})
	check(not e.is_empty() and bool(e.get("wading", false)), "a River Village rifleman in the river wades")
	check(absf(e.y - Ground.water_y(river.stage, e.x, "mid")) <= 8.0, "River Village waterline is the contact")
	var dune = fresh(2)
	var d: Dictionary = dune.spawn("rifleman", "mid", {"world_x": 1860.0, "world_y": 770.0})
	check(not d.is_empty() and bool(d.get("wading", false)), "a Dune Sea rifleman in the oasis gap wades")
