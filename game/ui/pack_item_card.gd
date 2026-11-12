class_name PackItemCard
extends PanelContainer

signal count_changed(item_key: String, new_count: int)

const ICON_LOCK: Texture2D = preload("res://assets/icons/lock.svg")

var item_key: String = ""
var item_name_key: String = ""
var unit_mass: float = 0.0
var max_units: int = 0
var is_greenhouse: bool = false
var size_options: Array = []
var count: int = 0

var _locked_count: int = -1  # -1 means not locked; >= 0 means locked at that value
var _lock_hint: String = ""

var icon_rect: TextureRect
var name_label: Label
var mass_label: Label
var btn_minus: Button
var count_label: Label
var btn_plus: Button
var lock_icon: TextureRect
var lock_label: Label

func _ensure_nodes() -> void:
	if btn_plus != null:
		return
	icon_rect = get_node_or_null("Margin/HBox/IconRect")
	name_label = get_node_or_null("Margin/HBox/InfoVBox/NameLabel")
	mass_label = get_node_or_null("Margin/HBox/InfoVBox/MassLabel")
	btn_minus = get_node_or_null("Margin/HBox/ControlsHBox/BtnMinus")
	count_label = get_node_or_null("Margin/HBox/ControlsHBox/CountLabel")
	btn_plus = get_node_or_null("Margin/HBox/ControlsHBox/BtnPlus")

	var controls_hbox := get_node_or_null("Margin/HBox/ControlsHBox")
	if controls_hbox != null:
		lock_icon = controls_hbox.get_node_or_null("LockIcon") as TextureRect
		if lock_icon == null:
			lock_icon = TextureRect.new()
			lock_icon.name = "LockIcon"
			lock_icon.texture = ICON_LOCK
			lock_icon.custom_minimum_size = Vector2(24, 24)
			lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock_icon.modulate = Color("#F2C14E")
			lock_icon.visible = false
			controls_hbox.add_child(lock_icon)

	var info_vbox := get_node_or_null("Margin/HBox/InfoVBox")
	if info_vbox != null:
		lock_label = info_vbox.get_node_or_null("LockLabel") as Label
		if lock_label == null:
			lock_label = Label.new()
			lock_label.name = "LockLabel"
			lock_label.add_theme_font_size_override("font_size", 12)
			lock_label.modulate = Color("#F2C14E")
			lock_label.visible = false
			info_vbox.add_child(lock_label)

func _ready() -> void:
	_ensure_nodes()
	if btn_minus and not btn_minus.pressed.is_connected(_on_minus_pressed):
		btn_minus.pressed.connect(_on_minus_pressed)
	if btn_plus and not btn_plus.pressed.is_connected(_on_plus_pressed):
		btn_plus.pressed.connect(_on_plus_pressed)
	if Settings != null and Settings.has_signal("language_changed"):
		if not Settings.language_changed.is_connected(_on_language_changed):
			Settings.language_changed.connect(_on_language_changed)
	_update_display()

func setup(
	p_key: String,
	p_name_key: String,
	p_mass: float,
	p_icon: Texture2D,
	p_max: int,
	p_is_gh: bool = false,
	p_options: Array = []
) -> void:
	_ensure_nodes()
	item_key = p_key
	item_name_key = p_name_key
	unit_mass = p_mass
	max_units = p_max
	is_greenhouse = p_is_gh
	size_options = p_options

	if icon_rect and p_icon:
		icon_rect.texture = p_icon

	_update_display()

func set_count(val: int) -> void:
	_ensure_nodes()
	if is_greenhouse and not size_options.is_empty():
		var closest: int = int(size_options[0])
		for opt in size_options:
			if int(opt) == val:
				closest = val
				break
		count = closest
	else:
		count = clampi(val, 0, max_units)
	_update_display()

func get_count() -> int:
	return count

## Lock this card to a fixed count. Pass -1 to unlock.
## When locked, +/- buttons are hidden and a lock icon + hint label are shown.
func set_locked(locked_count: int, hint_text: String) -> void:
	_ensure_nodes()
	_locked_count = locked_count
	_lock_hint = hint_text
	if locked_count >= 0:
		count = locked_count
	_update_display()

func _find_size_option_index(val: int) -> int:
	for i in range(size_options.size()):
		if int(size_options[i]) == val:
			return i
	return -1

func _on_minus_pressed() -> void:
	if _locked_count >= 0:
		return
	if is_greenhouse and not size_options.is_empty():
		var idx: int = _find_size_option_index(count)
		if idx > 0:
			count = int(size_options[idx - 1])
			_update_display()
			_play_audio("ui_click")
			count_changed.emit(item_key, count)
	else:
		if count > 0:
			count -= 1
			_update_display()
			_play_audio("ui_click")
			count_changed.emit(item_key, count)

func _on_plus_pressed() -> void:
	if _locked_count >= 0:
		return
	if is_greenhouse and not size_options.is_empty():
		var idx: int = _find_size_option_index(count)
		if idx >= 0 and idx < size_options.size() - 1:
			count = int(size_options[idx + 1])
			_update_display()
			_play_audio("ui_click")
			count_changed.emit(item_key, count)
	else:
		if count < max_units:
			count += 1
			_update_display()
			_play_audio("ui_click")
			count_changed.emit(item_key, count)

func _play_audio(sound_name: String) -> void:
	if Audio != null:
		Audio.play(sound_name)

func _update_display() -> void:
	if not is_inside_tree() and name_label == null:
		return
	_ensure_nodes()

	if name_label:
		name_label.text = tr(item_name_key)

	if mass_label:
		if is_greenhouse:
			mass_label.text = tr("PACK_UNIT_M2").format({"n": snappedf(unit_mass, 0.1)})
		else:
			mass_label.text = tr("PACK_UNIT_KG").format({"n": snappedf(unit_mass, 0.1)})

	if count_label:
		if is_greenhouse:
			count_label.text = tr("PACK_SIZE_M2").format({"n": count})
		else:
			count_label.text = str(count)

	var is_locked: bool = _locked_count >= 0
	if btn_minus:
		btn_minus.visible = not is_locked
		if is_locked:
			btn_minus.disabled = true
		elif is_greenhouse and not size_options.is_empty():
			btn_minus.disabled = (count <= int(size_options[0]))
		else:
			btn_minus.disabled = (count <= 0)

	if btn_plus:
		btn_plus.visible = not is_locked
		if is_locked:
			btn_plus.disabled = true
		elif is_greenhouse and not size_options.is_empty():
			btn_plus.disabled = (count >= int(size_options[size_options.size() - 1]))
		else:
			btn_plus.disabled = (count >= max_units)

	if lock_icon:
		lock_icon.visible = is_locked

	if lock_label:
		lock_label.visible = is_locked and (_lock_hint != "" or tr("PACK_LOCKED_ITEM") != "PACK_LOCKED_ITEM")
		lock_label.text = _lock_hint if _lock_hint != "" else tr("PACK_LOCKED_ITEM")

func _on_language_changed(_new_lang: String) -> void:
	_update_display()
