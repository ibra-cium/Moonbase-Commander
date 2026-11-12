extends Node

const CONSTANTS_PATH := "res://data/constants.json"
const SimConstantsScript := preload("res://sim/sim_constants.gd")

var sim: SimConstants = null

func _enter_tree() -> void:
	_load_constants()

func _load_constants() -> void:
	if not FileAccess.file_exists(CONSTANTS_PATH):
		push_error("Constants file not found at: %s" % CONSTANTS_PATH)
		return
	var text := FileAccess.get_file_as_string(CONSTANTS_PATH)
	sim = SimConstantsScript.from_json(text)

func v(id: String) -> Variant:
	if sim == null:
		_load_constants()
	if sim == null:
		push_error("Constants.sim is null when querying ID: %s" % id)
		return null
	return sim.v(id)

func meta(id: String) -> Dictionary:
	if sim == null:
		_load_constants()
	if sim == null:
		push_error("Constants.sim is null when querying meta for ID: %s" % id)
		return {}
	return sim.meta(id)

func has(id: String) -> bool:
	if sim == null:
		_load_constants()
	if sim == null:
		return false
	return sim.has(id)

func ids() -> PackedStringArray:
	if sim == null:
		_load_constants()
	if sim == null:
		return PackedStringArray()
	return sim.ids()
