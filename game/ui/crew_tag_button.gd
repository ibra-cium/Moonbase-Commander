class_name CrewTagButton
extends WorldAnchor

## Tappable 2D WorldAnchor pill tracking an outdoor astronaut's 3D NameTag.

signal tag_pressed(crew_index: int)

const HIT_SIZE := Vector2(96.0, 64.0)
const PILL_RADIUS: int = 8
const BORDER_NORMAL: int = 2
const BORDER_SELECTED: int = 3
const SELECTED_SCALE := Vector2(1.08, 1.08)

var crew_index: int = 0
var _suit_color: Color = Color.WHITE
var _crew_name: String = ""
var _selected: bool = false
var _overlay_enabled: bool = false
var _astronaut: Node3D = null

var _hit_btn: Button = null
var _tag_panel: PanelContainer = null
var _suit_dot: ColorRect = null
var _name_label: Label = null


var _use_i18n_name: bool = false

func _ready() -> void:
	super._ready()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = HIT_SIZE
	size = HIT_SIZE
	pivot_offset = HIT_SIZE * 0.5
	_ensure_wired()
	_apply_style()
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)


func _ensure_wired() -> void:
	_ensure_nodes()
	if _hit_btn != null and not _hit_btn.pressed.is_connected(_on_hit_pressed):
		_hit_btn.pressed.connect(_on_hit_pressed)


func _process(delta: float) -> void:
	var should_show := _can_display()
	tracking_enabled = should_show
	visible = should_show
	if not should_show:
		return
	super._process(delta)


## Binds this overlay button to an Astronaut instance and its NameTag anchor.
func _resolved_crew_name(idx: int) -> String:
	var key: String = "CREW_NAME_%d" % clampi(idx, 0, 3)
	var translated: String = tr(key)
	return translated if translated != key and not translated.is_empty() else ""

func setup(p_index: int, p_name: String, p_suit_color: Color, p_astronaut: Node3D, p_anchor: Node3D) -> void:
	_ensure_wired()
	crew_index = p_index
	var resolved: String = _resolved_crew_name(p_index)
	_use_i18n_name = (not resolved.is_empty() and p_name == resolved)
	_crew_name = resolved if _use_i18n_name else p_name
	_suit_color = p_suit_color
	_astronaut = p_astronaut
	if p_anchor != null:
		set_anchor_node(p_anchor, Vector3.ZERO)
	elif p_astronaut != null:
		set_anchor_node(p_astronaut, Vector3(0.0, 1.48, 0.0))
	if _name_label != null:
		_name_label.text = _crew_name
	if _suit_dot != null:
		_suit_dot.color = _suit_color
	_apply_style()

func refresh_language() -> void:
	if not _use_i18n_name:
		return
	var resolved: String = _resolved_crew_name(crew_index)
	if not resolved.is_empty():
		_crew_name = resolved
		if _name_label != null:
			_name_label.text = _crew_name

func _on_language_changed(_lang: String) -> void:
	refresh_language()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_language()


func set_overlay_enabled(enabled: bool) -> void:
	_overlay_enabled = enabled
	tracking_enabled = _can_display()
	visible = tracking_enabled
	if tracking_enabled:
		update_position()


func set_selected(selected: bool) -> void:
	_selected = selected
	scale = SELECTED_SCALE if _selected else Vector2.ONE
	_apply_style()


func _can_display() -> bool:
	if not _overlay_enabled or _astronaut == null or not is_instance_valid(_astronaut):
		return false
	if not _astronaut.visible:
		return false
	if _astronaut.has_method("is_name_tag_hidden") and _astronaut.is_name_tag_hidden():
		return false
	return true


func _ensure_nodes() -> void:
	if _hit_btn == null:
		_hit_btn = get_node_or_null("HitBtn") as Button
	if _tag_panel == null:
		_tag_panel = get_node_or_null("CenterBox/TagPanel") as PanelContainer
	if _suit_dot == null:
		_suit_dot = get_node_or_null("CenterBox/TagPanel/Margin/HBox/SuitDot") as ColorRect
	if _name_label == null:
		_name_label = get_node_or_null("CenterBox/TagPanel/Margin/HBox/NameLabel") as Label


func _apply_style() -> void:
	if _tag_panel == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.16, 0.23, 0.96) if _selected else Color(0.08, 0.09, 0.13, 0.90)
	sb.border_color = UIColors.POWER if _selected else _suit_color
	var bw: int = BORDER_SELECTED if _selected else BORDER_NORMAL
	sb.border_width_left = bw
	sb.border_width_top = bw
	sb.border_width_right = bw
	sb.border_width_bottom = bw
	sb.corner_radius_top_left = PILL_RADIUS
	sb.corner_radius_top_right = PILL_RADIUS
	sb.corner_radius_bottom_right = PILL_RADIUS
	sb.corner_radius_bottom_left = PILL_RADIUS
	if _selected:
		sb.shadow_color = Color(UIColors.POWER.r, UIColors.POWER.g, UIColors.POWER.b, 0.45)
		sb.shadow_size = 6
	_tag_panel.add_theme_stylebox_override("panel", sb)


func _on_hit_pressed() -> void:
	tag_pressed.emit(crew_index)

