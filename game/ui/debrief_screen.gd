class_name DebriefScreen
extends Control

signal retry_pressed
signal change_cargo_pressed
signal title_pressed
signal next_mission_pressed
signal certificate_pressed

enum DebriefStep { RESULT, QUESTION, LESSON, NASA_NOW, RANK_UP }

const ICON_STAR: Texture2D = preload("res://assets/icons/star.svg")
const SafeArea := preload("res://ui/safe_area.gd")
const LearningDataScript := preload("res://ui/learning_data.gd")
const CardAlbumScene := preload("res://ui/CardAlbum.tscn")
const STAR_EMPTY_COLOR := Color(0.34, 0.38, 0.46, 0.45)

const ICON_MAP: Dictionary = {
	"SUNSET": "res://assets/icons/nightlight.svg",
	"STORM_WARNING": "res://assets/icons/shield.svg",
	"BLACKOUT": "res://assets/icons/bolt.svg",
	"POWER_SHED": "res://assets/icons/bolt.svg",
	"CO2_HIGH": "res://assets/icons/co2.svg",
	"CREW_SICK": "res://assets/icons/warning.svg",
	"CREW_TIRED": "res://assets/icons/warning.svg",
	"RECYCLER_BROKE": "res://assets/icons/construction.svg",
	"METEOROID": "res://assets/icons/landscape.svg",
	"DUST_HIGH": "res://assets/icons/cleaning_services.svg",
	"FOOD_SPOILED": "res://assets/icons/restaurant.svg",
	"PLANTS_DIED": "res://assets/icons/eco.svg",
	"SUPPLY_LOW": "res://assets/icons/warning.svg",
	"EVAC_CO2": "res://assets/icons/rocket_launch.svg",
	"EVAC_O2": "res://assets/icons/rocket_launch.svg",
	"EVAC_WATER": "res://assets/icons/rocket_launch.svg",
	"EVAC_FOOD": "res://assets/icons/rocket_launch.svg",
	"EVAC_RADIATION": "res://assets/icons/rocket_launch.svg",
}

var title_label: Label
var outcome_label: Label
var stars_label: Label
var days_label: Label
var reason_label: Label
var root_cause_panel: PanelContainer
var seed_label: Label
var retry_button: Button
var change_cargo_button: Button
var title_button: Button
var next_mission_button: Button

var storm_disclosure_box: Control
var storm_chance_label: Label
var storm_source_tag: Control

var timeline_section: Control
var timeline_vbox: Control

var fact_panel: PanelContainer
var fact_label: Label
var fact_source_label: Label

var root_cause_header: Label
var timeline_header: Label
var fact_title_label: Label

var scroll_container: ScrollContainer
var button_box: HBoxContainer
var step_footer: HBoxContainer
var step_next_button: Button
var cert_row: HBoxContainer
var certificate_button: Button

var question_section: VBoxContainer
var question_title_label: Label
var question_prompt_label: Label
var question_options_vbox: VBoxContainer
var question_option_buttons: Array[Button] = []
var feedback_panel: PanelContainer
var feedback_icon: TextureRect
var feedback_mark: Label
var feedback_label: Label
var explain_label: Label
var explain_source_tag: SourceTag
var you_guessed_label: Label

var lesson_section: PanelContainer
var lesson_title_label: Label
var lesson_body_label: Label

var nasa_now_section: PanelContainer
var nasa_now_title_label: Label
var nasa_now_source_tag: SourceTag
var nasa_now_body_label: Label

var rank_up_section: PanelContainer
var rank_star_icon: TextureRect
var rank_up_label: Label

var _learning: LearningData = LearningData.new()
var _last_result = null
var _mission_seed: int = 0
var _last_has_next: bool = false
var _stars_row: HBoxContainer = null
var _current_mission_id: String = "M1"
var _survived: bool = false
var _debrief_step: int = DebriefStep.RESULT
var _question_data: Dictionary = {}
var _answered_after: bool = false
var _selected_after: int = -1
var _promoted_rank: String = ""
var _nasa_fact_id: String = ""
var _style_opt_normal: StyleBoxFlat
var _style_opt_right: StyleBoxFlat
var _style_opt_wrong: StyleBoxFlat
var new_cards_button: Button
var new_cards_label: Label
var new_cards_icons: HBoxContainer
var _card_album: CanvasLayer

func _ensure_nodes() -> void:
	if retry_button != null:
		return
	title_label = find_child("TitleLabel", true, false) as Label
	outcome_label = find_child("OutcomeLabel", true, false) as Label
	stars_label = find_child("StarsLabel", true, false) as Label
	days_label = find_child("DaysLabel", true, false) as Label
	reason_label = find_child("ReasonLabel", true, false) as Label
	root_cause_panel = find_child("RootCausePanel", true, false) as PanelContainer
	seed_label = find_child("SeedLabel", true, false) as Label
	retry_button = find_child("RetryButton", true, false) as Button
	change_cargo_button = find_child("ChangeCargoButton", true, false) as Button
	title_button = find_child("TitleButton", true, false) as Button
	next_mission_button = find_child("NextMissionButton", true, false) as Button

	scroll_container = find_child("ScrollContainer", true, false) as ScrollContainer
	button_box = find_child("ButtonBox", true, false) as HBoxContainer
	step_footer = find_child("StepFooter", true, false) as HBoxContainer
	step_next_button = find_child("StepNextButton", true, false) as Button
	cert_row = find_child("CertRow", true, false) as HBoxContainer
	certificate_button = find_child("CertificateButton", true, false) as Button

	storm_disclosure_box = find_child("StormDisclosureBox", true, false) as Control
	storm_chance_label = find_child("StormChanceLabel", true, false) as Label
	storm_source_tag = find_child("StormSourceTag", true, false) as Control

	if root_cause_panel != null:
		root_cause_header = root_cause_panel.get_node_or_null("VBox/Header") as Label

	timeline_section = find_child("TimelineSection", true, false) as Control
	timeline_header = find_child("TimelineHeader", true, false) as Label
	timeline_vbox = find_child("TimelineVBox", true, false) as Control

	fact_panel = find_child("FactPanel", true, false) as PanelContainer
	fact_title_label = find_child("FactTitle", true, false) as Label
	fact_label = find_child("FactLabel", true, false) as Label
	fact_source_label = find_child("FactSourceLabel", true, false) as Label

	question_section = find_child("QuestionSection", true, false) as VBoxContainer
	question_title_label = find_child("QuestionTitleLabel", true, false) as Label
	question_prompt_label = find_child("QuestionPromptLabel", true, false) as Label
	question_options_vbox = find_child("QuestionOptionsVBox", true, false) as VBoxContainer
	feedback_panel = find_child("FeedbackPanel", true, false) as PanelContainer
	feedback_icon = find_child("FeedbackIcon", true, false) as TextureRect
	feedback_mark = find_child("FeedbackMark", true, false) as Label
	feedback_label = find_child("FeedbackLabel", true, false) as Label
	explain_label = find_child("ExplainLabel", true, false) as Label
	explain_source_tag = find_child("ExplainSourceTag", true, false) as SourceTag
	you_guessed_label = find_child("YouGuessedLabel", true, false) as Label

	lesson_section = find_child("LessonSection", true, false) as PanelContainer
	lesson_title_label = find_child("LessonTitleLabel", true, false) as Label
	lesson_body_label = find_child("LessonBodyLabel", true, false) as Label

	nasa_now_section = find_child("NasaNowSection", true, false) as PanelContainer
	nasa_now_title_label = find_child("NasaNowTitleLabel", true, false) as Label
	nasa_now_source_tag = find_child("NasaNowSourceTag", true, false) as SourceTag
	nasa_now_body_label = find_child("NasaNowBodyLabel", true, false) as Label

	rank_up_section = find_child("RankUpSection", true, false) as PanelContainer
	rank_star_icon = find_child("RankStarIcon", true, false) as TextureRect
	rank_up_label = find_child("RankUpLabel", true, false) as Label

func _init_option_styles() -> void:
	if _style_opt_normal != null:
		return
	_style_opt_normal = StyleBoxFlat.new()
	_style_opt_normal.bg_color = Color(0.11, 0.145, 0.215, 0.96)
	_style_opt_normal.border_color = Color(0.28, 0.36, 0.50, 0.85)
	_style_opt_normal.set_border_width_all(2)
	_style_opt_normal.set_corner_radius_all(8)
	_style_opt_normal.set_content_margin_all(12)

	_style_opt_right = StyleBoxFlat.new()
	_style_opt_right.bg_color = Color(0.10, 0.28, 0.17, 0.96)
	_style_opt_right.border_color = Color(0.266667, 0.701961, 0.352941, 1.0)
	_style_opt_right.set_border_width_all(2)
	_style_opt_right.set_corner_radius_all(8)
	_style_opt_right.set_content_margin_all(12)

	_style_opt_wrong = StyleBoxFlat.new()
	_style_opt_wrong.bg_color = Color(0.30, 0.11, 0.13, 0.96)
	_style_opt_wrong.border_color = Color(0.878431, 0.282353, 0.282353, 1.0)
	_style_opt_wrong.set_border_width_all(2)
	_style_opt_wrong.set_corner_radius_all(8)
	_style_opt_wrong.set_content_margin_all(12)


func _ready() -> void:
	_ensure_nodes()
	_init_option_styles()
	_apply_static_texts()
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)
	if Settings != null and Settings.has_signal("card_collected") and not Settings.card_collected.is_connected(_on_card_collected):
		Settings.card_collected.connect(_on_card_collected)
	_ensure_new_cards_ui()
	if retry_button != null and not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	if change_cargo_button != null and not change_cargo_button.pressed.is_connected(_on_change_cargo_pressed):
		change_cargo_button.pressed.connect(_on_change_cargo_pressed)
	if title_button != null and not title_button.pressed.is_connected(_on_title_pressed):
		title_button.pressed.connect(_on_title_pressed)
	if next_mission_button != null and not next_mission_button.pressed.is_connected(_on_next_mission_pressed):
		next_mission_button.pressed.connect(_on_next_mission_pressed)
	if step_next_button != null and not step_next_button.pressed.is_connected(_on_step_next_pressed):
		step_next_button.pressed.connect(_on_step_next_pressed)
	if certificate_button != null and not certificate_button.pressed.is_connected(_on_certificate_pressed):
		certificate_button.pressed.connect(_on_certificate_pressed)
	_apply_safe_area()
	SafeArea.connect_resize(self, _apply_safe_area)

func _apply_safe_area() -> void:
	var insets: Dictionary = SafeArea.get_insets(self)
	var l: float = float(insets.get("left", 0))
	var t: float = float(insets.get("top", 0))
	var r: float = float(insets.get("right", 0))
	var b: float = float(insets.get("bottom", 0))
	var center := get_node_or_null("CenterContainer") as Control
	if center != null:
		center.offset_left = l
		center.offset_top = t
		center.offset_right = -r
		center.offset_bottom = -b
	var panel := get_node_or_null("CenterContainer/Panel") as PanelContainer
	if panel != null:
		var vp_size: Vector2 = size
		if vp_size.x <= 0.0 or vp_size.y <= 0.0:
			vp_size = Vector2(1280.0, 720.0)
		var avail_w: float = maxf(320.0, vp_size.x - l - r - 24.0)
		var avail_h: float = maxf(320.0, vp_size.y - t - b - 24.0)
		var is_portrait: bool = vp_size.y > vp_size.x
		if is_portrait:
			panel.custom_minimum_size = Vector2(minf(1080.0, avail_w - 32.0), minf(980.0, avail_h * 0.55))
		else:
			panel.custom_minimum_size = Vector2(minf(860.0, avail_w), minf(680.0, avail_h))
		var min_btn_w: float = 64.0 if avail_w < 560.0 else 160.0
		if button_box != null:
			button_box.add_theme_constant_override("separation", 8 if avail_w < 560.0 else 16)
		for btn in [retry_button, change_cargo_button, title_button, next_mission_button]:
			if btn != null:
				btn.custom_minimum_size = Vector2(min_btn_w, 64.0)
				btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _on_retry_pressed() -> void:
	_play_audio("ui_confirm")
	retry_pressed.emit()

func _on_change_cargo_pressed() -> void:
	_play_audio("ui_click")
	change_cargo_pressed.emit()

func _on_title_pressed() -> void:
	_play_audio("ui_click")
	title_pressed.emit()

func _on_next_mission_pressed() -> void:
	_play_audio("ui_confirm")
	next_mission_pressed.emit()

func _on_certificate_pressed() -> void:
	_play_audio("ui_confirm")
	certificate_pressed.emit()

func _on_step_next_pressed() -> void:
	_play_audio("ui_click")
	advance_step()

func _play_audio(sound_name: String) -> void:
	if Audio != null:
		Audio.play(sound_name)

func show_result_with_next(result, seed_val: int = 0, has_next: bool = false) -> void:
	show_result(result, seed_val, has_next)

func _resolve_total_days(result) -> int:
	if result != null:
		if result is Dictionary and int(result.get("total_days", 0)) > 0:
			return int(result.get("total_days", 0))
		elif "total_days" in result and int(result.total_days) > 0:
			return int(result.total_days)
	if GameState != null and GameState.current_mission != null:
		if GameState.current_mission.has_method("get_total_days"):
			return int(GameState.current_mission.get_total_days())
	if Constants != null:
		return int(Constants.v("MISSION_DAYS"))
	return 30

func _apply_static_texts() -> void:
	_ensure_nodes()
	if title_label != null:
		title_label.text = tr("DEBRIEF_TITLE")
	if root_cause_header != null:
		root_cause_header.text = tr("DEBRIEF_ROOT_CAUSE_TITLE")
	if timeline_header != null:
		timeline_header.text = tr("DEBRIEF_TIMELINE_TITLE")
	if fact_title_label != null:
		fact_title_label.text = tr("DEBRIEF_FACT_TITLE")
	if step_next_button != null:
		step_next_button.text = tr("BRIEF_NEXT")
	if certificate_button != null:
		certificate_button.text = tr("DEBRIEF_CERTIFICATE")
	if question_title_label != null:
		question_title_label.text = tr("DEBRIEF_NOW_YOU_KNOW")
	if lesson_title_label != null:
		lesson_title_label.text = tr("DEBRIEF_LEARNED")
	if nasa_now_title_label != null:
		nasa_now_title_label.text = tr("DEBRIEF_NASA_NOW")

func _on_language_changed(_lang: String) -> void:
	_apply_static_texts()
	if _last_result != null:
		_populate_from_last_result(true)

func _resolve_mission_id(result) -> String:
	if result != null:
		if result is Dictionary and not str(result.get("mission_id", "")).is_empty():
			return str(result.get("mission_id", ""))
		elif "mission_id" in result and not str(result.mission_id).is_empty():
			return str(result.mission_id)
	if Settings != null and not Settings.current_mission_id.is_empty():
		return Settings.current_mission_id
	return "M1"

func show_result(result, seed_val: int = 0, has_next: bool = false) -> void:
	_ensure_nodes()
	_init_option_styles()
	_last_result = result
	_mission_seed = seed_val
	_last_has_next = has_next
	_current_mission_id = _resolve_mission_id(result)
	_debrief_step = DebriefStep.RESULT
	_answered_after = false
	_selected_after = -1
	_promoted_rank = ""
	_populate_from_last_result(false)

func _populate_from_last_result(preserve_step: bool) -> void:
	_ensure_nodes()
	_init_option_styles()
	_apply_static_texts()
	var result = _last_result
	var seed_val: int = _mission_seed
	var has_next: bool = _last_has_next

	var outcome: String = "SURVIVED"
	var stars: int = 0
	var total_days: int = _resolve_total_days(result)
	var end_day: int = total_days
	var root_cause_code: String = ""
	var root_cause_values: Dictionary = {}
	var root_cause_text: String = ""
	var cause_chain: Array = []
	var fact_dict: Dictionary = {}

	if result != null:
		if result is Dictionary:
			outcome = str(result.get("outcome", "SURVIVED"))
			stars = int(result.get("stars", 0))
			end_day = int(result.get("end_day", total_days))
			root_cause_code = str(result.get("root_cause_code", result.get("root_cause", "")))
			if result.get("root_cause_values") is Dictionary:
				root_cause_values = result.get("root_cause_values")
			root_cause_text = str(result.get("root_cause_text", ""))
			if result.get("cause_chain") is Array:
				cause_chain = result.get("cause_chain")
			if result.get("fact") is Dictionary:
				fact_dict = result.get("fact")
		else:
			if "outcome" in result:
				outcome = str(result.outcome)
			if "stars" in result:
				stars = int(result.stars)
			if "end_day" in result:
				end_day = int(result.end_day)
			if "root_cause_code" in result:
				root_cause_code = str(result.root_cause_code)
			if "root_cause_values" in result and result.root_cause_values is Dictionary:
				root_cause_values = result.root_cause_values
			if "root_cause_text" in result:
				root_cause_text = str(result.root_cause_text)
			if "cause_chain" in result and result.cause_chain is Array:
				cause_chain = result.cause_chain
			if "fact" in result and result.fact is Dictionary:
				fact_dict = result.fact

	var survived := outcome.to_upper().contains("SURVIVE")
	_survived = survived

	if not preserve_step:
		_question_data = _learning.question(_current_mission_id)
		_nasa_fact_id = _learning.nasa_now_fact_id(_current_mission_id)
		if survived and stars >= 1 and Settings != null:
			_promoted_rank = Settings.promote_after_win(_current_mission_id, stars)
		else:
			_promoted_rank = ""
		_rebuild_question_options()

	# 1. Outcome
	if outcome_label != null:
		var out_text := tr("DEBRIEF_SURVIVED") if survived else tr("DEBRIEF_EVAC")
		outcome_label.text = out_text
		outcome_label.modulate = Color("#44B35A") if survived else Color("#E04848")

	# 2. Stars
	if stars_label != null:
		stars_label.visible = false
		var stars_str := ""
		for i in range(3):
			stars_str += "★ " if i < stars else "☆ "
		stars_label.text = stars_str.strip_edges()
		stars_label.modulate = Color("#F2C14E")
		_update_stars_icons(stars)

	# 3. Days reached
	if days_label != null:
		var raw_days := tr("DEBRIEF_DAY_REACHED")
		if raw_days == "DEBRIEF_DAY_REACHED":
			raw_days = "Completed {days} of {total} days"
		days_label.text = raw_days.format({"days": end_day, "total": total_days})

	# 4. Root cause analysis
	var display_root := _format_root_cause(root_cause_code, root_cause_values, root_cause_text, outcome, stars)
	if reason_label != null:
		reason_label.text = display_root
	if root_cause_panel != null:
		root_cause_panel.visible = not display_root.is_empty()

	# 5. Forced storm disclosure
	var had_storm := _check_had_storm(root_cause_code, outcome, cause_chain, end_day)
	if storm_disclosure_box != null:
		storm_disclosure_box.visible = had_storm
		if had_storm:
			var prob: float = 0.099258
			if Constants != null and Constants.has("SPE_CHANCE_STRONG_MISSION"):
				prob = float(Constants.v("SPE_CHANCE_STRONG_MISSION"))
			var p_percent: int = roundi(prob * 100.0)
			if storm_chance_label != null:
				storm_chance_label.text = tr("DEBRIEF_STORM_CHANCE").format({"p": p_percent})
			if storm_source_tag != null and storm_source_tag.has_method("setup"):
				storm_source_tag.setup("SPE_CHANCE_STRONG_MISSION")

	# 6. Cause chain timeline
	if timeline_section != null:
		timeline_section.visible = not cause_chain.is_empty()
		_populate_timeline(cause_chain)

	# 7. NASA Fact (must skip mission's nasa_now_fact)
	if fact_panel != null:
		if not _nasa_fact_id.is_empty() and str(fact_dict.get("id", "")) == _nasa_fact_id:
			fact_dict = {}
		if fact_dict.is_empty():
			fact_dict = _get_fallback_fact(root_cause_code, outcome, _nasa_fact_id)
		if not fact_dict.is_empty():
			var showed_fact_id: String = str(fact_dict.get("id", ""))
			if not showed_fact_id.is_empty() and Settings != null:
				Settings.collect_card(showed_fact_id)
			fact_panel.visible = true
			if fact_label != null:
				fact_label.text = _learning.text(fact_dict)
			if fact_source_label != null:
				var src_str: String = str(fact_dict.get("source", ""))
				fact_source_label.text = "— " + src_str if not src_str.is_empty() else ""
		else:
			fact_panel.visible = false

	# 8. Seed
	if seed_label != null:
		var raw_seed := tr("DEBRIEF_SEED")
		if raw_seed == "DEBRIEF_SEED":
			raw_seed = "Seed: {seed}"
		seed_label.text = raw_seed.format({"seed": seed_val})

	# 9. Button text translations
	if retry_button != null:
		retry_button.text = tr("DEBRIEF_RETRY")
	if change_cargo_button != null:
		change_cargo_button.text = tr("DEBRIEF_CHANGE_CARGO")
	if title_button != null:
		title_button.text = tr("DEBRIEF_TITLE_BTN")
	if next_mission_button != null:
		next_mission_button.text = tr("DEBRIEF_NEXT_MISSION")
		next_mission_button.visible = has_next and survived
	if certificate_button != null:
		certificate_button.text = tr("DEBRIEF_CERTIFICATE")
		certificate_button.visible = (_current_mission_id == "M4" and survived)

	_refresh_learning_texts()
	_refresh_step_visibility()
	if scroll_container != null:
		scroll_container.scroll_vertical = 0
	visible = true


func _rebuild_question_options() -> void:
	_ensure_nodes()
	if question_options_vbox == null:
		return
	for btn in question_option_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	question_option_buttons.clear()
	for child in question_options_vbox.get_children():
		child.queue_free()
	var options: Variant = _question_data.get("options", [])
	if not (options is Array):
		return
	for i in range(options.size()):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 64)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = _learning.text(options[i])
		btn.pressed.connect(select_after_answer.bind(i))
		question_options_vbox.add_child(btn)
		question_option_buttons.append(btn)


func select_after_answer(idx: int) -> void:
	_ensure_nodes()
	_init_option_styles()
	if _answered_after:
		return
	_selected_after = idx
	_answered_after = true
	if Settings != null:
		Settings.record_after_answer(_current_mission_id, idx)
	var correct_idx: int = int(_question_data.get("correct", 0))
	if idx == correct_idx:
		_play_audio("ui_confirm")
	else:
		_play_audio("ui_click")
	_refresh_learning_texts()
	_refresh_step_visibility()
	call_deferred("_scroll_feedback_into_view")


func _scroll_feedback_into_view() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree != null:
		await tree.process_frame
	_ensure_nodes()
	if scroll_container != null and feedback_panel != null and feedback_panel.visible:
		scroll_container.ensure_control_visible(feedback_panel)
		var vbar := scroll_container.get_v_scroll_bar()
		if vbar != null:
			scroll_container.scroll_vertical = int(vbar.max_value)


func _refresh_learning_texts() -> void:
	_ensure_nodes()
	_init_option_styles()
	if question_prompt_label != null:
		question_prompt_label.text = _learning.text(_question_data.get("text"))
	var options: Variant = _question_data.get("options", [])
	var correct_idx: int = int(_question_data.get("correct", 0))
	for i in range(question_option_buttons.size()):
		var btn: Button = question_option_buttons[i]
		if options is Array and i < options.size():
			btn.text = _learning.text(options[i])
		var style: StyleBoxFlat = _style_opt_normal
		if _answered_after:
			if i == correct_idx:
				style = _style_opt_right
			elif i == _selected_after:
				style = _style_opt_wrong
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

	if feedback_panel != null:
		feedback_panel.visible = _answered_after
	if _answered_after:
		var is_right: bool = (_selected_after == correct_idx)
		if feedback_icon != null:
			feedback_icon.visible = is_right
			feedback_icon.modulate = Color("#44B35A")
		if feedback_mark != null:
			feedback_mark.visible = not is_right
		if feedback_label != null:
			feedback_label.text = tr("DEBRIEF_RIGHT") if is_right else tr("DEBRIEF_WRONG")
			feedback_label.modulate = Color("#44B35A") if is_right else Color("#E04848")
		if explain_label != null:
			explain_label.text = _learning.formatted_text(_question_data.get("explain"))
		if explain_source_tag != null:
			var const_ids: Variant = _question_data.get("constant_ids", [])
			if const_ids is Array and not const_ids.is_empty():
				explain_source_tag.setup(str(const_ids[0]))
			else:
				explain_source_tag.setup("")
		if you_guessed_label != null:
			var before_idx: int = Settings.get_before_answer(_current_mission_id) if Settings != null else -1
			if before_idx >= 0 and options is Array and before_idx < options.size():
				you_guessed_label.visible = true
				you_guessed_label.text = tr("DEBRIEF_YOU_GUESSED").format({"answer": _learning.text(options[before_idx])})
			else:
				you_guessed_label.visible = false

	if lesson_body_label != null:
		lesson_body_label.text = _learning.formatted_text(_learning.lesson(_current_mission_id))

	var nasa_fact: Dictionary = _learning.nasa_now_fact(_current_mission_id)
	if nasa_now_body_label != null:
		nasa_now_body_label.text = _learning.text(nasa_fact)
	if nasa_now_source_tag != null:
		if not nasa_fact.is_empty():
			nasa_now_source_tag.setup_fact(nasa_fact)
		else:
			nasa_now_source_tag.setup("")

	if rank_up_label != null and not _promoted_rank.is_empty():
		rank_up_label.text = tr("DEBRIEF_NEW_RANK").format({"rank": _learning.rank_name(_promoted_rank)})
	_refresh_new_cards_row()


func is_final_step() -> bool:
	if _debrief_step == DebriefStep.RANK_UP:
		return true
	if _debrief_step == DebriefStep.NASA_NOW and _promoted_rank.is_empty():
		return true
	return false


func advance_step() -> void:
	match _debrief_step:
		DebriefStep.RESULT:
			_debrief_step = DebriefStep.QUESTION if not _question_data.is_empty() else DebriefStep.LESSON
		DebriefStep.QUESTION:
			if not _answered_after:
				return
			_debrief_step = DebriefStep.LESSON
		DebriefStep.LESSON:
			_debrief_step = DebriefStep.NASA_NOW
			if not _nasa_fact_id.is_empty() and Settings != null:
				Settings.collect_card(_nasa_fact_id)
		DebriefStep.NASA_NOW:
			if not _promoted_rank.is_empty():
				_debrief_step = DebriefStep.RANK_UP
				_play_audio("ui_confirm")
				_play_rank_celebration()
		_:
			pass
	if scroll_container != null:
		scroll_container.scroll_vertical = 0
	_refresh_step_visibility()


func _refresh_step_visibility() -> void:
	_ensure_nodes()
	var is_res: bool = (_debrief_step == DebriefStep.RESULT)
	if root_cause_panel != null:
		root_cause_panel.visible = is_res and not reason_label.text.is_empty()
	if storm_disclosure_box != null:
		storm_disclosure_box.visible = is_res and _check_had_storm_from_last()
	if timeline_section != null:
		timeline_section.visible = is_res and timeline_vbox != null and timeline_vbox.get_child_count() > 0
	if fact_panel != null:
		fact_panel.visible = is_res and fact_label != null and not fact_label.text.is_empty()

	if question_section != null:
		question_section.visible = (_debrief_step == DebriefStep.QUESTION)
	if lesson_section != null:
		lesson_section.visible = (_debrief_step == DebriefStep.LESSON)
	if nasa_now_section != null:
		nasa_now_section.visible = (_debrief_step == DebriefStep.NASA_NOW)
	if rank_up_section != null:
		rank_up_section.visible = (_debrief_step == DebriefStep.RANK_UP)

	var at_end: bool = is_final_step()
	if step_footer != null:
		step_footer.visible = not at_end
	if step_next_button != null:
		step_next_button.disabled = (_debrief_step == DebriefStep.QUESTION and not _answered_after)
	if button_box != null:
		button_box.visible = at_end
	if cert_row != null:
		cert_row.visible = at_end and (_current_mission_id == "M4" and _survived)
	_refresh_new_cards_row()
	if new_cards_button != null:
		new_cards_button.visible = at_end
	if scroll_container != null:
		scroll_container.scroll_vertical = 0


func _check_had_storm_from_last() -> bool:
	if _last_result == null:
		return false
	var root_code := ""
	var outcome := ""
	var chain: Array = []
	var end_day := 0
	if _last_result is Dictionary:
		root_code = str(_last_result.get("root_cause_code", _last_result.get("root_cause", "")))
		outcome = str(_last_result.get("outcome", ""))
		if _last_result.get("cause_chain") is Array:
			chain = _last_result.get("cause_chain")
		end_day = int(_last_result.get("end_day", 0))
	else:
		if "root_cause_code" in _last_result:
			root_code = str(_last_result.root_cause_code)
		if "outcome" in _last_result:
			outcome = str(_last_result.outcome)
		if "cause_chain" in _last_result and _last_result.cause_chain is Array:
			chain = _last_result.cause_chain
		if "end_day" in _last_result:
			end_day = int(_last_result.end_day)
	return _check_had_storm(root_code, outcome, chain, end_day)


func _play_rank_celebration() -> void:
	if rank_star_icon == null or not is_inside_tree():
		return
	rank_star_icon.pivot_offset = rank_star_icon.custom_minimum_size * 0.5
	rank_star_icon.scale = Vector2(0.5, 0.5)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(rank_star_icon, "scale", Vector2(1.15, 1.15), 0.28)
	tw.tween_property(rank_star_icon, "scale", Vector2(1.0, 1.0), 0.14)

func _format_root_cause(
	code: String,
	values: Dictionary,
	fallback_text: String,
	outcome: String,
	stars: int
) -> String:
	match code:
		"ROOT_NIGHT_ENERGY":
			var have_val = values.get("have", 0)
			var need_val = values.get("need", 0)
			return tr("ROOT_NIGHT_ENERGY").format({
				"have": roundi(float(have_val)),
				"need": roundi(float(need_val))
			})
		"ROOT_SHIELD":
			var g_val: float = float(values.get("g", 0.0))
			var g_needed_val: float = float(values.get("g_needed", 0.0))
			var limit_val: float = float(values.get("limit", 250.0))
			return tr("ROOT_SHIELD").format({
				"g": "%.1f" % g_val,
				"g_needed": "%.1f" % g_needed_val,
				"limit": roundi(limit_val)
			})
		"ROOT_REPAIR":
			var d_val = values.get("d", 0)
			return tr("ROOT_REPAIR").format({"d": d_val})
		"ROOT_SUPPLY":
			var packed_val = values.get("packed", 0)
			var used_val = values.get("used", 0)
			var item_val: String = str(values.get("item", ""))
			var item_display: String = item_val
			var item_key := "PACK_ITEM_" + item_val.to_upper()
			if tr(item_key) != item_key:
				item_display = tr(item_key)
			return tr("ROOT_SUPPLY").format({
				"packed": roundi(float(packed_val)),
				"used": roundi(float(used_val)),
				"item": item_display
			})
		"ROOT_SUCCESS":
			var s: int = int(values.get("stars", stars))
			var sick: bool = bool(values.get("ever_sick", false))
			var tired: bool = bool(values.get("ever_tired", false))
			var co2_sick: bool = bool(values.get("co2_sick", sick and not tired))
			var sci: int = int(values.get("science_points", 0))
			var goal: int = int(values.get("science_goal", 10))
			if s >= 3:
				return tr("ROOT_SUCCESS_3")
			elif s == 2:
				if tired and not co2_sick:
					return tr("ROOT_SUCCESS_2_TIRED").format({"name": _resolve_crew_names(values)})
				elif sick:
					return tr("ROOT_SUCCESS_2_SICK")
				else:
					return tr("ROOT_SUCCESS_2_SCI").format({"science": sci, "goal": goal})
			else:
				return tr("ROOT_SUCCESS_1").format({"science": sci, "goal": goal})
		_:
			if not fallback_text.is_empty():
				return fallback_text
			if outcome == "SURVIVED":
				if stars >= 3:
					return tr("ROOT_SUCCESS_3")
				else:
					return tr("ROOT_SUCCESS_2_SCI").format({"science": 0, "goal": 10})
			if not code.is_empty() and tr(code) != code:
				return tr(code)
			return code

func _check_had_storm(root_code: String, outcome: String, chain: Array, end_day: int) -> bool:
	if root_code == "ROOT_SHIELD" or outcome == "EVAC_RADIATION":
		return true
	for entry in chain:
		var code: String = str(entry.get("code", ""))
		if code.begins_with("STORM"):
			return true
	if GameState != null and GameState.current_mission != null:
		var ev = GameState.current_mission.events
		if ev != null and ev.has_method("has_storm"):
			return ev.has_storm() and end_day >= ev.storm_day
		return false
	var c_sim = Constants.sim if Constants and "sim" in Constants else null
	if c_sim != null and c_sim.has("STORM_GUARANTEED"):
		if int(c_sim.v("STORM_GUARANTEED")) == 1 and end_day >= 10:
			return true
	return false

func _populate_timeline(chain: Array) -> void:
	if timeline_vbox == null:
		return
	for child in timeline_vbox.get_children():
		child.queue_free()

	for entry in chain:
		var day: int = int(entry.get("day", 0))
		var code: String = str(entry.get("code", ""))
		var vals: Dictionary = entry.get("values", {}) if entry.get("values") is Dictionary else {}

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		# Day Badge
		var day_lbl := Label.new()
		var raw_day_fmt := tr("DEBRIEF_CHAIN_DAY")
		if raw_day_fmt == "DEBRIEF_CHAIN_DAY":
			raw_day_fmt = "Day {day}"
		day_lbl.text = raw_day_fmt.format({"day": day})
		day_lbl.custom_minimum_size = Vector2(65, 0)
		day_lbl.add_theme_color_override("font_color", Color("#9AA3B2"))
		day_lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(day_lbl)

		# Icon
		var icon_path: String = ICON_MAP.get(code, "res://assets/icons/info.svg")
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(22, 22)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
		if code.begins_with("EVAC"):
			icon_rect.modulate = Color("#E04848")
		elif code in ["SUNSET", "BLACKOUT", "POWER_SHED"]:
			icon_rect.modulate = Color("#F2C14E")
		else:
			icon_rect.modulate = Color("#E9E7E2")
		row.add_child(icon_rect)

		# Text
		var desc_lbl := Label.new()
		desc_lbl.text = _format_chain_entry(day, code, vals)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.add_theme_font_size_override("font_size", 15)
		desc_lbl.add_theme_color_override("font_color", Color("#F3F4F6"))
		row.add_child(desc_lbl)

		timeline_vbox.add_child(row)

func _format_chain_entry(day: int, code: String, values: Dictionary) -> String:
	match code:
		"SUNSET":
			return tr("CHAIN_SUNSET").format({"day": day})
		"STORM_WARNING":
			var warn_min = values.get("warning_min", 60)
			return tr("CHAIN_STORM_WARN").format({"day": day, "min": warn_min})
		"BLACKOUT":
			return tr("CHAIN_BLACKOUT").format({"day": day})
		"POWER_SHED":
			return tr("CHAIN_POWER_SHED").format({"day": day})
		"CO2_HIGH":
			var co2_val = values.get("co2", 0)
			return tr("CHAIN_CO2_HIGH").format({"day": day, "co2": "%.1f" % float(co2_val)})
		"CREW_SICK":
			return tr("CHAIN_CREW_SICK").format({"day": day})
		"CREW_TIRED":
			return tr("LOG_CREW_TIRED").format({"name": _resolve_crew_names(values)})
		"RECYCLER_BROKE":
			return tr("CHAIN_RECYCLER_BROKE").format({"day": day})
		"METEOROID":
			return tr("CHAIN_METEOROID").format({"day": day})
		"DUST_HIGH":
			return tr("CHAIN_DUST_HIGH").format({"day": day})
		"FOOD_SPOILED":
			return tr("CHAIN_FOOD_SPOILED").format({"day": day})
		"PLANTS_DIED":
			return tr("CHAIN_PLANTS_DIED").format({"day": day})
		"SUPPLY_LOW":
			var item = str(values.get("item", ""))
			return tr("CHAIN_SUPPLY_LOW").format({"day": day, "item": item})
		"EVAC_CO2":
			return tr("CHAIN_EVAC_CO2").format({"day": day})
		"EVAC_O2":
			return tr("CHAIN_EVAC_O2").format({"day": day})
		"EVAC_WATER":
			return tr("CHAIN_EVAC_WATER").format({"day": day})
		"EVAC_FOOD":
			return tr("CHAIN_EVAC_FOOD").format({"day": day})
		"EVAC_RADIATION":
			return tr("CHAIN_EVAC_RADIATION").format({"day": day})
		_:
			var key = "CHAIN_" + code
			if tr(key) != key:
				return tr(key).format({"day": day})
			return "Day %d: %s" % [day, code.replace("_", " ").capitalize()]

func _get_fallback_fact(root_code: String, outcome: String, exclude_id: String = "") -> Dictionary:
	var facts: Array = _learning.all_facts()
	if facts.is_empty():
		return {}
	var target_tag := ""
	match root_code:
		"ROOT_NIGHT_ENERGY": target_tag = "night"
		"ROOT_SHIELD": target_tag = "storm"
		"ROOT_REPAIR": target_tag = "water"
		"ROOT_SUPPLY":
			if outcome == "EVAC_WATER": target_tag = "water"
			elif outcome in ["EVAC_O2", "EVAC_CO2"]: target_tag = "oxygen"
			elif outcome == "EVAC_FOOD": target_tag = "food"
	if not target_tag.is_empty():
		for f in facts:
			if f is Dictionary and str(f.get("id", "")) != exclude_id and f.has("tags") and target_tag in f["tags"]:
				return f
	for f in facts:
		if f is Dictionary and str(f.get("id", "")) != exclude_id:
			return f
	return {}

func _resolve_crew_names(values: Dictionary) -> String:
	var indices_val = values.get("crew_indices", [])
	if indices_val is Array and not indices_val.is_empty():
		var parts: Array[String] = []
		for idx_v in indices_val:
			parts.append(Astronaut.crew_name_for(int(idx_v)))
		return ", ".join(parts)
	if values.has("crew_index"):
		return Astronaut.crew_name_for(int(values["crew_index"]))
	var fallback_name: String = str(values.get("name", ""))
	return fallback_name if not fallback_name.is_empty() else "Crew"

func _update_stars_icons(stars: int) -> void:
	if stars_label == null:
		return
	if _stars_row == null:
		var parent_box := stars_label.get_parent()
		if parent_box == null:
			return
		_stars_row = HBoxContainer.new()
		_stars_row.name = "StarsRow"
		_stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_stars_row.add_theme_constant_override("separation", 10)
		for _i in range(3):
			var star_icon := TextureRect.new()
			star_icon.custom_minimum_size = Vector2(28, 28)
			star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			star_icon.texture = ICON_STAR
			star_icon.modulate = STAR_EMPTY_COLOR
			_stars_row.add_child(star_icon)
		parent_box.add_child(_stars_row)
		parent_box.move_child(_stars_row, stars_label.get_index() + 1)
	var children := _stars_row.get_children()
	for i in range(mini(3, children.size())):
		var icon_node := children[i] as TextureRect
		if icon_node != null:
			icon_node.modulate = UIColors.POWER if i < stars else STAR_EMPTY_COLOR


func _ensure_new_cards_ui() -> void:
	if new_cards_button != null:
		return
	if cert_row == null:
		return
	var parent_vbox := cert_row.get_parent()
	if parent_vbox == null:
		return

	new_cards_button = Button.new()
	new_cards_button.name = "NewCardsButton"
	new_cards_button.custom_minimum_size = Vector2(0, 64)
	new_cards_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_cards_button.focus_mode = Control.FOCUS_NONE
	new_cards_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	new_cards_button.visible = false

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.13, 0.21, 0.94)
	sb.border_color = UIColors.WATER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.13, 0.19, 0.30, 0.98)
	new_cards_button.add_theme_stylebox_override("normal", sb)
	new_cards_button.add_theme_stylebox_override("hover", sb_hover)
	new_cards_button.add_theme_stylebox_override("pressed", sb_hover)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	new_cards_button.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	new_cards_label = Label.new()
	new_cards_label.name = "NewCardsLabel"
	new_cards_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_cards_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	new_cards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_cards_label.add_theme_font_size_override("font_size", 18)
	new_cards_label.add_theme_color_override("font_color", UIColors.TEXT)
	new_cards_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(new_cards_label)

	new_cards_icons = HBoxContainer.new()
	new_cards_icons.name = "NewCardsIcons"
	new_cards_icons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	new_cards_icons.add_theme_constant_override("separation", 6)
	new_cards_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(new_cards_icons)

	new_cards_button.pressed.connect(_on_new_cards_pressed)
	parent_vbox.add_child(new_cards_button)
	parent_vbox.move_child(new_cards_button, cert_row.get_index())
	_refresh_new_cards_row()


func _refresh_new_cards_row() -> void:
	if new_cards_button == null:
		return
	var mission_cards: Array[String] = Settings.mission_collected_cards if Settings != null else []
	if new_cards_label != null:
		new_cards_label.text = tr("DEBRIEF_NEW_CARDS").format({"n": mission_cards.size()})
	if new_cards_icons != null:
		for child in new_cards_icons.get_children():
			new_cards_icons.remove_child(child)
			child.queue_free()
		var max_icons: int = mini(6, mission_cards.size())
		for i in range(max_icons):
			var fid: String = mission_cards[i]
			var card: Dictionary = _learning.card_by_fact_id(fid)
			var cat: String = str(card.get("category", "moon"))
			var col: Color = LearningDataScript.category_color(cat)

			var badge := PanelContainer.new()
			badge.custom_minimum_size = Vector2(30, 30)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var bstyle := StyleBoxFlat.new()
			bstyle.bg_color = col.darkened(0.65)
			bstyle.border_color = col
			bstyle.set_border_width_all(1)
			bstyle.set_corner_radius_all(6)
			bstyle.set_content_margin_all(4)
			badge.add_theme_stylebox_override("panel", bstyle)

			var tex := TextureRect.new()
			tex.custom_minimum_size = Vector2(20, 20)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.texture = LearningDataScript.card_icon(card)
			tex.modulate = col
			tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.add_child(tex)
			new_cards_icons.add_child(badge)

		if mission_cards.size() > max_icons:
			var extra_lbl := Label.new()
			extra_lbl.text = "+%d" % (mission_cards.size() - max_icons)
			extra_lbl.add_theme_font_size_override("font_size", 15)
			extra_lbl.add_theme_color_override("font_color", UIColors.POWER)
			extra_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			new_cards_icons.add_child(extra_lbl)


func open_card_album() -> void:
	if _card_album == null:
		_card_album = CardAlbumScene.instantiate()
		add_child(_card_album)
	if _card_album != null and _card_album.has_method("open_album"):
		_card_album.call("open_album")


func _on_new_cards_pressed() -> void:
	_play_audio("ui_click")
	open_card_album()


func _on_card_collected(_fid: String) -> void:
	_refresh_new_cards_row()

func can_translate(key: String) -> bool:
	return tr(key) != key
