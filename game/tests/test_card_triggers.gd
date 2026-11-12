extends "res://tests/test_case.gd"

const LearningDataScript := preload("res://ui/learning_data.gd")
const CardTriggersScript := preload("res://ui/card_triggers.gd")
const CardControllerScript := preload("res://ui/card_controller.gd")
const SimDayReportScript := preload("res://sim/sim_day_report.gd")
const CardViewScene := preload("res://ui/CardView.tscn")
const CardAlbumScene := preload("res://ui/CardAlbum.tscn")
const DebriefScreenScene := preload("res://ui/DebriefScreen.tscn")
const MainScene := preload("res://scenes/Main.tscn")
const SourcesScreenScene := preload("res://ui/SourcesScreen.tscn")
const MissionMapScene := preload("res://ui/MissionMap.tscn")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const TutorialOverlayScene := preload("res://ui/TutorialOverlay.tscn")
const DayHudScene := preload("res://ui/DayHud.tscn")


func _make_report(day_num: int, overrides: Dictionary = {}) -> RefCounted:
	var r := SimDayReportScript.new()
	r.day = day_num
	r.sun_factor = float(overrides.get("sun_factor", 1.0))
	r.reactor_kwh = float(overrides.get("reactor_kwh", 0.0))
	r.battery_percent = float(overrides.get("battery_percent", 100.0))
	r.dust = float(overrides.get("dust", 0.05))
	r.shelter_g_cm2 = float(overrides.get("shelter_g_cm2", 0.0))
	r.science_points = int(overrides.get("science_points", 0))
	r.greenhouse_alive = bool(overrides.get("greenhouse_alive", false))
	r.events = overrides.get("events", [])
	for cr in overrides.get("crew_reports", []):
		r.crew_reports.append(cr)
	return r


func test_cards_facts_and_sources_md_match() -> void:
	var ld := LearningDataScript.new()
	var cards: Array = ld.cards()
	var facts: Array = ld.all_facts()
	assert_eq(cards.size(), 29, "learning.json defines all 29 science cards")
	assert_eq(facts.size(), 29, "facts.json defines all 29 facts")

	var seen_ids: Dictionary = {}
	for entry in cards:
		assert_true(entry is Dictionary, "Card entry is Dictionary")
		var c: Dictionary = entry
		var fid: String = str(c.get("fact_id", ""))
		assert_false(fid.is_empty(), "Card has fact_id")
		assert_false(seen_ids.has(fid), "Unique card for fact_id %s" % fid)
		seen_ids[fid] = true

		var title_en: String = str(c.get("title", {}).get("en", ""))
		assert_false(title_en.is_empty(), "Card %s has EN title" % fid)
		var cat: String = str(c.get("category", ""))
		assert_true(cat in ["moon", "survival", "nasa"], "Card %s valid category %s" % [fid, cat])
		var trig: String = str(c.get("trigger", ""))
		assert_false(trig.is_empty(), "Card %s has trigger" % fid)
		var hint_en: String = str(c.get("hint", {}).get("en", ""))
		assert_false(hint_en.is_empty(), "Card %s has EN hint" % fid)

		var f: Dictionary = ld.fact(fid)
		assert_false(f.is_empty(), "Fact %s exists for card" % fid)
		assert_false(str(f.get("en", "")).is_empty(), "Fact %s has EN text" % fid)
		assert_false(str(f.get("source", "")).is_empty(), "Fact %s has source" % fid)
		assert_false(str(f.get("link", "")).is_empty(), "Fact %s has link" % fid)

	var md_path: String = ProjectSettings.globalize_path("res://").path_join("../data/sources.md")
	var md_text: String = FileAccess.get_file_as_string(md_path)
	assert_true(md_text.contains("## Facts and Science Cards"), "sources.md has Facts and Science Cards heading")
	for entry in cards:
		var c: Dictionary = entry
		var fid: String = str(c.get("fact_id", ""))
		var f: Dictionary = ld.fact(fid)
		assert_true(md_text.contains(str(c.get("title", {}).get("en", ""))), "sources.md lists card %s title" % fid)
		assert_true(md_text.contains(str(f.get("source", ""))), "sources.md lists card %s source" % fid)
		assert_true(md_text.contains(str(f.get("link", ""))), "sources.md lists card %s link" % fid)


func test_every_gameplay_trigger_fires_once_from_report_changes() -> void:
	Settings.reset_training()
	var ct := CardTriggersScript.new()

	# 1. landed (Day 1)
	var d1 := _make_report(1)
	var res1: Array[String] = ct.evaluate(null, d1, ["REST", "REST", "REST", "REST"], {"collected_cards": []})
	assert_true(res1.has("F12"), "Day 1 report triggers landed card F12")
	var res1_repeat: Array[String] = ct.evaluate(null, d1, [], {"collected_cards": ["F12"]})
	assert_false(res1_repeat.has("F12"), "Already collected landed card skips re-trigger")

	# 2. first_outside_job + first_regolith
	var d2 := _make_report(2, {"shelter_g_cm2": 7.5})
	var d1_base := _make_report(1, {"shelter_g_cm2": 5.0})
	var res_reg: Array[String] = ct.evaluate(d1_base, d2, ["REGOLITH", "REST", "REST", "REST"], {"collected_cards": ["F12"]})
	assert_true(res_reg.has("F10"), "Outside job REGOLITH triggers F10")
	assert_true(res_reg.has("F23"), "Increasing shelter_g_cm2 triggers F23")

	# Storm day does not trigger outside job even if plan had jobs
	var d_storm_outside := _make_report(4, {"events": ["STORM"]})
	var res_storm_out: Array[String] = ct.evaluate(d2, d_storm_outside, ["REGOLITH"], {"collected_cards": ["F12", "F23"]})
	assert_false(res_storm_out.has("F10"), "Storm day does not fire first_outside_job")

	# 3. science thresholds [1,3,6,10,15] across single and multi-mission totals
	var d_sci1 := _make_report(2, {"science_points": 1})
	assert_true(ct.evaluate(d1_base, d_sci1, ["SCIENCE"], {"collected_cards": ["F12", "F10"]}).has("F21"), "Science 1 triggers F21")
	var d_sci3 := _make_report(2, {"science_points": 1})
	var res_sci_cross: Array[String] = ct.evaluate(d1_base, d_sci3, ["SCIENCE"], {
		"collected_cards": ["F12", "F10", "F21"],
		"prior_session_science": 2,
	})
	assert_true(res_sci_cross.has("F17"), "Session science 2+1=3 triggers F17")
	assert_true(ct.evaluate(d1_base, _make_report(5, {"science_points": 6}), ["SCIENCE"], {"collected_cards": ["F12", "F10", "F21", "F17"]}).has("F20"), "Science 6 triggers F20")
	assert_true(ct.evaluate(d1_base, _make_report(8, {"science_points": 4}), ["SCIENCE"], {"collected_cards": ["F12", "F10", "F21", "F17", "F20"], "prior_session_science": 6}).has("F18"), "Science 10 triggers F18")
	assert_true(ct.evaluate(d1_base, _make_report(12, {"science_points": 5}), ["SCIENCE"], {"collected_cards": ["F12", "F10", "F21", "F17", "F20", "F18"], "prior_session_science": 10}).has("F19"), "Science 15 triggers F19")

	# 4. dusty & first_clean
	var d_not_dusty := _make_report(3, {"dust": 0.14})
	assert_false(ct.evaluate(d1_base, d_not_dusty, [], {"collected_cards": ["F12"]}).has("F15"), "Dust 0.14 does not fire dusty card")
	var d_dusty := _make_report(4, {"dust": 0.15})
	assert_true(ct.evaluate(d_not_dusty, d_dusty, [], {"collected_cards": ["F12"]}).has("F15"), "Dust >= 0.15 triggers F15")
	var d_cleaned := _make_report(5, {"dust": 0.05})
	var res_clean: Array[String] = ct.evaluate(d_dusty, d_cleaned, ["CLEAN", "REST", "REST", "REST"], {"collected_cards": ["F12", "F10", "F15"]})
	assert_true(res_clean.has("F04"), "CLEAN reducing dust triggers F04")

	# 5. meteoroid & recycler_broke
	assert_true(ct.evaluate(d1_base, _make_report(6, {"events": ["METEOROID"]}), [], {"collected_cards": ["F12"]}).has("F16"), "METEOROID event triggers F16")
	assert_true(ct.evaluate(d1_base, _make_report(7, {"events": ["RECYCLER_BROKE"]}), [], {"collected_cards": ["F12"]}).has("F06"), "RECYCLER_BROKE event triggers F06")

	# 6. storm_warning & storm_survived
	assert_true(ct.evaluate_day_start(9, ["STORM_WARNING"], {"collected_cards": ["F12"]}).has("F11"), "STORM_WARNING triggers F11")
	var res_storm_ok: Array[String] = ct.evaluate(d1_base, _make_report(9, {"events": ["STORM"]}), [], {"collected_cards": ["F12"], "mission_ended": false})
	assert_true(res_storm_ok.has("F09"), "Survived STORM triggers F09")
	var res_storm_evac: Array[String] = ct.evaluate(d1_base, _make_report(9, {"events": ["STORM", "EVAC_RADIATION"]}), [], {"collected_cards": ["F12"], "mission_ended": true})
	assert_false(res_storm_evac.has("F09"), "Ended mission STORM does not trigger F09")

	# 7. sunset
	var sunset_day: int = int(Constants.v("SUNSET_DAY"))
	assert_true(ct.evaluate_day_start(sunset_day, ["SUNSET"], {"collected_cards": ["F12"], "sunset_day": sunset_day}).has("F01"), "Sunset day start triggers F01")

	# 8. night_reactor & night_battery_low
	var d_night_reac := _make_report(16, {"sun_factor": 0.0, "reactor_kwh": 240.0, "battery_percent": 100.0})
	assert_true(ct.evaluate(d1_base, d_night_reac, [], {"collected_cards": ["F12"]}).has("F25"), "Night with reactor triggers F25")
	assert_false(ct.evaluate(d1_base, d_night_reac, [], {"collected_cards": ["F12", "F25"]}).has("F26"), "Night with reactor does not trigger low battery F26")
	var d_night_low := _make_report(16, {"sun_factor": 0.0, "reactor_kwh": 0.0, "battery_percent": 29.0})
	assert_true(ct.evaluate(d1_base, d_night_low, [], {"collected_cards": ["F12"]}).has("F26"), "Night without reactor & battery < 30 triggers F26")

	# 9. first_farm & crew_tired
	var d_farm := _make_report(6, {"greenhouse_alive": true})
	assert_true(ct.evaluate(d1_base, d_farm, ["FARM", "REST", "REST", "REST"], {"collected_cards": ["F12"]}).has("F07"), "FARM on living greenhouse triggers F07")
	var d_farm_dead := _make_report(6, {"greenhouse_alive": false})
	assert_false(ct.evaluate(d1_base, d_farm_dead, ["FARM", "REST", "REST", "REST"], {"collected_cards": ["F12"]}).has("F07"), "FARM on dead greenhouse skips F07")
	var d_tired := _make_report(4, {"crew_reports": [{"energy": 2}, {"energy": 0}, {"energy": 1}, {"energy": 3}]})
	assert_true(ct.evaluate(d1_base, d_tired, [], {"collected_cards": ["F12"]}).has("F29"), "Crew energy == 0 triggers F29")


func test_quiet_day_every_second_day_pool_order() -> void:
	var ct := CardTriggersScript.new()
	var collected: Array[String] = ["F12"]  # landed already collected
	var q_count: int = 0

	# Quiet day 1 -> counter 1, no card
	var q1 := ct.evaluate_day(_make_report(1), _make_report(2), ["REST"], {"collected_cards": collected, "quiet_day_counter": q_count})
	q_count = int(q1["quiet_day_counter"])
	assert_eq(q_count, 1, "1st quiet day increments counter to 1")
	assert_eq(str(q1["quiet_card_id"]), "", "1st quiet day does not fire chip")

	# Alert day does not increment quiet counter or emit quiet card
	var qa := ct.evaluate_day(_make_report(2), _make_report(3), ["REST"], {"collected_cards": collected, "quiet_day_counter": q_count, "had_m04_alert": true})
	assert_eq(int(qa["quiet_day_counter"]), 1, "Alert day does not increment quiet day counter")
	assert_eq(str(qa["quiet_card_id"]), "", "Alert day emits no quiet card")

	# Quiet day 2 -> counter 2 -> picks F13
	var q2 := ct.evaluate_day(_make_report(3), _make_report(4), ["REST"], {"collected_cards": collected, "quiet_day_counter": q_count})
	q_count = int(q2["quiet_day_counter"])
	assert_eq(q_count, 2, "2nd quiet day increments counter to 2")
	assert_eq(str(q2["quiet_card_id"]), "F13", "2nd quiet day picks 1st quiet_day_pool entry F13")
	collected.append("F13")

	# Quiet day 3 -> none
	var q3 := ct.evaluate_day(_make_report(4), _make_report(5), ["REST"], {"collected_cards": collected, "quiet_day_counter": q_count})
	q_count = int(q3["quiet_day_counter"])
	assert_eq(str(q3["quiet_card_id"]), "", "3rd quiet day emits no card")

	# Quiet day 4 -> picks F03
	var q4 := ct.evaluate_day(_make_report(5), _make_report(6), ["REST"], {"collected_cards": collected, "quiet_day_counter": q_count})
	assert_eq(str(q4["quiet_card_id"]), "F03", "4th quiet day picks 2nd quiet_day_pool entry F03")


func test_controller_max_two_toasts_per_day_and_overflow_rollover() -> void:
	Settings.reset_training()
	var ctrl := CardControllerScript.new()
	ctrl.reset_mission(5.0, 0.05)

	# Day 1 resolves with 4 triggered cards at once: landed(F12), outside(F10), regolith(F23), sci1(F21)
	var d1 := _make_report(1, {"shelter_g_cm2": 7.5, "science_points": 1})
	ctrl.on_day_resolved(d1, ["REGOLITH", "SCIENCE", "REST", "REST"], {})

	assert_true(Settings.collected_cards.has("F12"), "Controller collected F12 immediately")
	assert_true(Settings.collected_cards.has("F10"), "Controller collected F10 immediately")
	assert_true(Settings.collected_cards.has("F23"), "Controller collected F23 immediately")
	assert_true(Settings.collected_cards.has("F21"), "Controller collected F21 immediately")
	assert_eq(ctrl.pending_toast_count(), 4, "All 4 queued for toast")

	# Day 2 starts: max 2 toasts allowed today
	ctrl.on_day_started(2, [])
	var n1: Dictionary = ctrl.pop_next_notification()
	var n2: Dictionary = ctrl.pop_next_notification()
	var n3: Dictionary = ctrl.pop_next_notification()
	assert_eq(str(n1.get("kind", "")), "toast", "1st popup is toast")
	assert_eq(str(n2.get("kind", "")), "toast", "2nd popup is toast")
	assert_true(n3.is_empty(), "3rd popup deferred cleanly due to 2-per-day cap")
	assert_eq(ctrl.pending_toast_count(), 2, "Remaining 2 cards wait for next planning day")

	# Day 3 starts: next 2 overflow cards toast
	ctrl.on_day_started(3, [])
	var n4: Dictionary = ctrl.pop_next_notification()
	var n5: Dictionary = ctrl.pop_next_notification()
	assert_false(n4.is_empty(), "3rd card toasts on Day 3")
	assert_false(n5.is_empty(), "4th card toasts on Day 3")
	assert_eq(ctrl.pending_toast_count(), 0, "Overflow queue drained cleanly")


func test_card_view_album_and_debrief_integration() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.root if tree != null else null
	assert_true(root != null, "SceneTree root available")

	Settings.reset_training()
	Settings.language = "en"
	Settings.begin_mission_cards()
	Settings.collect_card("F05")  # M1 briefing card
	Settings.collect_card("F25")  # NASA reactor card

	# CardView check
	var cv := CardViewScene.instantiate()
	root.add_child(cv)
	cv._ready()
	cv.open_card("F25")
	assert_true(cv.visible, "CardView visible when opened")
	assert_eq(cv.title_label.text, "A Moon Reactor", "CardView displays card title")
	assert_true(cv.fact_label.text.contains("nuclear reactor"), "CardView displays fact text")
	assert_true(cv.source_tag.visible, "CardView displays SourceTag")
	assert_true(cv.album_hint_label != null and cv.album_hint_label.visible and cv.album_hint_label.text.contains("Album"), "CardView displays album storage reassurance")
	cv.close_card()
	assert_false(cv.visible, "CardView closes cleanly")
	cv.free()

	# CardAlbum tabs + grid count
	var album := CardAlbumScene.instantiate()
	root.add_child(album)
	album._ready()
	album.open_album("all")
	assert_eq(album.cards_grid.get_child_count(), 29, "All tab renders all 29 card tiles")
	assert_true(album.count_label.text.contains("2/29"), "Album header shows collected count 2/29")
	var unlocked_btn := album.cards_grid.get_node_or_null("Tile_F25") as Button
	var locked_btn := album.cards_grid.get_node_or_null("Tile_F01") as Button
	assert_true(unlocked_btn != null and not unlocked_btn.disabled, "Collected card tile is tappable")
	assert_true(locked_btn != null and locked_btn.disabled, "Uncollected card tile is locked")
	album.set_category("nasa")
	assert_true(album.cards_grid.get_child_count() > 0 and album.cards_grid.get_child_count() < 29, "NASA category filters tiles")
	album.close_album()
	album.free()

	# Debrief collects fact_panel card & shows New cards this mission including briefing + nasa_now_fact
	var debrief := DebriefScreenScene.instantiate()
	root.add_child(debrief)
	debrief._ready()
	Settings.current_mission_id = "M1"
	debrief.show_result_with_next({
		"mission_id": "M1",
		"outcome": "SURVIVED",
		"stars": 2,
		"end_day": 5,
		"total_days": 5,
	}, 42, true)
	debrief.advance_step()
	debrief.select_after_answer(1)
	debrief.advance_step()
	debrief.advance_step()  # NASA_NOW (collects F27)
	debrief.advance_step()  # RANK_UP (final)
	assert_true(debrief.new_cards_button.visible, "Debrief new cards row visible on final step")
	assert_true(Settings.mission_collected_cards.has("F05"), "Mission cards include M1 briefing card F05")
	assert_true(Settings.mission_collected_cards.has("F27"), "Mission cards include M1 NASA now card F27")
	assert_true(debrief.new_cards_label.text.contains(str(Settings.mission_collected_cards.size())), "Debrief new cards label shows exact mission count")
	debrief.free()


func test_main_m4_playthrough_and_screens() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.root if tree != null else null
	assert_true(root != null, "SceneTree root available")

	var saved_mission: String = Settings.current_mission_id
	var saved_free: bool = Settings.free_play
	var saved_stars: Dictionary = Settings.mission_stars.duplicate()
	var saved_lang: String = Settings.language
	var saved_last_cargo: RefCounted = GameState.last_cargo

	Settings.reset_training()
	Settings.free_play = true
	Settings.language = "en"
	Settings.tutorial_pack_done = true
	Settings.tutorial_hud_done = true
	Settings.hint_battery_low_shown = true
	Settings.hint_broken_shown = true
	Settings.hint_co2_yellow_shown = true
	Settings.hint_collect_shown = true

	# 1. MissionMap CardsButton updates with collection count
	var mm := MissionMapScene.instantiate()
	root.add_child(mm)
	mm._ready()
	Settings.collect_card("F05")
	mm._refresh()
	assert_true(mm._cards_btn != null and mm._cards_btn.visible, "MissionMap shows Cards button")
	assert_true(mm._cards_btn.text.contains("1/29"), "MissionMap Cards button displays collected count")
	mm.open_cards()
	assert_true(mm._card_album != null and mm._card_album.visible, "MissionMap opens CardAlbum")
	mm.close_cards()
	mm.free()

	# 2. CardAlbum responsive portrait (3 cols) vs landscape (5 cols)
	var album := CardAlbumScene.instantiate()
	root.add_child(album)
	album._ready()
	var win := root as Window
	var orig_size: Vector2i = win.size if win != null else Vector2i(1280, 720)
	if win != null:
		win.size = Vector2i(390, 844)
	album.open_album("all")
	if win != null and root.get_visible_rect().size.y > root.get_visible_rect().size.x:
		assert_eq(album.cards_grid.columns, 3, "CardAlbum uses 3 columns in portrait")
	if win != null:
		win.size = Vector2i(1280, 720)
	album._update_layout()
	assert_eq(album.cards_grid.columns, 5, "CardAlbum uses 5 columns in landscape")
	if win != null:
		win.size = orig_size
	album.close_album()
	album.free()

	# 3. SourcesScreen FACTS filter shows all 29 science cards (and survives BN fallback)
	var src := SourcesScreenScene.instantiate()
	root.add_child(src)
	src._ready()
	var facts_idx: int = -1
	for i in range(src.system_option.item_count):
		if str(src.system_option.get_item_metadata(i)) == "FACTS":
			facts_idx = i
			break
	assert_true(facts_idx >= 0, "SourcesScreen includes FACTS filter option")
	src.system_option.select(facts_idx)
	src._on_system_selected(facts_idx)
	assert_eq(src.list_container.get_child_count(), 30, "SourcesScreen FACTS lists header + 29 card sources")
	Settings.language = "bn"
	src._on_language_changed("bn")
	assert_eq(src.list_container.get_child_count(), 30, "SourcesScreen FACTS stays intact in Bangla")
	Settings.language = "en"
	src.free()

	# 4. Full Main M4 flow with Reactor + Science + Regolith through lunar night Day 16
	Settings.reset_training()
	Settings.free_play = true
	Settings.tutorial_pack_done = true
	Settings.tutorial_hud_done = true
	Settings.hint_battery_low_shown = true
	Settings.hint_broken_shown = true
	Settings.hint_co2_yellow_shown = true
	Settings.hint_collect_shown = true

	var main := MainScene.instantiate()
	root.add_child(main)
	main._ready()
	main.mission_map._on_free_play_toggled(true)
	main.mission_map._on_mission_pressed("M4")
	main.mission_map._on_play_pressed()
	assert_eq(main.current_state, main.State.BRIEFING, "M4 enters BRIEFING")
	if main.mission_briefing.skip_button.visible:
		main.mission_briefing._on_skip_pressed()
	else:
		main.mission_briefing._on_next_pressed()
		main.mission_briefing._on_next_pressed()
		main.mission_briefing._on_option_pressed(0)
		main.mission_briefing._on_go_pressed()
	assert_eq(main.current_state, main.State.PACK, "M4 briefing enters PACK")

	var m4_cargo := SimCargoScript.new(Constants.sim)
	m4_cargo.load_dict({"solar": 20, "battery": 4, "reactor": 2, "o2": 2, "water": 6, "food": 5, "shield": 10})
	main._on_pack_launch_requested(m4_cargo)
	main._on_landing_completed()

	for _day_step in range(16):
		var cur = GameState.current_mission
		if cur == null or cur.ended:
			break
		if main.event_popup != null and main.event_popup.visible:
			main.event_popup.visible = false
		if main.tutorial_overlay != null and main.tutorial_overlay.visible:
			main.tutorial_overlay.visible = false
		main.current_plan.set_job(0, "SCIENCE")
		main.current_plan.set_job(1, "REGOLITH")
		if cur.life.recycler_broken or cur.power.broken_panels > 0:
			main.current_plan.set_job(2, "REPAIR")
		else:
			main.current_plan.set_job(2, "REST")
		main.current_plan.set_job(3, "REST")
		main._on_end_day_pressed()
		main._on_resolve_completed()

	# Dismiss any M4 Day 15 sunset alert / speech bubble and verify science card notifications fire
	if main.event_popup != null and main.event_popup.visible:
		main.event_popup.visible = false
	if main.speech_bubble != null and main.speech_bubble.visible:
		main.speech_bubble.hide_bubble()
	main._maybe_show_pending_card_notification()

	assert_true(Settings.collected_cards.has("F12"), "M4 unlocks landed card F12")
	assert_true(Settings.collected_cards.has("F23"), "M4 unlocks regolith card F23")
	assert_true(Settings.collected_cards.has("F21"), "M4 unlocks 1st science threshold F21")
	assert_true(Settings.collected_cards.has("F25"), "M4 reactor during lunar night unlocks F25")
	assert_true(main.day_hud != null and main.day_hud.end_day_button.visible, "End Day button remains visible during card notification")

	if main.get_parent() != null:
		main.get_parent().remove_child(main)
	main.free()

	GameState.current_mission = null
	GameState.last_cargo = saved_last_cargo
	Settings.reset_training()
	Settings.current_mission_id = saved_mission
	Settings.free_play = saved_free
	Settings.mission_stars = saved_stars
	Settings.language = saved_lang


func test_card_onboarding_tutorial_and_first_pickup() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.root if tree != null else null
	assert_true(root != null, "SceneTree root available")

	Settings.reset_onboarding()
	Settings.language = "en"

	# 1. TutorialOverlay "science_card" hint
	var tut := TutorialOverlayScene.instantiate()
	root.add_child(tut)
	tut._ready()
	tut.show_hint("science_card")
	assert_true(tut.visible, "TutorialOverlay shows science_card hint")
	assert_true(tut.title_label.text.contains("Science Cards"), "Title mentions Science Cards")
	assert_true(tut.body_label.text.contains("NASA"), "Body explains NASA discoveries & Album")
	tut.hide_overlay()
	tut.free()

	# 2. DayHUD first card pickup hint & non-dismissing hold
	var hud := DayHudScene.instantiate()
	root.add_child(hud)
	hud._ready()

	assert_false(Settings.card_first_pickup_done, "First pickup starts not done")
	hud.show_science_card_toast("F05", false)
	assert_true(hud._card_toast_wrap.visible, "Toast is visible")
	assert_true(hud._card_pickup_hint != null and hud._card_pickup_hint.visible, "First card toast shows pickup guidance hint")
	var hint_lbl: Label = hud._card_pickup_hint.get_node_or_null("HintHBox/HintLabel") as Label
	assert_true(hint_lbl != null and hint_lbl.text.contains("pick up"), "Pickup guidance has tap text")

	# Simulating tap on toast
	hud._on_card_toast_pressed()
	assert_true(Settings.card_first_pickup_done, "Tapping card marks card_first_pickup_done")
	assert_false(hud._card_toast_wrap.visible, "Toast closes upon tap")

	# Subsequent card toast does not show pickup hint
	hud.show_science_card_toast("F25", false)
	assert_true(hud._card_toast_wrap.visible, "Subsequent toast is visible")
	assert_false(hud._card_pickup_hint.visible, "Subsequent toast does not show first-pickup guidance")
	hud.hide_science_card_toast(true)
	hud.free()

	Settings.reset_onboarding()

