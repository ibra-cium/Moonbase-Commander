extends "res://tests/test_case.gd"

const S07_CARGO := {
	"solar": 24,
	"battery": 6,
	"reactor": 2,
	"greenhouse": 10,
	"o2": 2,
	"water": 4,
	"food": 5,
	"shield": 10
}

func test_model_catalog() -> void:
	# Verify cargo scene retrieval
	var cargo_keys := ["solar", "battery", "greenhouse", "o2", "water", "food"]
	for k in cargo_keys:
		var scene: PackedScene = ModelCatalog.get_cargo_scene(k)
		assert_true(scene != null, "ModelCatalog should have scene for cargo key: " + k)

	# Verify base scenes
	var base_keys := ["habitat", "lifesupport", "tunnel_straight", "shelter", "drill", "lights", "rover", "trailer", "radar", "landingpad", "dig_site"]
	for k in base_keys:
		var scene: PackedScene = ModelCatalog.get_base_scene(k)
		assert_true(scene != null, "ModelCatalog should have scene for base key: " + k)

	# Test instantiate_model
	var inst := ModelCatalog.instantiate_model("solar")
	assert_true(inst != null, "instantiate_model('solar') should succeed")
	if inst:
		inst.free()

func test_base_slots_and_static_structures() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	assert_true(base_scene != null, "Base.tscn should load")
	if base_scene == null:
		return

	var base: Node3D = base_scene.instantiate() as Node3D
	assert_true(base != null, "Base.tscn should instantiate")
	base._ready()

	# Check required Marker3D slots
	var required_slots := [
		"Slot_Habitat", "Slot_LifeSupport", "Slot_Greenhouse", "Slot_Shelter",
		"Slot_O2", "Slot_Water", "Slot_Battery", "Slot_Solar",
		"Slot_Reactor", "Slot_LandingPad", "Slot_Food", "Slot_Drill",
		"Slot_DigSite", "Slot_Rover"
	]
	for s in required_slots:
		assert_true(base.has_node("Slots/" + s), "Base must contain slot: " + s)

	# Check always-there static structures
	assert_true(base.has_node("StaticBuildings/Habitat"), "Base must have Habitat")
	assert_true(base.has_node("StaticBuildings/Habitat/Roof_Radar"), "Base must have roof radar")
	assert_true(base.has_node("StaticBuildings/LifeSupport"), "Base must have LifeSupport")
	assert_true(base.has_node("StaticBuildings/Shelter"), "Base must have half-buried Shelter")
	assert_true(base.has_node("StaticBuildings/Tunnels"), "Base must have Tunnels")
	assert_true(base.has_node("StaticBuildings/Drill"), "Base must have Drill")
	assert_true(base.has_node("StaticBuildings/DigSite"), "Base must have DigSite")
	assert_true(base.has_node("StaticBuildings/Rover"), "Base must have Rover")
	assert_true(base.has_node("StaticBuildings/LandingPad"), "Base must have LandingPad")
	assert_true(base.has_node("StaticBuildings/Lamps"), "Base must have Lamps")

	base.free()

func test_build_from_s07_cargo() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	base.call("build_from_cargo", S07_CARGO)

	var spawns: Node3D = base.get_node("CargoSpawns") as Node3D
	assert_true(spawns != null, "CargoSpawns node must exist")

	# 1. 24 solar panels
	var solar_group: Node3D = spawns.get_node_or_null("SolarGroup") as Node3D
	assert_true(solar_group != null, "SolarGroup must exist")
	if solar_group:
		assert_eq(solar_group.get_child_count(), 24, "S07 should have 24 solar panels")

	# 2. 6 batteries (no label because <= 12)
	var bat_group: Node3D = spawns.get_node_or_null("BatteryGroup") as Node3D
	assert_true(bat_group != null, "BatteryGroup must exist")
	if bat_group:
		assert_eq(bat_group.get_child_count(), 6, "S07 should have 6 batteries")
		assert_true(bat_group.get_node_or_null("BatteryMultiplierLabel") == null, "No multiplier label for <= 12 batteries")

	# 3. 2 reactors + 1 cable
	var reactor_group: Node3D = spawns.get_node_or_null("ReactorGroup") as Node3D
	assert_true(reactor_group != null, "ReactorGroup must exist")
	if reactor_group:
		var r_count := 0
		var has_cable := false
		for c in reactor_group.get_children():
			if c.name.begins_with("Reactor"):
				r_count += 1
			elif c.name == "PowerCable":
				has_cable = true
		assert_eq(r_count, 2, "S07 should have 2 reactors")
		assert_true(has_cable, "Reactor group should include power cable to habitat")

	# 4. Greenhouse (dome tinted pale green)
	var gh_group: Node3D = spawns.get_node_or_null("GreenhouseGroup") as Node3D
	assert_true(gh_group != null, "GreenhouseGroup must exist for area > 0")
	if gh_group:
		assert_eq(gh_group.get_child_count(), 1, "Greenhouse should have 1 module")
		var gh_inst := gh_group.get_child(0) as Node3D
		var mi := gh_inst.find_child("basemodule_E", true, false) as MeshInstance3D
		assert_true(mi != null, "Greenhouse mesh instance should exist")
		if mi:
			var override_mat: Material = mi.get_surface_override_material(0)
			assert_true(override_mat is StandardMaterial3D, "Greenhouse dome should have StandardMaterial3D override")
			if override_mat is StandardMaterial3D:
				var col: Color = (override_mat as StandardMaterial3D).albedo_color
				assert_true(col.g > col.r and col.g > col.b, "Greenhouse dome should be tinted pale green")

	# 5. O2 tanks (2 units)
	var o2_group: Node3D = spawns.get_node_or_null("O2Group") as Node3D
	assert_true(o2_group != null, "O2Group must exist")
	if o2_group:
		assert_eq(o2_group.get_child_count(), 2, "S07 should have 2 O2 tanks")

	# 6. Water tanks (4 units)
	var water_group: Node3D = spawns.get_node_or_null("WaterGroup") as Node3D
	assert_true(water_group != null, "WaterGroup must exist")
	if water_group:
		assert_eq(water_group.get_child_count(), 4, "S07 should have 4 water tanks")

	# 7. Food crates (5 units)
	var food_group: Node3D = spawns.get_node_or_null("FoodGroup") as Node3D
	assert_true(food_group != null, "FoodGroup must exist")
	if food_group:
		assert_eq(food_group.get_child_count(), 5, "S07 should have 5 food crates")

	# 8. Shield boxes (around shelter)
	var shield_group: Node3D = spawns.get_node_or_null("ShieldGroup") as Node3D
	assert_true(shield_group != null, "ShieldGroup must exist for shield > 0")
	if shield_group:
		assert_true(shield_group.get_child_count() >= 3, "Shield group should have boundary walls")

	base.free()

func test_build_empty_greenhouse() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	var cargo_no_gh := {
		"solar": 10,
		"battery": 4,
		"reactor": 0,
		"greenhouse": 0,
		"o2": 1,
		"water": 1,
		"food": 1,
		"shield": 0
	}
	base.call("build_from_cargo", cargo_no_gh)

	var spawns: Node3D = base.get_node("CargoSpawns") as Node3D
	var gh_group = spawns.get_node_or_null("GreenhouseGroup")
	assert_true(gh_group == null or gh_group.get_child_count() == 0, "No greenhouse should be spawned when area is 0")

	var shield_group = spawns.get_node_or_null("ShieldGroup")
	assert_true(shield_group == null or shield_group.get_child_count() == 0, "No shield should be spawned when shield is 0")

	base.free()

func test_battery_cluster_over_twelve() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	var cargo_many_bats := {
		"battery": 16
	}
	base.call("build_from_cargo", cargo_many_bats)

	var spawns: Node3D = base.get_node("CargoSpawns") as Node3D
	var bat_group: Node3D = spawns.get_node_or_null("BatteryGroup") as Node3D
	assert_true(bat_group != null, "BatteryGroup must exist")
	if bat_group:
		var label: Label3D = bat_group.get_node_or_null("BatteryMultiplierLabel") as Label3D
		assert_true(label != null, "Label3D should be present when battery count > 12")
		if label:
			assert_eq(label.text, "×16", "Label3D should display '×16'")
		# Total children: 12 models + 1 label = 13 children
		assert_eq(bat_group.get_child_count(), 13, "Battery group should contain 12 models + 1 label")

	base.free()

func test_apply_report_battery_and_lamps() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	base.call("build_from_cargo", S07_CARGO)

	# Full battery, no blackout
	base.call("apply_report", {"battery_percent": 100.0, "blackout": false})
	assert_near(base.call("get_battery_glow_energy"), 1.0, 0.05, "100% battery has 1.0 glow energy")
	assert_true(base.call("are_lamps_lit"), "Lamps should be lit normally")

	# Half battery
	base.call("apply_report", {"battery_percent": 50.0, "blackout": false})
	assert_near(base.call("get_battery_glow_energy"), 0.5, 0.05, "50% battery has 0.5 glow energy")

	# Empty battery with blackout
	base.call("apply_report", {"battery_percent": 0.0, "blackout": true})
	assert_near(base.call("get_battery_glow_energy"), 0.0, 0.05, "0% battery has 0.0 glow energy")
	assert_true(not base.call("are_lamps_lit"), "Lamps should be extinguished in blackout")

	base.free()

func test_apply_report_status_light() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	base.call("build_from_cargo", S07_CARGO)

	# Healthy state
	base.call("apply_report", {
		"blackout": false,
		"co2_mmhg": 1.0,
		"o2_kg": 50.0,
		"water_kg": 180.0,
		"food_kg": 334.6
	})
	assert_eq(base.call("get_status_light_state"), "green", "Status light should be green when healthy")

	# Warning state (CO2 > 2.0)
	base.call("apply_report", {
		"blackout": false,
		"co2_mmhg": 2.5,
		"o2_kg": 50.0,
		"water_kg": 180.0,
		"food_kg": 334.6
	})
	assert_eq(base.call("get_status_light_state"), "yellow", "Status light should be yellow when CO2 above healthy")

	# Critical state (CO2 >= 3.0 limit)
	base.call("apply_report", {
		"blackout": false,
		"co2_mmhg": 3.2,
		"o2_kg": 50.0,
		"water_kg": 180.0,
		"food_kg": 334.6
	})
	assert_eq(base.call("get_status_light_state"), "red", "Status light should be red when CO2 at limit")

	# Critical state (blackout)
	base.call("apply_report", {
		"blackout": true,
		"co2_mmhg": 1.0,
		"o2_kg": 50.0,
		"water_kg": 180.0,
		"food_kg": 334.6
	})
	assert_eq(base.call("get_status_light_state"), "red", "Status light should be red during blackout")

	base.free()

func test_apply_report_broken_panels_and_recycler() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	base.call("build_from_cargo", S07_CARGO)

	# Break 2 panels and recycler
	base.call("apply_report", {
		"broken_panels": 2,
		"recycler_broken": true
	})
	assert_true(base.call("is_recycler_light_on"), "Recycler red light should be on when broken")

	var spawns: Node3D = base.get_node("CargoSpawns") as Node3D
	var solar_group: Node3D = spawns.get_node("SolarGroup") as Node3D
	var panel0 := solar_group.get_child(0) as Node3D
	var panel1 := solar_group.get_child(1) as Node3D
	var panel2 := solar_group.get_child(2) as Node3D

	var decal0 := panel0.get_node_or_null("ScratchDecal") as MeshInstance3D
	assert_true(decal0 != null and decal0.visible, "Broken panel 0 should have visible scratch decal")

	var decal1 := panel1.get_node_or_null("ScratchDecal") as MeshInstance3D
	assert_true(decal1 != null and decal1.visible, "Broken panel 1 should have visible scratch decal")

	var decal2 := panel2.get_node_or_null("ScratchDecal") as MeshInstance3D
	assert_true(decal2 == null or not decal2.visible, "Working panel 2 should not have visible scratch decal")

	# Fix both
	base.call("apply_report", {
		"broken_panels": 0,
		"recycler_broken": false
	})
	assert_true(not base.call("is_recycler_light_on"), "Recycler red light should be off when repaired")
	assert_true(not decal0.visible, "Repaired panel 0 should have hidden scratch decal")

	base.free()

func test_apply_report_shelter_mound() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	base.call("build_from_cargo", S07_CARGO)

	var mound := base.call("get_shelter_mound") as MeshInstance3D
	assert_true(mound != null, "Shelter mound mesh should exist on shelter")

	# Initial 0 g/cm²
	base.call("apply_report", {"shelter_g_cm2": 0.0})
	assert_true(not mound.visible, "Shelter mound should be hidden at 0 g/cm²")

	# Grew to 10 g/cm²
	base.call("apply_report", {"shelter_g_cm2": 10.0})
	assert_true(mound.visible, "Shelter mound should be visible at 10 g/cm²")
	var scale_10: float = mound.scale.y

	# Grew to 20 g/cm²
	base.call("apply_report", {"shelter_g_cm2": 20.0})
	var scale_20: float = mound.scale.y
	assert_true(scale_20 > scale_10, "Shelter mound height should scale up as regolith increases")

	base.free()

func test_apply_report_greenhouse_plants() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	base.call("build_from_cargo", S07_CARGO)

	var spawns: Node3D = base.get_node("CargoSpawns") as Node3D
	var gh_group: Node3D = spawns.get_node("GreenhouseGroup") as Node3D
	var gh_inst := gh_group.get_child(0) as Node3D
	var plant_bed := gh_inst.get_node_or_null("PlantBed") as Node3D
	assert_true(plant_bed != null, "PlantBed should exist in greenhouse")

	# Healthy growth
	base.call("apply_report", {
		"greenhouse_alive": true,
		"greenhouse_wilt_days": 0,
		"greenhouse_growth_days": 5
	})
	assert_true(plant_bed.visible, "PlantBed should be visible when greenhouse is alive")
	var cone0 := plant_bed.get_child(0) as MeshInstance3D
	var mat0: StandardMaterial3D = cone0.material_override as StandardMaterial3D
	assert_true(mat0.albedo_color.g > mat0.albedo_color.r, "Healthy plant cone should be green")
	var scale_5: float = cone0.scale.y

	# More growth
	base.call("apply_report", {
		"greenhouse_alive": true,
		"greenhouse_wilt_days": 0,
		"greenhouse_growth_days": 15
	})
	var scale_15: float = cone0.scale.y
	assert_true(scale_15 > scale_5, "Plant cone scale should increase with growth_days")

	# Wilting
	base.call("apply_report", {
		"greenhouse_alive": true,
		"greenhouse_wilt_days": 2,
		"greenhouse_growth_days": 15
	})
	var mat_wilt: StandardMaterial3D = cone0.material_override as StandardMaterial3D
	assert_true(mat_wilt.albedo_color.r > mat_wilt.albedo_color.g, "Wilting plant cone should turn brown")

	# Dead
	base.call("apply_report", {
		"greenhouse_alive": false,
		"greenhouse_wilt_days": 3,
		"greenhouse_growth_days": 15
	})
	assert_true(not plant_bed.visible, "PlantBed should be hidden when greenhouse is dead")

	base.free()

func test_apply_report_tank_hiding_and_food() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base: Node3D = base_scene.instantiate() as Node3D
	base._ready()

	# Custom cargo with 5 water tanks to check 20% steps
	var cargo_5_water := {
		"water": 5,
		"o2": 2,
		"food": 3
	}
	base.call("build_from_cargo", cargo_5_water)

	var spawns: Node3D = base.get_node("CargoSpawns") as Node3D
	var water_group: Node3D = spawns.get_node("WaterGroup") as Node3D
	assert_eq(water_group.get_child_count(), 5, "Initial 5 water tanks")

	# 100% water -> 5 visible
	base.call("apply_report", {"water_kg": 225.0})
	var vis_count := 0
	for c in water_group.get_children():
		if c.visible: vis_count += 1
	assert_eq(vis_count, 5, "5 visible at 100% water")

	# 80% water (20% used) -> 4 visible (1 hidden per 20% used)
	base.call("apply_report", {"water_kg": 180.0})
	vis_count = 0
	for c in water_group.get_children():
		if c.visible: vis_count += 1
	assert_eq(vis_count, 4, "4 visible at 80% water (1 hidden)")

	# 60% water (40% used) -> 3 visible
	base.call("apply_report", {"water_kg": 135.0})
	vis_count = 0
	for c in water_group.get_children():
		if c.visible: vis_count += 1
	assert_eq(vis_count, 3, "3 visible at 60% water (2 hidden)")

	# 0% water -> 0 visible
	base.call("apply_report", {"water_kg": 0.0})
	vis_count = 0
	for c in water_group.get_children():
		if c.visible: vis_count += 1
	assert_eq(vis_count, 0, "0 visible at 0% water")

	# Food stage progression: stacked -> packed -> single -> none
	assert_eq(base.call("get_food_stage"), "stacked", "Initial food is stacked")

	base.call("apply_report", {"food_kg": 100.0})
	assert_eq(base.call("get_food_stage"), "packed", "50% food is packed")

	base.call("apply_report", {"food_kg": 30.0})
	assert_eq(base.call("get_food_stage"), "single", "15% food is single")

	base.call("apply_report", {"food_kg": 0.0})
	assert_eq(base.call("get_food_stage"), "none", "0% food is none (hidden)")

	base.free()

func test_base_debug_stepping() -> void:
	var debug_scene: PackedScene = load("res://world/BaseDebug.tscn")
	assert_true(debug_scene != null, "BaseDebug.tscn should load")
	if debug_scene == null:
		return

	var debug: Node3D = debug_scene.instantiate() as Node3D
	debug._ready()

	# 1. Test S01 step to Day 16: blackout and red status light
	debug.call("_load_scenario", "S01", debug.get("S01_CARGO"), debug.get("S01_FORCE"), "REST")
	debug.call("jump_to_day_16")

	var base_node: Node3D = debug.get_node("Base") as Node3D
	assert_eq(base_node.call("get_status_light_state"), "red", "Day 16 of S01 should show RED status light")
	assert_near(base_node.call("get_battery_glow_energy"), 0.0, 0.01, "Day 16 of S01 should show 0 battery glow")
	assert_true(not base_node.call("are_lamps_lit"), "Day 16 of S01 should have extinguished lamps in blackout")

	# 2. Test S07 stepping: mound grows and plants grow
	debug.call("_load_scenario", "S07", debug.get("S07_CARGO"), debug.get("S07_FORCE"), "SMART")
	var mound := base_node.call("get_shelter_mound") as MeshInstance3D
	assert_true(mound != null, "Shelter mound should exist")

	var initial_mound_height: float = mound.scale.y if mound.visible else 0.0

	# Step 5 days in S07
	for i in 5:
		debug.call("step_day")

	assert_true(mound.visible, "Mound should be visible after regolith jobs in S07")
	assert_true(mound.scale.y > initial_mound_height, "Mound should grow after regolith jobs")

	# Check plant cones
	var spawns: Node3D = base_node.get_node("CargoSpawns") as Node3D
	var gh_group: Node3D = spawns.get_node("GreenhouseGroup") as Node3D
	var gh_inst := gh_group.get_child(0) as Node3D
	var plant_bed := gh_inst.get_node("PlantBed") as Node3D
	assert_true(plant_bed.visible, "PlantBed should be visible in S07")
	var cone := plant_bed.get_child(0) as MeshInstance3D
	assert_true(cone.scale.y > 0.35, "Plant cones should grow in S07")

	debug.free()

