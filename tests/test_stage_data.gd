extends SceneTree
## Campaign and stage data load, validate, and difficulty rises per stage.
const StageData := preload("res://scripts/stage_data.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var c := StageData.campaign()
	check(c.get("stages", []).size() == 12, "campaign plans 12 stages")
	var s := StageData.load_stage(1)
	check(not s.is_empty(), "stage 1 loads")
	check(s.get("name", "") == "River Village", "stage 1 is River Village")
	check(float(s.duration) <= 180.0, "stage is at most 3 minutes")
	var problems := StageData.validate(s)
	check(problems.is_empty(), "stage 1 validates: " + str(problems))
	check(ResourceLoader.exists(str(s.background)), "background exists")
	var tex: Texture2D = load(str(s.background))
	check(tex != null and tex.get_height() == 1080, "background is 1080 px tall")
	check(tex != null and tex.get_width() >= int(s.world_width), "background covers the world width")
	var types := {}
	for w in s.waves: types[w.type] = true
	for t in ["rifleman", "mg", "paratrooper", "food", "powerup", "villager"]:
		check(types.has(t) or s.ambient.any(func(r): return r.type == t), "stage uses " + t)
	check(float(s.bands.far.scale) < float(s.bands.mid.scale) and float(s.bands.mid.scale) < float(s.bands.near.scale), "far < mid < near scale")
	check(float(s.bands.far.damage) < float(s.bands.near.damage), "near enemies hit harder")
	check(StageData.load_stage(2).is_empty(), "unbuilt stages are not playable yet")
	var prev := StageData.difficulty(1)
	for n in range(2, 13):
		var d := StageData.difficulty(n)
		for k in ["damage", "density", "fire_rate", "quota"]:
			check(float(d[k]) > float(prev[k]), "difficulty %s rises at stage %d" % [k, n])
		check(float(d.accuracy) >= float(prev.accuracy), "accuracy does not fall at stage %d" % n)
		check(float(d.telegraph) <= float(prev.telegraph), "warning time shrinks at stage %d" % n)
		prev = d
	check(float(StageData.difficulty(12).accuracy) <= 0.85, "accuracy is capped")
	var broken := s.duplicate(true); broken.duration = 200.0; broken.waves.append({"t": 1.0, "type": "dragon"})
	check(StageData.validate(broken).size() >= 2, "validator catches bad stages")
	print("Stage data: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
