class_name SimLog
extends RefCounted

const CAUSE_OVERWORK := "OVERWORK"

var _entries: Array[Dictionary] = []
var _entries_by_id: Dictionary = {}
var _next_id: int = 0

var entries: Array[Dictionary]:
	get:
		return _entries

func add(day: int, code: String, values: Dictionary = {}, caused_by: int = -1) -> int:
	var entry_id: int = _next_id
	_next_id += 1
	var entry: Dictionary = {
		"id": entry_id,
		"day": day,
		"code": code,
		"values": values.duplicate(true),
		"caused_by": caused_by,
	}
	_entries.append(entry)
	_entries_by_id[entry_id] = entry
	return entry_id

func get_entry(id: int) -> Dictionary:
	if _entries_by_id.has(id):
		return _entries_by_id[id]
	return {}

func latest(code: String) -> int:
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i]["code"] == code:
			return int(_entries[i]["id"])
	return -1

func latest_of(codes: Array) -> int:
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i]["code"] in codes:
			return int(_entries[i]["id"])
	return -1

func chain_from(id: int, max_steps: int = 5) -> Array:
	if not _entries_by_id.has(id):
		return []

	var path: Array[Dictionary] = []
	var visited: Dictionary = {}
	var current: Dictionary = _entries_by_id[id]

	while not current.is_empty():
		path.append(current)
		visited[int(current["id"])] = true

		if path.size() >= max_steps:
			break

		var parent_id: int = int(current["caused_by"])
		if parent_id < 0 or visited.has(parent_id) or not _entries_by_id.has(parent_id):
			break

		current = _entries_by_id[parent_id]

	path.reverse()
	return path

func cause_for(code: String, context: Dictionary = {}) -> int:
	match code:
		"BLACKOUT":
			var is_night: bool = bool(context.get("is_night", false))
			if is_night:
				return latest("SUNSET")
			var met_id: int = latest("METEOROID")
			var dust_id: int = latest("DUST_HIGH")
			return maxi(met_id, dust_id)
		"CO2_HIGH":
			return latest("BLACKOUT")
		"CREW_SICK":
			return latest("CO2_HIGH")
		"CREW_TIRED":
			return -1
		"OVERWORK":
			return latest("CREW_TIRED")
		"EVAC_CO2", "EVAC_O2":
			var co2_id: int = latest("CO2_HIGH")
			return co2_id if co2_id != -1 else latest("BLACKOUT")
		"EVAC_WATER":
			var rec_broken: bool = bool(context.get("recycler_broken", false))
			if rec_broken:
				var rec_id: int = latest("RECYCLER_BROKE")
				if rec_id != -1:
					return rec_id
			return latest("POWER_SHED")
		"EVAC_FOOD":
			return latest("FOOD_SPOILED")
		"EVAC_RADIATION":
			return latest("STORM_WARNING")
		_:
			return -1

func all_entries() -> Array[Dictionary]:
	return _entries

func size() -> int:
	return _entries.size()

func clear() -> void:
	_entries.clear()
	_entries_by_id.clear()
	_next_id = 0

