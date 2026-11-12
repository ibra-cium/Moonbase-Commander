class_name CertificateScreen
extends Control

signal back_to_map_pressed

const MISSION_IDS: Array[String] = ["M1", "M2", "M3", "M4"]
const ICON_STAR: Texture2D = preload("res://assets/icons/star.svg")
const ICON_CHECK: Texture2D = preload("res://assets/icons/check.svg")
const SafeArea := preload("res://ui/safe_area.gd")
const STAR_EMPTY_COLOR := Color(0.34, 0.38, 0.46, 0.45)

var safe_margin: MarginContainer
var card_panel: PanelContainer
var title_label: Label
var rank_label: Label
var cert_scroll: ScrollContainer
var stars_grid: HFlowContainer
var learned_header_label: Label
var learned_vbox: VBoxContainer
var cards_label: Label
var date_label: Label
var footer_label: Label
var back_button: Button

var show_cards_count: bool = true
var _learning: LearningData = LearningData.new()


func _ensure_nodes() -> void:
	if safe_margin != null:
		return
	safe_margin = get_node_or_null("SafeMargin")
	card_panel = find_child("CardPanel", true, false) as PanelContainer
	title_label = find_child("TitleLabel", true, false) as Label
	rank_label = find_child("RankLabel", true, false) as Label
	cert_scroll = find_child("CertScroll", true, false) as ScrollContainer
	stars_grid = find_child("StarsGrid", true, false) as HFlowContainer
	learned_header_label = find_child("LearnedHeaderLabel", true, false) as Label
	learned_vbox = find_child("LearnedVBox", true, false) as VBoxContainer
	cards_label = find_child("CardsLabel", true, false) as Label
	date_label = find_child("DateLabel", true, false) as Label
	footer_label = find_child("FooterLabel", true, false) as Label
	back_button = find_child("BackButton", true, false) as Button


func _ready() -> void:
	_ensure_nodes()
	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)
	SafeArea.connect_resize(self, _update_layout)
	_update_layout()
	refresh_certificate()


func _update_layout() -> void:
	_ensure_nodes()
	if not is_inside_tree() or safe_margin == null or card_panel == null:
		return
	var insets := SafeArea.get_insets(self)
	safe_margin.add_theme_constant_override("margin_left", 14 + int(insets["left"]))
	safe_margin.add_theme_constant_override("margin_right", 14 + int(insets["right"]))
	safe_margin.add_theme_constant_override("margin_top", 14 + int(insets["top"]))
	safe_margin.add_theme_constant_override("margin_bottom", 14 + int(insets["bottom"]))

	var vp_size := get_viewport_rect().size
	var avail_w: float = maxf(280.0, vp_size.x - float(insets["left"]) - float(insets["right"]) - 28.0)
	var avail_h: float = maxf(220.0, vp_size.y - float(insets["top"]) - float(insets["bottom"]) - 28.0)
	var is_portrait: bool = vp_size.y > vp_size.x
	card_panel.custom_minimum_size = Vector2(minf(1080.0, avail_w - 48.0) if is_portrait else minf(700.0, avail_w), 0.0)
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 20 if avail_w < 600.0 or avail_h < 500.0 else 28)
	if cert_scroll != null:
		var scroll_h: float = clampf(avail_h * 0.22, 200.0, 480.0) if is_portrait else clampf(avail_h - 190.0, 120.0, 440.0)
		cert_scroll.custom_minimum_size = Vector2(0.0, scroll_h)


func refresh_certificate() -> void:
	_ensure_nodes()
	if title_label != null:
		title_label.text = tr("CERT_TITLE")
	if rank_label != null:
		var rid: String = Settings.rank_id if Settings != null else "CADET"
		rank_label.text = tr("MAP_RANK").format({"rank": _learning.rank_name(rid)})
	if learned_header_label != null:
		learned_header_label.text = tr("CERT_LEARNED")
	if date_label != null:
		date_label.text = Time.get_date_string_from_system()
	if footer_label != null:
		footer_label.text = tr("CERT_FOOTER")
	if back_button != null:
		back_button.text = tr("CERT_BACK")

	if cards_label != null:
		cards_label.visible = show_cards_count
		if show_cards_count and Settings != null:
			cards_label.text = tr("CERT_CARDS").format({
				"n": Settings.collected_cards.size(),
				"total": _learning.cards().size(),
			})

	_rebuild_mission_stars()
	_rebuild_learned_lessons()
	_update_layout()


func _rebuild_mission_stars() -> void:
	if stars_grid == null:
		return
	for child in stars_grid.get_children():
		stars_grid.remove_child(child)
		child.queue_free()

	for mid in MISSION_IDS:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 4)
		var lbl := Label.new()
		lbl.text = mid
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", UIColors.TEXT)
		chip.add_child(lbl)

		var stars: int = int(Settings.mission_stars.get(mid, 0)) if Settings != null else 0
		for i in range(3):
			var st := TextureRect.new()
			st.custom_minimum_size = Vector2(18, 18)
			st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			st.texture = ICON_STAR
			st.modulate = UIColors.POWER if i < stars else STAR_EMPTY_COLOR
			chip.add_child(st)
		stars_grid.add_child(chip)


func _rebuild_learned_lessons() -> void:
	if learned_vbox == null:
		return
	for child in learned_vbox.get_children():
		learned_vbox.remove_child(child)
		child.queue_free()

	for mid in MISSION_IDS:
		var stars: int = int(Settings.mission_stars.get(mid, 0)) if Settings != null else 0
		if stars < 1:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = ICON_CHECK
		icon.modulate = UIColors.OXYGEN
		row.add_child(icon)

		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", UIColors.TEXT)
		lbl.text = _learning.formatted_text(_learning.lesson(mid))
		row.add_child(lbl)
		learned_vbox.add_child(row)


func _on_back_pressed() -> void:
	if Audio != null:
		Audio.play("ui_click")
	back_to_map_pressed.emit()


func _on_language_changed(_lang: String) -> void:
	refresh_certificate()

