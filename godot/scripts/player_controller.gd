extends CharacterBody3D

const WALK_SPEED := 7.0
const RUN_SPEED := 11.0
const JUMP_VELOCITY := 6.5
const LOOK_SENSITIVITY := 0.004

var move_input := Vector2.ZERO
var camera_yaw := 0.0
var camera_pitch := -0.16
var hud: Control
var camera_pivot: Node3D
var body_mesh: Node3D
var walk_time := 0.0

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
	camera.look_at_from_position(camera.position, Vector3(0, 0.3, 0), Vector3.UP)
	camera.position = Vector3(0, 2.1, 6.8)
	camera_pivot.rotation.y = camera_yaw
	camera.rotation.x = camera_pitch

func _build_hud() -> void:
	hud = Control.new()
	hud.set_script(load("res://scripts/touch_hud.gd"))
	get_tree().root.add_child.call_deferred(hud)
	hud.move_changed.connect(_on_move_changed)
	hud.look_changed.connect(_on_look_changed)
	hud.jump_requested.connect(_on_jump_requested)

func _on_move_changed(value: Vector2) -> void:
	move_input = value

func _on_look_changed(delta: Vector2) -> void:
	camera_yaw -= delta.x * LOOK_SENSITIVITY
	camera_pitch = clampf(camera_pitch - delta.y * LOOK_SENSITIVITY, -0.85, 0.25)
	camera_pivot.rotation.y = camera_yaw
	camera_pivot.get_child(0).rotation.x = camera_pitch

func _on_jump_requested() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func _physics_process(delta: float) -> void:
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
		walk_time += delta * 9.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 5.0 * delta)
	move_and_slide()
