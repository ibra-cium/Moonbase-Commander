class_name SimLife
extends RefCounted

const SimCargoScript := preload("res://sim/sim_cargo.gd")

var _c: SimConstants

var o2_kg: float = 0.0
var co2_mmhg: float = 0.0
var water_kg: float = 0.0
var food_kg: float = 0.0
var recycler_broken: bool = false

func _init(constants: SimConstants = null, cargo = null) -> void:
	_c = constants
	if _c != null:
		co2_mmhg = float(_c.v("CO2_START_MMHG"))
	if cargo != null:
		setup_from_cargo(cargo)

func setup(o2_units: int, water_units: int, food_units: int) -> void:
	if _c != null:
		o2_kg = float(o2_units) * float(_c.v("O2_UNIT_KG"))
		water_kg = float(water_units) * float(_c.v("WATER_UNIT_KG"))
		food_kg = float(food_units) * float(_c.v("FOOD_CRATE_MASS_KG"))
		co2_mmhg = float(_c.v("CO2_START_MMHG"))
	recycler_broken = false

func setup_amounts(o2: float, water: float, food: float, co2: float = -1.0) -> void:
	o2_kg = o2
	water_kg = water
	food_kg = food
	if co2 >= 0.0:
		co2_mmhg = co2
	elif _c != null:
		co2_mmhg = float(_c.v("CO2_START_MMHG"))
	recycler_broken = false

func setup_from_cargo(cargo) -> void:
	var o2_units: int = cargo.get_count("o2")
	var water_units: int = cargo.get_count("water")
	var food_units: int = cargo.get_count("food")
	setup(o2_units, water_units, food_units)

func resolve(
	power_result = null,
	greenhouse_o2: float = 0.0,
	greenhouse_water_kg: float = 0.0,
	crew_count: int = -1
) -> Dictionary:
	var crew: int = crew_count if crew_count > 0 else (int(_c.v("MISSION_CREW")) if _c != null else 4)

	var air_on: bool = true
	var water_served: bool = true
	var food_served: bool = true

	if power_result is Dictionary:
		var served: Dictionary = power_result.get("served", power_result)
		air_on = bool(served.get("core", false))
		water_served = bool(served.get("water", false))
		food_served = bool(served.get("food", false))
	elif typeof(power_result) == TYPE_BOOL:
		air_on = power_result
		water_served = power_result
		food_served = power_result

	# 1. CO2
	var prev_co2: float = co2_mmhg
	if air_on:
		co2_mmhg = maxf(float(_c.v("CO2_START_MMHG")), co2_mmhg - float(_c.v("CO2_FALL_PER_DAY_AIR_ON")))
	else:
		co2_mmhg = co2_mmhg + float(_c.v("CO2_RISE_PER_DAY_AIR_OFF"))
	var co2_delta: float = co2_mmhg - prev_co2
	var co2_high: bool = co2_mmhg > float(_c.v("CO2_HEADACHE_MMHG"))

	# 2. Water loss
	var drink_kg: float = float(_c.v("WATER_KG_PERSON_DAY")) * float(crew)
	var plants_kg: float = greenhouse_water_kg
	var recycler_on: bool = water_served and not recycler_broken
	var water_loss_kg: float = 0.0
	if recycler_on:
		water_loss_kg = (drink_kg + plants_kg) * (1.0 - float(_c.v("WATER_RECOVERY_FULL")))
	else:
		water_loss_kg = drink_kg + plants_kg
	water_kg -= water_loss_kg

	# 3. Oxygen (generator limited by water and OGA_O2_KG_DAY)
	var o2_need: float = float(_c.v("O2_KG_PERSON_DAY")) * float(crew) - greenhouse_o2
	var o2_need_clamped: float = maxf(0.0, o2_need)
	var oga_kg: float = 0.0
	if air_on:
		var max_oga_from_water: float = maxf(0.0, water_kg) / float(_c.v("OGA_WATER_PER_KG_O2"))
		oga_kg = minf(o2_need_clamped, minf(float(_c.v("OGA_O2_KG_DAY")), max_oga_from_water))
		oga_kg = maxf(0.0, oga_kg)
	var oga_water_used_kg: float = oga_kg * float(_c.v("OGA_WATER_PER_KG_O2"))
	water_kg -= oga_water_used_kg
	var o2_from_tanks_kg: float = maxf(0.0, o2_need_clamped - oga_kg)
	o2_kg -= o2_from_tanks_kg

	# 4. Food and spoil
	var food_eaten_kg: float = float(_c.v("FOOD_PACKED_KG_PERSON_DAY")) * float(crew)
	food_kg -= food_eaten_kg
	var food_spoiled_kg: float = 0.0
	var food_spoiled: bool = false
	if not food_served:
		food_spoiled_kg = float(_c.v("FOOD_SPOIL_DAYS_IF_OFF")) * food_eaten_kg
		food_kg -= food_spoiled_kg
		food_spoiled = true

	# 5. Supply warnings
	var warning_days: float = float(_c.v("SUPPLY_WARNING_DAYS"))
	var supply_low: Array[String] = []

	var o2_burn_rate: float = maxf(o2_from_tanks_kg, o2_need_clamped)
	if o2_burn_rate > 0.0:
		if (o2_kg / o2_burn_rate) < warning_days:
			supply_low.append("o2")
	elif o2_kg <= 0.0:
		supply_low.append("o2")

	var total_water_used: float = water_loss_kg + oga_water_used_kg
	if total_water_used > 0.0:
		if (water_kg / total_water_used) < warning_days:
			supply_low.append("water")
	elif water_kg <= 0.0:
		supply_low.append("water")

	var total_food_used: float = food_eaten_kg + food_spoiled_kg
	if total_food_used > 0.0:
		if (food_kg / total_food_used) < warning_days:
			supply_low.append("food")
	elif food_kg <= 0.0:
		supply_low.append("food")

	return {
		"air_on": air_on,
		"co2_mmhg": co2_mmhg,
		"co2_high": co2_high,
		"co2_delta": co2_delta,
		"water_kg": water_kg,
		"water_loss_kg": water_loss_kg,
		"oga_water_kg": oga_water_used_kg,
		"water_used_kg": total_water_used,
		"drink_kg": drink_kg,
		"plant_water_kg": plants_kg,
		"recycler_on": recycler_on,
		"o2_kg": o2_kg,
		"o2_need_kg": o2_need_clamped,
		"oga_kg": oga_kg,
		"o2_from_tanks_kg": o2_from_tanks_kg,
		"o2_used_kg": o2_from_tanks_kg,
		"food_kg": food_kg,
		"food_eaten_kg": food_eaten_kg,
		"food_spoiled_kg": food_spoiled_kg,
		"food_used_kg": total_food_used,
		"food_spoiled": food_spoiled,
		"supply_low": supply_low,
	}

func get_food_days_left(crew_count: int = -1) -> float:
	var crew: int = crew_count if crew_count > 0 else (int(_c.v("MISSION_CREW")) if _c != null else 4)
	var daily: float = float(_c.v("FOOD_PACKED_KG_PERSON_DAY")) * float(crew) if _c != null else 9.56
	return (food_kg / daily) if daily > 0.0 else 0.0

func get_water_days_left(crew_count: int = -1, with_recycler: bool = true) -> float:
	var crew: int = crew_count if crew_count > 0 else (int(_c.v("MISSION_CREW")) if _c != null else 4)
	if _c == null:
		return 0.0
	var drink: float = float(_c.v("WATER_KG_PERSON_DAY")) * float(crew)
	var loss: float = drink * (1.0 - float(_c.v("WATER_RECOVERY_FULL"))) if with_recycler else drink
	var oga_o2: float = float(_c.v("O2_KG_PERSON_DAY")) * float(crew)
	var oga_water: float = oga_o2 * float(_c.v("OGA_WATER_PER_KG_O2"))
	var total_daily: float = loss + oga_water
	return (water_kg / total_daily) if total_daily > 0.0 else 0.0

func get_o2_tank_days_left(crew_count: int = -1) -> float:
	var crew: int = crew_count if crew_count > 0 else (int(_c.v("MISSION_CREW")) if _c != null else 4)
	var daily: float = float(_c.v("O2_KG_PERSON_DAY")) * float(crew) if _c != null else 3.58
	return (o2_kg / daily) if daily > 0.0 else 0.0

