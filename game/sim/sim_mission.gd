class_name SimMission
extends RefCounted

const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimConstantsScript := preload("res://sim/sim_constants.gd")
const SimEventsScript := preload("res://sim/sim_events.gd")
const SimEventScript := preload("res://sim/sim_event.gd")
const SimPowerScript := preload("res://sim/sim_power.gd")
const SimLifeScript := preload("res://sim/sim_life.gd")
const SimCrewScript := preload("res://sim/sim_crew.gd")
const SimGreenhouseScript := preload("res://sim/sim_greenhouse.gd")
const SimLogScript := preload("res://sim/sim_log.gd")
const SimDebriefScript := preload("res://sim/sim_debrief.gd")
const SimDayReportScript := preload("res://sim/sim_day_report.gd")
const SimResultScript := preload("res://sim/sim_result.gd")

var _c: SimConstants
var cargo = null
var seed_val: int = 1
var rng: RandomNumberGenerator

var events: RefCounted
var power: RefCounted
var life: RefCounted
var crew: RefCounted
var greenhouse: RefCounted
var log: RefCounted
var debrief: RefCounted

var day: int = 1
var ended: bool = false
var result: RefCounted = null

var shelter_g_cm2: float = 0.0
var dust: float = 0.0
var science_points: int = 0

var initial_o2_kg: float = 0.0
var initial_water_kg: float = 0.0
var initial_food_kg: float = 0.0
var initial_shelter_g_cm2: float = 0.0

func _init(constants: SimConstants = null, p_cargo = null, p_seed: int = 1, force: Dictionary = {}) -> void:
	if constants != null:
		setup(constants, p_cargo, p_seed, force)

func setup(constants: SimConstants, p_cargo, p_seed: int = 1, force: Dictionary = {}) -> void:
	_c = constants
	seed_val = p_seed

	rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	if p_cargo is Dictionary:
		cargo = SimCargoScript.new(_c)
		cargo.load_dict(p_cargo)
	elif p_cargo is Object and p_cargo.has_method("get_count"):
		cargo = p_cargo
	else:
		cargo = SimCargoScript.new(_c)

	day = 1
	ended = false
	result = null
	science_points = 0

	events = SimEventsScript.new(_c)
	events.schedule(rng, force)

	power = SimPowerScript.new(_c, cargo)
	life = SimLifeScript.new(_c, cargo)
	crew = SimCrewScript.new(_c)
	greenhouse = SimGreenhouseScript.new(_c)
	greenhouse.setup_from_cargo(cargo)
	log = SimLogScript.new()
	debrief = SimDebriefScript.new(_c)

	var shield_unit: float = float(_c.v("SHIELD_UNIT_G_CM2")) if _c != null else 1.0
	shelter_g_cm2 = float(cargo.get_count("shield")) * shield_unit
	initial_shelter_g_cm2 = shelter_g_cm2

	dust = float(_c.v("DUST_LANDING")) if _c != null else 0.05
	power.dust = dust

	initial_o2_kg = life.o2_kg
	initial_water_kg = life.water_kg
	initial_food_kg = life.food_kg

func get_start_of_day_popups(p_day: int = -1) -> Array:
	var target_day: int = p_day if p_day > 0 else day
	if events == null:
		return []
	var sod: Array = events.start_of_day(target_day)
	var popups: Array = []
	for evt in sod:
		if evt != null and evt.needs_popup:
			popups.append(evt)
	return popups

func _get_state_dict() -> Dictionary:
	return {
		"solar": power.solar_panels,
		"battery": cargo.get_count("battery") if cargo != null else 0,
		"battery_capacity_kwh": power.capacity_kwh,
		"reactor": power.reactors,
		"reactors": power.reactors,
		"greenhouse": greenhouse.area,
		"greenhouse_alive": greenhouse.alive,
		"o2_kg": life.o2_kg,
		"water_kg": life.water_kg,
		"food_kg": life.food_kg,
		"co2_mmhg": life.co2_mmhg,
		"shelter_g_cm2": shelter_g_cm2,
		"dust": dust,
		"broken_panels": power.broken_panels,
		"recycler_broken": life.recycler_broken,
		"science_points": science_points,
		"ever_sick": crew.ever_sick,
		"ever_tired": crew.ever_tired,
		"tired_crew_indices": crew.tired_indices.duplicate(),
		"tired_crew_name": crew.names_for(crew.tired_indices),
		"highest_dose": crew.get_highest_dose(),
		"initial_o2_kg": initial_o2_kg,
		"initial_water_kg": initial_water_kg,
		"initial_food_kg": initial_food_kg,
		"initial_shelter_g_cm2": initial_shelter_g_cm2
	}

func step_day(plan = null) -> RefCounted:
	if ended:
		return null

	var current_day: int = day
	var start_log_count: int = log.size()
	var today_events: Array = []

	# 1. Start-of-day events (§8)
	var is_storm: bool = events.is_storm_day(current_day)
	var sod_events: Array = events.start_of_day(current_day)
	for evt in sod_events:
		today_events.append(evt)
		if evt.code == "SUNSET":
			log.add(current_day, "SUNSET", {})
		elif evt.code == "STORM_WARNING":
			var warn_min: int = int(_c.v("SPE_WARNING_TYPICAL_MIN")) if _c != null else 60
			log.add(current_day, "STORM_WARNING", {"warning_min": warn_min})

	# 2. Jobs: sick crew -> REST. Storm day -> all REST. Outside flags.
	var crew_jobs: Array[String] = crew.normalize_jobs(plan, is_storm)
	var outside_flags: Array[bool] = crew.outside_flags(life.recycler_broken)
	var has_outside: bool = false
	for f in outside_flags:
		if f:
			has_outside = true
			break

	# 3. Power (§4.1)
	var sci_gear_on: bool = false
	var gh_lights_on: bool = false
	if plan != null:
		if "science_gear_on" in plan:
			sci_gear_on = bool(plan.science_gear_on)
		elif plan is Dictionary and plan.has("science_gear_on"):
			sci_gear_on = bool(plan["science_gear_on"])

		if "greenhouse_lights_on" in plan:
			gh_lights_on = bool(plan.greenhouse_lights_on)
		elif plan is Dictionary and plan.has("greenhouse_lights_on"):
			gh_lights_on = bool(plan["greenhouse_lights_on"])

	var requested_power: Dictionary = {
		"core": true,
		"water": not life.recycler_broken,
		"food": true,
		"eva": has_outside,
		"science": sci_gear_on,
		"greenhouse": (greenhouse.area > 0.0 and greenhouse.alive and gh_lights_on),
		"greenhouse_area": greenhouse.area
	}

	var power_res: Dictionary = power.resolve(current_day, plan, requested_power)
	if power_res["blackout"]:
		var is_night: bool = (current_day > events.sunset_day)
		var cause_id: int = log.cause_for("BLACKOUT", {"is_night": is_night})
		log.add(current_day, "BLACKOUT", {"hours_on_battery": power_res["hours_on_battery"]}, cause_id)

	if not power_res["shed"].is_empty():
		log.add(current_day, "POWER_SHED", {"systems": power_res["shed"]})

	# 4. Greenhouse (§7)
	var gh_served: bool = bool(power_res["served"].get("greenhouse", false))
	var gh_res: Dictionary = greenhouse.resolve(gh_served, life.water_kg)
	if gh_res["died"]:
		log.add(current_day, "PLANTS_DIED", {})
	science_points += int(gh_res["science_point"])

	# 5. Life support (§5)
	var life_res: Dictionary = life.resolve(
		power_res,
		float(gh_res["o2_kg"]),
		float(gh_res["plant_water_kg"]),
		crew.get_crew_count()
	)
	if life_res["co2_high"]:
		log.add(current_day, "CO2_HIGH", {"co2": life.co2_mmhg}, log.cause_for("CO2_HIGH"))
	if life_res["food_spoiled"]:
		log.add(current_day, "FOOD_SPOILED", {"spoil_kg": life_res["food_spoiled_kg"]})
	for supply_item in life_res["supply_low"]:
		log.add(current_day, "SUPPLY_LOW", {"item": supply_item})

	# 6. Radiation dose (§6.3) and storm dose (§8)
	var eva_served: bool = bool(power_res["served"].get("eva", false))
	crew.apply_daily_dose(outside_flags, eva_served)
	var storm_dose: float = 0.0
	if is_storm:
		storm_dose = events.storm_dose(shelter_g_cm2)
		for m in crew.members:
			m.dose_msv += storm_dose
		today_events.append(SimEventScript.new("STORM", current_day, false, {"storm_dose": storm_dose}))

	# 7. Crew sickness and recovery (§6.4, §6.5)
	var sick_res: Dictionary = crew.apply_sickness(life_res["co2_high"], crew_jobs)
	if not sick_res["newly_sick"].is_empty():
		log.add(current_day, "CREW_SICK", {"count": sick_res["newly_sick"].size()}, log.cause_for("CREW_SICK"))
	if not sick_res["newly_tired"].is_empty():
		var tired_ids: Array[int] = sick_res["newly_tired"]
		log.add(current_day, "CREW_TIRED", {
			"count": tired_ids.size(),
			"crew_index": tired_ids[0],
			"crew_indices": tired_ids.duplicate(),
			"name": crew.names_for(tired_ids),
			"cause": SimLogScript.CAUSE_OVERWORK,
		}, log.cause_for("CREW_TIRED"))

	# 8. End checks (§9.1 in exact order)
	var end_outcome: String = ""
	var rad_limit: float = float(_c.v("RAD_SPE_LIMIT_MSV")) if _c != null else 250.0
	var co2_evac: float = float(_c.v("CO2_EVAC_MMHG")) if _c != null else 20.0

	if is_storm and storm_dose > rad_limit:
		end_outcome = "EVAC_RADIATION"
	elif life.co2_mmhg >= co2_evac:
		end_outcome = "EVAC_CO2"
	elif life.o2_kg < 0.0:
		end_outcome = "EVAC_O2"
	elif life.water_kg < 0.0:
		end_outcome = "EVAC_WATER"
	elif life.food_kg < 0.0:
		end_outcome = "EVAC_FOOD"

	if not end_outcome.is_empty():
		ended = true
		var cause_id: int = log.cause_for(end_outcome, {"recycler_broken": life.recycler_broken})
		log.add(current_day, end_outcome, {}, cause_id)
		var state_dict := _get_state_dict()
		result = debrief.build_result(end_outcome, current_day, log, state_dict, events, rng)

		return _build_report(current_day, power_res, gh_res, life_res, storm_dose, today_events, start_log_count)

	# 9. Job effects (§6.2), dust, days_since_farm
	var job_state: Dictionary = {
		"dust": dust,
		"recycler_broken": life.recycler_broken,
		"broken_panels": power.broken_panels,
		"shelter_g_cm2": shelter_g_cm2,
		"science_points": science_points,
		"greenhouse_alive": greenhouse.alive
	}
	var job_effects: Dictionary = crew.apply_job_effects(crew_jobs, power_res["served"], job_state)
	if job_effects["repaired_recycler"]:
		life.recycler_broken = false
	power.broken_panels = int(job_effects["broken_panels"])
	shelter_g_cm2 = float(job_effects["shelter_g_cm2"])
	science_points = int(job_effects["science_points"])
	dust = float(job_effects["dust"])
	power.dust = dust

	if job_effects["dust_high"]:
		log.add(current_day, "DUST_HIGH", {"dust": dust})
	if not job_effects["jobs_no_power"].is_empty():
		log.add(current_day, "JOB_NO_POWER", {"jobs": job_effects["jobs_no_power"]})
	greenhouse.end_of_day(bool(job_effects["farm_worked"]))

	# 10. End-of-day events: recycler breakdown, meteoroid (§8)
	var working_panels_count: int = maxi(0, power.solar_panels - power.broken_panels)
	var eod_events: Array = events.end_of_day(current_day, {"working_panels": working_panels_count})
	for evt in eod_events:
		today_events.append(evt)
		if evt.code == "RECYCLER_BROKE":
			life.recycler_broken = true
			log.add(current_day, "RECYCLER_BROKE", {})
		elif evt.code == "METEOROID":
			power.broken_panels += 1
			log.add(current_day, "METEOROID", {})

	# 11. Day increment / survival check
	var mission_days: int = int(_c.v("MISSION_DAYS")) if _c != null else 30
	if current_day >= mission_days:
		ended = true
		var state_dict := _get_state_dict()
		result = debrief.build_result("SURVIVED", current_day, log, state_dict, events, rng)
	else:
		day += 1

	return _build_report(current_day, power_res, gh_res, life_res, storm_dose, today_events, start_log_count)

func get_total_days() -> int:
	return int(_c.v("MISSION_DAYS")) if _c != null else 30

func get_constants() -> RefCounted:
	return _c

func _build_report(
	current_day: int,
	power_res: Dictionary,
	gh_res: Dictionary,
	life_res: Dictionary,
	storm_dose: float,
	today_events: Array,
	start_log_count: int
) -> RefCounted:
	var report := SimDayReportScript.new()
	report.day = current_day
	report.sun_factor = power.get_sun_factor(current_day)
	report.generation_kwh = float(power_res["generation_kwh"])
	report.solar_kwh = float(power_res["solar_kwh"])
	report.reactor_kwh = float(power_res["reactor_kwh"])
	report.battery_kwh = power.battery_kwh
	report.battery_capacity_kwh = power.capacity_kwh
	report.battery_percent = power.get_battery_percent()
	report.hours_on_battery = float(power_res["hours_on_battery"])
	report.blackout = bool(power_res["blackout"])

	report.power_served = power_res["served"].duplicate(true)
	var power_shed_arr: Array[String] = []
	for s in power_res["shed"]:
		power_shed_arr.append(str(s))
	report.power_shed = power_shed_arr

	report.o2_kg = life.o2_kg
	report.co2_mmhg = life.co2_mmhg
	report.co2_high = bool(life_res["co2_high"])
	report.water_kg = life.water_kg
	report.food_kg = life.food_kg
	report.stocks = {
		"o2_kg": life.o2_kg,
		"water_kg": life.water_kg,
		"food_kg": life.food_kg,
		"co2_mmhg": life.co2_mmhg
	}

	report.crew_reports = []
	for m in crew.members:
		report.crew_reports.append(m.to_dict())
	report.highest_dose_msv = crew.get_highest_dose()
	report.storm_dose_msv = storm_dose
	report.ever_sick = crew.ever_sick
	report.ever_tired = crew.ever_tired

	report.greenhouse_alive = greenhouse.alive
	report.greenhouse_healthy = bool(gh_res["healthy"])
	report.greenhouse_o2_kg = float(gh_res["o2_kg"])
	report.greenhouse_wilt_days = greenhouse.wilt_days
	report.greenhouse_healthy_days = greenhouse.healthy_days
	report.greenhouse_growth_days = greenhouse.growth_days

	report.shelter_g_cm2 = shelter_g_cm2
	report.dust = dust
	report.recycler_broken = life.recycler_broken
	report.broken_panels = power.broken_panels
	report.working_panels = maxi(0, power.solar_panels - power.broken_panels)
	report.science_points = science_points
	var crew_cnt: int = crew.members.size()
	report.o2_days_left = life.get_o2_tank_days_left(crew_cnt)
	report.water_days_left = life.get_water_days_left(crew_cnt, not life.recycler_broken)
	report.food_days_left = life.get_food_days_left(crew_cnt)
	report.days_to_go = maxi(0, get_total_days() - current_day)
	report.storm_dose_if_now_msv = events.storm_dose(shelter_g_cm2)

	report.events = today_events.duplicate()

	var new_ids: Array[int] = []
	for i in range(start_log_count, log.size()):
		new_ids.append(int(log.entries[i]["id"]))
	report.new_log_ids = new_ids

	return report
