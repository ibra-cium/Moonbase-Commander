extends "res://tests/test_case.gd"

const AstronautScript := preload("res://world/astronaut.gd")
const CrewCardScene := preload("res://ui/CrewCard.tscn")
const AstronautScene := preload("res://world/Astronaut.tscn")
const SpeechBubbleScript := preload("res://world/speech_bubble.gd")
const SpeechBubbleScene := preload("res://world/SpeechBubble.tscn")
const MainScene := preload("res://scenes/Main.tscn")
const SimPlanScript := preload("res://sim/sim_plan.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimDayReportScript := preload("res://sim/sim_day_report.gd")
const SimEventScript := preload("res://sim/sim_event.gd")

func test_crew_names_and_suit_badges() -> void:
	var expected_names: Array[String] = ["Rafi", "Mira", "Leo", "Nadia"]
	var root: Window = (Engine.get_main_loop() as SceneTree).root

	for i in range(4):
		assert_eq(AstronautScript.crew_name_for(i), expected_names[i], "Astronaut name %d matches" % i)

		var card = CrewCardScene.instantiate()
		root.add_child(card)
		card._ready()
		card.setup(i)
		assert_eq(card.crew_label.text, expected_names[i], "CrewCard %d label shows name" % i)
		assert_eq(card.suit_badge.color, AstronautScript.SUIT_COLORS[i], "CrewCard %d badge uses SUIT_COLORS" % i)

		card.open_picker()
		assert_true(card.picker_title.text.contains(expected_names[i]), "Picker title %d includes name" % i)
		assert_true(card.picker_suit_badge != null, "Picker header has suit badge %d" % i)
		assert_eq(card.picker_suit_badge.color, AstronautScript.SUIT_COLORS[i], "Picker badge %d uses SUIT_COLORS" % i)
		root.remove_child(card)
		card.free()

		var astro = AstronautScene.instantiate() as Astronaut
		root.add_child(astro)
		astro._ready()
		astro.set_crew_index(i)
		var tag: Label3D = astro.get_node_or_null("BodyPivot/NameTag") as Label3D
		assert_true(tag != null, "Astronaut %d has NameTag Label3D" % i)
		if tag != null:
			assert_eq(tag.text, expected_names[i], "NameTag %d text matches" % i)
			assert_eq(int(tag.billboard), int(BaseMaterial3D.BILLBOARD_ENABLED), "NameTag %d billboard enabled" % i)
			assert_true(tag.no_depth_test, "NameTag %d has no_depth_test" % i)
			astro.set_name_tag_hidden(true)
			assert_false(tag.visible, "NameTag %d hides for cinematics" % i)
			astro.set_name_tag_hidden(false)
			assert_true(tag.visible, "NameTag %d shows again after cinematic" % i)
		root.remove_child(astro)
		astro.free()

func _make_clean_report(day_num: int = 2) -> RefCounted:
	var rep := SimDayReportScript.new()
	rep.day = day_num
	rep.co2_mmhg = 0.8
	rep.food_kg = 100.0
	rep.recycler_broken = false
	rep.broken_panels = 0
	rep.science_points = 0
	rep.storm_dose_msv = 0.0
	rep.events = []
	rep.new_log_ids = []
	rep.crew_reports = [
		{"job": "REST", "sick": false, "sick_days": 0},
		{"job": "REST", "sick": false, "sick_days": 0},
		{"job": "REST", "sick": false, "sick_days": 0},
		{"job": "REST", "sick": false, "sick_days": 0},
	]
	return rep

func _base_ctx() -> Dictionary:
	return {
		"prev_sick": [false, false, false, false],
		"prev_recycler_broken": false,
		"prev_broken_panels": 0,
		"prev_science_points": 0,
		"sunset_day": 15,
		"co2_healthy_max": 2.0,
		"supply_warning_days": 3.0,
		"food_per_person_day": 2.39,
		"crew_count": 4,
		"seed_val": 424242,
	}

func test_speech_bubble_priority_and_speaker_rules() -> void:
	# Day 1 Hello
	var hello := SpeechBubbleScript.pick_hello(424242, [false, false, false, false])
	assert_eq(hello["key"], "CREW_SAY_HELLO", "Day 1 hello key")

	var ctx := _base_ctx()

	# Priority 9: Default good day
	var rep9 := _make_clean_report(3)
	var v9 := SpeechBubbleScript.pick_voice(rep9, ctx)
	assert_eq(v9["key"], "CREW_SAY_GOOD", "Priority 9 fallback GOOD")

	# Priority 8: Science went up beats GOOD
	var rep8 := _make_clean_report(4)
	rep8.science_points = 2
	var v8 := SpeechBubbleScript.pick_voice(rep8, ctx)
	assert_eq(v8["key"], "CREW_SAY_SCIENCE", "Priority 8 SCIENCE beats GOOD")

	# Priority 7: Repaired today beats SCIENCE, targets the repairer
	var ctx7 := _base_ctx()
	ctx7["prev_recycler_broken"] = true
	var rep7 := _make_clean_report(5)
	rep7.science_points = 3
	rep7.recycler_broken = false
	rep7.crew_reports[2]["job"] = "REPAIR"
	var v7 := SpeechBubbleScript.pick_voice(rep7, ctx7)
	assert_eq(v7["key"], "CREW_SAY_FIXED", "Priority 7 FIXED beats SCIENCE")
	assert_eq(v7["crew_index"], 2, "FIXED bubble placed on the repairer")

	# Priority 6: First day after sunset (Day 16) beats FIXED/SCIENCE
	var rep6 := _make_clean_report(16)
	rep6.recycler_broken = false
	rep6.science_points = 4
	var v6 := SpeechBubbleScript.pick_voice(rep6, ctx7)
	assert_eq(v6["key"], "CREW_SAY_DARK", "Priority 6 DARK beats FIXED/SCIENCE on Day 16")

	# Priority 5: Food low (< 3 days -> < 28.68 kg) beats DARK
	var rep5 := _make_clean_report(16)
	rep5.food_kg = 20.0
	var v5 := SpeechBubbleScript.pick_voice(rep5, ctx)
	assert_eq(v5["key"], "CREW_SAY_FOOD_LOW", "Priority 5 FOOD_LOW beats DARK")

	# Priority 4: CO2 > CO2_HEALTHY_MAX_MMHG (2.0) beats FOOD_LOW
	var rep4 := _make_clean_report(16)
	rep4.food_kg = 20.0
	rep4.co2_mmhg = 2.5
	var v4 := SpeechBubbleScript.pick_voice(rep4, ctx)
	assert_eq(v4["key"], "CREW_SAY_STUFFY", "Priority 4 STUFFY beats FOOD_LOW")

	# Priority 3: Broken recycler or panel beats STUFFY
	var rep3 := _make_clean_report(16)
	rep3.co2_mmhg = 2.5
	rep3.recycler_broken = true
	rep3.events = [SimEventScript.new("RECYCLER_BROKE", 16, false, {})]
	var v3 := SpeechBubbleScript.pick_voice(rep3, ctx)
	assert_eq(v3["key"], "CREW_SAY_BROKEN", "Priority 3 BROKEN beats STUFFY")

	# Priority 2: Newly sick beats BROKEN, placed over sick astronaut
	var rep2 := _make_clean_report(16)
	rep2.co2_mmhg = 2.5
	rep2.recycler_broken = true
	rep2.events = [SimEventScript.new("RECYCLER_BROKE", 16, false, {})]
	rep2.crew_reports[3]["sick"] = true
	var v2 := SpeechBubbleScript.pick_voice(rep2, ctx)
	assert_eq(v2["key"], "CREW_SAY_SICK", "Priority 2 SICK beats BROKEN")
	assert_eq(v2["crew_index"], 3, "SICK bubble placed on the sick astronaut")

	# Priority 1: Storm beats everything else
	var rep1 := _make_clean_report(16)
	rep1.co2_mmhg = 2.5
	rep1.recycler_broken = true
	rep1.crew_reports[3]["sick"] = true
	rep1.events = [SimEventScript.new("STORM", 16, false, {"storm_dose": 12.0})]
	var v1 := SpeechBubbleScript.pick_voice(rep1, ctx)
	assert_eq(v1["key"], "CREW_SAY_STORM", "Priority 1 STORM beats all")

func test_jobs_kept_between_days_and_science_auto() -> void:
	var prev_mission: String = Settings.current_mission_id
	var prev_tut_hud: bool = Settings.tutorial_hud_done
	var prev_tut_pack: bool = Settings.tutorial_pack_done
	var prev_tut_skip: bool = Settings.tutorial_skipped

	Settings.current_mission_id = "M4"
	Settings.tutorial_skipped = true
	Settings.tutorial_hud_done = true
	Settings.tutorial_pack_done = true

	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()

	var cargo := SimCargoScript.new(Constants.sim)
	cargo.set_count("solar", 20)
	cargo.set_count("battery", 4)
	cargo.set_count("reactor", 2)
	cargo.set_count("o2", 2)
	cargo.set_count("water", 6)
	cargo.set_count("food", 5)
	cargo.set_count("shield", 10)
	cargo.set_count("greenhouse", 1)

	main._on_pack_launch_requested(cargo)
	main._on_landing_completed()

	# Day 1 hello bubble appears
	assert_true(main.speech_bubble.is_showing(), "Day 1 hello bubble is visible after landing")
	assert_eq(main.speech_bubble.text_label.text, SpeechBubbleScript.translate_line("CREW_SAY_HELLO"), "Day 1 shows hello line")

	# Science switch hidden & follows SCIENCE job
	assert_false(main.day_hud.science_switch.visible, "ScienceSwitch hidden on HUD")
	main.day_hud.crew_cards[0].set_job(SimPlanScript.JOB_CLEAN)
	main.day_hud.crew_cards[1].set_job(SimPlanScript.JOB_SCIENCE)
	main.day_hud.crew_cards[2].set_job(SimPlanScript.JOB_FARM)
	assert_true(main.current_plan.science_gear_on, "science_gear_on is true when crew has SCIENCE")
	assert_true(main.day_hud.get_plan().science_gear_on, "HUD plan science_gear_on follows SCIENCE job")

	# Resolve Day 1 -> enter Day 2 PLAN_DAY (avoid random storm on Day 2)
	GameState.current_mission.events.storm_day = 99
	GameState.current_mission.events.recycler_day = 99
	GameState.current_mission.events.meteoroid_day = 99
	main._on_end_day_pressed()
	assert_false(main.speech_bubble.is_showing(), "Bubble hides when ending day")
	main._on_resolve_completed()

	assert_eq(GameState.current_mission.day, 2, "Advanced to Day 2")
	assert_eq(main.day_hud.crew_cards[0].get_job(), SimPlanScript.JOB_CLEAN, "Crew 0 kept CLEAN job on Day 2")
	assert_eq(main.day_hud.crew_cards[1].get_job(), SimPlanScript.JOB_SCIENCE, "Crew 1 kept SCIENCE job on Day 2")
	assert_eq(main.day_hud.crew_cards[2].get_job(), SimPlanScript.JOB_FARM, "Crew 2 kept FARM job on Day 2")
	assert_true(main.current_plan.science_gear_on, "Kept SCIENCE job preserves science_gear_on")
	assert_true(main.speech_bubble.is_showing(), "One bubble shown for resolved Day 1")

	# Removing SCIENCE turns science_gear_on false
	main.day_hud.crew_cards[1].set_job(SimPlanScript.JOB_REST)
	assert_false(main.current_plan.science_gear_on, "Removing SCIENCE turns science_gear_on false")

	# Sick crew member forced to REST on next report update
	var sick_rep := _make_clean_report(2)
	sick_rep.crew_reports[0]["sick"] = true
	sick_rep.crew_reports[0]["sick_days"] = 2
	sick_rep.greenhouse_alive = false
	main.day_hud.update_from_report(sick_rep)
	assert_eq(main.day_hud.crew_cards[0].get_job(), SimPlanScript.JOB_REST, "Sick crew forced to REST")
	assert_eq(main.day_hud.crew_cards[2].get_job(), SimPlanScript.JOB_REST, "FARM falls back to REST when greenhouse dead")

	# Tutorial/popup deferral & one bubble per day
	Settings.tutorial_skipped = false
	Settings.tutorial_hud_done = false
	main._reset_bubble_tracking()
	main._on_game_state_day_resolved(_make_clean_report(3))
	main._on_game_state_day_resolved(_make_clean_report(3)) # Duplicate call for same day ignored
	main.tutorial_overlay.show_step(2)
	main._maybe_show_pending_bubble()
	assert_false(main.speech_bubble.is_showing(), "Bubble waits while tutorial is open")
	main.tutorial_overlay.hide_overlay()
	main._on_tutorial_finished()
	assert_true(main.speech_bubble.is_showing(), "Bubble shows once tutorial closes")

	root.remove_child(main)
	main.free()

	Settings.current_mission_id = prev_mission
	Settings.tutorial_hud_done = prev_tut_hud
	Settings.tutorial_pack_done = prev_tut_pack
	Settings.tutorial_skipped = prev_tut_skip

func test_m2_recycler_and_m4_day16_dark_bubble() -> void:
	var prev_mission: String = Settings.current_mission_id
	var prev_tut_hud: bool = Settings.tutorial_hud_done
	var prev_tut_pack: bool = Settings.tutorial_pack_done
	var prev_tut_skip: bool = Settings.tutorial_skipped
	var prev_hint_broken: bool = Settings.hint_broken_shown
	var prev_hint_co2: bool = Settings.hint_co2_yellow_shown
	var prev_hint_bat: bool = Settings.hint_battery_low_shown

	Settings.tutorial_skipped = true
	Settings.tutorial_hud_done = true
	Settings.tutorial_pack_done = true
	Settings.hint_broken_shown = false
	Settings.hint_co2_yellow_shown = false
	Settings.hint_battery_low_shown = false

	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()

	# 1. M2: recycler breaks on Day 4 -> hint opens first, then CREW_SAY_BROKEN shows on close
	Settings.current_mission_id = "M2"
	main._on_mission_selected("M2")
	var m2_cargo := SimCargoScript.new(main._get_sim_missions().get_sim_constants("M2"))
	m2_cargo.set_count("solar", 10)
	m2_cargo.set_count("battery", 2)
	m2_cargo.set_count("o2", 2)
	m2_cargo.set_count("water", 2)
	m2_cargo.set_count("food", 4)
	main._on_pack_launch_requested(m2_cargo)
	main._on_landing_completed()

	for _d in range(4):
		main._on_end_day_pressed()
		main._on_resolve_completed()

	assert_true(GameState.current_mission.life.recycler_broken, "M2 Day 4 broke recycler")
	assert_true(main.event_popup.visible, "M2 Day 4 opens recycler alert card first")
	assert_false(main.tutorial_overlay.visible, "Broken onboarding hint suppressed when recycler card opens")
	assert_false(main.speech_bubble.is_showing(), "Bubble waits while recycler alert card is open")
	while main.event_popup.visible:
		main.event_popup.select_choice(0)
	while main.tutorial_overlay.visible:
		main.tutorial_overlay._on_primary_pressed()
	assert_true(main.speech_bubble.is_showing(), "M2 recycler broken bubble shown after alert card closes")
	assert_eq(main.speech_bubble.text_label.text, SpeechBubbleScript.translate_line("CREW_SAY_BROKEN"), "M2 shows CREW_SAY_BROKEN")

	# Repair with Crew 2 (Leo) -> Day 5 resolves -> CREW_SAY_FIXED over Crew 2
	main.day_hud.crew_cards[2].set_job(SimPlanScript.JOB_REPAIR)
	main._on_end_day_pressed()
	main._on_resolve_completed()
	while main.tutorial_overlay.visible:
		main.tutorial_overlay._on_primary_pressed()
	assert_false(GameState.current_mission.life.recycler_broken, "M2 recycler fixed on Day 5")
	assert_true(main.speech_bubble.is_showing(), "M2 fixed bubble shown")
	assert_eq(main.speech_bubble.text_label.text, SpeechBubbleScript.translate_line("CREW_SAY_FIXED"), "M2 shows CREW_SAY_FIXED")
	assert_eq(main.speech_bubble._crew_index, 2, "M2 fixed bubble targets Leo (repairer)")

	# 2. M4: run cleanly to Day 16 -> CREW_SAY_DARK
	Settings.current_mission_id = "M4"
	main._on_mission_selected("M4")
	var m4_cargo := SimCargoScript.new(Constants.sim)
	m4_cargo.set_count("solar", 20)
	m4_cargo.set_count("battery", 4)
	m4_cargo.set_count("reactor", 2)
	m4_cargo.set_count("o2", 2)
	m4_cargo.set_count("water", 6)
	m4_cargo.set_count("food", 5)
	m4_cargo.set_count("shield", 10)
	main._on_pack_launch_requested(m4_cargo)
	GameState.current_mission.events.storm_day = 99
	GameState.current_mission.events.recycler_day = 99
	GameState.current_mission.events.meteoroid_day = 99
	main._on_landing_completed()

	for _d in range(16):
		while main.event_popup.visible:
			main.event_popup.close()
		while main.tutorial_overlay.visible:
			main.tutorial_overlay._on_primary_pressed()
		main._on_end_day_pressed()
		main._on_resolve_completed()

	while main.event_popup.visible:
		main.event_popup.close()
	while main.tutorial_overlay.visible:
		main.tutorial_overlay._on_primary_pressed()

	assert_eq(GameState.current_mission.day, 17, "M4 completed Day 16")
	assert_true(main.speech_bubble.is_showing(), "M4 Day 16 dark bubble shown")
	assert_eq(main.speech_bubble.text_label.text, SpeechBubbleScript.translate_line("CREW_SAY_DARK"), "M4 shows CREW_SAY_DARK after sunset")

	root.remove_child(main)
	main.free()

	Settings.current_mission_id = prev_mission
	Settings.tutorial_hud_done = prev_tut_hud
	Settings.tutorial_pack_done = prev_tut_pack
	Settings.tutorial_skipped = prev_tut_skip
	Settings.hint_broken_shown = prev_hint_broken
	Settings.hint_co2_yellow_shown = prev_hint_co2
	Settings.hint_battery_low_shown = prev_hint_bat


