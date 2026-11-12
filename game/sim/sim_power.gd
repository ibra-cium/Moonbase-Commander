class_name SimPower
extends RefCounted

const SimCargoScript := preload("res://sim/sim_cargo.gd")

const OUTSIDE_JOBS: Array[String] = [
	"REGOLITH",
	"SCIENCE",
	"CLEAN",
	"REPAIR_PANEL"
]

var _c: SimConstants

var solar_panels: int = 0
var reactors: int = 0
var greenhouse_area: float = 0.0

var battery_kwh: float = 0.0
var capacity_kwh: float = 0.0
var dust: float = 0.0
var broken_panels: int = 0

func _init(constants: SimConstants = null, cargo = null) -> void:
	_c = constants
	if _c != null:
		dust = float(_c.v("DUST_LANDING"))
	if cargo != null:
		setup_from_cargo(cargo)

func setup(solar: int, battery: int, reactor: int, gh_area: float = 0.0) -> void:
	solar_panels = solar
	reactors = reactor
	greenhouse_area = gh_area
	if _c != null:
		capacity_kwh = float(battery) * float(_c.v("BATTERY_UNIT_KWH"))
		battery_kwh = capacity_kwh
		dust = float(_c.v("DUST_LANDING"))
		broken_panels = 0

func setup_from_cargo(cargo) -> void:
	var solar: int = cargo.get_count("solar")
	var battery: int = cargo.get_count("battery")
	var reactor: int = cargo.get_count("reactor")
	var gh_area: float = float(cargo.get_count("greenhouse"))
	setup(solar, battery, reactor, gh_area)

func get_sun_factor(day: int) -> float:
	var sunset_day: int = int(_c.v("SUNSET_DAY"))
	if day < sunset_day:
		return 1.0
	elif day == sunset_day:
		return float(_c.v("SUN_FACTOR_SUNSET_DAY"))
	else:
		return 0.0

func sun_factor(day: int) -> float:
	return get_sun_factor(day)

func get_systems_priority(area: float = -1.0) -> Array[Dictionary]:
	var gh_a: float = greenhouse_area if area < 0.0 else area
	var core_kw: float = (
		float(_c.v("LOAD_AIR_KW"))
		+ float(_c.v("LOAD_THERMAL_KW"))
		+ float(_c.v("LOAD_WASTE_KW"))
		+ float(_c.v("LOAD_COMMS_KW"))
	)
	var gh_kw: float = float(_c.v("GREENHOUSE_W_PER_M2")) * gh_a / 1000.0
	return [
		{"key": "core", "kw": core_kw},
		{"key": "water", "kw": float(_c.v("LOAD_WATER_KW"))},
		{"key": "food", "kw": float(_c.v("LOAD_FOOD_KW"))},
		{"key": "eva", "kw": float(_c.v("LOAD_EVA_KW"))},
		{"key": "science", "kw": float(_c.v("LOAD_OPS_KW"))},
		{"key": "greenhouse", "kw": gh_kw},
	]

func _has_outside_job(plan) -> bool:
	if plan == null:
		return false
	if plan.has_method("has_outside_jobs"):
		return plan.has_outside_jobs()
	if "outside" in plan:
		return bool(plan.outside)
	if "jobs" in plan:
		var jobs_val = plan.jobs
		if jobs_val is Array:
			for j in jobs_val:
				if OUTSIDE_JOBS.has(str(j)):
					return true
	if plan is Dictionary:
		if plan.has("outside"):
			return bool(plan["outside"])
		if plan.has("jobs") and plan["jobs"] is Array:
			for j in plan["jobs"]:
				if OUTSIDE_JOBS.has(str(j)):
					return true
	return false

func resolve(day: int, plan = null, requested: Dictionary = {}) -> Dictionary:
	var working_panels: int = maxi(0, solar_panels - broken_panels)
	var sun: float = get_sun_factor(day)
	var effective_dust: float = clampf(dust, 0.0, float(_c.v("DUST_MAX_LOSS")))
	var solar_gen: float = float(working_panels) * float(_c.v("SOLAR_UNIT_KW")) * 24.0 * sun * (1.0 - effective_dust)
	var reactor_gen: float = float(reactors) * float(_c.v("REACTOR_S_KWE")) * 24.0
	var generation_kwh: float = solar_gen + reactor_gen

	var battery_before: float = battery_kwh
	var supply: float = generation_kwh + battery_before
	var supply_before_core: float = supply

	var gh_area: float = greenhouse_area
	if requested.has("greenhouse_area"):
		gh_area = float(requested["greenhouse_area"])
	elif requested.has("area"):
		gh_area = float(requested["area"])
	elif plan != null and "greenhouse_area" in plan:
		gh_area = float(plan.greenhouse_area)

	var systems := get_systems_priority(gh_area)

	var served: Dictionary = {}
	var shed_list: Array[String] = []
	var has_shed: bool = false
	var hours_on_battery: float = 24.0

	for sys in systems:
		var key: String = sys["key"]
		var kw: float = sys["kw"]
		if requested.has(key) and (typeof(requested[key]) == TYPE_FLOAT or typeof(requested[key]) == TYPE_INT):
			kw = float(requested[key])

		var is_requested: bool = false
		if requested.has(key):
			if typeof(requested[key]) == TYPE_BOOL:
				is_requested = requested[key]
			else:
				is_requested = (kw > 0.0)
		else:
			match key:
				"core":
					is_requested = true
				"food":
					is_requested = true
				"water":
					var recycler_broken: bool = bool(requested.get("recycler_broken", false))
					if not recycler_broken and plan != null and "recycler_broken" in plan:
						recycler_broken = bool(plan.recycler_broken)
					is_requested = not recycler_broken
				"eva":
					var outside: bool = bool(requested.get("has_outside_job", requested.get("outside", false)))
					if not outside and plan != null:
						outside = _has_outside_job(plan)
					is_requested = outside
				"science":
					var sci_on: bool = bool(requested.get("science_gear_on", false))
					if not sci_on and plan != null:
						if "science_gear_on" in plan:
							sci_on = bool(plan.science_gear_on)
						elif plan is Dictionary and plan.has("science_gear_on"):
							sci_on = bool(plan["science_gear_on"])
					is_requested = sci_on
				"greenhouse":
					var gh_on: bool = bool(requested.get("greenhouse_lights_on", false))
					if not gh_on and plan != null:
						if "greenhouse_lights_on" in plan:
							gh_on = bool(plan.greenhouse_lights_on)
						elif plan is Dictionary and plan.has("greenhouse_lights_on"):
							gh_on = bool(plan["greenhouse_lights_on"])
					is_requested = (gh_area > 0.0 and gh_on)

		if not is_requested or kw <= 0.0:
			served[key] = false
			continue

		var need: float = kw * 24.0
		if key == "core":
			supply_before_core = supply

		if not has_shed and need <= supply:
			served[key] = true
			supply -= need
		else:
			if not has_shed:
				if key == "core":
					hours_on_battery = (supply_before_core / kw) if kw > 0.0 else 0.0
				supply = 0.0
				has_shed = true
			served[key] = false
			shed_list.append(key)

	var battery_after: float = minf(capacity_kwh, supply)
	battery_kwh = battery_after

	return {
		"generation_kwh": generation_kwh,
		"solar_kwh": solar_gen,
		"reactor_kwh": reactor_gen,
		"served": served,
		"shed": shed_list,
		"battery_after": battery_after,
		"battery_before": battery_before,
		"hours_on_battery": hours_on_battery,
		"blackout": not served.get("core", false)
	}

func get_battery_percent() -> float:
	if capacity_kwh <= 0.0:
		return 0.0
	return clampf(battery_kwh / capacity_kwh * 100.0, 0.0, 100.0)

