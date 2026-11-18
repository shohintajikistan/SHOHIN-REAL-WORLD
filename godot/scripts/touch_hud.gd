extends Control

signal move_changed(value: Vector2)
signal look_changed(value: Vector2)
signal jump_requested

var left_finger := -1
var right_finger := -1
var left_origin := Vector2.ZERO
var left_value := Vector2.ZERO
var jump_flash := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var base := Vector2(size.x * 0.17, size.y * 0.80)
	draw_circle(base, 66.0, Color(0.02, 0.08, 0.06, 0.35))
	draw_arc(base, 66.0, 0.0, TAU, 48, Color(0.65, 0.88, 0.72, 0.55), 3.0)
	var knob := base + left_value * 43.0
	draw_circle(knob, 29.0, Color(0.08, 0.55, 0.34, 0.82))
	draw_arc(knob, 29.0, 0.0, TAU, 36, Color(0.82, 1.0, 0.85, 0.9), 2.0)
	var jump_pos := Vector2(size.x * 0.86, size.y * 0.81)
	draw_circle(jump_pos, 38.0, Color(0.06, 0.30, 0.20, 0.72))
	draw_arc(jump_pos, 38.0, 0.0, TAU, 40, Color(0.78, 0.95, 0.72, 0.9), 3.0)
	draw_string(get_theme_default_font(), jump_pos + Vector2(-23, 7), "JUMP", HORIZONTAL_ALIGNMENT_CENTER, 48, 16, Color.WHITE)
	draw_string(get_theme_default_font(), Vector2(22, 34), "SHOHIN REAL WORLD", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.82, 0.95, 0.84, 0.9))

func _input(event: InputEvent) -> void:
	var size := get_viewport_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x > size.x * 0.76 and event.position.y > size.y * 0.68:
				jump_requested.emit()
			elif event.position.x < size.x * 0.48 and event.position.y > size.y * 0.48 and left_finger == -1:
				left_finger = event.index
				left_origin = event.position
				left_value = Vector2.ZERO
			elif event.position.x >= size.x * 0.48 and right_finger == -1:
				right_finger = event.index
		else:
			if event.index == left_finger:
				left_finger = -1
				left_value = Vector2.ZERO
				move_changed.emit(left_value)
				queue_redraw()
			if event.index == right_finger:
				right_finger = -1
	elif event is InputEventScreenDrag:
		if event.index == left_finger:
			left_value = ((event.position - left_origin) / 58.0).limit_length(1.0)
			move_changed.emit(left_value)
			queue_redraw()
		elif event.index == right_finger:
			look_changed.emit(event.relative)
