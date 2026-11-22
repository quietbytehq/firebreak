extends Node2D
## Opening dossier briefing. Types the mission orders over a painted map,
## skippable, with an optional "lock and load" voice line at the last sentence.

signal finished

const HEAD := "RAYAN  —  FIREBREAK UNIT"
const LINES := [
	"An arms network calling itself the Ember Ring has been moving weapons through river towns, desert tracks and quiet ports. They hide behind local gangs and leave civilians in the line of fire.",
	"Your orders are simple. Cut the chain. Spare the people who live along it. Do not let this fire jump to the next town.",
	"First link: a river village at golden hour. Lock and load.",
]
const CPS := 42.0          # characters per second
const LINE_PAUSE := 0.45

var bg: Texture2D
var font_head: Font
var font_body: Font
var font_hint: Font
var t := 0.0
var chars := 0.0
var shown := 0
var pause_left := 0.0
var done := false
var spoken := false
var voice_cb: Callable

func _ready() -> void:
	bg = load("res://assets/ui/briefing_bg.jpg")
	font_head = preload("res://scripts/ui_style.gd").font("bold")
	font_body = preload("res://scripts/ui_style.gd").font("medium")
	font_hint = preload("res://scripts/ui_style.gd").font("semibold")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	reset()

func reset() -> void:
	t = 0.0
	chars = 0.0
	shown = 0
	pause_left = 0.35
	done = false
	spoken = false
	queue_redraw()

func skip() -> void:
	shown = LINES.size()
	chars = 0.0
	pause_left = 0.0
	done = true
	_maybe_speak()
	queue_redraw()

func advance() -> void:
	if done:
		finished.emit()
	else:
		skip()

func _maybe_speak() -> void:
	if spoken:
		return
	if shown < LINES.size() and not (shown == LINES.size() - 1 and chars >= float(LINES[LINES.size() - 1].length())):
		return
	spoken = true
	if voice_cb.is_valid():
		voice_cb.call()

func _process(delta: float) -> void:
	if not visible or done:
		if visible:
			t += delta
			queue_redraw()
		return
	t += delta
	if pause_left > 0.0:
		pause_left -= delta
		queue_redraw()
		return
	if shown >= LINES.size():
		done = true
		_maybe_speak()
		queue_redraw()
		return
	chars += CPS * delta
	var need := float(LINES[shown].length())
	if chars >= need:
		chars = 0.0
		shown += 1
		pause_left = LINE_PAUSE
		if shown >= LINES.size():
			done = true
			_maybe_speak()
	elif shown == LINES.size() - 1 and chars >= need - 14.0:
		_maybe_speak()
	queue_redraw()

func _draw() -> void:
	if bg:
		draw_texture_rect(bg, Rect2(0, 0, 1920, 1080), false)
	# Left shade so the dossier text stays readable.
	draw_rect(Rect2(0, 0, 1040, 1080), Color(0.02, 0.015, 0.01, 0.55))
	draw_rect(Rect2(0, 0, 70, 1080), Color(0, 0, 0, 0.25))
	var origin := Vector2(110, 170)
	draw_string_outline(font_head, origin, HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, 8, Color(0, 0, 0, 0.85))
	draw_string(font_head, origin, HEAD, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color(1, 0.82, 0.48))
	draw_line(Vector2(110, 200), Vector2(820, 200), Color(1, 0.75, 0.4, 0.55), 2.0)
	var y := 250.0
	for i in LINES.size():
		var text := ""
		if i < shown:
			text = LINES[i]
		elif i == shown:
			text = LINES[i].substr(0, int(chars))
		if text == "":
			continue
		var wrapped := _wrap(text, 36, 700)
		for line in wrapped:
			draw_string_outline(font_body, Vector2(110, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, 7, Color(0, 0, 0, 0.85))
			draw_string(font_body, Vector2(110, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1, 0.93, 0.82))
			y += 46
		y += 22
	var hint := "CLICK OR ENTER TO CONTINUE" if done else "CLICK OR ENTER TO SKIP"
	var a := 0.55 + 0.45 * sin(t * 3.2) if done else 0.8
	draw_string_outline(font_hint, Vector2(110, 1008), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 6, Color(0, 0, 0, 0.85 * a))
	draw_string(font_hint, Vector2(110, 1008), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.86, 0.55, a))

func _wrap(s: String, size: int, width: float) -> PackedStringArray:
	var words := s.split(" ")
	var lines := PackedStringArray()
	var cur := ""
	for w in words:
		var trial := w if cur == "" else cur + " " + w
		if font_body.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
			cur = trial
		else:
			if cur != "":
				lines.append(cur)
			cur = w
	if cur != "":
		lines.append(cur)
	return lines
