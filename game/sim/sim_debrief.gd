class_name SimDebrief
extends RefCounted

const SimResultScript := preload("res://sim/sim_result.gd")

var _c: SimConstants
var _facts: Array = []

func _init(constants: SimConstants = null, facts_data: Array = []) -> void:
	_c = constants
	if not facts_data.is_empty():
		_facts = facts_data.duplicate(true)
	else:
		_load_default_facts()

func _load_default_facts() -> void:
	if not FileAccess.file_exists("res://data/facts.json"):
		return
	var text := FileAccess.get_file_as_string("res://data/facts.json")
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary and parsed.has("facts") and parsed["facts"] is Array:
		_facts = parsed["facts"]

func calculate_stars(outcome: String, ever_sick: bool, science_points: int) -> int:
	if outcome == "SURVIVED":
		var s1: int = 1
		var s2: int = 0 if ever_sick else 1
		var sci_goal: int = int(_c.v("SCIENCE_GOAL_POINTS")) if _c != null else 10
		var s3: int = 1 if science_points >= sci_goal else 0
		return 1 + s2 + (s2 * s3)
	return 0

func determine_root_cause(
	outcome: String,
	log,
	state: Dictionary,
	events = null
) -> Dictionary:
	var sunset_day: int = int(_c.v("SUNSET_DAY")) if _c != null else 15
	var essential_kw: float = 0.0
	if _c != null:
		essential_kw = (
			float(_c.v("LOAD_AIR_KW"))
			+ float(_c.v("LOAD_THERMAL_KW"))
			+ float(_c.v("LOAD_WASTE_KW"))
			+ float(_c.v("LOAD_COMMS_KW"))
			+ float(_c.v("LOAD_WATER_KW"))
			+ float(_c.v("LOAD_FOOD_KW"))
		)

	# Rule 1: Evacuated after a night BLACKOUT and reactor * REACTOR_S_KWE < essential_kW
	if outcome != "SURVIVED":
		var had_night_blackout: bool = false
		if log != null:
			for entry in log.entries:
				if str(entry.get("code", "")) == "BLACKOUT" and int(entry.get("day", 0)) > sunset_day:
					had_night_blackout = true
					break

		var reactors: int = int(state.get("reactor", state.get("reactors", 0)))
		var reactor_kwe_val: float = float(_c.v("REACTOR_S_KWE")) if _c != null else 3.5
		var reactor_gen_kw: float = float(reactors) * reactor_kwe_val

		if had_night_blackout and reactor_gen_kw < essential_kw:
			var night_hours: float = float(_c.v("NIGHT_HOURS")) if _c != null else 348.0
			var battery_cap: float = float(state.get("battery_capacity_kwh", state.get("capacity", 0.0)))
			if battery_cap <= 0.0 and state.has("battery"):
				var batt_unit: float = float(_c.v("BATTERY_UNIT_KWH")) if _c != null else 125.0
				battery_cap = float(state["battery"]) * batt_unit

			var need: float = essential_kw * night_hours
			var have: float = battery_cap + reactor_gen_kw * night_hours
			return {
				"code": "ROOT_NIGHT_ENERGY",
				"values": {
					"have": roundf(have),
					"need": roundf(need)
				},
				"text": "Your night energy: %d kWh. The base needed %d kWh to get through the night." % [roundi(have), roundi(need)]
			}

	# Rule 2: EVAC_RADIATION
	if outcome == "EVAC_RADIATION":
		var g: float = float(state.get("shelter_g_cm2", 0.0))
		var limit: float = float(_c.v("RAD_SPE_LIMIT_MSV")) if _c != null else 250.0
		var g_needed: float = 0.0
		if events != null and events.has_method("shield_needed_for_limit"):
			g_needed = events.shield_needed_for_limit(limit)
		return {
			"code": "ROOT_SHIELD",
			"values": {
				"g": g,
				"g_needed": g_needed,
				"limit": limit
			},
			"text": "Your shelter had %.1f g/cm². About %.1f g/cm² keeps the storm dose under %d mSv." % [g, g_needed, roundi(limit)]
		}

	# Rule 3: EVAC_WATER and recycler still broken
	var recycler_broken: bool = bool(state.get("recycler_broken", false))
	if outcome == "EVAC_WATER" and recycler_broken:
		var d: int = 0
		if log != null:
			var rec_id: int = log.latest("RECYCLER_BROKE")
			if rec_id != -1:
				var rec_entry = log.get_entry(rec_id)
				d = int(rec_entry.get("day", 0))
		if d == 0 and events != null and "recycler_day" in events:
			d = int(events.recycler_day)
		return {
			"code": "ROOT_REPAIR",
			"values": {
				"d": d
			},
			"text": "The water recycler broke on Day %d and was never repaired." % d
		}

	# Rule 4: Any other EVAC_*
	if outcome.begins_with("EVAC_"):
		var item: String = ""
		var packed: float = 0.0
		var used: float = 0.0
		match outcome:
			"EVAC_O2":
				item = "o2"
				packed = float(state.get("initial_o2_kg", 0.0))
				used = packed - maxf(0.0, float(state.get("o2_kg", 0.0)))
			"EVAC_WATER":
				item = "water"
				packed = float(state.get("initial_water_kg", 0.0))
				used = packed - maxf(0.0, float(state.get("water_kg", 0.0)))
			"EVAC_FOOD":
				item = "food"
				packed = float(state.get("initial_food_kg", 0.0))
				used = packed - maxf(0.0, float(state.get("food_kg", 0.0)))
			_:
				item = outcome.trim_prefix("EVAC_").to_lower()
				packed = 0.0
				used = 0.0

		return {
			"code": "ROOT_SUPPLY",
			"values": {
				"item": item,
				"packed": roundf(packed),
				"used": roundf(used)
			},
			"text": "You packed %d kg of %s. The crew used %d kg." % [roundi(packed), item, roundi(used)]
		}

	# Rule 5: SURVIVED
	var ever_sick: bool = bool(state.get("ever_sick", false))
	var ever_tired: bool = bool(state.get("ever_tired", false))
	var tired_indices: Array = state.get("tired_crew_indices", [])
	var tired_name: String = str(state.get("tired_crew_name", ""))
	if tired_name.is_empty() and ever_tired and log != null:
		var collected: Array[String] = []
		for entry in log.entries:
			if str(entry.get("code", "")) == "CREW_TIRED":
				var vals: Dictionary = entry.get("values", {})
				var n: String = str(vals.get("name", ""))
				if not n.is_empty() and not collected.has(n):
					collected.append(n)
				for idx_v in vals.get("crew_indices", []):
					var idx_i: int = int(idx_v)
					if not tired_indices.has(idx_i):
						tired_indices.append(idx_i)
		tired_name = ", ".join(collected)
	if tired_name.is_empty():
		tired_name = "Crew"

	var co2_sick: bool = false
	if log != null and log.latest("CREW_SICK") != -1:
		co2_sick = true
	elif ever_sick and not ever_tired:
		co2_sick = true

	var sci: int = int(state.get("science_points", 0))
	var goal: int = int(_c.v("SCIENCE_GOAL_POINTS")) if _c != null else 10
	var stars: int = calculate_stars(outcome, ever_sick, sci)

	var text: String = ""
	if stars == 3:
		text = "Mission accomplished with 3 stars! The base ran smoothly and all science goals were met."
	elif stars == 2:
		if ever_tired and not co2_sick:
			text = "Mission survived with 2 stars. Missing star: %s got sick from working too hard. Give everyone a Rest day." % tired_name
		elif ever_sick:
			text = "Mission survived with 2 stars. Missing star: The crew got sick from high CO2."
		else:
			text = "Mission survived with 2 stars. Missing star: Science points (%d/%d) were below the goal of %d." % [sci, goal, goal]
	else:
		if ever_tired and not co2_sick:
			text = "Mission survived with 1 star. Missing stars: %s got sick from working too hard, and science points (%d/%d) below goal." % [tired_name, sci, goal]
		elif ever_tired and co2_sick:
			text = "Mission survived with 1 star. Missing stars: crew got sick from high CO2 and overwork, and science points (%d/%d) below goal." % [sci, goal]
		else:
			text = "Mission survived with 1 star. Missing stars: Crew got sick from high CO2, and science points (%d/%d) below goal." % [sci, goal]

	return {
		"code": "ROOT_SUCCESS",
		"values": {
			"stars": stars,
			"ever_sick": ever_sick,
			"ever_tired": ever_tired,
			"co2_sick": co2_sick,
			"name": tired_name,
			"crew_indices": tired_indices.duplicate(),
			"science_points": sci,
			"science_goal": goal
		},
		"text": text
	}

func pick_fact(root_code: String, outcome: String = "", rng: RandomNumberGenerator = null) -> Dictionary:
	if _facts.is_empty():
		return {}

	var target_tag: String = ""
	match root_code:
		"ROOT_NIGHT_ENERGY":
			target_tag = "night"
		"ROOT_SHIELD":
			target_tag = "storm"
		"ROOT_REPAIR":
			target_tag = "water"
		"ROOT_SUPPLY":
			if outcome == "EVAC_WATER":
				target_tag = "water"
			elif outcome == "EVAC_O2" or outcome == "EVAC_CO2":
				target_tag = "oxygen"
			elif outcome == "EVAC_FOOD":
				target_tag = "food"
			else:
				target_tag = ""
		"ROOT_SUCCESS":
			target_tag = ""
		_:
			target_tag = ""

	var candidates: Array = []
	if not target_tag.is_empty():
		for f in _facts:
			if f is Dictionary and f.has("tags") and f["tags"] is Array:
				if f["tags"].has(target_tag):
					candidates.append(f)

	if candidates.is_empty():
		candidates = _facts.duplicate()

	var picked_idx: int = 0
	if rng != null and candidates.size() > 1:
		picked_idx = rng.randi_range(0, candidates.size() - 1)

	var chosen = candidates[picked_idx]
	return chosen if chosen is Dictionary else {}

func build_result(
	outcome: String,
	end_day: int,
	log,
	state: Dictionary,
	events = null,
	rng: RandomNumberGenerator = null
) -> RefCounted:
	var result := SimResultScript.new()
	result.outcome = outcome
	result.end_day = end_day
	result.total_days = int(_c.v("MISSION_DAYS")) if _c != null else 30

	var ever_sick: bool = bool(state.get("ever_sick", false))
	var sci_pts: int = int(state.get("science_points", 0))
	result.stars = calculate_stars(outcome, ever_sick, sci_pts)

	# Cause chain
	if log != null:
		var final_id: int = -1
		if log.entries.size() > 0:
			final_id = int(log.entries[-1]["id"])
		if final_id != -1 and outcome != "SURVIVED":
			result.cause_chain = log.chain_from(final_id, 5)

	# Root cause
	var root_data := determine_root_cause(outcome, log, state, events)
	result.root_cause_code = str(root_data.get("code", ""))
	result.root_cause_values = root_data.get("values", {})
	result.root_cause_text = str(root_data.get("text", ""))

	# Fact
	var chosen_fact := pick_fact(result.root_cause_code, outcome, rng)
	result.fact = chosen_fact
	result.fact_id = str(chosen_fact.get("id", ""))

	# Final stats
	result.stats = state.duplicate(true)

	return result
