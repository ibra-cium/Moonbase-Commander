class_name CrewCard
extends PanelContainer

signal job_changed(crew_index: int, new_job: String)
signal card_selected(crew_index: int)
signal picker_opened(crew_index: int)

const SimPlanScript := preload("res://sim/sim_plan.gd")
const AstronautScript := preload("res://world/astronaut.gd")

const SUIT_COLORS := AstronautScript.SUIT_COLORS
const PIP_EMPTY_COLOR := Color(0.42, 0.46, 0.52, 0.75)

const JOB_ICONS: Dictionary = {
	SimPlanScript.JOB_REST: preload("res://assets/icons/bedtime.svg"),
	SimPlanScript.JOB_REPAIR: preload("res://assets/icons/construction.svg"),
	SimPlanScript.JOB_CLEAN: preload("res://assets/icons/cleaning_services.svg"),
	SimPlanScript.JOB_FARM: preload("res://assets/icons/eco.svg"),
	SimPlanScript.JOB_REGOLITH: preload("res://assets/icons/landscape.svg"),
	SimPlanScript.JOB_SCIENCE: preload("res://assets/icons/science.svg"),
}

@export var crew_index: int = 0:
	set(val):
		crew_index = clampi(val, 0, 3)
		_refresh_display()

var current_job: String = SimPlanScript.JOB_REST
var dose_msv: float = 0.0
var is_sick: bool = false
var sick_days: int = 0
var energy: int = 3

# Base availability flags
var is_storm: bool = false
var recycler_broken: bool = false
var broken_panels: int = 0
var has_greenhouse: bool = false
var greenhouse_alive: bool = false

# Node references
var top_row: HBoxContainer
var suit_badge: ColorRect
var crew_label: Label
var dose_label: Label
var sick_container: HBoxContainer
var sick_icon: TextureRect
var sick_label: Label
var energy_row: HBoxContainer
var pips_container: HBoxContainer
var energy_pips: Array[ColorRect] = []
var tired_label: Label

var _selected: bool = false
var _base_panel_style: StyleBox = null
var _selected_panel_style: StyleBoxFlat = null
var _last_touch_tap_ms: int = -1000

var prev_job_btn: Button
var job_btn: Button
var next_job_btn: Button
var job_icon_rect: TextureRect
var job_name_label: Label

# Job picker popover
var picker_layer: CanvasLayer
var picker_backdrop: Control
var picker_suit_badge: ColorRect
var picker_title: Label
var picker_grid: GridContainer
var picker_close_btn: Button
var _picker_buttons: Dictionary = {}

func _ensure_nodes() -> void:
	if suit_badge != null:
		return
	if _base_panel_style == null:
		var base_sb := get_theme_stylebox("panel")
		if base_sb != null:
			_base_panel_style = base_sb
	top_row = get_node_or_null("Margin/VBox/TopRow")
	suit_badge = get_node_or_null("Margin/VBox/TopRow/SuitBadge")
	crew_label = get_node_or_null("Margin/VBox/TopRow/CrewLabel")
	dose_label = get_node_or_null("Margin/VBox/TopRow/DoseLabel")
	sick_container = get_node_or_null("Margin/VBox/TopRow/SickBox")
	if top_row != null:
		top_row.mouse_filter = Control.MOUSE_FILTER_STOP
		top_row.custom_minimum_size.y = maxf(top_row.custom_minimum_size.y, 22.0)
		for child in top_row.get_children():
			if child is Control:
				(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_row = get_node_or_null("Margin/VBox/EnergyRow")
	pips_container = get_node_or_null("Margin/VBox/EnergyRow/Pips")
	tired_label = get_node_or_null("Margin/VBox/EnergyRow/TiredLabel")
	energy_pips.clear()
	if energy_row != null:
		energy_row.mouse_filter = Control.MOUSE_FILTER_STOP
		for child in energy_row.get_children():
			if child is Control:
				(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	if pips_container != null:
		for child in pips_container.get_children():
			if child is ColorRect:
				(child as ColorRect).mouse_filter = Control.MOUSE_FILTER_IGNORE
				energy_pips.append(child as ColorRect)
	_sync_pip_count()
	if sick_container != null:
		sick_icon = sick_container.get_node_or_null("SickIcon")
		sick_label = sick_container.get_node_or_null("SickLabel")
		if sick_icon != null:
			sick_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if sick_label != null:
			sick_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	prev_job_btn = get_node_or_null("Margin/VBox/JobRow/PrevBtn")
	job_btn = get_node_or_null("Margin/VBox/JobRow/JobBtn")
	next_job_btn = get_node_or_null("Margin/VBox/JobRow/NextBtn")
	if job_btn != null:
		job_icon_rect = job_btn.get_node_or_null("HBox/JobIcon")
		job_name_label = job_btn.get_node_or_null("HBox/JobName")

	picker_layer = get_node_or_null("JobPickerLayer")
	if picker_layer != null:
		picker_backdrop = picker_layer.get_node_or_null("Backdrop")
		picker_suit_badge = picker_layer.get_node_or_null("Center/Panel/Margin/VBox/Header/PickerSuitBadge")
		picker_title = picker_layer.get_node_or_null("Center/Panel/Margin/VBox/Header/TitleLabel")
		picker_close_btn = picker_layer.get_node_or_null("Center/Panel/Margin/VBox/Header/CloseBtn")
		picker_grid = picker_layer.get_node_or_null("Center/Panel/Margin/VBox/Grid")

func _ensure_wired() -> void:
	_ensure_nodes()
	if picker_backdrop != null and not picker_backdrop.gui_input.is_connected(_on_picker_backdrop_gui_input):
		picker_backdrop.gui_input.connect(_on_picker_backdrop_gui_input)
	if picker_close_btn != null and not picker_close_btn.pressed.is_connected(close_picker):
		picker_close_btn.pressed.connect(close_picker)

	if top_row != null and not top_row.gui_input.is_connected(_on_top_row_gui_input):
		top_row.gui_input.connect(_on_top_row_gui_input)
	if energy_row != null and not energy_row.gui_input.is_connected(_on_top_row_gui_input):
		energy_row.gui_input.connect(_on_top_row_gui_input)
	if job_btn != null and not job_btn.pressed.is_connected(open_picker):
		job_btn.pressed.connect(open_picker)
	if prev_job_btn != null and not prev_job_btn.pressed.is_connected(_cycle_prev_job):
		prev_job_btn.pressed.connect(_cycle_prev_job)
	if next_job_btn != null and not next_job_btn.pressed.is_connected(_cycle_next_job):
		next_job_btn.pressed.connect(_cycle_next_job)

func _ready() -> void:
	_ensure_wired()
	energy = _get_max_energy()
	if picker_layer != null:
		picker_layer.visible = false
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)
	if Settings != null and Settings.has_signal("science_view_changed") and not Settings.science_view_changed.is_connected(_on_science_view_changed):
		Settings.science_view_changed.connect(_on_science_view_changed)
	_build_picker_buttons()
	_refresh_display()

func setup(idx: int) -> void:
	_ensure_wired()
	crew_index = clampi(idx, 0, 3)
	energy = _get_max_energy()
	_refresh_display()

func set_crew_data(p_dose: float, p_is_sick: bool, p_sick_days: int = 0, p_energy: int = -1) -> void:
	_ensure_nodes()
	dose_msv = p_dose
	is_sick = p_is_sick
	sick_days = p_sick_days
	if p_energy >= 0:
		energy = clampi(p_energy, 0, _get_max_energy())
	if is_sick:
		set_job(SimPlanScript.JOB_REST)
	_refresh_display()

func get_energy() -> int:
	return energy

func _get_max_energy() -> int:
	if Constants != null and Constants.has_method("has") and Constants.has("CREW_ENERGY_MAX"):
		return int(Constants.v("CREW_ENERGY_MAX"))
	if Constants != null and "sim" in Constants and Constants.sim != null and Constants.sim.has("CREW_ENERGY_MAX"):
		return int(Constants.v("CREW_ENERGY_MAX"))
	return 3

func is_tired_warning() -> bool:
	return (not is_sick) and (not is_storm) and (energy <= 0)

func get_tired_warning_text() -> String:
	var tmpl: String = tr("CREW_TIRED_WARN")
	if tmpl == "CREW_TIRED_WARN" or tmpl.is_empty():
		tmpl = "Too tired! Working today will make {name} sick."
	return tmpl.format({"name": get_crew_name()})

func get_rest_refill_text() -> String:
	var txt: String = tr("CREW_REST_REFILL")
	if txt == "CREW_REST_REFILL" or txt.is_empty():
		return "Rest: full energy"
	return txt

func _sync_pip_count() -> void:
	if pips_container == null:
		return
	var target: int = maxi(1, _get_max_energy())
	while energy_pips.size() < target:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(16, 6)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips_container.add_child(pip)
		energy_pips.append(pip)
	for i in range(energy_pips.size()):
		energy_pips[i].visible = (i < target)

func update_availability(
	p_is_storm: bool,
	p_recycler_broken: bool,
	p_broken_panels: int,
	p_has_greenhouse: bool,
	p_greenhouse_alive: bool
) -> void:
	_ensure_nodes()
	is_storm = p_is_storm
	recycler_broken = p_recycler_broken
	broken_panels = p_broken_panels
	has_greenhouse = p_has_greenhouse
	greenhouse_alive = p_greenhouse_alive

	if is_storm or is_sick:
		set_job(SimPlanScript.JOB_REST)
	elif current_job == SimPlanScript.JOB_REPAIR and not (recycler_broken or broken_panels > 0):
		set_job(SimPlanScript.JOB_REST)
	elif current_job == SimPlanScript.JOB_FARM and not (has_greenhouse and greenhouse_alive):
		set_job(SimPlanScript.JOB_REST)

	_refresh_display()

func set_job(job_name: String) -> void:
	_ensure_nodes()
	if current_job != job_name:
		current_job = job_name
		job_changed.emit(crew_index, current_job)
	_refresh_display()

func get_job() -> String:
	return current_job

func is_job_available(job_name: String, repair_target: String = "") -> bool:
	if is_storm:
		return job_name == SimPlanScript.JOB_REST
	if is_sick:
		return job_name == SimPlanScript.JOB_REST
	match job_name:
		SimPlanScript.JOB_REST:
			return true
		SimPlanScript.JOB_REPAIR:
			if repair_target == "RECYCLER":
				return recycler_broken
			if repair_target == "PANEL":
				return broken_panels > 0
			return recycler_broken or (broken_panels > 0)
		SimPlanScript.JOB_FARM:
			return has_greenhouse and greenhouse_alive
		SimPlanScript.JOB_CLEAN, SimPlanScript.JOB_REGOLITH, SimPlanScript.JOB_SCIENCE:
			return true
	return true

func get_job_disabled_reason(job_name: String, repair_target: String = "") -> String:
	if is_storm:
		return tr("JOB_GREY_STORM")
	if is_sick:
		return tr("JOB_GREY_SICK")
	match job_name:
		SimPlanScript.JOB_REPAIR:
			var can_repair: bool = is_job_available(job_name, repair_target)
			if not can_repair:
				return tr("JOB_GREY_NOTHING_BROKEN")
		SimPlanScript.JOB_FARM:
			if not (has_greenhouse and greenhouse_alive):
				return tr("JOB_GREY_NO_GREENHOUSE")
	return ""

func set_selected(selected: bool) -> void:
	_ensure_nodes()
	_selected = selected
	_refresh_selection_style()

func is_selected() -> bool:
	return _selected

func _refresh_selection_style() -> void:
	if _selected:
		if _selected_panel_style == null:
			var sb: StyleBoxFlat
			if _base_panel_style is StyleBoxFlat:
				sb = (_base_panel_style as StyleBoxFlat).duplicate() as StyleBoxFlat
			else:
				sb = StyleBoxFlat.new()
				sb.bg_color = UIColors.PANEL
				sb.set_corner_radius_all(8)
			sb.bg_color = Color(0.11, 0.14, 0.21, 0.94)
			sb.border_color = UIColors.POWER
			sb.set_border_width_all(3)
			_selected_panel_style = sb
		add_theme_stylebox_override("panel", _selected_panel_style)
	elif _base_panel_style != null:
		add_theme_stylebox_override("panel", _base_panel_style)
	else:
		remove_theme_stylebox_override("panel")

func _on_top_row_gui_input(event: InputEvent) -> void:
	var pressed_tap := false
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if not st.pressed:
			return
		_last_touch_tap_ms = Time.get_ticks_msec()
		pressed_tap = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT):
			return
		if mb.device == -1 and (Time.get_ticks_msec() - _last_touch_tap_ms) < 80:
			return
		pressed_tap = true
	if not pressed_tap:
		return
	if is_inside_tree() and get_viewport() != null:
		accept_event()
	card_selected.emit(crew_index)

func get_crew_name() -> String:
	return AstronautScript.crew_name_for(crew_index)

func get_suit_color() -> Color:
	return SUIT_COLORS[crew_index] if crew_index < SUIT_COLORS.size() else SUIT_COLORS[0]

func is_picker_open() -> bool:
	return picker_layer != null and picker_layer.visible

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh_language_texts()

func _on_language_changed(_lang: String) -> void:
	_refresh_language_texts()

func _on_science_view_changed(_enabled: bool) -> void:
	_refresh_display()

func _refresh_language_texts() -> void:
	for job_name in _picker_buttons:
		var data: Dictionary = _picker_buttons[job_name]
		var name_lbl: Label = data.get("name_lbl")
		if name_lbl != null:
			name_lbl.text = tr("JOB_" + job_name)
	if picker_title != null:
		picker_title.text = "%s - %s" % [get_crew_name(), tr("CREW_TITLE")]
	_refresh_display()

func _refresh_display() -> void:
	_ensure_nodes()
	var suit_col: Color = get_suit_color()
	if suit_badge != null:
		suit_badge.color = suit_col
	if picker_suit_badge != null:
		picker_suit_badge.color = suit_col

	if crew_label != null:
		crew_label.text = get_crew_name()

	if dose_label != null:
		var raw_dose := tr("CREW_DOSE")
		if raw_dose == "CREW_DOSE":
			raw_dose = "{dose} mSv"
		dose_label.text = raw_dose.format({"dose": "%.1f" % dose_msv})
		dose_label.visible = (Settings != null and Settings.science_view)

	if sick_container != null:
		sick_container.visible = is_sick
		if is_sick and sick_label != null:
			var raw_sick := tr("CREW_SICK")
			if raw_sick == "CREW_SICK":
				raw_sick = "Sick"
			if sick_days > 1:
				var fmt_sick: String = tr("CREW_SICK_DAYS")
				if fmt_sick == "CREW_SICK_DAYS":
					fmt_sick = "Sick ({days}d)"
				sick_label.text = fmt_sick.format({"days": sick_days})
			else:
				sick_label.text = raw_sick

	_sync_pip_count()
	var max_e: int = _get_max_energy()
	for i in range(mini(max_e, energy_pips.size())):
		energy_pips[i].color = suit_col if i < energy else PIP_EMPTY_COLOR
	if tired_label != null:
		tired_label.visible = (energy <= 0 and not is_sick)
		var tired_txt: String = tr("CREW_TIRED_LABEL")
		if tired_txt == "CREW_TIRED_LABEL" or tired_txt.is_empty():
			tired_txt = "Tired!"
		tired_label.text = tired_txt
		tired_label.add_theme_color_override("font_color", UIColors.POWER)

	if job_icon_rect != null and JOB_ICONS.has(current_job):
		job_icon_rect.texture = JOB_ICONS[current_job]
		job_icon_rect.modulate = Color(1, 1, 1, 1)
	if job_name_label != null:
		var tr_job_key: String = "JOB_" + current_job
		var job_text: String = tr(tr_job_key)
		if job_text == tr_job_key:
			job_text = current_job.capitalize()
		job_name_label.text = job_text
		job_name_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.97, 1))

	_update_picker_buttons_state()

func _cycle_next_job() -> void:
	var available := _get_available_jobs()
	if available.is_empty():
		return
	var cur_idx: int = available.find(current_job)
	var next_idx: int = (cur_idx + 1) % available.size()
	var next_job: String = available[next_idx]
	_play_audio("ui_error" if (is_tired_warning() and next_job != SimPlanScript.JOB_REST) else "ui_click")
	set_job(next_job)

func _cycle_prev_job() -> void:
	var available := _get_available_jobs()
	if available.is_empty():
		return
	var cur_idx: int = available.find(current_job)
	var prev_idx: int = (cur_idx - 1 + available.size()) % available.size()
	var prev_job: String = available[prev_idx]
	_play_audio("ui_error" if (is_tired_warning() and prev_job != SimPlanScript.JOB_REST) else "ui_click")
	set_job(prev_job)

func _get_available_jobs() -> Array[String]:
	var list: Array[String] = []
	for j in SimPlanScript.VALID_JOBS:
		if is_job_available(j):
			list.append(j)
	return list

func open_picker() -> void:
	_ensure_nodes()
	if picker_layer == null:
		return
	if picker_suit_badge != null:
		picker_suit_badge.color = get_suit_color()
	if picker_title != null:
		picker_title.text = "%s - %s" % [get_crew_name(), tr("CREW_TITLE")]
	_update_picker_buttons_state()
	_play_audio("ui_click")
	picker_layer.visible = true
	picker_opened.emit(crew_index)

func close_picker() -> void:
	_ensure_nodes()
	if picker_layer != null:
		if picker_layer.visible:
			_play_audio("ui_click")
		picker_layer.visible = false

func _on_picker_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_picker()
	elif event is InputEventScreenTouch and event.pressed:
		close_picker()

func _build_picker_buttons() -> void:
	if picker_grid == null or not _picker_buttons.is_empty():
		return
	
	for child in picker_grid.get_children():
		child.queue_free()

	for job_name in SimPlanScript.VALID_JOBS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 82)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		btn.add_child(margin)

		var hbox := HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 10)
		margin.add_child(hbox)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if JOB_ICONS.has(job_name):
			icon.texture = JOB_ICONS[job_name]
		hbox.add_child(icon)

		var vbox := VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)

		var name_lbl := Label.new()
		name_lbl.add_theme_font_size_override("font_size", 18)
		var tr_key := "JOB_" + job_name
		name_lbl.text = tr(tr_key)
		vbox.add_child(name_lbl)

		var reason_lbl := Label.new()
		reason_lbl.add_theme_font_size_override("font_size", 11)
		reason_lbl.add_theme_color_override("font_color", UIColors.ALERT)
		reason_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reason_lbl.visible = false
		vbox.add_child(reason_lbl)

		btn.pressed.connect(func():
			if is_tired_warning() and job_name != SimPlanScript.JOB_REST:
				_play_audio("ui_error")
			else:
				_play_audio("ui_confirm")
			set_job(job_name)
			if picker_layer != null:
				picker_layer.visible = false
		)
		btn.gui_input.connect(func(event: InputEvent) -> void:
			if btn.disabled and _is_press_event(event):
				_play_audio("ui_error")
		)

		picker_grid.add_child(btn)
		_picker_buttons[job_name] = {
			"button": btn,
			"icon": icon,
			"name_lbl": name_lbl,
			"reason_lbl": reason_lbl
		}

func _update_picker_buttons_state() -> void:
	if _picker_buttons.is_empty():
		return
	for job_name in _picker_buttons:
		var data: Dictionary = _picker_buttons[job_name]
		var btn: Button = data["button"]
		var reason_lbl: Label = data["reason_lbl"]
		var icon: TextureRect = data["icon"]
		var name_lbl: Label = data["name_lbl"]

		var available: bool = is_job_available(job_name)
		btn.disabled = not available
		var is_current_job: bool = (job_name == current_job)

		if is_current_job:
			name_lbl.modulate = Color(1.0, 0.85, 0.3)
			icon.modulate = Color(1.0, 0.85, 0.3)
		else:
			name_lbl.modulate = Color.WHITE
			icon.modulate = Color.WHITE

		if not available:
			var reason: String = get_job_disabled_reason(job_name)
			reason_lbl.text = reason
			reason_lbl.add_theme_color_override("font_color", UIColors.ALERT)
			reason_lbl.visible = not reason.is_empty()
			btn.modulate = Color(0.65, 0.65, 0.65, 0.7)
		elif is_tired_warning() and job_name != SimPlanScript.JOB_REST:
			reason_lbl.text = get_tired_warning_text()
			reason_lbl.add_theme_color_override("font_color", UIColors.ALERT)
			reason_lbl.visible = true
			btn.modulate = Color.WHITE
		elif job_name == SimPlanScript.JOB_REST and energy < _get_max_energy():
			reason_lbl.text = get_rest_refill_text()
			reason_lbl.add_theme_color_override("font_color", UIColors.OXYGEN)
			reason_lbl.visible = true
			btn.modulate = Color.WHITE
		else:
			reason_lbl.visible = false
			btn.modulate = Color.WHITE

func _is_press_event(event: InputEvent) -> bool:
	return (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)

func _play_audio(sound_name: String) -> void:
	if Audio != null:
		Audio.play(sound_name)


