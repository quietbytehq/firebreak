extends SceneTree
## Floating callouts stay out of the top HUD and fully on screen; hit flash
## no longer blows a figure to flat white.
const StageView := preload("res://scripts/stage_view.gd")
const SpriteArt := preload("res://scripts/sprite_art.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")

func box(text: String, pos: Vector2, size: int, font: Font) -> Rect2:
	var at := StageView.clamp_callout(text, pos, size, font)
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var ascent := font.get_ascent(size)
	var descent := font.get_descent(size)
	var o := StageView.CALLOUT_OUTLINE
	return Rect2(at.x - w * 0.5 - o, at.y - ascent - o, w + o * 2.0, ascent + descent + o * 2.0)

func fully_on_screen(r: Rect2) -> bool:
	var m := StageView.CALLOUT_MARGIN
	return r.position.x >= m - 0.5 \
		and r.position.y >= StageView.HUD_TOP_EDGE + m - 0.5 \
		and r.end.x <= StageView.VIEW_WIDTH - m + 0.5 \
		and r.end.y <= StageView.VIEW_HEIGHT - m + 0.5

func run() -> void:
	var font := ThemeDB.fallback_font
	check(font != null, "fallback font is available")
	# Pickup label spawned at the top-centre plate.
	var package_pos := Vector2(960, 40)
	var package_at := StageView.clamp_callout("PACKAGE", package_pos, 40, font)
	var package_box := box("PACKAGE", package_pos, 40, font)
	check(package_at.y > package_pos.y, "a high PACKAGE label is pushed down")
	check(package_box.position.y >= StageView.HUD_TOP_EDGE + StageView.CALLOUT_MARGIN - 0.5, "PACKAGE sits below the top HUD band")
	check(fully_on_screen(package_box), "PACKAGE stays fully on screen with a margin")
	# Score pop at the same high crate.
	var score_box := box("+50", Vector2(960, 20), 36, font)
	check(score_box.position.y >= StageView.HUD_TOP_EDGE + StageView.CALLOUT_MARGIN - 0.5, "score pops sit below the top HUD band")
	# Long wreck callout against the right edge (the convoy-shot case).
	var wreck := "TRUCK WRECKED"
	var wreck_at := StageView.clamp_callout(wreck, Vector2(1900, 520), 46, font)
	var wreck_box := box(wreck, Vector2(1900, 520), 46, font)
	check(wreck_at.x < 1900.0, "TRUCK WRECKED is pulled left from the right edge")
	check(wreck_box.end.x <= StageView.VIEW_WIDTH - StageView.CALLOUT_MARGIN + 0.5, "TRUCK WRECKED's right edge stays inside the margin")
	check(fully_on_screen(wreck_box), "TRUCK WRECKED is fully on screen with a margin")
	# Left edge and a wide streak title.
	var left_box := box("CIVILIAN!  -500", Vector2(10, 400), 42, font)
	check(left_box.position.x >= StageView.CALLOUT_MARGIN - 0.5, "a left-edge callout is pushed in")
	check(fully_on_screen(left_box), "a left-edge callout is fully on screen")
	var streak_box := box("UNSTOPPABLE", Vector2(960, 260), 76, font)
	check(fully_on_screen(streak_box), "UNSTOPPABLE stays fully on screen")
	# Floating upward must not enter the HUD: clamp again after a long drift.
	var floated := StageView.clamp_callout("PACKAGE", Vector2(960, -200), 40, font)
	var floated_box := box("PACKAGE", Vector2(960, -200), 40, font)
	check(floated.y >= StageView.HUD_TOP_EDGE, "a callout that drifted off the top is clamped back")
	check(floated_box.position.y >= StageView.HUD_TOP_EDGE + StageView.CALLOUT_MARGIN - 0.5, "a drifted PACKAGE still sits below the HUD")
	# A point already in the safe band is unchanged (within a pixel).
	var safe := Vector2(960, 400)
	var mid := StageView.clamp_callout("+120", safe, 36, font)
	check(mid.distance_to(safe) < 0.5, "a centred in-band score pop is not moved")
	# Hit flash: a full flash must not multiply the sprite past a readable lift.
	var lit: Color = SpriteArt.flash_mod({"flash": 1.0, "alpha": 1.0})
	check(lit.r <= 1.55 and lit.g <= 1.55 and lit.b <= 1.55, "full hit flash stays a highlight, not a 2.6x white-out")
	check(lit.r > 1.0 and lit.a == 1.0, "full hit flash still brightens the figure")
	var idle: Color = SpriteArt.flash_mod({"flash": 0.0, "alpha": 1.0})
	check(idle.r == 1.0 and idle.g == 1.0 and idle.b == 1.0, "no flash leaves the sprite unmodulated")
	print("Callouts: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
