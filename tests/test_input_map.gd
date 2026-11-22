extends SceneTree
## Input actions exist with keyboard, mouse and gamepad defaults; remaps persist.
const InputSetup := preload("res://scripts/input_setup.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func has_device(action: String, dev: String) -> bool:
	for ev in InputMap.action_get_events(action):
		if InputSetup.device_of(ev) == dev: return true
	return false
func run() -> void:
	InputSetup.ensure(false)
	for a in InputSetup.ACTIONS:
		check(InputMap.has_action(a), "action exists: " + a)
		check(InputMap.action_get_events(a).size() > 0, "action has a binding: " + a)
	for a in ["fire", "reload", "grenade", "airstrike", "pause"]:
		check(has_device(a, "joy"), "gamepad binding for " + a)
		check(has_device(a, "key"), "keyboard binding for " + a)
	for a in ["aim_left", "aim_right", "aim_up", "aim_down"]:
		check(has_device(a, "joy") and has_device(a, "key"), "crosshair can move by pad and keyboard: " + a)
	check(has_device("fire", "mouse"), "mouse fires")
	check(has_device("grenade", "mouse"), "mouse throws grenades")
	# 0.2.0 bindings: Space or right click throws a grenade; E, middle click or pad RB calls the air strike.
	var space := InputEventKey.new(); space.physical_keycode = KEY_SPACE; space.pressed = true
	check(InputMap.event_is_action(space, "grenade"), "Space throws a grenade")
	check(not InputMap.event_is_action(space, "fire"), "Space no longer fires")
	var rmb := InputEventMouseButton.new(); rmb.button_index = MOUSE_BUTTON_RIGHT; rmb.pressed = true
	check(InputMap.event_is_action(rmb, "grenade"), "right mouse button throws a grenade")
	var pad_b := InputEventJoypadButton.new(); pad_b.button_index = JOY_BUTTON_B; pad_b.pressed = true
	check(InputMap.event_is_action(pad_b, "grenade"), "gamepad B throws a grenade")
	var key_e := InputEventKey.new(); key_e.physical_keycode = KEY_E; key_e.pressed = true
	check(InputMap.event_is_action(key_e, "airstrike"), "E calls the air strike")
	var mmb := InputEventMouseButton.new(); mmb.button_index = MOUSE_BUTTON_MIDDLE; mmb.pressed = true
	check(InputMap.event_is_action(mmb, "airstrike"), "middle mouse calls the air strike")
	check(not InputMap.event_is_action(mmb, "reload"), "middle mouse no longer reloads")
	var rb := InputEventJoypadButton.new(); rb.button_index = JOY_BUTTON_RIGHT_SHOULDER; rb.pressed = true
	check(InputMap.event_is_action(rb, "airstrike"), "gamepad right shoulder calls the air strike")
	var ctrl := InputEventKey.new(); ctrl.physical_keycode = KEY_CTRL; ctrl.pressed = true
	check(InputMap.event_is_action(ctrl, "fire"), "Ctrl fires from the keyboard")
	var owners := {}
	for a in InputSetup.ACTIONS:
		for ev in InputMap.action_get_events(a):
			var key := InputSetup.device_of(ev) + ":" + InputSetup.describe(ev)
			if owners.has(key) and not key.contains("stick"): check(false, "binding used twice: %s (%s, %s)" % [key, owners[key], a])
			owners[key] = a
	check(true, "no default binding is shared by two actions")
	var f11 := InputEventKey.new(); f11.physical_keycode = KEY_F11; f11.pressed = true
	check(InputMap.event_is_action(f11, "fullscreen"), "F11 toggles fullscreen")
	var esc := InputEventKey.new(); esc.physical_keycode = KEY_ESCAPE; esc.pressed = true
	check(InputMap.event_is_action(esc, "pause"), "Esc pauses")
	var stick := InputEventJoypadMotion.new(); stick.axis = JOY_AXIS_LEFT_X; stick.axis_value = 0.9
	check(InputMap.event_is_action(stick, "aim_right"), "left stick moves crosshair right")
	# Remap reload to F, persist, reset in memory, reload from disk.
	var k := InputEventKey.new(); k.physical_keycode = KEY_F; k.pressed = true
	check(InputSetup.rebind("reload", k), "rebind accepted")
	check(InputMap.event_is_action(k, "reload"), "new key works")
	var r := InputEventKey.new(); r.physical_keycode = KEY_R; r.pressed = true
	check(not InputMap.event_is_action(r, "reload"), "old key replaced, not duplicated")
	check(has_device("reload", "joy"), "rebinding a key keeps the gamepad binding")
	InputSetup.save_remaps()
	check(FileAccess.file_exists(InputSetup.CONTROLS_PATH), "controls saved under user://")
	InputSetup.ensure(false)
	check(InputMap.event_is_action(r, "reload"), "defaults restored in memory")
	InputSetup.load_remaps()
	check(InputMap.event_is_action(k, "reload"), "saved remap loads back")
	var pad := InputEventJoypadButton.new(); pad.button_index = JOY_BUTTON_Y; pad.pressed = true
	InputSetup.rebind("grenade", pad)
	check(InputMap.event_is_action(pad, "grenade"), "gamepad button rebinding works")
	check(not InputSetup.rebind("fullscreen", pad), "fullscreen stays on the keyboard")
	var kg := InputEventKey.new(); kg.physical_keycode = KEY_Q; kg.pressed = true
	check(InputSetup.rebind("airstrike", kg) and InputMap.event_is_action(kg, "airstrike"), "air strike can be remapped")
	InputSetup.reset_defaults()
	check(InputMap.event_is_action(r, "reload") and not InputMap.event_is_action(k, "reload"), "reset to defaults")
	# A controls file saved by 0.1.0 (Space on Fire) must not override the new defaults.
	var old := ConfigFile.new()
	var old_fire := InputEventKey.new(); old_fire.physical_keycode = KEY_SPACE
	old.set_value("controls", "fire", [old_fire])
	old.save(InputSetup.CONTROLS_PATH)
	InputSetup.ensure(true)
	check(not InputMap.event_is_action(space, "fire") and InputMap.event_is_action(space, "grenade"), "old 0.1.0 remaps are ignored after the binding change")
	InputSetup.reset_defaults()
	check(InputSetup.describe_action("fire").contains("Left click"), "bindings are described for the controls screen")
	print("Input map: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
