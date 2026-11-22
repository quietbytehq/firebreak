extends Node2D
## Painted campaign map. Shows the twelve-stage Ember Ring route, the current
## position, the next stage, and a one-line brief.

signal finished

const StageData := preload("res://scripts/stage_data.gd")
const UiStyle := preload("res://scripts/ui_style.gd")

var bg: Texture2D
var font_title: Font
var font_name: Font
var font_body: Font
var t := 0.0
var cleared_stage := 0   # 0 = preview (no stage just finished)
var preview := false
var stages: Array = []

func _ready() -> void:
	bg = load("res://assets/ui/travel_map.jpg")
	font_title = UiStyle.font("bold")
	font_name = UiStyle.font("semibold")
	font_body = UiStyle.font("medium")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	stages = StageData.campaign().get("stages", [])

func setup(cleared: int, is_preview: bool) -> void:
	cleared_stage = cleared
	preview = is_preview
	t = 0.0
	if stages.is_empty():
		stages = StageData.campaign().get("stages", [])
	queue_redraw()

func current_number() -> int:
	return 1 if preview or cleared_stage < 1 else cleared_stage

func next_entry() -> Dictionary:
	var n := current_number() + (0 if preview else 1)
	for s in stages:
		if int(s.get("number", 0)) == n:
			return s
	return {}

func hint_text() -> String:
	var nxt := next_entry()
	if nxt.is_empty():
		return "THE CHAIN IS CUT"
	var name := str(nxt.get("name", "Next stage"))
	if preview:
		return "THE EMBER RING ROUTE  ·  FIRST LINK: %s  ·  CLICK OR ENTER TO RETURN" % name.to_upper()
	if not bool(nxt.get("playable", false)):
		return "NEXT: %s — COMING SOON  ·  CLICK OR ENTER TO CONTINUE" % name.to_upper()
	return "NEXT: %s  ·  CLICK OR ENTER TO CONTINUE" % name.to_upper()

func brief_text() -> String:
	var nxt := next_entry()
	if nxt.is_empty():
		return "The Ember Ring is finished."
	return str(nxt.get("brief", ""))

func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	queue_redraw()

func _draw() -> void:
	if bg:
		draw_texture_rect(bg, Rect2(0, 0, 1920, 1080), false)
	# Caption plate over the painted dark margin.
	draw_rect(Rect2(0, 820, 1920, 260), Color(0.05, 0.03, 0.02, 0.72))
	draw_line(Vector2(80, 820), Vector2(1840, 820), Color(1, 0.75, 0.4, 0.45), 2.0)
	var title := "THE EMBER RING"
	draw_string_outline(font_title, Vector2(960, 870), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, 8, Color(0, 0, 0, 0.85))
	draw_string(font_title, Vector2(960, 870), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color(1, 0.82, 0.48))
	var brief := brief_text()
	if brief != "":
		draw_string_outline(font_body, Vector2(960, 918), brief, HORIZONTAL_ALIGNMENT_CENTER, -1, 30, 6, Color(0, 0, 0, 0.85))
		draw_string(font_body, Vector2(960, 918), brief, HORIZONTAL_ALIGNMENT_CENTER, -1, 30, Color(1, 0.93, 0.82))
	var hint := hint_text()
	var a := 0.55 + 0.45 * sin(t * 3.0)
	draw_string_outline(font_body, Vector2(960, 1008), hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, 6, Color(0, 0, 0, 0.85 * a))
	draw_string(font_body, Vector2(960, 1008), hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, Color(1, 0.86, 0.55, a))
	_draw_pins()

func _pin_pos(s: Dictionary) -> Vector2:
	var m: Array = s.get("map", [0.5, 0.5])
	return Vector2(float(m[0]) * 1920.0, float(m[1]) * 1080.0)

func _draw_pins() -> void:
	var cur := current_number()
	var nxt := cur if preview else cur + 1
	# Pins sit on the painted ember route; we don't redraw the path.
	for s in stages:
		var n := int(s.get("number", 0))
		var p := _pin_pos(s)
		var is_cur := n == cur
		var is_next := n == nxt and not preview
		var r := 16.0 if (is_cur or is_next) else 11.0
		if is_cur or is_next:
			r += 2.0 * sin(t * 4.0)
		var fill := Color(0.35, 0.3, 0.25, 0.95)
		if n <= cur and not preview:
			fill = Color(1, 0.78, 0.3)
		if is_cur:
			fill = Color(1, 0.9, 0.45)
		if is_next:
			fill = Color(1, 0.45, 0.15)
		draw_circle(p, r + 4.0, Color(0, 0, 0, 0.65))
		draw_circle(p, r + 2.0, Color(1, 0.7, 0.25, 0.9 if is_cur or is_next else 0.55))
		draw_circle(p, r, fill)
		draw_circle(p, maxf(3.0, r * 0.35), Color(0.15, 0.08, 0.04) if fill.r > 0.6 else Color(1, 0.85, 0.55))
		var num := str(n)
		draw_string_outline(font_name, Vector2(p.x, p.y - r - 6), num, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 4, Color(0, 0, 0, 0.85))
		draw_string(font_name, Vector2(p.x, p.y - r - 6), num, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1, 0.9, 0.7, 0.9))
		if is_cur or is_next:
			var label := str(s.get("name", ""))
			var ly := p.y + r + 22.0
			if ly > 790: ly = p.y - r - 24.0
			draw_string_outline(font_name, Vector2(p.x, ly), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 22, 6, Color(0, 0, 0, 0.85))
			draw_string(font_name, Vector2(p.x, ly), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color(1, 0.92, 0.7))
