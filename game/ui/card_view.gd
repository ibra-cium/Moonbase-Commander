class_name CardView
extends CanvasLayer

signal closed(fact_id: String)

const LearningDataScript := preload("res://ui/learning_data.gd")
const SafeArea := preload("res://ui/safe_area.gd")

var safe_margin: MarginContainer
var card_panel: PanelContainer
var category_band: PanelContainer
var category_icon: TextureRect
var category_label: Label
var title_label: Label
var body_scroll: ScrollContainer
var fact_label: Label
var source_name_label: Label
var source_tag: SourceTag
var album_hint_label: Label
var close_button: Button
var backdrop: ColorRect

var _learning: LearningData = LearningDataScript.new()
var _current_fact_id: String = ""
var _band_style: StyleBoxFlat = null
var _panel_style: StyleBoxFlat = null


func _ensure_nodes() -> void:
	if safe_margin != null:
		return
	safe_margin = get_node_or_null("Root/SafeMargin")
	card_panel = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel")
	category_band = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/CategoryBand")
	category_icon = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/CategoryBand/BandHBox/CardIcon")
	category_label = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/CategoryBand/BandHBox/CategoryLabel")
	title_label = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/BodyMargin/BodyVBox/TitleLabel")
	body_scroll = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/BodyMargin/BodyVBox/BodyScroll")
	fact_label = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/BodyMargin/BodyVBox/BodyScroll/FactLabel")
	source_name_label = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/BodyMargin/BodyVBox/SourceRow/SourceNameLabel")
	source_tag = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/BodyMargin/BodyVBox/SourceRow/CardSourceTag")
	album_hint_label = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/BodyMargin/BodyVBox/AlbumHintLabel")
	close_button = get_node_or_null("Root/SafeMargin/CenterContainer/CardPanel/OuterVBox/BodyMargin/BodyVBox/CloseRow/CloseButton")
	backdrop = get_node_or_null("Root/Backdrop")


func _ready() -> void:
	_ensure_nodes()
	visible = false
	_init_styles()
	if close_button != null and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if backdrop != null and not backdrop.gui_input.is_connected(_on_backdrop_gui_input):
		backdrop.gui_input.connect(_on_backdrop_gui_input)
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)
	var root_ctrl := get_node_or_null("Root") as Control
	if root_ctrl != null:
		SafeArea.connect_resize(root_ctrl, _update_layout)
	_update_layout()


func _init_styles() -> void:
	if _panel_style == null:
		_panel_style = StyleBoxFlat.new()
		_panel_style.bg_color = Color("141821FA")
		_panel_style.border_color = Color("33415C")
		_panel_style.set_border_width_all(2)
		_panel_style.set_corner_radius_all(14)
		_panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
		_panel_style.shadow_size = 16
		_panel_style.shadow_offset = Vector2(0, 6)
		if card_panel != null:
			card_panel.add_theme_stylebox_override("panel", _panel_style)

	if _band_style == null:
		_band_style = StyleBoxFlat.new()
		_band_style.bg_color = UIColors.REGOLITH
		_band_style.corner_radius_top_left = 12
		_band_style.corner_radius_top_right = 12
		_band_style.corner_radius_bottom_left = 0
		_band_style.corner_radius_bottom_right = 0
		_band_style.content_margin_left = 18
		_band_style.content_margin_right = 18
		_band_style.content_margin_top = 12
		_band_style.content_margin_bottom = 12
		if category_band != null:
			category_band.add_theme_stylebox_override("panel", _band_style)


func open_card(fact_id: String) -> void:
	if fact_id.is_empty():
		return
	_ensure_nodes()
	_current_fact_id = fact_id
	_init_styles()
	_refresh()
	visible = true
	_update_layout()


func close_card() -> void:
	if not visible:
		return
	var closing_id: String = _current_fact_id
	visible = false
	if Audio != null:
		Audio.play("ui_click")
	closed.emit(closing_id)


func current_fact_id() -> String:
	return _current_fact_id


func _refresh() -> void:
	var card: Dictionary = _learning.card_by_fact_id(_current_fact_id)
	var fact: Dictionary = _learning.fact(_current_fact_id)
	var cat: String = str(card.get("category", "moon"))
	var band_col: Color = LearningDataScript.category_color(cat)

	if _band_style != null:
		_band_style.bg_color = band_col
	if _panel_style != null:
		_panel_style.border_color = band_col

	var on_band_dark: bool = (cat == "nasa" or cat == "moon")
	var band_fg: Color = Color("0B1018") if on_band_dark else Color("FFFFFF")

	if category_icon != null:
		category_icon.texture = LearningDataScript.card_icon(card)
		category_icon.modulate = band_fg

	if category_label != null:
		category_label.text = _category_label_text(cat).to_upper()
		category_label.add_theme_color_override("font_color", band_fg)

	if title_label != null:
		var card_title: String = _learning.text(card.get("title", {}))
		title_label.text = card_title if not card_title.is_empty() else _current_fact_id

	if fact_label != null:
		fact_label.text = _learning.text(fact)

	var fact_source: String = str(fact.get("source", ""))
	if source_name_label != null:
		source_name_label.text = "%s: %s" % [tr("SRC_SOURCE"), fact_source] if not fact_source.is_empty() else ""

	if source_tag != null:
		if not fact.is_empty():
			source_tag.setup_fact(fact)
			source_tag.visible = true
		else:
			source_tag.visible = false

	if album_hint_label != null:
		album_hint_label.text = tr("CARD_SAVED_ALBUM")

	if close_button != null:
		close_button.text = tr("CARD_CLOSE")


func _category_label_text(cat: String) -> String:
	match cat:
		"moon":
			return tr("CARD_TAB_MOON")
		"survival":
			return tr("CARD_TAB_SURVIVAL")
		"nasa":
			return tr("CARD_TAB_NASA")
		_:
			return tr("CARD_TAB_ALL")


func _update_layout() -> void:
	_ensure_nodes()
	var root_ctrl := get_node_or_null("Root") as Control
	var insets: Dictionary = SafeArea.get_insets(root_ctrl if root_ctrl != null else self)
	if safe_margin != null:
		SafeArea.apply_margin(safe_margin, 16, 16, 16, 16, insets)

	var vp_size := Vector2(1280.0, 720.0)
	if is_inside_tree() and get_viewport() != null:
		vp_size = get_viewport().get_visible_rect().size
	var avail_w: float = maxf(280.0, vp_size.x - float(insets["left"]) - float(insets["right"]) - 36.0)
	var avail_h: float = maxf(260.0, vp_size.y - float(insets["top"]) - float(insets["bottom"]) - 36.0)
	var is_portrait: bool = vp_size.y > vp_size.x

	if card_panel != null:
		var target_w: float = minf(680.0, avail_w - 16.0) if is_portrait else minf(560.0, avail_w)
		card_panel.custom_minimum_size = Vector2(target_w, 0.0)

	if body_scroll != null:
		var max_scroll_h: float = clampf(avail_h * 0.48, 120.0, 340.0)
		body_scroll.custom_minimum_size = Vector2(0.0, clampf(max_scroll_h * 0.65, 96.0, max_scroll_h))


func _on_close_pressed() -> void:
	close_card()


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_card()
	elif event is InputEventScreenTouch and event.pressed:
		close_card()


func _on_language_changed(_lang: String) -> void:
	if not _current_fact_id.is_empty():
		_refresh()
