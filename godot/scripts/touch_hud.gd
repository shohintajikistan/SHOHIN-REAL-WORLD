extends Control

signal move_changed(value: Vector2)
signal look_changed(value: Vector2)
signal action_requested(action: String)

var left_finger := -1
var right_finger := -1
var left_origin := Vector2.ZERO
var left_value := Vector2.ZERO
var status_text := "После катастрофы: найди ресурсы и построй убежище"
var message_text := ""
var message_time := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_status(value: String) -> void:
	status_text = value
	queue_redraw()

func set_message(value: String) -> void:
	message_text = value
	message_time = 4.0
	queue_redraw()

func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_text = ""
			queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var font := get_theme_default_font()
	var base := Vector2(size.x * 0.16, size.y * 0.80)
	draw_rect(Rect2(14, 12, minf(size.x - 28.0, 470.0), 62), Color(0.015, 0.055, 0.04, 0.72), true)
	draw_string(font, Vector2(26, 36), "SHOHIN  •  AFTER THE FALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.75, 0.95, 0.72))
	draw_string(font, Vector2(26, 59), status_text, HORIZONTAL_ALIGNMENT_LEFT, minf(size.x - 52.0, 440.0), 12, Color.WHITE)
	if message_text != "":
		draw_rect(Rect2(size.x * 0.24, size.y * 0.17, size.x * 0.52, 42), Color(0.02, 0.09, 0.06, 0.82), true)
		draw_string(font, Vector2(size.x * 0.26, size.y * 0.17 + 26), message_text, HORIZONTAL_ALIGNMENT_CENTER, size.x * 0.48, 14, Color.WHITE)
	draw_circle(base, 62.0, Color(0.02, 0.08, 0.06, 0.38))
	draw_arc(base, 62.0, 0.0, TAU, 48, Color(0.65, 0.88, 0.72, 0.58), 3.0)
	draw_circle(base + left_value * 40.0, 27.0, Color(0.08, 0.55, 0.34, 0.85))
	var actions := [
		["СОБРАТЬ", "gather", Vector2(size.x * 0.86, size.y * 0.63)],
		["ДОМ", "hut", Vector2(size.x * 0.76, size.y * 0.79)],
		["ПЛОТ", "raft", Vector2(size.x * 0.90, size.y * 0.83)],
		["ТОПОР", "craft", Vector2(size.x * 0.76, size.y * 0.94)],
		["КОСТЁР", "fire", Vector2(size.x * 0.90, size.y * 0.94)],
		["КИРКА", "pick", Vector2(size.x * 0.63, size.y * 0.94)],
		["ЕСТЬ", "eat", Vector2(size.x * 0.63, size.y * 0.83)]
	]
	for entry in actions:
		var pos: Vector2 = entry[2]
		draw_circle(pos, 31.0, Color(0.035, 0.24, 0.16, 0.82))
		draw_arc(pos, 31.0, 0.0, TAU, 36, Color(0.70, 0.94, 0.72, 0.85), 2.0)
		draw_string(font, pos + Vector2(-29, 5), entry[0], HORIZONTAL_ALIGNMENT_CENTER, 58, 10, Color.WHITE)
	draw_circle(Vector2(size.x * 0.91, size.y * 0.49), 28.0, Color(0.06, 0.30, 0.20, 0.72))
	draw_string(font, Vector2(size.x * 0.91 - 16, size.y * 0.49 + 5), "JUMP", HORIZONTAL_ALIGNMENT_CENTER, 42, 11, Color.WHITE)

func _action_at(pos: Vector2, size: Vector2) -> String:
	var actions := [
		["gather", Vector2(size.x * 0.86, size.y * 0.63)],
		["hut", Vector2(size.x * 0.76, size.y * 0.79)],
		["raft", Vector2(size.x * 0.90, size.y * 0.83)],
		["craft", Vector2(size.x * 0.76, size.y * 0.94)],
		["fire", Vector2(size.x * 0.90, size.y * 0.94)],
		["pick", Vector2(size.x * 0.63, size.y * 0.94)],
		["eat", Vector2(size.x * 0.63, size.y * 0.83)]
	]
	for entry in actions:
		if pos.distance_to(entry[1]) < 40.0:
			return entry[0]
	return ""

func _input(event: InputEvent) -> void:
	var size := get_viewport_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			var action := _action_at(event.position, size)
			if action != "":
				action_requested.emit(action)
			elif event.position.x > size.x * 0.84 and event.position.y > size.y * 0.43 and event.position.y < size.y * 0.56:
				action_requested.emit("jump")
			elif event.position.x < size.x * 0.43 and event.position.y > size.y * 0.48 and left_finger == -1:
				left_finger = event.index
				left_origin = event.position
				left_value = Vector2.ZERO
			elif event.position.x >= size.x * 0.43 and right_finger == -1:
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
