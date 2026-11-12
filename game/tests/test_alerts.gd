extends RefCounted

var failures: Array[String] = []

const MainScene := preload("res://scenes/Main.tscn")
const EventPopupScene := preload("res://ui/EventPopup.tscn")
const EventPopupScript := preload("res://ui/event_popup.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")

func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)

func assert_false(cond: bool, msg: String) -> void:
	if cond:
		failures.append(msg)

func assert_eq(a, b, msg: String) -> void:
	if a != b:
		failures.append("%s (expected %s, got %s)" % [msg, str(b), str(a)])

func _save_settings() -> Dictionary:
	return {
		"mission_id": Settings.current_mission_id,
		"free_play": Settings.free_play,
		"fast_mode": Settings.fast_mode,
		"pack_tut": Settings.tutorial_pack_done,
		"hud_tut": Settings.tutorial_hud_done,
		"bat_hint": Settings.hint_battery_low_shown,
		"broken_hint": Settings.hint_broken_shown,
		"co2_hint": Settings.hint_co2_yellow_shown,
		"collect_hint": Settings.hint_collect_shown,
		"stars": Settings.mission_stars.duplicate(),
		"last_cargo": GameState.last_cargo,
	}

func _restore_settings(saved: Dictionary) -> void:
	GameState.current_mission = null
	GameState.last_cargo = saved["last_cargo"]
	Settings.current_mission_id = saved["mission_id"]
	Settings.free_play = saved["free_play"]
	Settings.fast_mode = saved["fast_mode"]
	Settings.tutorial_pack_done = saved["pack_tut"]
	Settings.tutorial_hud_done = saved["hud_tut"]
	Settings.hint_battery_low_shown = saved["bat_hint"]
	Settings.hint_broken_shown = saved["broken_hint"]
	Settings.hint_co2_yellow_shown = saved["co2_hint"]
	Settings.hint_collect_shown = saved["collect_hint"]
	Settings.mission_stars = saved["stars"]

func _setup_main(mission_id: String, cargo_dict: Dictionary) -> Node:
	Settings.current_mission_id = mission_id
	Settings.free_play = true
	Settings.tutorial_pack_done = true
	Settings.tutorial_hud_done = true
	Settings.hint_battery_low_shown = true
	Settings.hint_broken_shown = false
	Settings.hint_co2_yellow_shown = true
	Settings.hint_collect_shown = true
	var root := (Engine.get_main_loop() as SceneTree).root
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()
	if main.event_popup != null and main.event_popup.has_method("_ensure_nodes"):
		main.event_popup._ensure_nodes()
	var cargo := SimCargoScript.new(Constants.sim)
	cargo.load_dict(cargo_dict)
	main._on_pack_launch_requested(cargo)
	main._on_landing_completed()
	return main

func _cleanup_main(main: Node) -> void:
	if main != null and is_instance_valid(main):
		var p := main.get_parent()
		if p != null:
			p.remove_child(main)
		main.free()

func test_popup_alert_layout_tones_and_legacy_compat() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	var popup = EventPopupScene.instantiate()
	root.add_child(popup)
	var warn_icon := load("res://assets/icons/warning.svg") as Texture2D

	popup.popup_alert(
		warn_icon,
		"ALERT_METEOR_TITLE",
		"ALERT_METEOR_BODY",
		"danger",
		["POPUP_OK"],
		{"bar_value": 12.0, "bar_max": 250.0, "source_id": "RAD_SPE_LIMIT_MSV"}
	)
	assert_true(popup.visible, "Alert card opens visible")
	assert_true(popup.tone_ribbon.visible, "Alert card shows top ribbon")
	assert_eq(popup.tone_ribbon.color, EventPopupScript.COLOR_DANGER, "Danger ribbon is red #E04848")
	assert_true(popup.icon_rect.custom_minimum_size.x >= 48.0, "Alert card uses big icon")
	assert_eq(popup.title_label.max_lines_visible, 1, "Alert title capped to 1 line")
	assert_eq(popup.message_label.max_lines_visible, 1, "Alert body capped to 1 line")
	assert_true(popup.alert_bar.visible, "Alert comparison bar shown")
	assert_eq(popup.alert_bar.max_value, 250.0, "Alert bar max set")
	assert_eq(popup.alert_bar.value, 12.0, "Alert bar value set")
	assert_true(popup.source_tag.visible, "SourceTag shown on alert card")
	assert_eq(popup.source_tag.constant_id, "RAD_SPE_LIMIT_MSV", "SourceTag constant_id matches")
	assert_true(popup.source_tag.popover_layer.layer > popup.layer, "SourceTag popover draws above alert popup")

	popup.popup_alert(warn_icon, "ALERT_NIGHT_TITLE", "ALERT_NIGHT_BODY", "warn", ["POPUP_OK"])
	assert_eq(popup.tone_ribbon.color, EventPopupScript.COLOR_WARN, "Warn ribbon uses amber #F2C14E")

	popup.popup_alert(warn_icon, "ALERT_STORM_SAFE_TITLE", "ALERT_STORM_SAFE_BODY", "safe", ["POPUP_OK"])
	assert_eq(popup.tone_ribbon.color, EventPopupScript.COLOR_SAFE, "Safe ribbon uses green #44B35A")

	popup.popup_alert(
		warn_icon,
		"ALERT_STORM_TITLE",
		"60 min to impact",
		"danger",
		["EVT_CHOICE_SHELTER"],
		{"countdown_start": 60.0, "countdown_sec": EventPopupScript.STORM_COUNTDOWN_SEC, "countdown_template": "{min} min to impact"}
	)
	popup._process(1.5)
	assert_true(popup.is_countdown_active(), "Normal 3.0s storm countdown still active at 1.5s")
	assert_eq(popup.button_box.get_child_count(), 0, "Normal countdown hides button before 3.0s")
	popup._process(1.6)
	assert_false(popup.is_countdown_active(), "Normal 3.0s storm countdown completes after 3.1s")
	assert_eq(popup.button_box.get_child_count(), 1, "Normal countdown reveals shelter button at 0")

	var picked := [-1]
	popup.choice_selected.connect(func(idx: int): picked[0] = idx)
	popup.popup_event("EVT_STORM_TITLE", "Legacy event body", ["POPUP_OK"])
	assert_false(popup.tone_ribbon.visible, "Legacy popup_event hides alert ribbon")
	assert_false(popup.alert_bar.visible, "Legacy popup_event hides alert bar")
	assert_false(popup.source_tag.visible, "Legacy popup_event hides SourceTag")
	assert_eq(popup.icon_rect.modulate, Color.WHITE, "Legacy popup_event resets icon modulate")
	popup.select_choice(0)
	assert_eq(picked[0], 0, "Legacy popup_event preserves choice_selected signal")

	root.remove_child(popup)
	popup.free()

func test_storm_warning_countdown_fast_and_auto_end_with_safe_card() -> void:
	var saved := _save_settings()
	Settings.fast_mode = true
	var main := _setup_main("M3", {"solar": 12, "battery": 3, "reactor": 0, "o2": 3, "water": 8, "food": 4, "shield": 10})
	GameState.current_mission.events.storm_day = 2
	GameState.current_mission.events.meteoroid_day = 99
	GameState.current_mission.events.recycler_day = 99

	main._on_end_day_pressed()
	main._on_resolve_completed()

	assert_eq(GameState.current_mission.day, 2, "Advanced to storm Day 2")
	assert_true(main.event_popup.visible, "Storm alert card opens at start of storm day")
	assert_eq(main.event_popup.title_label.text, TranslationServer.translate("ALERT_STORM_TITLE"), "Shows storm title")
	assert_eq(main.event_popup.tone_ribbon.color, EventPopupScript.COLOR_DANGER, "Storm warning is danger tone")
	assert_true(main.event_popup.is_countdown_active(), "Storm countdown is running")
	assert_eq(main.event_popup.button_box.get_child_count(), 0, "Shelter button hidden before countdown finishes")
	assert_true(main.event_popup.message_label.text.contains("60"), "Countdown starts from SPE_WARNING_TYPICAL_MIN")
	var base = main.world.get_node_or_null("Base")
	assert_true(base != null and base.is_shelter_door_light_on(), "Shelter door light turns on during storm alert")

	main.event_popup._process(0.5)
	assert_true(main.event_popup.is_countdown_active(), "Fast mode 1.0s countdown still active at 0.5s")
	assert_eq(main.event_popup.button_box.get_child_count(), 0, "Button still hidden mid-countdown")
	main.event_popup._process(0.6)
	assert_false(main.event_popup.is_countdown_active(), "Countdown stops at 0")
	assert_eq(main.event_popup.button_box.get_child_count(), 1, "EVT_CHOICE_SHELTER appears at 0")
	assert_eq((main.event_popup.button_box.get_child(0) as Button).text, TranslationServer.translate("EVT_CHOICE_SHELTER"), "Shelter button text matches")

	main.event_popup.select_choice(0)
	assert_eq(main.current_state, main.State.RESOLVE_DAY, "Pressing Shelter ends the storm day automatically")
	assert_eq(main.current_plan.get_job(0), "REST", "Crew job assigned to REST in shelter")

	main._on_resolve_completed()
	assert_false(GameState.current_mission.ended, "Shield 10 survives M3 storm")
	assert_false(main.day_hud.toast_panel.visible, "Duplicate HUD toast skipped when storm result card opens")
	assert_true(main.event_popup.visible, "Safe storm result card opens after resolve")
	assert_eq(main.event_popup.title_label.text, TranslationServer.translate("ALERT_STORM_SAFE_TITLE"), "Shows safe title")
	assert_eq(main.event_popup.tone_ribbon.color, EventPopupScript.COLOR_SAFE, "Result card uses safe tone")
	assert_true(main.event_popup.alert_bar.visible, "Dose vs limit comparison bar visible")
	assert_true(main.event_popup.source_tag.visible, "Result card shows SourceTag")
	assert_eq(main.event_popup.source_tag.constant_id, "RAD_SPE_LIMIT_MSV", "Result card cites RAD_SPE_LIMIT_MSV")
	assert_true(main.event_popup.message_label.text.contains("250"), "Result body shows rounded limit")

	_cleanup_main(main)
	_restore_settings(saved)

func test_storm_evacuation_skips_result_card() -> void:
	var saved := _save_settings()
	Settings.fast_mode = true
	var main := _setup_main("M3", {"solar": 12, "battery": 3, "reactor": 0, "o2": 3, "water": 8, "food": 4, "shield": 0})
	GameState.current_mission.events.storm_day = 2
	GameState.current_mission.events.meteoroid_day = 99
	GameState.current_mission.events.recycler_day = 99

	main._on_end_day_pressed()
	main._on_resolve_completed()
	main.event_popup.finish_countdown_now()
	main.event_popup.select_choice(0)
	main._on_resolve_completed()

	assert_true(GameState.current_mission.ended, "Shield 0 storm evacuates crew")
	assert_eq(GameState.current_mission.result.outcome, "EVAC_RADIATION", "Outcome is EVAC_RADIATION")
	assert_false(main.event_popup.visible, "No result card shown on storm evacuation")
	assert_true(main.pending_popups.is_empty(), "No pending result cards after evacuation")

	_cleanup_main(main)
	_restore_settings(saved)

func test_meteoroid_and_recycler_cards_toast_skip_and_stacking() -> void:
	var saved := _save_settings()
	Settings.fast_mode = true
	var main := _setup_main("M4", {"solar": 20, "battery": 4, "reactor": 2, "o2": 4, "water": 10, "food": 6, "shield": 10})
	GameState.current_mission.events.storm_day = 99
	GameState.current_mission.events.meteoroid_day = 2
	GameState.current_mission.events.recycler_day = 2

	main._on_end_day_pressed()
	main._on_resolve_completed()
	for i in range(4):
		main.current_plan.set_job(i, "REST")
	main._on_end_day_pressed()
	main._on_resolve_completed()

	assert_false(main.day_hud.toast_panel.visible, "HUD toast skipped when event result cards open")
	assert_true(Settings.hint_broken_shown, "RECYCLER_BROKE sets hint_broken_shown = true")
	assert_false(main.tutorial_overlay.visible, "Old broken onboarding hint suppressed")
	assert_true(main.event_popup.visible, "First queued card opens cleanly")
	assert_false(main.speech_bubble.is_showing(), "Speech bubble waits while stacked cards are open")

	var seen_titles: Array[String] = []
	while main.event_popup.visible:
		seen_titles.append(main.event_popup.title_label.text)
		assert_eq(main.event_popup.tone_ribbon.color, EventPopupScript.COLOR_DANGER, "Stacked incident cards are danger tone")
		main.event_popup.select_choice(0)
		if main.event_popup.visible:
			assert_false(main.speech_bubble.is_showing(), "Speech bubble still waits while second card is open")

	assert_true(seen_titles.has(TranslationServer.translate("ALERT_METEOR_TITLE")), "Meteoroid card shown in sequence")
	assert_true(seen_titles.has(TranslationServer.translate("ALERT_RECYCLER_TITLE")), "Recycler card shown in sequence")
	assert_true(main.speech_bubble.is_showing(), "Speech bubble opens only after all cards close")

	_cleanup_main(main)
	_restore_settings(saved)

func test_sunset_night_card_warn_safe_and_day15_only() -> void:
	var saved := _save_settings()
	Settings.fast_mode = true

	var m1 := _setup_main("M1", {"solar": 8, "battery": 2, "reactor": 0, "o2": 2, "water": 4, "food": 3, "shield": 0})
	var m1_saw_night := false
	for _d in range(5):
		if m1.event_popup.visible and m1.event_popup.title_label.text == TranslationServer.translate("ALERT_NIGHT_TITLE"):
			m1_saw_night = true
		if GameState.current_mission.ended:
			break
		m1._on_end_day_pressed()
		m1._on_resolve_completed()
	assert_false(m1_saw_night, "Short mission (M1) never shows sunset night card")
	_cleanup_main(m1)

	var m4_low := _setup_main("M4", {"solar": 20, "battery": 1, "reactor": 0, "o2": 4, "water": 10, "food": 6, "shield": 10})
	GameState.current_mission.events.storm_day = 99
	GameState.current_mission.events.meteoroid_day = 99
	GameState.current_mission.events.recycler_day = 99
	for _d in range(14):
		m4_low._on_end_day_pressed()
		m4_low._on_resolve_completed()
	assert_eq(GameState.current_mission.day, 15, "Low-power M4 reached SUNSET_DAY 15")
	assert_true(m4_low.event_popup.visible, "Sunset card opens on Day 15")
	assert_eq(m4_low.event_popup.title_label.text, TranslationServer.translate("ALERT_NIGHT_TITLE"), "Shows ALERT_NIGHT_TITLE")
	assert_eq(m4_low.event_popup.tone_ribbon.color, EventPopupScript.COLOR_WARN, "Underpowered night card uses warn tone")
	assert_true(m4_low.event_popup.alert_bar.visible, "Night energy card shows comparison bar")
	assert_eq(m4_low.event_popup.source_tag.constant_id, "NIGHT_HOURS", "Night card cites NIGHT_HOURS")
	_cleanup_main(m4_low)

	var m4_safe := _setup_main("M4", {"solar": 20, "battery": 4, "reactor": 2, "o2": 4, "water": 10, "food": 6, "shield": 10})
	GameState.current_mission.events.storm_day = 99
	GameState.current_mission.events.meteoroid_day = 99
	GameState.current_mission.events.recycler_day = 99
	for _d in range(14):
		m4_safe._on_end_day_pressed()
		m4_safe._on_resolve_completed()
	assert_eq(GameState.current_mission.day, 15, "Reactor M4 reached SUNSET_DAY 15")
	assert_true(m4_safe.event_popup.visible, "Safe sunset card opens on Day 15")
	assert_eq(m4_safe.event_popup.tone_ribbon.color, EventPopupScript.COLOR_SAFE, "Sufficient night power uses safe tone")
	_cleanup_main(m4_safe)

	_restore_settings(saved)
