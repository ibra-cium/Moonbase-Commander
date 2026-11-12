extends RefCounted

const SimConstantsScript := preload("res://sim/sim_constants.gd")

var failures: Array[String] = []

func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)

func assert_false(cond: bool, msg: String) -> void:
	if cond:
		failures.append(msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a != b:
		failures.append("%s (got %s, want %s)" % [msg, str(a), str(b)])

func assert_near(a: float, b: float, tol: float, msg: String) -> void:
	if absf(a - b) > tol:
		failures.append("%s (got %.4f, want %.4f ± %.4f)" % [msg, a, b, tol])

func load_constants() -> SimConstants:
	var text := FileAccess.get_file_as_string("res://data/constants.json")
	return SimConstantsScript.from_json(text)
