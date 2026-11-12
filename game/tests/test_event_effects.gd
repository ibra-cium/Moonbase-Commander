extends "res://tests/test_case.gd"

const EffectsScript := preload("res://world/effects.gd")
const BaseStationScript := preload("res://world/base.gd")

func test_effects_scene_structure() -> void:
	var scene: PackedScene = load("res://world/Effects.tscn")
	assert_true(scene != null, "Effects.tscn should load")
	if scene == null:
		return

	var eff = scene.instantiate() as Node3D
	assert_true(eff != null, "Effects should instantiate")
	eff._ready()

	# Verify required nodes exist
	assert_true(eff.has_node("StormStreaks"), "Must have StormStreaks particle emitter")
	assert_true(eff.has_node("SparkParticles"), "Must have SparkParticles emitter")
	assert_true(eff.has_node("SteamParticles"), "Must have SteamParticles emitter")
	assert_true(eff.has_node("DirtParticles"), "Must have DirtParticles emitter")
	assert_true(eff.has_node("StarParticles"), "Must have StarParticles emitter")
	assert_true(eff.has_node("MeteoroidStreak"), "Must have MeteoroidStreak sprite")
	assert_true(eff.has_node("RedOverlay"), "Must have RedOverlay CanvasLayer")
	assert_true(eff.has_node("RedOverlay/ColorRect"), "Must have RedOverlay/ColorRect")

	# Check particle counts for mobile/web phone budget
	var storm = eff.get_node("StormStreaks") as CPUParticles3D
	var spark = eff.get_node("SparkParticles") as CPUParticles3D
	var steam = eff.get_node("SteamParticles") as CPUParticles3D
	var dirt = eff.get_node("DirtParticles") as CPUParticles3D
	var star = eff.get_node("StarParticles") as CPUParticles3D

	assert_true(storm.amount <= 40, "Storm streaks particle budget <= 40 (got %d)" % storm.amount)
	assert_true(spark.amount <= 30, "Sparks particle budget <= 30 (got %d)" % spark.amount)
	assert_true(steam.amount <= 15, "Steam particle budget <= 15 (got %d)" % steam.amount)
	assert_true(dirt.amount <= 25, "Dirt particle budget <= 25 (got %d)" % dirt.amount)
	assert_true(star.amount <= 30, "Star particle budget <= 30 (got %d)" % star.amount)

	# Verify unshaded billboard materials
	assert_true(storm.mesh != null and storm.mesh.material != null, "Storm streaks must have mesh material")
	var sm = storm.mesh.material as StandardMaterial3D
	assert_true(sm != null, "Material must be StandardMaterial3D")
	if sm != null:
		assert_eq(sm.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, "Particle material must be unshaded")
		assert_eq(sm.billboard_mode, BaseMaterial3D.BILLBOARD_PARTICLES, "Particle material must use billboard mode")

	eff.free()

func test_event_methods_exist() -> void:
	var scene: PackedScene = load("res://world/Effects.tscn")
	var eff = scene.instantiate() as Node3D
	eff._ready()

	# Verify API methods for all event codes
	var required_methods = [
		"play_event",
		"play_storm", "STORM",
		"play_storm_warning", "STORM_WARNING",
		"play_meteoroid", "METEOROID",
		"play_recycler_broke", "RECYCLER_BROKE",
		"play_regolith", "REGOLITH",
		"play_science", "SCIENCE",
		"play_blackout", "BLACKOUT",
		"play_sunset", "SUNSET",
		"play_supply_low", "SUPPLY_LOW",
		"play_evacuation", "EVAC",
		"play_stars",
		"reset_all_effects"
	]

	for m in required_methods:
		assert_true(eff.has_method(m), "Effects must implement method '%s'" % m)

	eff.free()

func test_storm_and_warning_effects() -> void:
	var world_scene: PackedScene = load("res://world/World.tscn")
	assert_true(world_scene != null, "World.tscn should load")
	if world_scene == null:
		return

	var world = world_scene.instantiate()
	world._ready()

	var eff = world.get_node_or_null("Effects") as Node3D
	var base = world.get_node_or_null("Base") as BaseStation
	assert_true(eff != null, "World must contain Effects node")
	assert_true(base != null, "World must contain Base node")
	if eff != null:
		eff._ready()

	# 1. Storm Warning
	eff.play_storm_warning(0.2)
	assert_eq(eff.get_last_played_effect(), "STORM_WARNING", "Last played effect should be STORM_WARNING")
	assert_true(base.is_shelter_door_light_on(), "Shelter door light must be lit during storm warning")

	# 2. Storm
	eff.play_storm(0.2)
	assert_eq(eff.get_last_played_effect(), "STORM", "Last played effect should be STORM")
	assert_true(eff.is_storm_emitting(), "Storm streaks must be emitting during storm")
	assert_true(eff.get_red_overlay_opacity() > 0.0, "Red overlay opacity must increase during storm")
	assert_true(base.is_shelter_door_light_on(), "Shelter door light must be lit during storm")

	eff.reset_all_effects()
	assert_true(not eff.is_storm_emitting(), "Storm streaks should stop after reset")
	assert_true(is_equal_approx(eff.get_red_overlay_opacity(), 0.0), "Red overlay should clear after reset")

	world.free()

func test_meteoroid_and_recycler_effects() -> void:
	var world_scene: PackedScene = load("res://world/World.tscn")
	var world = world_scene.instantiate()
	world._ready()

	var eff = world.get_node_or_null("Effects") as Node3D
	var base = world.get_node_or_null("Base") as BaseStation
	if eff != null:
		eff._ready()

	# Setup base with solar panels
	var cargo_dict := {"solar": 4, "battery": 2}
	base.build_from_cargo(cargo_dict)

	# 1. Meteoroid
	eff.play_meteoroid(0.2)
	assert_eq(eff.get_last_played_effect(), "METEOROID", "Last played effect should be METEOROID")
	assert_true(eff.is_effect_running(), "Meteoroid effect should be running")

	# 2. Recycler breakdown
	eff.play_recycler_broke(0.2)
	assert_eq(eff.get_last_played_effect(), "RECYCLER_BROKE", "Last played effect should be RECYCLER_BROKE")
	assert_true(base.is_recycler_light_on(), "Recycler red light must turn on after recycler breakdown")

	eff.reset_all_effects()
	world.free()

func test_regolith_and_science_effects() -> void:
	var world_scene: PackedScene = load("res://world/World.tscn")
	var world = world_scene.instantiate()
	world._ready()

	var eff = world.get_node_or_null("Effects") as Node3D
	var base = world.get_node_or_null("Base") as BaseStation
	if eff != null:
		eff._ready()

	# 1. Regolith job effect
	eff.play_regolith(0.2)
	assert_eq(eff.get_last_played_effect(), "REGOLITH", "Last played effect should be REGOLITH")
	var rover = base.get_rover()
	assert_true(rover != null, "Rover should exist in base")

	# 2. Science drill effect
	eff.play_science(0.2)
	assert_eq(eff.get_last_played_effect(), "SCIENCE", "Last played effect should be SCIENCE")
	var drill = base.get_drill_module()
	assert_true(drill != null, "Drill module should exist in base")

	eff.reset_all_effects()
	world.free()

func test_report_event_dispatch() -> void:
	var world_scene: PackedScene = load("res://world/World.tscn")
	var world = world_scene.instantiate()
	world._ready()

	var eff = world.get_node_or_null("Effects") as Node3D
	if eff != null:
		eff._ready()

	# Create a dummy report with STORM event
	var SimDayReportScript = load("res://sim/sim_day_report.gd")
	var dummy_report = SimDayReportScript.new()
	var evt_storm := RefCounted.new()
	evt_storm.set_script(load("res://sim/sim_event.gd"))
	evt_storm.code = "STORM"
	dummy_report.events = [evt_storm]
	dummy_report.blackout = false
	var empty_reports: Array[Dictionary] = []
	dummy_report.crew_reports = empty_reports

	eff._on_game_state_day_resolved(dummy_report)
	assert_eq(eff.get_last_played_effect(), "STORM", "Should play STORM when present in report.events")

	# Create a dummy report with RECYCLER_BROKE
	var evt_rec := RefCounted.new()
	evt_rec.set_script(load("res://sim/sim_event.gd"))
	evt_rec.code = "RECYCLER_BROKE"
	dummy_report.events = [evt_rec]
	eff._on_game_state_day_resolved(dummy_report)
	assert_eq(eff.get_last_played_effect(), "RECYCLER_BROKE", "Should play RECYCLER_BROKE when present")

	# Create a dummy report with blackout
	dummy_report.events = []
	dummy_report.blackout = true
	eff._on_game_state_day_resolved(dummy_report)
	assert_eq(eff.get_last_played_effect(), "BLACKOUT", "Should play BLACKOUT when report.blackout is true")

	# Create a dummy report with REGOLITH job worked
	dummy_report.blackout = false
	var reg_reps: Array[Dictionary] = [{"job": "REGOLITH"}]
	dummy_report.crew_reports = reg_reps
	eff._on_game_state_day_resolved(dummy_report)
	assert_eq(eff.get_last_played_effect(), "REGOLITH", "Should play REGOLITH when crew worked regolith")

	# Create a dummy report with SCIENCE job worked
	var sci_reps: Array[Dictionary] = [{"job": "SCIENCE"}]
	dummy_report.crew_reports = sci_reps
	eff._on_game_state_day_resolved(dummy_report)
	assert_eq(eff.get_last_played_effect(), "SCIENCE", "Should play SCIENCE when crew worked science")

	eff.reset_all_effects()
	world.free()
