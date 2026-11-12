extends "res://tests/test_case.gd"

const SourceTagScene: PackedScene = preload("res://ui/SourceTag.tscn")
const GaugeScene: PackedScene = preload("res://ui/Gauge.tscn")
const EventPopupScene: PackedScene = preload("res://ui/EventPopup.tscn")
const SourcesScreenScene: PackedScene = preload("res://ui/SourcesScreen.tscn")
const BoltIcon: Texture2D = preload("res://assets/icons/bolt.svg")

func test_sourcetag_three_ids() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var test_ids: Array[String] = ["CARGO_LIMIT_KG", "SOLAR_UNIT_KW", "RAD_SPE_LIMIT_MSV"]
	for id in test_ids:
		assert_true(Constants.has(id), "Constants must have ID: %s" % id)
		var meta: Dictionary = Constants.meta(id)
		
		var tag: SourceTag = SourceTagScene.instantiate() as SourceTag
		root.add_child(tag)
		tag.setup(id)
		
		assert_eq(tag.constant_id, id, "SourceTag should store ID %s" % id)
		assert_eq(tag.title_label.text, str(meta.get("label", id)), "Title should match meta label")
		assert_true(tag.type_label.text.contains(str(meta.get("type", ""))), "Type should contain meta type")
		assert_true(tag.source_label.text.contains(str(meta.get("source", ""))), "Source should contain meta source")
		
		var mtype: String = str(meta.get("type", ""))
		var expect_game_choice: bool = (mtype == "Game setting" or mtype == "Game assumption")
		assert_eq(tag.game_choice_label.visible, expect_game_choice, "Game choice label visibility mismatch for %s" % id)
		var info_sb: StyleBox = tag.info_button.get_theme_stylebox("normal")
		assert_true(info_sb.content_margin_left + info_sb.content_margin_right < 12.0, "SourceTag InfoButton margins must leave room for SVG icon")
		root.remove_child(tag)
		tag.free()

func test_gauge_states_and_values() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var gauge: Gauge = GaugeScene.instantiate() as Gauge
	root.add_child(gauge)
	gauge.setup(BoltIcon, "kW", UIColors.POWER, "SOLAR_UNIT_KW", "Solar Power")
	gauge.set_value(12.5, 20.0)

	assert_eq(gauge.current_state, Gauge.State.NORMAL, "Default state should be NORMAL")
	assert_eq(gauge.bar.value, 12.5, "Gauge bar value should be 12.5")
	assert_eq(gauge.unit_label.text, "kW", "Unit label should be kW")
	assert_false(gauge.is_processing(), "Normal state should not process pulse")

	gauge.set_state("warn")
	assert_eq(gauge.current_state, Gauge.State.WARN, "State should be WARN")
	assert_false(gauge.is_processing(), "Warn state should not process pulse")

	gauge.set_state("critical")
	assert_eq(gauge.current_state, Gauge.State.CRITICAL, "State should be CRITICAL")
	assert_true(gauge.is_processing(), "Critical state should process pulse")
	root.remove_child(gauge)
	gauge.free()

func test_event_popup_signal() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var popup: EventPopup = EventPopupScene.instantiate() as EventPopup
	root.add_child(popup)
	
	var result: Array[int] = [-1]
	popup.choice_selected.connect(func(idx: int) -> void:
		result[0] = idx
	)
	
	popup.popup_event("Test Event", "Test description message.", ["Choice 0", "Choice 1"])
	assert_true(popup.visible, "Popup should be visible after popup_event")
	assert_eq(popup.button_box.get_child_count(), 2, "Should create 2 option buttons")
	
	var btn0: Button = popup.button_box.get_child(0) as Button
	btn0.pressed.emit()
	
	assert_eq(result[0], 0, "Pressed button should emit choice index 0")
	assert_false(popup.visible, "Popup should hide after choice")
	root.remove_child(popup)
	popup.free()

func test_sources_screen_lists_all_code_ids() -> void:
	# 1. Collect all IDs referenced in code using the same regex as test_constants.gd
	var gd_files: Array[String] = []
	_collect_gd_files("res://", gd_files)
	
	var regex := RegEx.new()
	regex.compile("\\bv\\(\\s*[\"']([A-Za-z0-9_]+)[\"']\\s*\\)")
	
	var code_ids: Dictionary = {}
	for file_path in gd_files:
		var file_text := FileAccess.get_file_as_string(file_path)
		var matches := regex.search_all(file_text)
		for m in matches:
			var id := m.get_string(1)
			if Constants.has(id):
				code_ids[id] = true
	
	assert_true(code_ids.size() > 0, "Code should reference at least one constant ID")
	
	# 2. Instantiate SourcesScreen in root and verify that every code ID is listed
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var screen: SourcesScreen = SourcesScreenScene.instantiate() as SourcesScreen
	root.add_child(screen)
	
	var all_screen_ids: PackedStringArray = Constants.ids()
	assert_true(all_screen_ids.size() >= code_ids.size(), "Sources screen should know all constants")
	
	for cid in code_ids.keys():
		assert_true(all_screen_ids.has(cid), "SourcesScreen must include code constant: %s" % cid)
	
	root.remove_child(screen)
	screen.free()

func _collect_gd_files(dir_path: String, out_files: Array[String]) -> void:
	if dir_path.begins_with("res://tests") or dir_path.begins_with("res://.godot"):
		return
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if dir.current_is_dir():
			if not item.begins_with(".") and item != "tests":
				var sub_path := dir_path.path_join(item)
				_collect_gd_files(sub_path, out_files)
		else:
			if item.ends_with(".gd"):
				out_files.append(dir_path.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()
