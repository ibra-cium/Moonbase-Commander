class_name BaseStation
extends Node3D

@onready var slots: Node3D = $Slots
@onready var static_buildings: Node3D = $StaticBuildings
@onready var cargo_spawns: Node3D = $CargoSpawns

# Material caches
var _mat_cable: StandardMaterial3D = null
var _mat_shield: StandardMaterial3D = null
var _mat_reactor_body: StandardMaterial3D = null
var _mat_reactor_rad: StandardMaterial3D = null
var _mat_battery_glow: StandardMaterial3D = null
var _mat_status_green: StandardMaterial3D = null
var _mat_status_yellow: StandardMaterial3D = null
var _mat_status_red: StandardMaterial3D = null
var _mat_panel_broken: StandardMaterial3D = null
var _mat_scratch: StandardMaterial3D = null
var _mat_regolith: StandardMaterial3D = null
var _mat_plant_green: StandardMaterial3D = null
var _mat_plant_brown: StandardMaterial3D = null
var _mat_lamp_lit: StandardMaterial3D = null
var _mat_lamp_unlit: StandardMaterial3D = null
var _mat_window: StandardMaterial3D = null

# Sun tracking & day-night state
var _last_sun_azimuth: float = 0.0
var _is_day: bool = true
var _current_broken_panels: int = 0

# Radar reference for slow turning
var _radar_node: Node3D = null

# Supply baselines for visual reactions
var _initial_o2_kg: float = 0.0
var _initial_water_kg: float = 0.0
var _initial_food_kg: float = 0.0
var _initial_shelter_g: float = 0.0
var _current_food_stage: String = "stacked"
var _food_slot_positions: Array[Vector3] = []

func _ready() -> void:
	_init_materials()
	_find_radar()
	_init_static_indicators()
	_connect_game_state()
	_find_and_connect_skyrig()

func _enter_tree() -> void:
	_connect_game_state()
	_find_and_connect_skyrig()

func _process(delta: float) -> void:
	if _radar_node != null:
		_radar_node.rotate_y(delta * 0.35)

func _init_materials() -> void:
	# Power cable: dark rubber black
	_mat_cable = StandardMaterial3D.new()
	_mat_cable.albedo_color = Color("#222428")
	_mat_cable.roughness = 0.9

	# Shield boxes: regolith/water shield grey
	_mat_shield = StandardMaterial3D.new()
	_mat_shield.albedo_color = Color("#6B7078")
	_mat_shield.roughness = 0.85

	# Reactor body: white/metallic with warm soft glow
	_mat_reactor_body = StandardMaterial3D.new()
	_mat_reactor_body.albedo_color = Color("#E9E7E2")
	_mat_reactor_body.emission_enabled = true
	_mat_reactor_body.emission = Color("#F2C14E")
	_mat_reactor_body.emission_energy_multiplier = 0.45
	_mat_reactor_body.roughness = 0.4

	# Reactor radiator panels: dark heat-radiating grey
	_mat_reactor_rad = StandardMaterial3D.new()
	_mat_reactor_rad.albedo_color = Color("#4E5156")
	_mat_reactor_rad.roughness = 0.8

	# Battery glow strip: Power yellow (#F2C14E) with dynamic emission
	_mat_battery_glow = StandardMaterial3D.new()
	_mat_battery_glow.albedo_color = Color("#F2C14E")
	_mat_battery_glow.emission_enabled = true
	_mat_battery_glow.emission = Color("#F2C14E")
	_mat_battery_glow.emission_energy_multiplier = 1.0
	_mat_battery_glow.roughness = 0.3

	# Status light materials per ART_DIRECTION §1
	_mat_status_green = StandardMaterial3D.new()
	_mat_status_green.albedo_color = Color("#44B35A") # Oxygen green
	_mat_status_green.emission_enabled = true
	_mat_status_green.emission = Color("#44B35A")
	_mat_status_green.emission_energy_multiplier = 1.5

	_mat_status_yellow = StandardMaterial3D.new()
	_mat_status_yellow.albedo_color = Color("#F2C14E") # Power yellow
	_mat_status_yellow.emission_enabled = true
	_mat_status_yellow.emission = Color("#F2C14E")
	_mat_status_yellow.emission_energy_multiplier = 1.5

	_mat_status_red = StandardMaterial3D.new()
	_mat_status_red.albedo_color = Color("#E04848") # Alert red
	_mat_status_red.emission_enabled = true
	_mat_status_red.emission = Color("#E04848")
	_mat_status_red.emission_energy_multiplier = 1.8

	# Broken solar panel material
	_mat_panel_broken = StandardMaterial3D.new()
	_mat_panel_broken.albedo_color = Color("#1A1C20")
	_mat_panel_broken.roughness = 0.95

	# Scratch decal material
	_mat_scratch = StandardMaterial3D.new()
	_mat_scratch.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_scratch.albedo_texture = preload("res://assets/particles/kenney/scratch_01.png")
	_mat_scratch.albedo_color = Color(1.0, 1.0, 1.0, 0.95)
	_mat_scratch.roughness = 0.8
	_mat_scratch.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Regolith mound material
	_mat_regolith = StandardMaterial3D.new()
	_mat_regolith.albedo_color = Color("#8B8D90") # Regolith grey
	_mat_regolith.roughness = 1.0

	# Plant cone materials
	_mat_plant_green = StandardMaterial3D.new()
	_mat_plant_green.albedo_color = Color("#44B35A") # Oxygen green
	_mat_plant_green.roughness = 0.7

	_mat_plant_brown = StandardMaterial3D.new()
	_mat_plant_brown.albedo_color = Color("#8B6239") # Wilt brown
	_mat_plant_brown.roughness = 0.9

	# Lamp materials
	_mat_lamp_lit = StandardMaterial3D.new()
	_mat_lamp_lit.albedo_color = Color("#FFF4E0")
	_mat_lamp_lit.emission_enabled = true
	_mat_lamp_lit.emission = Color("#FFF4E0")
	_mat_lamp_lit.emission_energy_multiplier = 1.2

	_mat_lamp_unlit = StandardMaterial3D.new()
	_mat_lamp_unlit.albedo_color = Color("#33363D")
	_mat_lamp_unlit.emission_enabled = false
	_mat_lamp_unlit.emission_energy_multiplier = 0.0

	# Module window glow material: warm interior light
	_mat_window = StandardMaterial3D.new()
	_mat_window.albedo_color = Color("#FFE8A0")
	_mat_window.emission_enabled = true
	_mat_window.emission = Color("#FFE8A0")
	_mat_window.emission_energy_multiplier = 0.0
	_mat_window.roughness = 0.3

func _find_radar() -> void:
	_radar_node = find_child("Roof_Radar", true, false) as Node3D
	if _radar_node == null:
		_radar_node = find_child("roof_radar", true, false) as Node3D

func _init_static_indicators() -> void:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return

	_init_lamp_lights()
	_tune_static_prop_shadows()

	var hab := static_buildings.find_child("Habitat", true, false) as Node3D
	if hab != null and hab.get_node_or_null("StatusLight") == null:
		var light_mesh := MeshInstance3D.new()
		light_mesh.name = "StatusLight"
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		light_mesh.mesh = sphere
		light_mesh.material_override = _mat_status_green
		light_mesh.position = Vector3(0.0, 1.25, 0.45)
		light_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hab.add_child(light_mesh)

	if hab != null and hab.get_node_or_null("WindowGlow_0") == null:
		var win_defs = [
			{"pos": Vector3(0.95, 1.1, 0.4), "size": Vector3(0.05, 0.3, 0.5)},
			{"pos": Vector3(-0.95, 1.1, 0.4), "size": Vector3(0.05, 0.3, 0.5)}
		]
		for idx in win_defs.size():
			var w_mesh := MeshInstance3D.new()
			w_mesh.name = "WindowGlow_%d" % idx
			var box := BoxMesh.new()
			box.size = win_defs[idx]["size"]
			w_mesh.mesh = box
			w_mesh.material_override = _mat_window
			w_mesh.position = win_defs[idx]["pos"]
			w_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			hab.add_child(w_mesh)

	var ls := static_buildings.find_child("LifeSupport", true, false) as Node3D
	if ls != null and ls.get_node_or_null("RecyclerLight") == null:
		var r_light := MeshInstance3D.new()
		r_light.name = "RecyclerLight"
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		r_light.mesh = sphere
		r_light.material_override = _mat_status_red
		r_light.position = Vector3(0.0, 1.25, 0.45)
		r_light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		r_light.visible = false
		ls.add_child(r_light)

	if ls != null and ls.get_node_or_null("WindowGlow_0") == null:
		var win_mesh := MeshInstance3D.new()
		win_mesh.name = "WindowGlow_0"
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.3, 0.5)
		win_mesh.mesh = box
		win_mesh.material_override = _mat_window
		win_mesh.position = Vector3(0.0, 1.1, 0.95)
		win_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ls.add_child(win_mesh)

	var shelter := static_buildings.find_child("Shelter", true, false) as Node3D
	if shelter != null and shelter.get_node_or_null("ShelterMound") == null:
		var mound := MeshInstance3D.new()
		mound.name = "ShelterMound"
		var sphere := SphereMesh.new()
		sphere.radius = 1.6
		sphere.height = 1.0
		mound.mesh = sphere
		mound.material_override = _mat_regolith
		mound.position = Vector3(0.0, 0.65, 0.0)
		mound.scale = Vector3(1.0, 0.3, 1.0)
		mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mound.visible = false
		shelter.add_child(mound)

	if shelter != null and shelter.get_node_or_null("ShelterDoorLight") == null:
		var d_light := MeshInstance3D.new()
		d_light.name = "ShelterDoorLight"
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		d_light.mesh = sphere
		d_light.material_override = _mat_status_red
		d_light.position = Vector3(0.0, 1.25, 1.4)
		d_light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		d_light.visible = false
		shelter.add_child(d_light)

func _get_constants_node():
	if is_inside_tree():
		return get_node_or_null("/root/Constants")
	return null

func _connect_game_state() -> void:
	if not is_inside_tree():
		return
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		if not gs.mission_started.is_connected(_on_mission_started):
			gs.mission_started.connect(_on_mission_started)
		if not gs.day_resolved.is_connected(_on_day_resolved):
			gs.day_resolved.connect(_on_day_resolved)

func _on_mission_started(mission: RefCounted) -> void:
	if mission != null and "cargo" in mission:
		build_from_cargo(mission.cargo)

func _on_day_resolved(report: RefCounted) -> void:
	apply_report(report)

func get_slot_position(slot_name: String) -> Vector3:
	if has_node("Slots/" + slot_name):
		return (get_node("Slots/" + slot_name) as Node3D).position
	return Vector3.ZERO

func get_job_spot_position(job_name: String, repair_target: String = "") -> Vector3:
	match job_name.to_upper():
		"REST":
			return get_slot_position("Slot_Job_Habitat")
		"CLEAN":
			return get_slot_position("Slot_Job_Panels")
		"FARM":
			return get_slot_position("Slot_Job_Greenhouse")
		"REGOLITH":
			return get_slot_position("Slot_Job_DigSite")
		"SCIENCE":
			return get_slot_position("Slot_Job_Drill")
		"REPAIR":
			if repair_target == "PANEL":
				return get_slot_position("Slot_Job_Panels")
			elif repair_target == "RECYCLER":
				return get_slot_position("Slot_Job_LifeSupport")
			else:
				if is_recycler_light_on():
					return get_slot_position("Slot_Job_LifeSupport")
				return get_slot_position("Slot_Job_Panels")
		"SHELTER", "SHELTERED", "STORM":
			return get_slot_position("Slot_Job_Shelter")
		"LANDER", "EVACUATE", "EVACUATING":
			return get_slot_position("Slot_Job_Lander")
		_:
			return get_slot_position("Slot_Job_Habitat")

func has_greenhouse_built() -> bool:
	return cargo_spawns != null and cargo_spawns.get_node_or_null("GreenhouseGroup") != null

func get_building_marker_anchor(building_key: String) -> Vector3:
	var local_spot: Vector3
	match building_key:
		"habitat":
			local_spot = get_job_spot_position("REST")
		"life_support":
			local_spot = get_job_spot_position("REPAIR", "RECYCLER")
		"solar":
			local_spot = get_job_spot_position("CLEAN")
		"greenhouse":
			local_spot = get_job_spot_position("FARM")
		"dig_site":
			local_spot = get_job_spot_position("REGOLITH")
		"drill":
			local_spot = get_job_spot_position("SCIENCE")
		_:
			local_spot = get_job_spot_position("REST")
	var local_anchor := local_spot + Vector3(0.0, 2.0, 0.0)
	return to_global(local_anchor) if is_inside_tree() else (position + local_anchor)

func _get_cargo_count(cargo, key: String) -> int:
	if cargo == null:
		return 0
	if cargo is Dictionary:
		return int(cargo.get(key, 0))
	if cargo.has_method("get_count"):
		return int(cargo.get_count(key))
	return 0

func clear_cargo() -> void:
	if cargo_spawns == null:
		return
	for child in cargo_spawns.get_children():
		child.queue_free()

func build_from_cargo(cargo) -> void:
	# Ensure spawns container is available
	if cargo_spawns == null:
		cargo_spawns = get_node_or_null("CargoSpawns")
		if cargo_spawns == null:
			cargo_spawns = Node3D.new()
			cargo_spawns.name = "CargoSpawns"
			add_child(cargo_spawns)

	# Remove previous cargo objects
	for child in cargo_spawns.get_children():
		cargo_spawns.remove_child(child)
		child.free()

	if _mat_cable == null:
		_init_materials()
	_init_static_indicators()

	var solar_count := _get_cargo_count(cargo, "solar")
	var battery_count := _get_cargo_count(cargo, "battery")
	var reactor_count := _get_cargo_count(cargo, "reactor")
	var gh_count := _get_cargo_count(cargo, "greenhouse")
	var o2_count := _get_cargo_count(cargo, "o2")
	var water_count := _get_cargo_count(cargo, "water")
	var food_count := _get_cargo_count(cargo, "food")
	var shield_count := _get_cargo_count(cargo, "shield")

	# Compute initial supply baselines
	var o2_unit_kg := 25.0
	var water_unit_kg := 45.0
	var food_crate_kg := 66.92
	var shield_unit_g := 1.0

	var c_node = _get_constants_node()
	if c_node != null and c_node.has_method("has"):
		if c_node.has("O2_UNIT_KG"):
			o2_unit_kg = float(c_node.v("O2_UNIT_KG"))
		if c_node.has("WATER_UNIT_KG"):
			water_unit_kg = float(c_node.v("WATER_UNIT_KG"))
		if c_node.has("FOOD_CRATE_MASS_KG"):
			food_crate_kg = float(c_node.v("FOOD_CRATE_MASS_KG"))
		if c_node.has("SHIELD_UNIT_G_CM2"):
			shield_unit_g = float(c_node.v("SHIELD_UNIT_G_CM2"))

	_initial_o2_kg = float(o2_count) * o2_unit_kg
	_initial_water_kg = float(water_count) * water_unit_kg
	_initial_food_kg = float(food_count) * food_crate_kg
	_initial_shelter_g = float(shield_count) * shield_unit_g
	_current_food_stage = "stacked"

	_spawn_solar(solar_count)
	_spawn_battery(battery_count)
	_spawn_reactors(reactor_count)
	_spawn_greenhouse(gh_count)
	_spawn_o2(o2_count)
	_spawn_water(water_count)
	_spawn_food(food_count)
	_spawn_shield(shield_count)

# --- Spawners ---

func _spawn_solar(count: int) -> void:
	if count <= 0:
		return
	var group := Node3D.new()
	group.name = "SolarGroup"
	cargo_spawns.add_child(group)

	var origin := get_slot_position("Slot_Solar")
	var per_row := 6
	var spacing_x := 1.8
	var spacing_z := 2.0

	for i in count:
		var scene: PackedScene = ModelCatalog.SCENE_SOLAR
		if scene == null:
			continue
		var inst := scene.instantiate() as Node3D
		var col := i % per_row
		var row := int(float(i) / float(per_row))
		inst.position = origin + Vector3(col * spacing_x, 0.0, row * spacing_z)
		ModelCatalog.set_shadows_enabled(inst, false)
		if _is_day:
			var mi := inst.find_child("solarpanel", true, false) as MeshInstance3D
			if mi == null:
				for c in inst.get_children():
					if c is MeshInstance3D:
						mi = c
						break
			if mi != null:
				mi.rotation.y = _last_sun_azimuth
		group.add_child(inst)

func _spawn_battery(count: int) -> void:
	if count <= 0:
		return
	var group := Node3D.new()
	group.name = "BatteryGroup"
	cargo_spawns.add_child(group)

	var origin := get_slot_position("Slot_Battery")
	var models_to_show := mini(count, 12)
	var per_row := 4
	var spacing := 0.7

	for i in models_to_show:
		var scene: PackedScene = ModelCatalog.SCENE_BATTERY
		if scene == null:
			continue
		var inst := scene.instantiate() as Node3D
		var col := i % per_row
		var row := int(float(i) / float(per_row))
		inst.position = origin + Vector3(col * spacing, 0.0, row * spacing)
		ModelCatalog.set_shadows_enabled(inst, false)

		# Emissive battery glow strip
		var glow_strip := MeshInstance3D.new()
		glow_strip.name = "GlowStrip"
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 0.04, 0.04)
		glow_strip.mesh = box
		glow_strip.material_override = _mat_battery_glow
		glow_strip.position = Vector3(0.0, 0.35, 0.28)
		glow_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		inst.add_child(glow_strip)

		group.add_child(inst)

	# If battery count exceeds 12, show ×N Label3D per task specification
	if count > 12:
		var label := Label3D.new()
		label.name = "BatteryMultiplierLabel"
		label.text = "×%d" % count
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("#F2C14E") # Power yellow
		label.outline_modulate = Color("#000000")
		label.outline_size = 8
		label.font_size = 48
		label.position = origin + Vector3(1.05, 0.9, 0.7)
		group.add_child(label)

func _spawn_reactors(count: int) -> void:
	if count <= 0:
		return
	var group := Node3D.new()
	group.name = "ReactorGroup"
	cargo_spawns.add_child(group)

	var origin := get_slot_position("Slot_Reactor")
	var hab_pos := get_slot_position("Slot_Habitat")

	for i in count:
		var r_pos := origin + Vector3(float(i) * 2.8, 0.0, 0.0)
		var reactor_inst := _create_single_reactor()
		reactor_inst.name = "Reactor_%d" % i
		reactor_inst.position = r_pos
		group.add_child(reactor_inst)

	# Thin cable (stretched box) from reactor area to habitat
	var cable := _create_cable(origin, hab_pos)
	group.add_child(cable)

func _create_single_reactor() -> Node3D:
	var reactor := Node3D.new()
	reactor.name = "Reactor"

	# Stand: KayKit lander_base
	var base_scene: PackedScene = ModelCatalog.SCENE_REACTOR_BASE
	if base_scene != null:
		var stand := base_scene.instantiate() as Node3D
		stand.name = "Stand"
		ModelCatalog.set_shadows_enabled(stand, false)
		reactor.add_child(stand)

	# Reactor core: CylinderMesh
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = 0.35
	cyl_mesh.bottom_radius = 0.35
	cyl_mesh.height = 1.0

	var core := MeshInstance3D.new()
	core.name = "Core"
	core.mesh = cyl_mesh
	core.material_override = _mat_reactor_body
	core.position = Vector3(0.0, 0.75, 0.0)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reactor.add_child(core)

	# 4 thin BoxMesh radiator panels
	var rad_defs = [
		{"pos": Vector3(0.0, 0.75, 0.55), "size": Vector3(0.04, 0.8, 0.4)},
		{"pos": Vector3(0.0, 0.75, -0.55), "size": Vector3(0.04, 0.8, 0.4)},
		{"pos": Vector3(0.55, 0.75, 0.0), "size": Vector3(0.4, 0.8, 0.04)},
		{"pos": Vector3(-0.55, 0.75, 0.0), "size": Vector3(0.4, 0.8, 0.04)}
	]

	var rads := Node3D.new()
	rads.name = "Radiators"
	reactor.add_child(rads)

	for d in rad_defs:
		var rad_mesh := BoxMesh.new()
		rad_mesh.size = d["size"]
		var r_inst := MeshInstance3D.new()
		r_inst.mesh = rad_mesh
		r_inst.material_override = _mat_reactor_rad
		r_inst.position = d["pos"]
		r_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rads.add_child(r_inst)

	return reactor

func _create_cable(from: Vector3, to: Vector3) -> MeshInstance3D:
	var cable := MeshInstance3D.new()
	cable.name = "PowerCable"

	var p1 := Vector3(from.x, 0.02, from.z)
	var p2 := Vector3(to.x, 0.02, to.z)
	var dist := p1.distance_to(p2)
	var center := (p1 + p2) * 0.5

	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.04, dist)

	cable.mesh = box
	cable.material_override = _mat_cable
	cable.position = center
	cable.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var dir := (p2 - p1).normalized()
	if dir.length_squared() > 0.001:
		var yaw := atan2(dir.x, dir.z)
		cable.rotation = Vector3(0.0, yaw, 0.0)

	return cable

func _spawn_greenhouse(area: int) -> void:
	if area <= 0:
		return

	var group := Node3D.new()
	group.name = "GreenhouseGroup"
	cargo_spawns.add_child(group)

	var origin := get_slot_position("Slot_Greenhouse")
	var scene: PackedScene = ModelCatalog.SCENE_GREENHOUSE
	if scene == null:
		return

	var inst := scene.instantiate() as Node3D
	inst.position = origin
	ModelCatalog.set_shadows_enabled(inst, true)

	# Tint dome pale green using duplicated material per spec
	var mi := inst.find_child("basemodule_E", true, false) as MeshInstance3D
	if mi != null and mi.mesh != null:
		var base_mat: Material = mi.mesh.surface_get_material(0)
		if base_mat is StandardMaterial3D:
			var dup_mat := (base_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			dup_mat.albedo_color = Color(0.75, 1.0, 0.75) # pale green tint
			mi.set_surface_override_material(0, dup_mat)

	# Code-built plant cones inside greenhouse
	var plant_bed := Node3D.new()
	plant_bed.name = "PlantBed"
	plant_bed.position = Vector3(0.0, 0.15, 0.0)
	inst.add_child(plant_bed)

	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = 0.13
	cone_mesh.height = 0.32

	var offsets = [
		Vector3(-0.4, 0.16, -0.3), Vector3(0.0, 0.16, -0.3), Vector3(0.4, 0.16, -0.3),
		Vector3(-0.4, 0.16, 0.3), Vector3(0.0, 0.16, 0.3), Vector3(0.4, 0.16, 0.3)
	]
	for idx in offsets.size():
		var cone := MeshInstance3D.new()
		cone.name = "PlantCone_%d" % idx
		cone.mesh = cone_mesh
		cone.material_override = _mat_plant_green
		cone.position = offsets[idx]
		cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plant_bed.add_child(cone)

	group.add_child(inst)

func _spawn_o2(count: int) -> void:
	if count <= 0:
		return
	var group := Node3D.new()
	group.name = "O2Group"
	cargo_spawns.add_child(group)

	var origin := get_slot_position("Slot_O2")
	var per_row := 2
	var spacing := 0.8

	for i in count:
		var scene: PackedScene = ModelCatalog.SCENE_O2
		if scene == null:
			continue
		var inst := scene.instantiate() as Node3D
		var col := i % per_row
		var row := int(float(i) / float(per_row))
		inst.position = origin + Vector3(col * spacing, 0.0, row * spacing)
		ModelCatalog.set_shadows_enabled(inst, false)
		group.add_child(inst)

func _spawn_water(count: int) -> void:
	if count <= 0:
		return
	var group := Node3D.new()
	group.name = "WaterGroup"
	cargo_spawns.add_child(group)

	var origin := get_slot_position("Slot_Water")
	var per_row := 2
	var spacing := 0.8

	for i in count:
		var scene: PackedScene = ModelCatalog.SCENE_WATER
		if scene == null:
			continue
		var inst := scene.instantiate() as Node3D
		var col := i % per_row
		var row := int(float(i) / float(per_row))
		inst.position = origin + Vector3(col * spacing, 0.0, row * spacing)
		ModelCatalog.set_shadows_enabled(inst, false)
		group.add_child(inst)

func _spawn_food(count: int) -> void:
	if count <= 0:
		return
	var group := Node3D.new()
	group.name = "FoodGroup"
	cargo_spawns.add_child(group)

	var origin := get_slot_position("Slot_Food")
	var per_row := 2
	var spacing := 1.1
	_food_slot_positions.clear()

	for i in count:
		var scene: PackedScene = ModelCatalog.SCENE_FOOD
		if scene == null:
			continue
		var inst := scene.instantiate() as Node3D
		var col := i % per_row
		var row := int(float(i) / float(per_row))
		var pos := origin + Vector3(col * spacing, 0.0, row * spacing)
		inst.position = pos
		_food_slot_positions.append(pos)
		ModelCatalog.set_shadows_enabled(inst, false)
		group.add_child(inst)

func _spawn_shield(count: int) -> void:
	if count <= 0:
		return
	var group := Node3D.new()
	group.name = "ShieldGroup"
	cargo_spawns.add_child(group)

	var shelter_pos := get_slot_position("Slot_Shelter")

	# Thickness scales with units: thicker look for more units
	var thickness := 0.15 + (float(count) / 10.0) * 0.25
	var height := 0.55

	# North barrier wall behind shelter
	var north_wall := MeshInstance3D.new()
	north_wall.name = "NorthWall"
	var north_mesh := BoxMesh.new()
	north_mesh.size = Vector3(2.5, height, thickness)
	north_wall.mesh = north_mesh
	north_wall.material_override = _mat_shield
	north_wall.position = shelter_pos + Vector3(0.0, height * 0.5, -0.65 - thickness * 0.5)
	north_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	group.add_child(north_wall)

	# East side barrier wall
	var east_wall := MeshInstance3D.new()
	east_wall.name = "EastWall"
	var east_mesh := BoxMesh.new()
	east_mesh.size = Vector3(thickness, height, 1.2)
	east_wall.mesh = east_mesh
	east_wall.material_override = _mat_shield
	east_wall.position = shelter_pos + Vector3(1.2 + thickness * 0.5, height * 0.5, 0.0)
	east_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	group.add_child(east_wall)

	# West side barrier wall
	var west_wall := MeshInstance3D.new()
	west_wall.name = "WestWall"
	var west_mesh := BoxMesh.new()
	west_mesh.size = Vector3(thickness, height, 1.2)
	west_wall.mesh = west_mesh
	west_wall.material_override = _mat_shield
	west_wall.position = shelter_pos + Vector3(-1.2 - thickness * 0.5, height * 0.5, 0.0)
	west_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	group.add_child(west_wall)

# --- Visual Reactions to Simulation Day Reports ---

func _get_report_field(report, field_name: String, default_val = null) -> Variant:
	if report == null:
		return default_val
	if report is Dictionary:
		return report.get(field_name, default_val)
	if field_name in report:
		return report.get(field_name)
	return default_val

func apply_report(report) -> void:
	if report == null:
		return

	if _mat_battery_glow == null:
		_init_materials()
	_init_static_indicators()

	var bat_pct: float = float(_get_report_field(report, "battery_percent", 100.0))
	var blackout: bool = bool(_get_report_field(report, "blackout", false))
	var co2_mmhg: float = float(_get_report_field(report, "co2_mmhg", 1.0))
	var co2_high: bool = bool(_get_report_field(report, "co2_high", false))
	var o2_kg: float = float(_get_report_field(report, "o2_kg", _initial_o2_kg))
	var water_kg: float = float(_get_report_field(report, "water_kg", _initial_water_kg))
	var food_kg: float = float(_get_report_field(report, "food_kg", _initial_food_kg))
	var shelter_g: float = float(_get_report_field(report, "shelter_g_cm2", _initial_shelter_g))
	var broken_panels: int = int(_get_report_field(report, "broken_panels", 0))
	var recycler_broken: bool = bool(_get_report_field(report, "recycler_broken", false))
	var gh_alive: bool = bool(_get_report_field(report, "greenhouse_alive", false))
	var gh_wilt: int = int(_get_report_field(report, "greenhouse_wilt_days", 0))
	var gh_growth: int = int(_get_report_field(report, "greenhouse_growth_days", 0))

	# Initialize fallback baselines if apply_report is tested before build_from_cargo
	if _initial_o2_kg <= 0.0 and o2_kg > 0.0:
		_initial_o2_kg = o2_kg
	if _initial_water_kg <= 0.0 and water_kg > 0.0:
		_initial_water_kg = water_kg
	if _initial_food_kg <= 0.0 and food_kg > 0.0:
		_initial_food_kg = food_kg
	if _initial_shelter_g <= 0.0 and shelter_g > 0.0:
		_initial_shelter_g = shelter_g

	# 1. Battery glow emission (modulated by battery fraction, extinguished in blackout)
	var bat_fraction: float = clampf(bat_pct / 100.0, 0.0, 1.0)
	_mat_battery_glow.emission_energy_multiplier = 0.0 if blackout else bat_fraction

	var day_num: int = int(_get_report_field(report, "day", -1))
	var sunset_day: int = 15
	var c_node = _get_constants_node()
	if c_node != null and c_node.has_method("has") and c_node.has("SUNSET_DAY"):
		sunset_day = int(c_node.v("SUNSET_DAY"))

	var is_night: bool = (day_num >= sunset_day or day_num == -1)
	_is_day = not is_night

	# 2. Status light on habitat roof
	var co2_limit: float = 3.0
	var co2_healthy: float = 2.0
	var warn_days: float = 3.0
	var o2_day_rate: float = 0.84 * 4.0
	var water_day_rate: float = 3.52 * 4.0
	var food_day_rate: float = 0.62 * 4.0

	if c_node != null and c_node.has_method("has"):
		if c_node.has("CO2_LIMIT_MMHG"):
			co2_limit = float(c_node.v("CO2_LIMIT_MMHG"))
		if c_node.has("CO2_HEALTHY_MAX_MMHG"):
			co2_healthy = float(c_node.v("CO2_HEALTHY_MAX_MMHG"))
		if c_node.has("SUPPLY_WARNING_DAYS"):
			warn_days = float(c_node.v("SUPPLY_WARNING_DAYS"))
		var crew_cnt: float = float(c_node.v("MISSION_CREW")) if c_node.has("MISSION_CREW") else 4.0
		if c_node.has("O2_KG_PERSON_DAY"):
			o2_day_rate = float(c_node.v("O2_KG_PERSON_DAY")) * crew_cnt
		if c_node.has("WATER_KG_PERSON_DAY"):
			water_day_rate = float(c_node.v("WATER_KG_PERSON_DAY")) * crew_cnt
		if c_node.has("FOOD_PACKED_KG_PERSON_DAY"):
			food_day_rate = float(c_node.v("FOOD_PACKED_KG_PERSON_DAY")) * crew_cnt

	var o2_days: float = (o2_kg / o2_day_rate) if o2_day_rate > 0.0 else 999.0
	var water_days: float = (water_kg / water_day_rate) if water_day_rate > 0.0 else 999.0
	var food_days: float = (food_kg / food_day_rate) if food_day_rate > 0.0 else 999.0

	var is_supply_low: bool = (
		o2_days < warn_days or water_days < warn_days or food_days < warn_days
		or (_initial_o2_kg > 0.0 and o2_kg < _initial_o2_kg * 0.2)
		or (_initial_water_kg > 0.0 and water_kg < _initial_water_kg * 0.2)
		or (_initial_food_kg > 0.0 and food_kg < _initial_food_kg * 0.2)
	)

	if blackout or co2_mmhg >= co2_limit or co2_high:
		_set_status_light("red")
	elif is_supply_low or co2_mmhg > co2_healthy:
		_set_status_light("yellow")
	else:
		_set_status_light("green")

	# 3. Night lamps & Window lights
	_update_lamps(blackout, is_night)
	_update_windows(blackout, is_night)

	# 4. Broken solar panels (dark material + scratch decal quad)
	_update_solar_panels(broken_panels)

	# 5. Recycler warning light on basemodule_C
	_update_recycler_light(recycler_broken)

	# 6. Shelter mound scaled by shelter_g_cm2
	_update_shelter_mound(shelter_g)

	# 7. Greenhouse plant cones
	_update_greenhouse(gh_alive, gh_wilt, gh_growth)

	# 8. O2 and water tank hiding (1 tank hidden per 20% used)
	_update_tank_group("O2Group", o2_kg, _initial_o2_kg)
	_update_tank_group("WaterGroup", water_kg, _initial_water_kg)

	# 9. Food crates (stacked -> packed -> single -> none)
	_update_food_crates(food_kg, _initial_food_kg)

	# 10. Shelter door alarm light during storm
	var storm_today := false
	if report != null:
		var storm_dose: float = float(_get_report_field(report, "storm_dose_msv", 0.0))
		if storm_dose > 0.0:
			storm_today = true
		elif "events" in report and report.events is Array:
			for evt in report.events:
				var code: String = str(evt.code if "code" in evt else (evt.get("code", "") if evt is Dictionary else ""))
				if code == "STORM_WARNING" or code == "SOLAR_STORM":
					storm_today = true
					break
	set_shelter_door_light(storm_today)

func _set_status_light(color_name: String) -> void:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return
	var hab := static_buildings.find_child("Habitat", true, false) as Node3D
	if hab == null:
		return
	var light_mesh := hab.get_node_or_null("StatusLight") as MeshInstance3D
	if light_mesh == null:
		return
	match color_name:
		"red":
			light_mesh.material_override = _mat_status_red
		"yellow":
			light_mesh.material_override = _mat_status_yellow
		"green", _:
			light_mesh.material_override = _mat_status_green

func _init_lamp_lights() -> void:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return
	var lamps_node := static_buildings.find_child("Lamps", true, false) as Node3D
	if lamps_node == null:
		return
	for lamp in lamps_node.get_children():
		var omni := lamp.get_node_or_null("LampOmni") as OmniLight3D
		if omni == null:
			omni = OmniLight3D.new()
			omni.name = "LampOmni"
			omni.light_color = Color("#FFF4E0")
			omni.light_energy = 1.2
			omni.omni_range = 8.0
			omni.omni_attenuation = 1.0
			omni.shadow_enabled = false
			omni.position = Vector3(0.0, 2.2, 0.0)
			omni.visible = false
			lamp.add_child(omni)

func _tune_static_prop_shadows() -> void:
	if static_buildings == null:
		return
	var lamps := static_buildings.find_child("Lamps", true, false)
	if lamps != null:
		ModelCatalog.set_shadows_enabled(lamps, false)
	var rover := static_buildings.find_child("Rover", true, false)
	if rover != null:
		for wheel_name in ["spacetruck_wheel_front_left", "spacetruck_wheel_front_right", "spacetruck_wheel_rear_left", "spacetruck_wheel_rear_right"]:
			var wheel = rover.find_child(wheel_name, true, false)
			if wheel is GeometryInstance3D:
				wheel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var trailer := static_buildings.find_child("Trailer", true, false)
	if trailer != null:
		for wheel_name in ["spacetruck_trailer_wheel_front_left", "spacetruck_trailer_wheel_front_right", "spacetruck_trailer_wheel_rear_left", "spacetruck_trailer_wheel_rear_right"]:
			var wheel = trailer.find_child(wheel_name, true, false)
			if wheel is GeometryInstance3D:
				wheel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var drill_mod := static_buildings.find_child("drill_module", true, false)
	if drill_mod is GeometryInstance3D:
		drill_mod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dig := static_buildings.find_child("DigSite", true, false)
	if dig != null:
		ModelCatalog.set_shadows_enabled(dig, false)
	var pad := static_buildings.find_child("LandingPad", true, false)
	if pad != null:
		ModelCatalog.set_shadows_enabled(pad, false)

func _update_lamps(blackout: bool, is_night: bool = true) -> void:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return
	var lamps_node := static_buildings.find_child("Lamps", true, false) as Node3D
	if lamps_node == null:
		return
	var should_be_lit := (is_night and not blackout)
	for lamp in lamps_node.get_children():
		var mi := lamp.find_child("lights", true, false) as MeshInstance3D
		if mi != null:
			mi.material_override = _mat_lamp_lit if should_be_lit else _mat_lamp_unlit
		var omni := lamp.get_node_or_null("LampOmni") as OmniLight3D
		if omni != null:
			omni.visible = should_be_lit

func _update_windows(blackout: bool, is_night: bool = true) -> void:
	if _mat_window == null:
		return
	if blackout or not is_night:
		_mat_window.emission_energy_multiplier = 0.0
	else:
		_mat_window.emission_energy_multiplier = 1.2

func _find_and_connect_skyrig() -> void:
	if not is_inside_tree():
		return
	var world_parent = find_parent("World")
	if world_parent != null:
		var sky = world_parent.get_node_or_null("SkyRig")
		if sky != null and sky.has_signal("sun_updated"):
			if not sky.sun_updated.is_connected(_on_sun_updated):
				sky.sun_updated.connect(_on_sun_updated)
			return
	if get_parent() != null:
		var sky = get_parent().get_node_or_null("SkyRig")
		if sky != null and sky.has_signal("sun_updated"):
			if not sky.sun_updated.is_connected(_on_sun_updated):
				sky.sun_updated.connect(_on_sun_updated)

func _on_sun_updated(_t: float, azimuth_rad: float, is_day: bool) -> void:
	update_sun_tracking(azimuth_rad, is_day)

func update_sun_tracking(azimuth_rad: float, is_day: bool) -> void:
	_last_sun_azimuth = azimuth_rad
	_is_day = is_day
	if not is_day:
		return
	if cargo_spawns == null:
		return
	var solar_group := cargo_spawns.get_node_or_null("SolarGroup") as Node3D
	if solar_group == null:
		return
	for i in solar_group.get_child_count():
		if i < _current_broken_panels:
			continue
		var panel := solar_group.get_child(i) as Node3D
		var mi := panel.find_child("solarpanel", true, false) as MeshInstance3D
		if mi == null:
			for c in panel.get_children():
				if c is MeshInstance3D and c.name != "ScratchDecal":
					mi = c
					break
		if mi != null:
			mi.rotation.y = azimuth_rad

func _update_solar_panels(broken_panels: int) -> void:
	_current_broken_panels = broken_panels
	if cargo_spawns == null:
		return
	var solar_group := cargo_spawns.get_node_or_null("SolarGroup") as Node3D
	if solar_group == null:
		return

	for i in solar_group.get_child_count():
		var panel_inst := solar_group.get_child(i) as Node3D
		var is_broken := (i < broken_panels)
		_update_single_panel(panel_inst, is_broken)
		if not is_broken and _is_day:
			var mi := panel_inst.find_child("solarpanel", true, false) as MeshInstance3D
			if mi == null:
				for c in panel_inst.get_children():
					if c is MeshInstance3D and c.name != "ScratchDecal":
						mi = c
						break
			if mi != null:
				mi.rotation.y = _last_sun_azimuth

func _update_single_panel(panel: Node3D, is_broken: bool) -> void:
	var mi := panel.find_child("solarpanel", true, false) as MeshInstance3D
	if mi == null:
		for c in panel.get_children():
			if c is MeshInstance3D and c.name != "ScratchDecal":
				mi = c
				break

	var decal := panel.get_node_or_null("ScratchDecal") as MeshInstance3D

	if is_broken:
		if mi != null:
			mi.material_override = _mat_panel_broken
		if decal == null:
			decal = MeshInstance3D.new()
			decal.name = "ScratchDecal"
			var qm := QuadMesh.new()
			qm.size = Vector2(0.55, 0.55)
			decal.mesh = qm
			decal.material_override = _mat_scratch
			decal.position = Vector3(0.0, 0.38, 0.0)
			decal.rotation_degrees = Vector3(-45.0, 0.0, 0.0)
			decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			panel.add_child(decal)
		decal.visible = true
	else:
		if mi != null:
			mi.material_override = null
		if decal != null:
			decal.visible = false

func _update_recycler_light(broken: bool) -> void:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return
	var ls := static_buildings.find_child("LifeSupport", true, false) as Node3D
	if ls == null:
		return
	var r_light := ls.get_node_or_null("RecyclerLight") as MeshInstance3D
	if r_light != null:
		r_light.visible = broken

func _update_shelter_mound(shelter_g_cm2: float) -> void:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return
	var shelter := static_buildings.find_child("Shelter", true, false) as Node3D
	if shelter == null:
		return
	var mound := shelter.get_node_or_null("ShelterMound") as MeshInstance3D
	if mound == null:
		return

	if shelter_g_cm2 <= 0.01:
		mound.visible = false
		return

	mound.visible = true
	var goal_g := 20.0
	var c_node = _get_constants_node()
	if c_node != null and c_node.has_method("has") and c_node.has("SHIELD_GOAL_G_CM2"):
		goal_g = float(c_node.v("SHIELD_GOAL_G_CM2"))

	var factor := clampf(shelter_g_cm2 / goal_g, 0.0, 2.0)
	mound.scale = Vector3(0.8 + factor * 0.4, 0.2 + factor * 0.8, 0.8 + factor * 0.4)

func _update_greenhouse(alive: bool, wilt_days: int, growth_days: int) -> void:
	if cargo_spawns == null:
		return
	var gh_group := cargo_spawns.get_node_or_null("GreenhouseGroup") as Node3D
	if gh_group == null or gh_group.get_child_count() == 0:
		return

	var gh_inst := gh_group.get_child(0) as Node3D
	var plant_bed := gh_inst.get_node_or_null("PlantBed") as Node3D
	if plant_bed == null:
		return

	if not alive:
		plant_bed.visible = false
		return

	plant_bed.visible = true
	var plant_mat := _mat_plant_brown if wilt_days > 0 else _mat_plant_green
	var plant_scale := Vector3.ONE * clampf(0.3 + float(growth_days) * 0.05, 0.3, 1.8)

	for cone in plant_bed.get_children():
		if cone is MeshInstance3D:
			cone.material_override = plant_mat
			cone.scale = plant_scale

func _update_tank_group(group_name: String, current_kg: float, initial_kg: float) -> void:
	if cargo_spawns == null:
		return
	var group := cargo_spawns.get_node_or_null(group_name) as Node3D
	if group == null:
		return
	var total_tanks := group.get_child_count()
	if total_tanks <= 0:
		return

	var used_fraction := 0.0
	if initial_kg > 0.0:
		used_fraction = clampf(1.0 - (current_kg / initial_kg), 0.0, 1.0)
	else:
		used_fraction = 1.0

	var tanks_to_hide := int((used_fraction + 0.0001) / 0.2)
	var visible_count := maxi(0, total_tanks - tanks_to_hide)
	if current_kg > 0.0 and visible_count == 0 and total_tanks > 0:
		visible_count = 1
	if current_kg <= 0.0:
		visible_count = 0

	for i in total_tanks:
		var tank := group.get_child(i) as Node3D
		tank.visible = (i < visible_count)

func _update_food_crates(current_kg: float, initial_kg: float) -> void:
	if cargo_spawns == null:
		return
	var group := cargo_spawns.get_node_or_null("FoodGroup") as Node3D
	if group == null:
		return
	var total_crates := group.get_child_count()
	if total_crates <= 0:
		return

	var remaining_fraction := 0.0
	if initial_kg > 0.0:
		remaining_fraction = clampf(current_kg / initial_kg, 0.0, 1.0)

	var target_stage := ""
	var target_scene: PackedScene = null

	if current_kg <= 0.0 or remaining_fraction <= 0.0:
		target_stage = "none"
	elif remaining_fraction <= 0.33:
		target_stage = "single"
		target_scene = ModelCatalog.SCENE_FOOD_SINGLE
	elif remaining_fraction <= 0.66:
		target_stage = "packed"
		target_scene = ModelCatalog.SCENE_FOOD_PACKED
	else:
		target_stage = "stacked"
		target_scene = ModelCatalog.SCENE_FOOD

	if target_stage == "none":
		for child in group.get_children():
			child.visible = false
		_current_food_stage = "none"
		return

	for child in group.get_children():
		child.visible = true

	if _current_food_stage != target_stage and target_scene != null:
		_current_food_stage = target_stage
		for i in total_crates:
			var old_child := group.get_child(i) as Node3D
			var pos := old_child.position
			var rot := old_child.rotation
			var new_inst := target_scene.instantiate() as Node3D
			new_inst.position = pos
			new_inst.rotation = rot
			ModelCatalog.set_shadows_enabled(new_inst, false)
			group.add_child(new_inst)
			group.move_child(new_inst, i)
			old_child.queue_free()

# --- Inspection & Testing Accessors ---

func get_status_light_state() -> String:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return ""
	var hab := static_buildings.find_child("Habitat", true, false) as Node3D
	if hab == null:
		return ""
	var light_mesh := hab.get_node_or_null("StatusLight") as MeshInstance3D
	if light_mesh == null or light_mesh.material_override == null:
		return ""
	if light_mesh.material_override == _mat_status_red:
		return "red"
	if light_mesh.material_override == _mat_status_yellow:
		return "yellow"
	if light_mesh.material_override == _mat_status_green:
		return "green"
	return ""

func are_lamps_lit() -> bool:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return false
	var lamps_node := static_buildings.find_child("Lamps", true, false) as Node3D
	if lamps_node == null or lamps_node.get_child_count() == 0:
		return false
	var first_lamp := lamps_node.get_child(0)
	var mi := first_lamp.find_child("lights", true, false) as MeshInstance3D
	if mi != null:
		return mi.material_override != _mat_lamp_unlit
	return true

func is_recycler_light_on() -> bool:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return false
	var ls := static_buildings.find_child("LifeSupport", true, false) as Node3D
	if ls == null:
		return false
	var r_light := ls.get_node_or_null("RecyclerLight") as MeshInstance3D
	if r_light != null:
		return r_light.visible
	return false

func set_recycler_light(broken: bool) -> void:
	_update_recycler_light(broken)

func get_rover() -> Node3D:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings != null:
		return static_buildings.find_child("Rover", true, false) as Node3D
	return null

func get_trailer() -> Node3D:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings != null:
		return static_buildings.find_child("Trailer", true, false) as Node3D
	return null

func get_drill_module() -> Node3D:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings != null:
		return static_buildings.find_child("drill_module", true, false) as Node3D
	return null

func get_solar_panels() -> Array[Node3D]:
	var result: Array[Node3D] = []
	if cargo_spawns != null:
		var solar_group := cargo_spawns.get_node_or_null("SolarGroup") as Node3D
		if solar_group != null:
			for child in solar_group.get_children():
				if child is Node3D:
					result.append(child)
	return result

func get_battery_glow_energy() -> float:
	if _mat_battery_glow != null:
		return _mat_battery_glow.emission_energy_multiplier
	return 0.0

func get_shelter_mound() -> MeshInstance3D:
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return null
	var shelter := static_buildings.find_child("Shelter", true, false) as Node3D
	if shelter != null:
		return shelter.get_node_or_null("ShelterMound") as MeshInstance3D
	return null

func get_food_stage() -> String:
	return _current_food_stage

func set_shelter_door_light(active: bool) -> void:
	if _mat_status_red == null:
		_init_materials()
	_init_static_indicators()
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return
	var shelter := static_buildings.find_child("Shelter", true, false) as Node3D
	if shelter != null:
		var dl := shelter.get_node_or_null("ShelterDoorLight") as MeshInstance3D
		if dl != null:
			dl.visible = active

func is_shelter_door_light_on() -> bool:
	if _mat_status_red == null:
		_init_materials()
	_init_static_indicators()
	if static_buildings == null:
		static_buildings = get_node_or_null("StaticBuildings")
	if static_buildings == null:
		return false
	var shelter := static_buildings.find_child("Shelter", true, false) as Node3D
	if shelter != null:
		var dl := shelter.get_node_or_null("ShelterDoorLight") as MeshInstance3D
		if dl != null:
			return dl.visible
	return false

func prepare_for_landing() -> void:
	if static_buildings != null:
		for child in static_buildings.get_children():
			if child.name != "LandingPad":
				child.scale = Vector3(0.001, 0.001, 0.001)
	if cargo_spawns != null:
		for child in cargo_spawns.get_children():
			child.scale = Vector3(0.001, 0.001, 0.001)

func reset_building_scales() -> void:
	if static_buildings != null:
		for child in static_buildings.get_children():
			child.scale = Vector3.ONE
	if cargo_spawns != null:
		for child in cargo_spawns.get_children():
			child.scale = Vector3.ONE

func animate_pop_in(duration: float = 0.4) -> Tween:
	var tween := create_tween()
	tween.set_parallel(true)
	var delay: float = 0.0
	var step: float = 0.03

	if static_buildings != null:
		for child in static_buildings.get_children():
			if child.name == "LandingPad":
				continue
			child.scale = Vector3(0.001, 0.001, 0.001)
			tween.tween_property(child, "scale", Vector3.ONE, duration).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			delay += step

	if cargo_spawns != null:
		for child in cargo_spawns.get_children():
			child.scale = Vector3(0.001, 0.001, 0.001)
			tween.tween_property(child, "scale", Vector3.ONE, duration).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			delay += step

	return tween


const COLLECT_OFFSET_SOLAR := Vector3(0.0, 2.2, 0.0)
const COLLECT_OFFSET_REACTOR := Vector3(0.0, 2.4, 0.0)
const COLLECT_OFFSET_DRILL := Vector3(0.0, 1.5, 0.0)
const COLLECT_OFFSET_SHELTER := Vector3(0.0, 1.8, 0.0)
const COLLECT_OFFSET_PLANTS := Vector3(0.0, 2.4, 0.0)


func get_collect_anchor(kind: String) -> Vector3:
	if cargo_spawns == null:
		cargo_spawns = get_node_or_null("CargoSpawns")
	match kind:
		"energy":
			return _get_energy_collect_anchor()
		"science":
			var drill: Node3D = get_drill_module()
			return _node_anchor_pos(drill) + COLLECT_OFFSET_DRILL if drill != null else Vector3.ZERO
		"shelter":
			var mound: MeshInstance3D = get_shelter_mound()
			return _node_anchor_pos(mound) + COLLECT_OFFSET_SHELTER if mound != null else Vector3.ZERO
		"plants":
			return _get_plants_collect_anchor()
		_:
			return Vector3.ZERO


func _get_energy_collect_anchor() -> Vector3:
	var solar_panels: Array[Node3D] = get_solar_panels()
	if not solar_panels.is_empty():
		var sum := Vector3.ZERO
		for panel in solar_panels:
			sum += _node_anchor_pos(panel)
		return sum / float(solar_panels.size()) + COLLECT_OFFSET_SOLAR

	if cargo_spawns == null:
		return Vector3.ZERO
	var reactor_group := cargo_spawns.get_node_or_null("ReactorGroup") as Node3D
	if reactor_group == null:
		return Vector3.ZERO
	var reactors: Array[Node3D] = []
	for child in reactor_group.get_children():
		if child is Node3D and child.name.begins_with("Reactor_"):
			reactors.append(child as Node3D)
	if reactors.is_empty():
		return Vector3.ZERO
	var r_sum := Vector3.ZERO
	for r in reactors:
		r_sum += _node_anchor_pos(r)
	return r_sum / float(reactors.size()) + COLLECT_OFFSET_REACTOR


func _get_plants_collect_anchor() -> Vector3:
	if cargo_spawns == null:
		return Vector3.ZERO
	var gh_group := cargo_spawns.get_node_or_null("GreenhouseGroup") as Node3D
	if gh_group == null:
		return Vector3.ZERO
	for child in gh_group.get_children():
		if child is Node3D:
			return _node_anchor_pos(child as Node3D) + COLLECT_OFFSET_PLANTS
	return Vector3.ZERO


func _node_anchor_pos(node: Node3D) -> Vector3:
	if node == null:
		return Vector3.ZERO
	if node.is_inside_tree():
		return node.global_position
	var pos := Vector3.ZERO
	var cur: Node = node
	while cur != null and cur != self:
		if cur is Node3D:
			pos += (cur as Node3D).position
		cur = cur.get_parent()
	return pos


