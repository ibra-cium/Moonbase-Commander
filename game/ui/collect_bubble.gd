class_name CollectBubble
extends WorldAnchor

signal bubble_tapped(bubble: CollectBubble)
signal collection_arrived(kind: String, amount: float)

const BUBBLE_SIZE := Vector2(72.0, 72.0)
const BOB_SPEED := 2.8
const BOB_AMPLITUDE := 5.0
const FLY_DURATION_TAP := 0.5
const FLY_DURATION_FAST := 0.2
const POP_DURATION := 0.14
const FLY_ICON_SIZE := Vector2(28.0, 28.0)

var kind: String = ""
var amount: float = 0.0
var display_text: String = ""
var accent_color: Color = UIColors.POWER

var _icon_texture: Texture2D = null
var _target_control: Control = null
var _fly_parent: Control = null
var _collecting: bool = false
var _collected_done: bool = false
var _bob_time: float = 0.0
var _bob_phase: float = 0.0
var _active_fly_icon: TextureRect = null
var _active_tween: Tween = null

var _bubble_button: Button = null
var _icon_rect: TextureRect = null
var _value_label: Label = null
var _hint_panel: PanelContainer = null
var _hint_label: Label = null


func _ready() -> void:
	super._ready()
	custom_minimum_size = BUBBLE_SIZE
	size = BUBBLE_SIZE
	_ensure_nodes()
	if _bubble_button != null:
		_bubble_button.pivot_offset = BUBBLE_SIZE * 0.5
		if not _bubble_button.pressed.is_connected(_on_pressed):
			_bubble_button.pressed.connect(_on_pressed)
	_refresh_visuals()


func _process(delta: float) -> void:
	if _collecting:
		return
	super._process(delta)
	if visible and _bubble_button != null:
		_bob_time += delta * BOB_SPEED
		_bubble_button.position.y = sin(_bob_time + _bob_phase) * BOB_AMPLITUDE
		var pulse: float = 1.0 + sin(_bob_time * 1.4 + _bob_phase) * 0.03
		_bubble_button.scale = Vector2(pulse, pulse)


func _exit_tree() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null
	if _active_fly_icon != null and is_instance_valid(_active_fly_icon):
		_active_fly_icon.queue_free()
		_active_fly_icon = null


func setup(spec: Dictionary, target_ctrl: Control, fly_parent: Control, phase_offset: float = 0.0) -> void:
	kind = str(spec.get("kind", ""))
	amount = float(spec.get("amount", 0.0))
	display_text = str(spec.get("text", "+0"))
	accent_color = spec.get("color", UIColors.POWER)
	_icon_texture = spec.get("icon", null)
	world_point = spec.get("anchor", Vector3.ZERO)
	_target_control = target_ctrl
	_fly_parent = fly_parent
	_bob_phase = phase_offset
	_ensure_nodes()
	_refresh_visuals()
	if is_inside_tree() and tracking_enabled:
		update_position()


func show_hint(hint_text: String) -> void:
	_ensure_nodes()
	if _hint_label != null:
		_hint_label.text = hint_text
	if _hint_panel != null:
		_hint_panel.visible = true


func hide_hint() -> void:
	_ensure_nodes()
	if _hint_panel != null:
		_hint_panel.visible = false


func is_collecting() -> bool:
	return _collecting


func is_collected_done() -> bool:
	return _collected_done


func collect(fly_duration: float = FLY_DURATION_TAP, play_sound: bool = true) -> void:
	if _collecting or _collected_done:
		return
	_collecting = true
	tracking_enabled = false
	hide_hint()
	_ensure_nodes()
	if _bubble_button != null:
		_bubble_button.disabled = true
		_bubble_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if play_sound:
		Audio.play("ui_confirm")
	bubble_tapped.emit(self)

	if not is_inside_tree() or fly_duration <= 0.0 or _fly_parent == null:
		_finish_collection()
		return

	_spawn_pop_and_fly(fly_duration)


func finish_immediately() -> void:
	if _collected_done:
		return
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null
	if _active_fly_icon != null and is_instance_valid(_active_fly_icon):
		_active_fly_icon.free()
		_active_fly_icon = null
	_finish_collection()


func _on_pressed() -> void:
	collect(FLY_DURATION_TAP, true)


func _ensure_nodes() -> void:
	if _bubble_button == null:
		_bubble_button = get_node_or_null("BubbleButton") as Button
	if _icon_rect == null:
		_icon_rect = get_node_or_null("BubbleButton/CenterBox/IconRect") as TextureRect
	if _value_label == null:
		_value_label = get_node_or_null("BubbleButton/CenterBox/ValueLabel") as Label
	if _hint_panel == null:
		_hint_panel = get_node_or_null("HintPanel") as PanelContainer
	if _hint_label == null:
		_hint_label = get_node_or_null("HintPanel/HintMargin/HintLabel") as Label


func _refresh_visuals() -> void:
	if _icon_rect != null:
		_icon_rect.texture = _icon_texture
		_icon_rect.modulate = accent_color
	if _value_label != null:
		_value_label.text = display_text
	if _bubble_button != null:
		_apply_button_styles(accent_color)


func _apply_button_styles(border_col: Color) -> void:
	var normal_style := _make_circle_style(Color(0.08, 0.095, 0.13, 0.92), border_col, 10)
	var hover_style := _make_circle_style(Color(0.14, 0.17, 0.24, 0.96), border_col.lightened(0.25), 14)
	var pressed_style := _make_circle_style(Color(border_col.r, border_col.g, border_col.b, 0.35), Color.WHITE, 16)
	_bubble_button.add_theme_stylebox_override("normal", normal_style)
	_bubble_button.add_theme_stylebox_override("hover", hover_style)
	_bubble_button.add_theme_stylebox_override("pressed", pressed_style)
	_bubble_button.add_theme_stylebox_override("disabled", normal_style)


func _make_circle_style(bg_col: Color, border_col: Color, shadow_sz: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 36
	sb.corner_radius_top_right = 36
	sb.corner_radius_bottom_right = 36
	sb.corner_radius_bottom_left = 36
	sb.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.55)
	sb.shadow_size = shadow_sz
	sb.shadow_offset = Vector2.ZERO
	return sb


func _spawn_pop_and_fly(fly_duration: float) -> void:
	var fly_icon := TextureRect.new()
	fly_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fly_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fly_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fly_icon.custom_minimum_size = FLY_ICON_SIZE
	fly_icon.size = FLY_ICON_SIZE
	fly_icon.pivot_offset = FLY_ICON_SIZE * 0.5
	fly_icon.texture = _icon_texture
	fly_icon.modulate = accent_color
	_fly_parent.add_child(fly_icon)

	var start_pos: Vector2 = _get_start_center() - FLY_ICON_SIZE * 0.5
	var end_pos: Vector2 = _get_target_center() - FLY_ICON_SIZE * 0.5
	fly_icon.global_position = start_pos
	fly_icon.scale = Vector2(1.2, 1.2)
	_active_fly_icon = fly_icon

	var pop_time: float = minf(POP_DURATION, fly_duration * 0.6)
	var tween := _fly_parent.create_tween()
	_active_tween = tween
	tween.set_parallel(true)
	if _bubble_button != null:
		tween.tween_property(_bubble_button, "scale", Vector2(1.28, 1.28), pop_time)
		tween.tween_property(_bubble_button, "modulate:a", 0.0, pop_time)
	tween.tween_property(fly_icon, "global_position", end_pos, fly_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fly_icon, "scale", Vector2(0.75, 0.75), fly_duration)
	tween.chain().tween_callback(_on_fly_tween_finished.bind(fly_icon))


func _get_start_center() -> Vector2:
	if _icon_rect != null and _icon_rect.is_inside_tree():
		return _icon_rect.global_position + _icon_rect.size * 0.5
	return global_position + size * 0.5


func _get_target_center() -> Vector2:
	if _target_control != null and is_instance_valid(_target_control) and _target_control.is_inside_tree():
		return _target_control.global_position + _target_control.size * 0.5
	if _fly_parent != null:
		var vp_w: float = _fly_parent.size.x if _fly_parent.size.x > 0.0 else 1280.0
		return Vector2(vp_w * 0.5, 28.0)
	return Vector2(640.0, 28.0)


func _on_fly_tween_finished(fly_icon: TextureRect) -> void:
	if is_instance_valid(fly_icon):
		fly_icon.queue_free()
	if _active_fly_icon == fly_icon:
		_active_fly_icon = null
	_finish_collection()


func _finish_collection() -> void:
	if _collected_done:
		return
	_collected_done = true
	visible = false
	collection_arrived.emit(kind, amount)
	if is_inside_tree():
		queue_free()

