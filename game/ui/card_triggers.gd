class_name CardTriggers
extends RefCounted

const LearningDataScript := preload("res://ui/learning_data.gd")

const DUST_CARD_THRESHOLD: float = 0.15
const BATTERY_LOW_THRESHOLD: float = 30.0
const OUTSIDE_JOBS: Array[String] = ["REGOLITH", "SCIENCE", "CLEAN", "REPAIR_PANEL"]
const M04_ALERT_CODES: Array[String] = ["STORM", "STORM_WARNING", "METEOROID", "RECYCLER_BROKE", "SUNSET"]
const EVAC_PREFIX: String = "EVAC_"

var _learning: LearningData


func _init(learning: LearningData = null) -> void:
	_learning = learning if learning != null else LearningDataScript.new()


## Evaluate gameplay report changes and return newly triggered fact IDs,
## skipping any card already in context["collected_cards"] or Settings.collected_cards.
func evaluate(
	prev_report: Variant,
	curr_report: Variant,
	jobs: Array = [],
	context: Dictionary = {}
) -> Array[String]:
	var triggered: Array[String] = []
	var collected: Dictionary = _collected_set(context)

	var rep_day: int = _prop_int(curr_report, "day", 0)
	var sunset_day: int = int(context.get("sunset_day", _get_sunset_day()))
	var events: Dictionary = _extract_events(curr_report, context)
	var mission_ended: bool = bool(context.get("mission_ended", false)) or _has_evac_event(events)
	var is_day_start: bool = bool(context.get("is_day_start", false))
	var day_start_day: int = int(context.get("day_start_day", 0))
	var executed_jobs: Array[String] = _extract_executed_jobs(curr_report, jobs, events.has("STORM"))

	if curr_report != null and not is_day_start and rep_day == 1:
		_add_trigger("landed", triggered, collected)

	if curr_report != null and not events.has("STORM") and _any_job_in(executed_jobs, OUTSIDE_JOBS):
		_add_trigger("first_outside_job", triggered, collected)

	if curr_report != null and _did_regolith_increase(prev_report, curr_report, executed_jobs, context):
		_add_trigger("first_regolith", triggered, collected)

	if curr_report != null and not events.has("STORM") and _any_job_in(executed_jobs, ["FARM"]) and _prop_bool(curr_report, "greenhouse_alive", false):
		_add_trigger("first_farm", triggered, collected)

	if curr_report != null and _did_clean_dust(prev_report, curr_report, executed_jobs, events.has("STORM"), context):
		_add_trigger("first_clean", triggered, collected)

	if curr_report != null and _prop_float(curr_report, "dust", 0.0) >= DUST_CARD_THRESHOLD:
		_add_trigger("dusty", triggered, collected)

	if curr_report != null and (_any_crew_zero_energy(curr_report) or bool(context.get("crew_tired", false))):
		_add_trigger("crew_tired", triggered, collected)

	if curr_report != null:
		var session_sci: int = _compute_session_science(curr_report, context)
		var curr_sci: int = _prop_int(curr_report, "science_points", 0)
		if curr_sci > 0 or session_sci > 0:
			for pair in _learning.science_thresholds():
				if pair is Array and pair.size() >= 2:
					var thresh: int = int(pair[0])
					var fid: String = str(pair[1])
					if session_sci >= thresh:
						_add_fact_id(fid, triggered, collected)

	if events.has("METEOROID"):
		_add_trigger("meteoroid", triggered, collected)

	if events.has("RECYCLER_BROKE"):
		_add_trigger("recycler_broke", triggered, collected)

	if events.has("STORM_WARNING") or bool(context.get("storm_warning", false)):
		_add_trigger("storm_warning", triggered, collected)

	if events.has("STORM") and not mission_ended:
		_add_trigger("storm_survived", triggered, collected)

	if (curr_report != null and rep_day == sunset_day) or events.has("SUNSET") or day_start_day == sunset_day:
		_add_trigger("sunset", triggered, collected)

	if curr_report != null:
		var sun_f: float = _prop_float(curr_report, "sun_factor", 1.0)
		var reactor_kwh: float = _prop_float(curr_report, "reactor_kwh", 0.0)
		var bat_pct: float = _prop_float(curr_report, "battery_percent", 100.0)
		if is_equal_approx(sun_f, 0.0):
			if reactor_kwh > 0.0:
				_add_trigger("night_reactor", triggered, collected)
			elif bat_pct < BATTERY_LOW_THRESHOLD:
				_add_trigger("night_battery_low", triggered, collected)

	return triggered


## Evaluate start-of-day M-04 alerts (storm_warning, sunset) once those alert cards close.
func evaluate_day_start(day: int, warnings: Array = [], context: Dictionary = {}) -> Array[String]:
	var warn_codes: Array = []
	for w in warnings:
		var code: String = _event_code(w)
		if not code.is_empty():
			warn_codes.append(code)
	if context.has("events") and context["events"] is Array:
		for e in context["events"]:
			var c: String = _event_code(e)
			if not c.is_empty():
				warn_codes.append(c)
	var ctx := context.duplicate()
	ctx["is_day_start"] = true
	ctx["day_start_day"] = day
	ctx["events"] = warn_codes
	return evaluate(null, null, [], ctx)


## Evaluate both triggered cards and quiet-day "Did you know?" chip selection.
## Every 2nd quiet day (where no card triggered and no M-04 alert showed) picks
## the next uncollected card in quiet_day_pool.
func evaluate_day(
	prev_report: Variant,
	curr_report: Variant,
	jobs: Array = [],
	context: Dictionary = {}
) -> Dictionary:
	var triggered := evaluate(prev_report, curr_report, jobs, context)
	var collected: Dictionary = _collected_set(context)
	for fid in triggered:
		collected[fid] = true

	var events: Dictionary = _extract_events(curr_report, context)
	var sunset_day: int = int(context.get("sunset_day", _get_sunset_day()))
	var rep_day: int = _prop_int(curr_report, "day", 0)
	var had_alert: bool = bool(context.get("had_m04_alert", false)) or _has_m04_alert_in_events(events) or (curr_report != null and rep_day == sunset_day)
	var mission_ended: bool = bool(context.get("mission_ended", false)) or _has_evac_event(events)

	var quiet_count: int = int(context.get("quiet_day_counter", 0))
	var quiet_card_id: String = ""
	var is_quiet: bool = curr_report != null and triggered.is_empty() and not had_alert and not mission_ended

	if is_quiet:
		quiet_count += 1
		if quiet_count % 2 == 0:
			for fid in _learning.quiet_day_pool():
				if not collected.has(fid):
					quiet_card_id = fid
					break

	return {
		"triggered": triggered,
		"quiet_card_id": quiet_card_id,
		"is_quiet_day": is_quiet,
		"quiet_day_counter": quiet_count,
		"session_science_total": _compute_session_science(curr_report, context) if curr_report != null else int(context.get("prior_session_science", 0)),
	}


func _add_trigger(trigger_name: String, out: Array[String], collected: Dictionary) -> void:
	for card in _learning.cards_for_trigger(trigger_name):
		if card is Dictionary:
			_add_fact_id(str(card.get("fact_id", "")), out, collected)


func _add_fact_id(fid: String, out: Array[String], collected: Dictionary) -> void:
	if fid.is_empty() or collected.has(fid) or out.has(fid):
		return
	out.append(fid)


func _collected_set(context: Dictionary) -> Dictionary:
	var set_dict: Dictionary = {}
	var source: Variant = context.get("collected_cards", null)
	if source == null and Settings != null:
		source = Settings.collected_cards
	if source is Array or source is PackedStringArray:
		for fid in source:
			var s: String = str(fid)
			if not s.is_empty():
				set_dict[s] = true
	elif source is Dictionary:
		for k in source.keys():
			if bool(source[k]):
				set_dict[str(k)] = true
	return set_dict


func _get_sunset_day() -> int:
	if Constants != null:
		return int(Constants.v("SUNSET_DAY"))
	return 15


func _compute_session_science(curr_report: Variant, context: Dictionary) -> int:
	if context.has("session_science"):
		return int(context["session_science"])
	var curr_sci: int = _prop_int(curr_report, "science_points", 0)
	var prior: int = int(context.get("prior_session_science", 0))
	return prior + curr_sci


func _did_regolith_increase(prev_report: Variant, curr_report: Variant, executed_jobs: Array[String], context: Dictionary) -> bool:
	var curr_sh: float = _prop_float(curr_report, "shelter_g_cm2", 0.0)
	if prev_report != null:
		return curr_sh > _prop_float(prev_report, "shelter_g_cm2", 0.0) + 0.0001
	if context.has("prev_shelter_g_cm2"):
		return curr_sh > float(context["prev_shelter_g_cm2"]) + 0.0001
	if context.has("initial_shelter_g_cm2"):
		return curr_sh > float(context["initial_shelter_g_cm2"]) + 0.0001
	return _any_job_in(executed_jobs, ["REGOLITH"]) and curr_sh > 0.0001


func _did_clean_dust(prev_report: Variant, curr_report: Variant, executed_jobs: Array[String], is_storm: bool, context: Dictionary) -> bool:
	if is_storm:
		return false
	var default_dust: float = float(Constants.v("DUST_LANDING")) if Constants != null else 0.05
	var prev_dust: float = _prop_float(prev_report, "dust", float(context.get("prev_dust", context.get("initial_dust", default_dust))))
	var curr_dust: float = _prop_float(curr_report, "dust", prev_dust)
	if prev_report != null or context.has("prev_dust") or context.has("initial_dust"):
		return curr_dust < prev_dust - 0.0001
	return _any_job_in(executed_jobs, ["CLEAN"]) and curr_dust < prev_dust - 0.0001


func _any_crew_zero_energy(curr_report: Variant) -> bool:
	var crew_reps: Variant = _prop(curr_report, "crew_reports", [])
	if crew_reps is Array:
		for cr in crew_reps:
			if cr is Dictionary and cr.has("energy") and int(cr.get("energy", -1)) == 0:
				return true
	return false


func _extract_executed_jobs(curr_report: Variant, fallback_jobs: Array, is_storm: bool) -> Array[String]:
	var out: Array[String] = []
	if is_storm:
		return out
	var crew_reps: Variant = _prop(curr_report, "crew_reports", [])
	if crew_reps is Array and not crew_reps.is_empty():
		for cr in crew_reps:
			if cr is Dictionary and cr.has("job"):
				out.append(str(cr.get("job", "")))
		if not out.is_empty():
			return out
	for j in fallback_jobs:
		out.append(str(j))
	return out


func _any_job_in(job_list: Array[String], targets: Array[String]) -> bool:
	for j in job_list:
		if targets.has(j):
			return true
	return false


func _extract_events(curr_report: Variant, context: Dictionary) -> Dictionary:
	var dict: Dictionary = {}
	var rep_events: Variant = _prop(curr_report, "events", [])
	if rep_events is Array:
		for e in rep_events:
			var c := _event_code(e)
			if not c.is_empty():
				dict[c] = true
	var ctx_events: Variant = context.get("events", [])
	if ctx_events is Array:
		for e in ctx_events:
			var c := _event_code(e)
			if not c.is_empty():
				dict[c] = true
	return dict


func _event_code(evt: Variant) -> String:
	if evt == null:
		return ""
	if evt is String:
		return evt
	if evt is Dictionary:
		return str(evt.get("code", ""))
	if evt is Object and "code" in evt:
		return str(evt.code)
	return ""


func _has_evac_event(events: Dictionary) -> bool:
	for k in events.keys():
		if str(k).begins_with(EVAC_PREFIX):
			return true
	return false


func _has_m04_alert_in_events(events: Dictionary) -> bool:
	for code in M04_ALERT_CODES:
		if events.has(code):
			return true
	return false


func _prop(obj: Variant, key: String, default_val: Variant) -> Variant:
	if obj == null:
		return default_val
	if obj is Dictionary:
		return obj.get(key, default_val)
	if obj is Object and key in obj:
		return obj.get(key)
	return default_val


func _prop_int(obj: Variant, key: String, default_val: int) -> int:
	return int(_prop(obj, key, default_val))


func _prop_float(obj: Variant, key: String, default_val: float) -> float:
	return float(_prop(obj, key, default_val))


func _prop_bool(obj: Variant, key: String, default_val: bool) -> bool:
	return bool(_prop(obj, key, default_val))

