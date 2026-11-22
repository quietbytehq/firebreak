extends RefCounted
## Creates Firebreak's input actions with keyboard, mouse and standard
## gamepad defaults, and saves/loads player remaps to user://controls.cfg.

const CONTROLS_PATH := "user://controls.cfg"
## Bumped when default bindings change in a way old saves would conflict with
## (0.2.0: Space moved from Fire to Grenade, middle click from Reload to Air strike).
const CONTROLS_VERSION := 2
const ACTIONS := ["fire", "reload", "grenade", "airstrike", "weapon_1", "weapon_2", "weapon_3", "weapon_next", "weapon_prev",
	"aim_left", "aim_right", "aim_up", "aim_down", "pause", "fullscreen"]
const LABELS := {
	"fire": "Fire", "reload": "Reload", "grenade": "Special (grenade / launcher)", "airstrike": "Air strike",
	"weapon_1": "Pistol (slot 1)", "weapon_2": "Primary (slot 2)", "weapon_3": "Special (slot 3)",
	"weapon_next": "Next weapon", "weapon_prev": "Previous weapon", "aim_left": "Aim left", "aim_right": "Aim right",
	"aim_up": "Aim up", "aim_down": "Aim down", "pause": "Pause", "fullscreen": "Fullscreen",
}

static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new(); e.physical_keycode = code; return e

static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new(); e.button_index = button; return e

static func _joy(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new(); e.button_index = button; e.device = -1; return e

static func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new(); e.axis = axis; e.axis_value = value; e.device = -1; return e

static func defaults() -> Dictionary:
	return {
		"fire": [_mouse(MOUSE_BUTTON_LEFT), _key(KEY_CTRL), _joy(JOY_BUTTON_A), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"reload": [_key(KEY_R), _joy(JOY_BUTTON_X)],
		"grenade": [_key(KEY_SPACE), _mouse(MOUSE_BUTTON_RIGHT), _key(KEY_G), _joy(JOY_BUTTON_B), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)],
		"airstrike": [_key(KEY_E), _mouse(MOUSE_BUTTON_MIDDLE), _joy(JOY_BUTTON_RIGHT_SHOULDER)],
		"weapon_1": [_key(KEY_1)],
		"weapon_2": [_key(KEY_2)],
		"weapon_3": [_key(KEY_3)],
		"weapon_next": [_key(KEY_Q), _mouse(MOUSE_BUTTON_WHEEL_DOWN), _joy(JOY_BUTTON_LEFT_SHOULDER)],
		"weapon_prev": [_mouse(MOUSE_BUTTON_WHEEL_UP), _joy(JOY_BUTTON_Y)],
		"aim_left": [_key(KEY_LEFT), _key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0), _joy(JOY_BUTTON_DPAD_LEFT)],
		"aim_right": [_key(KEY_RIGHT), _key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0), _joy(JOY_BUTTON_DPAD_RIGHT)],
		"aim_up": [_key(KEY_UP), _key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0), _joy(JOY_BUTTON_DPAD_UP)],
		"aim_down": [_key(KEY_DOWN), _key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0), _joy(JOY_BUTTON_DPAD_DOWN)],
		"pause": [_key(KEY_ESCAPE), _key(KEY_P), _joy(JOY_BUTTON_START)],
		"fullscreen": [_key(KEY_F11)],
	}

## Ensures every action exists with defaults, then applies saved remaps.
static func ensure(load_saved: bool = true) -> void:
	var d := defaults()
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		InputMap.action_erase_events(action)
		for ev in d[action]:
			InputMap.action_add_event(action, ev)
	if load_saved:
		load_remaps()

static func reset_defaults() -> void:
	ensure(false)
	save_remaps()

## Device class of an event: "key", "mouse" or "joy".
static func device_of(ev: InputEvent) -> String:
	if ev is InputEventKey: return "key"
	if ev is InputEventMouseButton: return "mouse"
	if ev is InputEventJoypadButton or ev is InputEventJoypadMotion: return "joy"
	return ""

## Replaces the first binding of the same device class (key, mouse or gamepad)
## with the new event. Returns false for unsupported events.
static func rebind(action: String, ev: InputEvent) -> bool:
	var dev := device_of(ev)
	if dev == "" or not InputMap.has_action(action) or action == "fullscreen" and dev != "key":
		return false
	var fresh := ev.duplicate()
	if fresh is InputEventKey:
		if fresh.physical_keycode == KEY_NONE: fresh.physical_keycode = fresh.keycode
		fresh.keycode = KEY_NONE; fresh.pressed = false
	elif fresh is InputEventMouseButton:
		fresh.pressed = false; fresh.position = Vector2.ZERO; fresh.global_position = Vector2.ZERO
	elif fresh is InputEventJoypadButton:
		fresh.pressed = false; fresh.device = -1
	elif fresh is InputEventJoypadMotion:
		fresh.axis_value = signf(fresh.axis_value); fresh.device = -1
	var events := InputMap.action_get_events(action)
	var replaced := false
	InputMap.action_erase_events(action)
	for old in events:
		if not replaced and device_of(old) == dev and not (dev == "joy" and (old is InputEventJoypadMotion) != (fresh is InputEventJoypadMotion)):
			InputMap.action_add_event(action, fresh); replaced = true
		else:
			InputMap.action_add_event(action, old)
	if not replaced:
		InputMap.action_add_event(action, fresh)
	return true

static func save_remaps() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", CONTROLS_VERSION)
	for action in ACTIONS:
		cfg.set_value("controls", action, InputMap.action_get_events(action))
	cfg.save(CONTROLS_PATH)

static func load_remaps() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONTROLS_PATH) != OK: return
	# Remaps saved by an older version would clash with the new defaults; start fresh.
	if int(cfg.get_value("meta", "version", 1)) < CONTROLS_VERSION: return
	for action in ACTIONS:
		var events = cfg.get_value("controls", action, null)
		if events is Array and not events.is_empty():
			InputMap.action_erase_events(action)
			for ev in events:
				if ev is InputEvent: InputMap.action_add_event(action, ev)

static func describe(ev: InputEvent) -> String:
	if ev is InputEventKey:
		return OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode)
	if ev is InputEventMouseButton:
		return {MOUSE_BUTTON_LEFT: "Left click", MOUSE_BUTTON_RIGHT: "Right click", MOUSE_BUTTON_MIDDLE: "Middle click",
			MOUSE_BUTTON_WHEEL_UP: "Wheel up", MOUSE_BUTTON_WHEEL_DOWN: "Wheel down"}.get(ev.button_index, "Mouse %d" % ev.button_index)
	if ev is InputEventJoypadButton:
		return {JOY_BUTTON_A: "Pad A", JOY_BUTTON_B: "Pad B", JOY_BUTTON_X: "Pad X", JOY_BUTTON_Y: "Pad Y", JOY_BUTTON_START: "Pad Start",
			JOY_BUTTON_BACK: "Pad Back", JOY_BUTTON_LEFT_SHOULDER: "Pad LB", JOY_BUTTON_RIGHT_SHOULDER: "Pad RB",
			JOY_BUTTON_DPAD_UP: "D-pad up", JOY_BUTTON_DPAD_DOWN: "D-pad down", JOY_BUTTON_DPAD_LEFT: "D-pad left", JOY_BUTTON_DPAD_RIGHT: "D-pad right"}.get(ev.button_index, "Pad %d" % ev.button_index)
	if ev is InputEventJoypadMotion:
		var names := {JOY_AXIS_LEFT_X: "Left stick X", JOY_AXIS_LEFT_Y: "Left stick Y", JOY_AXIS_RIGHT_X: "Right stick X", JOY_AXIS_RIGHT_Y: "Right stick Y", JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT"}
		var n: String = names.get(ev.axis, "Axis %d" % ev.axis)
		if ev.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]: return "Pad " + n
		return n + (" +" if ev.axis_value > 0 else " -")
	return "?"

static func describe_action(action: String) -> String:
	var parts := []
	for ev in InputMap.action_get_events(action):
		parts.append(describe(ev))
	return ", ".join(parts)
