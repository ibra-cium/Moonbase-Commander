class_name SourceTag
extends Control

signal opened
signal closed

@export var constant_id: String = "":
	set(val):
		constant_id = val
		if not constant_id.is_empty():
			_fact_meta.clear()
		_ensure_nodes()
		_refresh()

@export var dynamic_value: Variant = null

var info_button: Button
var popover_layer: CanvasLayer
var backdrop: Control
var popover_panel: PanelContainer
var title_label: Label
var close_button: Button
var value_label: Label
var type_label: Label
var source_label: Label
var link_label: Label
var game_choice_label: Label

var _current_meta: Dictionary = {}
var _fact_meta: Dictionary = {}

func _ensure_nodes() -> void:
	if info_button != null:
		return
	info_button = get_node_or_null("InfoButton")
	popover_layer = get_node_or_null("PopoverLayer")
	if popover_layer != null:
		backdrop = popover_layer.get_node_or_null("Backdrop")
		popover_panel = popover_layer.get_node_or_null("CenterContainer/PopoverPanel")
		title_label = popover_layer.get_node_or_null("CenterContainer/PopoverPanel/Margin/VBox/Header/TitleLabel")
		close_button = popover_layer.get_node_or_null("CenterContainer/PopoverPanel/Margin/VBox/Header/CloseButton")
		value_label = popover_layer.get_node_or_null("CenterContainer/PopoverPanel/Margin/VBox/ValueLabel")
		type_label = popover_layer.get_node_or_null("CenterContainer/PopoverPanel/Margin/VBox/TypeLabel")
		source_label = popover_layer.get_node_or_null("CenterContainer/PopoverPanel/Margin/VBox/SourceLabel")
		link_label = popover_layer.get_node_or_null("CenterContainer/PopoverPanel/Margin/VBox/LinkLabel")
		game_choice_label = popover_layer.get_node_or_null("CenterContainer/PopoverPanel/Margin/VBox/GameChoiceLabel")

func _ready() -> void:
	_ensure_nodes()
	if popover_layer != null:
		popover_layer.visible = false
	if info_button != null and not info_button.pressed.is_connected(show_popover):
		info_button.pressed.connect(show_popover)
	if backdrop != null and not backdrop.gui_input.is_connected(_on_backdrop_gui_input):
		backdrop.gui_input.connect(_on_backdrop_gui_input)
	if close_button != null and not close_button.pressed.is_connected(hide_popover):
		close_button.pressed.connect(hide_popover)
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)
	_refresh()

func setup(id: String, override_value: Variant = null) -> void:
	_ensure_nodes()
	_fact_meta.clear()
	constant_id = id
	dynamic_value = override_value
	_refresh()


## Configure the source tag to show a fact's NASA source and link.
func setup_fact(fact_dict: Dictionary) -> void:
	_ensure_nodes()
	_fact_meta = fact_dict.duplicate(true)
	_current_meta.clear()
	constant_id = ""
	dynamic_value = null
	_refresh()


func _refresh() -> void:
	_ensure_nodes()
	if not _fact_meta.is_empty():
		visible = true
		_update_popover_content()
		return

	if constant_id.is_empty():
		visible = false
		return
	
	visible = true
	if not Constants.has(constant_id):
		return
	
	_current_meta = Constants.meta(constant_id)
	_update_popover_content()

func _update_popover_content() -> void:
	_ensure_nodes()
	if title_label == null:
		return

	if not _fact_meta.is_empty():
		title_label.text = tr("BRIEF_FACT_BADGE")
		if value_label != null:
			value_label.visible = false
		if type_label != null:
			type_label.visible = false
		var fact_source: String = str(_fact_meta.get("source", ""))
		if source_label != null:
			source_label.text = "%s: %s" % [tr("SRC_SOURCE"), fact_source]
		var fact_link: String = str(_fact_meta.get("link", "")).strip_edges()
		if link_label != null:
			link_label.visible = not fact_link.is_empty()
			link_label.text = fact_link
		if game_choice_label != null:
			game_choice_label.visible = false
		return

	if _current_meta.is_empty():
		return

	if value_label != null:
		value_label.visible = true
	if type_label != null:
		type_label.visible = true
	if link_label != null:
		link_label.visible = false

	var label_text: String = str(_current_meta.get("label", constant_id))
	title_label.text = label_text

	var val: Variant = dynamic_value if dynamic_value != null else _current_meta.get("value", "")
	var unit: String = str(_current_meta.get("unit", ""))
	if unit.is_empty():
		value_label.text = "%s: %s" % [tr("SRC_VALUE"), str(val)]
	else:
		value_label.text = "%s: %s %s" % [tr("SRC_VALUE"), str(val), unit]

	var meta_type: String = str(_current_meta.get("type", ""))
	type_label.text = "%s: %s" % [tr("SRC_TYPE"), meta_type]

	var meta_source: String = str(_current_meta.get("source", ""))
	source_label.text = "%s: %s" % [tr("SRC_SOURCE"), meta_source]

	var is_game_choice: bool = (meta_type == "Game setting" or meta_type == "Game assumption")
	game_choice_label.visible = is_game_choice
	if is_game_choice:
		game_choice_label.text = tr("SRC_GAME_CHOICE")

func show_popover() -> void:
	_play_audio("ui_click")
	_update_popover_content()
	if popover_layer != null:
		popover_layer.visible = true
	opened.emit()

func hide_popover() -> void:
	_play_audio("ui_click")
	if popover_layer != null:
		popover_layer.visible = false
	closed.emit()

func _play_audio(sound_name: String) -> void:
	if Audio != null:
		Audio.play(sound_name)

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_popover()
	elif event is InputEventScreenTouch and event.pressed:
		hide_popover()

func _on_language_changed(_lang: String) -> void:
	_update_popover_content()
