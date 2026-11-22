extends Node2D
## Title screen: Rayan's action-comic art full screen with a slow zoom and a
## little mouse parallax, rising embers and drifting smoke, the live
## "FIREBREAK" logo (stacked on the left, clear of Rayan's head), a pulsing
## PRESS START and a small QuietByte credit.

const LogoShader := preload("res://shaders/logo_fill.gdshader")
const LOGO_POS := Vector2(86, 228)
const LOGO_SIZE := 190
const LINE_H := 186.0

var bg: Texture2D
var t := 0.0
var embers: Array = []
var smoke: Array = []
var soft: Texture2D
var font: FontVariation
var fill: Node2D
var press_start := true
var version := ""
var subtitle := "CUT THE EMBER RING"
var ui_font: Font

func _ready() -> void:
	bg = load("res://assets/ui/title_bg.jpg")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	font = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 1.1
	font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.16, 1.0), Vector2.ZERO)
	font.spacing_glyph = 6
	ui_font = preload("res://scripts/ui_style.gd").font("semibold")
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.width = 64; gt.height = 64
	gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(1.0, 0.5)
	soft = gt
	for i in 70: embers.append(_ember(true))
	for i in 9: smoke.append({"p": Vector2(randf_range(80, 700), randf_range(300, 900)), "s": randf_range(120, 240), "v": randf_range(8, 20), "a": randf_range(0.08, 0.16)})
	fill = Node2D.new()
	var m := ShaderMaterial.new(); m.shader = LogoShader; m.set_shader_parameter("line_height", LINE_H)
	m.set_shader_parameter("top0", LOGO_POS.y - LOGO_SIZE * 0.73); m.set_shader_parameter("cap", LOGO_SIZE * 0.73)
	fill.material = m
	fill.draw.connect(_draw_logo_fill)
	add_child(fill)
	version = str(ProjectSettings.get_setting("application/config/version", ""))

func _ember(anywhere: bool) -> Dictionary:
	return {"p": Vector2(randf_range(0, 1920), randf_range(0, 1080) if anywhere else randf_range(1090, 1200)),
		"v": Vector2(randf_range(-25, 15), randf_range(-90, -35)), "s": randf_range(2.0, 5.5), "ph": randf() * TAU,
		"c": Color(1, randf_range(0.45, 0.8), 0.2)}

func _process(delta: float) -> void:
	if not visible: return
	t += delta
	for e in embers:
		e.p += (e.v + Vector2(sin(t * 1.3 + e.ph) * 18.0, 0)) * delta
		if e.p.y < -20: e.merge(_ember(false), true)
	for s in smoke:
		s.p.x -= s.v * delta; s.p.y -= s.v * 0.3 * delta
		if s.p.x < -260: s.p = Vector2(randf_range(600, 900), randf_range(400, 950))
	queue_redraw(); fill.queue_redraw()

func _logo_lines() -> Array:
	return [["FIRE", LOGO_POS], ["BREAK", LOGO_POS + Vector2(34, LINE_H)]]

func _draw() -> void:
	# Background: slow breathing zoom plus a little mouse parallax.
	var z := 1.045 + 0.025 * sin(t * 0.11)
	var mouse := get_viewport().get_mouse_position() if is_inside_tree() else Vector2(960, 540)
	var par := (mouse - Vector2(960, 540)) / Vector2(960, 540) * -12.0
	var size := Vector2(1920, 1080) * z
	if bg:
		draw_texture_rect(bg, Rect2(Vector2(960, 540) - size * 0.5 + par, size), false)
	for s in smoke:
		draw_texture_rect(soft, Rect2(s.p - Vector2(s.s, s.s), Vector2(s.s, s.s) * 2.0), false, Color(0.08, 0.06, 0.05, s.a))
	# Left-side shade so the logo and menu read against the art.
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(980, 0), Vector2(620, 1080), Vector2(0, 1080)]),
		PackedColorArray([Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.55)]))
	# Logo back layers: drop shadow, dark rim, hot orange rim.
	for l in _logo_lines():
		draw_string_outline(font, l[1] + Vector2(10, 12), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, LOGO_SIZE, 34, Color(0, 0, 0, 0.6))
		draw_string_outline(font, l[1], l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, LOGO_SIZE, 30, Color(0.18, 0.04, 0.01))
		draw_string_outline(font, l[1], l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, LOGO_SIZE, 14, Color(1.0, 0.45, 0.08))
		draw_string_outline(font, l[1], l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, LOGO_SIZE, 6, Color(0.3, 0.06, 0.02))
	var sub := subtitle
	draw_string_outline(ui_font, LOGO_POS + Vector2(40, LINE_H + 74), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 8, Color(0, 0, 0, 0.85))
	draw_string(ui_font, LOGO_POS + Vector2(40, LINE_H + 74), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1, 0.86, 0.62))
	for e in embers:
		var fl := 0.6 + 0.4 * sin(t * 7.0 + e.ph)
		draw_texture_rect(soft, Rect2(e.p - Vector2(e.s, e.s) * 2.0, Vector2(e.s, e.s) * 4.0), false, Color(e.c.r, e.c.g, e.c.b, 0.85 * fl))
	if press_start:
		var a := 0.55 + 0.45 * sin(t * 3.4)
		var txt := "PRESS START"
		var f := ui_font
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 60).x
		var pos := Vector2(380 - w * 0.5, 820)
		draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 60, 12, Color(0, 0, 0, 0.8 * a))
		draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 60, Color(1, 0.88, 0.5, a))
		var hint := "Click, press Enter or a gamepad button"
		var hw := f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string_outline(f, Vector2(380 - hw * 0.5, 866), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, Color(0, 0, 0, 0.8))
		draw_string(f, Vector2(380 - hw * 0.5, 866), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.95, 0.88, 0.75))
	var credit := "A QuietByte game  ·  v" + version
	var cf := ui_font
	var cw := cf.get_string_size(credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string_outline(cf, Vector2(1890 - cw, 1058), credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, Color(0, 0, 0, 0.85))
	draw_string(cf, Vector2(1890 - cw, 1058), credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.92, 0.8, 0.9))

func _draw_logo_fill() -> void:
	for l in _logo_lines():
		fill.draw_string(font, l[1], l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, LOGO_SIZE, Color(1, 1, 1, 1))
