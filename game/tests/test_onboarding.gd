extends "res://tests/test_case.gd"

const TutorialOverlayScene: PackedScene = preload("res://ui/TutorialOverlay.tscn")
const MainScene: PackedScene = preload("res://scenes/Main.tscn")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimDayReportScript := preload("res://sim/sim_day_report.gd")
const SimEventScript := preload("res://sim/sim_event.gd")

func _reset_state() -> void:
	if Settings != null and Settings.has_method("reset_onboarding"):
		Settings.reset_onboarding()
	if GameState != null:
		GameState.current_mission = null
		GameState.last_cargo = null

func test_tutorial_overlay_steps_and_skip() -> void:
	_reset_state()
	var prev_id: String = Settings.current_mission_id
	Settings.current_mission_id = "M4"
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var overlay: TutorialOverlay = TutorialOverlayScene.instantiate() as TutorialOverlay
	root.add_child(overlay)
	overlay._ready()

	assert_false(overlay.visible, "TutorialOverlay starts hidden")
	assert_true(overlay.primary_button.custom_minimum_size.y >= 64.0, "Primary button >= 64px height")
	assert_true(overlay.skip_button.custom_minimum_size.y >= 64.0, "Skip button >= 64px height")

	var acked: Array = []
	var finished := [false]
	var skipped := [false]
	overlay.step_acknowledged.connect(func(s: int): acked.append(s))
	overlay.tutorial_finished.connect(func(): finished[0] = true)
	overlay.tutorial_skipped.connect(func(): skipped[0] = true)

	# Step 1
	overlay.show_step(1)
	assert_true(overlay.visible, "Step 1 visible")
	assert_true(overlay.skip_button.visible, "Skip visible on Step 1")
	assert_false(overlay.title_label.text.is_empty(), "Step 1 title populated")
	assert_false(overlay.body_label.text.contains("{"), "Step 1 placeholders formatted")
	assert_true(overlay.body_label.text.contains("15000"), "Step 1 uses CARGO_LIMIT_KG")
	assert_false(overlay.tasks_grid.visible, "TasksGrid hidden on Step 1")

	overlay.primary_button.pressed.emit()
	assert_false(overlay.visible, "Step 1 hides after Got it")
	assert_eq(acked, [1], "Step 1 acknowledged")

	# Step 2 -> Step 3 (Crew Tasks) -> Step 4 (Night/Goal) -> Finish
	overlay.show_step(2)
	assert_true(overlay.visible, "Step 2 visible")
	assert_true(overlay.skip_button.visible, "Skip visible on Step 2")
	assert_false(overlay.tasks_grid.visible, "TasksGrid hidden on Step 2")

	overlay.primary_button.pressed.emit()
	assert_true(overlay.visible, "Overlay remains visible for Step 3")
	assert_eq(overlay.current_step, 3, "Advanced from Step 2 to Step 3")
	assert_true(overlay.skip_button.visible, "Skip visible on Step 3")
	assert_true(overlay.badge_label.text.contains("3") and overlay.badge_label.text.contains("4"), "Step 3 badge shows 3 / 4")
	assert_true(overlay.tasks_grid.visible, "TasksGrid visible on Step 3")
	assert_eq(overlay.task_rows.size(), 6, "All 6 crew tasks shown in tutorial")

	var seen_jobs: Dictionary = {}
	for row in overlay.task_rows:
		var job_id: String = str(row["job"])
		var t_lbl: Label = row["title_label"] as Label
		var d_lbl: Label = row["desc_label"] as Label
		var icon_tx: TextureRect = row["icon_rect"] as TextureRect
		seen_jobs[job_id] = d_lbl.text
		assert_false(t_lbl.text.is_empty(), "Task title populated for " + job_id)
		assert_false(d_lbl.text.is_empty(), "Task desc populated for " + job_id)
		assert_false(d_lbl.text.contains("{"), "Task desc placeholders formatted for " + job_id)
		assert_true(icon_tx.texture != null, "Task icon loaded for " + job_id)
	assert_eq(seen_jobs.size(), 6, "All 6 distinct crew jobs present")
	assert_true(str(seen_jobs.get("REST", "")).contains(str(int(Constants.v("SICK_REST_DAYS")))), "REST desc uses SICK_REST_DAYS")
	assert_true(str(seen_jobs.get("FARM", "")).contains(str(int(Constants.v("FARM_EVERY_DAYS")))), "FARM desc uses FARM_EVERY_DAYS")
	assert_true(str(seen_jobs.get("REGOLITH", "")).contains("2.5"), "REGOLITH desc uses REGOLITH_G_CM2_PER_JOB")
	assert_true(str(seen_jobs.get("SCIENCE", "")).contains(str(int(Constants.v("SCIENCE_GOAL_POINTS")))), "SCIENCE desc uses SCIENCE_GOAL_POINTS")

	overlay.primary_button.pressed.emit()
	assert_true(overlay.visible, "Overlay remains visible for Step 4")
	assert_eq(overlay.current_step, 4, "Advanced from Step 3 to Step 4")
	assert_false(overlay.tasks_grid.visible, "TasksGrid hidden on Step 4")
	assert_false(overlay.skip_button.visible, "Skip hidden on final Step 4")
	assert_false(overlay.body_label.text.contains("{"), "Step 4 placeholders formatted")
	assert_true(overlay.body_label.text.contains("15"), "Step 4 uses SUNSET_DAY")

	overlay.primary_button.pressed.emit()
	assert_false(overlay.visible, "Overlay hides after Step 4 finish")
	assert_true(finished[0], "tutorial_finished emitted")
	assert_eq(acked, [1, 2, 3, 4], "All 4 steps acknowledged")

	# Hints must keep TasksGrid hidden
	overlay.show_step(3)
	assert_true(overlay.tasks_grid.visible, "TasksGrid visible before switching to hint")
	overlay.show_hint("broken")
	assert_false(overlay.tasks_grid.visible, "TasksGrid hidden on hint")

	# Skip test
	overlay.show_step(1)
	overlay.skip_button.pressed.emit()
	assert_false(overlay.visible, "Overlay hides on skip")
	assert_true(skipped[0], "tutorial_skipped emitted")

	root.remove_child(overlay)
	overlay.free()
	Settings.current_mission_id = prev_id
	_reset_state()

func test_tutorial_shows_once_and_can_be_skipped_in_main() -> void:
	_reset_state()
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()

	# First mission: Pack screen shows Step 1
	main._enter_state(main.State.PACK)
	assert_true(main.tutorial_overlay.visible, "Step 1 shows on first PACK entry")
	assert_eq(main.tutorial_overlay.current_step, 1, "Overlay shows Step 1 on PACK")

	main.tutorial_overlay.primary_button.pressed.emit()
	assert_false(main.tutorial_overlay.visible, "Step 1 closes on Got it")
	assert_true(Settings.tutorial_pack_done, "tutorial_pack_done marked true")

	# Re-entering PACK does not re-show Step 1
	main._enter_state(main.State.PACK)
	assert_false(main.tutorial_overlay.visible, "Step 1 does not show twice on PACK")

	# Launch into Day 1 PLAN_DAY -> Step 2 & Step 3
	var cargo := SimCargoScript.new(Constants.sim)
	cargo.set_count("solar", 20)
	cargo.set_count("battery", 4)
	cargo.set_count("reactor", 2)
	cargo.set_count("o2", 2)
	cargo.set_count("water", 4)
	cargo.set_count("food", 5)
	cargo.set_count("shield", 10)
	main._on_pack_launch_requested(cargo)
	assert_false(main.tutorial_overlay.visible, "Overlay hidden during LANDING")

	main._on_landing_completed()
	assert_eq(main.current_state, main.State.PLAN_DAY, "Entered PLAN_DAY")
	assert_true(main.tutorial_overlay.visible, "Step 2 shows on first PLAN_DAY")
	assert_eq(main.tutorial_overlay.current_step, 2, "Overlay shows Step 2 on Day 1")

	main.tutorial_overlay.primary_button.pressed.emit()
	assert_true(main.tutorial_overlay.visible, "Step 3 shows after Next")
	assert_eq(main.tutorial_overlay.current_step, 3, "Overlay shows Step 3 crew tasks")
	assert_true(main.tutorial_overlay.tasks_grid.visible, "Crew tasks grid visible on Step 3")

	main.tutorial_overlay.primary_button.pressed.emit()
	assert_true(main.tutorial_overlay.visible, "Step 4 shows after Next")
	assert_eq(main.tutorial_overlay.current_step, 4, "Overlay shows Step 4")
	assert_false(main.tutorial_overlay.tasks_grid.visible, "Crew tasks grid hidden on Step 4")

	main.tutorial_overlay.primary_button.pressed.emit()
	assert_false(main.tutorial_overlay.visible, "Overlay closes after Step 4")
	assert_true(Settings.is_tutorial_finished(), "Tutorial marked finished for session")

	# Second mission in same session: no tutorial
	main._on_debrief_change_cargo_pressed()
	assert_false(main.tutorial_overlay.visible, "Tutorial does not show on second mission PACK")
	main._on_pack_launch_requested(cargo)
	main._on_landing_completed()
	assert_false(main.tutorial_overlay.visible, "Tutorial does not show on second mission PLAN_DAY")

	# Test skip on Step 1 suppresses Steps 2-4 too
	_reset_state()
	main._enter_state(main.State.PACK)
	assert_true(main.tutorial_overlay.visible, "Step 1 shows after onboarding reset")
	main.tutorial_overlay.skip_button.pressed.emit()
	assert_true(Settings.tutorial_skipped, "Skip sets tutorial_skipped")
	main._on_pack_launch_requested(cargo)
	main._on_landing_completed()
	assert_false(main.tutorial_overlay.visible, "Steps 2-4 do not show after skipping on Step 1")

	root.remove_child(main)
	main.free()
	_reset_state()

func test_context_hints_trigger_once_each_and_respect_popups() -> void:
	_reset_state()
	Settings.tutorial_skipped = true
	Settings.tutorial_pack_done = true
	Settings.tutorial_hud_done = true

	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()

	var cargo := SimCargoScript.new(Constants.sim)
	cargo.set_count("solar", 20)
	cargo.set_count("battery", 4)
	cargo.set_count("reactor", 1)
	cargo.set_count("o2", 2)
	cargo.set_count("water", 4)
	cargo.set_count("food", 5)
	cargo.set_count("shield", 10)
	main._on_pack_launch_requested(cargo)
	main._on_landing_completed()
	assert_false(main.tutorial_overlay.visible, "Tutorial skipped")

	# 1. Daytime low battery (<30% on Day 5) should NOT trigger night battery hint
	var day5_rep := SimDayReportScript.new()
	day5_rep.day = 5
	day5_rep.battery_capacity_kwh = 40.0
	day5_rep.battery_percent = 20.0
	day5_rep.co2_mmhg = 1.5
	main._on_game_state_day_resolved(day5_rep)
	main._enter_state(main.State.PLAN_DAY)
	assert_false(Settings.hint_battery_low_shown, "Battery < 30% in daylight does not trigger night hint")
	assert_false(main.tutorial_overlay.visible, "No hint shown for daytime battery")

	# 2. Nighttime battery < 30% (Day 16) triggers once after SUNSET popup closes
	main.pending_popups.append(SimEventScript.new("SUNSET", 15, true, {}))
	var day15_rep := SimDayReportScript.new()
	day15_rep.day = 15
	day15_rep.battery_capacity_kwh = 40.0
	day15_rep.battery_percent = 25.0
	day15_rep.co2_mmhg = 1.5
	main._on_game_state_day_resolved(day15_rep)
	main._enter_state(main.State.PLAN_DAY)

	assert_true(main.event_popup.visible, "SUNSET EventPopup shows first")
	assert_false(main.tutorial_overlay.visible, "Hint waits until EventPopup closes")

	main.event_popup.select_choice(0)
	assert_false(main.event_popup.visible, "SUNSET EventPopup closed")
	assert_true(main.tutorial_overlay.visible, "Battery low hint shows after EventPopup")
	assert_eq(main.tutorial_overlay.current_hint_id, "battery_low", "Shows battery_low hint")
	assert_false(main.tutorial_overlay.body_label.text.contains("{"), "Battery hint formatted")

	main.tutorial_overlay.primary_button.pressed.emit()
	assert_false(main.tutorial_overlay.visible, "Battery hint closes on OK")
	assert_true(Settings.hint_battery_low_shown, "Battery hint marked shown")

	# Second low battery report does NOT re-trigger
	var day16_rep := SimDayReportScript.new()
	day16_rep.day = 16
	day16_rep.battery_capacity_kwh = 40.0
	day16_rep.battery_percent = 10.0
	day16_rep.co2_mmhg = 1.5
	main._on_game_state_day_resolved(day16_rep)
	main._enter_state(main.State.PLAN_DAY)
	assert_false(main.tutorial_overlay.visible, "Battery hint does not repeat")

	# 3. First broken thing + First CO2 yellow queued together
	var day17_rep := SimDayReportScript.new()
	day17_rep.day = 17
	day17_rep.battery_capacity_kwh = 40.0
	day17_rep.battery_percent = 50.0
	day17_rep.recycler_broken = true
	day17_rep.co2_mmhg = float(Constants.v("CO2_HEALTHY_MAX_MMHG")) + 0.5
	main._on_game_state_day_resolved(day17_rep)
	main._enter_state(main.State.PLAN_DAY)

	assert_true(main.tutorial_overlay.visible, "Broken equipment hint shows first")
	assert_eq(main.tutorial_overlay.current_hint_id, "broken", "Shows broken hint")
	main.tutorial_overlay.primary_button.pressed.emit()

	assert_true(main.tutorial_overlay.visible, "Queued CO2 yellow hint shows next")
	assert_eq(main.tutorial_overlay.current_hint_id, "co2_yellow", "Shows co2_yellow hint")
	assert_false(main.tutorial_overlay.body_label.text.contains("{"), "CO2 hint formatted")
	main.tutorial_overlay.primary_button.pressed.emit()
	assert_false(main.tutorial_overlay.visible, "All hints dismissed")

	# Broken solar panel + high CO2 next day do NOT re-trigger
	var day18_rep := SimDayReportScript.new()
	day18_rep.day = 18
	day18_rep.broken_panels = 1
	day18_rep.co2_mmhg = 3.5
	main._on_game_state_day_resolved(day18_rep)
	main._enter_state(main.State.PLAN_DAY)
	assert_false(main.tutorial_overlay.visible, "Broken and CO2 hints do not repeat")

	root.remove_child(main)
	main.free()
	_reset_state()
