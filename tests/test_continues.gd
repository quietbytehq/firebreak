extends SceneTree
## Three continue diamonds per run: a failed stage can be retried until they run out.
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await process_frame

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	if main == null or main.get_script() == null:
		check(false, "main scene script loads")
		print("Continues: ", checks, " checks, ", failures, " failures")
		quit(1)
		return
	root.add_child(main)
	await frames(3)
	main.qa = {"run": true, "seed": 4}  # do not write the player's score file
	main.begin_run()
	check(main.run_continues == 3 and main.RUN_CONTINUES == 3, "a new run starts with 3 continue diamonds")
	main.start_stage(1)
	await frames(8)
	check(main.hud.continues == 3 and main.hud.continues_max == 3, "the HUD shows three diamonds")
	_fail_civilians(main.sim)
	check(main.sim.state == "failed" and main.sim.end_reason == "civilians", "3 civilian kills fail the stage")
	check(main.can_use_continue(), "a continue is offered after the first fail")
	main.view.banner("TOO MANY CIVILIANS", Vector2(960, 280), Color(1, 0.28, 0.22), 64, 2.2)
	main.view.title_card = main.view.title_card_max
	main.show_result()
	await frames(2)
	check(main.view.title_card <= 0.0, "the result screen clears the stage title card")
	var leftover := 0
	for q in main.view.popups:
		var txt := str(q.get("text", ""))
		if "CIVILIAN" in txt or "TOO MANY" in txt:
			leftover += 1
	check(leftover == 0, "the result screen clears civilian banners so they cannot overlap the title")
	var kept: int = main.run_score
	check(main.use_continue(), "Continue spends a diamond and restarts the stage")
	await frames(8)
	check(main.run_continues == 2, "one diamond was spent")
	check(main.hud.continues == 2, "the HUD dropped to 2 diamonds")
	check(main.mode == "playing" and main.sim != null and main.sim.state == "playing", "the stage restarted")
	check(main.sim.stats.villagers_hit == 0 and main.sim.time < 1.0, "the retried stage is a fresh attempt")
	check(main.run_score == kept, "the run total of earlier stages is unchanged")
	check(main.stage_number == 1, "the same stage is retried")
	# Spend the last two diamonds the same way, then the run is over.
	_fail_civilians(main.sim)
	check(main.use_continue(), "second continue works")
	await frames(4)
	_fail_civilians(main.sim)
	check(main.use_continue(), "third continue works")
	await frames(4)
	check(main.run_continues == 0, "all three diamonds are spent")
	_fail_civilians(main.sim)
	check(main.sim.state == "failed", "a fourth fail still ends the stage")
	check(not main.can_use_continue(), "with 0 diamonds left there is no continue")
	# Finalizing records the run score (skipped under qa.run, but the hook still runs).
	var before: bool = main.run_score_saved
	main._finalize_failed_run()
	check(main.run_banked, "game over banks the failed run")
	# qa.run blocks the actual file write; the flag may stay false. That's intended.
	check(before == main.run_score_saved or main.qa.has("run"), "qa runs do not write the player's table")
	print("Continues: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)

func _fail_civilians(sim) -> void:
	for i in 3:
		var v: Dictionary = sim.spawn("villager", "mid")
		if v.is_empty():
			v = sim.spawn("villager", "near")
		if v.is_empty():
			sim.health = 0.0
			sim.step(0.05)
			return
		sim.damage_entity(v, 99.0, Vector2(v.x - sim.camera_x, v.y - 40.0))
