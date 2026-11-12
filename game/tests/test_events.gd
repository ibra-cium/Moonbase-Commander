extends "res://tests/test_case.gd"

const SimEventsScript := preload("res://sim/sim_events.gd")
const SimEventScript := preload("res://sim/sim_event.gd")
const SimLogScript := preload("res://sim/sim_log.gd")

func test_events_same_seed_same_days() -> void:
	var sim: SimConstants = load_constants()

	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 42
	var events1 = SimEventsScript.new(sim)
	events1.schedule(rng1)

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 42
	var events2 = SimEventsScript.new(sim)
	events2.schedule(rng2)

	assert_eq(events1.storm_day, events2.storm_day, "same seed should yield same storm_day")
	assert_eq(events1.recycler_day, events2.recycler_day, "same seed should yield same recycler_day")
	assert_eq(events1.meteoroid_day, events2.meteoroid_day, "same seed should yield same meteoroid_day")

func test_force_overrides_and_never() -> void:
	var sim: SimConstants = load_constants()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1

	var events = SimEventsScript.new(sim)
	events.schedule(rng, {
		"storm_day": 10,
		"recycler_day": 99,
		"meteoroid_day": 0,
	})

	assert_eq(events.storm_day, 10, "storm_day should be forced to 10")
	assert_eq(events.recycler_day, 99, "recycler_day should be forced to 99 (never)")
	assert_eq(events.meteoroid_day, 0, "meteoroid_day should be forced to 0 (never)")

	assert_true(events.has_storm(), "events has_storm should be true for day 10")
	assert_false(events.has_recycler_break(), "events has_recycler_break should be false for day 99")
	assert_false(events.has_meteoroid(), "events has_meteoroid should be false for day 0")

	# Test short-form keys in force dictionary
	var events_short = SimEventsScript.new(sim)
	events_short.schedule(rng, {
		"storm": 12,
		"recycler": 14,
		"meteoroid": 20,
	})
	assert_eq(events_short.storm_day, 12, "storm should force storm_day to 12")
	assert_eq(events_short.recycler_day, 14, "recycler should force recycler_day to 14")
	assert_eq(events_short.meteoroid_day, 20, "meteoroid should force meteoroid_day to 20")

func test_storm_dose_interpolation() -> void:
	var sim: SimConstants = load_constants()
	var events = SimEventsScript.new(sim)

	assert_near(events.storm_dose(0.0), 398.0, 0.001, "storm_dose(0) should be 398.0")
	assert_near(events.storm_dose(2.5), 287.85, 0.01, "storm_dose(2.5) should be ≈ 287.85")
	assert_near(events.storm_dose(5.0), 177.7, 0.001, "storm_dose(5) should be 177.7")
	assert_near(events.storm_dose(10.0), 68.1, 0.001, "storm_dose(10) should be 68.1")
	assert_near(events.storm_dose(15.0), 46.9, 0.001, "storm_dose(15) should be 46.9")
	assert_near(events.storm_dose(20.0), 46.9, 0.001, "storm_dose(20) should be capped at 46.9")

func test_shield_needed_for_limit() -> void:
	var sim: SimConstants = load_constants()
	var events = SimEventsScript.new(sim)

	var needed_250: float = events.shield_needed_for_limit(250.0)
	assert_near(needed_250, 3.4, 0.05, "needed shield for 250 mSv should be ≈ 3.4 g/cm²")

	var default_needed: float = events.shield_needed_for_limit()
	assert_near(default_needed, 3.4, 0.05, "default needed shield (RAD_SPE_LIMIT_MSV = 250) should be ≈ 3.4 g/cm²")

	# Boundary cases
	assert_near(events.shield_needed_for_limit(400.0), 0.0, 0.001, "limit >= 398 requires 0 shield")
	assert_near(events.shield_needed_for_limit(40.0), 15.0, 0.001, "limit <= 46.9 requires max shield 15.0")

func test_sim_log_chain_walks_back_correctly() -> void:
	var log = SimLogScript.new()

	var id0: int = log.add(15, "SUNSET")
	var id1: int = log.add(16, "BLACKOUT", {"battery": 0.0}, id0)
	var id2: int = log.add(17, "CO2_HIGH", {"co2": 8.5}, id1)
	var id3: int = log.add(17, "CREW_SICK", {"sick": 4}, id2)
	var id4: int = log.add(18, "EVAC_CO2", {"day": 18}, id3)

	assert_eq(log.latest("CO2_HIGH"), id2, "latest CO2_HIGH should return id2")
	assert_eq(log.latest("NONEXISTENT"), -1, "latest NONEXISTENT should return -1")

	var full_chain: Array = log.chain_from(id4, 5)
	assert_eq(full_chain.size(), 5, "chain with max_steps 5 should have 5 items")
	assert_eq(full_chain[0]["code"], "SUNSET", "chain step 0 should be SUNSET (oldest)")
	assert_eq(full_chain[1]["code"], "BLACKOUT", "chain step 1 should be BLACKOUT")
	assert_eq(full_chain[2]["code"], "CO2_HIGH", "chain step 2 should be CO2_HIGH")
	assert_eq(full_chain[3]["code"], "CREW_SICK", "chain step 3 should be CREW_SICK")
	assert_eq(full_chain[4]["code"], "EVAC_CO2", "chain step 4 should be EVAC_CO2 (newest)")

	var short_chain: Array = log.chain_from(id4, 3)
	assert_eq(short_chain.size(), 3, "chain with max_steps 3 should have 3 items")
	assert_eq(short_chain[0]["code"], "CO2_HIGH", "short chain step 0 should be CO2_HIGH")
	assert_eq(short_chain[1]["code"], "CREW_SICK", "short chain step 1 should be CREW_SICK")
	assert_eq(short_chain[2]["code"], "EVAC_CO2", "short chain step 2 should be EVAC_CO2")

	var empty_chain: Array = log.chain_from(-1)
	assert_eq(empty_chain.size(), 0, "chain from invalid id should be empty")

func test_start_and_end_of_day_events() -> void:
	var sim: SimConstants = load_constants()
	var events = SimEventsScript.new(sim)
	events.schedule(null, {
		"storm_day": 10,
		"recycler_day": 12,
		"meteoroid_day": 14,
	})

	# Start of day 15 is SUNSET
	var day_15_events: Array = events.start_of_day(15)
	assert_eq(day_15_events.size(), 1, "day 15 start should have SUNSET event")
	assert_eq(day_15_events[0].code, "SUNSET", "event code should be SUNSET")
	assert_false(day_15_events[0].needs_popup, "SUNSET should not need popup")

	# Start of day 10 is STORM_WARNING
	var day_10_events: Array = events.start_of_day(10)
	assert_eq(day_10_events.size(), 1, "day 10 start should have STORM_WARNING event")
	assert_eq(day_10_events[0].code, "STORM_WARNING", "event code should be STORM_WARNING")
	assert_true(day_10_events[0].needs_popup, "STORM_WARNING should need popup")
	assert_eq(int(day_10_events[0].data["warning_min"]), 60, "warning_min should be 60")

	# End of day 12 is RECYCLER_BROKE
	var day_12_events: Array = events.end_of_day(12)
	assert_eq(day_12_events.size(), 1, "day 12 end should have RECYCLER_BROKE event")
	assert_eq(day_12_events[0].code, "RECYCLER_BROKE", "event code should be RECYCLER_BROKE")

	# End of day 14 is METEOROID when working panels exist
	var day_14_events: Array = events.end_of_day(14, {"working_panels": 10})
	assert_eq(day_14_events.size(), 1, "day 14 end should have METEOROID event if panels exist")
	assert_eq(day_14_events[0].code, "METEOROID", "event code should be METEOROID")

	# End of day 14 when working panels is 0: no event
	var day_14_no_panels: Array = events.end_of_day(14, {"working_panels": 0})
	assert_eq(day_14_no_panels.size(), 0, "day 14 end should not have METEOROID event if 0 working panels")

func test_sim_event_properties() -> void:
	var evt = SimEventScript.new("STORM_WARNING", 10, true, {"warning_min": 60})
	assert_eq(evt.code, "STORM_WARNING", "code should match")
	assert_eq(evt.day, 10, "day should match")
	assert_true(evt.needs_popup, "needs_popup should be true")
	assert_true(evt.needs_choice, "needs_choice should match needs_popup")
	assert_eq(int(evt.data["warning_min"]), 60, "data should contain warning_min")

	var d: Dictionary = evt.to_dict()
	assert_eq(d["code"], "STORM_WARNING", "to_dict code should match")
	assert_eq(d["day"], 10, "to_dict day should match")
	assert_true(d["needs_popup"], "to_dict needs_popup should match")

func test_cause_for_helper() -> void:
	var log = SimLogScript.new()

	# Empty log: cause_for should return -1
	assert_eq(log.cause_for("CO2_HIGH"), -1, "cause for CO2_HIGH with no blackout is -1")

	var s_id: int = log.add(15, "SUNSET")
	var b_night: int = log.cause_for("BLACKOUT", {"is_night": true})
	assert_eq(b_night, s_id, "night blackout caused by SUNSET")

	var b_id: int = log.add(16, "BLACKOUT", {}, b_night)
	var co2_cause: int = log.cause_for("CO2_HIGH")
	assert_eq(co2_cause, b_id, "CO2_HIGH caused by latest BLACKOUT")

	var co2_id: int = log.add(17, "CO2_HIGH", {}, co2_cause)
	var sick_cause: int = log.cause_for("CREW_SICK")
	assert_eq(sick_cause, co2_id, "CREW_SICK caused by latest CO2_HIGH")

	var evac_co2_cause: int = log.cause_for("EVAC_CO2")
	assert_eq(evac_co2_cause, co2_id, "EVAC_CO2 caused by latest CO2_HIGH")

	var rec_id: int = log.add(12, "RECYCLER_BROKE")
	var evac_water_broken: int = log.cause_for("EVAC_WATER", {"recycler_broken": true})
	assert_eq(evac_water_broken, rec_id, "EVAC_WATER caused by broken recycler")

	var shed_id: int = log.add(13, "POWER_SHED", {"systems": ["water"]})
	var evac_water_shed: int = log.cause_for("EVAC_WATER", {"recycler_broken": false})
	assert_eq(evac_water_shed, shed_id, "EVAC_WATER caused by power shed when recycler fixed")

	var food_id: int = log.add(18, "FOOD_SPOILED")
	var evac_food: int = log.cause_for("EVAC_FOOD")
	assert_eq(evac_food, food_id, "EVAC_FOOD caused by FOOD_SPOILED")

	var storm_id: int = log.add(10, "STORM_WARNING")
	var evac_rad: int = log.cause_for("EVAC_RADIATION")
	assert_eq(evac_rad, storm_id, "EVAC_RADIATION caused by STORM_WARNING")

func test_schedule_bounds_without_force() -> void:
	var sim: SimConstants = load_constants()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var events = SimEventsScript.new(sim)
	events.schedule(rng)

	assert_true(events.storm_day >= 8 and events.storm_day <= 26, "storm_day in [8, 26]")
	assert_true(events.recycler_day >= 10 and events.recycler_day <= 20, "recycler_day in [10, 20]")
	assert_true((events.meteoroid_day >= 3 and events.meteoroid_day <= 28) or events.meteoroid_day == 0, "meteoroid_day in [3, 28] or 0")

