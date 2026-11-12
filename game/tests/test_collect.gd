extends "res://tests/test_case.gd"

const BaseScene: PackedScene = preload("res://world/Base.tscn")
const DayHudScene: PackedScene = preload("res://ui/DayHud.tscn")
const WorldAnchorScript := preload("res://ui/world_anchor.gd")
const DayHudScript := preload("res://ui/day_hud.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimMissionScript := preload("res://sim/sim_mission.gd")
const SimDayReportScript := preload("res://sim/sim_day_report.gd")
const UIColorsScript := preload("res://ui/ui_colors.gd")


func test_world_anchor_visibility_and_tracking() -> void:
	var cam := Camera3D.new()
	cam.look_at_from_position(Vector3(0.0, 2.0, 10.0), Vector3.ZERO, Vector3.UP)

	var anchor: Control = WorldAnchorScript.new()
	anchor.size = Vector2(72.0, 72.0)

	anchor.world_point = Vector3.ZERO
	var ok_front: bool = anchor.update_position(cam, Vector2(1280.0, 720.0))
	assert_true(ok_front, "WorldAnchor visible for point in front of camera")
	assert_true(anchor.visible, "WorldAnchor Control should be visible")
	assert_near(anchor.position.x + 36.0, 640.0, 40.0, "Centered X on screen center")

	anchor.world_point = Vector3(0.0, 2.0, 25.0)
	var ok_behind: bool = anchor.update_position(cam, Vector2(1280.0, 720.0))
	assert_false(ok_behind, "WorldAnchor hidden when point is behind camera")
	assert_false(anchor.visible, "WorldAnchor Control hidden behind camera")

	anchor.world_point = Vector3(400.0, 0.0, 0.0)
	var ok_off: bool = anchor.update_position(cam, Vector2(1280.0, 720.0))
	assert_false(ok_off, "WorldAnchor hidden when point is off screen")
	assert_false(anchor.visible, "WorldAnchor Control hidden off screen")

	anchor.free()
	cam.free()


func test_base_collect_anchors() -> void:
	var c := load_constants()
	var base: Node3D = BaseScene.instantiate()
	var cargo := SimCargoScript.new(c)
	cargo.set_count("solar", 4)
	cargo.set_count("greenhouse", 0)
	cargo.set_count("reactor", 0)
	base.build_from_cargo(cargo)

	assert_true(base.get_collect_anchor("energy") != Vector3.ZERO, "Energy anchor present with solar")
	assert_true(base.get_collect_anchor("science") != Vector3.ZERO, "Science anchor present at drill")
	assert_true(base.get_collect_anchor("shelter") != Vector3.ZERO, "Shelter anchor present with ShelterMound")
	assert_true(base.get_collect_anchor("plants") == Vector3.ZERO, "Plants anchor ZERO when greenhouse missing")
	assert_true(base.get_collect_anchor("unknown") == Vector3.ZERO, "Unknown anchor ZERO")

	var cargo_reactor_only := SimCargoScript.new(c)
	cargo_reactor_only.set_count("solar", 0)
	cargo_reactor_only.set_count("reactor", 1)
	cargo_reactor_only.set_count("greenhouse", 1)
	base.build_from_cargo(cargo_reactor_only)
	assert_true(base.get_collect_anchor("energy") != Vector3.ZERO, "Energy anchor falls back to reactor")
	assert_true(base.get_collect_anchor("plants") != Vector3.ZERO, "Plants anchor present with greenhouse")

	var cargo_no_power := SimCargoScript.new(c)
	cargo_no_power.set_count("solar", 0)
	cargo_no_power.set_count("reactor", 0)
	cargo_no_power.set_count("greenhouse", 0)
	base.build_from_cargo(cargo_no_power)
	assert_true(base.get_collect_anchor("energy") == Vector3.ZERO, "Energy anchor ZERO without solar or reactor")

	base.free()


func test_collect_specs_for_report_pair() -> void:
	var r1 := SimDayReportScript.new()
	r1.day = 1
	r1.generation_kwh = 18.4
	r1.science_points = 0
	r1.shelter_g_cm2 = 2.0
	r1.greenhouse_healthy = false
	r1.greenhouse_o2_kg = 0.0

	var specs_day1: Array[Dictionary] = DayHudScript.build_collect_specs(null, r1, null, 2.0)
	assert_eq(specs_day1.size(), 1, "Day 1 without gains spawns only energy bubble")
	assert_eq(specs_day1[0]["kind"], "energy", "Only energy bubble appears")
	assert_eq(specs_day1[0]["text"], "+18", "Energy value rounded")

	var r2 := SimDayReportScript.new()
	r2.day = 2
	r2.generation_kwh = 24.6
	r2.science_points = 2
	r2.shelter_g_cm2 = 4.5
	r2.greenhouse_healthy = true
	r2.greenhouse_o2_kg = 1.6

	var specs_day2: Array[Dictionary] = DayHudScript.build_collect_specs(r1, r2)
	assert_eq(specs_day2.size(), 4, "All 4 bubbles spawn when everything grew")
	assert_eq(specs_day2[0]["text"], "+25", "Rounded up generation_kwh")
	assert_eq(specs_day2[1]["kind"], "science", "Science bubble appears")
	assert_eq(specs_day2[1]["text"], "+2", "Science delta matches")
	assert_eq(specs_day2[2]["kind"], "shelter", "Shelter bubble appears")
	assert_eq(specs_day2[2]["text"], "+2.5", "Shelter delta formatted to 1 decimal")
	assert_eq(specs_day2[3]["kind"], "plants", "Plants bubble appears")
	assert_eq(specs_day2[3]["text"], "+1.6", "Plants O2 formatted to 1 decimal")

	var r3 := SimDayReportScript.new()
	r3.day = 3
	r3.generation_kwh = 12.0
	r3.science_points = 2
	r3.shelter_g_cm2 = 4.5
	r3.greenhouse_healthy = false
	r3.greenhouse_o2_kg = 0.0

	var specs_day3: Array[Dictionary] = DayHudScript.build_collect_specs(r2, r3)
	assert_eq(specs_day3.size(), 1, "No deltas or healthy plants spawns only energy bubble")
	assert_eq(specs_day3[0]["kind"], "energy", "Energy bubble always shown")


func test_collect_bubble_tap_and_auto_collect_counters() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var hud: Control = DayHudScene.instantiate() as Control
	root.add_child(hud)
	hud._ready()

	var c := load_constants()
	var cargo := SimCargoScript.new(c)
	cargo.set_count("solar", 4)
	cargo.set_count("shield", 1)
	cargo.set_count("greenhouse", 1)
	var mission := SimMissionScript.new(c, cargo, 123)
	var prev_hint: bool = Settings.hint_collect_shown
	Settings.hint_collect_shown = false
	hud.setup_mission(mission)

	var goal: int = int(Constants.v("SCIENCE_GOAL_POINTS"))
	var initial_shelter: float = mission.shelter_g_cm2
	assert_eq(hud.res_science_value.text, "0 / %d" % goal, "Initial science counter shows 0 / goal")
	assert_eq(hud.res_energy_value.text, "0 kWh", "Initial energy counter shows 0 kWh")
	assert_eq(hud.res_shelter_value.text, "%.1f g/cm²" % initial_shelter, "Initial shelter matches mission")
	assert_eq(hud.res_science_tag.constant_id, "SCIENCE_GOAL_POINTS", "Science SourceTag constant set")
	assert_eq(hud.res_energy_tag.constant_id, "SOLAR_UNIT_KW", "Energy SourceTag constant set")
	assert_eq(hud.res_shelter_tag.constant_id, "SHIELD_GOAL_G_CM2", "Shelter SourceTag constant set")

	var r1 := SimDayReportScript.new()
	r1.day = 1
	r1.generation_kwh = 20.4
	r1.science_points = 3
	r1.shelter_g_cm2 = initial_shelter + 2.5
	r1.greenhouse_healthy = true
	r1.greenhouse_o2_kg = 1.6
	r1.co2_mmhg = 0.8

	hud.update_from_report(r1, true)
	var bubbles: Array[Control] = hud.spawn_collect_bubbles_for_report(r1, 0, initial_shelter)
	assert_eq(bubbles.size(), 4, "Spawned 4 bubbles")
	assert_true(Settings.hint_collect_shown, "COLLECT_HINT shown once and recorded")

	var sci_bubble: Control = null
	for b in bubbles:
		var btn := b.get_node_or_null("BubbleButton") as Button
		assert_true(btn != null and btn.custom_minimum_size.x >= 64.0 and btn.custom_minimum_size.y >= 64.0, "Touch target >= 64px")
		if b.get("kind") == "science":
			sci_bubble = b

	assert_eq(hud.res_science_value.text, "0 / %d" % goal, "Science counter waits until tapped")
	assert_true(sci_bubble != null, "Science bubble found")
	sci_bubble.call("_on_pressed")
	sci_bubble.call("finish_immediately")
	assert_eq(hud.res_science_value.text, "3 / %d" % goal, "Science ticks up on bubble arrival")
	assert_eq(hud.res_energy_value.text, "0 kWh", "Untapped energy bubble still pending")

	hud.auto_collect_all()
	assert_eq(hud.get_pending_collect_count(), 0, "End Day auto-collect leaves 0 uncollected bubbles")
	hud.flush_pending_collections()
	assert_eq(hud.res_science_value.text, "3 / %d" % goal, "Science matches report total")
	assert_eq(hud.res_energy_value.text, "20 kWh", "Energy matches report total")
	assert_eq(hud.res_shelter_value.text, "%.1f g/cm²" % r1.shelter_g_cm2, "Shelter matches report total")
	assert_eq(hud.get_collect_bubbles().size(), 0, "All bubbles freed after collect")

	# Goal reached turns Science gold
	var r_goal := SimDayReportScript.new()
	r_goal.day = 2
	r_goal.generation_kwh = 15.0
	r_goal.science_points = goal
	r_goal.shelter_g_cm2 = r1.shelter_g_cm2
	hud.update_from_report(r_goal, false)
	assert_eq(hud.res_science_value.text, "%d / %d" % [goal, goal], "Science goal counter reached")
	assert_eq(hud.res_science_value.get_theme_color("font_color"), UIColorsScript.POWER, "Science counter turns gold at goal")

	Settings.hint_collect_shown = prev_hint
	root.remove_child(hud)
	hud.free()


func test_co2_gauge_status_words() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var hud: Control = DayHudScene.instantiate() as Control
	root.add_child(hud)
	hud._ready()

	var c := load_constants()
	var cargo := SimCargoScript.new(c)
	var mission := SimMissionScript.new(c, cargo, 10)
	hud.setup_mission(mission)
	assert_eq(hud.co2_gauge.source_constant_id, "CO2_LIMIT_MMHG", "CO2 gauge keeps source tag")

	var healthy_max: float = float(Constants.v("CO2_HEALTHY_MAX_MMHG"))
	var limit_mmhg: float = float(Constants.v("CO2_LIMIT_MMHG"))

	var rep := SimDayReportScript.new()
	rep.co2_mmhg = healthy_max
	hud.update_from_report(rep)
	assert_true(hud.get_co2_status_text().to_lower().contains("good"), "At healthy max shows AIR_GOOD")

	rep.co2_mmhg = (healthy_max + limit_mmhg) * 0.5
	hud.update_from_report(rep)
	assert_true(hud.get_co2_status_text().to_lower().contains("stuffy"), "Above healthy max up to limit shows AIR_STUFFY")

	rep.co2_mmhg = limit_mmhg + 0.3
	hud.update_from_report(rep)
	assert_true(hud.get_co2_status_text().to_lower().contains("danger"), "Above limit shows AIR_DANGER")

	root.remove_child(hud)
	hud.free()


func test_main_m3_regolith_and_m4_science_collect_flow() -> void:
	var prev_id: String = Settings.current_mission_id
	var prev_free: bool = Settings.free_play
	var prev_stars: Dictionary = Settings.mission_stars.duplicate(true)
	var prev_hint: bool = Settings.hint_collect_shown
	var prev_tut_skipped: bool = Settings.tutorial_skipped
	var prev_cargo = GameState.last_cargo
	var prev_mission = GameState.current_mission

	Settings.free_play = true
	Settings.tutorial_skipped = true
	var main_scene: PackedScene = preload("res://scenes/Main.tscn")
	var SimPlanScript := preload("res://sim/sim_plan.gd")
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var main := main_scene.instantiate()
	root.add_child(main)
	main._ensure_nodes()
	main.world.get_node("Base")._ready()
	main.mission_map._ready()
	main.pack_screen._ready()
	main.day_hud._ready()
	for card in main.day_hud.crew_cards:
		card._ready()
	main._ready()

	# Start M3 via Pack and run 1 day with REGOLITH jobs
	main.mission_map._on_mission_pressed("M3")
	main.mission_map._on_play_pressed()
	var m3_cargo := SimCargoScript.new(Constants.sim)
	m3_cargo.load_dict({"solar": 20, "battery": 4, "reactor": 2, "o2": 2, "water": 4, "food": 5, "shield": 0})
	main._on_pack_launch_requested(m3_cargo)
	main.world.get_node("Base").build_from_cargo(GameState.current_mission.cargo)
	main._on_landing_completed()

	if main.day_hud.crew_cards.size() >= 2:
		main.day_hud.crew_cards[0].set_job(SimPlanScript.JOB_REGOLITH)
		main.day_hud.crew_cards[1].set_job(SimPlanScript.JOB_REGOLITH)
	main._on_end_day_pressed()
	main._on_resolve_completed()

	var m3_kinds: Array[String] = []
	for b in main.day_hud.get_collect_bubbles():
		m3_kinds.append(str(b.get("kind")))
	assert_true(m3_kinds.has("energy"), "M3 Day 1 resolved spawns energy bubble")
	assert_true(m3_kinds.has("shelter"), "M3 Day 1 with regolith jobs spawns shelter bubble")
	main._on_end_day_pressed()
	assert_eq(main.day_hud.get_pending_collect_count(), 0, "M3 End Day auto-collects remaining bubbles")

	# Start M4 via Pack and run 1 day with SCIENCE jobs
	main.mission_map._on_mission_pressed("M4")
	main.mission_map._on_play_pressed()
	var m4_cargo := SimCargoScript.new(Constants.sim)
	m4_cargo.load_dict({"solar": 20, "battery": 4, "reactor": 2, "greenhouse": 1, "o2": 2, "water": 6, "food": 5, "shield": 1})
	main._on_pack_launch_requested(m4_cargo)
	main.world.get_node("Base").build_from_cargo(GameState.current_mission.cargo)
	main._on_landing_completed()

	if main.day_hud.crew_cards.size() >= 2:
		main.day_hud.crew_cards[0].set_job(SimPlanScript.JOB_SCIENCE)
		main.day_hud.crew_cards[1].set_job(SimPlanScript.JOB_SCIENCE)
	main.day_hud._on_greenhouse_switch_pressed()
	main._on_end_day_pressed()
	main._on_resolve_completed()

	var m4_kinds: Array[String] = []
	for b in main.day_hud.get_collect_bubbles():
		m4_kinds.append(str(b.get("kind")))
	assert_true(m4_kinds.has("energy"), "M4 Day 1 resolved spawns energy bubble")
	assert_true(m4_kinds.has("science"), "M4 Day 1 with science jobs spawns science bubble")
	assert_true(m4_kinds.has("plants"), "M4 Day 1 with healthy greenhouse spawns plants bubble")
	main.day_hud.flush_pending_collections()
	assert_true(main.day_hud.res_science_value.text.begins_with("2 / "), "M4 science bar updates to report points after collect")

	root.remove_child(main)
	main.free()
	Settings.current_mission_id = prev_id
	Settings.free_play = prev_free
	Settings.mission_stars = prev_stars
	Settings.hint_collect_shown = prev_hint
	Settings.tutorial_skipped = prev_tut_skipped
	GameState.last_cargo = prev_cargo
	GameState.current_mission = prev_mission

