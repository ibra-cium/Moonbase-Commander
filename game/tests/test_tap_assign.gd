extends "res://tests/test_case.gd"

const BaseScene: PackedScene = preload("res://world/Base.tscn")
const CrewScene: PackedScene = preload("res://world/Crew.tscn")
const DayHudScene: PackedScene = preload("res://ui/DayHud.tscn")
const MainScene: PackedScene = preload("res://scenes/Main.tscn")
const CameraRigScene: PackedScene = preload("res://world/CameraRig.tscn")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimMissionScript := preload("res://sim/sim_mission.gd")
const SimPlanScript := preload("res://sim/sim_plan.gd")


func test_translation_keys_updated() -> void:
	var prev_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	assert_eq(
		tr("TUT_STEP2_BODY"),
		"Tap an astronaut, then tap a building to give a job. Then press End Day.",
		"TUT_STEP2_BODY reflects tap astronaut then building"
	)
	assert_eq(tr("ASSIGN_PICK_BUILDING"), "Where should {name} work?", "ASSIGN_PICK_BUILDING present")
	assert_eq(tr("ASSIGN_CLEAN"), "Clean", "ASSIGN_CLEAN present")
	assert_eq(tr("ASSIGN_REPAIR"), "Repair", "ASSIGN_REPAIR present")
	TranslationServer.set_locale(prev_locale)


func test_crew_card_header_select_and_toggle() -> void:
	var prev_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var hud: DayHud = DayHudScene.instantiate() as DayHud
	root.add_child(hud)
	hud._ready()
	hud.bind_world_nodes(null, null)

	var card0: CrewCard = hud.crew_cards[0]
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	card0.top_row.gui_input.emit(mb)

	assert_eq(hud.get_selected_crew_index(), 0, "Tapping portrait/name selects crew 0")
	assert_true(card0.is_selected(), "Selected crew card shows selection highlight")
	assert_true(hud.is_select_banner_visible(), "Selection banner shown")
	assert_eq(hud.get_select_banner_text(), "Where should Rafi work?", "Banner names selected astronaut")
	assert_false(hud.get_building_markers().is_empty(), "Building markers shown while selected")

	# Tapping next job arrow assigns job without clearing through header input
	card0.next_job_btn.pressed.emit()
	assert_true(card0.get_job() != SimPlanScript.JOB_REST, "Prev/Next arrows still change job")

	# Tapping same crew header again cancels selection
	card0.top_row.gui_input.emit(mb)
	assert_eq(hud.get_selected_crew_index(), -1, "Re-tapping selected card cancels selection")
	assert_false(card0.is_selected(), "Deselected card clears highlight")
	assert_false(hud.is_select_banner_visible(), "Banner hides on cancel")
	assert_true(hud.get_building_markers().is_empty(), "Building markers hide on cancel")

	hud.free()
	TranslationServer.set_locale(prev_locale)


func test_crew_tag_anchor_and_hop_selection() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var cam := Camera3D.new()
	var base: BaseStation = BaseScene.instantiate() as BaseStation
	var crew: Crew = CrewScene.instantiate() as Crew
	var hud: DayHud = DayHudScene.instantiate() as DayHud
	root.add_child(cam)
	root.add_child(base)
	root.add_child(crew)
	root.add_child(hud)
	cam.look_at_from_position(Vector3(0.0, 12.0, 26.0), Vector3.ZERO, Vector3.UP)
	cam.current = true
	crew._ready()
	hud._ready()
	hud.bind_world_nodes(base, crew)

	var tags := hud.get_crew_tag_buttons()
	assert_eq(tags.size(), 4, "Created 4 CrewTagButton WorldAnchors")

	var tag1: CrewTagButton = tags[1] as CrewTagButton
	tag1.camera_override = cam
	tag1._process(0.016)
	assert_false(tag1.visible, "Resting astronaut indoors hides 2D name tag")

	crew.assign_job(1, SimPlanScript.JOB_CLEAN)
	hud.crew_cards[1].set_job(SimPlanScript.JOB_CLEAN)
	tag1._process(0.016)
	assert_true(tag1.visible, "Outdoor working astronaut shows 2D CrewTagButton")
	assert_true(tag1.custom_minimum_size.x >= 64.0 and tag1.custom_minimum_size.y >= 64.0, "Tag hit target >= 64px")

	tag1._hit_btn.pressed.emit()
	assert_eq(hud.get_selected_crew_index(), 1, "Tapping 2D WorldAnchor name tag selects Mira")
	assert_true(hud.crew_cards[1].is_selected(), "Card 1 highlights when 3D tag tapped")
	var astro1: Astronaut = crew.get_astronaut(1)
	assert_true(astro1._is_selected, "Astronaut marks selected outline")

	hud.deselect_crew()
	assert_eq(hud.get_selected_crew_index(), -1, "deselect_crew clears selection")
	assert_false(astro1._is_selected, "Astronaut clears selected outline")

	hud.free()
	crew.free()
	base.free()
	cam.free()


func test_greenhouse_marker_visibility_and_dead_reason() -> void:
	var prev_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var c := load_constants()
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var base: BaseStation = BaseScene.instantiate() as BaseStation
	root.add_child(base)
	var hud: DayHud = DayHudScene.instantiate() as DayHud
	root.add_child(hud)
	hud._ready()
	hud.bind_world_nodes(base, null)

	# Case 1: No greenhouse packed -> greenhouse marker hidden
	var cargo_no_gh := SimCargoScript.new(c)
	cargo_no_gh.set_count("greenhouse", 0)
	var m_no_gh := SimMissionScript.new(c, cargo_no_gh)
	hud.setup_mission(m_no_gh)
	hud.select_crew(0)
	var markers := hud.get_building_markers()
	assert_true(markers.has("habitat"), "Habitat marker shown")
	assert_true(markers.has("life_support"), "Life support marker shown")
	assert_true(markers.has("solar"), "Solar marker shown")
	assert_true(markers.has("dig_site"), "Dig site marker shown")
	assert_true(markers.has("drill"), "Drill marker shown")
	assert_false(markers.has("greenhouse"), "Greenhouse marker hidden when not packed")
	assert_near(
		(markers["drill"] as BuildingMarker).get_world_point().y,
		base.get_job_spot_position("SCIENCE").y + 2.0,
		0.05,
		"Marker WorldAnchor sits ~2 m above job spot"
	)

	# Case 2: Greenhouse packed and later died -> shown and greyed with JOB_GREY_NO_GREENHOUSE
	hud.set_packed_greenhouse(true)
	hud.crew_cards[0].update_availability(false, false, 0, false, false)
	hud.select_crew(0) # deselect
	hud.select_crew(0) # re-select cleanly
	markers = hud.get_building_markers()
	assert_true(markers.has("greenhouse"), "Dead packed greenhouse marker still shown")
	var gh_marker: BuildingMarker = markers["greenhouse"] as BuildingMarker
	assert_false(gh_marker.is_primary_available(), "Dead greenhouse marker greyed")
	assert_eq(gh_marker.get_primary_reason(), tr("JOB_GREY_NO_GREENHOUSE"), "Shows no living greenhouse reason")

	# Case 3: Greenhouse packed and alive -> active
	hud.crew_cards[0].update_availability(false, false, 0, true, true)
	hud.select_crew(0)
	hud.select_crew(0)
	gh_marker = hud.get_building_markers()["greenhouse"] as BuildingMarker
	assert_true(gh_marker.is_primary_available(), "Living greenhouse marker active")

	hud.free()
	base.free()
	TranslationServer.set_locale(prev_locale)


func test_repair_solar_split_sick_and_storm_markers() -> void:
	var prev_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var hud: DayHud = DayHudScene.instantiate() as DayHud
	root.add_child(hud)
	hud._ready()
	hud.set_packed_greenhouse(true)

	# 1. Nothing broken: life_support greyed, solar single CLEAN
	hud.crew_cards[0].update_availability(false, false, 0, true, true)
	hud.select_crew(0)
	var ls_m: BuildingMarker = hud.get_building_markers()["life_support"] as BuildingMarker
	var solar_m: BuildingMarker = hud.get_building_markers()["solar"] as BuildingMarker
	assert_false(ls_m.is_primary_available(), "Life support greyed when nothing broken")
	assert_eq(ls_m.get_primary_reason(), tr("JOB_GREY_NOTHING_BROKEN"), "Life support disabled reason")
	assert_false(solar_m.is_split_mode, "Solar is single CLEAN when no panels broken")
	assert_eq(solar_m.get_primary_job(), SimPlanScript.JOB_CLEAN, "Solar default job is CLEAN")

	# Tapping greyed marker shows reason in banner and keeps selection open
	ls_m.disabled_tapped.emit("life_support", SimPlanScript.JOB_REPAIR, ls_m.get_primary_reason())
	assert_eq(hud.get_selected_crew_index(), 0, "Greyed tap keeps selection open")
	assert_eq(hud.get_select_banner_text(), tr("JOB_GREY_NOTHING_BROKEN"), "Banner shows disabled reason")

	# 2. Broken panel & recycler OK -> Solar split Clean + Repair, Life support still greyed
	hud.crew_cards[0].update_availability(false, false, 1, true, true)
	hud.deselect_crew()
	hud.select_crew(0)
	ls_m = hud.get_building_markers()["life_support"] as BuildingMarker
	solar_m = hud.get_building_markers()["solar"] as BuildingMarker
	assert_false(ls_m.is_primary_available(), "Life support stays greyed when only panel broken")
	assert_true(solar_m.is_split_mode, "Solar splits into Clean and Repair when panel broken")
	assert_true(solar_m.is_left_available() and solar_m.is_right_available(), "Solar Clean and Repair both active")

	# 2b. Recycler broken (+ broken panel) -> Life support REPAIR active, Solar stays single CLEAN, assigning sets REPAIR
	hud.crew_cards[0].update_availability(false, true, 1, true, true)
	hud.deselect_crew()
	hud.select_crew(0)
	ls_m = hud.get_building_markers()["life_support"] as BuildingMarker
	solar_m = hud.get_building_markers()["solar"] as BuildingMarker
	assert_true(ls_m.is_primary_available(), "Life support active when recycler broken")
	assert_false(solar_m.is_split_mode, "Solar stays single CLEAN when recycler is broken")
	ls_m.marker_activated.emit("life_support", SimPlanScript.JOB_REPAIR)
	assert_eq(hud.crew_cards[0].get_job(), SimPlanScript.JOB_REPAIR, "Life support marker assigns REPAIR")

	# 3. Sick astronaut -> can still select, only Habitat active
	hud.crew_cards[2].set_crew_data(400.0, true, 1)
	hud.crew_cards[2].update_availability(false, true, 1, true, true)
	hud.select_crew(2)
	assert_eq(hud.get_selected_crew_index(), 2, "Sick astronaut can still be selected")
	var markers := hud.get_building_markers()
	assert_true((markers["habitat"] as BuildingMarker).is_primary_available(), "Sick astronaut can always Rest at Habitat")
	for bkey in ["life_support", "solar", "greenhouse", "dig_site", "drill"]:
		var bm: BuildingMarker = markers[bkey] as BuildingMarker
		if bm.is_split_mode:
			assert_false(bm.is_left_available() or bm.is_right_available(), "%s split greyed for sick" % bkey)
		else:
			assert_false(bm.is_primary_available(), "%s greyed for sick" % bkey)
			assert_eq(bm.get_primary_reason(), tr("JOB_GREY_SICK"), "%s sick reason matches" % bkey)

	# 4. Storm day -> healthy astronaut selectable, only Habitat active
	hud.set_storm_day(true)
	hud.select_crew(0)
	assert_eq(hud.get_selected_crew_index(), 0, "Healthy astronaut still selectable during storm")
	markers = hud.get_building_markers()
	assert_true((markers["habitat"] as BuildingMarker).is_primary_available(), "Habitat active in storm")
	for bkey in ["life_support", "solar", "greenhouse", "dig_site", "drill"]:
		var bm: BuildingMarker = markers[bkey] as BuildingMarker
		assert_false(bm.is_primary_available(), "%s greyed during storm" % bkey)
		assert_eq(bm.get_primary_reason(), tr("JOB_GREY_STORM"), "%s storm reason matches" % bkey)

	hud.free()
	TranslationServer.set_locale(prev_locale)


func test_assign_advances_to_next_rest_crew_in_main() -> void:
	var prev_id: String = Settings.current_mission_id
	var prev_free: bool = Settings.free_play
	var prev_stars: Dictionary = Settings.mission_stars.duplicate(true)
	var prev_tut_skipped: bool = Settings.tutorial_skipped
	var prev_hint: bool = Settings.hint_collect_shown

	Settings.current_mission_id = "M4"
	Settings.free_play = true
	Settings.tutorial_skipped = true
	Settings.hint_collect_shown = true

	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var main := MainScene.instantiate()
	root.add_child(main)
	main._ready()
	if main.day_hud != null:
		main.day_hud._ready()
	if main.title_screen != null:
		main.title_screen.visible = false
	var sm: SimMissions = main._get_sim_missions()
	GameState.new_mission(null, 123, sm.get_force("M4"), sm.get_sim_constants("M4"))
	main._enter_state(main.State.PLAN_DAY)

	var hud: DayHud = main.day_hud
	var crew: Crew = main.world.get_node_or_null("Crew") as Crew

	# Step 1: Select Crew 0 (Rafi) and tap Drill (SCIENCE) -> advances to Crew 1 (Mira)
	hud.select_crew(0)
	(hud.get_building_markers()["drill"] as BuildingMarker).marker_activated.emit("drill", SimPlanScript.JOB_SCIENCE)
	assert_eq(hud.crew_cards[0].get_job(), SimPlanScript.JOB_SCIENCE, "Crew 0 assigned SCIENCE")
	assert_eq(main.current_plan.jobs[0], SimPlanScript.JOB_SCIENCE, "Main plan updated via job_changed")
	assert_eq(crew.get_astronaut_job(0), SimPlanScript.JOB_SCIENCE, "3D Crew astronaut moved to SCIENCE")
	assert_eq(hud.get_selected_crew_index(), 1, "Selection advances to next REST crew (1)")

	# Step 2: Assign Crew 1 CLEAN -> advances to Crew 2
	(hud.get_building_markers()["solar"] as BuildingMarker).marker_activated.emit("solar", SimPlanScript.JOB_CLEAN)
	assert_eq(hud.get_selected_crew_index(), 2, "Selection advances to Crew 2")

	# Step 3: Assign Crew 2 REGOLITH -> advances to Crew 3
	(hud.get_building_markers()["dig_site"] as BuildingMarker).marker_activated.emit("dig_site", SimPlanScript.JOB_REGOLITH)
	assert_eq(hud.get_selected_crew_index(), 3, "Selection advances to Crew 3")

	# Step 4: Assign Crew 3 CLEAN -> no more crew on REST -> selection clears
	(hud.get_building_markers()["solar"] as BuildingMarker).marker_activated.emit("solar", SimPlanScript.JOB_CLEAN)
	assert_eq(hud.get_selected_crew_index(), -1, "Selection clears once all crew leave REST")
	assert_true(hud.get_building_markers().is_empty(), "Building markers hidden when selection clears")

	main.free()
	Settings.current_mission_id = prev_id
	Settings.free_play = prev_free
	Settings.mission_stars = prev_stars
	Settings.tutorial_skipped = prev_tut_skipped
	Settings.hint_collect_shown = prev_hint


func test_camera_touch_safety_and_empty_ground_tap() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var cam := CameraRigScene.instantiate()
	var hud: DayHud = DayHudScene.instantiate() as DayHud
	root.add_child(cam)
	root.add_child(hud)
	cam._ready()
	var cam3d := cam.get_node("YawNode/PitchNode/Camera3D") as Camera3D
	cam3d.look_at_from_position(Vector3(0.0, 12.0, 26.0), Vector3.ZERO, Vector3.UP)
	cam3d.current = true
	hud._ready()
	hud.select_crew(0)

	var empty_taps := [0]
	cam.empty_ground_tapped.connect(func(): empty_taps[0] += 1)
	cam.empty_ground_tapped.connect(hud.deselect_crew)

	# 1. Point over an active building marker button blocks camera
	var solar_marker := hud.get_building_markers()["solar"] as BuildingMarker
	solar_marker.camera_override = cam3d
	solar_marker.update_position(cam3d)
	var solar_btn := solar_marker._circle_btn
	solar_btn.global_position = Vector2(300.0, 220.0)
	solar_btn.size = Vector2(72.0, 72.0)
	var btn_center := solar_btn.global_position + solar_btn.size * 0.5
	assert_true(solar_marker.visible, "BuildingMarker visible when camera looks at base")
	assert_true(cam.is_ui_blocking_point(btn_center), "Camera blocks touch starting on BuildingMarker button")

	var ui_down := InputEventScreenTouch.new()
	ui_down.index = 0
	ui_down.pressed = true
	ui_down.position = btn_center
	cam._unhandled_input(ui_down)

	var yaw_before: float = cam.target_yaw
	var ui_drag := InputEventScreenDrag.new()
	ui_drag.index = 0
	ui_drag.position = btn_center + Vector2(40.0, 0.0)
	ui_drag.relative = Vector2(40.0, 0.0)
	cam._unhandled_input(ui_drag)
	assert_near(cam.target_yaw, yaw_before, 0.0001, "Drag starting on marker does not rotate camera")

	var ui_up := InputEventScreenTouch.new()
	ui_up.index = 0
	ui_up.pressed = false
	ui_up.position = btn_center
	cam._unhandled_input(ui_up)
	assert_eq(empty_taps[0], 0, "UI touch does not emit empty_ground_tapped")
	assert_eq(hud.get_selected_crew_index(), 0, "UI touch does not deselect via empty ground")

	# 2. Long drag (>= 12 px) on empty ground orbits camera and does NOT deselect
	var ground_pt := Vector2(1050.0, 180.0)
	assert_false(cam.is_ui_blocking_point(ground_pt), "Open ground point is not blocked by UI")

	var g_down := InputEventScreenTouch.new()
	g_down.index = 1
	g_down.pressed = true
	g_down.position = ground_pt
	cam._unhandled_input(g_down)

	var g_drag := InputEventScreenDrag.new()
	g_drag.index = 1
	g_drag.position = ground_pt + Vector2(30.0, 0.0)
	g_drag.relative = Vector2(30.0, 0.0)
	cam._unhandled_input(g_drag)
	assert_true(not is_equal_approx(cam.target_yaw, yaw_before), "Empty ground drag rotates camera")

	var g_up := InputEventScreenTouch.new()
	g_up.index = 1
	g_up.pressed = false
	g_up.position = ground_pt + Vector2(30.0, 0.0)
	cam._unhandled_input(g_up)
	assert_eq(empty_taps[0], 0, "Drag >= 12 px does not emit empty_ground_tapped")

	# 3. Short tap (< 12 px) on empty ground cancels selection
	var t_down := InputEventScreenTouch.new()
	t_down.index = 2
	t_down.pressed = true
	t_down.position = ground_pt
	cam._unhandled_input(t_down)

	var t_up := InputEventScreenTouch.new()
	t_up.index = 2
	t_up.pressed = false
	t_up.position = ground_pt + Vector2(5.0, 3.0)
	cam._unhandled_input(t_up)
	assert_eq(empty_taps[0], 1, "Short tap < 12 px emits empty_ground_tapped")
	assert_eq(hud.get_selected_crew_index(), -1, "Short ground tap cancels active selection")

	hud.free()
	cam.free()

