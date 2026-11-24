extends Node2D
## Title screen: Rayan's action-comic art full screen with a slow zoom and a
## little mouse parallax, rising embers and drifting smoke, the live
## "FIREBREAK" logo (stacked on the left, clear of Rayan's head), a pulsing
## PRESS START and a small QuietByte credit.

const LogoShader := preload("res://shaders/logo_fill.gdshader")
const Scores := preload("res://scripts/scores.gd")
const StageData := preload("res://scripts/stage_data.gd")
const UiStyleScript := preload("res://scripts/ui_style.gd")
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
var ui_font_bold: Font
var local_scores: Array = []
var stage_bests: Array = []
var player_label := "PLAYER"
var score_tab := "run"
const SCORES_RECT := Rect2(1410, 590, 490, 430)
const NAME_RECT := Rect2(1410, 528, 490, 52)
const GLOBAL_RECT := Rect2(1430, 958, 450, 48)
const GLOBAL_URL := "https://firebreak.quietbytehq.uk"

func _ready() -> void:
	bg = load("res://assets/ui/title_bg.jpg")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	font = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 1.1
	font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.16, 1.0), Vector2.ZERO)
	font.spacing_glyph = 6
	ui_font = UiStyleScript.font("semibold")
	ui_font_bold = UiStyleScript.font("bold")
	refresh_scores()
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

func refresh_scores() -> void:
	local_scores = Scores.load_scores()
	player_label = Scores.player_name()
	stage_bests = []
	for s in StageData.campaign().get("stages", []):
		if not bool(s.get("playable", false)):
			continue
		var n := int(s.get("number", 0))
		var list := Scores.load_stage_scores(n)
		var best: Dictionary = list[0] if not list.is_empty() else {}
		stage_bests.append({"number": n, "name": str(s.get("name", "Stage %d" % n)), "best": best})
	if score_tab != "run" and not tab_defs().any(func(d): return str(d.id) == score_tab):
		score_tab = "run"
	queue_redraw()

func tab_defs() -> Array:
	var out: Array = [{"id": "run", "title": "RUN"}]
	for s in StageData.campaign().get("stages", []):
		if bool(s.get("playable", false)):
			out.append({"id": str(int(s.get("number", 0))), "title": str(s.get("name", ""))})
	return out

func select_tab(id: String) -> void:
	for d in tab_defs():
		if str(d.id) == id:
			score_tab = id
			queue_redraw()
			return

func current_scores() -> Array:
	if score_tab == "run":
		return local_scores
	return Scores.load_stage_scores(int(score_tab))

func name_hit(pos: Vector2) -> bool:
	return NAME_RECT.has_point(pos)

func tab_hit(pos: Vector2) -> String:
	var defs := tab_defs()
	if defs.is_empty():
		return ""
	var r := SCORES_RECT
	var y := r.position.y + 42
	var x := r.position.x + 12
	var w := (r.size.x - 24.0) / float(defs.size())
	for i in defs.size():
		var tr := Rect2(x + w * i, y - 18, w, 26)
		if tr.has_point(pos):
			return str(defs[i].id)
	return ""

func global_hit(pos: Vector2) -> bool:
	return GLOBAL_RECT.has_point(pos)

func _draw_section_head(pos: Vector2, width: float, text: String) -> void:
	draw_string_outline(ui_font_bold, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, 20, 5, Color(0, 0, 0, 0.85))
	draw_string(ui_font_bold, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, 20, Color(1, 0.78, 0.42))

func _draw_score_line(pos: Vector2, line: String, col: Color, size: int = 20) -> void:
	draw_string_outline(ui_font, pos, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0, 0, 0, 0.85))
	draw_string(ui_font, pos, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _draw_local_scores() -> void:
	# Player name / Change name, just above the scores plate.
	var nr := NAME_RECT
	draw_rect(nr, Color(0.35, 0.18, 0.06, 0.88))
	draw_rect(nr, Color(1, 0.75, 0.4, 0.7), false, 2.0)
	var nl := "PLAYER  " + player_label + "    ·    CHANGE NAME"
	draw_string_outline(ui_font_bold, Vector2(nr.position.x, nr.position.y + 36), nl, HORIZONTAL_ALIGNMENT_CENTER, nr.size.x, 22, 5, Color(0, 0, 0, 0.85))
	draw_string(ui_font_bold, Vector2(nr.position.x, nr.position.y + 36), nl, HORIZONTAL_ALIGNMENT_CENTER, nr.size.x, 22, Color(1, 0.88, 0.5))
	var r := SCORES_RECT
	draw_rect(r, Color(0.04, 0.03, 0.02, 0.62))
	draw_rect(r, Color(1, 0.75, 0.4, 0.4), false, 2.0)
	var head := "LOCAL HIGH SCORES"
	draw_string_outline(ui_font_bold, Vector2(r.position.x, r.position.y + 28), head, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 24, 6, Color(0, 0, 0, 0.85))
	draw_string(ui_font_bold, Vector2(r.position.x, r.position.y + 28), head, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 24, Color(1, 0.82, 0.48))
	var defs := tab_defs()
	var y := r.position.y + 42
	var x := r.position.x + 12
	var tw := (r.size.x - 24.0) / float(maxi(defs.size(), 1))
	for i in defs.size():
		var d: Dictionary = defs[i]
		var on := str(d.id) == score_tab
		var col := Color(1, 0.9, 0.55) if on else Color(0.95, 0.88, 0.75, 0.8)
		var tx := x + tw * i
		if on:
			draw_rect(Rect2(tx, y - 16, tw - 4, 22), Color(1, 0.75, 0.4, 0.22))
		draw_string_outline(ui_font_bold, Vector2(tx, y + 2), str(d.title), HORIZONTAL_ALIGNMENT_CENTER, tw - 4, 16, 4, Color(0, 0, 0, 0.85))
		draw_string(ui_font_bold, Vector2(tx, y + 2), str(d.title), HORIZONTAL_ALIGNMENT_CENTER, tw - 4, 16, col)
	y += 28
	var rows := current_scores()
	if rows.is_empty():
		_draw_score_line(Vector2(r.position.x + 24, y + 8), "No scores yet", Color(0.95, 0.88, 0.75, 0.85))
	else:
		var n := mini(rows.size(), 10)
		for i in n:
			var s: Dictionary = rows[i]
			var line := "%2d  %-12s  %s" % [i + 1, str(s.get("name", "PLAYER")), _fmt_score(int(s.get("score", 0)))]
			var col := Color(1, 0.9, 0.55) if i == 0 else Color(1, 0.93, 0.82)
			_draw_score_line(Vector2(r.position.x + 24, y), line, col)
			y += 24
	var g := GLOBAL_RECT
	var pulse := 0.75 + 0.25 * sin(t * 3.0)
	draw_rect(g, Color(0.35, 0.18, 0.06, 0.88))
	draw_rect(g, Color(1, 0.75, 0.4, 0.7), false, 2.0)
	var gl := "GLOBAL SCORES"
	draw_string_outline(ui_font_bold, Vector2(g.position.x, g.position.y + 34), gl, HORIZONTAL_ALIGNMENT_CENTER, g.size.x, 26, 5, Color(0, 0, 0, 0.85))
	draw_string(ui_font_bold, Vector2(g.position.x, g.position.y + 34), gl, HORIZONTAL_ALIGNMENT_CENTER, g.size.x, 26, Color(1, 0.88, 0.5, pulse))

func _fmt_score(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

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
	_draw_local_scores()
	var credit := "A QuietByte game  ·  v" + version
	var cf := ui_font
	var cw := cf.get_string_size(credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string_outline(cf, Vector2(1890 - cw, 1058), credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, Color(0, 0, 0, 0.85))
	draw_string(cf, Vector2(1890 - cw, 1058), credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.92, 0.8, 0.9))

func _draw_logo_fill() -> void:
	for l in _logo_lines():
		fill.draw_string(font, l[1], l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, LOGO_SIZE, Color(1, 1, 1, 1))
