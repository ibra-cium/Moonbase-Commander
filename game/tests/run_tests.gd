extends SceneTree

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	var dir := DirAccess.open("res://tests")
	if dir == null:
		print("Failed to open res://tests")
		quit(1)
		return
	for file_name in dir.get_files():
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			_run_file("res://tests/" + file_name)
	print("PASSED %d  FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _run_file(path: String) -> void:
	var script: GDScript = load(path)
	if script == null:
		_failed += 1
		print("FAIL %s: failed to load script" % path.get_file())
		return
	var test_case: Object = script.new()
	for method in test_case.get_method_list():
		var name: String = method["name"]
		if not name.begins_with("test_"):
			continue
		test_case.failures.clear()
		test_case.call(name)
		if test_case.failures.is_empty():
			_passed += 1
		else:
			_failed += 1
			print("FAIL %s.%s: %s" % [path.get_file(), name, "; ".join(test_case.failures)])

