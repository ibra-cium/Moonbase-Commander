extends "res://tests/test_case.gd"

const SimMissionsScript := preload("res://sim/sim_missions.gd")
const SimMissionScript := preload("res://sim/sim_mission.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const PackScreenScene: PackedScene = preload("res://ui/PackScreen.tscn")
const DayHudScene: PackedScene = preload("res://ui/DayHud.tscn")
const DebriefScreenScene: PackedScene = preload("res://ui/DebriefScreen.tscn")
const TutorialOverlayScene: PackedScene = preload("res://ui/TutorialOverlay.tscn")
const MissionMapScene: PackedScene = preload("res://ui/MissionMap.tscn")
const MainScene: PackedScene = preload("res://scenes/Main.tscn")

func test_constants_with_overrides_pure() -> void:
	var base := load_constants()
	var base_days: int = int(base.v("MISSION_DAYS"))
	var base_limit: float = float(base.v("CARGO_LIMIT_KG"))

	var overridden := base.with_overrides({"MISSION_DAYS": 5})
	assert_eq(int(overridden.v("MISSION_DAYS")), 5, "Overridden MISSION_DAYS should be 5")
	assert_near(float(overridden.v("CARGO_LIMIT_KG")), base_limit, 0.01, "Non-overridden constants preserved")
	assert_eq(int(base.v("MISSION_DAYS")), base_days, "Base SimConstants must remain unchanged")

func test_sim_missions_data_and_m4_equals_base() -> void:
	var base := load_constants()
	var sm := SimMissionsScript.new(base)

	var ids := sm.all_ids()
	assert_eq(ids.size(), 4, "Should have 4 missions")
	assert_eq(ids, ["M1", "M2", "M3", "M4"], "Mission IDs in order M1..M4")

	# M1: 5 days, hidden reactor/greenhouse/shield, forced 0s
	var m1_sim := sm.get_sim_constants("M1")
	assert_eq(int(m1_sim.v("MISSION_DAYS")), 5, "M1 MISSION_DAYS = 5")
	var m1_force := sm.get_force("M1")
	assert_eq(int(m1_force.get("recycler_day", -1)), 0, "M1 forces recycler_day = 0")
	assert_eq(int(m1_force.get("storm_day", -1)), 0, "M1 forces storm_day = 0")
	var m1_hidden := sm.get_hidden_items("M1")
	assert_true("reactor" in m1_hidden, "M1 hides reactor")
	assert_true("greenhouse" in m1_hidden, "M1 hides greenhouse")
	assert_true("shield" in m1_hidden, "M1 hides shield")

	# M2: 10 days, recycler breaks Day 4, water locked at 2
	var m2_sim := sm.get_sim_constants("M2")
	assert_eq(int(m2_sim.v("MISSION_DAYS")), 10, "M2 MISSION_DAYS = 10")
	var m2_force := sm.get_force("M2")
	assert_eq(int(m2_force.get("recycler_day", 0)), 4, "M2 forces recycler_day = 4")
	var m2_locked := sm.get_locked_items("M2")
	assert_eq(int(m2_locked.get("water", 0)), 2, "M2 locks water at 2")

	# M3: 12 days, storm Day 8
	var m3_sim := sm.get_sim_constants("M3")
	assert_eq(int(m3_sim.v("MISSION_DAYS")), 12, "M3 MISSION_DAYS = 12")
	var m3_force := sm.get_force("M3")
	assert_eq(int(m3_force.get("storm_day", 0)), 8, "M3 forces storm_day = 8")

	# M4 equals base constants completely
	var m4_sim := sm.get_sim_constants("M4")
	for cid in base.ids():
		assert_eq(str(m4_sim.v(cid)), str(base.v(cid)), "M4 constant %s must equal base" % cid)
	assert_true(sm.get_force("M4").is_empty(), "M4 has no forced events")
	assert_true(sm.get_hidden_items("M4").is_empty(), "M4 hides no items")
	assert_true(sm.get_locked_items("M4").is_empty(), "M4 locks no items")

func test_settings_unlock_progression_and_free_play() -> void:
	var prev_id: String = Settings.current_mission_id
	var prev_stars: Dictionary = Settings.mission_stars.duplicate(true)
	var prev_free: bool = Settings.free_play

	Settings.mission_stars.clear()
	Settings.free_play = false

	assert_true(Settings.is_mission_unlocked("M1"), "M1 always unlocked")
	assert_false(Settings.is_mission_unlocked("M2"), "M2 initially locked")
	assert_false(Settings.is_mission_unlocked("M3"), "M3 initially locked")
	assert_false(Settings.is_mission_unlocked("M4"), "M4 initially locked")

	Settings.record_stars("M1", 2)
	assert_true(Settings.is_mission_unlocked("M2"), "M2 unlocks after winning M1")
	assert_false(Settings.is_mission_unlocked("M3"), "M3 stays locked until M2 won")

	# Record lower stars does not downgrade best
	Settings.record_stars("M1", 1)
	assert_eq(int(Settings.mission_stars.get("M1", 0)), 2, "Best star count preserved")

	Settings.free_play = true
	for mid in ["M1", "M2", "M3", "M4"]:
		assert_true(Settings.is_mission_unlocked(mid), "%s unlocked in free play" % mid)

	Settings.free_play = false
	assert_false(Settings.is_mission_unlocked("M3"), "M3 locks again when free play disabled")

	Settings.current_mission_id = prev_id
	Settings.mission_stars = prev_stars
	Settings.free_play = prev_free

func test_pack_screen_hidden_locked_and_night_warning() -> void:
	var prev_id: String = Settings.current_mission_id
	var prev_cargo = GameState.last_cargo
	var root: Window = (Engine.get_main_loop() as SceneTree).root

	# M1: reactor/greenhouse/shield hidden, night warning hidden
	Settings.current_mission_id = "M1"
	GameState.last_cargo = null
	var pack := PackScreenScene.instantiate()
	root.add_child(pack)
	pack._ready()

	assert_false(pack.card_reactor.visible, "M1 hides reactor card")
	assert_false(pack.card_greenhouse.visible, "M1 hides greenhouse card")
	assert_false(pack.card_shield.visible, "M1 hides shield card")
	assert_true(pack.card_solar.visible, "M1 shows solar card")
	if pack.warn_night_row != null:
		assert_false(pack.warn_night_row.visible, "M1 hides night-energy warning row")

	# M2: water locked at 2 with no +/- buttons
	Settings.current_mission_id = "M2"
	GameState.last_cargo = null
	pack.reset_to_initial_or_last()
	assert_eq(pack.get_current_cargo().get_count("water"), 2, "M2 starts with water locked at 2")
	assert_false(pack.card_water.btn_minus.visible, "Locked water hides minus button")
	assert_false(pack.card_water.btn_plus.visible, "Locked water hides plus button")
	pack.card_water._on_plus_pressed()
	assert_eq(pack.get_current_cargo().get_count("water"), 2, "Locked water cannot be incremented")

	# M4: all 8 visible, night warning visible
	Settings.current_mission_id = "M4"
	GameState.last_cargo = null
	pack.reset_to_initial_or_last()
	assert_true(pack.card_reactor.visible, "M4 shows reactor card")
	assert_true(pack.card_greenhouse.visible, "M4 shows greenhouse card")
	assert_true(pack.card_shield.visible, "M4 shows shield card")
	assert_true(pack.card_water.btn_minus.visible, "M4 water minus button visible")
	if pack.warn_night_row != null:
		assert_true(pack.warn_night_row.visible, "M4 shows night-energy warning row")

	root.remove_child(pack)
	pack.free()
	Settings.current_mission_id = prev_id
	GameState.last_cargo = prev_cargo

func test_hud_debrief_and_tutorial_use_mission_days() -> void:
	var prev_id: String = Settings.current_mission_id
	var base := load_constants()
	var sm := SimMissionsScript.new(base)
	var m1_c := sm.get_sim_constants("M1")
	var m1_cargo := SimCargoScript.new(m1_c)
	m1_cargo.load_dict({"solar": 10, "o2": 2, "water": 4, "food": 5})
	var m1_mission := SimMissionScript.new(m1_c, m1_cargo, 1, sm.get_force("M1"))

	var root: Window = (Engine.get_main_loop() as SceneTree).root

	# DayHud shows / 5 and not 30
	var hud := DayHudScene.instantiate()
	root.add_child(hud)
	hud._ready()
	hud.setup_mission(m1_mission)
	assert_true(hud.day_label.text.contains("5"), "HUD day label includes 5 for M1")
	assert_false(hud.day_label.text.contains("30"), "HUD day label must not show 30 for M1")
	root.remove_child(hud)
	hud.free()

	# Debrief uses 5 and shows Next mission only on SURVIVED with has_next
	var debrief := DebriefScreenScene.instantiate()
	root.add_child(debrief)
	debrief._ready()
	debrief.show_result_with_next({"outcome": "SURVIVED", "end_day": 5, "total_days": 5, "stars": 2}, 1, true)
	assert_true(debrief.days_label.text.contains("5"), "Debrief days text shows 5")
	assert_false(debrief.days_label.text.contains("30"), "Debrief days text must not show 30 for M1")
	assert_true(debrief.next_mission_button.visible, "Next mission button visible on win when has_next is true")

	debrief.show_result_with_next({"outcome": "EVAC_FOOD", "end_day": 1, "total_days": 5, "stars": 0}, 1, true)
	assert_false(debrief.next_mission_button.visible, "Next mission button hidden on loss")
	root.remove_child(debrief)
	debrief.free()

	# Tutorial step 4 uses TUT_STEP3_GOAL for M1 and lunar night for M4
	var tut := TutorialOverlayScene.instantiate()
	root.add_child(tut)
	tut._ready()
	Settings.current_mission_id = "M1"
	tut.show_step(4)
	assert_true(tut.body_label.text.contains("5"), "Tutorial step 4 shows M1 5-day goal")
	assert_false(tut.body_label.text.contains("14"), "Tutorial step 4 must not mention 14 dark days on M1")

	Settings.current_mission_id = "M4"
	tut.show_step(4)
	assert_true(tut.body_label.text.contains("14"), "Tutorial step 4 mentions 14 dark days on M4")
	root.remove_child(tut)
	tut.free()

	Settings.current_mission_id = prev_id

func test_mission_map_screen() -> void:
	var prev_id: String = Settings.current_mission_id
	var prev_stars: Dictionary = Settings.mission_stars.duplicate(true)
	var prev_free: bool = Settings.free_play
	Settings.mission_stars.clear()
	Settings.free_play = false

	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var map: MissionMap = MissionMapScene.instantiate() as MissionMap
	root.add_child(map)
	map._ready()
	assert_true(map._bg != null and map._bg.texture != null, "MissionMap Moon background texture must load in exported builds")
	var m1_stars: HBoxContainer = map._btns[0].get_node_or_null("CaptionPill/CaptionVBox/StarsRow") as HBoxContainer
	assert_true(m1_stars != null and m1_stars.get_child_count() == 3 and m1_stars.get_child(0) is TextureRect, "MissionMap stars use SVG TextureRects")

	# Tapping locked M2 shows MAP_LOCKED and keeps Play hidden
	map._on_mission_pressed("M2")
	assert_true(map._detail_panel.visible, "Detail panel shows locked info")
	assert_eq(map._detail_goal.text, tr("MAP_LOCKED"), "Locked detail shows MAP_LOCKED")
	assert_false(map._play_btn.visible, "Play button hidden for locked mission")

	# Tapping M1 shows Play button and 5-day goal
	map._on_mission_pressed("M1")
	assert_true(map._play_btn.visible, "Play button visible for unlocked M1")
	assert_true(map._detail_goal.text.contains("5"), "M1 goal includes 5 days")

	# Free play unlocks M2
	map._on_free_play_toggled(true)
	map._on_mission_pressed("M2")
	assert_true(map._play_btn.visible, "Play button visible for M2 in Free play")

	root.remove_child(map)
	map.free()
	Settings.current_mission_id = prev_id
	Settings.mission_stars = prev_stars
	Settings.free_play = prev_free

func test_end_to_end_m1_m2_lose_and_m4_day15() -> void:
	var prev_id: String = Settings.current_mission_id
	var prev_stars: Dictionary = Settings.mission_stars.duplicate(true)
	var prev_free: bool = Settings.free_play
	var prev_pack_tut: bool = Settings.tutorial_pack_done
	var prev_hud_tut: bool = Settings.tutorial_hud_done
	var prev_cargo = GameState.last_cargo

	Settings.reset_onboarding()
	Settings.mission_stars.clear()
	Settings.free_play = false
	GameState.current_mission = null
	GameState.last_cargo = null

	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()

	# 1. Title -> Map
	assert_eq(main.current_state, main.State.TITLE, "Starts on TITLE")
	main._on_title_start_completed()
	assert_eq(main.current_state, main.State.MAP, "Title leads to MAP")

	# 2. Pick M1 on Map -> Briefing -> Pack
	main.mission_map._on_mission_pressed("M1")
	main.mission_map._on_play_pressed()
	assert_eq(main.current_state, main.State.BRIEFING, "Play M1 enters BRIEFING")
	main.mission_briefing._on_next_pressed()
	main.mission_briefing._on_next_pressed()
	main.mission_briefing._on_option_pressed(0)
	main.mission_briefing._on_go_pressed()
	assert_eq(main.current_state, main.State.PACK, "Completing M1 briefing enters PACK")
	assert_eq(Settings.current_mission_id, "M1", "Selected mission is M1")
	assert_eq(main.pack_screen.get_current_cargo().get_count("solar"), 10, "M1 starts with start_cargo solar=10")

	if main.tutorial_overlay != null and main.tutorial_overlay.visible:
		main.tutorial_overlay.primary_button.pressed.emit()

	# 3. Play M1 to SURVIVED on Day 5
	main._on_pack_launch_requested(main.pack_screen.get_current_cargo())
	main._on_landing_completed()
	assert_eq(main.current_state, main.State.PLAN_DAY, "M1 entered PLAN_DAY")
	if main.tutorial_overlay != null and main.tutorial_overlay.visible:
		main.tutorial_overlay.primary_button.pressed.emit()  # Step 2 -> Step 3 (Crew Tasks)
		main.tutorial_overlay.primary_button.pressed.emit()  # Step 3 -> Step 4 (Mission Goal)
		assert_true(main.tutorial_overlay.body_label.text.contains("5"), "M1 Step 4 shows M1 goal days")
		assert_false(main.tutorial_overlay.body_label.text.contains("14"), "M1 Step 4 omits lunar night 14")
		main.tutorial_overlay.primary_button.pressed.emit()

	var m1_iters := 0
	while not GameState.current_mission.ended and m1_iters < 10:
		m1_iters += 1
		main._on_end_day_pressed()
		main._on_resolve_completed()
	assert_true(GameState.current_mission.ended, "M1 ended within 5 days")
	assert_eq(GameState.current_mission.result.outcome, "SURVIVED", "M1 survived")
	assert_eq(GameState.current_mission.result.end_day, 5, "M1 ended on day 5")
	if main.current_state == main.State.ENDING:
		main._on_ending_skip_pressed()
	assert_eq(main.current_state, main.State.DEBRIEF, "M1 reached DEBRIEF")
	assert_true(main.debrief_screen.next_mission_button.visible, "Next mission visible after M1 win")
	assert_true(Settings.is_mission_unlocked("M2"), "M2 unlocked after M1 win")

	# 4. Next mission -> M2 Briefing -> Pack, lose on purpose (no repair)
	main._on_debrief_next_mission_pressed()
	assert_eq(main.current_state, main.State.BRIEFING, "Next mission enters BRIEFING for M2")
	main.mission_briefing._on_next_pressed()
	main.mission_briefing._on_next_pressed()
	main.mission_briefing._on_option_pressed(0)
	main.mission_briefing._on_go_pressed()
	assert_eq(main.current_state, main.State.PACK, "Completing M2 briefing enters PACK")
	assert_eq(Settings.current_mission_id, "M2", "Mission advanced to M2")
	assert_eq(main.pack_screen.get_current_cargo().get_count("water"), 2, "M2 water locked at 2")
	assert_false(main.pack_screen.card_water.btn_plus.visible, "M2 water hides plus button")

	main._on_pack_launch_requested(main.pack_screen.get_current_cargo())
	main._on_landing_completed()
	var m2_iters := 0
	while not GameState.current_mission.ended and m2_iters < 12:
		m2_iters += 1
		for i in range(4):
			main.current_plan.set_job(i, "REST")
		main._on_end_day_pressed()
		main._on_resolve_completed()
	assert_true(GameState.current_mission.ended, "M2 loss ended")
	assert_eq(GameState.current_mission.result.outcome, "EVAC_WATER", "M2 lost to EVAC_WATER")
	assert_eq(GameState.current_mission.result.end_day, 9, "M2 lost on day 9")
	assert_eq(GameState.current_mission.result.root_cause_code, "ROOT_REPAIR", "M2 root cause is ROOT_REPAIR")
	if main.current_state == main.State.ENDING:
		main._on_ending_skip_pressed()
	assert_eq(main.current_state, main.State.DEBRIEF, "M2 reached DEBRIEF")
	assert_false(main.debrief_screen.next_mission_button.visible, "Next mission hidden after loss")
	assert_false(main.debrief_screen.storm_disclosure_box.visible, "No storm disclosure on M2")
	assert_true(main.debrief_screen.days_label.text.contains("10"), "M2 debrief displays total 10 days")
	assert_false(main.debrief_screen.days_label.text.contains("30"), "M2 debrief does not show 30")

	# 5. Debrief Title/Map button -> Map -> Free play -> M4 to Day 15
	main._on_debrief_title_pressed()
	assert_eq(main.current_state, main.State.MAP, "Debrief title button returns to MAP")
	main.mission_map._on_free_play_toggled(true)
	main.mission_map._on_mission_pressed("M4")
	main.mission_map._on_play_pressed()
	assert_eq(main.current_state, main.State.BRIEFING, "Free play M4 enters BRIEFING")
	main.mission_briefing._on_skip_pressed() if main.mission_briefing.skip_button.visible else main.mission_briefing._on_next_pressed()
	if main.current_state == main.State.BRIEFING:
		main.mission_briefing._on_next_pressed()
		main.mission_briefing._on_option_pressed(0)
		main.mission_briefing._on_go_pressed()
	assert_eq(main.current_state, main.State.PACK, "Free play M4 briefing enters PACK")
	assert_eq(Settings.current_mission_id, "M4", "Free play selected M4")

	var m4_cargo := SimCargoScript.new(Constants.sim)
	m4_cargo.load_dict({"solar": 20, "battery": 4, "reactor": 2, "o2": 2, "water": 6, "food": 5, "shield": 10})
	main._on_pack_launch_requested(m4_cargo)
	main._on_landing_completed()
	var reached_day_15 := false
	for _d in range(15):
		if GameState.current_mission.ended:
			break
		if GameState.current_mission.day == 15:
			reached_day_15 = true
		if GameState.current_mission.life.recycler_broken or GameState.current_mission.power.broken_panels > 0:
			main.current_plan.set_job(0, "REPAIR")
		else:
			main.current_plan.set_job(0, "REST")
		main._on_end_day_pressed()
		main._on_resolve_completed()
	assert_true(reached_day_15, "M4 reached Day 15 sunset")

	# Verify Change Cargo keeps last_cargo
	main._on_debrief_change_cargo_pressed()
	assert_eq(main.current_state, main.State.PACK, "Change Cargo returns to PACK")
	assert_eq(main.pack_screen.get_current_cargo().get_count("reactor"), 2, "Change Cargo keeps previous reactor count")

	root.remove_child(main)
	main.free()
	GameState.current_mission = null
	GameState.last_cargo = prev_cargo
	Settings.current_mission_id = prev_id
	Settings.mission_stars = prev_stars
	Settings.free_play = prev_free
	Settings.tutorial_pack_done = prev_pack_tut
	Settings.tutorial_hud_done = prev_hud_tut

