extends "res://tests/test_case.gd"

const SimGreenhouseScript := preload("res://sim/sim_greenhouse.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")

func test_ten_m2_healthy_oxygen() -> void:
	var sim: SimConstants = load_constants()
	var gh = SimGreenhouseScript.new(sim, 10.0)

	assert_near(gh.area, 10.0, 0.001, "greenhouse area should be 10 m2")
	assert_true(gh.alive, "plants should start alive")
	assert_eq(gh.days_since_farm, 0, "days_since_farm starts at 0")

	var res: Dictionary = gh.resolve(true, 50.0)
	assert_true(bool(res["healthy"]), "10 m2 greenhouse with power and water should be healthy")
	# CROP_O2_G_M2_DAY = 39.777778 -> 10 m2 * 39.777778 / 1000 = 0.3977778 kg ≈ 0.398 kg
	assert_near(float(res["o2_kg"]), 0.3978, 0.001, "10 m2 healthy produces ≈ 0.398 kg O2")
	# GREENHOUSE_WATER_L_M2_DAY = 2.1 -> 10 m2 * 2.1 = 21.0 kg plant water
	assert_near(float(res["water_kg"]), 21.0, 0.001, "10 m2 uses 21.0 kg plant water")
	assert_eq(int(res["science_point"]), 0, "day 1 gives 0 science points")
	assert_false(bool(res["died"]), "plants should not die when healthy")
	assert_eq(gh.healthy_days, 1, "healthy_days should be 1")
	assert_eq(gh.growth_days, 1, "growth_days should be 1")

func test_science_point_every_three_healthy_days() -> void:
	var sim: SimConstants = load_constants()
	var gh = SimGreenhouseScript.new(sim, 10.0)

	var r1: Dictionary = gh.resolve(true, 50.0)
	assert_eq(int(r1["science_point"]), 0, "healthy day 1 gives 0 science points")
	gh.end_of_day(true)

	var r2: Dictionary = gh.resolve(true, 50.0)
	assert_eq(int(r2["science_point"]), 0, "healthy day 2 gives 0 science points")
	gh.end_of_day(true)

	var r3: Dictionary = gh.resolve(true, 50.0)
	assert_eq(int(r3["science_point"]), 1, "healthy day 3 gives 1 science point")
	gh.end_of_day(true)

	var r4: Dictionary = gh.resolve(true, 50.0)
	assert_eq(int(r4["science_point"]), 0, "healthy day 4 gives 0 science points")
	gh.end_of_day(true)

	var r5: Dictionary = gh.resolve(true, 50.0)
	assert_eq(int(r5["science_point"]), 0, "healthy day 5 gives 0 science points")
	gh.end_of_day(true)

	var r6: Dictionary = gh.resolve(true, 50.0)
	assert_eq(int(r6["science_point"]), 1, "healthy day 6 gives 1 science point")
	assert_eq(gh.healthy_days, 6, "healthy_days should be 6")
	assert_eq(gh.growth_days, 6, "growth_days should be 6")

func test_two_unhealthy_days_dead_forever() -> void:
	var sim: SimConstants = load_constants()
	var gh = SimGreenhouseScript.new(sim, 10.0)

	# Day 1 unhealthy (power unserved)
	var r1: Dictionary = gh.resolve(false, 50.0)
	assert_false(bool(r1["healthy"]), "day 1 unhealthy when power is unserved")
	assert_false(bool(r1["died"]), "plants should not die on 1st wilt day")
	assert_true(gh.alive, "plants still alive after 1 wilt day")
	assert_eq(gh.wilt_days, 1, "wilt_days should be 1")
	assert_near(float(r1["o2_kg"]), 0.0, 0.0001, "0 O2 produced when unhealthy")
	gh.end_of_day(true)

	# Day 2 unhealthy (power unserved) -> 2nd unhealthy day kills plants
	var r2: Dictionary = gh.resolve(false, 50.0)
	assert_false(bool(r2["healthy"]), "day 2 unhealthy")
	assert_true(bool(r2["died"]), "died flag should be true on 2nd unhealthy day")
	assert_false(gh.alive, "plants should now be dead")
	assert_eq(gh.wilt_days, 2, "wilt_days reaches 2")
	gh.end_of_day(true)

	# Day 3: ideal conditions provided, but plants remain dead forever
	var r3: Dictionary = gh.resolve(true, 50.0)
	assert_false(bool(r3["healthy"]), "dead plants cannot be healthy")
	assert_false(gh.alive, "dead plants remain dead forever")
	assert_false(bool(r3["died"]), "died flag is only true on the day of death")
	assert_near(float(r3["o2_kg"]), 0.0, 0.0001, "dead plants produce no O2")
	assert_near(float(r3["water_kg"]), 0.0, 0.0001, "dead plants use no water")

func test_no_farm_job_for_two_days_unhealthy() -> void:
	var sim: SimConstants = load_constants()
	var gh = SimGreenhouseScript.new(sim, 10.0)

	# Day 1: start-of-day days_since_farm = 0 (< 2) -> healthy
	var r1: Dictionary = gh.resolve(true, 50.0)
	assert_true(bool(r1["healthy"]), "day 1 healthy (0 days since farm)")
	gh.end_of_day(false) # no farm job
	assert_eq(gh.days_since_farm, 1, "days_since_farm increments to 1")

	# Day 2: start-of-day days_since_farm = 1 (< 2) -> healthy
	var r2: Dictionary = gh.resolve(true, 50.0)
	assert_true(bool(r2["healthy"]), "day 2 healthy (1 day since farm)")
	gh.end_of_day(false) # no farm job again (2 days without farm)
	assert_eq(gh.days_since_farm, 2, "days_since_farm increments to 2")

	# Day 3: start-of-day days_since_farm = 2 (not < 2) -> unhealthy!
	var r3: Dictionary = gh.resolve(true, 50.0)
	assert_false(bool(r3["healthy"]), "day 3 unhealthy because no farm job for 2 days")
	assert_eq(gh.wilt_days, 1, "wilt_days increments to 1")

	# Crew farms today
	gh.end_of_day(true)
	assert_eq(gh.days_since_farm, 0, "farming resets days_since_farm to 0")

	# Day 4: recovered
	var r4: Dictionary = gh.resolve(true, 50.0)
	assert_true(bool(r4["healthy"]), "plants recover when farmed in time")
	assert_eq(gh.wilt_days, 0, "wilt_days resets to 0 upon recovering")

func test_area_zero_does_nothing() -> void:
	var sim: SimConstants = load_constants()
	var gh = SimGreenhouseScript.new(sim, 0.0)

	assert_false(gh.alive, "area 0 greenhouse is not alive")
	assert_near(gh.area, 0.0, 0.001, "area is 0.0")

	var res: Dictionary = gh.resolve(true, 100.0)
	assert_false(bool(res["healthy"]), "area 0 is not healthy")
	assert_near(float(res["o2_kg"]), 0.0, 0.0001, "area 0 produces 0 O2")
	assert_near(float(res["water_kg"]), 0.0, 0.0001, "area 0 consumes 0 water")
	assert_eq(int(res["science_point"]), 0, "area 0 gives 0 science points")
	assert_false(bool(res["died"]), "area 0 cannot die")

	gh.end_of_day(false)
	assert_eq(gh.days_since_farm, 0, "days_since_farm remains 0")
	assert_eq(gh.healthy_days, 0, "healthy_days remains 0")
	assert_eq(gh.growth_days, 0, "growth_days remains 0")

func test_water_zero_causes_unhealthy() -> void:
	var sim: SimConstants = load_constants()
	var gh = SimGreenhouseScript.new(sim, 10.0)

	var res: Dictionary = gh.resolve(true, 0.0)
	assert_false(bool(res["healthy"]), "greenhouse without water is unhealthy")
	assert_near(float(res["o2_kg"]), 0.0, 0.0001, "unhealthy greenhouse produces 0 O2")
	assert_eq(gh.wilt_days, 1, "wilt_days is 1")

func test_setup_from_cargo() -> void:
	var sim: SimConstants = load_constants()
	var cargo: SimCargo = SimCargoScript.new(sim)
	cargo.set_count("greenhouse", 10)

	var gh = SimGreenhouseScript.new(sim)
	gh.setup_from_cargo(cargo)
	assert_near(gh.area, 10.0, 0.001, "setup_from_cargo sets area to 10.0")
	assert_true(gh.alive, "plants are alive")

