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
	_no_dry_feet_on_water()
	_harbour_near_wades()
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
	var rush: Dictionary = sim.spawn("rusher", "mid", {"world_x": p.x, "world_y": p.y})
	check(not rush.is_empty() and bool(rush.get("wading", false)), "a mid-bay rusher is marked wading")
	check(float(rush.get("submerge", 0.0)) >= 0.4, "the rusher is waist-deep")
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
	var gre: Dictionary = sim.spawn("grenadier", "mid", {"world_x": 1700.0, "world_y": 710.0, "scale": 0.5})
	check(not gre.is_empty() and not bool(gre.get("wading", false)), "a pier grenadier stays on the planks")
	check(str(gre.get("path", "")) == "pier" or gre.get("planted", false), "the grenadier is on the pier path")
	var goff := Ground.feet_off(sim.stage, gre)
	check(goff >= 0.0 and goff <= Ground.feet_slack(gre) + 2.0, "grenadier feet sit on the pier (%.2f)" % goff)

func _river_and_dune_audit() -> void:
	# Anyone placed in the known water gaps must wade, not stand on the surface.
	var river = fresh(1)
	var e: Dictionary = river.spawn("rifleman", "mid", {"world_x": 1800.0, "world_y": 800.0})
	check(not e.is_empty() and bool(e.get("wading", false)), "a River Village rifleman in the river wades")
	check(absf(e.y - Ground.water_y(river.stage, e.x, "mid")) <= 8.0, "River Village waterline is the contact")
	var dune = fresh(2)
	var d: Dictionary = dune.spawn("rifleman", "mid", {"world_x": 1860.0, "world_y": 770.0})
	check(not d.is_empty() and bool(d.get("wading", false)), "a Dune Sea rifleman in the oasis gap wades")

func _no_dry_feet_on_water() -> void:
	# No near or mid figure may have water under or directly behind its feet
	# unless it is wading or a boat / pier crew (DRY_TYPES).
	for n in [1, 2, 3]:
		var sim = fresh(n)
		var dry_on_water := 0
		var sampled := 0
		var waders := 0
		for band in ["near", "mid"]:
			var x := 20.0
			while x <= 3820.0:
				var place := Ground.on_ground(sim.stage, band, x) or Ground.in_water(sim.stage, band, x, "rifleman") or Ground.water_under_or_behind(sim.stage, band, x, "rifleman")
				if place:
					var e: Dictionary = sim.spawn("rifleman", band, {"world_x": x})
					if e.is_empty():
						x += 40.0
						continue
					sampled += 1
					var wet := Ground.water_under_or_behind(sim.stage, band, float(e.x), "rifleman")
					if wet and not bool(e.get("wading", false)):
						dry_on_water += 1
					if bool(e.get("wading", false)):
						waders += 1
						if float(e.get("submerge", 0.0)) < 0.4:
							dry_on_water += 1
					sim.entities.erase(e)
				x += 40.0
		check(sampled > 0, "stage %d has near/mid placement samples" % n)
		check(dry_on_water == 0, "stage %d: no near/mid rifleman has water under or behind its feet unless wading (%d)" % [n, dry_on_water])
		if n == 3:
			check(waders > 0, "Coral Coast has at least one wading sample on the audit grid")
	# A Dune Sea near figure on the sand bank in front of the oasis stays dry.
	var dune = fresh(2)
	var bank: Dictionary = dune.spawn("rifleman", "near", {"world_x": 1860.0})
	check(not bank.is_empty() and not bool(bank.get("wading", false)), "Dune Sea near infantry stay dry on the oasis sand bank")
	check(not Ground.water_under_or_behind(dune.stage, "near", 1860.0, "rifleman"), "the oasis is not 'directly behind' the near sand bank")

func _harbour_near_wades() -> void:
	# The harbour parapet has only sea behind it. Near figures there must
	# wade at the near shore waterline, not stand on the sandbag lip.
	var sim = fresh(3)
	sim.camera_x = 1920.0
	for x in [2000.0, 2400.0, 2800.0, 3200.0, 3600.0]:
		check(Ground.water_under_or_behind(sim.stage, "near", x, "rifleman"), "Coral harbour x=%.0f has water under or behind a near figure" % x)
		check(not Ground.on_ground(sim.stage, "near", x), "Coral harbour x=%.0f is not a dry near parapet" % x)
		var e: Dictionary = sim.spawn("rifleman", "near", {"world_x": x})
		check(not e.is_empty() and bool(e.get("wading", false)), "a near rifleman at harbour x=%.0f wades" % x)
		if e.is_empty():
			continue
		check(float(e.get("submerge", 0.0)) >= 0.4, "harbour near wader at x=%.0f is waist-deep" % x)
		var wy := Ground.water_y(sim.stage, x, "near")
		check(absf(e.y - wy) <= 8.0, "harbour near wader at x=%.0f contacts the near shore waterline (y=%.1f, water=%.1f)" % [x, e.y, wy])
		check(e.y >= 790.0, "harbour near wader stays at the parapet shore, not mid-bay depth (y=%.1f)" % e.y)
		sim.entities.erase(e)
	# The open beach in front of the mid bay stays dry near land.
	sim.camera_x = 0.0
	var beach: Dictionary = sim.spawn("rifleman", "near", {"world_x": 400.0})
	check(not beach.is_empty() and not bool(beach.get("wading", false)), "a near rifleman on the Coral beach stays dry")
	check(Ground.on_ground(sim.stage, "near", 400.0), "the Coral beach is near land")
	# Combat picks in the harbour must not plant a dry near figure on the bags.
	sim.camera_x = 1920.0
	var dry_picks := 0
	for i in 16:
		var p: Vector2 = sim.pick_combat_point("near", 140.0, float(i) / 15.0)
		if p.x < 0.0:
			continue
		if Ground.water_under_or_behind(sim.stage, "near", p.x, "rifleman") == false and not Ground.on_ground(sim.stage, "near", p.x):
			dry_picks += 1
		elif Ground.water_under_or_behind(sim.stage, "near", p.x, "rifleman") == false and p.x >= 1890.0:
			dry_picks += 1
	check(dry_picks == 0, "harbour combat picks do not choose a dry near site on the wet parapet (%d)" % dry_picks)

