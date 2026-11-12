class_name EventPopup
extends CanvasLayer

signal choice_selected(choice_index: int)
signal closed
signal countdown_finished

const STORM_COUNTDOWN_SEC: float = 3.0
const STORM_COUNTDOWN_FAST_SEC: float = 1.0
const COLOR_DANGER := Color(0.878431, 0.282353, 0.282353, 1.0)
const COLOR_WARN := Color(0.94902, 0.756863, 0.305882, 1.0)
const COLOR_SAFE := Color(0.266667, 0.701961, 0.352941, 1.0)
const COLOR_BAR_BG := Color(0.133333, 0.156863, 0.211765, 1.0)

var center_container: CenterContainer
var tone_ribbon: ColorRect
var source_tag: Control
var alert_bar: ProgressBar
var _anim_tween: Tween = null
var _countdown_active: bool = false
var _countdown_elapsed: float = 0.0
var _countdown_duration: float = STORM_COUNTDOWN_SEC
var _countdown_start_val: float = 0.0
var _countdown_template: String = ""
var _countdown_buttons: Array = []
var _tone_color: Color = COLOR_DANGER

var backdrop: ColorRect
var panel: PanelContainer
var icon_rect: TextureRect
var title_label: Label
var message_label: Label
var button_box: HBoxContainer

var _choices: Array = []
var _last_title_key: String = ""
var _last_body_key: String = ""

func _ensure_nodes() -> void:
	if backdrop != null:
		return
	backdrop = get_node_or_null("Backdrop")
	center_container = get_node_or_null("Center")
	panel = get_node_or_null("Center/Panel")
	tone_ribbon = get_node_or_null("Center/Panel/Margin/VBox/ToneRibbon")
	icon_rect = get_node_or_null("Center/Panel/Margin/VBox/Header/IconRect")
	title_label = get_node_or_null("Center/Panel/Margin/VBox/Header/TitleLabel")
	source_tag = get_node_or_null("Center/Panel/Margin/VBox/Header/SourceTag")
	message_label = get_node_or_null("Center/Panel/Margin/VBox/MessageLabel")
	alert_bar = get_node_or_null("Center/Panel/Margin/VBox/AlertBar")
	button_box = get_node_or_null("Center/Panel/Margin/VBox/ButtonBox")
	if source_tag != null and "popover_layer" in source_tag and source_tag.popover_layer != null:
		source_tag.popover_layer.layer = layer + 5

func _ready() -> void:
	_ensure_nodes()
	visible = false
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)

func _on_language_changed(_lang: String) -> void:
	if not visible:
		return
	_ensure_nodes()
	if title_label != null and not _last_title_key.is_empty():
		title_label.text = tr(_last_title_key)
	if message_label != null and not _countdown_active and not _last_body_key.is_empty():
		message_label.text = tr(_last_body_key)
	if button_box != null:
		var btns := button_box.get_children()
		for i in range(mini(btns.size(), _choices.size())):
			var btn := btns[i] as Button
			if btn != null:
				btn.text = tr(str(_choices[i]))

func popup_event(title_text: String, message_text: String, options: Array = [], icon: Texture2D = null) -> void:
	_ensure_nodes()
	_reset_alert_state()
	_ensure_nodes()
	_last_title_key = title_text
	_last_body_key = message_text
	if title_label != null:
		title_label.text = tr(title_text)
	if message_label != null:
		message_label.text = tr(message_text)
	
	if icon_rect != null:
		if icon != null:
			icon_rect.texture = icon
			icon_rect.visible = true
		else:
			icon_rect.visible = false
	
	if button_box != null:
		for child in button_box.get_children():
			child.queue_free()
		
		_choices = options if not options.is_empty() else ["POPUP_OK"]
		for i in range(_choices.size()):
			var btn := Button.new()
			btn.text = tr(_choices[i])
			btn.custom_minimum_size = Vector2(140, 64)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.pressed.connect(_on_choice_pressed.bind(i))
			button_box.add_child(btn)
	
	visible = true

func select_choice(idx: int) -> void:
	_on_choice_pressed(idx)

func _on_choice_pressed(idx: int) -> void:
	_countdown_active = false
	if source_tag != null and source_tag.has_method("hide_popover"):
		source_tag.hide_popover()
	_play_audio("ui_confirm")
	visible = false
	choice_selected.emit(idx)
	closed.emit()

func _process(delta: float) -> void:
	if not visible:
		_countdown_active = false
		return
	if not _countdown_active:
		return
	_countdown_elapsed += delta
	var frac: float = clampf(_countdown_elapsed / maxf(_countdown_duration, 0.01), 0.0, 1.0)
	var mins_left: int = maxi(0, int(ceil((1.0 - frac) * _countdown_start_val)))
	_update_countdown_text(mins_left)
	if frac >= 1.0:
		_finish_countdown()

func popup_alert(icon: Texture2D, title_text: String, body_text: String, tone: String, buttons: Array, extra: Dictionary = {}) -> void:
	_ensure_nodes()
	_reset_alert_state()
	_last_title_key = title_text
	_last_body_key = body_text
	_tone_color = _color_for_tone(tone)
	_apply_alert_layout(icon, title_text, body_text)
	_configure_alert_extras(extra, buttons)
	visible = true
	_animate_alert_card(tone == "danger")

func set_alert_bar(val: float, max_val: float, bar_color: Variant = null) -> void:
	_ensure_nodes()
	if alert_bar == null:
		return
	var safe_max: float = maxf(max_val, 0.001)
	alert_bar.min_value = 0.0
	alert_bar.max_value = safe_max
	alert_bar.value = clampf(val, 0.0, safe_max)
	var fill_col: Color = bar_color if bar_color is Color else _tone_color
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = COLOR_BAR_BG
	bg_box.set_corner_radius_all(4)
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = fill_col
	fill_box.set_corner_radius_all(4)
	alert_bar.add_theme_stylebox_override("background", bg_box)
	alert_bar.add_theme_stylebox_override("fill", fill_box)
	alert_bar.visible = true

func set_source_tag(const_id: String, override_val: Variant = null) -> void:
	_ensure_nodes()
	if source_tag == null or const_id.is_empty():
		return
	if source_tag.has_method("setup"):
		source_tag.setup(const_id, override_val)
	if "popover_layer" in source_tag and source_tag.popover_layer != null:
		source_tag.popover_layer.layer = layer + 5
	source_tag.visible = true

func start_countdown(from_val: float, duration_sec: float, template_text: String, deferred_buttons: Array) -> void:
	_ensure_nodes()
	_countdown_active = true
	_countdown_elapsed = 0.0
	_countdown_duration = maxf(duration_sec, 0.01)
	_countdown_start_val = from_val
	_countdown_template = template_text
	_countdown_buttons = deferred_buttons.duplicate()
	_update_countdown_text(int(round(from_val)))
	_set_alert_buttons([])
	if button_box != null:
		button_box.custom_minimum_size.y = 52.0

func finish_countdown_now() -> void:
	if _countdown_active:
		_finish_countdown()

func is_countdown_active() -> bool:
	return _countdown_active

func dismiss_silent() -> void:
	_ensure_nodes()
	_reset_alert_state()
	visible = false

func _finish_countdown() -> void:
	_countdown_active = false
	_update_countdown_text(0)
	_set_alert_buttons(_countdown_buttons)
	countdown_finished.emit()

func _update_countdown_text(mins_left: int) -> void:
	if message_label != null and not _countdown_template.is_empty():
		message_label.text = _countdown_template.format({"min": mins_left})

func _apply_alert_layout(icon: Texture2D, title_text: String, body_text: String) -> void:
	if panel != null:
		panel.custom_minimum_size = Vector2(560.0, 0.0)
	if tone_ribbon != null:
		tone_ribbon.color = _tone_color
		tone_ribbon.visible = true
	if icon_rect != null:
		icon_rect.texture = icon
		icon_rect.visible = icon != null
		icon_rect.custom_minimum_size = Vector2(52.0, 52.0)
		icon_rect.modulate = _tone_color
	if title_label != null:
		title_label.text = tr(title_text)
		title_label.add_theme_font_size_override("font_size", 22)
		title_label.max_lines_visible = 1
	if message_label != null:
		message_label.text = tr(body_text)
		message_label.custom_minimum_size = Vector2(0.0, 32.0)
		message_label.max_lines_visible = 1

func _configure_alert_extras(extra: Dictionary, buttons: Array) -> void:
	if extra.has("bar_value") and extra.has("bar_max"):
		set_alert_bar(float(extra["bar_value"]), float(extra["bar_max"]), extra.get("bar_color", _tone_color))
	if extra.has("source_id"):
		set_source_tag(str(extra["source_id"]), extra.get("source_override", null))
	if extra.has("countdown_start") and extra.has("countdown_sec"):
		start_countdown(
			float(extra["countdown_start"]),
			float(extra["countdown_sec"]),
			str(extra.get("countdown_template", "")),
			buttons
		)
	else:
		_set_alert_buttons(buttons)

func _color_for_tone(tone: String) -> Color:
	if tone == "safe":
		return COLOR_SAFE
	if tone == "warn":
		return COLOR_WARN
	return COLOR_DANGER

func _set_alert_buttons(buttons: Array) -> void:
	_choices = buttons.duplicate()
	_clear_buttons()
	if button_box == null:
		return
	button_box.visible = true
	for i in range(buttons.size()):
		var btn := Button.new()
		btn.text = tr(str(buttons[i]))
		btn.custom_minimum_size = Vector2(140.0, 64.0)
		btn.pressed.connect(_on_choice_pressed.bind(i))
		button_box.add_child(btn)

func _clear_buttons() -> void:
	if button_box == null:
		return
	for ch in button_box.get_children():
		button_box.remove_child(ch)
		ch.queue_free()

func _reset_alert_state() -> void:
	_countdown_active = false
	_countdown_elapsed = 0.0
	_countdown_buttons.clear()
	_countdown_template = ""
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = null
	if center_container != null:
		center_container.position = Vector2.ZERO
	if panel != null:
		panel.modulate = Color.WHITE
		panel.custom_minimum_size = Vector2(500.0, 0.0)
	if tone_ribbon != null:
		tone_ribbon.visible = false
	if alert_bar != null:
		alert_bar.visible = false
	if source_tag != null:
		if source_tag.has_method("hide_popover"):
			source_tag.hide_popover()
		source_tag.visible = false
	if icon_rect != null:
		icon_rect.visible = true
		icon_rect.custom_minimum_size = Vector2(32.0, 32.0)
		icon_rect.modulate = Color.WHITE
	if title_label != null:
		title_label.remove_theme_font_size_override("font_size")
		title_label.max_lines_visible = -1
	if message_label != null:
		message_label.custom_minimum_size = Vector2(0.0, 56.0)
		message_label.max_lines_visible = 2
	if button_box != null:
		button_box.custom_minimum_size.y = 0.0

func _animate_alert_card(with_shake: bool) -> void:
	if not is_inside_tree() or panel == null or center_container == null:
		return
	center_container.position = Vector2(0.0, -28.0)
	panel.modulate.a = 0.0
	_anim_tween = create_tween()
	_anim_tween.set_parallel(true)
	_anim_tween.tween_property(center_container, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	if with_shake:
		_anim_tween.chain().set_parallel(false)
		_anim_tween.tween_property(center_container, "position:x", 9.0, 0.04)
		_anim_tween.tween_property(center_container, "position:x", -9.0, 0.05)
		_anim_tween.tween_property(center_container, "position:x", 5.0, 0.04)
		_anim_tween.tween_property(center_container, "position:x", 0.0, 0.04)

func _play_audio(sound_name: String) -> void:
	if Audio != null:
		Audio.play(sound_name)

func close() -> void:
	visible = false
	closed.emit()
