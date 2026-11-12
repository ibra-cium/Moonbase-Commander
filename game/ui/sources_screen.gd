class_name SourcesScreen
extends Control

signal back_pressed

const SafeArea := preload("res://ui/safe_area.gd")
const LearningDataScript := preload("res://ui/learning_data.gd")

var back_button: Button
var title_label: Label
var search_edit: LineEdit
var system_option: OptionButton
var simplification_label: Label
var list_container: VBoxContainer

var _all_ids: PackedStringArray = PackedStringArray()
var _filter_system: String = "ALL"
var _filter_query: String = ""
var _learning: LearningData = LearningDataScript.new()

func _ensure_nodes() -> void:
	if back_button == null:
		back_button = get_node_or_null("Margin/VBox/TopBar/BackButton") as Button
	if title_label == null:
		title_label = get_node_or_null("Margin/VBox/TopBar/TitleLabel") as Label
	if search_edit == null:
		search_edit = get_node_or_null("Margin/VBox/FilterBar/SearchEdit") as LineEdit
	if system_option == null:
		system_option = get_node_or_null("Margin/VBox/FilterBar/SystemOption") as OptionButton
	if simplification_label == null:
		simplification_label = get_node_or_null("Margin/VBox/SimplificationCard/Margin/SimplificationLabel") as Label
	if list_container == null:
		list_container = get_node_or_null("Margin/VBox/Scroll/CardsList") as VBoxContainer

func _ready() -> void:
	_ensure_nodes()
	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if search_edit != null and not search_edit.text_changed.is_connected(_on_search_changed):
		search_edit.text_changed.connect(_on_search_changed)
	if system_option != null and not system_option.item_selected.is_connected(_on_system_selected):
		system_option.item_selected.connect(_on_system_selected)
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)

	_init_system_options()
	_populate_list()
	_apply_safe_area()
	SafeArea.connect_resize(self, _apply_safe_area)

func _apply_safe_area() -> void:
	var insets: Dictionary = SafeArea.get_insets(self)
	var margin := get_node_or_null("Margin") as MarginContainer
	SafeArea.apply_margin(margin, 16, 16, 16, 16, insets)

func _init_system_options() -> void:
	system_option.clear()
	system_option.add_item(tr("SRC_FILTER_ALL"), 0)
	system_option.set_item_metadata(0, "ALL")

	var systems: Dictionary = {}
	_all_ids = Constants.ids()
	for id in _all_ids:
		var m: Dictionary = Constants.meta(id)
		var sys: String = str(m.get("system", "Other"))
		systems[sys] = true
	
	var sorted_systems: Array = systems.keys()
	sorted_systems.sort()

	var idx: int = 1
	for sys in sorted_systems:
		system_option.add_item(sys, idx)
		system_option.set_item_metadata(idx, sys)
		idx += 1
	system_option.add_item(tr("CARD_ALBUM_TITLE"), idx)
	system_option.set_item_metadata(idx, "FACTS")

func _populate_list() -> void:
	for child in list_container.get_children():
		list_container.remove_child(child)
		child.queue_free()

	simplification_label.text = tr("SRC_SIMPLIFICATIONS_NOTE")
	title_label.text = tr("SRC_SCREEN_TITLE")
	back_button.text = tr("SRC_BACK")
	if search_edit != null:
		search_edit.placeholder_text = tr("SRC_SEARCH_PLACEHOLDER")

	if _filter_system == "FACTS":
		_populate_facts_list()
		return

	var groups: Dictionary = {}
	for id in _all_ids:
		var m: Dictionary = Constants.meta(id)
		var sys: String = str(m.get("system", "Other"))
		if not groups.has(sys):
			groups[sys] = []
		groups[sys].append(id)

	var sorted_systems: Array = groups.keys()
	sorted_systems.sort()

	var added_count: int = 0
	for sys in sorted_systems:
		if _filter_system != "ALL" and sys != _filter_system:
			continue

		var ids_in_sys: Array = groups[sys]
		var filtered_ids: Array = []
		for id in ids_in_sys:
			var m: Dictionary = Constants.meta(id)
			var label: String = str(m.get("label", ""))
			var source: String = str(m.get("source", ""))
			if _matches_query(id, label, source):
				filtered_ids.append(id)

		if filtered_ids.is_empty():
			continue

		# Add System Header
		var header_label := Label.new()
		header_label.text = sys.to_upper()
		header_label.theme_type_variation = &"HeaderMedium"
		header_label.add_theme_color_override("font_color", UIColors.POWER)
		header_label.add_theme_font_size_override("font_size", 22)
		list_container.add_child(header_label)

		# Add cards for each constant
		for id in filtered_ids:
			var card: PanelContainer = _create_constant_card(id)
			list_container.add_child(card)
			added_count += 1

	if added_count == 0:
		var empty_label := Label.new()
		empty_label.text = tr("SRC_NO_RESULTS")
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		list_container.add_child(empty_label)

func _create_constant_card(id: String) -> PanelContainer:
	var m: Dictionary = Constants.meta(id)
	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Top row: Label & ID
	var top_row := HBoxContainer.new()
	var lbl_name := Label.new()
	lbl_name.text = str(m.get("label", id))
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.add_theme_color_override("font_color", UIColors.TEXT)
	lbl_name.add_theme_font_size_override("font_size", 20)
	lbl_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_row.add_child(lbl_name)

	var lbl_id := Label.new()
	lbl_id.text = id
	lbl_id.add_theme_color_override("font_color", UIColors.MUTED)
	lbl_id.add_theme_font_size_override("font_size", 16)
	top_row.add_child(lbl_id)
	vbox.add_child(top_row)

	# Value row
	var val: Variant = m.get("value", "")
	var unit: String = str(m.get("unit", ""))
	var val_str: String = "%s %s" % [str(val), unit] if not unit.is_empty() else str(val)
	var lbl_val := Label.new()
	lbl_val.text = "%s: %s" % [tr("SRC_VALUE"), val_str]
	lbl_val.add_theme_color_override("font_color", UIColors.POWER)
	lbl_val.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lbl_val)

	# Meta details: Type and Source
	var meta_type: String = str(m.get("type", ""))
	var lbl_type := Label.new()
	lbl_type.text = "%s: %s" % [tr("SRC_TYPE"), meta_type]
	lbl_type.add_theme_color_override("font_color", UIColors.MUTED)
	lbl_type.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lbl_type)

	var meta_source: String = str(m.get("source", ""))
	var lbl_src := Label.new()
	lbl_src.text = "%s: %s" % [tr("SRC_SOURCE"), meta_source]
	lbl_src.add_theme_color_override("font_color", UIColors.TEXT)
	lbl_src.add_theme_font_size_override("font_size", 16)
	lbl_src.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_src)

	# Link as text (no external navigation)
	var link_str: String = str(m.get("link", ""))
	if not link_str.is_empty():
		var lbl_link := Label.new()
		lbl_link.text = "%s: %s" % [tr("SRC_LINK"), link_str]
		lbl_link.add_theme_color_override("font_color", UIColors.WATER)
		lbl_link.add_theme_font_size_override("font_size", 14)
		lbl_link.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_link)

	# Simplification / game choice note
	var is_game_choice: bool = (meta_type == "Game setting" or meta_type == "Game assumption")
	if is_game_choice:
		var lbl_note := Label.new()
		lbl_note.text = tr("SRC_GAME_CHOICE")
		lbl_note.add_theme_color_override("font_color", UIColors.POWER)
		lbl_note.add_theme_font_size_override("font_size", 15)
		lbl_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_note)

	return card

func _matches_query(id: String, label: String, source: String) -> bool:
	if _filter_query.is_empty():
		return true
	var q: String = _filter_query.to_lower()
	return id.to_lower().contains(q) or label.to_lower().contains(q) or source.to_lower().contains(q)

func _on_search_changed(new_text: String) -> void:
	_filter_query = new_text.strip_edges()
	_populate_list()

func _on_system_selected(idx: int) -> void:
	_play_audio("ui_click")
	_filter_system = str(system_option.get_item_metadata(idx))
	_populate_list()

func _on_back_pressed() -> void:
	_play_audio("ui_click")
	back_pressed.emit()

func _play_audio(sound_name: String) -> void:
	if Audio != null:
		Audio.play(sound_name)

func _on_language_changed(_lang: String) -> void:
	if system_option != null:
		for i in range(system_option.item_count):
			var meta_val: String = str(system_option.get_item_metadata(i))
			if meta_val == "ALL":
				system_option.set_item_text(i, tr("SRC_FILTER_ALL"))
			elif meta_val == "FACTS":
				system_option.set_item_text(i, tr("CARD_ALBUM_TITLE"))
	_populate_list()


func _populate_facts_list() -> void:
	var header_label := Label.new()
	header_label.text = tr("CARD_ALBUM_TITLE").to_upper()
	header_label.theme_type_variation = &"HeaderMedium"
	header_label.add_theme_color_override("font_color", UIColors.POWER)
	header_label.add_theme_font_size_override("font_size", 22)
	list_container.add_child(header_label)

	var added_count: int = 0
	for entry in _learning.cards():
		if not (entry is Dictionary):
			continue
		var card: Dictionary = entry
		var fid: String = str(card.get("fact_id", ""))
		var title_txt: String = _learning.text(card.get("title", {}))
		var fact: Dictionary = _learning.fact(fid)
		var fact_txt: String = _learning.text(fact)
		var fact_src: String = str(fact.get("source", ""))
		var fact_link: String = str(fact.get("link", ""))
		if not _filter_query.is_empty():
			var q: String = _filter_query.to_lower()
			var hit: bool = fid.to_lower().contains(q) or title_txt.to_lower().contains(q) or fact_txt.to_lower().contains(q) or fact_src.to_lower().contains(q)
			if not hit:
				continue
		list_container.add_child(_create_fact_source_card(fid, title_txt, fact_txt, fact_src, fact_link))
		added_count += 1

	if added_count == 0:
		var empty_label := Label.new()
		empty_label.text = tr("SRC_NO_RESULTS")
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		list_container.add_child(empty_label)


func _create_fact_source_card(fid: String, title_txt: String, fact_txt: String, fact_src: String, fact_link: String) -> PanelContainer:
	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var top_row := HBoxContainer.new()
	var lbl_title := Label.new()
	lbl_title.text = title_txt if not title_txt.is_empty() else fid
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_color_override("font_color", UIColors.POWER)
	lbl_title.add_theme_font_size_override("font_size", 20)
	lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_row.add_child(lbl_title)

	var lbl_id := Label.new()
	lbl_id.text = fid
	lbl_id.add_theme_color_override("font_color", UIColors.MUTED)
	lbl_id.add_theme_font_size_override("font_size", 16)
	top_row.add_child(lbl_id)
	vbox.add_child(top_row)

	var lbl_fact := Label.new()
	lbl_fact.text = fact_txt
	lbl_fact.add_theme_color_override("font_color", UIColors.TEXT)
	lbl_fact.add_theme_font_size_override("font_size", 16)
	lbl_fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_fact)

	var lbl_src := Label.new()
	lbl_src.text = "%s: %s" % [tr("SRC_SOURCE"), fact_src]
	lbl_src.add_theme_color_override("font_color", UIColors.MUTED)
	lbl_src.add_theme_font_size_override("font_size", 15)
	lbl_src.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_src)

	if not fact_link.is_empty():
		var lbl_link := Label.new()
		lbl_link.text = "%s: %s" % [tr("SRC_LINK"), fact_link]
		lbl_link.add_theme_color_override("font_color", UIColors.WATER)
		lbl_link.add_theme_font_size_override("font_size", 14)
		lbl_link.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_link)

	return card
