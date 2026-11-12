extends "res://tests/test_case.gd"

func test_constants_load() -> void:
	var sim: SimConstants = load_constants()
	assert_true(sim != null, "constants should load successfully")
	if sim == null:
		return
	var ids: PackedStringArray = sim.ids()
	assert_eq(ids.size(), 172, "should contain 172 constant IDs")

func test_constants_values() -> void:
	var sim: SimConstants = load_constants()
	if sim == null:
		assert_true(false, "sim constants is null")
		return

	assert_near(float(sim.v("SOLAR_UNIT_MASS_KG")), 12.5, 0.01, "SOLAR_UNIT_MASS_KG should be ~12.5")
	assert_near(float(sim.v("LOAD_TOTAL_KW")), 18.7, 0.01, "LOAD_TOTAL_KW should be ~18.7")
	assert_near(float(sim.v("NIGHT_BATTERY_MASS_KG")), 41416.7, 0.1, "NIGHT_BATTERY_MASS_KG should be ~41416.7")
	assert_true(not sim.has("NOT_AN_ID"), "has('NOT_AN_ID') should be false")

func test_constants_meta_fields() -> void:
	var sim: SimConstants = load_constants()
	if sim == null:
		assert_true(false, "sim constants is null")
		return

	for id in sim.ids():
		var m: Dictionary = sim.meta(id)
		assert_true(m.has("value"), "ID %s missing 'value'" % id)
		assert_true(m.has("unit"), "ID %s missing 'unit'" % id)
		assert_true(m.has("type"), "ID %s missing 'type'" % id)
		assert_true(m.has("source"), "ID %s missing 'source'" % id)

func test_gdscript_constant_references() -> void:
	var sim: SimConstants = load_constants()
	if sim == null:
		assert_true(false, "sim constants is null")
		return

	var gd_files: Array[String] = []
	_collect_gd_files("res://", gd_files)

	var regex := RegEx.new()
	regex.compile("\\bv\\(\\s*[\"']([A-Za-z0-9_]+)[\"']\\s*\\)")

	var checked_count: int = 0
	for file_path in gd_files:
		var file_text := FileAccess.get_file_as_string(file_path)
		var matches := regex.search_all(file_text)
		for m in matches:
			var id := m.get_string(1)
			checked_count += 1
			assert_true(sim.has(id), "File %s uses unknown constant ID: %s" % [file_path, id])

	assert_true(checked_count > 0, "Scan test should find at least one constant reference in project code")

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

func test_data_files_utf8_no_bom_no_mojibake() -> void:
	var paths := [
		"res://data/constants.json",
		"res://data/facts.json",
		"res://data/learning.json",
		"res://data/missions.json",
		"res://i18n/strings.csv",
	]
	var bad_sequences := ["â€", "Ã", "Â"]
	for path in paths:
		var raw := FileAccess.get_file_as_bytes(path)
		assert_true(raw.size() > 0, "%s should exist and be non-empty" % path)
		var has_bom := raw.size() >= 3 and raw[0] == 0xEF and raw[1] == 0xBB and raw[2] == 0xBF
		assert_false(has_bom, "%s must not start with a UTF-8 BOM" % path)
		var text := raw.get_string_from_utf8()
		for seq in bad_sequences:
			assert_false(text.contains(seq), "%s must not contain mojibake sequence '%s'" % [path, seq])


