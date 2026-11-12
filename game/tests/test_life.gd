extends "res://tests/test_case.gd"

const SimLifeScript := preload("res://sim/sim_life.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")

func test_recycler_on_water_loss_and_oga() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	# 4 crew, 50 kg O2, 100 kg water, 100 kg food
	life.setup_amounts(50.0, 100.0, 100.0)

	var power_res: Dictionary = {
		"served": {"core": true, "water": true, "food": true}
	}
	var res: Dictionary = life.resolve(power_res, 0.0, 0.0, 4)

	assert_true(bool(res["air_on"]), "air should be on")
	assert_true(bool(res["recycler_on"]), "recycler should be on")
	# 4 crew: drink = 3.217 * 4 = 12.868 kg; loss = 12.868 * (1 - 0.98) = 0.25736 kg ≈ 0.257 kg
	assert_near(float(res["water_loss_kg"]), 0.2574, 0.001, "water loss with recycler on should be ≈ 0.257 kg")
	# O2 need = 0.895 * 4 = 3.58 kg; OGA water = 3.58 * 1.125 = 4.0275 kg ≈ 4.03 kg
	assert_near(float(res["oga_kg"]), 3.58, 0.001, "OGA should produce full 3.58 kg O2")
	assert_near(float(res["oga_water_kg"]), 4.0275, 0.001, "generator water should be ≈ 4.03 kg")
	assert_near(float(res["water_used_kg"]), 0.25736 + 4.0275, 0.001, "total water used should be loss + OGA water")
	assert_near(float(res["o2_from_tanks_kg"]), 0.0, 0.0001, "tanks should not be drawn when OGA meets need")
	assert_near(life.o2_kg, 50.0, 0.0001, "o2 tank stock remains untouched at 50 kg")
	assert_near(life.water_kg, 100.0 - (0.25736 + 4.0275), 0.001, "water_kg updated correctly")

func test_recycler_broken_water_loss() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	life.setup_amounts(50.0, 100.0, 100.0)
	life.recycler_broken = true

	var power_res: Dictionary = {
		"served": {"core": true, "water": true, "food": true}
	}
	var res: Dictionary = life.resolve(power_res, 0.0, 0.0, 4)

	assert_false(bool(res["recycler_on"]), "recycler should be off when broken")
	# drink = 12.868 kg unrecovered ≈ 12.87 kg
	assert_near(float(res["water_loss_kg"]), 12.868, 0.001, "water loss with broken recycler should be ≈ 12.87 kg")
	assert_near(float(res["oga_water_kg"]), 4.0275, 0.001, "generator water should still be ≈ 4.03 kg")
	assert_near(float(res["water_used_kg"]), 12.868 + 4.0275, 0.001, "total water should be ≈ 16.90 kg")

func test_air_off_co2_rise_and_tanks_drawn() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	life.setup_amounts(50.0, 100.0, 100.0, 1.5)

	# core shed / blackout
	var power_res: Dictionary = {
		"served": {"core": false, "water": true, "food": true}
	}
	var res: Dictionary = life.resolve(power_res, 0.0, 0.0, 4)

	assert_false(bool(res["air_on"]), "air should be off when core is shed")
	# CO2 rises by CO2_RISE_PER_DAY_AIR_OFF (1.5 mmHg) -> 1.5 + 1.5 = 3.0 mmHg
	assert_near(float(res["co2_delta"]), 1.5, 0.001, "CO2 delta should be +1.5 mmHg")
	assert_near(float(res["co2_mmhg"]), 3.0, 0.001, "CO2 should rise to 3.0 mmHg")
	assert_near(life.co2_mmhg, 3.0, 0.001, "life.co2_mmhg should be 3.0 mmHg")

	# OGA cannot run without air -> 0 OGA, all 3.58 kg from tanks
	assert_near(float(res["oga_kg"]), 0.0, 0.0001, "OGA should produce 0 kg O2 without air")
	assert_near(float(res["oga_water_kg"]), 0.0, 0.0001, "OGA uses 0 water without air")
	assert_near(float(res["o2_from_tanks_kg"]), 3.58, 0.001, "all 3.58 kg O2 comes from tanks")
	assert_near(life.o2_kg, 50.0 - 3.58, 0.001, "tank O2 reduced by 3.58 kg")

func test_co2_never_below_start_when_air_on() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)

	# Starting at CO2_START_MMHG (1.5 mmHg)
	life.co2_mmhg = 1.5
	var res1: Dictionary = life.resolve(null, 0.0, 0.0, 4)
	assert_near(float(res1["co2_mmhg"]), 1.5, 0.001, "CO2 should not drop below CO2_START_MMHG (1.5)")

	# Starting elevated at 2.0 mmHg -> falls by 1.0 down to max(1.5, 1.0) = 1.5
	life.co2_mmhg = 2.0
	var res2: Dictionary = life.resolve(null, 0.0, 0.0, 4)
	assert_near(float(res2["co2_mmhg"]), 1.5, 0.001, "CO2 should fall to 1.5 mmHg and clamp")

	# Starting elevated at 4.0 mmHg -> falls to 3.0 mmHg
	life.co2_mmhg = 4.0
	var res3: Dictionary = life.resolve(null, 0.0, 0.0, 4)
	assert_near(float(res3["co2_mmhg"]), 3.0, 0.001, "CO2 at 4.0 should fall by 1.0 to 3.0 mmHg")

func test_co2_high_flag() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	life.co2_mmhg = 3.0

	# 1 day air off: rises to 4.5 mmHg > CO2_HEADACHE_MMHG (3.0) -> co2_high = true
	var res: Dictionary = life.resolve({"served": {"core": false}}, 0.0, 0.0, 4)
	assert_near(float(res["co2_mmhg"]), 4.5, 0.001, "CO2 rises to 4.5 mmHg")
	assert_true(bool(res["co2_high"]), "co2_high should be true when CO2 > 3.0 mmHg")

func test_food_spoils_when_food_power_shed() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	life.setup_amounts(50.0, 100.0, 100.0)

	# Normal day with food power
	var res_normal: Dictionary = life.resolve({"served": {"core": true, "water": true, "food": true}}, 0.0, 0.0, 4)
	# 4 crew eat: 2.39 * 4 = 9.56 kg
	assert_near(float(res_normal["food_eaten_kg"]), 9.56, 0.001, "crew eats 9.56 kg")
	assert_near(float(res_normal["food_spoiled_kg"]), 0.0, 0.0001, "0 food spoils when powered")
	assert_false(bool(res_normal["food_spoiled"]), "food_spoiled flag should be false")
	assert_near(life.food_kg, 100.0 - 9.56, 0.001, "food_kg reduced by 9.56 kg")

	# Next day with food power shed
	var res_shed: Dictionary = life.resolve({"served": {"core": true, "water": true, "food": false}}, 0.0, 0.0, 4)
	# Eaten 9.56 kg + spoiled FOOD_SPOIL_DAYS_IF_OFF * 9.56 = 9.56 kg -> total 19.12 kg
	assert_near(float(res_shed["food_eaten_kg"]), 9.56, 0.001, "crew still eats 9.56 kg")
	assert_near(float(res_shed["food_spoiled_kg"]), 9.56, 0.001, "1 extra day spoils (9.56 kg)")
	assert_near(float(res_shed["food_used_kg"]), 19.12, 0.001, "total food lost is 19.12 kg")
	assert_true(bool(res_shed["food_spoiled"]), "food_spoiled flag should be true")
	assert_near(life.food_kg, 100.0 - 9.56 - 19.12, 0.001, "food_kg drops by 19.12 kg")

func test_oga_limited_by_water_shortage() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	# Recycler on: water loss = 0.25736 kg.
	# With 2.25736 kg water available:
	# After water loss, remaining water = 2.0 kg.
	# Max O2 from 2.0 kg water = 2.0 / 1.125 = 1.77778 kg O2.
	# Need is 3.58 kg O2 -> OGA generates 1.7778 kg, remaining 1.8022 kg comes from tanks!
	life.setup_amounts(50.0, 2.25736, 100.0)

	var res: Dictionary = life.resolve(null, 0.0, 0.0, 4)
	assert_near(float(res["oga_kg"]), 1.7778, 0.001, "OGA limited by remaining water")
	assert_near(float(res["oga_water_kg"]), 2.0, 0.001, "OGA uses remaining 2.0 kg water")
	assert_near(life.water_kg, 0.0, 0.0001, "water reaches exactly 0.0 kg")
	assert_near(float(res["o2_from_tanks_kg"]), 3.58 - 1.7778, 0.001, "remaining O2 drawn from tanks")
	assert_near(life.o2_kg, 50.0 - (3.58 - 1.7778), 0.001, "tanks reduced by shortfall")

func test_greenhouse_o2_reduces_need() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	life.setup_amounts(50.0, 100.0, 100.0)

	# 10 m² greenhouse gives 0.398 kg O2
	# Need becomes 3.58 - 0.398 = 3.182 kg O2
	var res: Dictionary = life.resolve(null, 0.398, 21.0, 4)
	assert_near(float(res["o2_need_kg"]), 3.182, 0.001, "greenhouse O2 reduces crew need")
	assert_near(float(res["oga_kg"]), 3.182, 0.001, "OGA generates 3.182 kg O2")
	assert_near(float(res["oga_water_kg"]), 3.182 * 1.125, 0.001, "OGA water matches 3.182 kg O2")
	# Plant water is included in water_loss_kg (with recycler on: 21.0 * 0.02 = 0.42 kg)
	assert_near(float(res["plant_water_kg"]), 21.0, 0.001, "plant water is recorded")

func test_supply_low_warnings() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	# Set low levels (< 3 days of each)
	# Food: 15.0 kg (< 3 * 9.56 = 28.68 kg)
	# Water: 10.0 kg (< 3 * 4.28 = 12.84 kg)
	# O2: 5.0 kg (< 3 * 3.58 = 10.74 kg)
	life.setup_amounts(5.0, 10.0, 15.0)

	var res: Dictionary = life.resolve(null, 0.0, 0.0, 4)
	var low: Array = res["supply_low"]
	assert_true(low.has("food"), "food should be flagged as supply_low")
	assert_true(low.has("water"), "water should be flagged as supply_low")
	assert_true(low.has("o2"), "o2 should be flagged as supply_low")

func test_setup_from_cargo() -> void:
	var sim: SimConstants = load_constants()
	var cargo: SimCargo = SimCargoScript.new(sim)
	cargo.set_count("o2", 2)
	cargo.set_count("water", 4)
	cargo.set_count("food", 5)

	var life = SimLifeScript.new(sim, cargo)
	# 2 * 25 = 50 kg O2
	assert_near(life.o2_kg, 50.0, 0.01, "2 O2 tanks = 50 kg")
	# 4 * 45 = 180 kg water
	assert_near(life.water_kg, 180.0, 0.01, "4 water containers = 180 kg")
	# 5 * 66.92 = 334.6 kg food
	assert_near(life.food_kg, 334.6, 0.01, "5 food crates = 334.6 kg")
	assert_near(life.co2_mmhg, 1.5, 0.001, "CO2 starts at 1.5 mmHg")
	assert_false(life.recycler_broken, "recycler not broken at start")

func test_oga_capped_at_max_daily_production() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	# 8 crew: need = 0.895 * 8 = 7.16 kg O2
	# OGA_O2_KG_DAY is 5.4 kg -> OGA capped at 5.4 kg
	# Remaining 7.16 - 5.4 = 1.76 kg drawn from tanks
	life.setup_amounts(50.0, 100.0, 100.0)

	var res: Dictionary = life.resolve(null, 0.0, 0.0, 8)
	assert_near(float(res["oga_kg"]), 5.4, 0.001, "OGA output capped at OGA_O2_KG_DAY (5.4 kg)")
	assert_near(float(res["oga_water_kg"]), 5.4 * 1.125, 0.001, "water used by 5.4 kg O2")
	assert_near(float(res["o2_from_tanks_kg"]), 7.16 - 5.4, 0.001, "shortfall drawn from tanks")

func test_days_left_helpers() -> void:
	var sim: SimConstants = load_constants()
	var life = SimLifeScript.new(sim)
	# 4 crew: food eat = 9.56 kg/day. 95.6 kg food = 10.0 days
	life.setup_amounts(35.8, 42.8486, 95.6)
	assert_near(life.get_food_days_left(4), 10.0, 0.01, "food days left should be 10.0")
	# O2 tank: 35.8 kg / 3.58 kg/day = 10.0 days
	assert_near(life.get_o2_tank_days_left(4), 10.0, 0.01, "o2 tank days left should be 10.0")
	# Water with recycler: loss = 0.25736, oga_water = 4.0275 -> total ≈ 4.28486 kg/day. 42.8486 kg = 10.0 days
	assert_near(life.get_water_days_left(4, true), 10.0, 0.01, "water days left with recycler should be 10.0")

