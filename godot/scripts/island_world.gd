extends Node3D

# SHOHIN REAL WORLD — first Godot 4 island foundation.
# Island dimensions: 4,000 x 4,000 metres.
const ISLAND_SIZE := 4000.0
const GRID := 64
const WATER_LEVEL := -7.0

var terrain_noise := FastNoiseLite.new()

func _ready() -> void:
	_build_environment()
	_build_ocean()
	_build_island()
	_build_forests()
	_build_resource_props()
	_spawn_player()
	print("SHOHIN REAL WORLD: playable island loaded.")

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.58, 0.66, 0.72)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)

func _build_ocean() -> void:
	var ocean := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(ISLAND_SIZE * 2.5, ISLAND_SIZE * 2.5)
	ocean.mesh = plane
	ocean.position.y = WATER_LEVEL
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.025, 0.19, 0.25)
	water.metallic = 0.22
	water.roughness = 0.24
	water.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	ocean.material_override = water
	add_child(ocean)

func _height_at(x: float, z: float) -> float:
	var nx := x / (ISLAND_SIZE * 0.5)
	var nz := z / (ISLAND_SIZE * 0.5)
	var radius := sqrt(nx * nx + nz * nz)
	var coast := clampf(1.0 - radius, 0.0, 1.0)
	var broad := pow(coast, 0.62) * 250.0
	var mountain_noise := terrain_noise.get_noise_2d(x * 0.0017, z * 0.0017)
	var detail := terrain_noise.get_noise_2d(x * 0.006, z * 0.006) * 18.0
	var ridge := maxf(0.0, 1.0 - absf(terrain_noise.get_noise_2d(x * 0.0008 + 80.0, z * 0.0008)) * 2.0)
	var mountains := pow(coast, 0.9) * maxf(0.0, mountain_noise + 0.05) * ridge * 420.0
	return WATER_LEVEL - 3.0 + broad + mountains + detail * coast

func _build_island() -> void:
	terrain_noise.seed = 20261118
	terrain_noise.frequency = 1.0
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(GRID):
		for x in range(GRID):
			var x0 := (float(x) / GRID - 0.5) * ISLAND_SIZE
			var z0 := (float(z) / GRID - 0.5) * ISLAND_SIZE
			var x1 := (float(x + 1) / GRID - 0.5) * ISLAND_SIZE
			var z1 := (float(z + 1) / GRID - 0.5) * ISLAND_SIZE
			_add_terrain_triangle(st, Vector3(x0, _height_at(x0, z0), z0), Vector3(x1, _height_at(x1, z0), z0), Vector3(x0, _height_at(x0, z1), z1))
			_add_terrain_triangle(st, Vector3(x1, _height_at(x1, z0), z0), Vector3(x1, _height_at(x1, z1), z1), Vector3(x0, _height_at(x0, z1), z1))
	st.generate_normals()
	var terrain := MeshInstance3D.new()
	terrain.mesh = st.commit()
	var ground := StandardMaterial3D.new()
	ground.vertex_color_use_as_albedo = true
	ground.roughness = 1.0
	terrain.material_override = ground
	add_child(terrain)
	var ground_body := StaticBody3D.new()
	ground_body.name = "IslandCollision"
	var ground_collision := CollisionShape3D.new()
	ground_collision.shape = terrain.mesh.create_trimesh_shape()
	ground_body.add_child(ground_collision)
	add_child(ground_body)

func _add_terrain_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		var color := Color(0.12, 0.22, 0.12)
		if point.y < WATER_LEVEL + 8.0:
			color = Color(0.62, 0.53, 0.35)
		elif point.y > 250.0:
			color = Color(0.42, 0.43, 0.42)
		elif point.y > 105.0:
			color = Color(0.24, 0.27, 0.20)
		elif absf(point.x) < 700.0 and absf(point.z) < 700.0:
			color = Color(0.12, 0.29, 0.13)
		else:
			color = Color(0.16, 0.31, 0.14)
		st.set_color(color)
		st.add_vertex(point)

func _build_forests() -> void:
	var pine_mesh := _make_tree_mesh(false)
	var tropical_mesh := _make_tree_mesh(true)
	var pines := MultiMesh.new()
	pines.transform_format = MultiMesh.TRANSFORM_3D
	pines.mesh = pine_mesh
	pines.instance_count = 520
	var tropics := MultiMesh.new()
	tropics.transform_format = MultiMesh.TRANSFORM_3D
	tropics.mesh = tropical_mesh
	tropics.instance_count = 220
	var pine_i := 0
	var tropic_i := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 480021
	for i in range(1100):
		var x := rng.randf_range(-1850.0, 1850.0)
		var z := rng.randf_range(-1850.0, 1850.0)
		var radius := Vector2(x, z).length()
		if radius > 1850.0:
			continue
		var y := _height_at(x, z)
		if y < WATER_LEVEL + 10.0 or y > 280.0:
			continue
		var tropical_zone := (x > 350.0 and z > 250.0 and y < 100.0)
		var scale := rng.randf_range(0.75, 1.55)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * scale)
		var transform := Transform3D(basis, Vector3(x, y, z))
		if tropical_zone and tropic_i < tropics.instance_count:
			tropics.set_instance_transform(tropic_i, transform)
			tropic_i += 1
		elif pine_i < pines.instance_count:
			pines.set_instance_transform(pine_i, transform)
			pine_i += 1
	pines.instance_count = pine_i
	tropics.instance_count = tropic_i
	var pine_node := MultiMeshInstance3D.new()
	pine_node.multimesh = pines
	add_child(pine_node)
	var tropic_node := MultiMeshInstance3D.new()
	tropic_node.multimesh = tropics
	add_child(tropic_node)

func _make_tree_mesh(tropical: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.16 if tropical else 0.12
	trunk.bottom_radius = 0.24 if tropical else 0.19
	trunk.height = 5.0 if tropical else 7.0
	var trunk_surface := SurfaceTool.new()
	trunk_surface.create_from(trunk, 0)
	var trunk_array := trunk_surface.commit()
	var foliage_mesh: Mesh
	if tropical:
		var crown := SphereMesh.new()
		crown.radius = 2.0
		crown.height = 2.0
		foliage_mesh = crown
	else:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 2.0
		cone.height = 5.0
		foliage_mesh = cone
	var foliage_surface := SurfaceTool.new()
	foliage_surface.create_from(foliage_mesh, 0)
	var foliage_array := foliage_surface.commit()
	var combined := ArrayMesh.new()
	combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, trunk_array.surface_get_arrays(0))
	combined.surface_set_material(0, _tree_material(Color(0.24, 0.13, 0.07)))
	combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, foliage_array.surface_get_arrays(0))
	combined.surface_set_material(1, _tree_material(Color(0.08, 0.22, 0.09) if tropical else Color(0.055, 0.19, 0.075)))
	return combined

func _tree_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


func _build_resource_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261119
	for i in range(20):
		var x := rng.randf_range(-900.0, 900.0)
		var z := rng.randf_range(-900.0, 900.0)
		var y := _height_at(x, z)
		if y < WATER_LEVEL + 12.0:
			continue
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = rng.randf_range(0.7, 1.8)
		rock_mesh.height = rock_mesh.radius * 1.25
		rock.mesh = rock_mesh
		rock.position = Vector3(x, y + rock_mesh.radius * 0.35, z)
		rock.scale = Vector3(rng.randf_range(0.8, 1.4), rng.randf_range(0.55, 1.0), rng.randf_range(0.8, 1.3))
		var stone := StandardMaterial3D.new()
		stone.albedo_color = Color(0.28, 0.31, 0.29)
		stone.roughness = 1.0
		rock.material_override = stone
		add_child(rock)
	for i in range(10):
		var x := rng.randf_range(-1000.0, 1000.0)
		var z := rng.randf_range(-1000.0, 1000.0)
		var y := _height_at(x, z)
		if y < WATER_LEVEL + 12.0:
			continue
		var log := MeshInstance3D.new()
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.18
		log_mesh.bottom_radius = 0.22
		log_mesh.height = rng.randf_range(2.5, 4.5)
		log.mesh = log_mesh
		log.position = Vector3(x, y + 0.25, z)
		log.rotation.z = PI * 0.5
		var wood := StandardMaterial3D.new()
		wood.albedo_color = Color(0.27, 0.16, 0.085)
		wood.roughness = 1.0
		log.material_override = wood
		add_child(log)

func _spawn_player() -> void:
	var player_script = load("res://scripts/player_controller.gd")
	var player := CharacterBody3D.new()
	player.set_script(player_script)
	player.position = Vector3(0.0, _height_at(0.0, 0.0) + 2.0, 0.0)
	add_child(player)

