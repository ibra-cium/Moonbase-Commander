extends "res://tests/test_case.gd"

func test_smoke_pass() -> void:
	assert_true(true, "smoke test should pass")
	assert_eq(1 + 1, 2, "math works")
