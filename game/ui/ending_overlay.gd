class_name EndingOverlay
extends Control

signal skip_pressed

const SafeArea := preload("res://ui/safe_area.gd")

@onready var title_label: Label = $TopBanner/Margin/TitleLabel
@onready var skip_button: Button = $TopRightMargin/SkipButton

var _is_success: bool = true

func _ensure_nodes() -> void:
	if title_label == null:
		title_label = get_node_or_null("TopBanner/Margin/TitleLabel") as Label
	if skip_button == null:
		skip_button = get_node_or_null("TopRightMargin/SkipButton") as Button

func _ready() -> void:
	_ensure_nodes()
	if skip_button != null and not skip_button.pressed.is_connected(_on_skip_button_pressed):
		skip_button.pressed.connect(_on_skip_button_pressed)
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)
	_refresh_language_texts()
	_apply_safe_area()
	SafeArea.connect_resize(self, _apply_safe_area)

func _apply_safe_area() -> void:
	var insets: Dictionary = SafeArea.get_insets(self)
	var t: float = float(insets.get("top", 0))
	var r: float = float(insets.get("right", 0))
	var banner := get_node_or_null("TopBanner") as Control
	if banner != null:
		banner.offset_top = 24.0 + t
		banner.offset_bottom = 88.0 + t
	var top_right := get_node_or_null("TopRightMargin") as Control
	if top_right != null:
		top_right.offset_left = -180.0 - r
		top_right.offset_right = -24.0 - r
		top_right.offset_top = 24.0 + t
		top_right.offset_bottom = 88.0 + t

func setup(is_success: bool) -> void:
	_is_success = is_success
	_refresh_language_texts()

func _refresh_language_texts() -> void:
	_ensure_nodes()
	if title_label != null:
		title_label.text = tr("ENDING_SUCCESS_TITLE") if _is_success else tr("ENDING_EVAC_TITLE")
	if skip_button != null:
		skip_button.text = tr("BTN_SKIP")

func _on_language_changed(_lang: String) -> void:
	_refresh_language_texts()

func _on_skip_button_pressed() -> void:
	if Audio != null:
		Audio.play("ui_click")
	skip_pressed.emit()

