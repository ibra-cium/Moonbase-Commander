extends "res://tests/test_case.gd"

const LanderScene: PackedScene = preload("res://world/Lander.tscn")
const DayHudScene: PackedScene = preload("res://ui/DayHud.tscn")
const DebriefScreenScene: PackedScene = preload("res://ui/DebriefScreen.tscn")
const MainScene: PackedScene = preload("res://scenes/Main.tscn")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimMissionScript := preload("res://sim/sim_mission.gd")

func test_lander_nodes_and_methods() -> void:
	var lander = LanderScene.instantiate()
	assert_true(lander != null, "Lander must instantiate")
	assert_true(lander.has_node("LanderBody"), "Must have LanderBody")
	assert_true(lander.has_node("LanderBody/FlameSprite"), "Must have FlameSprite")
	assert_true(lander.has_node("DustParticles"), "Must have DustParticles")
	assert_true(lander.has_node("ScorchMark"), "Must have ScorchMark")
	assert_true(lander.has_node("CratesContainer"), "Must have CratesContainer")

	lander._ready()
	assert_near(lander.lander_body.position.y, 0.0, 0.01, "Lander body at rest is at y=0")
	assert_false(lander.flame_sprite.visible, "Flame sprite hidden at rest")

	lander.setup_landing_start()
	assert_near(lander.lander_body.position.y, 22.0, 0.1, "Lander starts descent from high y")
	assert_true(lander.flame_sprite.visible, "Flame sprite visible during descent")

	lander.reset_state()
	assert_near(lander.lander_body.position.y, 0.0, 0.01, "Lander reset restores y=0")
	lander.free()

func test_day_hud() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var hud: Control = DayHudScene.instantiate() as Control
	root.add_child(hud)
	hud._ready()

	assert_true(hud.day_label != null, "DayLabel must exist")
	assert_true(hud.fast_toggle != null, "FastToggle button must exist")
	assert_true(hud.end_day_button != null, "EndDayButton must exist")
	assert_true(hud.status_label != null, "StatusLabel must exist")

	# Touch target check: EndDayButton >= 64px tall
	assert_true(hud.end_day_button.custom_minimum_size.y >= 64.0, "EndDayButton height >= 64px for touch")

	hud.set_day(5)
	assert_true(hud.day_label.text.contains("5"), "DayLabel should display day 5")

	hud.set_resolving(true)
	assert_true(hud.end_day_button.disabled, "EndDayButton should be disabled during resolution")
	assert_true(hud.status_label.visible, "StatusLabel visible during resolution")

	hud.set_resolving(false)
	assert_false(hud.end_day_button.disabled, "EndDayButton should be enabled during planning")
	assert_false(hud.status_label.visible, "StatusLabel hidden during planning")

	root.remove_child(hud)
	hud.free()

func test_crew_card_functionality() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var crew_card_scene: PackedScene = preload("res://ui/CrewCard.tscn")
	var card = crew_card_scene.instantiate()
	root.add_child(card)
	card._ready()

	# Crew 1: Purple suit
	card.setup(1)
	assert_eq(card.crew_index, 1, "Crew index set to 1")
	assert_near(card.suit_badge.color.r, 0.545, 0.05, "Suit badge red channel")
	assert_near(card.suit_badge.color.b, 0.965, 0.05, "Suit badge blue channel")
	assert_eq(card.get_job(), "REST", "Initial job is REST")

	# Availability check: without broken stuff or greenhouse, available are REST, CLEAN, REGOLITH, SCIENCE
	card.update_availability(false, false, 0, false, false)
	assert_true(card.is_job_available("REST"), "REST always available")
	assert_false(card.is_job_available("REPAIR"), "REPAIR unavailable when nothing broken")
	assert_false(card.is_job_available("FARM"), "FARM unavailable without greenhouse")
	assert_true(card.is_job_available("CLEAN"), "CLEAN available")
	assert_true(card.is_job_available("REGOLITH"), "REGOLITH available")
	assert_true(card.is_job_available("SCIENCE"), "SCIENCE available")

	# Cycling jobs
	card._cycle_next_job()
	assert_eq(card.get_job(), "CLEAN", "Next job cycled to CLEAN")

	# When recycler broken: REPAIR becomes available
	card.update_availability(false, true, 0, false, false)
	assert_true(card.is_job_available("REPAIR"), "REPAIR available when recycler broken")

	# When greenhouse alive: FARM becomes available
	card.update_availability(false, false, 0, true, true)
	assert_true(card.is_job_available("FARM"), "FARM available when greenhouse active")

	# Sickness: sick crew can only REST
	card.set_crew_data(15.5, true, 2)
	assert_eq(card.get_job(), "REST", "Sick crew forced to REST")
	assert_true(card.is_sick, "Crew is sick")
	assert_true(card.sick_container.visible, "Sick indicator visible")
	assert_true(card.dose_label.text.contains("15.5"), "Dose displayed")
	assert_true(card.is_job_available("REST"), "REST available when sick")
	assert_false(card.is_job_available("CLEAN"), "CLEAN unavailable when sick")
	assert_false(card.is_job_available("SCIENCE"), "SCIENCE unavailable when sick")

	# Storm: forces REST
	card.set_crew_data(0.0, false, 0)
	card.update_availability(true, true, 1, true, true)
	assert_eq(card.get_job(), "REST", "Storm forces REST")
	assert_false(card.is_job_available("SCIENCE"), "SCIENCE unavailable in storm")

	root.remove_child(card)
	card.free()

func test_day_hud_gauges_and_switches() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var hud = DayHudScene.instantiate()
	root.add_child(hud)
	hud._ready()

	# 7 Gauges exist
	assert_true(hud.power_gauge != null, "Power gauge exists")
	assert_true(hud.o2_gauge != null, "O2 gauge exists")
	assert_true(hud.co2_gauge != null, "CO2 gauge exists")
	assert_true(hud.water_gauge != null, "Water gauge exists")
	assert_true(hud.food_gauge != null, "Food gauge exists")
	assert_true(hud.rad_gauge != null, "Rad gauge exists")
	assert_true(hud.shelter_gauge != null, "Shelter gauge exists")

	# Every gauge has source tag constant id
	assert_true(hud.power_gauge.source_constant_id != "", "Power gauge has source tag")
	assert_true(hud.power_gauge.source_tag.visible, "Power gauge source tag is visible")
	assert_true(hud.power_gauge.source_tag.info_button != null, "Power gauge info button exists")
	assert_true(hud.power_gauge.source_tag.info_button.visible, "Power gauge info button is visible")
	assert_true(hud.o2_gauge.source_constant_id != "", "O2 gauge has source tag")
	assert_true(hud.o2_gauge.source_tag.visible, "O2 gauge source tag is visible")
	assert_true(hud.co2_gauge.source_constant_id != "", "CO2 gauge has source tag")
	assert_true(hud.water_gauge.source_constant_id != "", "Water gauge has source tag")
	assert_true(hud.food_gauge.source_constant_id != "", "Food gauge has source tag")
	assert_true(hud.rad_gauge.source_constant_id != "", "Rad gauge has source tag")
	assert_true(hud.shelter_gauge.source_constant_id != "", "Shelter gauge has source tag")

	# 4 Crew cards exist
	assert_eq(hud.crew_cards.size(), 4, "4 CrewCards exist in HUD")

	# Day / Sun / Night icon
	hud.set_day(1)
	assert_eq(hud.sun_night_label.text, "Sun", "Day 1 is Sun")
	hud.set_day(15)
	assert_eq(hud.sun_night_label.text, "Night", "Day 15 is Night")

	# Switches
	assert_true(hud.greenhouse_switch != null, "Greenhouse switch exists")
	assert_true(hud.science_switch != null, "Science switch exists")
	assert_false(hud.science_switch.visible, "Science switch is hidden on HUD")
	hud.crew_cards[0].set_job("SCIENCE")
	assert_true(hud.get_plan().science_gear_on, "Science gear auto ON with SCIENCE job")
	hud.crew_cards[0].set_job("REST")
	assert_false(hud.get_plan().science_gear_on, "Science gear auto OFF without SCIENCE job")

	# Report update & Toast
	var rep_script = preload("res://sim/sim_day_report.gd")
	var rep = rep_script.new()
	rep.day = 3
	rep.generation_kwh = 140.0
	rep.battery_percent = 0.90
	rep.o2_kg = 80.0
	rep.co2_mmhg = 1.2
	rep.water_kg = 250.0
	rep.food_kg = 180.0
	rep.highest_dose_msv = 5.0
	rep.shelter_g_cm2 = 12.0
	var crew_arr: Array[Dictionary] = [
		{"dose_msv": 5.0, "sick": false, "sick_days": 0},
		{"dose_msv": 4.0, "sick": false, "sick_days": 0},
		{"dose_msv": 3.0, "sick": false, "sick_days": 0},
		{"dose_msv": 2.0, "sick": false, "sick_days": 0}
	]
	rep.crew_reports = crew_arr
	hud.update_from_report(rep)

	assert_true(hud.toast_panel.visible, "Toast visible after report")
	assert_true(hud.toast_line1.text.contains("Day 3"), "Toast mentions Day 3")

	# Blackout report
	rep.blackout = true
	rep.hours_on_battery = 18.5
	hud.update_from_report(rep)
	assert_eq(hud.power_gauge.current_state, hud.power_gauge.State.CRITICAL, "Blackout sets critical power gauge")
	assert_true(hud.toast_line1.text.contains("18.5"), "Toast mentions battery hours on blackout")

	# Menu
	hud._on_menu_button_pressed()
	assert_true(hud.pause_layer.visible, "Pause menu opens on menu button")
	hud._close_pause_menu()
	assert_false(hud.pause_layer.visible, "Pause menu closes")

	root.remove_child(hud)
	hud.free()

func test_fast_mode_toggle() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	Settings.fast_mode = false
	assert_false(Settings.fast_mode, "fast_mode initially false")

	var hud: Control = DayHudScene.instantiate() as Control
	root.add_child(hud)
	hud._ready()

	hud._on_fast_button_pressed()
	assert_true(Settings.fast_mode, "fast_mode toggles to true")

	hud._on_fast_button_pressed()
	assert_false(Settings.fast_mode, "fast_mode toggles back to false")

	root.remove_child(hud)
	hud.free()

func test_debrief_screen() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var debrief: Control = DebriefScreenScene.instantiate() as Control
	root.add_child(debrief)
	debrief._ready()

	assert_true(debrief.outcome_label != null, "OutcomeLabel exists")
	assert_true(debrief.stars_label != null, "StarsLabel exists")
	assert_true(debrief.days_label != null, "DaysLabel exists")
	assert_true(debrief.seed_label != null, "SeedLabel exists")
	assert_true(debrief.retry_button != null, "RetryButton exists")
	assert_true(debrief.change_cargo_button != null, "ChangeCargoButton exists")
	assert_true(debrief.title_button != null, "TitleButton exists")

	# Touch targets: buttons >= 64px
	assert_true(debrief.retry_button.custom_minimum_size.y >= 64.0, "RetryButton height >= 64px")
	assert_true(debrief.change_cargo_button.custom_minimum_size.y >= 64.0, "ChangeCargoButton height >= 64px")
	assert_true(debrief.title_button.custom_minimum_size.y >= 64.0, "TitleButton height >= 64px")

	# Test success result (3 stars)
	var success_res = {
		"outcome": "SURVIVED",
		"stars": 3,
		"end_day": 30,
		"root_cause_code": "ROOT_SUCCESS",
		"root_cause_values": {"stars": 3, "ever_sick": false, "science_points": 12, "science_goal": 10},
		"root_cause": "ROOT_SUCCESS"
	}
	debrief.show_result(success_res, 987654)
	assert_true(debrief.stars_label.text.contains("★ ★ ★"), "Shows 3 stars")
	assert_true(debrief.seed_label.text.contains("987654"), "Shows seed 987654")
	assert_true(debrief.days_label.text.contains("30"), "Shows 30 days")
	assert_true(debrief.reason_label.text.contains("3 stars"), "Shows 3 stars success text")

	# Test evacuated result (S01 - night energy)
	var s01_res = {
		"outcome": "EVAC_CO2",
		"stars": 0,
		"end_day": 18,
		"root_cause_code": "ROOT_NIGHT_ENERGY",
		"root_cause_values": {"have": 1250, "need": 4350},
		"cause_chain": [
			{"id": 1, "day": 15, "code": "SUNSET", "values": {}},
			{"id": 2, "day": 16, "code": "BLACKOUT", "values": {}},
			{"id": 3, "day": 17, "code": "CO2_HIGH", "values": {"co2": 8.5}},
			{"id": 4, "day": 18, "code": "EVAC_CO2", "values": {}}
		]
	}
	debrief.show_result(s01_res, 12345)
	assert_true(debrief.stars_label.text.contains("☆ ☆ ☆"), "Shows 0 stars")
	assert_true(debrief.seed_label.text.contains("12345"), "Shows seed 12345")
	assert_true(debrief.days_label.text.contains("18"), "Shows day 18")
	assert_true(debrief.reason_label.text.contains("1250"), "Shows have kWh in root cause")
	assert_true(debrief.reason_label.text.contains("4350"), "Shows need kWh in root cause")
	assert_true(debrief.timeline_section.visible, "Timeline visible when chain present")
	assert_eq(debrief.timeline_vbox.get_child_count(), 4, "Timeline contains 4 entries")

	# Test S05 (radiation / shelter)
	var s05_res = {
		"outcome": "EVAC_RADIATION",
		"stars": 0,
		"end_day": 12,
		"root_cause_code": "ROOT_SHIELD",
		"root_cause_values": {"g": 0.0, "g_needed": 14.8, "limit": 250.0},
		"cause_chain": [
			{"id": 5, "day": 12, "code": "STORM_WARNING", "values": {"warning_min": 60}},
			{"id": 6, "day": 12, "code": "EVAC_RADIATION", "values": {}}
		]
	}
	debrief.show_result(s05_res, 55555)
	assert_true(debrief.reason_label.text.contains("0.0 g/cm²"), "Shows shelter g in root cause")
	assert_true(debrief.reason_label.text.contains("14.8 g/cm²"), "Shows g_needed in root cause")
	assert_true(debrief.storm_disclosure_box.visible, "Storm disclosure visible for storm evacuation")

	# Test S06 (recycler not fixed)
	var s06_res = {
		"outcome": "EVAC_WATER",
		"stars": 0,
		"end_day": 20,
		"root_cause_code": "ROOT_REPAIR",
		"root_cause_values": {"d": 12}
	}
	debrief.show_result(s06_res, 66666)
	assert_true(debrief.reason_label.text.contains("Day 12"), "Shows recycler broke day in root cause")

	# Test Survived with 2 stars (missing science star)
	var s02_res = {
		"outcome": "SURVIVED",
		"stars": 2,
		"end_day": 30,
		"root_cause_code": "ROOT_SUCCESS",
		"root_cause_values": {"stars": 2, "ever_sick": false, "science_points": 0, "science_goal": 10}
	}
	debrief.show_result(s02_res, 22222)
	assert_true(debrief.stars_label.text.contains("★ ★ ☆"), "Shows 2 stars")
	assert_true(debrief.reason_label.text.contains("Missing star"), "Shows missing star explanation")
	assert_true(debrief.reason_label.text.contains("0/10"), "Shows science points vs goal")

	root.remove_child(debrief)
	debrief.free()

func test_main_state_machine_flow() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()

	assert_eq(main.current_state, main.State.TITLE, "Starts in TITLE state")

	# Move TITLE -> PACK
	main._enter_state(main.State.PACK)
	assert_eq(main.current_state, main.State.PACK, "In PACK state")
	assert_true(main.pack_screen.visible, "PackScreen visible")

	# Move PACK -> LANDING
	var test_cargo := SimCargoScript.new(Constants.sim)
	test_cargo.set_count("solar", 20)
	test_cargo.set_count("battery", 4)
	test_cargo.set_count("reactor", 2)
	test_cargo.set_count("o2", 2)
	test_cargo.set_count("water", 4)
	test_cargo.set_count("food", 5)
	test_cargo.set_count("shield", 10)

	main._on_pack_launch_requested(test_cargo)
	assert_eq(main.current_state, main.State.LANDING, "In LANDING state")
	assert_true(main.current_seed > 0, "Seed was generated")
	assert_true(GameState.current_mission != null, "Mission started in GameState")

	# Fast-forward landing completion -> PLAN_DAY
	main._on_landing_completed()
	assert_eq(main.current_state, main.State.PLAN_DAY, "In PLAN_DAY state")
	assert_true(main.day_hud.visible, "DayHud visible in PLAN_DAY")
	assert_eq(GameState.current_mission.day, 1, "Mission is on Day 1")

	# End Day 1 -> RESOLVE_DAY
	main._on_end_day_pressed()
	assert_eq(main.current_state, main.State.RESOLVE_DAY, "In RESOLVE_DAY state")
	assert_true(main.day_hud.is_resolving, "HUD shows resolving")

	# Resolve finishes -> PLAN_DAY (Day 2)
	main._on_resolve_completed()
	assert_eq(main.current_state, main.State.PLAN_DAY, "Returned to PLAN_DAY")
	assert_eq(GameState.current_mission.day, 2, "Mission advanced to Day 2")

	root.remove_child(main)
	main.free()

func test_full_30_day_mission_completion() -> void:
	# Run a complete 30-day mission (M4) start to end with base cargo
	var prev_mission_id: String = Settings.current_mission_id
	Settings.current_mission_id = "M4"
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()

	var base_cargo := SimCargoScript.new(Constants.sim)
	base_cargo.set_count("solar", 20)
	base_cargo.set_count("battery", 4)
	base_cargo.set_count("reactor", 2)
	base_cargo.set_count("o2", 2)
	base_cargo.set_count("water", 6)
	base_cargo.set_count("food", 5)
	base_cargo.set_count("shield", 10)

	# Launch
	main._on_pack_launch_requested(base_cargo)
	assert_eq(main.current_state, main.State.LANDING, "In LANDING state")

	# Landing finishes
	main._on_landing_completed()
	assert_eq(main.current_state, main.State.PLAN_DAY, "In PLAN_DAY state")

	# Play through 30 days
	var max_iterations := 40
	var iterations := 0
	while not GameState.current_mission.ended and iterations < max_iterations:
		iterations += 1
		# In plan day: if storm day, shelter crew; repair if needed
		if GameState.current_mission.events != null and GameState.current_mission.day == GameState.current_mission.events.storm_day:
			for i in range(4):
				main.current_plan.set_job(i, "REST")
		elif GameState.current_mission.life != null and GameState.current_mission.life.recycler_broken:
			main.current_plan.set_job(0, "REPAIR")
		elif GameState.current_mission.power != null and GameState.current_mission.power.broken_panels > 0:
			main.current_plan.set_job(0, "REPAIR")

		# End day
		main._on_end_day_pressed()
		assert_eq(main.current_state, main.State.RESOLVE_DAY, "Step %d: In RESOLVE_DAY" % iterations)

		# Resolve completes
		main._on_resolve_completed()

	assert_true(GameState.current_mission.ended, "Mission must be ended after 30 days")
	# When mission ends, Main enters ENDING sequence; skipping or completing it reaches DEBRIEF
	if main.current_state == main.State.ENDING:
		assert_true(main.ending_overlay != null and main.ending_overlay.visible, "EndingOverlay visible during ENDING")
		main._on_ending_skip_pressed()
	assert_eq(main.current_state, main.State.DEBRIEF, "Reached DEBRIEF state")
	assert_true(main.debrief_screen.visible, "DebriefScreen visible")
	assert_eq(GameState.current_mission.result.outcome, "SURVIVED", "Mission survived successfully")
	assert_eq(GameState.current_mission.result.end_day, 30, "Survived all 30 days")

	# Test Retry Mission button
	main._on_debrief_retry_pressed()
	assert_eq(main.current_state, main.State.LANDING, "Retry starts a new LANDING")
	assert_true(main.current_seed > 0, "New seed generated for retried mission")

	root.remove_child(main)
	main.free()
	Settings.current_mission_id = prev_mission_id

func test_hud_reset_crew_to_rest_and_signal() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var hud: DayHud = DayHudScene.instantiate() as DayHud
	root.add_child(hud)
	hud._ready()

	var received := {"idx": -1, "job": ""}
	hud.crew_job_changed.connect(func(idx: int, job: String):
		received.idx = idx
		received.job = job
	)

	# Change job on crew card 0
	hud.crew_cards[0].set_job("CLEAN")
	assert_eq(received.idx, 0, "crew_job_changed received index 0")
	assert_eq(received.job, "CLEAN", "crew_job_changed received CLEAN job")
	assert_eq(hud.crew_cards[0].get_job(), "CLEAN", "Card 0 job is CLEAN")

	# Reset all to rest
	hud.reset_crew_to_rest()
	for i in range(4):
		assert_eq(hud.crew_cards[i].get_job(), "REST", "Card %d reset to REST" % i)

	root.remove_child(hud)
	hud.free()

