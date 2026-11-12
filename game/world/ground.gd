extends Node3D

const TERRAIN_LOW: PackedScene = preload("res://assets/models/kaykit/terrain_low.gltf")
const TERRAIN_SLOPE: PackedScene = preload("res://assets/models/kaykit/terrain_slope.gltf")
const TERRAIN_MINING: PackedScene = preload("res://assets/models/kaykit/terrain_mining.gltf")

const GRID_SIZE := 30
const TILE_SIZE := 2.0

static func _find_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D and node.mesh:
		return node.mesh
	for child in node.get_children():
		var m := _find_mesh(child)
		if m:
			return m
	return null

static func _extract_mesh(scene: PackedScene) -> Mesh:
	var temp := scene.instantiate()
	var mesh := _find_mesh(temp)
	temp.free()
	return mesh

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
	_build_ground()

func _build_ground() -> void:
	var regolith_mat := StandardMaterial3D.new()
	regolith_mat.albedo_color = Color("#8B8D90")
	regolith_mat.roughness = 1.0

	var low_mesh := _extract_mesh(TERRAIN_LOW)
	var slope_mesh := _extract_mesh(TERRAIN_SLOPE)

	var low_transforms: Array[Transform3D] = []
	var slope_transforms: Array[Transform3D] = []

	# Crater grid positions (X, Z)
	var crater_positions := [
		Vector2i(6, 10),   # Crater 1 (Dig site area in West/North-West)
		Vector2i(22, 21),  # Crater 2 (South-East)
	]

	var half_grid: float = float(GRID_SIZE - 1) * 0.5

	for gx in range(GRID_SIZE):
		for gz in range(GRID_SIZE):
			var pos_x: float = (float(gx) - half_grid) * TILE_SIZE
			var pos_z: float = (float(gz) - half_grid) * TILE_SIZE
			var tile_pos := Vector3(pos_x, 0.0, pos_z)

			# Check if crater
			var is_crater := false
			for cp in crater_positions:
				if cp.x == gx and cp.y == gz:
					is_crater = true
					break

			if is_crater:
				var crater := TERRAIN_MINING.instantiate() as Node3D
				crater.position = tile_pos
				paint(crater, regolith_mat)
				disable_shadows(crater)
				add_child(crater)
				continue

			# Check if perimeter edge
			var is_north := (gz == 0)
			var is_south := (gz == GRID_SIZE - 1)
			var is_west := (gx == 0)
			var is_east := (gx == GRID_SIZE - 1)

			if is_north or is_south or is_west or is_east:
				var yaw := 0.0
				if is_north and is_west:
					yaw = PI * 0.75
				elif is_north and is_east:
					yaw = -PI * 0.75
				elif is_south and is_west:
					yaw = PI * 0.25
				elif is_south and is_east:
					yaw = -PI * 0.25
				elif is_north:
					yaw = PI
				elif is_south:
					yaw = 0.0
				elif is_west:
					yaw = PI * 0.5
				elif is_east:
					yaw = -PI * 0.5

				var t := Transform3D(Basis(Vector3.UP, yaw), tile_pos)
				slope_transforms.append(t)
			else:
				var t := Transform3D(Basis(), tile_pos)
				low_transforms.append(t)

	# MultiMesh for flat terrain tiles
	if low_mesh and not low_transforms.is_empty():
		var mm_low := MultiMesh.new()
		mm_low.transform_format = MultiMesh.TRANSFORM_3D
		mm_low.mesh = low_mesh
		mm_low.instance_count = low_transforms.size()
		for i in low_transforms.size():
			mm_low.set_instance_transform(i, low_transforms[i])

		var mmi_low := MultiMeshInstance3D.new()
		mmi_low.name = "TerrainFlat"
		mmi_low.multimesh = mm_low
		mmi_low.material_override = regolith_mat
		mmi_low.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi_low)

	# MultiMesh for slope edge tiles
	if slope_mesh and not slope_transforms.is_empty():
		var mm_slope := MultiMesh.new()
		mm_slope.transform_format = MultiMesh.TRANSFORM_3D
		mm_slope.mesh = slope_mesh
		mm_slope.instance_count = slope_transforms.size()
		for i in slope_transforms.size():
			mm_slope.set_instance_transform(i, slope_transforms[i])

		var mmi_slope := MultiMeshInstance3D.new()
		mmi_slope.name = "TerrainSlopes"
		mmi_slope.multimesh = mm_slope
		mmi_slope.material_override = regolith_mat
		mmi_slope.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi_slope)

