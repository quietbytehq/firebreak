extends Control
## Composites Rayan's cut-out bust into the result screen: a left vignette,
## a soft contact shadow, and a colour-graded, edge-feathered portrait so he
## sits in the battlefield instead of looking pasted on.

const SHADER := preload("res://shaders/result_portrait.gdshader")

var fail := false
var bust: Texture2D
var soft: Texture2D
var figure: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	bust = load("res://assets/ui/rayan_bust_cutout.png")
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 128
	gt.height = 128
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	soft = gt
	figure = TextureRect.new()
	figure.texture = bust
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	# Slightly larger than the old 540×720 card, sitting in the left column.
	figure.position = Vector2(-10, 70)
	figure.size = Vector2(680, 907)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	if fail:
		mat.set_shader_parameter("grade", Color(0.84, 0.68, 0.62))
		mat.set_shader_parameter("contrast", 0.92)
		mat.set_shader_parameter("fade_bottom", 0.26)
		mat.set_shader_parameter("fade_right", 0.10)
		mat.set_shader_parameter("fade_left", 0.015)
	else:
		mat.set_shader_parameter("grade", Color(1.06, 0.96, 0.84))
		mat.set_shader_parameter("contrast", 1.04)
		mat.set_shader_parameter("fade_bottom", 0.22)
		mat.set_shader_parameter("fade_right", 0.08)
		mat.set_shader_parameter("fade_left", 0.015)
	figure.material = mat
	add_child(figure)

func _draw() -> void:
	# Left pocket of shade so Rayan reads against the dusk battlefield.
	var a0 := 0.50 if fail else 0.32
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(920, 0), Vector2(640, 1080), Vector2(0, 1080)]),
		PackedColorArray([Color(0, 0, 0, a0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, a0 + 0.12)])
	)
	# Soft contact shadow behind the torso, grounding him on the sandbags.
	if soft:
		var col := Color(0, 0, 0, 0.50 if fail else 0.36)
		draw_texture_rect(soft, Rect2(40, 420, 620, 780), false, col)
