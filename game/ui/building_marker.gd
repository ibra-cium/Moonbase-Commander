class_name BuildingMarker
extends WorldAnchor

## 2D WorldAnchor marker button shown above each moonbase building while a crew member is selected.

signal marker_activated(building_key: String, job: String)
signal disabled_tapped(building_key: String, job: String, reason_text: String)

const SINGLE_SIZE := Vector2(88.0, 88.0)
const SPLIT_SIZE := Vector2(156.0, 68.0)
const CIRCLE_DIAMETER: int = 72
const CIRCLE_RADIUS: int = 36
const SPLIT_RADIUS: int = 18

var building_key: String = ""
var is_split_mode: bool = false

var _primary_job: String = ""
var _primary_available: bool = true
var _primary_reason: String = ""
var _primary_accent: Color = UIColors.MODULE

var _left_job: String = "CLEAN"
var _left_available: bool = true
var _left_reason: String = ""

var _right_job: String = "REPAIR"
var _right_available: bool = true
var _right_reason: String = ""

var _single_wrap: Control = null
var _circle_btn: Button = null
var _circle_icon: TextureRect = null
var _circle_label: Label = null
var _circle_pill: PanelContainer = null

var _split_wrap: HBoxContainer = null
var _left_btn: Button = null
var _left_icon: TextureRect = null
var _left_label: Label = null
var _right_btn: Button = null
var _right_icon: TextureRect = null
var _right_label: Label = null
var _warn_pill: PanelContainer = null
var _warn_label: Label = null
var _warning_text: String = ""
var is_pulsing: bool = false
var _pulse_tween: Tween = null


func _ready() -> void:
	super._ready()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_wired()


func _ensure_wired() -> void:
	_ensure_nodes()
	if _circle_btn != null and not _circle_btn.pressed.is_connected(_on_circle_pressed):
		_circle_btn.pressed.connect(_on_circle_pressed)
	if _left_btn != null and not _left_btn.pressed.is_connected(_on_left_pressed):
		_left_btn.pressed.connect(_on_left_pressed)
	if _right_btn != null and not _right_btn.pressed.is_connected(_on_right_pressed):
		_right_btn.pressed.connect(_on_right_pressed)


## Configures a single round building marker button (REST, REPAIR, CLEAN, FARM, REGOLITH, SCIENCE).
func configure_single(
	p_building_key: String,
	p_job: String,
	p_label_key: String,
	p_icon: Texture2D,
	p_accent: Color,
	p_available: bool,
	p_reason: String,
	p_anchor_point: Vector3,
	p_warning: String = ""
) -> void:
	_ensure_wired()
	building_key = p_building_key
	is_split_mode = false
	_primary_job = p_job
	_primary_available = p_available
	_primary_reason = p_reason
	_primary_accent = p_accent

	custom_minimum_size = SINGLE_SIZE
	size = SINGLE_SIZE
	pivot_offset = SINGLE_SIZE * 0.5
	set_anchor_point(p_anchor_point)

	if _single_wrap != null:
		_single_wrap.visible = true
	if _split_wrap != null:
		_split_wrap.visible = false
	if _circle_icon != null:
		_circle_icon.texture = p_icon
		_circle_icon.modulate = Color.WHITE if p_available else Color(0.68, 0.70, 0.76, 0.75)
	if _circle_label != null:
		_circle_label.text = tr(p_label_key)
		_circle_label.modulate = UIColors.TEXT if p_available else UIColors.MUTED
	if _circle_btn != null:
		_apply_button_styles(_circle_btn, p_accent, p_available, CIRCLE_RADIUS)
	if _circle_pill != null:
		_apply_pill_style(_circle_pill, p_accent, p_available)
	_apply_warning_banner(p_warning if p_available else "")
	update_position()


## Configures the two-button Solar Field marker (Clean + Repair) when solar panels are broken.
func configure_split(
	p_building_key: String,
	p_left_spec: Dictionary,
	p_right_spec: Dictionary,
	p_anchor_point: Vector3
) -> void:
	_ensure_wired()
	building_key = p_building_key
	is_split_mode = true

	_left_job = str(p_left_spec.get("job", "CLEAN"))
	_left_available = bool(p_left_spec.get("available", true))
	_left_reason = str(p_left_spec.get("reason", ""))

	_right_job = str(p_right_spec.get("job", "REPAIR"))
	_right_available = bool(p_right_spec.get("available", true))
	_right_reason = str(p_right_spec.get("reason", ""))

	custom_minimum_size = SPLIT_SIZE
	size = SPLIT_SIZE
	pivot_offset = SPLIT_SIZE * 0.5
	set_anchor_point(p_anchor_point)

	if _single_wrap != null:
		_single_wrap.visible = false
	if _split_wrap != null:
		_split_wrap.visible = true

	_setup_split_button(
		_left_btn,
		_left_icon,
		_left_label,
		p_left_spec.get("icon", null),
		tr(str(p_left_spec.get("label_key", "ASSIGN_CLEAN"))),
		Color(p_left_spec.get("accent", UIColors.POWER)),
		_left_available
	)
	_setup_split_button(
		_right_btn,
		_right_icon,
		_right_label,
		p_right_spec.get("icon", null),
		tr(str(p_right_spec.get("label_key", "ASSIGN_REPAIR"))),
		Color(p_right_spec.get("accent", UIColors.ALERT)),
		_right_available
	)
	var split_warn := ""
	if _left_available and not str(p_left_spec.get("warning", "")).is_empty():
		split_warn = str(p_left_spec.get("warning", ""))
	elif _right_available and not str(p_right_spec.get("warning", "")).is_empty():
		split_warn = str(p_right_spec.get("warning", ""))
	_apply_warning_banner(split_warn)
	update_position()


func get_primary_job() -> String:
	return _primary_job


func is_primary_available() -> bool:
	return _primary_available


func get_primary_reason() -> String:
	return _primary_reason


func is_left_available() -> bool:
	return _left_available


func get_left_reason() -> String:
	return _left_reason


func is_right_available() -> bool:
	return _right_available


func get_right_reason() -> String:
	return _right_reason


func get_warning_text() -> String:
	return _warning_text


func is_warning_visible() -> bool:
	return _warn_pill != null and _warn_pill.visible


func get_label_text() -> String:
	return _circle_label.text if _circle_label != null else ""


func _setup_split_button(
	btn: Button,
	icon_rect: TextureRect,
	lbl: Label,
	icon_tex: Variant,
	label_text: String,
	accent: Color,
	available: bool
) -> void:
	if icon_rect != null and icon_tex is Texture2D:
		icon_rect.texture = icon_tex as Texture2D
		icon_rect.modulate = Color.WHITE if available else Color(0.68, 0.70, 0.76, 0.75)
	if lbl != null:
		lbl.text = label_text
		lbl.modulate = UIColors.TEXT if available else UIColors.MUTED
	if btn != null:
		_apply_button_styles(btn, accent, available, SPLIT_RADIUS)


func _ensure_nodes() -> void:
	if _single_wrap == null:
		_single_wrap = get_node_or_null("SingleWrap") as Control
	if _circle_btn == null:
		_circle_btn = get_node_or_null("SingleWrap/CircleBtn") as Button
	if _circle_icon == null:
		_circle_icon = get_node_or_null("SingleWrap/CircleBtn/Center/Icon") as TextureRect
	if _circle_pill == null:
		_circle_pill = get_node_or_null("SingleWrap/LabelPill") as PanelContainer
	if _circle_label == null:
		_circle_label = get_node_or_null("SingleWrap/LabelPill/Margin/Label") as Label

	if _split_wrap == null:
		_split_wrap = get_node_or_null("SplitWrap") as HBoxContainer
	if _left_btn == null:
		_left_btn = get_node_or_null("SplitWrap/LeftBtn") as Button
	if _left_icon == null:
		_left_icon = get_node_or_null("SplitWrap/LeftBtn/Margin/VBox/Icon") as TextureRect
	if _left_label == null:
		_left_label = get_node_or_null("SplitWrap/LeftBtn/Margin/VBox/Label") as Label
	if _right_btn == null:
		_right_btn = get_node_or_null("SplitWrap/RightBtn") as Button
	if _right_icon == null:
		_right_icon = get_node_or_null("SplitWrap/RightBtn/Margin/VBox/Icon") as TextureRect
	if _right_label == null:
		_right_label = get_node_or_null("SplitWrap/RightBtn/Margin/VBox/Label") as Label
	if _warn_pill == null:
		_warn_pill = get_node_or_null("WarnPill") as PanelContainer
	if _warn_label == null:
		_warn_label = get_node_or_null("WarnPill/Margin/WarnLabel") as Label


func _apply_warning_banner(p_warning: String) -> void:
	_warning_text = p_warning
	if _warn_pill == null:
		return
	var show_warn := not p_warning.is_empty()
	_warn_pill.visible = show_warn
	if _warn_label != null:
		_warn_label.text = p_warning
		_warn_label.add_theme_color_override("font_color", UIColors.ALERT)
	if show_warn:
		_apply_pill_style(_warn_pill, UIColors.ALERT, true)


func _apply_button_styles(btn: Button, accent: Color, available: bool, radius: int) -> void:
	var bg_normal := Color(0.08, 0.10, 0.15, 0.92) if available else Color(0.10, 0.11, 0.14, 0.64)
	var bg_hover := Color(0.13, 0.16, 0.24, 0.96) if available else Color(0.12, 0.13, 0.17, 0.72)
	var bg_pressed := Color(0.16, 0.20, 0.30, 0.98) if available else Color(0.14, 0.12, 0.14, 0.78)
	var border_col := accent if available else UIColors.MUTED
	var border_w: int = 3 if available else 2

	btn.add_theme_stylebox_override("normal", _make_style(bg_normal, border_col, border_w, radius, 6 if available else 0))
	btn.add_theme_stylebox_override("hover", _make_style(bg_hover, border_col.lightened(0.15), border_w, radius, 8 if available else 0))
	btn.add_theme_stylebox_override("pressed", _make_style(bg_pressed, border_col.lightened(0.25), border_w, radius, 4 if available else 0))
	btn.add_theme_stylebox_override("focus", _make_style(bg_normal, border_col, border_w, radius, 0))


func _apply_pill_style(pill: PanelContainer, accent: Color, available: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.13, 0.95) if available else Color(0.10, 0.11, 0.14, 0.75)
	sb.border_color = accent if available else UIColors.MUTED
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	pill.add_theme_stylebox_override("panel", sb)


func _make_style(bg: Color, border: Color, bw: int, radius: int, shadow: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = bw
	sb.border_width_top = bw
	sb.border_width_right = bw
	sb.border_width_bottom = bw
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	if shadow > 0:
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
		sb.shadow_size = shadow
	return sb


func _emit_choice(job: String, available: bool, reason: String) -> void:
	if available:
		marker_activated.emit(building_key, job)
	else:
		disabled_tapped.emit(building_key, job, reason)


func _on_circle_pressed() -> void:
	_emit_choice(_primary_job, _primary_available, _primary_reason)


func _on_left_pressed() -> void:
	_emit_choice(_left_job, _left_available, _left_reason)


func _on_right_pressed() -> void:
	_emit_choice(_right_job, _right_available, _right_reason)


func pulse_highlight() -> void:
	is_pulsing = true
	z_index = 4
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	if not is_inside_tree():
		return
	pivot_offset = size * 0.5
	_pulse_tween = create_tween()
	for _i in range(3):
		_pulse_tween.tween_property(self, "scale", Vector2(1.22, 1.22), 0.16)
		_pulse_tween.parallel().tween_property(self, "modulate", Color(1.3, 1.15, 0.65, 1.0), 0.16)
		_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.18)
		_pulse_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.18)
	_pulse_tween.tween_callback(func(): is_pulsing = false)

