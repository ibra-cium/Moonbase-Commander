extends SceneTree

const SimConstantsScript := preload("res://sim/sim_constants.gd")
const SimMissionsScript := preload("res://sim/sim_missions.gd")
const SimMissionScript := preload("res://sim/sim_mission.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimPlanScript := preload("res://sim/sim_plan.gd")

func _initialize() -> void:
	var constants_text := FileAccess.get_file_as_string("res://data/constants.json")
	var base_sim: SimConstants = SimConstantsScript.from_json(constants_text)
	var missions := SimMissionsScript.new(base_sim)

	var dir := DirAccess.open("res://tests/scenarios")
	if dir == null:
		print("ERROR: Could not open res://tests/scenarios")
		quit(1)
		return

	var scenario_files: Array[String] = []
	for file_name in dir.get_files():
		if file_name.ends_with(".json"):
			scenario_files.append(file_name)
	scenario_files.sort()

	if scenario_files.is_empty():
		print("ERROR: No scenario files found in res://tests/scenarios")
		quit(1)
		return

	print("%-24s %-16s %4s %6s  %-20s %s" % ["ID", "OUTCOME", "DAY", "STARS", "ROOT", "OK"])

	var all_passed: bool = true
	var count_passed: int = 0
	var count_total: int = 0

	for file_name in scenario_files:
		count_total += 1
		var file_path := "res://tests/scenarios/" + file_name
		var content := FileAccess.get_file_as_string(file_path)
		var json_result: Variant = JSON.parse_string(content)
		if not (json_result is Dictionary):
			print("ERROR: Failed to parse %s" % file_name)
			all_passed = false
			continue

		var data: Dictionary = json_result
		var sc_id: String = str(data.get("id", file_name.get_basename()))
		var mission_id: String = str(data.get("mission", ""))
		var cargo_dict: Dictionary = data.get("cargo", {})
		var seed_val: int = int(data.get("seed", 1))
		var rule: String = str(data.get("rule", "REST"))
		var sc_force: Dictionary = data.get("force", {})
		var expect: Dictionary = data.get("expect", {})

		var sim: SimConstants = missions.get_sim_constants(mission_id) if mission_id != "" else base_sim
		var force: Dictionary = missions.get_force(mission_id) if mission_id != "" else {}
		for k in sc_force.keys():
			force[k] = sc_force[k]

		var exp_outcome: String = str(expect.get("outcome", ""))
		var exp_day: int = int(expect.get("end_day", expect.get("day", 0)))
		var exp_stars: int = int(expect.get("stars", 0))
		var exp_root: String = str(expect.get("root", ""))
		var check_ever_tired: bool = expect.has("ever_tired")
		var exp_ever_tired: bool = bool(expect.get("ever_tired", false))

		# Check cargo validity first
		var cargo := SimCargoScript.new(sim)
		cargo.load_dict(cargo_dict)

		var actual_outcome: String = ""
		var actual_day: int = 0
		var actual_stars: int = 0
		var actual_root: String = ""
		var actual_ever_tired: bool = false

		if not cargo.is_valid():
			actual_outcome = "INVALID"
			actual_day = 0
			actual_stars = 0
			actual_root = "CARGO_INVALID"
		else:
			var mission := SimMissionScript.new(sim, cargo, seed_val, force)
			var last_report = null
			var mission_days: int = int(sim.v("MISSION_DAYS"))

			for d in range(1, mission_days + 1):
				if mission.ended:
					break

				var state: Dictionary = {}
				if last_report != null:
					state = {
						"day": mission.day,
						"recycler_broken": last_report.recycler_broken,
						"broken_panels": last_report.broken_panels,
						"dust": last_report.dust,
						"shelter_g_cm2": last_report.shelter_g_cm2,
						"greenhouse_alive": last_report.greenhouse_alive,
						"greenhouse_area": mission.greenhouse.area
					}
				else:
					state = {
						"day": mission.day,
						"recycler_broken": mission.life.recycler_broken,
						"broken_panels": mission.power.broken_panels,
						"dust": mission.dust,
						"shelter_g_cm2": mission.shelter_g_cm2,
						"greenhouse_alive": mission.greenhouse.alive,
						"greenhouse_area": mission.greenhouse.area
					}

				var plan := _build_plan(rule, mission.day, state, sim)
				last_report = mission.step_day(plan)

			if mission.result != null:
				actual_outcome = mission.result.outcome
				actual_day = mission.result.end_day
				actual_stars = mission.result.stars
				actual_root = mission.result.root_cause_code
				actual_ever_tired = bool(mission.result.stats.get("ever_tired", false))

		var match_outcome: bool = (actual_outcome == exp_outcome)
		var match_day: bool = (actual_day == exp_day)
		var match_stars: bool = (actual_stars == exp_stars)
		var match_root: bool = (actual_root == exp_root)
		var match_tired: bool = (not check_ever_tired) or (actual_ever_tired == exp_ever_tired)

		var ok: bool = match_outcome and match_day and match_stars and match_root and match_tired
		if ok:
			count_passed += 1
		else:
			all_passed = false

		var status_str: String = "✓" if ok else "FAIL"
		print("%-24s %-16s %4d %6d  %-20s %s" % [
			sc_id,
			actual_outcome,
			actual_day,
			actual_stars,
			actual_root,
			status_str
		])

		if not ok:
			print("   Mismatch details for %s:" % sc_id)
			if not match_outcome:
				print("     Outcome: got %s, expected %s" % [actual_outcome, exp_outcome])
			if not match_day:
				print("     Day:     got %d, expected %d" % [actual_day, exp_day])
			if not match_stars:
				print("     Stars:   got %d, expected %d" % [actual_stars, exp_stars])
			if not match_root:
				print("     Root:    got %s, expected %s" % [actual_root, exp_root])
			if not match_tired:
				print("     Tired:   got %s, expected %s" % [str(actual_ever_tired), str(exp_ever_tired)])

	print("")
	print("Scenarios passed: %d / %d" % [count_passed, count_total])
	quit(0 if all_passed else 1)

func _build_plan(rule: String, current_day: int, state: Dictionary, sim: SimConstants) -> SimPlan:
	var sunset_day: int = int(sim.v("SUNSET_DAY")) if sim != null else 15
	var is_day: bool = (current_day < sunset_day)
	var plan := SimPlanScript.new()

	match rule:
		"NOFIX":
			# NOFIX: everyone REST every day.
			for i in range(4):
				plan.set_job(i, "REST")
			plan.greenhouse_lights_on = false
			plan.science_gear_on = false

		"REST":
			# REST: crew 0 REPAIR when something is broken, everyone else REST. Lights off, science gear off.
			var broken_rec: bool = bool(state.get("recycler_broken", false))
			var broken_pan: int = int(state.get("broken_panels", 0))
			if broken_rec or broken_pan > 0:
				plan.set_job(0, "REPAIR")
			else:
				plan.set_job(0, "REST")
			for i in range(1, 4):
				plan.set_job(i, "REST")
			plan.greenhouse_lights_on = false
			plan.science_gear_on = false

		"SMART":
			# SMART: crew 0 REPAIR if broken, else CLEAN if dust > 0.2, else REST
			# crew 1 REGOLITH until shelter ≥ 15 g/cm², then SCIENCE by day, REST at night
			# crew 2 SCIENCE by day, REST at night
			# crew 3 FARM if the greenhouse is alive, else SCIENCE by day
			# greenhouse lights always on · science gear on by day only.
			var broken_rec: bool = bool(state.get("recycler_broken", false))
			var broken_pan: int = int(state.get("broken_panels", 0))
			var dust: float = float(state.get("dust", 0.0))
			var shelter_g: float = float(state.get("shelter_g_cm2", 0.0))
			var gh_alive: bool = bool(state.get("greenhouse_alive", false))
			var gh_area: float = float(state.get("greenhouse_area", 0.0))

			# crew 0
			if broken_rec or broken_pan > 0:
				plan.set_job(0, "REPAIR")
			elif dust > 0.2:
				plan.set_job(0, "CLEAN")
			else:
				plan.set_job(0, "REST")

			# crew 1
			if shelter_g < 15.0:
				plan.set_job(1, "REGOLITH")
			elif is_day:
				plan.set_job(1, "SCIENCE")
			else:
				plan.set_job(1, "REST")

			# crew 2
			if is_day:
				plan.set_job(2, "SCIENCE")
			else:
				plan.set_job(2, "REST")

			# crew 3
			if gh_alive and gh_area > 0.0:
				plan.set_job(3, "FARM")
			elif is_day:
				plan.set_job(3, "SCIENCE")
			else:
				plan.set_job(3, "REST")

			plan.greenhouse_lights_on = true
			plan.science_gear_on = is_day

			# Rotate 1 rest day every 4 days per crew member (except crew 0 when repairing).
			for i in range(4):
				if (current_day + i) % 4 == 0:
					if i == 0 and (broken_rec or broken_pan > 0):
						continue
					plan.set_job(i, "REST")

		"ALLWORK":
			# ALLWORK: everyone SCIENCE every day, crew 0 REPAIR when broken.
			var broken_rec: bool = bool(state.get("recycler_broken", false))
			var broken_pan: int = int(state.get("broken_panels", 0))
			for i in range(4):
				plan.set_job(i, "SCIENCE")
			if broken_rec or broken_pan > 0:
				plan.set_job(0, "REPAIR")
			plan.greenhouse_lights_on = false
			plan.science_gear_on = true

		_:
			for i in range(4):
				plan.set_job(i, "REST")
			plan.greenhouse_lights_on = false
			plan.science_gear_on = false

	return plan
