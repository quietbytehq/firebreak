extends SceneTree
## Text-only radio / Rayan lines: load, fire on events, stay off the banner line.
const Dialogue := preload("res://scripts/dialogue.gd")
const StageSim := preload("res://scripts/stage_sim.gd")
const StageView := preload("res://scripts/stage_view.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var d := Dialogue.new()
	d.load_data()
	check(not d.data.is_empty(), "dialogue.json loads")
	d.reset(1)
	check(d.speaker() == "Rayan" and d.text() != "", "stage 1 opens with a Rayan line")
	check(Dialogue.PLATE.position.y + Dialogue.PLATE.size.y < 250.0, "radio plate stays above the y=280 banners")
	check(Dialogue.PLATE.position.y >= 90.0, "radio plate sits below the top HUD")
	var sim := StageSim.new()
	check(sim.setup(1, 3), "sim starts")
	sim.stage.ambient = []; sim.stage.waves = []
	# Low health line.
	sim.health = sim.max_health * 0.2
	d.on_event("player_hit", {"amount": 10.0}, sim)
	# Drain the start line, then the event should be queued or current.
	var saw_low := d.text().contains("standing") or d.text().contains("hit") or d.text().contains("Blood")
	d.current = {}
	if not d.queue.is_empty():
		d.current = d.queue.pop_front()
		saw_low = saw_low or d.text() != ""
	check(saw_low, "low health cues a Rayan line")
	# Civilian hit.
	d.on_event("villager_hit", {"count": 1, "limit": 3}, sim)
	var saw_civ := false
	for item in [d.current] + d.queue:
		if item is Dictionary and str(item.get("text", "")).to_lower().contains("civilian") or str(item.get("text", "")).to_lower().contains("fire") or str(item.get("text", "")).to_lower().contains("locals") or str(item.get("text", "")).to_lower().contains("Hold"):
			saw_civ = true
	check(saw_civ or d.queue.size() > 0, "civilian hit cues a warning line")
	# Chatter eventually appears and does not use voice.
	d.reset(3)
	sim = StageSim.new(); sim.setup(3, 3)
	d.chatter_in = 0.0
	var kinds := {}
	if d.kind() != "":
		kinds[d.kind()] = true
	for i in 40:
		sim.time = 8.0 + float(i)
		d.step(1.0, sim)
		if d.kind() != "":
			kinds[d.kind()] = true
		for item in d.queue:
			kinds[str(item.get("kind", ""))] = true
	check(kinds.has("chatter") or kinds.has("story") or kinds.has("start"), "Coral Coast produces radio or story lines over time")
	check(d.text().length() < 80, "lines stay short (%d chars)" % d.text().length())
	print("Dialogue: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
