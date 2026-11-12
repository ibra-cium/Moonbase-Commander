class_name SimCargo
extends RefCounted

const ITEM_KEYS: Array[String] = [
	"solar",
	"battery",
	"reactor",
	"greenhouse",
	"o2",
	"water",
	"food",
	"shield"
]

var _c: SimConstants
var _counts: Dictionary = {}

func _init(constants: SimConstants = null) -> void:
	_c = constants
	for key in ITEM_KEYS:
		_counts[key] = 0

func _canonical_key(key: String) -> String:
	if key == "gh":
		return "greenhouse"
	return key

func get_count(key: String) -> int:
	var canonical := _canonical_key(key)
	return int(_counts.get(canonical, 0))

func set_count(key: String, n: int) -> void:
	var canonical := _canonical_key(key)
	if not ITEM_KEYS.has(canonical):
		return
	var max_limit := max_units(canonical)
	_counts[canonical] = clampi(n, 0, max_limit)

func max_units(key: String) -> int:
	var canonical := _canonical_key(key)
	match canonical:
		"solar":
			return int(_c.v("SOLAR_MAX_UNITS"))
		"battery":
			return int(_c.v("BATTERY_MAX_UNITS"))
		"reactor":
			return int(_c.v("REACTOR_MAX_UNITS"))
		"greenhouse":
			var options: Array = _c.v("GREENHOUSE_SIZE_OPTIONS_M2")
			var max_opt: int = 0
			for opt in options:
				if int(opt) > max_opt:
					max_opt = int(opt)
			return max_opt
		"o2", "water", "food", "shield":
			return int(_c.v("SUPPLY_MAX_UNITS"))
	return 0

func max_count(key: String) -> int:
	return max_units(key)

func unit_mass(key: String) -> float:
	var canonical := _canonical_key(key)
	match canonical:
		"solar":
			return float(_c.v("SOLAR_UNIT_MASS_KG"))
		"battery":
			return float(_c.v("BATTERY_UNIT_MASS_KG"))
		"reactor":
			return float(_c.v("REACTOR_S_MASS_KG"))
		"greenhouse":
			return float(_c.v("GREENHOUSE_KG_PER_M2"))
		"o2":
			return float(_c.v("O2_UNIT_MASS_KG"))
		"water":
			return float(_c.v("WATER_UNIT_MASS_KG"))
		"food":
			return float(_c.v("FOOD_CRATE_MASS_KG"))
		"shield":
			return float(_c.v("SHIELD_UNIT_KG"))
	return 0.0

func total_mass() -> float:
	var total: float = 0.0
	for key in ITEM_KEYS:
		total += float(get_count(key)) * unit_mass(key)
	return total

func is_valid() -> bool:
	var limit_kg: float = float(_c.v("CARGO_LIMIT_KG"))
	if total_mass() > limit_kg:
		return false
	for key in ITEM_KEYS:
		var count: int = get_count(key)
		if count < 0 or count > max_units(key):
			return false
	var gh_options: Array = _c.v("GREENHOUSE_SIZE_OPTIONS_M2")
	var gh_count := get_count("greenhouse")
	var gh_valid := false
	for opt in gh_options:
		if int(opt) == gh_count:
			gh_valid = true
			break
	if not gh_valid:
		return false
	return true

func battery_kwh_capacity() -> float:
	return float(get_count("battery")) * float(_c.v("BATTERY_UNIT_KWH"))

func solar_kw() -> float:
	return float(get_count("solar")) * float(_c.v("SOLAR_UNIT_KW"))

func reactor_kw() -> float:
	return float(get_count("reactor")) * float(_c.v("REACTOR_S_KWE"))

func o2_kg() -> float:
	return float(get_count("o2")) * float(_c.v("O2_UNIT_KG"))

func water_kg() -> float:
	return float(get_count("water")) * float(_c.v("WATER_UNIT_KG"))

func food_kg() -> float:
	return float(get_count("food")) * float(_c.v("FOOD_CRATE_MASS_KG"))

func shelter_g_cm2() -> float:
	return float(get_count("shield")) * float(_c.v("SHIELD_UNIT_G_CM2"))

func food_days() -> float:
	var daily_rate: float = float(_c.v("FOOD_PACKED_KG_PERSON_DAY")) * float(_c.v("MISSION_CREW"))
	if daily_rate <= 0.0:
		return 0.0
	return food_kg() / daily_rate

func water_days() -> float:
	var crew: float = float(_c.v("MISSION_CREW"))
	var drink_loss: float = float(_c.v("WATER_KG_PERSON_DAY")) * crew * (1.0 - float(_c.v("WATER_RECOVERY_FULL")))
	var oga_water: float = float(_c.v("O2_KG_PERSON_DAY")) * crew * float(_c.v("OGA_WATER_PER_KG_O2"))
	var daily_use: float = drink_loss + oga_water
	if daily_use <= 0.0:
		return 0.0
	return water_kg() / daily_use

func essential_kw() -> float:
	var core_kw: float = float(_c.v("LOAD_AIR_KW")) + float(_c.v("LOAD_THERMAL_KW")) + float(_c.v("LOAD_WASTE_KW")) + float(_c.v("LOAD_COMMS_KW"))
	var water_kw: float = float(_c.v("LOAD_WATER_KW"))
	var food_kw: float = float(_c.v("LOAD_FOOD_KW"))
	return core_kw + water_kw + food_kw

func night_energy_need_kwh() -> float:
	return essential_kw() * float(_c.v("NIGHT_HOURS"))

func night_energy_have_kwh() -> float:
	return battery_kwh_capacity() + reactor_kw() * float(_c.v("NIGHT_HOURS"))

func get_warnings() -> Array[Dictionary]:
	var mission_days: float = float(_c.v("MISSION_DAYS"))
	var f_days: float = food_days()
	var w_days: float = water_days()
	var have_kwh: float = night_energy_have_kwh()
	var need_kwh: float = night_energy_need_kwh()

	var food_warn: Dictionary = {
		"code": "WARN_FOOD",
		"values": {
			"n": snappedf(f_days, 0.1),
			"days": f_days,
			"target_days": mission_days,
			"is_warning": f_days < mission_days,
			"source_id": "FOOD_PACKED_KG_PERSON_DAY"
		}
	}
	var water_warn: Dictionary = {
		"code": "WARN_WATER",
		"values": {
			"n": snappedf(w_days, 0.1),
			"days": w_days,
			"target_days": mission_days,
			"is_warning": w_days < mission_days,
			"source_id": "WATER_RECOVERY_FULL"
		}
	}
	var night_warn: Dictionary = {
		"code": "WARN_NIGHT_ENERGY",
		"values": {
			"have": roundf(have_kwh),
			"need": roundf(need_kwh),
			"is_warning": have_kwh < need_kwh,
			"source_id": "NIGHT_HOURS"
		}
	}
	return [food_warn, water_warn, night_warn]

func get_active_warnings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for w in get_warnings():
		var vals: Dictionary = w.get("values", {})
		if vals.get("is_warning", false):
			result.append(w)
	return result

func has_warnings() -> bool:
	return not get_active_warnings().is_empty()

func get_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in ITEM_KEYS:
		result.append(get_catalog_entry(key))
	return result

func get_catalog_entry(key: String) -> Dictionary:
	var canonical := _canonical_key(key)
	match canonical:
		"solar":
			return {
				"key": "solar",
				"name_key": "PACK_ITEM_SOLAR",
				"unit_mass": unit_mass("solar"),
				"max_units": max_units("solar"),
				"mass_id": "SOLAR_UNIT_MASS_KG",
				"max_id": "SOLAR_MAX_UNITS",
				"benefit_id": "SOLAR_UNIT_KW"
			}
		"battery":
			return {
				"key": "battery",
				"name_key": "PACK_ITEM_BATTERY",
				"unit_mass": unit_mass("battery"),
				"max_units": max_units("battery"),
				"mass_id": "BATTERY_UNIT_MASS_KG",
				"max_id": "BATTERY_MAX_UNITS",
				"benefit_id": "BATTERY_UNIT_KWH"
			}
		"reactor":
			return {
				"key": "reactor",
				"name_key": "PACK_ITEM_REACTOR",
				"unit_mass": unit_mass("reactor"),
				"max_units": max_units("reactor"),
				"mass_id": "REACTOR_S_MASS_KG",
				"max_id": "REACTOR_MAX_UNITS",
				"benefit_id": "REACTOR_S_KWE"
			}
		"greenhouse":
			return {
				"key": "greenhouse",
				"name_key": "PACK_ITEM_GREENHOUSE",
				"unit_mass": unit_mass("greenhouse"),
				"max_units": max_units("greenhouse"),
				"mass_id": "GREENHOUSE_KG_PER_M2",
				"max_id": "GREENHOUSE_SIZE_OPTIONS_M2",
				"benefit_id": "GREENHOUSE_SIZE_OPTIONS_M2",
				"size_options": _c.v("GREENHOUSE_SIZE_OPTIONS_M2")
			}
		"o2":
			return {
				"key": "o2",
				"name_key": "PACK_ITEM_O2",
				"unit_mass": unit_mass("o2"),
				"max_units": max_units("o2"),
				"mass_id": "O2_UNIT_MASS_KG",
				"max_id": "SUPPLY_MAX_UNITS",
				"benefit_id": "O2_UNIT_KG"
			}
		"water":
			return {
				"key": "water",
				"name_key": "PACK_ITEM_WATER",
				"unit_mass": unit_mass("water"),
				"max_units": max_units("water"),
				"mass_id": "WATER_UNIT_MASS_KG",
				"max_id": "SUPPLY_MAX_UNITS",
				"benefit_id": "WATER_UNIT_KG"
			}
		"food":
			return {
				"key": "food",
				"name_key": "PACK_ITEM_FOOD",
				"unit_mass": unit_mass("food"),
				"max_units": max_units("food"),
				"mass_id": "FOOD_CRATE_MASS_KG",
				"max_id": "SUPPLY_MAX_UNITS",
				"benefit_id": "FOOD_CRATE_MASS_KG"
			}
		"shield":
			return {
				"key": "shield",
				"name_key": "PACK_ITEM_SHIELD",
				"unit_mass": unit_mass("shield"),
				"max_units": max_units("shield"),
				"mass_id": "SHIELD_UNIT_KG",
				"max_id": "SUPPLY_MAX_UNITS",
				"benefit_id": "SHIELD_UNIT_G_CM2"
			}
	return {}

func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for key in ITEM_KEYS:
		result[key] = get_count(key)
	return result

func load_dict(data: Dictionary) -> void:
	for key in data.keys():
		var str_key := str(key)
		set_count(str_key, int(data[key]))

func clone() -> SimCargo:
	var copy := SimCargo.new(_c)
	copy.load_dict(to_dict())
	return copy

static func from_dict(dict: Dictionary, constants: SimConstants) -> SimCargo:
	var cargo := SimCargo.new(constants)
	cargo.load_dict(dict)
	return cargo
