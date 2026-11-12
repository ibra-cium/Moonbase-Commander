extends "res://tests/test_case.gd"

const AstronautScript := preload("res://world/astronaut.gd")
const CrewScript := preload("res://world/crew.gd")
const BaseStationScript := preload("res://world/base.gd")

func test_astronaut_geometry_and_suit_colors() -> void:
	var astro_scene: PackedScene = load("res://world/Astronaut.tscn")
	assert_true(astro_scene != null, "Astronaut.tscn should load")
	if astro_scene == null:
		return

	var astro = astro_scene.instantiate() as Astronaut
	assert_true(astro != null, "Astronaut should instantiate")
	astro._ready()

	# Verify 1.0m height: helmet center at Y=0.84 with radius 0.16 reaches Y=1.00m
	var helmet_node = astro.get_node_or_null("BodyPivot/Helmet") as MeshInstance3D
	assert_true(helmet_node != null, "Astronaut must have Helmet MeshInstance3D")
	if helmet_node != null:
		var sphere = helmet_node.mesh as SphereMesh
		assert_true(sphere != null, "Helmet mesh must be SphereMesh")
		if sphere != null:
			var top_y: float = helmet_node.position.y + sphere.radius
			assert_true(is_equal_approx(top_y, 1.0), "Astronaut top of helmet must be at 1.0m (got %f)" % top_y)

	# Suit colours per ART_DIRECTION §1: orange, purple, pink, brown
	# NEVER blue, green or yellow
	var expected_colors: Array[Color] = [
		Color("#F28C28"), # Crew 0: orange
		Color("#8B5CF6"), # Crew 1: purple
		Color("#EC6FA8"), # Crew 2: pink
		Color("#A0673A")  # Crew 3: brown
	]

	for i in range(4):
		astro.set_crew_index(i)
		var c := astro.get_suit_color()
		assert_eq(c, expected_colors[i], "Crew %d should have correct suit color" % i)

		# Verify none are blue, green, or yellow
		assert_true(c != Color("#3D8BD9"), "Suit color must not be water blue")
		assert_true(c != Color("#44B35A"), "Suit color must not be oxygen green")
		assert_true(c != Color("#F2C14E"), "Suit color must not be power yellow")

	# Verify required nodes
	assert_true(astro.has_node("BodyPivot"), "Astronaut must have BodyPivot")
	assert_true(astro.has_node("BodyPivot/Capsule"), "Astronaut must have Capsule")
	assert_true(astro.has_node("BodyPivot/Helmet"), "Astronaut must have Helmet")
	assert_true(astro.has_node("BodyPivot/Helmet/Visor"), "Astronaut must have Visor")
	assert_true(astro.has_node("BodyPivot/Backpack"), "Astronaut must have Backpack")
	assert_true(astro.has_node("BodyPivot/SickIcon"), "Astronaut must have SickIcon")

	astro.free()

func test_astronaut_states() -> void:
	var astro_scene: PackedScene = load("res://world/Astronaut.tscn")
	var astro = astro_scene.instantiate() as Astronaut
	astro._ready()

	# State WORKING
	astro.set_state(AstronautScript.State.WORKING)
	assert_true(astro.visible, "Working astronaut should be visible")
	assert_true(not astro.is_sick_icon_visible(), "Working astronaut sick icon should be hidden")

	# State SICK
	astro.set_state(AstronautScript.State.SICK)
	assert_true(astro.visible, "Sick astronaut should be visible")
	assert_true(astro.is_sick_icon_visible(), "Sick astronaut sick icon should be visible")

	# State RESTING
	astro.set_state(AstronautScript.State.RESTING)
	assert_true(not astro.visible, "Resting astronaut should be hidden inside habitat")

	# State SHELTERED
	astro.set_state(AstronautScript.State.SHELTERED)
	assert_true(not astro.visible, "Sheltered astronaut should be hidden inside shelter")

	# State EVACUATING
	astro.set_state(AstronautScript.State.EVACUATING)
	assert_true(astro.visible, "Evacuating astronaut should be visible")

	astro.free()

func test_base_job_slots_and_shelter_door_light() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base = base_scene.instantiate() as BaseStation
	base._ready()

	var required_job_slots := [
		"Slot_Job_Panels",
		"Slot_Job_LifeSupport",
		"Slot_Job_Greenhouse",
		"Slot_Job_DigSite",
		"Slot_Job_Drill",
		"Slot_Job_Habitat",
		"Slot_Job_Shelter",
		"Slot_Job_Lander"
	]
	for slot_name in required_job_slots:
		assert_true(base.has_node("Slots/" + slot_name), "Base must contain job slot: " + slot_name)

	# Verify job spot queries
	var pos_rest := base.get_job_spot_position("REST")
	var pos_clean := base.get_job_spot_position("CLEAN")
	var pos_farm := base.get_job_spot_position("FARM")
	var pos_rego := base.get_job_spot_position("REGOLITH")
	var pos_sci := base.get_job_spot_position("SCIENCE")
	var pos_shelter := base.get_job_spot_position("SHELTER")
	var pos_lander := base.get_job_spot_position("LANDER")

	assert_true(pos_rest != Vector3.ZERO, "REST spot position should be non-zero")
	assert_true(pos_clean != Vector3.ZERO, "CLEAN spot position should be non-zero")
	assert_true(pos_farm != Vector3.ZERO, "FARM spot position should be non-zero")
	assert_true(pos_rego != Vector3.ZERO, "REGOLITH spot position should be non-zero")
	assert_true(pos_sci != Vector3.ZERO, "SCIENCE spot position should be non-zero")
	assert_true(pos_shelter != Vector3.ZERO, "SHELTER spot position should be non-zero")
	assert_true(pos_lander != Vector3.ZERO, "LANDER spot position should be non-zero")

	# Verify shelter door light
	assert_true(not base.is_shelter_door_light_on(), "Shelter door light should initially be off")
	base.set_shelter_door_light(true)
	assert_true(base.is_shelter_door_light_on(), "Shelter door light should turn on")
	base.set_shelter_door_light(false)
	assert_true(not base.is_shelter_door_light_on(), "Shelter door light should turn off")

	# Verify Rover and Trailer scaling (scaled ~3.5x to match 1.0m astronaut ratio)
	var rover = base.get_node_or_null("StaticBuildings/Rover") as Node3D
	assert_true(rover != null, "Base must have Rover")
	if rover != null:
		assert_true(is_equal_approx(rover.scale.x, 3.5), "Rover scale.x should be 3.5")
	var trailer = base.get_node_or_null("StaticBuildings/Trailer") as Node3D
	assert_true(trailer != null, "Base must have Trailer")
	if trailer != null:
		assert_true(is_equal_approx(trailer.scale.x, 3.5), "Trailer scale.x should be 3.5")

	base.free()

func test_crew_setup_and_suit_colors() -> void:
	var crew_scene: PackedScene = load("res://world/Crew.tscn")
	assert_true(crew_scene != null, "Crew.tscn should load")

	var crew = crew_scene.instantiate() as Crew
	assert_true(crew != null, "Crew should instantiate")
	crew._ready()

	assert_eq(crew.get_astronaut_count(), 4, "Crew should have 4 astronauts")

	for i in range(4):
		var astro := crew.get_astronaut(i)
		assert_true(astro != null, "Astronaut %d should exist" % i)
		assert_eq(astro.crew_index, i, "Astronaut %d should have crew_index %d" % [i, i])

	crew.free()

func test_crew_job_dispatch() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base = base_scene.instantiate() as BaseStation
	base._ready()

	var crew_scene: PackedScene = load("res://world/Crew.tscn")
	var crew = crew_scene.instantiate() as Crew
	base.add_child(crew)
	crew._ready()

	# Simulate report with different jobs: REPAIR, REGOLITH, SCIENCE, FARM
	var mock_report := {
		"day": 1,
		"recycler_broken": false,
		"storm_dose_msv": 0.0,
		"events": [],
		"crew_reports": [
			{"job": "CLEAN", "sick": false},
			{"job": "REGOLITH", "sick": false},
			{"job": "SCIENCE", "sick": false},
			{"job": "FARM", "sick": false}
		]
	}

	crew.apply_report(mock_report)

	for i in range(4):
		var astro := crew.get_astronaut(i)
		assert_true(astro.visible, "Working crew %d should be visible" % i)
		assert_eq(int(astro.current_state), int(AstronautScript.State.WORKING), "Crew %d should be WORKING" % i)

	assert_eq(crew.get_astronaut_job(0), "CLEAN", "Crew 0 job should be CLEAN")
	assert_eq(crew.get_astronaut_job(1), "REGOLITH", "Crew 1 job should be REGOLITH")
	assert_eq(crew.get_astronaut_job(2), "SCIENCE", "Crew 2 job should be SCIENCE")
	assert_eq(crew.get_astronaut_job(3), "FARM", "Crew 3 job should be FARM")

	base.free()

func test_crew_storm_day_shelter() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base = base_scene.instantiate() as BaseStation
	base._ready()

	var crew_scene: PackedScene = load("res://world/Crew.tscn")
	var crew = crew_scene.instantiate() as Crew
	base.add_child(crew)
	crew._ready()

	# Storm day report
	var storm_report := {
		"day": 12,
		"storm_dose_msv": 150.0,
		"recycler_broken": false,
		"events": [{"code": "STORM_WARNING"}],
		"crew_reports": [
			{"job": "REST", "sick": false},
			{"job": "REST", "sick": false},
			{"job": "REST", "sick": false},
			{"job": "REST", "sick": false}
		]
	}

	crew.apply_report(storm_report)

	# Verify shelter door light is on
	assert_true(base.is_shelter_door_light_on(), "Shelter door light must be ON during storm")

	# Verify all crew are sheltered
	for i in range(4):
		var astro := crew.get_astronaut(i)
		assert_eq(int(astro.current_state), int(AstronautScript.State.SHELTERED), "Crew %d must be SHELTERED" % i)
		assert_true(not astro.visible, "Sheltered crew %d must be hidden inside shelter" % i)

	base.free()

func test_crew_sick_astronaut() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base = base_scene.instantiate() as BaseStation
	base._ready()

	var crew_scene: PackedScene = load("res://world/Crew.tscn")
	var crew = crew_scene.instantiate() as Crew
	base.add_child(crew)
	crew._ready()

	# Crew 1 is sick
	var sick_report := {
		"day": 5,
		"storm_dose_msv": 0.0,
		"recycler_broken": false,
		"events": [],
		"crew_reports": [
			{"job": "SCIENCE", "sick": false},
			{"job": "REST", "sick": true},
			{"job": "SCIENCE", "sick": false},
			{"job": "REST", "sick": false}
		]
	}

	crew.apply_report(sick_report)

	# Crew 1 should be SICK, visible, with red sick icon
	var sick_astro := crew.get_astronaut(1)
	assert_eq(int(sick_astro.current_state), int(AstronautScript.State.SICK), "Crew 1 should be in SICK state")
	assert_true(sick_astro.visible, "Sick crew should be visible at habitat door")
	assert_true(sick_astro.is_sick_icon_visible(), "Sick crew should display red sick icon")

	# Crew 3 is healthy REST -> should be hidden inside habitat
	var resting_astro := crew.get_astronaut(3)
	assert_eq(int(resting_astro.current_state), int(AstronautScript.State.RESTING), "Crew 3 should be in RESTING state")
	assert_true(not resting_astro.visible, "Healthy resting crew should be hidden inside habitat")

	base.free()

func test_crew_evacuation() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base = base_scene.instantiate() as BaseStation
	base._ready()

	var crew_scene: PackedScene = load("res://world/Crew.tscn")
	var crew = crew_scene.instantiate() as Crew
	base.add_child(crew)
	crew._ready()

	crew.evacuate()

	for i in range(4):
		var astro := crew.get_astronaut(i)
		assert_eq(int(astro.current_state), int(AstronautScript.State.EVACUATING), "Crew %d should be EVACUATING" % i)
		assert_true(astro.visible, "Evacuating crew %d should be visible" % i)

	base.free()

func test_crew_assign_job_immediate_hop() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base = base_scene.instantiate() as BaseStation
	base._ready()

	var crew_scene: PackedScene = load("res://world/Crew.tscn")
	var crew = crew_scene.instantiate() as Crew
	base.add_child(crew)
	crew._ready()

	# Crew 0 initially RESTING and hidden
	var astro0 := crew.get_astronaut(0)
	assert_true(not astro0.visible, "Astronaut 0 initially resting inside habitat")

	# Assign Crew 0 to FARM -> immediate walk/hop to greenhouse
	crew.assign_job(0, "FARM")
	assert_true(astro0.visible, "Astronaut 0 should be visible when assigned to FARM")
	assert_eq(int(astro0.current_state), int(AstronautScript.State.WORKING), "Astronaut 0 should be WORKING")
	assert_eq(crew.get_astronaut_job(0), "FARM", "Astronaut 0 job should be FARM")

	# Assign Crew 0 to REST -> hops back and rests inside habitat
	crew.assign_job(0, "REST")
	assert_eq(int(astro0.current_state), int(AstronautScript.State.RESTING), "Astronaut 0 should return to RESTING")
	assert_true(not astro0.visible, "Astronaut 0 should be hidden inside habitat after returning to REST")

	base.free()

func test_crew_recall_to_rest() -> void:
	var base_scene: PackedScene = load("res://world/Base.tscn")
	var base = base_scene.instantiate() as BaseStation
	base._ready()

	var crew_scene: PackedScene = load("res://world/Crew.tscn")
	var crew = crew_scene.instantiate() as Crew
	base.add_child(crew)
	crew._ready()

	# Assign two crew to work
	crew.assign_job(0, "FARM")
	crew.assign_job(1, "SCIENCE")
	assert_true(crew.get_astronaut(0).visible, "Crew 0 working at farm")
	assert_true(crew.get_astronaut(1).visible, "Crew 1 working at science")

	# Recall to rest at end of day
	crew.recall_to_rest(false)
	assert_eq(int(crew.get_astronaut(0).current_state), int(AstronautScript.State.RESTING), "Crew 0 should be RESTING")
	assert_true(not crew.get_astronaut(0).visible, "Crew 0 should be hidden inside habitat")
	assert_eq(int(crew.get_astronaut(1).current_state), int(AstronautScript.State.RESTING), "Crew 1 should be RESTING")
	assert_true(not crew.get_astronaut(1).visible, "Crew 1 should be hidden inside habitat")

	base.free()

func _make_m6_test_cargo(c: RefCounted):
	var sim_cargo_script := load("res://sim/sim_cargo.gd")
	var cargo = sim_cargo_script.new(c)
	var text := FileAccess.get_file_as_string("res://tests/scenarios/S10_overwork.json")
	var parsed: Variant = JSON.parse_string(text)
	assert_true(parsed is Dictionary and parsed.has("cargo"), "S10_overwork.json should load cargo template")
	if parsed is Dictionary and parsed.get("cargo") is Dictionary:
		var cargo_dict: Dictionary = parsed["cargo"]
		for k in cargo_dict:
			cargo.set_count(str(k), int(cargo_dict[k]))
	return cargo

func test_crew_energy_work_rest_overwork_and_co2() -> void:
	var sim_crew_script := load("res://sim/sim_crew.gd")
	var sim_plan_script := load("res://sim/sim_plan.gd")
	var sim_log_script := load("res://sim/sim_log.gd")
	var sim_mission_script := load("res://sim/sim_mission.gd")

	var max_energy: int = int(Constants.v("CREW_ENERGY_MAX"))
	var sick_days_const: int = int(Constants.v("SICK_REST_DAYS"))
	assert_eq(max_energy, 3, "CREW_ENERGY_MAX should be 3")

	var c := Constants.sim
	assert_true(c != null, "Constants.sim must be loaded")

	# Direct SimCrew checks: start full, REST refills, storm refills, CO2 untouched, sick crew not re-sickened
	var sim_crew = sim_crew_script.new(c)
	assert_eq(sim_crew.get_max_energy(), max_energy, "SimCrew.get_max_energy matches CREW_ENERGY_MAX")
	for i in range(4):
		assert_eq(sim_crew.members[i].energy, max_energy, "Crew %d starts with max energy" % i)

	# 3 consecutive work days on crew 0 drain energy 3 -> 2 -> 1 -> 0 without sickness
	for d in range(max_energy):
		var step_res: Dictionary = sim_crew.apply_sickness(false, ["SCIENCE", "REST", "REST", "REST"])
		assert_true((step_res["newly_tired"] as Array).is_empty(), "No overwork sickness while energy > 0 (step %d)" % d)
		assert_eq(sim_crew.members[0].energy, max_energy - (d + 1), "Crew 0 loses 1 energy on work step %d" % d)
		assert_false(bool(sim_crew.members[0].to_dict()["sick"]), "Crew 0 not sick yet after %d work days" % (d + 1))

	# Resting at 0 energy refills back to max_energy without sickness
	sim_crew.apply_sickness(false, ["REST", "REST", "REST", "REST"])
	assert_eq(sim_crew.members[0].energy, max_energy, "REST refills energy back to max")
	assert_false(sim_crew.ever_tired, "Resting in time avoids ever_tired")

	# Storm day (all forced REST) also refills tired crew to max_energy
	sim_crew.members[1].energy = 1
	sim_crew.apply_sickness(false, ["REST", "REST", "REST", "REST"])
	assert_eq(sim_crew.members[1].energy, max_energy, "Forced storm REST refills energy to max")

	# CO2 sickness still works independently and does not set ever_tired
	var co2_res: Dictionary = sim_crew.apply_sickness(true, ["REST", "REST", "REST", "REST"])
	assert_true(not (co2_res["newly_sick"] as Array).is_empty(), "High CO2 makes crew sick")
	assert_false(sim_crew.ever_tired, "CO2 sickness does not set ever_tired")

	# Already-sick crew are NOT made sick again by CO2 or work job, and REST ticks down recovery
	var already_sick_idx: int = int((co2_res["newly_sick"] as Array)[0])
	var before_days: int = sim_crew.members[already_sick_idx].sick_days
	var repeat_res: Dictionary = sim_crew.apply_sickness(false, ["SCIENCE", "SCIENCE", "SCIENCE", "SCIENCE"])
	assert_false(already_sick_idx in (repeat_res["newly_sick"] as Array), "Already-sick crew not re-sickened")
	assert_false(already_sick_idx in (repeat_res["newly_tired"] as Array), "Already-sick crew not overworked again")
	sim_crew.apply_sickness(false, ["REST", "REST", "REST", "REST"])
	assert_eq(sim_crew.members[already_sick_idx].sick_days, before_days - 1, "Already-sick crew counts down recovery on REST")

	# Full SimMission check: Leo (crew index 2) works SCIENCE for 4 consecutive days while others rotate REST
	var cargo = _make_m6_test_cargo(c)
	var mission = sim_mission_script.new(c, cargo, 7, {"storm_day": 99, "recycler_day": 99, "meteoroid_day": 0})
	var expected_energy_seq: Array[int] = [2, 1, 0]
	for day_idx in range(3):
		var plan = sim_plan_script.new([
			"REST" if day_idx == 0 else "CLEAN",
			"CLEAN" if day_idx == 0 else "REST",
			"SCIENCE",
			"REST"
		], false, true)
		var prev_sci: int = mission.science_points
		var rep = mission.step_day(plan)
		assert_eq(mission.science_points, prev_sci + 1, "Leo completes SCIENCE on day %d" % (day_idx + 1))
		assert_eq(int(rep.crew_reports[2]["energy"]), expected_energy_seq[day_idx], "Leo energy after day %d" % (day_idx + 1))
		assert_false(bool(rep.crew_reports[2]["sick"]), "Leo healthy through day %d" % (day_idx + 1))
		assert_false(rep.ever_tired, "ever_tired remains false before day 4")

	# Day 4: Leo works SCIENCE at energy == 0 -> completes day's job FIRST, then gets sick for SICK_REST_DAYS
	var day4_plan = sim_plan_script.new(["REST", "REST", "SCIENCE", "REST"], false, true)
	var sci_before_d4: int = mission.science_points
	var d4_rep = mission.step_day(day4_plan)
	assert_eq(mission.science_points, sci_before_d4 + 1, "Day 4 SCIENCE job finishes before overwork sickness triggers")
	assert_true(bool(d4_rep.crew_reports[2]["sick"]), "Leo becomes sick after working at 0 energy")
	assert_eq(mission.crew.members[2].sick_days, sick_days_const, "Leo sick_days equals SICK_REST_DAYS")
	assert_true(mission.crew.ever_sick, "mission.crew.ever_sick is true after overwork")
	assert_true(mission.crew.ever_tired, "mission.crew.ever_tired is true after overwork")
	assert_true(d4_rep.ever_tired, "SimDayReport.ever_tired is true")
	assert_false(bool(d4_rep.crew_reports[0]["sick"]), "Rafi did not get sick")
	assert_false(bool(d4_rep.crew_reports[1]["sick"]), "Mira did not get sick")
	assert_false(bool(d4_rep.crew_reports[3]["sick"]), "Nadia did not get sick")

	var found_tired_log: bool = false
	for entry in mission.log.entries:
		if entry.code == "CREW_TIRED":
			found_tired_log = true
			assert_eq(entry.caused_by, -1, "CREW_TIRED log caused_by is -1")
			assert_eq(str(entry.values.get("cause", "")), sim_log_script.CAUSE_OVERWORK, "CREW_TIRED cause is OVERWORK")
			assert_eq(str(entry.values.get("name", "")), "Leo", "CREW_TIRED names Leo")
			assert_true(2 in (entry.values.get("crew_indices", []) as Array), "CREW_TIRED lists crew index 2")
	assert_true(found_tired_log, "SimLog records CREW_TIRED entry on overwork")

	# Day 5 & 6: Leo is forced to REST -> energy refills to max and recovers after SICK_REST_DAYS
	var d5_plan = sim_plan_script.new(["REST", "REST", "REST", "REST"])
	var d5_rep = mission.step_day(d5_plan)
	assert_eq(int(d5_rep.crew_reports[2]["energy"]), max_energy, "Sick forced rest refills Leo energy to max")
	assert_true(bool(d5_rep.crew_reports[2]["sick"]), "Leo still resting on sick day 1")

	var d6_plan = sim_plan_script.new(["REST", "REST", "REST", "REST"])
	var d6_rep = mission.step_day(d6_plan)
	assert_eq(int(d6_rep.crew_reports[2]["energy"]), max_energy, "Leo retains max energy on recovery")
	assert_false(bool(d6_rep.crew_reports[2]["sick"]), "Leo recovers after SICK_REST_DAYS")

func test_crew_energy_debrief_root_causes() -> void:
	var sim_log_script := load("res://sim/sim_log.gd")
	var sim_debrief_script := load("res://sim/sim_debrief.gd")
	var debrief_scene: PackedScene = load("res://ui/DebriefScreen.tscn")

	# Direct SimDebrief check for overwork root cause (ever_sick => 1 star under GAME_RULES §9.2)
	var empty_log = sim_log_script.new()
	var sim_debrief = sim_debrief_script.new(Constants.sim)
	var sci_goal: int = int(Constants.v("SCIENCE_GOAL_POINTS"))
	var root_overwork: Dictionary = sim_debrief.determine_root_cause(
		"SURVIVED",
		empty_log,
		{
			"ever_sick": true,
			"ever_tired": true,
			"co2_sick": false,
			"tired_crew_indices": [2],
			"tired_crew_name": "Leo",
			"science_points": sci_goal
		},
		null
	)
	assert_eq(str(root_overwork.get("code", "")), "ROOT_SUCCESS", "Overwork win returns ROOT_SUCCESS")
	var vals_overwork: Dictionary = root_overwork.get("values", {})
	assert_eq(int(vals_overwork.get("stars", 0)), 1, "Any ever_sick win scores 1 star per calculate_stars")
	assert_true(bool(vals_overwork.get("ever_tired", false)), "SimDebrief sets ever_tired flag")
	assert_eq(str(vals_overwork.get("name", "")), "Leo", "SimDebrief includes Leo name")
	assert_true(str(root_overwork.get("text", "")).contains("working too hard"), "SimDebrief fallback text cites working too hard")

	var debrief_2: DebriefScreen = debrief_scene.instantiate() as DebriefScreen
	var vals_2 := vals_overwork.duplicate(true)
	vals_2["stars"] = 2
	debrief_2.show_result({
		"outcome": "SURVIVED",
		"end_day": int(Constants.v("MISSION_DAYS")),
		"total_days": int(Constants.v("MISSION_DAYS")),
		"stars": 2,
		"root_cause_code": "ROOT_SUCCESS",
		"root_cause_values": vals_2,
		"root_cause_text": str(root_overwork.get("text", "")),
		"cause_chain": [{
			"day": 4,
			"code": "CREW_TIRED",
			"values": {"crew_indices": [2], "name": "Leo", "cause": "OVERWORK"}
		}]
	})
	assert_true(debrief_2.reason_label.text.contains("Leo"), "ROOT_SUCCESS_2_TIRED shows overworked crew name")
	assert_true(debrief_2.reason_label.text.contains("Rest"), "ROOT_SUCCESS_2_TIRED tells player to give Rest")
	debrief_2.free()

	# 1-star result with CREW_TIRED formats ROOT_SUCCESS_1 cleanly
	var debrief_1: DebriefScreen = debrief_scene.instantiate() as DebriefScreen
	debrief_1.show_result({
		"outcome": "SURVIVED",
		"end_day": int(Constants.v("MISSION_DAYS")),
		"total_days": int(Constants.v("MISSION_DAYS")),
		"stars": 1,
		"root_cause_code": "ROOT_SUCCESS",
		"root_cause_values": {
			"stars": 1,
			"ever_sick": true,
			"ever_tired": true,
			"co2_sick": false,
			"tired_crew_indices": [2],
			"tired_crew_name": "Leo",
			"science_points": 4,
			"science_goal": sci_goal
		},
		"cause_chain": []
	})
	assert_true(debrief_1.reason_label.text.contains("crew got sick"), "ROOT_SUCCESS_1 mentions crew got sick")
	assert_true(debrief_1.reason_label.text.contains("4/%d" % sci_goal), "ROOT_SUCCESS_1 formats science ratio")
	debrief_1.free()

func test_crew_energy_ui_voice_hints_and_i18n_fallback() -> void:
	var speech_bubble_script := load("res://world/speech_bubble.gd")
	var crew_card_scene: PackedScene = load("res://ui/CrewCard.tscn")
	var day_hud_scene: PackedScene = load("res://ui/DayHud.tscn")
	var tutorial_scene: PackedScene = load("res://ui/TutorialOverlay.tscn")
	var sim_plan_script := load("res://sim/sim_plan.gd")
	var sim_mission_script := load("res://sim/sim_mission.gd")

	var max_energy: int = int(Constants.v("CREW_ENERGY_MAX"))
	var prev_locale := TranslationServer.get_locale()
	Settings.sound_on = true
	Audio.set_unlocked_for_test(true)
	Audio.stop_all()

	# 1. CrewCard pips, tired badge, non-REST still selectable + red warning + ui_error chime
	var card: CrewCard = crew_card_scene.instantiate() as CrewCard
	card._ready()
	card.setup(2) # Leo
	card.update_availability(false, false, 0, false, false)

	card.set_crew_data(0.0, false, 0, max_energy)
	assert_eq(card.get_energy(), max_energy, "CrewCard reports full energy")
	assert_eq(card.energy_pips.size(), max_energy, "CrewCard displays CREW_ENERGY_MAX pips")
	for pip in card.energy_pips:
		assert_eq(pip.color, card.SUIT_COLORS[2], "Full pips use crew suit color")
	assert_false(card.tired_label.visible, "Tired label hidden at max energy")
	assert_false(card.is_tired_warning(), "No tired warning at max energy")

	card.set_crew_data(0.0, false, 0, 1)
	assert_eq(card.energy_pips[0].color, card.SUIT_COLORS[2], "Pip 0 filled at 1 energy")
	assert_eq(card.energy_pips[1].color, card.PIP_EMPTY_COLOR, "Pip 1 empty grey at 1 energy")
	assert_eq(card.energy_pips[2].color, card.PIP_EMPTY_COLOR, "Pip 2 empty grey at 1 energy")
	assert_true(card._picker_buttons["REST"]["reason_lbl"].visible, "REST shows refill note below max energy")
	assert_false(card._picker_buttons["SCIENCE"]["reason_lbl"].visible, "SCIENCE shows no warning at 1 energy")

	card.set_crew_data(0.0, false, 0, 0)
	for pip in card.energy_pips:
		assert_eq(pip.color, card.PIP_EMPTY_COLOR, "All pips grey at 0 energy")
	assert_true(card.tired_label.visible, "Tired badge visible at 0 energy when healthy")
	assert_eq(card.tired_label.text, tr("CREW_TIRED_LABEL"), "Tired badge uses CREW_TIRED_LABEL")
	assert_true(card.is_tired_warning(), "is_tired_warning true at 0 energy when healthy")

	var sci_btn: Button = card._picker_buttons["SCIENCE"]["button"]
	var sci_reason: Label = card._picker_buttons["SCIENCE"]["reason_lbl"]
	var rest_reason: Label = card._picker_buttons["REST"]["reason_lbl"]
	assert_false(sci_btn.disabled, "Non-REST jobs stay selectable at 0 energy")
	assert_eq(sci_btn.modulate, Color.WHITE, "Selectable warning button stays full brightness")
	assert_true(sci_reason.visible, "SCIENCE shows warning label at 0 energy")
	assert_eq(sci_reason.text, tr("CREW_TIRED_WARN").format({"name": "Leo"}), "SCIENCE warning matches formatted CREW_TIRED_WARN")
	assert_true(rest_reason.visible and rest_reason.text == tr("CREW_REST_REFILL"), "REST shows CREW_REST_REFILL")

	Audio._last_sfx_ms.erase("ui_error")
	sci_btn.pressed.emit()
	assert_eq(card.get_job(), sim_plan_script.JOB_SCIENCE, "Player can still confirm SCIENCE at 0 energy")
	assert_true(Audio.is_playing("ui_error"), "Picking non-REST at 0 energy plays ui_error warning chime")
	Audio.stop_all()
	card.free()

	# 2. DayHud + BuildingMarker warnings when selected crew has 0 energy
	var cargo = _make_m6_test_cargo(Constants.sim)
	var mission = sim_mission_script.new(Constants.sim, cargo, 1, {"storm_day": 99, "recycler_day": 99, "meteoroid_day": 0})
	var hud = day_hud_scene.instantiate()
	hud._ready()
	hud.setup_mission(mission)
	hud.crew_cards[2].set_crew_data(0.0, false, 0, 0)
	hud.select_crew(2, false)
	var markers: Dictionary = hud.get_building_markers()
	var sci_marker: BuildingMarker = markers["drill"] as BuildingMarker
	var hab_marker: BuildingMarker = markers["habitat"] as BuildingMarker
	assert_true(sci_marker.is_primary_available(), "Drill (Science) marker stays selectable at 0 energy")
	assert_true(sci_marker.is_warning_visible(), "Drill (Science) marker shows tired warning pill")
	assert_eq(sci_marker.get_warning_text(), tr("CREW_TIRED_WARN").format({"name": "Leo"}), "Drill (Science) marker shows formatted CREW_TIRED_WARN")
	assert_true(hab_marker.get_label_text().contains(tr("CREW_REST_REFILL")), "Habitat marker shows CREW_REST_REFILL at 0 energy")

	Audio._last_sfx_ms.erase("ui_error")
	hud._on_building_marker_activated("drill", sim_plan_script.JOB_SCIENCE)
	assert_true(Audio.is_playing("ui_error"), "Tapping drill (Science) marker at 0 energy plays ui_error chime")
	Audio.stop_all()
	hud.free()

	# 3. SpeechBubble tired / overworked voice lines
	var base_rep: Dictionary = {
		"day": 3,
		"outcome": "CONTINUE",
		"blackout": false,
		"co2_high": false,
		"co2_mmhg": 3.0,
		"stocks": {"o2_kg": 100.0, "water_kg": 100.0, "food_kg": 100.0},
		"recycler_broken": false,
		"broken_panels": 0,
		"plants_died": false,
		"science_points": 1,
		"crew_reports": [
			{"job": "REST", "sick": false, "energy": 3},
			{"job": "REST", "sick": false, "energy": 3},
			{"job": "SCIENCE", "sick": false, "energy": 0},
			{"job": "REST", "sick": false, "energy": 3}
		]
	}
	var tired_voice: Dictionary = speech_bubble_script.pick_voice(base_rep, {})
	assert_eq(str(tired_voice.get("key", "")), "CREW_SAY_TIRED", "SpeechBubble speaks CREW_SAY_TIRED at 0 energy")
	assert_eq(int(tired_voice.get("crew_index", -1)), 2, "Tired voice comes from tired healthy crew 2")

	var overworked_rep: Dictionary = base_rep.duplicate(true)
	overworked_rep["crew_reports"][2] = {"job": "REST", "sick": true, "energy": 0}
	var over_voice: Dictionary = speech_bubble_script.pick_voice(overworked_rep, {"newly_tired": [2]})
	assert_eq(str(over_voice.get("key", "")), "CREW_SAY_OVERWORKED", "SpeechBubble speaks CREW_SAY_OVERWORKED on overwork")
	assert_eq(int(over_voice.get("crew_index", -1)), 2, "Overworked voice comes from overworked crew 2")

	# 4. TutorialOverlay one-time "tired" hint
	Settings.hint_tired_shown = false
	var overlay = tutorial_scene.instantiate()
	overlay._ready()
	overlay.show_hint("tired")
	assert_true(overlay.visible, "Tired hint becomes visible")
	assert_eq(overlay.title_label.text, tr("HINT_TIRED_TITLE"), "Tired hint renders HINT_TIRED_TITLE")
	assert_eq(overlay.body_label.text, tr("HINT_TIRED_BODY"), "Tired hint renders HINT_TIRED_BODY")
	overlay.hide_overlay()
	overlay.free()

	# 5. Empty Bangla translations fall back cleanly to English when locale is bn
	TranslationServer.set_locale("bn")
	assert_eq(tr("CREW_TIRED_LABEL"), "Tired!", "Empty bn CREW_TIRED_LABEL falls back to English")
	assert_eq(tr("CREW_TIRED_WARN"), "Too tired! Working today will make {name} sick.", "Empty bn CREW_TIRED_WARN falls back to English")
	TranslationServer.set_locale(prev_locale)
	Settings.reset_onboarding()
	Audio.stop_all()
