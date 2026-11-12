class_name CardAlbum
extends CanvasLayer

signal closed

const LearningDataScript := preload("res://ui/learning_data.gd")
const SafeArea := preload("res://ui/safe_area.gd")
const ICON_LOCK := preload("res://assets/icons/lock.svg")

const CATEGORY_TABS: Array[Dictionary] = [
	{"id": "all", "key": "CARD_TAB_ALL"},
	{"id": "moon", "key": "CARD_TAB_MOON"},
	{"id": "survival", "key": "CARD_TAB_SURVIVAL"},
	{"id": "nasa", "key": "CARD_TAB_NASA"},
]

var safe_margin: MarginContainer
var album_panel: PanelContainer
var title_label: Label
var count_label: Label
var close_button: Button
var tabs_row: HBoxContainer
var cards_scroll: ScrollContainer
var cards_grid: GridContainer
var card_view: CardView
var backdrop: ColorRect

var _learning: LearningData = LearningDataScript.new()
var _active_category: String = "all"
var _tab_buttons: Dictionary = {}  # cat_id -> Button

var _style_panel: StyleBoxFlat
var _style_tab_idle: StyleBoxFlat
var _style_locked: StyleBoxFlat


func _ensure_nodes() -> void:
	if safe_margin != null:
		return
	safe_margin = get_node_or_null("Root/SafeMargin")
	album_panel = get_node_or_null("Root/SafeMargin/CenterContainer/AlbumPanel")
	title_label = get_node_or_null("Root/SafeMargin/CenterContainer/AlbumPanel/VBox/HeaderRow/TitleVBox/TitleLabel")
	count_label = get_node_or_null("Root/SafeMargin/CenterContainer/AlbumPanel/VBox/HeaderRow/TitleVBox/CountLabel")
	close_button = get_node_or_null("Root/SafeMargin/CenterContainer/AlbumPanel/VBox/HeaderRow/CloseButton")
	tabs_row = get_node_or_null("Root/SafeMargin/CenterContainer/AlbumPanel/VBox/TabsRow")
	cards_scroll = get_node_or_null("Root/SafeMargin/CenterContainer/AlbumPanel/VBox/CardsScroll")
	cards_grid = get_node_or_null("Root/SafeMargin/CenterContainer/AlbumPanel/VBox/CardsScroll/CardsGrid")
	card_view = get_node_or_null("CardView") as CardView
	backdrop = get_node_or_null("Root/Backdrop")


func _ready() -> void:
	_ensure_nodes()
	visible = false
	_init_styles()
	if close_button != null and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if backdrop != null and not backdrop.gui_input.is_connected(_on_backdrop_gui_input):
		backdrop.gui_input.connect(_on_backdrop_gui_input)
	if Settings != null:
		if Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
			Settings.language_changed.connect(_on_language_changed)
		if Settings.has_signal("card_collected") and not Settings.card_collected.is_connected(_on_card_collected):
			Settings.card_collected.connect(_on_card_collected)
	_build_tabs()
	var root_ctrl := get_node_or_null("Root") as Control
	if root_ctrl != null:
		SafeArea.connect_resize(root_ctrl, _update_layout)
	_update_layout()
	refresh()


func _init_styles() -> void:
	if _style_panel != null:
		return
	_style_panel = StyleBoxFlat.new()
	_style_panel.bg_color = Color("141821F5")
	_style_panel.border_color = Color("33415C")
	_style_panel.set_border_width_all(2)
	_style_panel.set_corner_radius_all(14)
	_style_panel.content_margin_left = 20
	_style_panel.content_margin_right = 20
	_style_panel.content_margin_top = 18
	_style_panel.content_margin_bottom = 18
	if album_panel != null:
		album_panel.add_theme_stylebox_override("panel", _style_panel)

	_style_tab_idle = StyleBoxFlat.new()
	_style_tab_idle.bg_color = Color("1B2230")
	_style_tab_idle.border_color = Color("2E3A50")
	_style_tab_idle.set_border_width_all(1)
	_style_tab_idle.set_corner_radius_all(10)
	_style_tab_idle.content_margin_left = 10
	_style_tab_idle.content_margin_right = 10
	_style_tab_idle.content_margin_top = 8
	_style_tab_idle.content_margin_bottom = 8

	_style_locked = StyleBoxFlat.new()
	_style_locked.bg_color = Color("0D1119")
	_style_locked.border_color = Color("263044")
	_style_locked.set_border_width_all(1)
	_style_locked.set_corner_radius_all(10)


func _build_tabs() -> void:
	if tabs_row == null or not _tab_buttons.is_empty():
		return
	for tab in CATEGORY_TABS:
		var cat_id: String = str(tab["id"])
		var btn := Button.new()
		btn.name = "Tab_" + cat_id
		btn.custom_minimum_size = Vector2(80, 64)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(_on_tab_pressed.bind(cat_id))
		tabs_row.add_child(btn)
		_tab_buttons[cat_id] = btn


func open_album(initial_category: String = "all") -> void:
	_ensure_nodes()
	_active_category = initial_category
	_init_styles()
	_build_tabs()
	_update_layout()
	refresh()
	visible = true


func close_album() -> void:
	_ensure_nodes()
	if card_view != null and card_view.visible:
		card_view.visible = false
	if not visible:
		return
	visible = false
	if Audio != null:
		Audio.play("ui_click")
	closed.emit()


func set_category(category: String) -> void:
	_active_category = category
	refresh()


func open_card(fact_id: String) -> void:
	_ensure_nodes()
	if card_view != null:
		card_view.open_card(fact_id)


func refresh() -> void:
	_ensure_nodes()
	_init_styles()
	_build_tabs()

	var collected_arr: Array[String] = Settings.collected_cards if Settings != null else []
	var total: int = _learning.total_cards_count()

	if title_label != null:
		title_label.text = tr("CARD_ALBUM_TITLE")
	if count_label != null:
		count_label.text = tr("CARD_ALBUM_COUNT").format({
			"n": collected_arr.size(),
			"total": total,
		})
	if close_button != null:
		close_button.text = tr("CARD_CLOSE")

	for tab in CATEGORY_TABS:
		var cat_id: String = str(tab["id"])
		var btn: Button = _tab_buttons.get(cat_id)
		if btn == null:
			continue
		btn.text = tr(str(tab["key"]))
		var active: bool = (cat_id == _active_category)
		if active:
			var accent: Color = UIColors.WATER if cat_id == "all" else LearningDataScript.category_color(cat_id)
			var sb := StyleBoxFlat.new()
			sb.bg_color = accent.darkened(0.68)
			sb.border_color = accent
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(10)
			sb.content_margin_left = 10
			sb.content_margin_right = 10
			sb.content_margin_top = 8
			sb.content_margin_bottom = 8
			btn.add_theme_stylebox_override("normal", sb)
			btn.add_theme_stylebox_override("hover", sb)
			btn.add_theme_stylebox_override("pressed", sb)
			btn.add_theme_color_override("font_color", UIColors.TEXT)
		else:
			btn.add_theme_stylebox_override("normal", _style_tab_idle)
			btn.add_theme_stylebox_override("hover", _style_tab_idle)
			btn.add_theme_stylebox_override("pressed", _style_tab_idle)
			btn.add_theme_color_override("font_color", UIColors.MUTED)

	_rebuild_grid(collected_arr)


func _rebuild_grid(collected_arr: Array[String]) -> void:
	if cards_grid == null:
		return
	for child in cards_grid.get_children():
		cards_grid.remove_child(child)
		child.queue_free()

	var cards: Array = _learning.cards_by_category(_active_category)
	var vp_size: Vector2 = _viewport_size()
	var is_portrait: bool = vp_size.y > vp_size.x
	var cols: int = 3 if is_portrait else 5
	cards_grid.columns = cols

	for entry in cards:
		if not (entry is Dictionary):
			continue
		var card: Dictionary = entry
		var fid: String = str(card.get("fact_id", ""))
		var is_collected: bool = collected_arr.has(fid)
		cards_grid.add_child(_create_card_tile(card, is_collected))


func _create_card_tile(card: Dictionary, is_collected: bool) -> Control:
	var fid: String = str(card.get("fact_id", ""))
	var cat: String = str(card.get("category", "moon"))
	var accent: Color = LearningDataScript.category_color(cat)

	var tile := Button.new()
	tile.name = "Tile_" + fid
	tile.custom_minimum_size = Vector2(170, 170)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.focus_mode = Control.FOCUS_NONE
	tile.disabled = not is_collected
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_collected else Control.CURSOR_ARROW

	var normal_sb := StyleBoxFlat.new()
	if is_collected:
		normal_sb.bg_color = Color("161E2E")
		normal_sb.border_color = accent
		normal_sb.set_border_width_all(2)
	else:
		normal_sb.bg_color = Color("0D1119")
		normal_sb.border_color = Color("263044")
		normal_sb.set_border_width_all(1)
	normal_sb.set_corner_radius_all(10)
	normal_sb.set_content_margin_all(0)

	var hover_sb := normal_sb.duplicate() as StyleBoxFlat
	if is_collected:
		hover_sb.bg_color = Color("1E2A40")

	tile.add_theme_stylebox_override("normal", normal_sb)
	tile.add_theme_stylebox_override("hover", hover_sb)
	tile.add_theme_stylebox_override("pressed", hover_sb)
	tile.add_theme_stylebox_override("disabled", normal_sb)

	if is_collected:
		tile.pressed.connect(_on_tile_pressed.bind(fid))

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_theme_constant_override("separation", 0)
	tile.add_child(outer)

	var stripe := ColorRect.new()
	stripe.custom_minimum_size = Vector2(0, 8)
	stripe.color = accent if is_collected else Color("232B3D")
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(stripe)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	outer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	if is_collected:
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(34, 34)
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = LearningDataScript.card_icon(card)
		icon_rect.modulate = accent
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon_rect)

		var title_lbl := Label.new()
		title_lbl.text = _learning.text(card.get("title", {}))
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.add_theme_color_override("font_color", UIColors.TEXT)
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(title_lbl)
	else:
		var lock_row := HBoxContainer.new()
		lock_row.alignment = BoxContainer.ALIGNMENT_CENTER
		lock_row.add_theme_constant_override("separation", 6)
		lock_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lock_row)

		var lock_icon := TextureRect.new()
		lock_icon.custom_minimum_size = Vector2(20, 20)
		lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_icon.texture = ICON_LOCK
		lock_icon.modulate = UIColors.MUTED
		lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_row.add_child(lock_icon)

		var q_lbl := Label.new()
		q_lbl.text = "?"
		q_lbl.add_theme_font_size_override("font_size", 24)
		q_lbl.add_theme_color_override("font_color", UIColors.MUTED)
		q_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_row.add_child(q_lbl)

		var locked_lbl := Label.new()
		locked_lbl.text = tr("CARD_LOCKED")
		locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked_lbl.add_theme_font_size_override("font_size", 15)
		locked_lbl.add_theme_color_override("font_color", UIColors.TEXT)
		locked_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(locked_lbl)

		var hint_lbl := Label.new()
		hint_lbl.text = tr("CARD_HOW_TO_FIND").format({"hint": _learning.text(card.get("hint", {}))})
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_lbl.add_theme_font_size_override("font_size", 13)
		hint_lbl.add_theme_color_override("font_color", UIColors.MUTED)
		hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(hint_lbl)

	return tile


func _viewport_size() -> Vector2:
	if is_inside_tree() and get_viewport() != null:
		return get_viewport().get_visible_rect().size
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_visible_rect().size
	return Vector2(1280.0, 720.0)


func _update_layout() -> void:
	var root_ctrl := get_node_or_null("Root") as Control
	var safe_node: Node = (root_ctrl as Node) if root_ctrl != null else (self as Node)
	var insets: Dictionary = SafeArea.get_insets(safe_node)
	if safe_margin != null:
		SafeArea.apply_margin(safe_margin, 14, 14, 14, 14, insets)

	var vp_size: Vector2 = _viewport_size()
	var avail_w: float = maxf(300.0, vp_size.x - float(insets["left"]) - float(insets["right"]) - 28.0)
	var avail_h: float = maxf(320.0, vp_size.y - float(insets["top"]) - float(insets["bottom"]) - 28.0)
	var is_portrait: bool = vp_size.y > vp_size.x

	if album_panel != null:
		var panel_w: float = avail_w if is_portrait else minf(1080.0, avail_w)
		var panel_h: float = avail_h * 0.90 if is_portrait else minf(640.0, avail_h * 0.94)
		album_panel.custom_minimum_size = Vector2(panel_w, panel_h)

	if cards_grid != null:
		var target_cols: int = 3 if is_portrait else 5
		if cards_grid.columns != target_cols:
			cards_grid.columns = target_cols


func _on_tab_pressed(cat_id: String) -> void:
	if Audio != null:
		Audio.play("ui_click")
	set_category(cat_id)


func _on_tile_pressed(fact_id: String) -> void:
	if Audio != null:
		Audio.play("ui_confirm")
	open_card(fact_id)


func _on_close_pressed() -> void:
	close_album()


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_album()
	elif event is InputEventScreenTouch and event.pressed:
		close_album()


func _on_language_changed(_lang: String) -> void:
	refresh()


func _on_card_collected(_fid: String) -> void:
	if visible:
		refresh()

