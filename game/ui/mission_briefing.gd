class_name MissionBriefing
extends Control

signal completed

const SafeArea := preload("res://ui/safe_area.gd")

var safe_margin: MarginContainer
var card_panel: PanelContainer
var control_label: Label
var mission_label: Label
var skip_button: Button
var step_scroll: ScrollContainer
var card_section: VBoxContainer
var badge_row: HBoxContainer
var fact_badge: Label
var card_source_tag: SourceTag
var card_title_label: Label
var card_body_label: Label
var guess_section: VBoxContainer
var guess_title_label: Label
var question_label: Label
var options_vbox: VBoxContainer
var hint_label: Label
var progress_label: Label
var next_button: Button
var go_button: Button

var option_buttons: Array[Button] = []

var _learning: LearningData = LearningData.new()
var _mission_id: String = "M1"
var _cards: Array = []
var _question: Dictionary = {}
var _step: int = 0
var _is_replay: bool = false
var _selected_guess: int = -1

var _style_opt_normal: StyleBoxFlat
var _style_opt_selected: StyleBoxFlat


func _ensure_nodes() -> void:
	if safe_margin != null:
		return
	safe_margin = get_node_or_null("SafeMargin")
	card_panel = get_node_or_null("SafeMargin/CenterContainer/CardPanel")
	control_label = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/Header/HeaderLabels/ControlLabel")
	mission_label = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/Header/HeaderLabels/MissionLabel")
	skip_button = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/Header/SkipButton")
	step_scroll = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll")
	card_section = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/CardSection")
	badge_row = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/CardSection/BadgeRow")
	fact_badge = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/CardSection/BadgeRow/FactBadge")
	card_source_tag = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/CardSection/BadgeRow/CardSourceTag")
	card_title_label = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/CardSection/CardTitleLabel")
	card_body_label = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/CardSection/CardBodyLabel")
	guess_section = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/GuessSection")
	guess_title_label = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/GuessSection/GuessTitleLabel")
	question_label = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/GuessSection/QuestionLabel")
	options_vbox = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/GuessSection/OptionsVBox")
	hint_label = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/StepScroll/ContentVBox/GuessSection/HintLabel")
	progress_label = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/FooterRow/ProgressLabel")
	next_button = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/FooterRow/NextButton")
	go_button = get_node_or_null("SafeMargin/CenterContainer/CardPanel/CardMargin/RootVBox/FooterRow/GoButton")


func _init_styles() -> void:
	if _style_opt_normal != null:
		return
	_style_opt_normal = StyleBoxFlat.new()
	_style_opt_normal.bg_color = Color(0.11, 0.145, 0.215, 0.96)
	_style_opt_normal.border_color = Color(0.28, 0.36, 0.50, 0.85)
	_style_opt_normal.set_border_width_all(2)
	_style_opt_normal.set_corner_radius_all(8)
	_style_opt_normal.set_content_margin_all(12)

	_style_opt_selected = StyleBoxFlat.new()
	_style_opt_selected.bg_color = Color(0.15, 0.28, 0.46, 0.98)
	_style_opt_selected.border_color = Color(0.45, 0.72, 1.0, 1.0)
	_style_opt_selected.set_border_width_all(2)
	_style_opt_selected.set_corner_radius_all(8)
	_style_opt_selected.set_content_margin_all(12)


func _ready() -> void:
	_ensure_nodes()
	_init_styles()
	if skip_button != null and not skip_button.pressed.is_connected(_on_skip_pressed):
		skip_button.pressed.connect(_on_skip_pressed)
	if next_button != null and not next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.connect(_on_next_pressed)
	if go_button != null and not go_button.pressed.is_connected(_on_go_pressed):
		go_button.pressed.connect(_on_go_pressed)
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)
	SafeArea.connect_resize(self, _update_layout)
	_update_layout()


func _update_layout() -> void:
	_ensure_nodes()
	if not is_inside_tree() or safe_margin == null or card_panel == null:
		return
	var insets := SafeArea.get_insets(self)
	safe_margin.add_theme_constant_override("margin_left", 16 + int(insets["left"]))
	safe_margin.add_theme_constant_override("margin_right", 16 + int(insets["right"]))
	safe_margin.add_theme_constant_override("margin_top", 16 + int(insets["top"]))
	safe_margin.add_theme_constant_override("margin_bottom", 16 + int(insets["bottom"]))

	var vp_size := get_viewport_rect().size
	var avail_w: float = maxf(280.0, vp_size.x - float(insets["left"]) - float(insets["right"]) - 32.0)
	var avail_h: float = maxf(240.0, vp_size.y - float(insets["top"]) - float(insets["bottom"]) - 32.0)
	var is_portrait: bool = vp_size.y > vp_size.x
	var panel_w: float = minf(1040.0, avail_w - 48.0) if is_portrait else minf(640.0, avail_w)
	card_panel.custom_minimum_size = Vector2(panel_w, 0.0)
	if step_scroll != null:
		var max_scroll_h: float = clampf(avail_h * 0.24, 220.0, 520.0) if is_portrait else clampf(avail_h - 170.0, 140.0, 420.0)
		step_scroll.custom_minimum_size = Vector2(0.0, max_scroll_h)


func start_briefing(mission_id: String) -> void:
	_ensure_nodes()
	_init_styles()
	_mission_id = mission_id
	_cards = _learning.briefing(_mission_id)
	_question = _learning.question(_mission_id)
	_is_replay = Settings != null and Settings.has_before_answer(_mission_id)
	_step = 0
	_selected_guess = -1
	_rebuild_option_buttons()
	_render_step()
	_update_layout()


func _rebuild_option_buttons() -> void:
	_ensure_nodes()
	if options_vbox == null:
		return
	for btn in option_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	option_buttons.clear()
	for child in options_vbox.get_children():
		child.queue_free()

	var options: Variant = _question.get("options", [])
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
		btn.pressed.connect(_on_option_pressed.bind(i))
		options_vbox.add_child(btn)
		option_buttons.append(btn)


func _render_step() -> void:
	_ensure_nodes()
	_init_styles()
	if control_label != null:
		control_label.text = _learning.mission_control_name()
	if mission_label != null:
		mission_label.text = _mission_title_text(_mission_id)
	if skip_button != null:
		skip_button.visible = _is_replay
		skip_button.text = tr("BRIEF_SKIP")
	if fact_badge != null:
		fact_badge.text = tr("BRIEF_FACT_BADGE")
	if next_button != null:
		next_button.text = tr("BRIEF_NEXT")
	if go_button != null:
		go_button.text = tr("BRIEF_GO")

	var card_count: int = _cards.size()
	var total_steps: int = card_count if _is_replay else card_count + 1
	if total_steps <= 0:
		total_steps = 1
	if progress_label != null:
		progress_label.text = "%d / %d" % [mini(_step + 1, total_steps), total_steps]

	if _step < card_count:
		if card_section != null:
			card_section.visible = true
		if guess_section != null:
			guess_section.visible = false
		_render_card(_step)
		var is_last_on_replay: bool = _is_replay and _step == card_count - 1
		if next_button != null:
			next_button.visible = not is_last_on_replay
		if go_button != null:
			go_button.visible = is_last_on_replay
			go_button.disabled = false
	else:
		if card_section != null:
			card_section.visible = false
		if guess_section != null:
			guess_section.visible = true
		_render_guess()
		if next_button != null:
			next_button.visible = false
		if go_button != null:
			go_button.visible = true
			go_button.disabled = _selected_guess < 0

	if step_scroll != null:
		step_scroll.scroll_vertical = 0


func _render_card(index: int) -> void:
	var raw_card: Variant = _cards[index] if index >= 0 and index < _cards.size() else {}
	var card: Dictionary = raw_card if raw_card is Dictionary else {}
	var title_text: String = _learning.text(card.get("title"))
	if card_title_label != null:
		card_title_label.visible = not title_text.is_empty()
		card_title_label.text = title_text

	var fact_id: String = ""
	var raw_fid: Variant = card.get("fact_id", null)
	if raw_fid != null:
		fact_id = str(raw_fid)

	if not fact_id.is_empty():
		var fact_dict: Dictionary = _learning.fact(fact_id)
		if badge_row != null:
			badge_row.visible = true
		if card_source_tag != null:
			card_source_tag.setup_fact(fact_dict)
		if card_body_label != null:
			card_body_label.text = _learning.text(fact_dict)
		if Settings != null:
			Settings.collect_card(fact_id)
	else:
		if badge_row != null:
			badge_row.visible = false
		if card_body_label != null:
			card_body_label.text = _learning.formatted_text(card.get("text"))


func _render_guess() -> void:
	if guess_title_label != null:
		guess_title_label.text = tr("GUESS_TITLE")
	if question_label != null:
		question_label.text = _learning.text(_question.get("text"))
	if hint_label != null:
		hint_label.text = tr("GUESS_HINT")

	var options: Variant = _question.get("options", [])
	for i in range(option_buttons.size()):
		var btn: Button = option_buttons[i]
		if options is Array and i < options.size():
			btn.text = _learning.text(options[i])
		var style: StyleBoxFlat = _style_opt_selected if i == _selected_guess else _style_opt_normal
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)


func _on_option_pressed(idx: int) -> void:
	_play_audio("ui_click")
	_selected_guess = idx
	_render_guess()
	if go_button != null:
		go_button.disabled = false


func _on_next_pressed() -> void:
	_play_audio("ui_click")
	_step += 1
	if _is_replay and _step >= _cards.size():
		completed.emit()
		return
	_render_step()


func _on_go_pressed() -> void:
	if not _is_replay and _step >= _cards.size():
		if _selected_guess < 0:
			return
		if Settings != null:
			Settings.record_before_answer(_mission_id, _selected_guess)
	_play_audio("ui_confirm")
	completed.emit()


func _on_skip_pressed() -> void:
	_play_audio("ui_click")
	completed.emit()


func _on_language_changed(_lang: String) -> void:
	_render_step()


func _mission_title_text(mid: String) -> String:
	var key: String = "MAP_%s_TITLE" % mid
	var translated: String = tr(key)
	if translated != key:
		return translated
	return mid


func _play_audio(sound_name: String) -> void:
	if Audio != null:
		Audio.play(sound_name)

