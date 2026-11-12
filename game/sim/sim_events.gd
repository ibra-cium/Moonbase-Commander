class_name SimEvents
extends RefCounted

const SimEventScript = preload("res://sim/sim_event.gd")

var _c: SimConstants

var storm_day: int = 0
var recycler_day: int = 0
var meteoroid_day: int = 0
var sunset_day: int = 15

func _init(constants: SimConstants = null) -> void:
	_c = constants
	if _c != null:
		sunset_day = int(_c.v("SUNSET_DAY"))

func schedule(rng: RandomNumberGenerator = null, force: Dictionary = {}) -> void:
	# Draw events in exact order of GAME_RULES §8
	var storm_guaranteed: int = int(_c.v("STORM_GUARANTEED")) if _c != null else 1
	var storm_min: int = int(_c.v("STORM_DAY_MIN")) if _c != null else 8
	var storm_max: int = int(_c.v("STORM_DAY_MAX")) if _c != null else 26
	if storm_guaranteed == 1:
		if rng != null:
			storm_day = rng.randi_range(storm_min, storm_max)
		else:
			storm_day = storm_min
	else:
		storm_day = 0

	var rec_min: int = int(_c.v("RECYCLER_BREAK_DAY_MIN")) if _c != null else 10
	var rec_max: int = int(_c.v("RECYCLER_BREAK_DAY_MAX")) if _c != null else 20
	if rng != null:
		recycler_day = rng.randi_range(rec_min, rec_max)
	else:
		recycler_day = rec_min

	var met_chance: float = float(_c.v("METEOROID_CHANCE")) if _c != null else 0.3
	var met_min: int = int(_c.v("METEOROID_DAY_MIN")) if _c != null else 3
	var met_max: int = int(_c.v("METEOROID_DAY_MAX")) if _c != null else 28
	if rng != null:
		if rng.randf() < met_chance:
			meteoroid_day = rng.randi_range(met_min, met_max)
		else:
			meteoroid_day = 0
	else:
		meteoroid_day = 0

	# Apply force overrides (0 or 99 = never)
	if force.has("storm_day"):
		storm_day = int(force["storm_day"])
	elif force.has("storm"):
		storm_day = int(force["storm"])

	if force.has("recycler_day"):
		recycler_day = int(force["recycler_day"])
	elif force.has("recycler"):
		recycler_day = int(force["recycler"])

	if force.has("meteoroid_day"):
		meteoroid_day = int(force["meteoroid_day"])
	elif force.has("meteoroid"):
		meteoroid_day = int(force["meteoroid"])

func has_storm() -> bool:
	return storm_day > 0 and storm_day < 99

func has_recycler_break() -> bool:
	return recycler_day > 0 and recycler_day < 99

func has_meteoroid() -> bool:
	return meteoroid_day > 0 and meteoroid_day < 99

func is_storm_day(day: int) -> bool:
	return has_storm() and day == storm_day

func is_sunset_day(day: int) -> bool:
	return day == sunset_day

func start_of_day(day: int) -> Array:
	var events: Array = []
	if day == sunset_day:
		events.append(SimEventScript.new("SUNSET", day, false, {}))
	if has_storm() and day == storm_day:
		var warn_min: int = int(_c.v("SPE_WARNING_TYPICAL_MIN")) if _c != null else 60
		events.append(SimEventScript.new("STORM_WARNING", day, true, {"warning_min": warn_min}))
	return events

func end_of_day(day: int, state: Dictionary = {}) -> Array:
	var events: Array = []
	if has_recycler_break() and day == recycler_day:
		events.append(SimEventScript.new("RECYCLER_BROKE", day, false, {}))
	if has_meteoroid() and day == meteoroid_day:
		var has_panel: bool = true
		if state.has("working_panels"):
			has_panel = int(state["working_panels"]) > 0
		elif state.has("solar") and state.has("broken_panels"):
			has_panel = (int(state["solar"]) - int(state["broken_panels"])) > 0
		if has_panel:
			events.append(SimEventScript.new("METEOROID", day, false, {}))
	return events

func storm_dose(g_cm2: float) -> float:
	var pts: Array = _c.v("SPE_SHIELD_TABLE_G_CM2") if _c != null else [0, 5, 10, 15]
	var doses: Array = [
		float(_c.v("SPE_DOSE_HABITAT_NO_EXTRA_MSV")) if _c != null else 398.0,
		float(_c.v("SPE_DOSE_SHIELD_5")) if _c != null else 177.7,
		float(_c.v("SPE_DOSE_SHIELD_10")) if _c != null else 68.1,
		float(_c.v("SPE_DOSE_SHIELD_15")) if _c != null else 46.9,
	]
	if g_cm2 <= float(pts[0]):
		return float(doses[0])
	if g_cm2 >= float(pts[-1]):
		return float(doses[-1])
	for i in range(pts.size() - 1):
		var x0: float = float(pts[i])
		var x1: float = float(pts[i + 1])
		if g_cm2 >= x0 and g_cm2 <= x1:
			var t: float = (g_cm2 - x0) / (x1 - x0)
			return float(doses[i]) + t * (float(doses[i + 1]) - float(doses[i]))
	return float(doses[-1])

func shield_needed_for_limit(limit_msv: float = -1.0) -> float:
	var target_limit: float = limit_msv
	if target_limit < 0.0:
		target_limit = float(_c.v("RAD_SPE_LIMIT_MSV")) if _c != null else 250.0

	var pts: Array = _c.v("SPE_SHIELD_TABLE_G_CM2") if _c != null else [0, 5, 10, 15]
	var doses: Array = [
		float(_c.v("SPE_DOSE_HABITAT_NO_EXTRA_MSV")) if _c != null else 398.0,
		float(_c.v("SPE_DOSE_SHIELD_5")) if _c != null else 177.7,
		float(_c.v("SPE_DOSE_SHIELD_10")) if _c != null else 68.1,
		float(_c.v("SPE_DOSE_SHIELD_15")) if _c != null else 46.9,
	]
	if target_limit >= float(doses[0]):
		return 0.0
	if target_limit <= float(doses[-1]):
		return roundf(float(pts[-1]) * 10.0) / 10.0

	for i in range(doses.size() - 1):
		var d0: float = float(doses[i])
		var d1: float = float(doses[i + 1])
		if target_limit <= d0 and target_limit >= d1:
			var t: float = (target_limit - d0) / (d1 - d0)
			var x0: float = float(pts[i])
			var x1: float = float(pts[i + 1])
			var g: float = x0 + t * (x1 - x0)
			return roundf(g * 10.0) / 10.0

	return roundf(float(pts[-1]) * 10.0) / 10.0

func to_dict() -> Dictionary:
	return {
		"storm_day": storm_day,
		"recycler_day": recycler_day,
		"meteoroid_day": meteoroid_day,
		"sunset_day": sunset_day,
	}
