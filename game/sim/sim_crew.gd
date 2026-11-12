class_name SimCrew
extends RefCounted

const SimPlanScript := preload("res://sim/sim_plan.gd")

class CrewMember:
	extends RefCounted
	var job: String = "REST"
	var sick_days: int = 0
	var dose_msv: float = 0.0
	var energy: int = 3

	func is_sick() -> bool:
		return sick_days > 0

	func get_health_status() -> String:
		return "SICK" if is_sick() else "OK"

	func to_dict() -> Dictionary:
		return {
			"job": job,
			"sick_days": sick_days,
			"dose_msv": dose_msv,
			"energy": energy,
			"sick": is_sick(),
			"health": get_health_status()
		}

const DEFAULT_CREW_NAMES: Array[String] = ["Rafi", "Mira", "Leo", "Nadia"]

var _c: SimConstants
var members: Array[CrewMember] = []
var ever_sick: bool = false
var ever_tired: bool = false
var tired_indices: Array[int] = []

func _init(constants: SimConstants = null, crew_count: int = -1) -> void:
	_c = constants
	setup(crew_count)

func get_max_energy() -> int:
	return int(_c.v("CREW_ENERGY_MAX")) if _c != null else 3

func member_name(idx: int) -> String:
	if idx >= 0 and idx < DEFAULT_CREW_NAMES.size():
		return DEFAULT_CREW_NAMES[idx]
	return "Crew %d" % (idx + 1)

func names_for(indices: Array) -> String:
	var parts: Array[String] = []
	for idx_val in indices:
		parts.append(member_name(int(idx_val)))
	return ", ".join(parts)

func setup(crew_count: int = -1) -> void:
	var count: int = crew_count
	if count <= 0:
		count = int(_c.v("MISSION_CREW")) if _c != null else 4

	var max_energy: int = get_max_energy()
	members.clear()
	for i in range(count):
		var m := CrewMember.new()
		m.job = SimPlanScript.JOB_REST
		m.sick_days = 0
		m.dose_msv = 0.0
		m.energy = max_energy
		members.append(m)
	ever_sick = false
	ever_tired = false
	tired_indices.clear()

func get_crew_count() -> int:
	return members.size()

func get_member(idx: int) -> CrewMember:
	if idx >= 0 and idx < members.size():
		return members[idx]
	return null

func get_jobs() -> Array[String]:
	var result: Array[String] = []
	for m in members:
		result.append(m.job)
	return result

func get_sick_count() -> int:
	var count: int = 0
	for m in members:
		if m.is_sick():
			count += 1
	return count

func is_anyone_sick() -> bool:
	return get_sick_count() > 0

func get_highest_dose() -> float:
	var highest: float = 0.0
	for m in members:
		if m.dose_msv > highest:
			highest = m.dose_msv
	return highest

func normalize_jobs(plan = null, storm_today: bool = false) -> Array[String]:
	var normalized: Array[String] = []

	for i in range(members.size()):
		var m := members[i]
		if storm_today:
			m.job = SimPlanScript.JOB_REST
		elif m.is_sick():
			m.job = SimPlanScript.JOB_REST
		else:
			var job_code: String = SimPlanScript.JOB_REST
			if plan != null:
				if plan.has_method("get_job"):
					job_code = plan.get_job(i)
				elif "jobs" in plan and plan.jobs is Array and i < plan.jobs.size():
					job_code = str(plan.jobs[i])
				elif plan is Array and i < plan.size():
					job_code = str(plan[i])
				elif plan is Dictionary and plan.has("jobs") and i < plan["jobs"].size():
					job_code = str(plan["jobs"][i])
			m.job = job_code
		normalized.append(m.job)

	return normalized

func outside_flags(state = null) -> Array[bool]:
	var recycler_broken: bool = false
	if state is bool:
		recycler_broken = state
	elif state is Dictionary:
		recycler_broken = bool(state.get("recycler_broken", state.get("broken_rec", false)))
	elif state != null and "recycler_broken" in state:
		recycler_broken = bool(state.recycler_broken)

	var flags: Array[bool] = []
	var cur_rec_broken: bool = recycler_broken

	for i in range(members.size()):
		var job_code: String = members[i].job
		if state is Dictionary and state.has("jobs") and state["jobs"] is Array:
			if i < state["jobs"].size():
				job_code = str(state["jobs"][i])

		var is_outside: bool = false
		match job_code:
			"REGOLITH", "SCIENCE", "CLEAN", "REPAIR_PANEL":
				is_outside = true
			"REST", "FARM", "REPAIR_REC":
				is_outside = false
			"REPAIR":
				if cur_rec_broken:
					is_outside = false
					cur_rec_broken = false
				else:
					is_outside = true
			_:
				is_outside = false
		flags.append(is_outside)

	return flags

func apply_daily_dose(worked_outside: Array, eva_served: bool = true) -> Array[float]:
	var doses: Array[float] = []
	var habitat_rad: float = float(_c.v("RAD_HABITAT_MSV_DAY")) if _c != null else 0.95
	var surface_rad: float = float(_c.v("RAD_SURFACE_MSV_DAY")) if _c != null else 1.369

	for i in range(members.size()):
		var is_outside: bool = false
		if i < worked_outside.size():
			is_outside = bool(worked_outside[i]) and eva_served

		var dose_add: float = surface_rad if is_outside else habitat_rad
		members[i].dose_msv += dose_add
		doses.append(members[i].dose_msv)

	return doses

func apply_sickness(co2_high: bool, jobs: Array = []) -> Dictionary:
	var newly_sick: Array[int] = []
	var newly_tired: Array[int] = []
	var recovered: Array[int] = []
	var sick_days_duration: int = int(_c.v("SICK_REST_DAYS")) if _c != null else 2
	var max_energy: int = get_max_energy()

	for i in range(members.size()):
		var m := members[i]
		var member_job: String = m.job
		if i < jobs.size() and not str(jobs[i]).is_empty():
			member_job = str(jobs[i])
		var was_sick: bool = m.sick_days > 0

		if co2_high:
			if member_job == SimPlanScript.JOB_REST:
				m.energy = max_energy
			elif m.energy > 0:
				m.energy -= 1
			if not was_sick:
				m.sick_days = sick_days_duration
				ever_sick = true
				newly_sick.append(i)
		else:
			if was_sick:
				if member_job == SimPlanScript.JOB_REST:
					m.energy = max_energy
					m.sick_days -= 1
					if m.sick_days <= 0:
						m.sick_days = 0
						recovered.append(i)
			else:
				if member_job == SimPlanScript.JOB_REST:
					m.energy = max_energy
				elif m.energy > 0:
					m.energy -= 1
				else:
					m.sick_days = sick_days_duration
					ever_sick = true
					ever_tired = true
					newly_tired.append(i)
					if not tired_indices.has(i):
						tired_indices.append(i)

	return {
		"co2_high": co2_high,
		"newly_sick": newly_sick,
		"newly_tired": newly_tired,
		"recovered": recovered,
		"sick_count": get_sick_count(),
		"ever_sick": ever_sick,
		"ever_tired": ever_tired
	}

func apply_job_effects(
	jobs: Array,
	power_served: Dictionary = {},
	state: Dictionary = {}
) -> Dictionary:
	var eva_served: bool = bool(power_served.get("eva", false))
	var sci_served: bool = bool(power_served.get("science", power_served.get("ops", false)))

	var cur_dust: float = float(state.get("dust", 0.0))
	var rec_broken: bool = bool(state.get("recycler_broken", false))
	var broken_pan: int = int(state.get("broken_panels", 0))
	var shelter_g: float = float(state.get("shelter_g_cm2", 0.0))
	var sci_pts: int = int(state.get("science_points", 0))
	var gh_alive: bool = bool(state.get("greenhouse_alive", true))

	var repaired_recycler: bool = false
	var repaired_panels: int = 0
	var shelter_added: float = 0.0
	var science_added: int = 0
	var farm_worked: bool = false
	var clean_worked: bool = false
	var outside_worked_count: int = 0
	var worked_outside_flags: Array[bool] = []
	var jobs_no_power: Array[int] = []

	for i in range(jobs.size()):
		var job_code: String = str(jobs[i])

		var is_outside: bool = false
		match job_code:
			"REGOLITH", "SCIENCE", "CLEAN", "REPAIR_PANEL":
				is_outside = true
			"REPAIR":
				if rec_broken and not repaired_recycler:
					is_outside = false
				else:
					is_outside = true
			_:
				is_outside = false

		if is_outside and not eva_served:
			jobs_no_power.append(i)
			worked_outside_flags.append(false)
			continue

		if job_code == "SCIENCE" and not sci_served:
			jobs_no_power.append(i)
			worked_outside_flags.append(false)
			continue

		if is_outside:
			worked_outside_flags.append(true)
		else:
			worked_outside_flags.append(false)

		match job_code:
			"REPAIR":
				if rec_broken and not repaired_recycler:
					repaired_recycler = true
					rec_broken = false
				elif broken_pan > 0 and eva_served:
					broken_pan -= 1
					repaired_panels += 1
					outside_worked_count += 1
				elif eva_served:
					outside_worked_count += 1
			"REPAIR_REC":
				if rec_broken and not repaired_recycler:
					repaired_recycler = true
					rec_broken = false
			"REPAIR_PANEL":
				if broken_pan > 0 and eva_served:
					broken_pan -= 1
					repaired_panels += 1
				if eva_served:
					outside_worked_count += 1
			"CLEAN":
				if eva_served:
					clean_worked = true
			"REGOLITH":
				if eva_served:
					var reg_gain: float = float(_c.v("REGOLITH_G_CM2_PER_JOB")) if _c != null else 2.5
					shelter_g += reg_gain
					shelter_added += reg_gain
					outside_worked_count += 1
			"SCIENCE":
				if eva_served and sci_served:
					sci_pts += 1
					science_added += 1
					outside_worked_count += 1
			"FARM":
				if gh_alive:
					farm_worked = true
			"REST":
				pass

	var dust_max: float = float(_c.v("DUST_MAX_LOSS")) if _c != null else 0.4
	var dust_per_job: float = float(_c.v("DUST_PER_OUTSIDE_JOB")) if _c != null else 0.02
	var dust_increase: float = dust_per_job * float(outside_worked_count)
	var dust_before_clean: float = minf(dust_max, cur_dust + dust_increase)
	var new_dust: float = dust_before_clean
	if clean_worked:
		new_dust = 0.0

	var dust_high: bool = (dust_before_clean >= dust_max) and not clean_worked

	return {
		"dust": new_dust,
		"dust_delta": new_dust - cur_dust,
		"dust_high": dust_high,
		"clean_worked": clean_worked,
		"recycler_broken": rec_broken,
		"repaired_recycler": repaired_recycler,
		"broken_panels": broken_pan,
		"repaired_panels": repaired_panels,
		"shelter_g_cm2": shelter_g,
		"shelter_delta": shelter_added,
		"science_points": sci_pts,
		"science_delta": science_added,
		"farm_worked": farm_worked,
		"worked_outside": worked_outside_flags,
		"jobs_no_power": jobs_no_power
	}

