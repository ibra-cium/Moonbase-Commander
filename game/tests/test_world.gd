extends "res://tests/test_case.gd"

func test_skyrig_instantiation_and_methods() -> void:
	var skyrig_scene: PackedScene = load("res://world/SkyRig.tscn")
	assert_true(skyrig_scene != null, "SkyRig.tscn should load")
	if skyrig_scene == null:
		return

	var skyrig: Node3D = skyrig_scene.instantiate() as Node3D
	assert_true(skyrig != null, "SkyRig should instantiate")

	# Check children
	assert_true(skyrig.has_node("WorldEnvironment"), "SkyRig must have WorldEnvironment")
	assert_true(skyrig.has_node("SunLight"), "SkyRig must have SunLight")
	assert_true(skyrig.has_node("SunGlow"), "SkyRig must have SunGlow")
	assert_true(skyrig.has_node("Stars"), "SkyRig must have Stars")
	assert_true(skyrig.has_node("Earth"), "SkyRig must have Earth")

	# Trigger _ready
	skyrig._ready()

	# Check sun progress calculation
	var p1: float = skyrig.sun_progress(1, 0.0)
	var p_sunset: float = skyrig.sun_progress(15, 0.5)
	assert_near(p1, 0.0, 0.01, "Day 1 sunrise progress should be 0.0")
	assert_near(p_sunset, 1.0, 0.05, "Sunset day should reach 1.0")

	# Test apply_sun
	skyrig.apply_sun(0.0)
	var sun: DirectionalLight3D = skyrig.get_node("SunLight") as DirectionalLight3D
	assert_near(sun.light_energy, 1.4, 0.01, "Sun energy should be SUN_ENERGY at t=0")

	skyrig.apply_sun(1.0)
	assert_near(sun.light_energy, 0.0, 0.01, "Sun energy should be 0.0 at night (t>=1)")

	skyrig.free()

func test_camera_rig_instantiation() -> void:
	var cam_scene: PackedScene = load("res://world/CameraRig.tscn")
	assert_true(cam_scene != null, "CameraRig.tscn should load")
	if cam_scene == null:
		return

	var cam_rig: Node3D = cam_scene.instantiate() as Node3D
	assert_true(cam_rig != null, "CameraRig should instantiate")
	assert_true(cam_rig.has_node("YawNode"), "CameraRig must have YawNode")
	assert_true(cam_rig.has_node("YawNode/PitchNode"), "CameraRig must have PitchNode")
	assert_true(cam_rig.has_node("YawNode/PitchNode/Camera3D"), "CameraRig must have Camera3D")

	cam_rig._ready()
	assert_near(cam_rig.current_distance, 35.0, 0.1, "Default camera distance should be 35")
	assert_true(cam_rig.min_pitch_deg <= 25.0, "Min pitch should be clamped properly")
	assert_true(cam_rig.max_pitch_deg >= 65.0, "Max pitch should be clamped properly")

	cam_rig.free()

func test_ground_and_rocks() -> void:
	var ground_node := Node3D.new()
	ground_node.set_script(load("res://world/ground.gd"))
	ground_node._ready()

	var child_count := ground_node.get_child_count()
	assert_true(child_count >= 3, "Ground should have TerrainFlat, TerrainSlopes and craters")
	var has_flat := ground_node.has_node("TerrainFlat")
	var has_slopes := ground_node.has_node("TerrainSlopes")
	assert_true(has_flat, "Ground should have MultiMesh TerrainFlat")
	assert_true(has_slopes, "Ground should have MultiMesh TerrainSlopes")

	ground_node.free()

	var rocks_node := Node3D.new()
	rocks_node.set_script(load("res://world/rocks.gd"))
	rocks_node._ready()

	var rock_count := rocks_node.get_child_count()
	assert_true(rock_count >= 10 and rock_count <= 15, "Should have 10-15 rocks (got %d)" % rock_count)

	# Verify rock material and no shadows
	for child in rocks_node.get_children():
		var geom: GeometryInstance3D = null
		if child is GeometryInstance3D:
			geom = child
		else:
			for c in child.get_children():
				if c is GeometryInstance3D:
					geom = c
					break
		if geom:
			assert_eq(geom.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Rock must not cast shadows")
			if geom is MeshInstance3D and geom.material_override is StandardMaterial3D:
				var mat: StandardMaterial3D = geom.material_override
				assert_near(mat.albedo_color.r, Color("#5E6166").r, 0.05, "Rock grey color match")

	rocks_node.free()

func test_world_scene_structure() -> void:
	var world_scene: PackedScene = load("res://world/World.tscn")
	assert_true(world_scene != null, "World.tscn should load")
	if world_scene == null:
		return

	var world: Node3D = world_scene.instantiate() as Node3D
	assert_true(world != null, "World should instantiate")

	# Check all ARCHITECTURE required children
	assert_true(world.has_node("Ground"), "World must have Ground")
	assert_true(world.has_node("Rocks"), "World must have Rocks")
	assert_true(world.has_node("Base"), "World must have Base")
	assert_true(world.has_node("Crew"), "World must have Crew")
	assert_true(world.has_node("SkyRig"), "World must have SkyRig")
	assert_true(world.has_node("CameraRig"), "World must have CameraRig")
	assert_true(world.has_node("Effects"), "World must have Effects")

	world.free()

func test_main_scene_has_world() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	assert_true(main_scene != null, "Main.tscn should load")
	if main_scene == null:
		return

	var main: Node = main_scene.instantiate()
	assert_true(main.has_node("World"), "Main must have World instance")
	var world: Node = main.get_node("World")
	assert_true(world.has_node("SkyRig"), "Main/World must have SkyRig")
	assert_true(world.has_node("CameraRig"), "Main/World must have CameraRig")

	main.free()

func test_skyrig_day_progression_and_sun_tracking() -> void:
	var skyrig_scene: PackedScene = load("res://world/SkyRig.tscn")
	var skyrig: Node3D = skyrig_scene.instantiate() as Node3D
	skyrig._ready()

	# Test set_day Day 1
	skyrig.call("set_day", 1, 0.0)
	assert_true(skyrig.call("is_day"), "Day 1 should be day")
	assert_near(skyrig.call("get_sun_t"), 0.0, 0.01, "Day 1 sunrise t should be 0.0")

	# Test signal emission
	var captured := {"received": false, "azimuth": 0.0}
	skyrig.connect("sun_updated", func(t, azimuth, is_d):
		captured["received"] = true
		captured["azimuth"] = azimuth
	)
	skyrig.call("set_day", 8, 0.5)
	assert_true(captured["received"], "sun_updated signal should be emitted")
	assert_near(skyrig.call("get_sun_azimuth"), captured["azimuth"], 0.01, "Azimuth should match")

	# Test sunset day night
	skyrig.call("set_day", 15, 1.0)
	assert_true(not skyrig.call("is_day"), "Day 15 end should be night")
	var sun: DirectionalLight3D = skyrig.get_node("SunLight") as DirectionalLight3D
	assert_near(sun.light_energy, 0.0, 0.01, "Sun energy at night should be 0.0")

	skyrig.free()

func test_base_night_lighting_and_omni_lights() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	# Verify LampOmni exists on lamps
	var lamp0 = base.get_node("StaticBuildings/Lamps/Lamp_0")
	assert_true(lamp0.has_node("LampOmni"), "Lamp_0 must have LampOmni")
	var omni: OmniLight3D = lamp0.get_node("LampOmni") as OmniLight3D
	assert_true(omni != null, "LampOmni must be OmniLight3D")
	assert_true(not omni.shadow_enabled, "Omni light should not cast shadow for performance")

	# Verify window glow meshes
	assert_true(base.has_node("StaticBuildings/Habitat/WindowGlow_0"), "Habitat must have WindowGlow")
	assert_true(base.has_node("StaticBuildings/LifeSupport/WindowGlow_0"), "LifeSupport must have WindowGlow")

	# Daytime report (Day 5, no blackout)
	base.call("apply_report", {"day": 5, "blackout": false, "battery_percent": 100.0})
	assert_true(not base.call("are_lamps_lit"), "Lamps should be unlit in daytime")
	assert_true(not omni.visible, "OmniLight should be invisible in daytime")

	# Sunset / night report (Day 15, no blackout)
	base.call("apply_report", {"day": 15, "blackout": false, "battery_percent": 90.0})
	assert_true(base.call("are_lamps_lit"), "Lamps should be lit at sunset/night")
	assert_true(omni.visible, "OmniLight should be visible at night")

	# Blackout report (Day 16, blackout)
	base.call("apply_report", {"day": 16, "blackout": true, "battery_percent": 0.0})
	assert_true(not base.call("are_lamps_lit"), "Lamps should be extinguished in blackout")
	assert_true(not omni.visible, "OmniLight should be off in blackout")
	assert_eq(base.call("get_status_light_state"), "red", "Status light should be red in blackout")
	assert_near(base.call("get_battery_glow_energy"), 0.0, 0.01, "Battery glow should be 0 in blackout")

	base.free()

func test_solar_panels_tracking_sun() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	base.call("build_from_cargo", {"solar": 3})
	var solar_group: Node3D = base.get_node("CargoSpawns/SolarGroup")
	assert_eq(solar_group.get_child_count(), 3, "Should have 3 panels")

	# Track sun to +45 deg (PI/4)
	var angle1 := PI / 4.0
	base.call("update_sun_tracking", angle1, true)

	var p0_mi := solar_group.get_child(0).find_child("solarpanel", true, false) as MeshInstance3D
	var p1_mi := solar_group.get_child(1).find_child("solarpanel", true, false) as MeshInstance3D
	assert_near(p0_mi.rotation.y, angle1, 0.01, "Panel 0 should orient to sun azimuth")
	assert_near(p1_mi.rotation.y, angle1, 0.01, "Panel 1 should orient to sun azimuth")

	# Break 1 panel, then turn sun to +60 deg (PI/3)
	base.call("apply_report", {"broken_panels": 1, "day": 5})
	var angle2 := PI / 3.0
	base.call("update_sun_tracking", angle2, true)

	assert_near(p0_mi.rotation.y, angle1, 0.01, "Broken Panel 0 should NOT track new azimuth")
	assert_near(p1_mi.rotation.y, angle2, 0.01, "Working Panel 1 should track new azimuth")

	# Night falls: panels stop turning
	var angle3 := PI / 2.0
	base.call("update_sun_tracking", angle3, false)
	assert_near(p1_mi.rotation.y, angle2, 0.01, "Panel should stop turning at night")

	base.free()

