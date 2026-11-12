class_name SimDayReport
extends RefCounted

var day: int = 0
var sun_factor: float = 0.0
var generation_kwh: float = 0.0
var solar_kwh: float = 0.0
var reactor_kwh: float = 0.0
var battery_kwh: float = 0.0
var battery_capacity_kwh: float = 0.0
var battery_percent: float = 0.0
var hours_on_battery: float = 24.0
var blackout: bool = false

var power_served: Dictionary = {}
var power_shed: Array[String] = []

var o2_kg: float = 0.0
var co2_mmhg: float = 0.0
var co2_high: bool = false
var water_kg: float = 0.0
var food_kg: float = 0.0
var stocks: Dictionary = {}

var crew_reports: Array[Dictionary] = []
var highest_dose_msv: float = 0.0
var storm_dose_msv: float = 0.0
var ever_sick: bool = false
var ever_tired: bool = false

var greenhouse_alive: bool = false
var greenhouse_healthy: bool = false
var greenhouse_o2_kg: float = 0.0
var greenhouse_wilt_days: int = 0
var greenhouse_healthy_days: int = 0
var greenhouse_growth_days: int = 0

var shelter_g_cm2: float = 0.0
var dust: float = 0.0
var recycler_broken: bool = false
var broken_panels: int = 0
var working_panels: int = 0
var science_points: int = 0
var o2_days_left: float = 0.0
var water_days_left: float = 0.0
var food_days_left: float = 0.0
var days_to_go: int = 0
var storm_dose_if_now_msv: float = 0.0

var events: Array = []
var new_log_ids: Array[int] = []

func to_dict() -> Dictionary:
	return {
		"day": day,
		"sun_factor": sun_factor,
		"generation_kwh": generation_kwh,
		"solar_kwh": solar_kwh,
		"reactor_kwh": reactor_kwh,
		"battery_kwh": battery_kwh,
		"battery_capacity_kwh": battery_capacity_kwh,
		"battery_percent": battery_percent,
		"hours_on_battery": hours_on_battery,
		"blackout": blackout,
		"power_served": power_served.duplicate(true),
		"power_shed": power_shed.duplicate(),
		"o2_kg": o2_kg,
		"co2_mmhg": co2_mmhg,
		"co2_high": co2_high,
		"water_kg": water_kg,
		"food_kg": food_kg,
		"stocks": stocks.duplicate(true),
		"crew": crew_reports.duplicate(true),
		"crew_reports": crew_reports.duplicate(true),
		"highest_dose_msv": highest_dose_msv,
		"storm_dose_msv": storm_dose_msv,
		"ever_sick": ever_sick,
		"ever_tired": ever_tired,
		"greenhouse_alive": greenhouse_alive,
		"greenhouse_healthy": greenhouse_healthy,
		"greenhouse_o2_kg": greenhouse_o2_kg,
		"greenhouse_wilt_days": greenhouse_wilt_days,
		"greenhouse_healthy_days": greenhouse_healthy_days,
		"greenhouse_growth_days": greenhouse_growth_days,
		"shelter_g_cm2": shelter_g_cm2,
		"dust": dust,
		"recycler_broken": recycler_broken,
		"broken_panels": broken_panels,
		"working_panels": working_panels,
		"science_points": science_points,
		"o2_days_left": o2_days_left,
		"water_days_left": water_days_left,
		"food_days_left": food_days_left,
		"days_to_go": days_to_go,
		"storm_dose_if_now_msv": storm_dose_if_now_msv,
		"events": events.duplicate(),
		"new_log_ids": new_log_ids.duplicate()
	}

