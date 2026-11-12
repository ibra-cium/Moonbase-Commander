class_name TutorialOverlay
extends CanvasLayer

signal step_acknowledged(step_num: int)
signal tutorial_finished
signal tutorial_skipped
signal hint_closed(hint_id: String)

const BATTERY_LOW_HINT_PERCENT: float = 30.0
const TOTAL_STEPS: int = 4
const PANEL_WIDTH_DEFAULT: float = 580.0
const PANEL_WIDTH_TASKS: float = 760.0
const BODY_SIZE_DEFAULT := Vector2(536.0, 56.0)
const BODY_SIZE_TASKS := Vector2(716.0, 32.0)

const SimMissionsScript := preload("res://sim/sim_missions.gd")
const SimPlanScript := preload("res://sim/sim_plan.gd")

const ICON_ROCKET: Texture2D = preload("res://assets/icons/rocket_launch.svg")
const ICON_CONSTRUCTION: Texture2D = preload("res://assets/icons/construction.svg")
const ICON_NIGHT: Texture2D = preload("res://assets/icons/nightlight.svg")
const ICON_BOLT: Texture2D = preload("res://assets/icons/bolt.svg")
const ICON_CO2: Texture2D = preload("res://assets/icons/co2.svg")
const ICON_INFO: Texture2D = preload("res://assets/icons/info.svg")
const ICON_BEDTIME: Texture2D = preload("res://assets/icons/bedtime.svg")
const ICON_CLEAN: Texture2D = preload("res://assets/icons/cleaning_services.svg")
const ICON_ECO: Texture2D = preload("res://assets/icons/eco.svg")
const ICON_LANDSCAPE: Texture2D = preload("res://assets/icons/landscape.svg")
const ICON_SCIENCE: Texture2D = preload("res://assets/icons/science.svg")

const TASK_CARD_DEFS: Array = [
	{
		"job": SimPlanScript.JOB_REST,
		"title_key": "JOB_REST",
		"desc_key": "TUT_TASK_REST_DESC",
		"icon": ICON_BEDTIME,
		"color": UIColors.MODULE,
	},
	{
		"job": SimPlanScript.JOB_REPAIR,
		"title_key": "JOB_REPAIR",
		"desc_key": "TUT_TASK_REPAIR_DESC",
		"icon": ICON_CONSTRUCTION,
		"color": UIColors.ALERT,
	},
	{
		"job": SimPlanScript.JOB_CLEAN,
		"title_key": "JOB_CLEAN",
		"desc_key": "TUT_TASK_CLEAN_DESC",
		"icon": ICON_CLEAN,
		"color": UIColors.POWER,
	},
	{
		"job": SimPlanScript.JOB_FARM,
		"title_key": "JOB_FARM",
		"desc_key": "TUT_TASK_FARM_DESC",
		"icon": ICON_ECO,
		"color": UIColors.OXYGEN,
	},
	{
		"job": SimPlanScript.JOB_REGOLITH,
		"title_key": "JOB_REGOLITH",
		"desc_key": "TUT_TASK_REGOLITH_DESC",
		"icon": ICON_LANDSCAPE,
		"color": UIColors.REGOLITH,
	},
	{
		"job": SimPlanScript.JOB_SCIENCE,
		"title_key": "JOB_SCIENCE",
		"desc_key": "TUT_TASK_SCIENCE_DESC",
		"icon": ICON_SCIENCE,
		"color": UIColors.WATER,
	},
]

enum Mode {
	NONE,
	STEP,
	HINT
}

var backdrop: ColorRect
var panel: PanelContainer
var icon_rect: TextureRect
var title_label: Label
var badge_label: Label
var body_label: Label
var tasks_grid: GridContainer
var skip_button: Button
var primary_button: Button

var task_rows: Array[Dictionary] = []
var current_mode: Mode = Mode.NONE
var current_step: int = 0
var current_hint_id: String = ""

func _ensure_nodes() -> void:
	if primary_button != null:
		return
	backdrop = get_node_or_null("Backdrop")
	panel = get_node_or_null("Center/Panel")
	icon_rect = get_node_or_null("Center/Panel/Margin/VBox/Header/IconRect")
	title_label = get_node_or_null("Center/Panel/Margin/VBox/Header/TitleLabel")
	badge_label = get_node_or_null("Center/Panel/Margin/VBox/Header/BadgeLabel")
	body_label = get_node_or_null("Center/Panel/Margin/VBox/BodyLabel")
	tasks_grid = get_node_or_null("Center/Panel/Margin/VBox/TasksGrid")
	skip_button = get_node_or_null("Center/Panel/Margin/VBox/ButtonBox/SkipButton")
	primary_button = get_node_or_null("Center/Panel/Margin/VBox/ButtonBox/PrimaryButton")
	if tasks_grid != null and task_rows.is_empty():
		_build_tasks_grid()
	if skip_button != null and not skip_button.pressed.is_connected(_on_skip_pressed):
		skip_button.pressed.connect(_on_skip_pressed)
	if primary_button != null and not primary_button.pressed.is_connected(_on_primary_pressed):
		primary_button.pressed.connect(_on_primary_pressed)
	if Settings != null and Settings.has_signal("language_changed"):
		if not Settings.language_changed.is_connected(_on_language_changed):
			Settings.language_changed.connect(_on_language_changed)

func _ready() -> void:
	_ensure_nodes()
	visible = false

func show_step(step_num: int) -> void:
	_ensure_nodes()
	current_mode = Mode.STEP
	current_step = clampi(step_num, 1, TOTAL_STEPS)
	current_hint_id = ""
	_refresh_content()
	visible = true

func show_hint(hint_id: String) -> void:
	_ensure_nodes()
	current_mode = Mode.HINT
	current_step = 0
	current_hint_id = hint_id
	_refresh_content()
	visible = true

func hide_overlay() -> void:
	current_mode = Mode.NONE
	current_step = 0
	current_hint_id = ""
	visible = false

func _refresh_content() -> void:
	_ensure_nodes()
	if current_mode == Mode.STEP:
		_render_step(current_step)
	elif current_mode == Mode.HINT:
		_render_hint(current_hint_id)

func _set_header(icon_tex: Texture2D, icon_color: Color, title_text: String) -> void:
	if icon_rect != null:
		icon_rect.texture = icon_tex
		icon_rect.modulate = icon_color
	if title_label != null:
		title_label.text = title_text

func _set_tasks_layout(show_tasks: bool) -> void:
	if tasks_grid != null:
		tasks_grid.visible = show_tasks
	if panel != null:
		panel.custom_minimum_size.x = PANEL_WIDTH_TASKS if show_tasks else PANEL_WIDTH_DEFAULT
	if body_label != null:
		body_label.custom_minimum_size = BODY_SIZE_TASKS if show_tasks else BODY_SIZE_DEFAULT

func _const_float(id: String, fallback: float, mc: RefCounted = null) -> float:
	if mc != null:
		return float(mc.v(id))
	if Constants != null:
		return float(Constants.v(id))
	return fallback

func _format_number(val: float) -> String:
	return str(int(val)) if is_equal_approx(val, roundf(val)) else ("%.1f" % val)

func _get_mission_sim_constants() -> RefCounted:
	if Constants != null and Constants.sim != null and Settings != null:
		var sm: RefCounted = SimMissionsScript.new(Constants.sim)
		return sm.get_sim_constants(Settings.current_mission_id)
	return null

func _build_tasks_grid() -> void:
	task_rows.clear()
	for child in tasks_grid.get_children():
		child.queue_free()
	for entry in TASK_CARD_DEFS:
		var row: Dictionary = _create_task_card(entry)
		tasks_grid.add_child(row["card"])
		task_rows.append(row)

func _create_task_card(entry: Dictionary) -> Dictionary:
	var accent: Color = entry["color"]
	var card := PanelContainer.new()
	card.name = "TaskCard_" + str(entry["job"])
	card.custom_minimum_size = Vector2(336.0, 0.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0706, 0.0824, 0.1176, 0.85)
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.6)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_top = 8.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 8.0
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(28.0, 28.0)
	tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tex.texture = entry["icon"]
	tex.modulate = accent
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(tex)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var job_title := Label.new()
	job_title.add_theme_font_size_override("font_size", 17)
	job_title.add_theme_color_override("font_color", UIColors.TEXT)
	vbox.add_child(job_title)

	var job_desc := Label.new()
	job_desc.custom_minimum_size = Vector2(260.0, 0.0)
	job_desc.add_theme_font_size_override("font_size", 14)
	job_desc.add_theme_color_override("font_color", UIColors.MUTED)
	job_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	job_desc.max_lines_visible = 2
	vbox.add_child(job_desc)

	return {
		"job": str(entry["job"]),
		"title_key": str(entry["title_key"]),
		"desc_key": str(entry["desc_key"]),
		"card": card,
		"icon_rect": tex,
		"title_label": job_title,
		"desc_label": job_desc,
	}

func _format_task_desc(job: String, desc_key: String, mc: RefCounted) -> String:
	match job:
		SimPlanScript.JOB_REST:
			return tr(desc_key).format({"days": int(_const_float("SICK_REST_DAYS", 2.0, mc))})
		SimPlanScript.JOB_FARM:
			return tr(desc_key).format({"days": int(_const_float("FARM_EVERY_DAYS", 2.0, mc))})
		SimPlanScript.JOB_REGOLITH:
			return tr(desc_key).format({"g": _format_number(_const_float("REGOLITH_G_CM2_PER_JOB", 2.5, mc))})
		SimPlanScript.JOB_SCIENCE:
			return tr(desc_key).format({"goal": int(_const_float("SCIENCE_GOAL_POINTS", 10.0, mc))})
		_:
			return tr(desc_key)

func _refresh_tasks_grid() -> void:
	var mc: RefCounted = _get_mission_sim_constants()
	for row in task_rows:
		var title_lbl: Label = row["title_label"] as Label
		var desc_lbl: Label = row["desc_label"] as Label
		if title_lbl != null:
			title_lbl.text = tr(str(row["title_key"]))
		if desc_lbl != null:
			desc_lbl.text = _format_task_desc(str(row["job"]), str(row["desc_key"]), mc)

func _render_goal_step() -> void:
	var sunset_day: int = int(_const_float("SUNSET_DAY", 15.0))
	var night_days: int = int(_const_float("NIGHT_DAYS", 14.0))
	var mission_days: int = int(_const_float("MISSION_DAYS", 30.0))
	var mc: RefCounted = _get_mission_sim_constants()
	if mc != null:
		mission_days = int(mc.v("MISSION_DAYS"))
	elif GameState != null and GameState.current_mission != null and GameState.current_mission.has_method("get_total_days"):
		mission_days = int(GameState.current_mission.get_total_days())

	if mission_days >= sunset_day:
		_set_header(ICON_NIGHT, UIColors.POWER, tr("TUT_STEP3_TITLE"))
		if body_label != null:
			body_label.text = tr("TUT_STEP3_BODY").format({"day": sunset_day, "night": night_days})
		return

	var mission_name: String = tr("TUT_STEP3_TITLE")
	var mission_goal: String = ""
	if Constants != null and Constants.sim != null and Settings != null:
		var sm: RefCounted = SimMissionsScript.new(Constants.sim)
		var m: Dictionary = sm.get_mission(Settings.current_mission_id)
		if not m.is_empty():
			var n_key: String = str(m.get("name_key", ""))
			var g_key: String = str(m.get("goal_key", ""))
			if n_key != "":
				mission_name = tr(n_key)
			if g_key != "":
				mission_goal = tr(g_key).format({"days": mission_days, "night": night_days})
	_set_header(ICON_ROCKET, UIColors.OXYGEN, mission_name)
	if body_label != null:
		body_label.text = tr("TUT_STEP3_GOAL").format({"goal": mission_goal})

func _render_step(step_num: int) -> void:
	if badge_label != null:
		badge_label.text = tr("TUT_STEP_BADGE").format({"step": step_num, "total": TOTAL_STEPS})
		badge_label.modulate = UIColors.POWER
	_set_tasks_layout(step_num == 3)

	match step_num:
		1:
			var limit_kg: int = int(_const_float("CARGO_LIMIT_KG", 15000.0))
			_set_header(ICON_ROCKET, UIColors.WATER, tr("TUT_STEP1_TITLE"))
			if body_label != null:
				body_label.text = tr("TUT_STEP1_BODY").format({"limit": limit_kg})
			if primary_button != null:
				primary_button.text = tr("TUT_GOT_IT")
			if skip_button != null:
				skip_button.text = tr("TUT_SKIP")
				skip_button.visible = true
		2:
			_set_header(ICON_CONSTRUCTION, UIColors.OXYGEN, tr("TUT_STEP2_TITLE"))
			if body_label != null:
				body_label.text = tr("TUT_STEP2_BODY")
			if primary_button != null:
				primary_button.text = tr("TUT_NEXT")
			if skip_button != null:
				skip_button.text = tr("TUT_SKIP")
				skip_button.visible = true
		3:
			_set_header(ICON_INFO, UIColors.WATER, tr("TUT_TASKS_TITLE"))
			if body_label != null:
				body_label.text = tr("TUT_TASKS_BODY")
			_refresh_tasks_grid()
			if primary_button != null:
				primary_button.text = tr("TUT_NEXT")
			if skip_button != null:
				skip_button.text = tr("TUT_SKIP")
				skip_button.visible = true
		4:
			_render_goal_step()
			if primary_button != null:
				primary_button.text = tr("TUT_PLAY")
			if skip_button != null:
				skip_button.visible = false

func _render_hint(hint_id: String) -> void:
	_set_tasks_layout(false)
	if badge_label != null:
		badge_label.text = tr("HINT_BADGE")
		badge_label.modulate = UIColors.POWER
	if skip_button != null:
		skip_button.visible = false
	if primary_button != null:
		primary_button.text = tr("POPUP_OK")

	match hint_id:
		"battery_low":
			_set_header(ICON_BOLT, UIColors.POWER, tr("HINT_BATTERY_TITLE"))
			if body_label != null:
				body_label.text = tr("HINT_BATTERY_BODY").format({"pct": int(BATTERY_LOW_HINT_PERCENT)})
		"broken":
			_set_header(ICON_CONSTRUCTION, UIColors.ALERT, tr("HINT_BROKEN_TITLE"))
			if body_label != null:
				body_label.text = tr("HINT_BROKEN_BODY")
		"co2_yellow":
			var co2_max: float = _const_float("CO2_HEALTHY_MAX_MMHG", 2.0)
			_set_header(ICON_CO2, UIColors.POWER, tr("HINT_CO2_TITLE"))
			if body_label != null:
				body_label.text = tr("HINT_CO2_BODY").format({"mmhg": _format_number(co2_max)})
		"tired":
			_set_header(ICON_BEDTIME, UIColors.POWER, tr("HINT_TIRED_TITLE"))
			if body_label != null:
				body_label.text = tr("HINT_TIRED_BODY")
		"science_card":
			_set_header(ICON_SCIENCE, UIColors.WATER, tr("HINT_CARD_TITLE"))
			if body_label != null:
				body_label.text = tr("HINT_CARD_BODY")

func _on_primary_pressed() -> void:
	_play_audio("ui_confirm")
	if current_mode == Mode.STEP:
		var finished_step: int = current_step
		if finished_step == 1:
			hide_overlay()
			step_acknowledged.emit(1)
		elif finished_step < TOTAL_STEPS:
			step_acknowledged.emit(finished_step)
			show_step(finished_step + 1)
		else:
			hide_overlay()
			step_acknowledged.emit(finished_step)
			tutorial_finished.emit()
	elif current_mode == Mode.HINT:
		var closed_id: String = current_hint_id
		hide_overlay()
		hint_closed.emit(closed_id)

func _on_skip_pressed() -> void:
	_play_audio("ui_click")
	hide_overlay()
	tutorial_skipped.emit()

func _play_audio(sound_name: String) -> void:
	if Audio != null:
		Audio.play(sound_name)

func _on_language_changed(_new_lang: String) -> void:
	if visible and current_mode != Mode.NONE:
		_refresh_content()
