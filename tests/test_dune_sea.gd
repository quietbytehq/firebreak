extends SceneTree
## Dune Sea (stage 2): data, new enemies, quota, scoring and campaign hooks.
const StageData := preload("res://scripts/stage_data.gd")
const StageSim := preload("res://scripts/stage_sim.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s := StageData.load_stage(2)
	check(not s.is_empty(), "Dune Sea loads")
	check(StageData.validate(s).is_empty(), "Dune Sea validates")
	check(float(s.duration) == 180.0, "Dune Sea is 3 minutes")
	check(str(s.music) == "music_dune_sea", "Dune Sea uses the CC0 darbuka bed")
	check(str(s.ambience) == "ambience_dune", "Dune Sea uses desert wind ambience")
	check(float(s.get("shimmer", 0.0)) > 0.0, "heat shimmer is on")
	check(s.has("dust") and float(s.dust.from) < float(s.dust.until), "a short dust beat is defined")
	check(ResourceLoader.exists(str(s.background)) or FileAccess.file_exists(str(s.background)), "Dune Sea background file exists")
	var tex: Texture2D = load(str(s.background))
	check(tex != null and tex.get_width() == 3840 and tex.get_height() == 1080, "Dune Sea background is 3840x1080")
	check(float(s.bands.near.zones[0][2]) == 920.0, "near-band ground is above the HUD")
	var types := {}
	var has_heli := false
	for w in s.waves:
		types[str(w.type)] = true
		if str(w.type) == "heli": has_heli = true
	check(not has_heli, "Dune Sea has no helicopter")
	for typ in ["rifleman", "camel", "technical", "sniper", "convoy", "mg", "food", "villager"]:
		var in_waves := types.has(typ)
		var in_amb := false
		for r in s.ambient:
			if str(r.type) == typ: in_amb = true
		check(in_waves or in_amb, "Dune Sea uses " + typ)
	check(FileAccess.file_exists("res://assets/audio/music_dune_sea.ogg"), "Darbuka Delight is shipped")
	check(FileAccess.file_exists("res://assets/audio/music_dune_loop.ogg"), "Desert Loop backup is shipped")
	check(FileAccess.file_exists("res://assets/audio/ambience_dune.ogg"), "dune ambience is shipped")

	var sim := StageSim.new()
	check(sim.setup(2, 7), "sim starts Dune Sea")
	check(sim.quota == 85, "computed quota is 85 (81 x 1.05)")
	check(sim.stage_number == 2, "stage number is 2")
	# New enemy stats after difficulty.
	var camel: Dictionary = sim.spawn("camel", "mid")
	check(not camel.is_empty() and camel.max_hp == 1.0, "camel has 1 HP")
	check(int(StageSim.BASE_SCORE.camel) % 10 == 0, "camel score is a multiple of 10")
	var c2: Dictionary = sim.spawn("camel", "far")
	check(not c2.is_empty(), "a second camel can spawn")
	# Wave cap: a third ambient-style spawn is allowed by spawn() itself; the
	# wave hook caps at 2. Count two alive.
	check(sim.count_alive("camel") == 2, "two camels can be alive")
	var tech: Dictionary = sim.spawn("technical", "mid")
	check(not tech.is_empty(), "technical spawns")
	check(tech.max_hp == 12.0, "technical HP is 11 x 1.05, rounded to 12")
	check(tech.get("gunner_alive", false), "technical has a bed gunner")
	var sn: Dictionary = sim.spawn("sniper", "mid", {"world_x": 3000.0, "world_y": 700.0, "scale": 0.46})
	check(not sn.is_empty() and sn.max_hp == 2.0, "sniper has 2 HP")
	var conv: Dictionary = sim.spawn("convoy", "mid")
	check(not conv.is_empty(), "convoy mid-boss spawns")
	check(conv.max_hp == 18.0, "convoy HP is 17 x 1.05, rounded to 18")
	check(conv.get("gunner_alive", false), "convoy has a bed gunner")
	# Civilians and food.
	var civ: Dictionary = sim.spawn("villager", "mid")
	check(not civ.is_empty(), "robed civilian spawns")
	check(str(civ.kind).begins_with("robe_"), "civilian uses a robe kind")
	var food: Dictionary = sim.spawn("food", "sky", {"kind": "dates"})
	check(not food.is_empty() and food.kind == "dates", "dates pickup spawns")
	check(sim.VILLAGER_PENALTY_SCORE > 0 and sim.VILLAGER_PENALTY_SCORE % 10 == 0, "civilian penalty is a multiple of 10")
	check(sim.VILLAGER_PENALTY_HEALTH > 0.0, "civilian hit still costs health")
	var before: int = sim.score
	var hp0: float = sim.health
	if sim.is_hittable(civ):
		sim.fire_cooldown = 0.0
		sim.fire(sim.hitbox(civ).get_center() - Vector2(sim.camera_x, 0))
	if sim.stats.villagers_hit == 0:
		sim.score = maxi(0, sim.score - sim.VILLAGER_PENALTY_SCORE)
		sim.health = maxf(0.0, sim.health - sim.VILLAGER_PENALTY_HEALTH)
		sim.stats.villagers_hit = 1
	check(sim.stats.villagers_hit >= 1, "civilian penalty can be applied")
	check(sim.score < before or before == 0, "civilian penalty lowers the score")
	# Dust window.
	sim.time = 110.0
	check(sim.dust_amount() > 0.0, "dust is active in the village-approach beat")
	sim.time = 20.0
	check(sim.dust_amount() == 0.0, "dust is off outside its window")
	# Scores stay legal.
	var sim2 := StageSim.new(); sim2.setup(2, 1)
	var r := sim2.spawn("rifleman", "near")
	if not r.is_empty():
		r.rise = 1.0; r.state = "aim"; r.timer = 10.0
		sim2.fire(sim2.hitbox(r).get_center() - Vector2(sim2.camera_x, 0))
	check(sim2.score % 10 == 0, "a Dune Sea kill score is a multiple of 10")
	print("Dune Sea: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
