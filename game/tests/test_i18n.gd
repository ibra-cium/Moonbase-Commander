extends "res://tests/test_case.gd"

const TitleScreenScene := preload("res://ui/TitleScreen.tscn")
const MissionMapScene := preload("res://ui/MissionMap.tscn")
const PackScreenScene := preload("res://ui/PackScreen.tscn")
const DayHudScene := preload("res://ui/DayHud.tscn")
const DebriefScreenScene := preload("res://ui/DebriefScreen.tscn")
const EndingOverlayScene := preload("res://ui/EndingOverlay.tscn")
const SourcesScreenScene := preload("res://ui/SourcesScreen.tscn")
const SourceTagScene := preload("res://ui/SourceTag.tscn")
const EventPopupScene := preload("res://ui/EventPopup.tscn")
const SpeechBubbleScene := preload("res://world/SpeechBubble.tscn")
const CrewTagButtonScene := preload("res://ui/CrewTagButton.tscn")
const AstronautScene := preload("res://world/Astronaut.tscn")

func _get_root() -> Window:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root if tree != null else null

func _tr(key: String) -> String:
	return TranslationServer.translate(key)

func _read_csv_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var f := FileAccess.open("res://i18n/strings.csv", FileAccess.READ)
	if f == null:
		return rows
	var _header := f.get_csv_line()
	while not f.eof_reached():
		var cols := f.get_csv_line()
		if cols.is_empty() or (cols.size() == 1 and cols[0].strip_edges().is_empty()):
			continue
		var key: String = cols[0].strip_edges()
		if key.is_empty():
			continue
		var en_val: String = cols[1] if cols.size() > 1 else ""
		var bn_val: String = cols[2] if cols.size() > 2 else ""
		rows.append({"key": key, "en": en_val, "bn": bn_val})
	return rows

func _extract_placeholders(text: String) -> Array[String]:
	var rx := RegEx.new()
	rx.compile("\\{[^}]+\\}")
	var out: Array[String] = []
	for m in rx.search_all(text):
		out.append(m.get_string())
	out.sort()
	return out

func test_csv_keys_and_empty_bn_english_fallback() -> void:
	var saved_lang: String = Settings.language
	var rows := _read_csv_rows()
	assert_true(rows.size() >= 200, "strings.csv should contain all UI keys")

	Settings.language = "en"
	for row in rows:
		var key: String = row["key"]
		var en_val: String = row["en"]
		var got_en: String = _tr(key)
		assert_false(got_en.is_empty(), "EN translation non-empty for %s" % key)
		assert_eq(got_en, en_val, "EN translation matches CSV for %s" % key)

	Settings.language = "bn"
	var filled_bn_count: int = 0
	for row in rows:
		var key: String = row["key"]
		var en_val: String = row["en"]
		var bn_val: String = row["bn"]
		var got_bn: String = _tr(key)
		if bn_val.strip_edges().is_empty():
			assert_eq(got_bn, en_val, "Empty bn falls back to English for %s" % key)
		else:
			filled_bn_count += 1
			assert_eq(got_bn, bn_val, "Filled bn uses Bangla for %s" % key)
			assert_eq(_extract_placeholders(en_val), _extract_placeholders(bn_val), "Placeholders match for %s" % key)

	assert_true(filled_bn_count >= 200, "Existing strings.csv entries keep Bangla translations")

	var tr_en := Translation.new()
	tr_en.locale = "en"
	tr_en.add_message("__I18N_TEST_FALLBACK__", "Fallback EN")
	TranslationServer.add_translation(tr_en)
	assert_eq(_tr("__I18N_TEST_FALLBACK__"), "Fallback EN", "Missing bn translation falls back to English")
	TranslationServer.remove_translation(tr_en)

	var facts_text: String = FileAccess.get_file_as_string("res://data/facts.json")
	var facts_parsed: Variant = JSON.parse_string(facts_text)
	assert_true(facts_parsed is Dictionary and facts_parsed.has("facts"), "facts.json parses cleanly")
	var facts_list: Array = (facts_parsed as Dictionary).get("facts", [])
	assert_true(facts_list.size() >= 16, "facts.json contains all science facts")
	for item in facts_list:
		var fid: String = str(item.get("id", ""))
		assert_false(str(item.get("en", "")).strip_edges().is_empty(), "Fact %s en filled" % fid)
		var bn_fact: String = str(item.get("bn", "")).strip_edges()
		if fid.begins_with("F") and int(fid.substr(1)) <= 16:
			assert_false(bn_fact.is_empty(), "Fact %s bn filled" % fid)
	Settings.language = saved_lang

func test_title_and_map_language_refresh() -> void:
	var root := _get_root()
	assert_true(root != null, "SceneTree root available")
	var saved_lang: String = Settings.language
	var saved_sci: bool = Settings.science_view
	Settings.language = "en"
	Settings.science_view = false

	var title := TitleScreenScene.instantiate()
	root.add_child(title)
	title._ready()
	assert_eq(title.lang_button.text, "বাংলা", "Title shows বাংলা toggle in EN")
	assert_eq(title.start_button.text, "Start", "Title Start in EN")

	title._on_lang_pressed()
	assert_eq(Settings.language, "bn", "Title toggle sets Settings.language to bn")
	assert_eq(title.lang_button.text, "English", "Title shows English toggle in BN")
	assert_eq(title.start_button.text, "শুরু", "Title Start in BN")
	assert_eq(title.title_label.text, _tr("GAME_TITLE"), "Title heading refreshed in BN")
	assert_eq(title.subtitle_label.text, _tr("TITLE_SUBTITLE_TRAINING"), "Subtitle refreshed in BN")
	assert_eq(title.sources_button.text, _tr("TITLE_SOURCES"), "Sources button refreshed")
	assert_eq(title.credit_label.text, _tr("TITLE_CREDIT_MOON"), "Credit label refreshed")
	title.free()

	Settings.language = "en"
	var mmap := MissionMapScene.instantiate()
	root.add_child(mmap)
	mmap._ready()
	mmap._on_mission_pressed("M4")
	var locked_en: String = mmap._detail_goal.text
	Settings.language = "bn"
	assert_eq(mmap._title_label.text, _tr("MAP_TITLE"), "MissionMap title refreshed on language_changed")
	assert_eq(mmap._play_btn.text, _tr("MAP_PLAY"), "MissionMap play button refreshed")
	assert_eq(mmap._free_toggle.text, _tr("MAP_FREE_PLAY"), "MissionMap free play toggle refreshed")
	assert_eq(mmap._credit_label.text, _tr("MAP_CREDIT_MOON"), "MissionMap credit label refreshed")
	assert_eq(mmap._detail_goal.text, _tr("MAP_LOCKED"), "MissionMap locked text refreshes to BN")
	assert_true(mmap._detail_goal.text != locked_en, "MissionMap locked text switches out of EN")
	mmap.free()

	Settings.language = saved_lang
	Settings.science_view = saved_sci

func test_hud_pause_menu_and_world_fonts() -> void:
	var root := _get_root()
	assert_true(root != null, "SceneTree root available")
	var saved_lang: String = Settings.language
	var saved_sci: bool = Settings.science_view
	Settings.language = "en"
	Settings.science_view = false

	var hud := DayHudScene.instantiate()
	root.add_child(hud)
	hud._ready()
	assert_true(hud.pause_resume_btn.custom_minimum_size.y >= 64.0, "Pause ResumeBtn >= 64px")
	assert_true(hud.pause_sources_btn.custom_minimum_size.y >= 64.0, "Pause SourcesBtn >= 64px")
	assert_true(hud.pause_lang_btn.custom_minimum_size.y >= 64.0, "Pause LangBtn >= 64px")

	hud._on_menu_button_pressed()
	assert_eq(hud.pause_lang_btn.text, "Language: English", "Pause menu shows English before toggle")

	hud._on_pause_lang_pressed()
	assert_eq(Settings.language, "bn", "Pause menu language button switches to bn")
	assert_eq(hud.pause_lang_btn.text, _tr("HUD_LANGUAGE").format({"lang": "বাংলা"}), "Pause menu updates to বাংলা")
	assert_eq(hud.end_day_button.text, _tr("HUD_END_DAY"), "End Day button refreshed")
	assert_eq(hud.menu_btn.text, _tr("HUD_MENU"), "Menu button refreshed")
	assert_eq(hud.pause_title_label.text, _tr("MENU_PAUSE_TITLE"), "Pause title refreshed")
	assert_eq(hud.pause_resume_btn.text, _tr("MENU_RESUME"), "Pause resume refreshed")
	assert_eq(hud.pause_sources_btn.text, _tr("MENU_SOURCES"), "Pause sources refreshed")
	assert_eq(hud.power_gauge.title_label.text, _tr("KID_BATTERY"), "Battery kid gauge title refreshed")
	assert_eq(hud.co2_gauge.title_label.text, _tr("KID_AIR"), "Air kid gauge title refreshed")
	assert_eq(hud.water_gauge.title_label.text, _tr("HUD_WATER"), "Water gauge title refreshed")
	assert_eq(hud.food_gauge.title_label.text, _tr("HUD_FOOD"), "Food gauge title refreshed")
	assert_eq(hud.shelter_gauge.title_label.text, _tr("KID_STORM_SAFETY"), "Storm safety kid gauge title refreshed")
	Settings.science_view = true
	assert_eq(hud.power_gauge.title_label.text, _tr("HUD_POWER"), "Power gauge title refreshed in Science view")
	assert_eq(hud.o2_gauge.title_label.text, _tr("HUD_OXYGEN"), "O2 gauge title refreshed in Science view")
	assert_eq(hud.co2_gauge.title_label.text, _tr("HUD_CO2"), "CO2 gauge title refreshed in Science view")
	assert_eq(hud.rad_gauge.title_label.text, _tr("HUD_RADIATION"), "Radiation gauge title refreshed in Science view")
	assert_eq(hud.shelter_gauge.title_label.text, _tr("HUD_SHELTER"), "Shelter gauge title refreshed in Science view")
	Settings.science_view = false
	assert_eq(hud.res_science_title.text, _tr("RES_SCIENCE"), "Science pill title refreshed")
	assert_eq(hud.res_energy_title.text, _tr("RES_ENERGY"), "Energy pill title refreshed")
	assert_eq(hud.res_shelter_title.text, _tr("RES_SHELTER"), "Shelter pill title refreshed")

	hud._on_pause_lang_pressed()
	assert_eq(Settings.language, "en", "Pause menu switches back to en")
	assert_eq(hud.pause_lang_btn.text, "Language: English", "Pause menu updates back to English")
	hud.free()

	var astro := AstronautScene.instantiate()
	root.add_child(astro)
	astro._ready()
	var name_tag := astro.get_node_or_null("BodyPivot/NameTag") as Label3D
	assert_true(name_tag != null and name_tag.font != null, "Astronaut 3D NameTag has Bangla fallback font")
	astro.free()

	var bubble := SpeechBubbleScene.instantiate()
	root.add_child(bubble)
	bubble._ready()
	assert_true(bubble.theme != null, "SpeechBubble carries Theme.tres with Bangla fallback")
	bubble.show_bubble("CREW_SAY_HELLO")
	Settings.language = "bn"
	assert_eq(bubble.text_label.text, _tr("CREW_SAY_HELLO"), "SpeechBubble refreshes on language change")
	bubble.free()

	var tag_btn := CrewTagButtonScene.instantiate()
	root.add_child(tag_btn)
	tag_btn._ready()
	tag_btn.setup(0, _tr("CREW_NAME_0"), Color.WHITE, null, null)
	Settings.language = "en"
	assert_eq(tag_btn._name_label.text, _tr("CREW_NAME_0"), "CrewTagButton uses translated crew name")
	tag_btn.free()

	var popup := EventPopupScene.instantiate()
	root.add_child(popup)
	popup._ready()
	popup.popup_event("EVT_STORM_TITLE", "EVT_STORM_WARN", ["POPUP_OK"])
	Settings.language = "bn"
	assert_eq(popup.title_label.text, _tr("EVT_STORM_TITLE"), "EventPopup refreshes title on language change")
	popup.free()

	Settings.language = saved_lang
	Settings.science_view = saved_sci

func test_debrief_ending_sources_and_pack_refresh() -> void:
	var root := _get_root()
	assert_true(root != null, "SceneTree root available")
	var saved_lang: String = Settings.language
	var saved_mission: String = Settings.current_mission_id

	Settings.language = "en"
	var ending := EndingOverlayScene.instantiate()
	root.add_child(ending)
	ending._ready()
	ending.setup(true)
	assert_eq(ending.skip_button.text, "Skip >>", "Ending skip button in EN")
	Settings.language = "bn"
	assert_eq(ending.title_label.text, _tr("ENDING_SUCCESS_TITLE"), "Ending title updates to BN")
	assert_eq(ending.skip_button.text, _tr("BTN_SKIP"), "Ending skip button updates to BN")
	ending.free()

	Settings.language = "en"
	var debrief := DebriefScreenScene.instantiate()
	root.add_child(debrief)
	debrief._ready()
	var sample_res := {
		"outcome": "SURVIVED",
		"stars": 3,
		"end_day": 30,
		"total_days": 30,
		"root_cause_code": "SUCCESS_3",
		"cause_chain": [{"day": 15, "code": "SUNSET", "values": {}}],
		"fact": {"id": "FTEST", "en": "English fact", "bn": "বাংলা তথ্য", "source": "NASA"},
	}
	debrief.show_result(sample_res, 123, false)
	assert_eq(debrief.title_label.text, _tr("DEBRIEF_TITLE"), "Debrief title uses tr key")
	assert_eq(debrief.root_cause_header.text, _tr("DEBRIEF_ROOT_CAUSE_TITLE"), "Debrief analysis header uses tr key")
	assert_eq(debrief.timeline_header.text, _tr("DEBRIEF_TIMELINE_TITLE"), "Debrief timeline header uses tr key")
	assert_eq(debrief.fact_title_label.text, _tr("DEBRIEF_FACT_TITLE"), "Debrief fact header uses tr key")
	assert_eq(debrief.fact_label.text, "English fact", "Debrief shows English fact in EN")

	Settings.language = "bn"
	assert_eq(debrief.fact_label.text, "বাংলা তথ্য", "Debrief switches to bn fact when filled")

	var empty_bn_res := {
		"outcome": "SURVIVED",
		"stars": 3,
		"end_day": 30,
		"total_days": 30,
		"root_cause_code": "SUCCESS_3",
		"fact": {"id": "FEMPTY", "en": "Fallback English fact", "bn": "", "source": "NASA"},
	}
	debrief.show_result(empty_bn_res, 123, false)
	assert_eq(debrief.fact_label.text, "Fallback English fact", "Empty bn fact falls back to English")
	debrief.free()

	Settings.language = "en"
	var sources := SourcesScreenScene.instantiate()
	root.add_child(sources)
	sources._ready()
	Settings.language = "bn"
	assert_eq(sources.search_edit.placeholder_text, _tr("SRC_SEARCH_PLACEHOLDER"), "Sources search placeholder uses tr")
	assert_eq(sources.system_option.get_item_text(0), _tr("SRC_FILTER_ALL"), "Sources system filter item 0 uses tr")
	sources.free()

	var tag := SourceTagScene.instantiate()
	root.add_child(tag)
	tag._ready()
	var close_btn := tag.get_node_or_null("PopoverLayer/CenterContainer/PopoverPanel/Margin/VBox/Header/CloseButton") as Button
	assert_true(close_btn != null and close_btn.text == "×", "SourceTag CloseButton uses safe × glyph instead of ✕")
	tag.free()

	Settings.current_mission_id = "M1"
	Settings.language = "en"
	var pack := PackScreenScene.instantiate()
	root.add_child(pack)
	pack._ready()
	pack.card_solar._ready()
	assert_eq(pack.card_solar.lock_label.text, _tr("PACK_LOCKED_ITEM"), "Pack locked card uses tr key")
	Settings.language = "bn"
	assert_eq(pack.title_label.text, _tr("PACK_TITLE"), "PackScreen refreshes title on language_changed")
	assert_eq(pack.card_solar.lock_label.text, _tr("PACK_LOCKED_ITEM"), "Pack locked card refreshes on language_changed")
	pack.free()

	Settings.current_mission_id = saved_mission
	Settings.language = saved_lang
