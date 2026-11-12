## SimMissions — loads missions.json and resolves mission data.
## Pure RefCounted: no scene tree, no autoloads. Testable headlessly.
class_name SimMissions
extends RefCounted

const MISSIONS_PATH := "res://data/missions.json"

var _missions: Array = []  # Array of Dictionaries
var _base_sim: SimConstants = null

func _init(base_sim: SimConstants) -> void:
	_base_sim = base_sim
	_load()

func _load() -> void:
	if not FileAccess.file_exists(MISSIONS_PATH):
		push_error("SimMissions: missions.json not found at %s" % MISSIONS_PATH)
		return
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		_missions = parsed
	else:
		push_error("SimMissions: missions.json must be a JSON array")

## Returns the mission Dictionary for the given ID, or an empty dict.
func get_mission(id: String) -> Dictionary:
	for m in _missions:
		if m is Dictionary and m.get("id", "") == id:
			return m
	return {}

## Returns all mission IDs in order.
func all_ids() -> Array:
	var ids: Array = []
	for m in _missions:
		if m is Dictionary:
			ids.append(str(m.get("id", "")))
	return ids

## Returns a SimConstants for the given mission ID with MISSION_DAYS overridden
## from the mission's days_id constant. The base SimConstants is not modified.
func get_sim_constants(id: String) -> SimConstants:
	var m := get_mission(id)
	if m.is_empty() or _base_sim == null:
		return _base_sim
	var days_id: String = str(m.get("days_id", "MISSION_DAYS"))
	var days_val: Variant = _base_sim.v(days_id) if _base_sim.has(days_id) else _base_sim.v("MISSION_DAYS")
	return _base_sim.with_overrides({"MISSION_DAYS": days_val})

## Returns the resolved force dictionary for the given mission ID.
## String values in the JSON (constant IDs) are looked up in base_sim.
## 0 / 99 means "never". The scenario's own force wins if both exist.
func get_force(id: String) -> Dictionary:
	var m := get_mission(id)
	if m.is_empty() or _base_sim == null:
		return {}
	var raw_force: Dictionary = m.get("force", {}) as Dictionary
	var resolved: Dictionary = {}
	for key in raw_force.keys():
		var val: Variant = raw_force[key]
		if val is String and val != "":
			# Look up the constant ID
			if _base_sim.has(val):
				resolved[key] = int(_base_sim.v(val))
			else:
				push_error("SimMissions: Unknown constant ID in force: %s" % val)
				resolved[key] = 0
		else:
			resolved[key] = int(val)
	return resolved

## Returns the hidden_items array for the mission.
func get_hidden_items(id: String) -> Array:
	var m := get_mission(id)
	return m.get("hidden_items", []) as Array

## Returns the locked_items dict (key -> fixed count) for the mission.
func get_locked_items(id: String) -> Dictionary:
	var m := get_mission(id)
	return m.get("locked_items", {}) as Dictionary

## Returns the start_cargo dict for the mission (empty = player chooses freely).
func get_start_cargo(id: String) -> Dictionary:
	var m := get_mission(id)
	return m.get("start_cargo", {}) as Dictionary

