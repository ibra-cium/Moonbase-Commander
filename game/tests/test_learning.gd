extends "res://tests/test_case.gd"

const LearningDataScript := preload("res://ui/learning_data.gd")
const MissionBriefingScene: PackedScene = preload("res://ui/MissionBriefing.tscn")
const DebriefScreenScene: PackedScene = preload("res://ui/DebriefScreen.tscn")
const MissionMapScene: PackedScene = preload("res://ui/MissionMap.tscn")
const CertificateScreenScene: PackedScene = preload("res://ui/CertificateScreen.tscn")
const TitleScreenScene: PackedScene = preload("res://ui/TitleScreen.tscn")


func _get_root() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root if tree != null else null


func run() -> void:
	var saved_lang: String = Settings.language
	var saved_stars: Dictionary = Settings.mission_stars.duplicate()
	var saved_mission: String = Settings.current_mission_id
	var saved_free: bool = Settings.free_play
	Settings.reset_training()
	Settings.mission_stars = {}
	Settings.free_play = false
	Settings.language = "en"

	test_formatted_explanations_and_fallback()
	test_data_integrity()
	test_session_state_and_ranks()
	test_strings_csv_bn_fallback()
	test_briefing_flow_and_replay_skip()
	test_debrief_learning_steps_and_certificate_gate()
	test_map_results_and_certificate_screen()

	Settings.reset_training()
	Settings.mission_stars = saved_stars
	Settings.current_mission_id = saved_mission
	Settings.free_play = saved_free
	Settings.language = saved_lang


func test_formatted_explanations_and_fallback() -> void:
	var ld: LearningData = LearningDataScript.new()
	Settings.language = "en"

	var m1_exp: String = ld.formatted_text(ld.question("M1").get("explain"))
	assert_eq(
		m1_exp,
		"About 3.2 kg a day – that's about three 1-litre bottles for each astronaut!",
		"M1 formatted explain matches expected string"
	)

	var m2_exp: String = ld.formatted_text(ld.question("M2").get("explain"))
	assert_eq(
		m2_exp,
		"About 98%! Even sweat and urine are cleaned into drinking water.",
		"M2 formatted explain matches expected string"
	)

	var m3_exp: String = ld.formatted_text(ld.question("M3").get("explain"))
	assert_eq(
		m3_exp,
		"Water and Moon soil! 15 g/cm² of water cuts the storm dose from 398 to about 47 mSv.",
		"M3 formatted explain matches expected string"
	)

	var m4_exp: String = ld.formatted_text(ld.question("M4").get("explain"))
	assert_eq(
		m4_exp,
		"About 2 weeks! For our base, batteries for the whole night would weigh about 41,000 kg – but the lander carries only 15,000 kg.",
		"M4 formatted explain matches expected string"
	)

	Settings.language = "bn"
	# Empty bn falls back to English
	assert_eq(ld.mission_control_name(), "Mission Control", "Empty bn mission_control falls back to EN")
	assert_eq(ld.rank_name("CADET"), "Cadet", "Empty bn rank falls back to EN")
	assert_eq(ld.formatted_text(ld.question("M1").get("explain")), m1_exp, "Empty bn question explain falls back to EN")
	assert_eq(ld.text(ld.fact("F27")), str(ld.fact("F27").get("en", "")), "Empty bn F27 fact falls back to EN")
	# Non-empty bn uses Bangla
	var f01: Dictionary = ld.fact("F01")
	assert_eq(ld.text(f01), str(f01.get("bn", "")), "Non-empty bn fact returns Bangla text")
	Settings.language = "en"


func test_data_integrity() -> void:
	var ld: LearningData = LearningDataScript.new()
	for mid in ["M1", "M2", "M3", "M4"]:
		var cards: Array = ld.briefing(mid)
		assert_eq(cards.size(), 2, "%s has 2 briefing cards" % mid)
		for card in cards:
			if card is Dictionary:
				var fid_v: Variant = card.get("fact_id", null)
				if fid_v != null and not str(fid_v).is_empty():
					var f: Dictionary = ld.fact(str(fid_v))
					assert_false(f.is_empty(), "%s briefing fact_id %s exists in facts.json" % [mid, str(fid_v)])
				var txt_v: Variant = card.get("text", null)
				if txt_v is Dictionary:
					for tok in ld.find_placeholders(str(txt_v.get("en", ""))):
						assert_true(Constants.has(tok["id"]), "%s briefing token %s in constants.json" % [mid, tok["id"]])

		var q: Dictionary = ld.question(mid)
		assert_false(q.is_empty(), "%s question present" % mid)
		var exp_en: String = str(q.get("explain", {}).get("en", ""))
		for tok in ld.find_placeholders(exp_en):
			assert_true(Constants.has(tok["id"]), "%s explain token %s in constants.json" % [mid, tok["id"]])
		for cid_v in q.get("constant_ids", []):
			assert_true(Constants.has(str(cid_v)), "%s constant_ids entry %s in constants.json" % [mid, str(cid_v)])

		var les_en: String = str(ld.lesson(mid).get("en", ""))
		for tok in ld.find_placeholders(les_en):
			assert_true(Constants.has(tok["id"]), "%s lesson token %s in constants.json" % [mid, tok["id"]])

		var nasa_id: String = ld.nasa_now_fact_id(mid)
		assert_false(nasa_id.is_empty(), "%s has nasa_now_fact" % mid)
		assert_false(ld.fact(nasa_id).is_empty(), "%s nasa_now_fact %s exists in facts.json" % [mid, nasa_id])

	for c in ld.cards():
		if c is Dictionary:
			var fid: String = str(c.get("fact_id", ""))
			assert_false(ld.fact(fid).is_empty(), "Card fact_id %s exists in facts.json" % fid)


func test_session_state_and_ranks() -> void:
	Settings.reset_training()
	assert_eq(Settings.rank_id, "CADET", "Initial rank is CADET")

	# before is stored only once
	assert_true(Settings.record_before_answer("M1", 0), "M1 before stores first time")
	assert_false(Settings.record_before_answer("M1", 1), "M1 before cannot be overwritten")
	assert_eq(Settings.get_before_answer("M1"), 0, "M1 before kept first value 0")

	# after is stored only once
	assert_true(Settings.record_after_answer("M1", 1), "M1 after stores first time")
	assert_false(Settings.record_after_answer("M1", 2), "M1 after cannot be overwritten")
	assert_eq(Settings.get_after_answer("M1"), 1, "M1 after kept first value 1")

	var score1: Dictionary = Settings.training_score()
	assert_eq(int(score1.get("answered", -1)), 1, "Score answered = 1")
	assert_eq(int(score1.get("before_right", -1)), 0, "Score before_right = 0")
	assert_eq(int(score1.get("after_right", -1)), 1, "Score after_right = 1")

	# Second mission: both right (M2 correct == 2)
	Settings.record_before_answer("M2", 2)
	Settings.record_after_answer("M2", 2)
	var score2: Dictionary = Settings.training_score()
	assert_eq(int(score2.get("answered", -1)), 2, "Score answered = 2")
	assert_eq(int(score2.get("before_right", -1)), 1, "Score before_right = 1")
	assert_eq(int(score2.get("after_right", -1)), 2, "Score after_right = 2")

	# Collect card once
	assert_true(Settings.collect_card("F05"), "collect_card returns true when new")
	assert_false(Settings.collect_card("F05"), "collect_card returns false on duplicate")

	# Rank only goes up, and only on a win
	assert_eq(Settings.promote_after_win("M1", 0), "", "Loss on M1 does not promote")
	assert_eq(Settings.rank_id, "CADET", "Rank stays CADET on loss")
	assert_eq(Settings.promote_after_win("M1", 2), "JUNIOR", "M1 win promotes CADET -> JUNIOR")
	assert_eq(Settings.rank_id, "JUNIOR", "Rank updated to JUNIOR")
	assert_eq(Settings.promote_after_win("M3", 1), "ENGINEER", "M3 win promotes JUNIOR -> ENGINEER")
	assert_eq(Settings.promote_after_win("M2", 3), "", "Lower mission win never demotes rank")
	assert_eq(Settings.rank_id, "ENGINEER", "Rank stays ENGINEER")
	assert_eq(Settings.promote_after_win("M4", 3), "COMMANDER", "M4 win promotes ENGINEER -> COMMANDER")
	assert_eq(Settings.promote_after_win("M4", 3), "", "Re-winning M4 does not re-trigger promotion")


func test_strings_csv_bn_fallback() -> void:
	var new_keys: Array[String] = [
		"BRIEF_NEXT", "BRIEF_SKIP", "BRIEF_GO", "BRIEF_FACT_BADGE",
		"GUESS_TITLE", "GUESS_HINT", "DEBRIEF_NOW_YOU_KNOW",
		"DEBRIEF_RIGHT", "DEBRIEF_WRONG", "DEBRIEF_YOU_GUESSED",
		"DEBRIEF_LEARNED", "DEBRIEF_NASA_NOW", "DEBRIEF_NEW_RANK",
		"DEBRIEF_CERTIFICATE", "MAP_RANK", "MAP_TRAINING_SCORE",
		"MAP_RESULTS", "RESULTS_TITLE", "RESULTS_COL_MISSION",
		"RESULTS_COL_BEFORE", "RESULTS_COL_AFTER", "RESULTS_COL_STARS",
		"RESULTS_COPY", "RESULTS_COPIED", "RESULTS_NOTE",
		"CERT_TITLE", "CERT_LEARNED", "CERT_CARDS", "CERT_FOOTER",
		"CERT_BACK", "TITLE_SUBTITLE_TRAINING",
	]
	for key in new_keys:
		Settings.language = "en"
		var en_val: String = TranslationServer.translate(key)
		assert_false(en_val.is_empty() or en_val == key, "EN translation exists for %s" % key)
		Settings.language = "bn"
		var bn_val: String = TranslationServer.translate(key)
		assert_eq(bn_val, en_val, "Empty bn strings.csv cell for %s falls back to EN in bn locale" % key)

	Settings.language = "bn"
	var root := _get_root()
	if root != null:
		var title := TitleScreenScene.instantiate()
		root.add_child(title)
		title._ready()
		assert_eq(title.subtitle_label.text, "Junior Astronaut Training", "Title subtitle falls back cleanly in BN")
		title.free()
	Settings.language = "en"


func test_briefing_flow_and_replay_skip() -> void:
	var root := _get_root()
	assert_true(root != null, "SceneTree root available")
	Settings.reset_training()
	Settings.language = "en"

	var brief: MissionBriefing = MissionBriefingScene.instantiate() as MissionBriefing
	root.add_child(brief)
	brief._ready()

	var done_count: Array[int] = [0]
	brief.completed.connect(func(): done_count[0] += 1)

	brief.start_briefing("M1")
	assert_false(brief.skip_button.visible, "First M1 briefing hides Skip button")
	assert_true(brief.card_section.visible, "Card 0 visible initially")
	brief._on_next_pressed()
	assert_true(brief.card_section.visible, "Card 1 visible after Next")
	assert_true(brief.badge_row.visible, "Card 1 shows fact badge + SourceTag for F05")
	assert_true(Settings.collected_cards.has("F05"), "Briefing fact card F05 collected")
	brief._on_next_pressed()

	assert_true(brief.guess_section.visible, "Guess first screen shown")
	assert_eq(brief.option_buttons.size(), 3, "Three answer buttons shown")
	for btn in brief.option_buttons:
		assert_true(btn.custom_minimum_size.y >= 64.0, "Guess option button >= 64px high")
	assert_true(brief.go_button.disabled, "Go button disabled before picking guess")

	brief._on_option_pressed(0)
	assert_false(brief.go_button.disabled, "Go button enabled after picking guess")
	brief._on_go_pressed()
	assert_eq(done_count[0], 1, "Briefing emitted completed")
	assert_eq(Settings.get_before_answer("M1"), 0, "M1 before stored after first Guess")

	# Replay same mission: Skip visible, Guess first skipped
	brief.start_briefing("M1")
	assert_true(brief.skip_button.visible, "Replay briefing shows Skip button")
	brief._on_next_pressed()  # Card 0 -> Card 1
	assert_true(brief.go_button.visible, "Replay Card 1 goes directly to Let's go button")
	brief._on_skip_pressed()
	assert_eq(done_count[0], 2, "Skip emits completed cleanly")

	brief.free()


func test_debrief_learning_steps_and_certificate_gate() -> void:
	var root := _get_root()
	assert_true(root != null, "SceneTree root available")
	Settings.reset_training()
	Settings.language = "en"
	var ld: LearningData = LearningDataScript.new()

	var debrief: DebriefScreen = DebriefScreenScene.instantiate() as DebriefScreen
	root.add_child(debrief)
	debrief._ready()

	# 1. M1 win: promotes CADET -> JUNIOR, no certificate button, fact skips F27
	Settings.current_mission_id = "M1"
	debrief.show_result_with_next({
		"mission_id": "M1",
		"outcome": "SURVIVED",
		"stars": 2,
		"end_day": 5,
		"total_days": 5,
		"fact": ld.nasa_now_fact("M1"),
	}, 42, true)
	assert_false(debrief.certificate_button.visible, "Certificate not offered after M1 win")
	assert_true(debrief.fact_label.text != ld.text(ld.nasa_now_fact("M1")), "M1 debrief fact skips nasa_now_fact F27")
	assert_eq(Settings.rank_id, "JUNIOR", "M1 win promoted to JUNIOR")

	# Step through M1 debrief learning loop
	debrief.advance_step()
	assert_true(debrief.question_section.visible, "M1 Debrief enters Now you know!")
	assert_true(debrief.step_next_button.disabled, "Next disabled until question answered")
	debrief.select_after_answer(1)
	assert_false(debrief.step_next_button.disabled, "Next enabled after answering")
	assert_true(debrief.feedback_panel.visible, "Feedback panel visible")
	assert_true(debrief.explain_label.text.contains("3.2"), "M1 feedback explains 3.2 kg")
	assert_eq(debrief.explain_source_tag.constant_id, "WATER_KG_PERSON_DAY", "Explain SourceTag shows WATER_KG_PERSON_DAY")
	debrief.advance_step()
	assert_true(debrief.lesson_section.visible, "You learned step visible")
	debrief.advance_step()
	assert_true(debrief.nasa_now_section.visible, "NASA now step visible")
	assert_true(Settings.collected_cards.has("F27"), "M1 NASA now card F27 collected")
	debrief.advance_step()
	assert_true(debrief.rank_up_section.visible, "Rank up step visible on M1 win")
	assert_true(debrief.is_final_step(), "Rank up is final step when promoted")

	# 2. M2 loss: learning steps STILL show, no rank up, no certificate, skips F28
	Settings.current_mission_id = "M2"
	debrief.show_result_with_next({
		"mission_id": "M2",
		"outcome": "EVAC_WATER",
		"stars": 0,
		"end_day": 9,
		"total_days": 10,
		"fact": ld.nasa_now_fact("M2"),
	}, 99, true)
	assert_false(debrief.certificate_button.visible, "Certificate not offered after M2 loss")
	assert_true(debrief.fact_label.text != ld.text(ld.nasa_now_fact("M2")), "M2 debrief fact skips nasa_now_fact F28")
	assert_eq(Settings.rank_id, "JUNIOR", "M2 loss keeps rank JUNIOR")
	debrief.advance_step()
	assert_true(debrief.question_section.visible, "Now you know STILL shows when mission failed")
	debrief.select_after_answer(2)
	assert_true(debrief.explain_label.text.contains("98%"), "M2 feedback explains 98%")
	debrief.advance_step()
	assert_true(debrief.lesson_section.visible, "M2 You learned step visible on failure")
	debrief.advance_step()
	assert_true(debrief.nasa_now_section.visible, "M2 NASA now step visible on failure")
	assert_true(debrief.is_final_step(), "NASA now is final step when not promoted")

	# 3. M4 loss: certificate NOT offered
	Settings.current_mission_id = "M4"
	debrief.show_result_with_next({
		"mission_id": "M4",
		"outcome": "EVAC_POWER",
		"stars": 0,
		"end_day": 16,
		"total_days": 30,
	}, 100, false)
	assert_false(debrief.certificate_button.visible, "Certificate NOT offered on M4 loss")
	assert_true(debrief.fact_label.text != ld.text(ld.nasa_now_fact("M4")), "M4 debrief fact skips nasa_now_fact F25")

	# 4. M4 win: certificate offered, rank promoted to COMMANDER
	debrief.show_result_with_next({
		"mission_id": "M4",
		"outcome": "SURVIVED",
		"stars": 3,
		"end_day": 30,
		"total_days": 30,
	}, 101, false)
	assert_eq(Settings.rank_id, "COMMANDER", "M4 win promotes to COMMANDER")
	assert_true(debrief.certificate_button.visible, "Certificate button visible on M4 win")
	debrief.advance_step()
	debrief.select_after_answer(1)
	debrief.advance_step()
	debrief.advance_step()
	debrief.advance_step()
	assert_true(debrief.cert_row.visible and debrief.certificate_button.visible, "Certificate CTA visible on final step")

	debrief.free()


func test_map_results_and_certificate_screen() -> void:
	var root := _get_root()
	assert_true(root != null, "SceneTree root available")
	Settings.reset_training()
	Settings.language = "en"
	Settings.mission_stars = {"M1": 3, "M2": 0, "M3": 2, "M4": 3}
	Settings.record_before_answer("M1", 0)
	Settings.record_after_answer("M1", 1)
	Settings.promote_after_win("M4", 3)

	var mmap: MissionMap = MissionMapScene.instantiate() as MissionMap
	root.add_child(mmap)
	mmap._ready()
	assert_true(mmap._rank_label.text.contains("Moonbase Commander"), "Map shows rank badge")
	assert_true(mmap._score_label.visible, "Map shows training score when answered > 0")
	assert_true(mmap._score_label.text.contains("before 0/1"), "Map training score shows before count")
	assert_true(mmap._score_label.text.contains("after 1/1"), "Map training score shows after count")

	mmap.open_results()
	assert_true(mmap._results_layer.visible, "Results panel opens")
	mmap.copy_results_summary()
	assert_true(mmap._results_copied_label.visible, "Results shows Copied label after copy")
	var summary: String = mmap.build_results_summary()
	assert_true(summary.contains("Before 0/1") and summary.contains("After 1/1"), "Results summary contains score")
	mmap.close_results()
	mmap.free()

	var cert: CertificateScreen = CertificateScreenScene.instantiate() as CertificateScreen
	root.add_child(cert)
	cert._ready()
	cert.refresh_certificate()
	assert_eq(cert.title_label.text, TranslationServer.translate("CERT_TITLE"), "Certificate shows CERT_TITLE")
	assert_true(cert.rank_label.text.contains("Moonbase Commander"), "Certificate shows rank")
	assert_true(cert.cards_label.visible, "CERT_CARDS visible in M-09")
	assert_true(cert.cards_label.text.contains("Science Cards:"), "Certificate shows Science Cards count")
	assert_eq(cert.date_label.text, Time.get_date_string_from_system(), "Certificate shows today's date")
	assert_true(cert.footer_label.text.contains("Space-ArenaX"), "Certificate shows footer")
	assert_eq(cert.learned_vbox.get_child_count(), 3, "Certificate lists 3 survived mission lessons (M1, M3, M4)")
	assert_eq(cert.find_children("*", "LineEdit", true, false).size(), 0, "Certificate has no name input field")
	assert_eq(cert.find_children("*", "TextEdit", true, false).size(), 0, "Certificate has no name TextEdit")
	assert_true(cert.back_button.custom_minimum_size.y >= 64.0, "Back to map button >= 64px")
	cert.free()

