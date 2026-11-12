class_name SimGreenhouse
extends RefCounted

var _c: SimConstants

var area: float = 0.0
var alive: bool = false
var days_since_farm: int = 0
var wilt_days: int = 0
var healthy_days: int = 0
var growth_days: int = 0

func _init(constants: SimConstants = null, gh_area: float = 0.0) -> void:
	_c = constants
	setup(gh_area)

func setup(gh_area: float) -> void:
	area = maxf(0.0, gh_area)
	alive = area > 0.0
	days_since_farm = 0
	wilt_days = 0
	healthy_days = 0
	growth_days = 0

func setup_from_cargo(cargo) -> void:
	var gh_area: float = 0.0
	if cargo != null:
		if cargo.has_method("get_count"):
			gh_area = float(cargo.get_count("greenhouse"))
		elif "greenhouse" in cargo:
			gh_area = float(cargo["greenhouse"])
		elif "gh" in cargo:
			gh_area = float(cargo["gh"])
	setup(gh_area)

func resolve(served: bool, water_kg: float) -> Dictionary:
	if area <= 0.0 or not alive:
		return {
			"healthy": false,
			"o2_kg": 0.0,
			"water_kg": 0.0,
			"plant_water_kg": 0.0,
			"science_point": 0,
			"science_points": 0,
			"died": false,
			"alive": alive,
			"wilt_days": wilt_days,
			"healthy_days": healthy_days,
			"growth_days": growth_days,
		}

	var farm_limit: int = int(_c.v("FARM_EVERY_DAYS")) if _c != null else 2
	var healthy: bool = served and (water_kg > 0.0) and (days_since_farm < farm_limit)

	var o2_kg: float = 0.0
	var science_point: int = 0
	var died: bool = false
	var water_rate: float = float(_c.v("GREENHOUSE_WATER_L_M2_DAY")) if _c != null else 2.1
	var plant_water: float = 0.0

	if healthy:
		wilt_days = 0
		healthy_days += 1
		growth_days += 1

		var o2_rate: float = float(_c.v("CROP_O2_G_M2_DAY")) if _c != null else 39.777778
		o2_kg = o2_rate * area / 1000.0

		var days_per_pt: int = int(_c.v("GREENHOUSE_DAYS_PER_POINT")) if _c != null else 3
		if days_per_pt > 0 and (healthy_days % days_per_pt == 0):
			science_point = 1

		plant_water = water_rate * area
	else:
		o2_kg = 0.0
		wilt_days += 1
		if wilt_days >= 2:
			alive = false
			died = true
		if served and water_kg > 0.0:
			plant_water = water_rate * area

	return {
		"healthy": healthy,
		"o2_kg": o2_kg,
		"water_kg": plant_water,
		"plant_water_kg": plant_water,
		"science_point": science_point,
		"science_points": science_point,
		"died": died,
		"alive": alive,
		"wilt_days": wilt_days,
		"healthy_days": healthy_days,
		"growth_days": growth_days,
	}

func end_of_day(farmed_today: bool) -> void:
	if area <= 0.0 or not alive:
		return
	if farmed_today:
		days_since_farm = 0
	else:
		days_since_farm += 1

func to_dict() -> Dictionary:
	return {
		"area": area,
		"alive": alive,
		"days_since_farm": days_since_farm,
		"wilt_days": wilt_days,
		"healthy_days": healthy_days,
		"growth_days": growth_days,
	}

