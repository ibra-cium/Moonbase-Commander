extends Node3D

const ROCK_A: PackedScene = preload("res://assets/models/kaykit/rock_A.gltf")
const ROCK_B: PackedScene = preload("res://assets/models/kaykit/rock_B.gltf")
const ROCKS_A: PackedScene = preload("res://assets/models/kaykit/rocks_A.gltf")
const ROCKS_B: PackedScene = preload("res://assets/models/kaykit/rocks_B.gltf")

static func paint(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		paint(child, mat)

static func disable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		disable_shadows(child)

func _ready() -> void:
	_scatter_rocks()

func _scatter_rocks() -> void:
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color("#5E6166")
	rock_mat.roughness = 1.0

	var rock_scenes: Array[PackedScene] = [ROCK_A, ROCK_B, ROCKS_A, ROCKS_B]

	# 14 rocks scattered around perimeter and hills away from base center
	var rock_data: Array[Dictionary] = [
		{"scene_idx": 0, "pos": Vector3(-22.0, 0.0, -18.0), "scale": 1.2, "yaw": 0.5},
		{"scene_idx": 1, "pos": Vector3(-18.0, 0.0, -22.0), "scale": 0.9, "yaw": 1.8},
		{"scene_idx": 2, "pos": Vector3(20.0, 0.0, -20.0), "scale": 1.1, "yaw": 2.4},
		{"scene_idx": 0, "pos": Vector3(24.0, 0.0, -12.0), "scale": 0.8, "yaw": 0.2},
		{"scene_idx": 3, "pos": Vector3(-24.0, 0.0, 15.0), "scale": 1.0, "yaw": 3.1},
		{"scene_idx": 1, "pos": Vector3(-20.0, 0.0, 22.0), "scale": 1.3, "yaw": 1.1},
		{"scene_idx": 0, "pos": Vector3(18.0, 0.0, 22.0), "scale": 1.0, "yaw": 4.0},
		{"scene_idx": 2, "pos": Vector3(22.0, 0.0, 18.0), "scale": 0.9, "yaw": 5.2},
		{"scene_idx": 1, "pos": Vector3(-10.0, 0.0, -24.0), "scale": 1.1, "yaw": 0.9},
		{"scene_idx": 0, "pos": Vector3(8.0, 0.0, -24.0), "scale": 1.0, "yaw": 2.1},
		{"scene_idx": 3, "pos": Vector3(-25.0, 0.0, -2.0), "scale": 0.85, "yaw": 3.7},
		{"scene_idx": 1, "pos": Vector3(25.0, 0.0, 2.0), "scale": 1.2, "yaw": 1.5},
		{"scene_idx": 0, "pos": Vector3(-5.0, 0.0, 24.0), "scale": 1.15, "yaw": 4.5},
		{"scene_idx": 2, "pos": Vector3(8.0, 0.0, 25.0), "scale": 0.95, "yaw": 0.7},
	]

	for data in rock_data:
		var scene: PackedScene = rock_scenes[data["scene_idx"]]
		var node := scene.instantiate() as Node3D
		node.position = data["pos"]
		node.rotation.y = data["yaw"]
		var s: float = data["scale"]
		node.scale = Vector3(s, s, s)

		paint(node, rock_mat)
		disable_shadows(node)
		add_child(node)

