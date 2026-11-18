extends CharacterBody3D

const WALK_SPEED := 6.5
const RUN_SPEED := 10.0
const JUMP_VELOCITY := 6.5
const LOOK_SENSITIVITY := 0.004
const INTERACT_DISTANCE := 5.0

var move_input := Vector2.ZERO
var camera_yaw := 0.0
var camera_pitch := 0.16
var hud: Control
var camera_pivot: Node3D
var body_mesh: Node3D
var inventory := {"wood": 0, "stone": 0, "fiber": 0}
var health := 100.0
var hunger := 100.0
var thirst := 100.0
var survival_clock := 0.0
var built_count := 0

func _ready() -> void:
	name = "Player"
	floor_snap_length = 0.35
	_build_character()
	_build_camera()
	_build_hud()
	position.y += 5.0

func _build_character() -> void:
	var skin := _mat(Color(0.70, 0.48, 0.32), 0.9)
	var shirt := _mat(Color(0.12, 0.22, 0.17), 0.95)
	var pants := _mat(Color(0.12, 0.15, 0.14), 1.0)
	var boots := _mat(Color(0.055, 0.065, 0.055), 0.9)
	var pack := _mat(Color(0.34, 0.22, 0.12), 1.0)
	body_mesh = Node3D.new()
	body_mesh.name = "SurvivorModel"
	add_child(body_mesh)
	_add_capsule(body_mesh, "Torso", 0.34, 0.88, Vector3(0, 1.28, 0), shirt)
	_add_capsule(body_mesh, "Neck", 0.12, 0.22, Vector3(0, 1.82, 0), skin)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position = Vector3(0, 2.12, 0)
	head.material_override = skin
	body_mesh.add_child(head)
	_add_capsule(body_mesh, "LeftArm", 0.115, 0.78, Vector3(-0.43, 1.31, 0), shirt, Vector3(0, 0, -0.18))
	_add_capsule(body_mesh, "RightArm", 0.115, 0.78, Vector3(0.43, 1.31, 0), shirt, Vector3(0, 0, 0.18))
	_add_capsule(body_mesh, "LeftLeg", 0.15, 0.82, Vector3(-0.18, 0.48, 0), pants)
	_add_capsule(body_mesh, "RightLeg", 0.15, 0.82, Vector3(0.18, 0.48, 0), pants)
	_add_box(body_mesh, "LeftBoot", Vector3(0.25, 0.16, 0.38), Vector3(-0.18, 0.10, -0.06), boots)
	_add_box(body_mesh, "RightBoot", Vector3(0.25, 0.16, 0.38), Vector3(0.18, 0.10, -0.06), boots)
	_add_box(body_mesh, "Backpack", Vector3(0.52, 0.62, 0.24), Vector3(0, 1.35, 0.30), pack)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 2.15
	collision.shape = capsule
	collision.position.y = 1.08
	add_child(collision)

func _add_capsule(parent: Node3D, node_name: String, radius: float, height: float, pos: Vector3, material: Material, rot := Vector3.ZERO) -> void:
	var part := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	part.mesh = mesh
	part.position = pos
	part.rotation = rot
	part.material_override = material
	part.name = node_name
	parent.add_child(part)

func _add_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.material_override = material
	part.name = node_name
	parent.add_child(part)

func _mat(color: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.65, 0)
	add_child(camera_pivot)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.1, 6.8)
	camera.current = true
	camera.fov = 72.0
	camera_pivot.add_child(camera)
	camera_pivot.rotation.y = camera_yaw
	camera.rotation.x = camera_pitch

func _build_hud() -> void:
	hud = Control.new()
	hud.set_script(load("res://scripts/touch_hud.gd"))
	get_tree().root.add_child.call_deferred(hud)
	hud.move_changed.connect(_on_move_changed)
	hud.look_changed.connect(_on_look_changed)
	hud.action_requested.connect(_on_action_requested)
	_update_hud()

func _on_move_changed(value: Vector2) -> void:
	move_input = value

func _on_look_changed(delta: Vector2) -> void:
	camera_yaw -= delta.x * LOOK_SENSITIVITY
	camera_pitch = clampf(camera_pitch - delta.y * LOOK_SENSITIVITY, -0.85, 0.25)
	camera_pivot.rotation.y = camera_yaw
	camera_pivot.get_child(0).rotation.x = camera_pitch

func _on_action_requested(action: String) -> void:
	match action:
		"gather":
			_gather_nearest()
		"hut":
			_build_structure("hut")
		"raft":
			_build_structure("raft")
		"craft":
			_craft_tool()
		"jump":
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
		"rest":
			hunger = minf(100.0, hunger + 8.0)
			thirst = minf(100.0, thirst + 5.0)
	_update_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_gather_nearest()
		elif event.keycode == KEY_1:
			_build_structure("hut")
		elif event.keycode == KEY_2:
			_build_structure("raft")
		elif event.keycode == KEY_3:
			_craft_tool()
		_update_hud()

func _gather_nearest() -> void:
	var nearest: Node3D = null
	var nearest_distance := INTERACT_DISTANCE
	for item in get_tree().get_nodes_in_group("gatherable"):
		if not is_instance_valid(item):
			continue
		var distance := global_position.distance_to(item.global_position)
		if distance < nearest_distance:
			nearest = item
			nearest_distance = distance
	if nearest == null:
		_show_message("Подойди ближе к дереву или камням")
		return
	var kind: String = nearest.get_meta("resource_type", "wood")
	var amount: int = nearest.get_meta("amount", 1)
	inventory[kind] = int(inventory.get(kind, 0)) + amount
	nearest.queue_free()
	_show_message("Собрано: %s × %d" % [kind, amount])

func _craft_tool() -> void:
	if int(inventory.wood) >= 3 and int(inventory.stone) >= 2:
		inventory.wood -= 3
		inventory.stone -= 2
		_show_message("Каменный топор создан. Сбор ресурсов станет быстрее.")
	else:
		_show_message("Для топора нужно: 3 дерева и 2 камня")

func _build_structure(kind: String) -> void:
	if kind == "hut":
		if int(inventory.wood) < 8 or int(inventory.stone) < 3:
			_show_message("Для дома нужно: 8 дерева и 3 камня")
			return
		inventory.wood -= 8
		inventory.stone -= 3
		_place_hut()
		_show_message("Убежище построено. Теперь здесь можно укрыться.")
	else:
		if int(inventory.wood) < 12:
			_show_message("Для плота нужно 12 дерева")
			return
		inventory.wood -= 12
		_place_raft()
		_show_message("Плот готов. Следующая цель — исследовать берег.")
	built_count += 1

func _place_hut() -> void:
	var root := Node3D.new()
	root.name = "PlayerShelter"
	root.position = global_position + -global_transform.basis.z * 5.0
	get_tree().current_scene.add_child(root)
	var wood_mat := _mat(Color(0.30, 0.18, 0.09), 1.0)
	var wall := BoxMesh.new()
	wall.size = Vector3(4.0, 2.5, 0.22)
	for side in range(3):
		var part := MeshInstance3D.new()
		part.mesh = wall
		part.material_override = wood_mat
		part.position = Vector3(0, 1.25, -1.8 if side == 0 else 1.8)
		if side == 1:
			part.rotation.y = PI * 0.5
			part.position = Vector3(-2.0, 1.25, 0)
		if side == 2:
			part.rotation.y = PI * 0.5
			part.position = Vector3(2.0, 1.25, 0)
		root.add_child(part)
	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(4.6, 1.8, 4.6)
	roof.mesh = roof_mesh
	roof.position.y = 3.1
	roof.material_override = _mat(Color(0.16, 0.22, 0.12), 1.0)
	root.add_child(roof)

func _place_raft() -> void:
	var root := Node3D.new()
	root.name = "PlayerRaft"
	root.position = global_position + -global_transform.basis.z * 5.0
	get_tree().current_scene.add_child(root)
	var wood_mat := _mat(Color(0.36, 0.22, 0.11), 0.9)
	for i in range(5):
		var plank := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.48, 0.22, 3.8)
		plank.mesh = mesh
		plank.position.x = (float(i) - 2.0) * 0.5
		plank.material_override = wood_mat
		root.add_child(plank)

func _show_message(message: String) -> void:
	if hud:
		hud.set_message(message)

func _update_hud() -> void:
	if hud:
		hud.set_status("HP %d  |  Еда %d  |  Вода %d\nДерево %d  Камень %d  |  Постройки %d" % [int(health), int(hunger), int(thirst), int(inventory.wood), int(inventory.stone), built_count])

func _physics_process(delta: float) -> void:
	survival_clock += delta
	if survival_clock >= 12.0:
		survival_clock = 0.0
		hunger = maxf(0.0, hunger - 1.0)
		thirst = maxf(0.0, thirst - 1.5)
		if hunger <= 0.0 or thirst <= 0.0:
			health = maxf(0.0, health - 2.0)
		_update_hud()
	var keyboard := Vector2.ZERO
	keyboard.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	keyboard.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var input_dir := move_input if move_input.length() > 0.05 else keyboard.normalized()
	if not is_on_floor():
		velocity.y -= 19.0 * delta
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_yaw)
	var speed := RUN_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	if direction.length() > 0.05:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, atan2(-direction.x, -direction.z), delta * 9.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 5.0 * delta)
	move_and_slide()
