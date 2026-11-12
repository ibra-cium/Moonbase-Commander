extends "res://tests/test_case.gd"

const SimMissionScript := preload("res://sim/sim_mission.gd")
const SimPlanScript := preload("res://sim/sim_plan.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimDebriefScript := preload("res://sim/sim_debrief.gd")
const GameStateScript := preload("res://autoload/game_state.gd")

func test_s02_survival_30_days() -> void:
	var sim: SimConstants = load_constants()
	var base_cargo := {
		"solar": 20,
		"battery": 4,
		"reactor": 2,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 5,
		"shield": 10
	}
	var mission := SimMissionScript.new(sim, base_cargo, 1, {
		"storm": 10,
		"recycler": 99,
		"meteoroid": 0
	})

	var last_report = null
	for d in range(1, 31):
		assert_false(mission.ended, "mission should not be ended before or during day %d" % d)
		assert_eq(mission.day, d, "current day should match step counter %d" % d)

		var plan := SimPlanScript.new()
		# Rule REST: repair if something broken, else REST
		if mission.life.recycler_broken:
			plan.set_job(0, "REPAIR")
		elif mission.power.broken_panels > 0:
			plan.set_job(0, "REPAIR")
		else:
			plan.set_job(0, "REST")
		plan.set_job(1, "REST")
		plan.set_job(2, "REST")
		plan.set_job(3, "REST")
		plan.greenhouse_lights_on = false
		plan.science_gear_on = false

		last_report = mission.step_day(plan)
		assert_eq(last_report.day, d, "report day should be %d" % d)

	assert_true(mission.ended, "mission should be ended after day 30")
	assert_true(mission.result != null, "mission should have result")
	assert_eq(mission.result.outcome, "SURVIVED", "outcome should be SURVIVED")
	assert_eq(mission.result.end_day, 30, "end_day should be 30")
	assert_eq(mission.result.stars, 2, "stars should be 2 (no sickness, sci < 10)")
	assert_eq(mission.result.root_cause_code, "ROOT_SUCCESS", "root cause should be ROOT_SUCCESS")
	assert_true(mission.result.fact_id != "", "should have assigned a fact id")
	assert_false(mission.crew.ever_sick, "crew should never have gotten sick")

func test_end_checks_order() -> void:
	var sim: SimConstants = load_constants()
	var base_cargo := {
		"solar": 20,
		"battery": 4,
		"reactor": 2,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 5,
		"shield": 0
	}

	# 1. EVAC_RADIATION takes priority over EVAC_CO2
	var m1 := SimMissionScript.new(sim, base_cargo, 1, {"storm": 1})
	m1.life.co2_mmhg = 30.0 # above CO2_EVAC_MMHG
	var r1 = m1.step_day(SimPlanScript.new())
	assert_true(m1.ended, "m1 should end on day 1")
	assert_eq(m1.result.outcome, "EVAC_RADIATION", "EVAC_RADIATION should take priority over EVAC_CO2")

	# 2. EVAC_CO2 takes priority over EVAC_O2
	var m2 := SimMissionScript.new(sim, base_cargo, 1, {"storm": 99})
	m2.life.co2_mmhg = 25.0
	m2.life.o2_kg = -5.0
	var r2 = m2.step_day(SimPlanScript.new())
	assert_true(m2.ended, "m2 should end on day 1")
	assert_eq(m2.result.outcome, "EVAC_CO2", "EVAC_CO2 should take priority over EVAC_O2")

	# 3. EVAC_O2 takes priority over EVAC_WATER
	var m3 := SimMissionScript.new(sim, base_cargo, 1, {"storm": 99})
	m3.life.o2_kg = -5.0
	m3.life.water_kg = -10.0
	var r3 = m3.step_day(SimPlanScript.new())
	assert_true(m3.ended, "m3 should end on day 1")
	assert_eq(m3.result.outcome, "EVAC_O2", "EVAC_O2 should take priority over EVAC_WATER")

	# 4. EVAC_WATER takes priority over EVAC_FOOD
	var m4 := SimMissionScript.new(sim, base_cargo, 1, {"storm": 99})
	m4.life.water_kg = -10.0
	m4.life.food_kg = -10.0
	var r4 = m4.step_day(SimPlanScript.new())
	assert_true(m4.ended, "m4 should end on day 1")
	assert_eq(m4.result.outcome, "EVAC_WATER", "EVAC_WATER should take priority over EVAC_FOOD")

func test_root_cause_rules() -> void:
	var sim: SimConstants = load_constants()

	# ROOT_NIGHT_ENERGY (S01: solar only, battery 10, reactor 0)
	var c_s01 := {
		"solar": 20,
		"battery": 10,
		"reactor": 0,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 5,
		"shield": 10
	}
	var m_s01 := SimMissionScript.new(sim, c_s01, 1, {"storm": 10, "recycler": 99, "meteoroid": 0})
	for d in range(1, 31):
		m_s01.step_day(SimPlanScript.new())
		if m_s01.ended:
			break
	assert_true(m_s01.ended, "S01 should end early")
	assert_eq(m_s01.result.outcome, "EVAC_CO2", "S01 should evacuate due to CO2")
	assert_eq(m_s01.result.end_day, 18, "S01 should evacuate on day 18")
	assert_eq(m_s01.result.root_cause_code, "ROOT_NIGHT_ENERGY", "S01 root cause should be ROOT_NIGHT_ENERGY")
	assert_true(m_s01.result.root_cause_values.has("have"), "root cause values should have 'have'")
	assert_true(m_s01.result.root_cause_values.has("need"), "root cause values should have 'need'")

	# ROOT_SHIELD (S05: shield 0, storm day 12)
	var c_s05 := {
		"solar": 20,
		"battery": 4,
		"reactor": 2,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 5,
		"shield": 0
	}
	var m_s05 := SimMissionScript.new(sim, c_s05, 1, {"storm": 12, "recycler": 99, "meteoroid": 0})
	for d in range(1, 31):
		m_s05.step_day(SimPlanScript.new())
		if m_s05.ended:
			break
	assert_true(m_s05.ended, "S05 should end early")
	assert_eq(m_s05.result.outcome, "EVAC_RADIATION", "S05 should evacuate due to radiation")
	assert_eq(m_s05.result.end_day, 12, "S05 should evacuate on day 12")
	assert_eq(m_s05.result.root_cause_code, "ROOT_SHIELD", "S05 root cause should be ROOT_SHIELD")
	assert_near(float(m_s05.result.root_cause_values["g"]), 0.0, 0.01, "shelter g should be 0")

	# ROOT_REPAIR (S06: recycler broke day 12, NOFIX -> EVAC_WATER day 20)
	var c_s06 := {
		"solar": 20,
		"battery": 4,
		"reactor": 2,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 5,
		"shield": 10
	}
	var m_s06 := SimMissionScript.new(sim, c_s06, 1, {"storm": 10, "recycler": 12, "meteoroid": 0})
	for d in range(1, 31):
		m_s06.step_day(SimPlanScript.new()) # NOFIX: all REST
		if m_s06.ended:
			break
	assert_true(m_s06.ended, "S06 should end early")
	assert_eq(m_s06.result.outcome, "EVAC_WATER", "S06 should evacuate due to water")
	assert_eq(m_s06.result.end_day, 20, "S06 should evacuate on day 20")
	assert_eq(m_s06.result.root_cause_code, "ROOT_REPAIR", "S06 root cause should be ROOT_REPAIR")
	assert_eq(int(m_s06.result.root_cause_values["d"]), 12, "recycler break day should be 12")

	# ROOT_SUPPLY (Food shortage without night blackout)
	var c_supply := {
		"solar": 20,
		"battery": 4,
		"reactor": 2,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 1,
		"shield": 10
	}
	var m_supply := SimMissionScript.new(sim, c_supply, 1, {"storm": 99, "recycler": 99, "meteoroid": 0})
	for d in range(1, 31):
		m_supply.step_day(SimPlanScript.new())
		if m_supply.ended:
			break
	assert_true(m_supply.ended, "Food shortage mission should end early")
	assert_eq(m_supply.result.outcome, "EVAC_FOOD", "Should evacuate due to food")
	assert_eq(m_supply.result.root_cause_code, "ROOT_SUPPLY", "Root cause should be ROOT_SUPPLY")
	assert_eq(str(m_supply.result.root_cause_values["item"]), "food", "Supply item should be food")

func test_deterministic_reproducibility() -> void:
	var sim: SimConstants = load_constants()
	var base_cargo := {
		"solar": 20,
		"battery": 4,
		"reactor": 2,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 5,
		"shield": 10
	}

	var m1 := SimMissionScript.new(sim, base_cargo, 777)
	var m2 := SimMissionScript.new(sim, base_cargo, 777)

	for d in range(1, 15):
		var plan := SimPlanScript.new()
		var r1 = m1.step_day(plan)
		var r2 = m2.step_day(plan)

		assert_near(r1.generation_kwh, r2.generation_kwh, 0.001, "day %d gen should match" % d)
		assert_near(r1.battery_kwh, r2.battery_kwh, 0.001, "day %d batt should match" % d)
		assert_near(r1.water_kg, r2.water_kg, 0.001, "day %d water should match" % d)
		assert_near(r1.o2_kg, r2.o2_kg, 0.001, "day %d o2 should match" % d)
		assert_near(r1.food_kg, r2.food_kg, 0.001, "day %d food should match" % d)
		assert_eq(r1.events.size(), r2.events.size(), "day %d event count should match" % d)

class SignalListener:
	extends RefCounted
	var log: Array[String] = []

	func on_mission_started(_m) -> void:
		log.append("mission_started")

	func on_day_started(_day, _warnings) -> void:
		log.append("day_started")

	func on_event_triggered(_evt) -> void:
		log.append("event_triggered")

	func on_day_resolved(_report) -> void:
		log.append("day_resolved")

	func on_mission_ended(_result) -> void:
		log.append("mission_ended")

func test_game_state_signals_order() -> void:
	var sim: SimConstants = load_constants()
	var state = GameStateScript.new()
	var listener := SignalListener.new()

	state.mission_started.connect(listener.on_mission_started)
	state.day_started.connect(listener.on_day_started)
	state.event_triggered.connect(listener.on_event_triggered)
	state.day_resolved.connect(listener.on_day_resolved)
	state.mission_ended.connect(listener.on_mission_ended)

	var base_cargo := {
		"solar": 20,
		"battery": 4,
		"reactor": 2,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 5,
		"shield": 10
	}

	# 1. new_mission emits mission_started, then day_started
	state.new_mission(base_cargo, 1, {"storm": 10, "recycler": 99, "meteoroid": 0}, sim)
	assert_eq(listener.log.size(), 2, "new_mission should emit 2 signals")
	assert_eq(listener.log[0], "mission_started", "first signal should be mission_started")
	assert_eq(listener.log[1], "day_started", "second signal should be day_started")

	# 2. submit_day on normal day emits day_resolved, then day_started
	listener.log.clear()
	state.submit_day(SimPlanScript.new())
	assert_true(listener.log.has("day_resolved"), "should emit day_resolved")
	assert_eq(listener.log[listener.log.size() - 1], "day_started", "last signal should be day_started for day 2")

	# 3. submit_day when mission ends emits day_resolved, then mission_ended
	# Force end by emptying food
	state.current_mission.life.food_kg = -1.0
	listener.log.clear()
	state.submit_day(SimPlanScript.new())
	assert_true(listener.log.has("day_resolved"), "should emit day_resolved on end")
	assert_eq(listener.log[listener.log.size() - 1], "mission_ended", "last signal on end should be mission_ended")

