class_name Gauge
extends PanelContainer

const KidGaugeGraphicScript := preload("res://ui/kid_gauge_graphic.gd")

signal gauge_tapped(gauge: Gauge)

enum State {
	NORMAL,
	WARN,
	CRITICAL
}

@export var icon_texture: Texture2D:
	set(val):
		icon_texture = val
		_ensure_nodes()
		if icon_rect != null:
			icon_rect.texture = icon_texture

@export var meaning_color: Color = UIColors.OXYGEN:
	set(val):
		meaning_color = val
		_ensure_nodes()
		_update_visuals()

@export var unit_text: String = "":
	set(val):
		unit_text = val
		_ensure_nodes()
		if unit_label != null:
			unit_label.text = unit_text

@export var source_constant_id: String = "":
	set(val):
		source_constant_id = val
		_ensure_nodes()
		if source_tag != null:
			source_tag.setup(source_constant_id)

var gauge_key: String = ""
var current_state: State = State.NORMAL
var current_value: float = 0.0
var max_value: float = 100.0

var icon_rect: TextureRect
var title_label: Label
var status_label: Label
var value_label: Label
var unit_label: Label
var source_tag: SourceTag
var bar: ProgressBar

var battery_outline: KidGaugeGraphicScript
var face_graphic: KidGaugeGraphicScript
var mark_graphic: KidGaugeGraphicScript
var arrow_graphic: KidGaugeGraphicScript
var extra_mark_graphic: KidGaugeGraphicScript
var extra_status_label: Label
var shield_pips_box: HBoxContainer
var shield_pip_nodes: Array[TextureRect] = []
var science_label: Label

var _pulse_timer: float = 0.0
var _pulse_critical: bool = true
var _custom_fill_style: StyleBoxFlat
var _battery_mode: bool = false
var _battery_ratio: float = 1.0
var _last_touch_tap_ms: int = -1000
var _use_status_as_primary: bool = false
var _shield_pip_count: int = 0


func _ensure_nodes() -> void:
	if bar != null:
		return
	icon_rect = get_node_or_null("Margin/VBox/TopRow/IconSlot/IconRect")
	battery_outline = get_node_or_null("Margin/VBox/TopRow/IconSlot/BatteryOutline") as KidGaugeGraphicScript
	title_label = get_node_or_null("Margin/VBox/TopRow/TitleLabel")
	source_tag = get_node_or_null("Margin/VBox/TopRow/SourceTag")

	face_graphic = get_node_or_null("Margin/VBox/ValueRow/FaceGraphic") as KidGaugeGraphicScript
	mark_graphic = get_node_or_null("Margin/VBox/ValueRow/MarkGraphic") as KidGaugeGraphicScript
	value_label = get_node_or_null("Margin/VBox/ValueRow/ValueLabel")
	unit_label = get_node_or_null("Margin/VBox/ValueRow/UnitLabel")
	status_label = get_node_or_null("Margin/VBox/ValueRow/StatusLabel")
	arrow_graphic = get_node_or_null("Margin/VBox/ValueRow/ArrowGraphic") as KidGaugeGraphicScript
	extra_mark_graphic = get_node_or_null("Margin/VBox/ValueRow/ExtraMarkGraphic") as KidGaugeGraphicScript
	extra_status_label = get_node_or_null("Margin/VBox/ValueRow/ExtraStatusLabel")
	shield_pips_box = get_node_or_null("Margin/VBox/ValueRow/ShieldPips")
	if shield_pips_box != null:
		shield_pip_nodes.clear()
		for i in range(3):
			var pip := shield_pips_box.get_node_or_null("Pip%d" % i) as TextureRect
			if pip != null:
				shield_pip_nodes.append(pip)

	bar = get_node_or_null("Margin/VBox/Bar")
	science_label = get_node_or_null("Margin/VBox/ScienceLabel")

	if bar != null and _custom_fill_style == null:
		_custom_fill_style = StyleBoxFlat.new()
		_custom_fill_style.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", _custom_fill_style)


func _ready() -> void:
	set_process(false)
	_ensure_nodes()
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if icon_texture != null and icon_rect != null:
		icon_rect.texture = icon_texture
	if unit_label != null:
		unit_label.text = unit_text
	if source_tag != null:
		if not source_constant_id.is_empty():
			source_tag.setup(source_constant_id)
		else:
			source_tag.visible = false

	_update_visuals()


func setup(icon: Texture2D, unit: String, col: Color, src_id: String = "", title: String = "") -> void:
	_ensure_nodes()
	icon_texture = icon
	unit_text = unit
	meaning_color = col
	source_constant_id = src_id

	if title_label != null:
		title_label.text = title
	if icon_rect != null:
		icon_rect.texture = icon_texture


func set_title(title: String) -> void:
	_ensure_nodes()
	if title_label != null:
		title_label.text = title
	if unit_label != null:
		unit_label.text = unit_text
	if source_tag != null:
		if not source_constant_id.is_empty():
			source_tag.setup(source_constant_id)
		else:
			source_tag.visible = false
	_update_visuals()


func set_value(cur: float, mx: float, display_str: String = "", custom_unit: String = "") -> void:
	_ensure_nodes()
	current_value = cur
	max_value = mx
	if bar != null:
		bar.max_value = mx if mx > 0.0 else 1.0
		bar.value = clampf(cur, 0.0, bar.max_value)

	if not custom_unit.is_empty():
		unit_text = custom_unit

	if value_label != null:
		if not display_str.is_empty():
			var cleaned: String = display_str
			if not unit_text.is_empty() and cleaned.ends_with(unit_text):
				cleaned = cleaned.substr(0, cleaned.length() - unit_text.length()).strip_edges()
			value_label.text = cleaned
		else:
			if is_equal_approx(cur, roundf(cur)):
				value_label.text = str(int(cur))
			else:
				value_label.text = "%.1f" % cur

	if unit_label != null:
		unit_label.text = unit_text
		unit_label.visible = (not _use_status_as_primary) and (not unit_text.is_empty())

	if source_tag != null and not source_constant_id.is_empty():
		source_tag.dynamic_value = cur


func set_primary_kid_text(big_text: String, hide_unit: bool = true) -> void:
	_ensure_nodes()
	_use_status_as_primary = false
	if value_label != null:
		value_label.visible = true
		value_label.text = big_text
	if unit_label != null:
		unit_label.visible = not hide_unit and not unit_text.is_empty()


func set_status_word(word_text: String, col: Color = UIColors.TEXT, as_primary: bool = false) -> void:
	_ensure_nodes()
	_use_status_as_primary = as_primary
	if status_label == null:
		return
	if word_text.is_empty():
		status_label.visible = false
		status_label.text = ""
		if value_label != null:
			value_label.visible = true
		return
	status_label.text = word_text
	status_label.add_theme_color_override("font_color", col)
	status_label.add_theme_font_size_override("font_size", 16 if as_primary else 13)
	status_label.visible = true
	if value_label != null:
		value_label.visible = not as_primary
	if unit_label != null:
		unit_label.visible = (not as_primary) and (not unit_text.is_empty())


func set_battery_visual(enabled: bool, fill_ratio: float, arrow_dir: String, arrow_text: String, arrow_color: Color) -> void:
	_ensure_nodes()
	_battery_mode = enabled
	_battery_ratio = clampf(fill_ratio, 0.0, 1.0)
	if battery_outline != null:
		battery_outline.visible = enabled
		if enabled:
			battery_outline.configure("battery", _state_color(), _battery_ratio)
	if icon_rect != null:
		if enabled:
			icon_rect.offset_left = 4.0
			icon_rect.offset_top = 3.0
			icon_rect.offset_right = -6.0
			icon_rect.offset_bottom = -3.0
		else:
			icon_rect.offset_left = 0.0
			icon_rect.offset_top = 0.0
			icon_rect.offset_right = 0.0
			icon_rect.offset_bottom = 0.0
	if arrow_graphic != null:
		if arrow_dir == "up" or arrow_dir == "down":
			arrow_graphic.visible = true
			arrow_graphic.configure("arrow_" + arrow_dir, arrow_color)
		else:
			arrow_graphic.visible = false
	set_extra_status(arrow_text, arrow_color, "")


func set_face_visual(mood: String) -> void:
	_ensure_nodes()
	if face_graphic == null:
		return
	if mood.is_empty():
		face_graphic.visible = false
		return
	face_graphic.visible = true
	var face_col: Color = _state_color()
	match mood:
		"danger":
			face_col = UIColors.ALERT
		"stuffy":
			face_col = UIColors.POWER
		_:
			face_col = UIColors.OXYGEN
	face_graphic.configure("face_" + mood, face_col)


func set_primary_mark(kind: String, col: Color = UIColors.OXYGEN) -> void:
	_ensure_nodes()
	if mark_graphic == null:
		return
	if kind.is_empty():
		mark_graphic.visible = false
		return
	mark_graphic.visible = true
	mark_graphic.configure(kind, col)


func set_extra_status(word_text: String, col: Color = UIColors.TEXT, mark_kind: String = "") -> void:
	_ensure_nodes()
	if extra_mark_graphic != null:
		if mark_kind.is_empty():
			extra_mark_graphic.visible = false
		else:
			extra_mark_graphic.visible = true
			extra_mark_graphic.configure(mark_kind, col)
	if extra_status_label == null:
		return
	if word_text.is_empty():
		extra_status_label.visible = false
		extra_status_label.text = ""
		return
	extra_status_label.text = word_text
	extra_status_label.add_theme_color_override("font_color", col)
	extra_status_label.visible = true


func set_shield_pips(enabled: bool, filled_count: int, fill_color: Color = UIColors.OXYGEN, empty_color: Color = Color(0.55, 0.60, 0.68, 0.28)) -> void:
	_ensure_nodes()
	_shield_pip_count = clampi(filled_count, 0, 3)
	if shield_pips_box == null:
		return
	shield_pips_box.visible = enabled
	if not enabled:
		return
	for i in range(shield_pip_nodes.size()):
		var pip: TextureRect = shield_pip_nodes[i]
		if pip != null:
			pip.modulate = fill_color if i < _shield_pip_count else empty_color


func get_shield_pip_count() -> int:
	return _shield_pip_count


func set_science_subtext(sub_text: String) -> void:
	_ensure_nodes()
	if science_label == null:
		return
	if sub_text.is_empty():
		science_label.visible = false
		science_label.text = ""
		return
	science_label.text = sub_text
	science_label.visible = true


func set_state(state_name: String, pulse_on_critical: bool = true) -> void:
	_ensure_nodes()
	_pulse_critical = pulse_on_critical
	match state_name.to_lower():
		"warn", "warning":
			current_state = State.WARN
		"critical", "danger", "alert":
			current_state = State.CRITICAL
		_:
			current_state = State.NORMAL
	_update_visuals()


func _state_color() -> Color:
	match current_state:
		State.WARN:
			return UIColors.POWER
		State.CRITICAL:
			return UIColors.ALERT
		_:
			return meaning_color


func _update_visuals() -> void:
	_ensure_nodes()
	if _custom_fill_style == null or icon_rect == null or value_label == null:
		return

	match current_state:
		State.NORMAL:
			set_process(false)
			icon_rect.modulate = meaning_color
			_custom_fill_style.bg_color = meaning_color
			value_label.modulate = UIColors.TEXT
			if battery_outline != null and _battery_mode:
				battery_outline.configure("battery", meaning_color, _battery_ratio)
		State.WARN:
			set_process(false)
			icon_rect.modulate = UIColors.POWER
			_custom_fill_style.bg_color = UIColors.POWER
			value_label.modulate = UIColors.POWER
			if battery_outline != null and _battery_mode:
				battery_outline.configure("battery", UIColors.POWER, _battery_ratio)
		State.CRITICAL:
			_pulse_timer = 0.0
			set_process(_pulse_critical)
			_apply_critical_pulse(1.0)


func _process(delta: float) -> void:
	if current_state != State.CRITICAL or not _pulse_critical:
		set_process(false)
		return
	_pulse_timer += delta * 5.0
	var alpha_factor: float = 0.45 + 0.55 * (0.5 + 0.5 * sin(_pulse_timer))
	_apply_critical_pulse(alpha_factor)


func _apply_critical_pulse(factor: float) -> void:
	if icon_rect == null or _custom_fill_style == null or value_label == null:
		return
	var pulse_col: Color = UIColors.ALERT
	pulse_col.a = factor
	icon_rect.modulate = pulse_col
	_custom_fill_style.bg_color = pulse_col
	value_label.modulate = Color(1.0, 0.4 * factor, 0.4 * factor)
	if battery_outline != null and _battery_mode:
		battery_outline.configure("battery", pulse_col, _battery_ratio)


func _is_point_on_source_tag(global_pt: Vector2) -> bool:
	return source_tag != null and visible and source_tag.visible and source_tag.get_global_rect().has_point(global_pt)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			var gpos: Vector2 = get_global_transform_with_canvas().origin + st.position
			if _is_point_on_source_tag(gpos):
				return
			_last_touch_tap_ms = Time.get_ticks_msec()
			gauge_tapped.emit(self)
			accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.device == InputEvent.DEVICE_ID_EMULATION:
				return
			if Time.get_ticks_msec() - _last_touch_tap_ms < 250:
				return
			var gpos: Vector2 = get_global_transform_with_canvas().origin + mb.position
			if _is_point_on_source_tag(gpos):
				return
			gauge_tapped.emit(self)
			accept_event()
