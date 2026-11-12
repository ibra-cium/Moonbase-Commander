extends "res://tests/test_case.gd"

const SimPowerScript := preload("res://sim/sim_power.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")

func test_sun_factor() -> void:
	var sim: SimConstants = load_constants()
	var power: SimPower = SimPowerScript.new(sim)

	assert_near(power.get_sun_factor(1), 1.0, 0.0001, "day 1 sun factor should be 1.0")
	assert_near(power.get_sun_factor(14), 1.0, 0.0001, "day 14 sun factor should be 1.0")
	assert_near(power.get_sun_factor(15), 0.5, 0.0001, "day 15 sun factor should be 0.5 (SUNSET_DAY)")
	assert_near(power.get_sun_factor(16), 0.0, 0.0001, "day 16 sun factor should be 0.0 (night)")
	assert_near(power.get_sun_factor(30), 0.0, 0.0001, "day 30 sun factor should be 0.0 (night)")

func test_day_1_solar_generation_landing_dust() -> void:
	var sim: SimConstants = load_constants()
	var power: SimPower = SimPowerScript.new(sim)
	# 20 panels, no reactor, day 1 with landing dust (0.05) -> 456 kWh
	power.setup(20, 0, 0, 0.0)

	assert_near(power.dust, 0.05, 0.0001, "landing dust should default to DUST_LANDING (0.05)")
	var res: Dictionary = power.resolve(1)
	assert_near(float(res["solar_kwh"]), 456.0, 0.01, "solar generation day 1 with landing dust should be 456 kWh")
	assert_near(float(res["generation_kwh"]), 456.0, 0.01, "total generation should be 456 kWh")

func test_day_15_solar_generation_half() -> void:
	var sim: SimConstants = load_constants()
	var power: SimPower = SimPowerScript.new(sim)
	# 20 panels, no reactor, day 15 half sunlight -> 228 kWh
	power.setup(20, 0, 0, 0.0)

	var res: Dictionary = power.resolve(15)
	assert_near(float(res["solar_kwh"]), 228.0, 0.01, "solar generation day 15 should be half (228 kWh)")
	assert_near(float(res["generation_kwh"]), 228.0, 0.01, "total generation day 15 should be 228 kWh")

func test_night_two_reactors_serves_essential() -> void:
	var sim: SimConstants = load_constants()
	var power: SimPower = SimPowerScript.new(sim)
	# night (day 16), 0 panels, 2 reactors, 0 battery
	power.setup(0, 0, 2, 0.0)

	var res: Dictionary = power.resolve(16)
	var served: Dictionary = res["served"]
	assert_true(bool(served["core"]), "night with 2 reactors should serve core")
	assert_true(bool(served["water"]), "night with 2 reactors should serve water")
	assert_true(bool(served["food"]), "night with 2 reactors should serve food")
	assert_false(bool(res["blackout"]), "should not blackout with 2 reactors")
	assert_eq((res["shed"] as Array).size(), 0, "shed list should be empty")
	# 2 reactors = 20 kW * 24 = 480 kWh; essential = (5.260001 + 0.86 + 2.846667) * 24 = 215.2 kWh
	assert_near(float(res["generation_kwh"]), 480.0, 0.01, "2 reactors generate 480 kWh")

func test_night_ten_batteries_sheds_core_blackout() -> void:
	var sim: SimConstants = load_constants()
	var power: SimPower = SimPowerScript.new(sim)
	# night (day 16), 0 solar, 10 batteries (100 kWh), 0 reactors
	power.setup(0, 10, 0, 0.0)

	assert_near(power.capacity_kwh, 100.0, 0.01, "10 batteries should give 100 kWh capacity")
	assert_near(power.battery_kwh, 100.0, 0.01, "starting battery should be full at 100 kWh")

	var res: Dictionary = power.resolve(16)
	var served: Dictionary = res["served"]
	assert_false(bool(served["core"]), "core should be shed on 100 kWh supply (need is ~126.24 kWh)")
	assert_false(bool(served["water"]), "water should be shed after core is shed")
	assert_false(bool(served["food"]), "food should be shed after core is shed")
	assert_true(bool(res["blackout"]), "blackout should be true")
	assert_near(float(res["battery_after"]), 0.0, 0.0001, "battery should be drained to 0 on blackout")
	assert_near(power.battery_kwh, 0.0, 0.0001, "power.battery_kwh should update to 0")

	# hours_on_battery = supply_before_core / core_kW = 100.0 / 5.260001 ≈ 19.011 h
	assert_near(float(res["hours_on_battery"]), 100.0 / 5.260001, 0.05, "hours on battery should be ~19 h")
	var shed: Array = res["shed"]
	assert_true(shed.has("core"), "shed list must include core")
	assert_true(shed.has("water"), "shed list must include water")
	assert_true(shed.has("food"), "shed list must include food")

func test_battery_never_above_capacity() -> void:
	var sim: SimConstants = load_constants()
	var power: SimPower = SimPowerScript.new(sim)
	# 20 solar, 4 batteries (40 kWh capacity), 0 reactors, day 1
	# Gen = 456 kWh, essential load ≈ 215.2 kWh -> excess ~240.8 kWh
	power.setup(20, 4, 0, 0.0)
	assert_near(power.capacity_kwh, 40.0, 0.01, "capacity should be 40 kWh")

	var res: Dictionary = power.resolve(1)
	assert_near(float(res["battery_after"]), 40.0, 0.0001, "battery_after should not exceed capacity (40 kWh)")
	assert_near(power.battery_kwh, 40.0, 0.0001, "power.battery_kwh should not exceed capacity")

func test_shedding_stops_lower_systems_once_shed() -> void:
	var sim: SimConstants = load_constants()
	var power: SimPower = SimPowerScript.new(sim)
	# Night, no solar, no reactor.
	# Core need ≈ 126.24 kWh.
	# Water need ≈ 20.64 kWh.
	# Food need ≈ 68.32 kWh.
	# If we have 14 batteries (140 kWh):
	# Core (126.24) is served -> left = 13.76 kWh.
	# Water needs 20.64 > 13.76 -> water cannot be served!
	# Water is shed, partial use drains supply to 0, food is also shed!
	power.setup(0, 14, 0, 0.0)

	var res: Dictionary = power.resolve(16)
	var served: Dictionary = res["served"]
	assert_true(bool(served["core"]), "core should be served with 140 kWh")
	assert_false(bool(served["water"]), "water should be shed when supply is 13.76 kWh")
	assert_false(bool(served["food"]), "food should be shed after water is shed")
	assert_false(bool(res["blackout"]), "core was served so blackout is false")
	assert_near(float(res["battery_after"]), 0.0, 0.0001, "battery should be drained to 0 after partial use")

	var shed: Array = res["shed"]
	assert_false(shed.has("core"), "core was served so not in shed")
	assert_true(shed.has("water"), "water must be in shed list")
	assert_true(shed.has("food"), "food must be in shed list")

func test_setup_from_cargo() -> void:
	var sim: SimConstants = load_constants()
	var cargo: SimCargo = SimCargoScript.new(sim)
	cargo.set_count("solar", 24)
	cargo.set_count("battery", 6)
	cargo.set_count("reactor", 2)
	cargo.set_count("greenhouse", 10)

	var power: SimPower = SimPowerScript.new(sim, cargo)
	assert_eq(power.solar_panels, 24, "solar panels should be 24")
	assert_eq(power.reactors, 2, "reactors should be 2")
	assert_near(power.capacity_kwh, 60.0, 0.01, "capacity should be 60 kWh")
	assert_near(power.battery_kwh, 60.0, 0.01, "battery should be full at 60 kWh")
	assert_near(power.greenhouse_area, 10.0, 0.01, "greenhouse area should be 10 m²")

func test_broken_panels_reduce_generation() -> void:
	var sim: SimConstants = load_constants()
	var power: SimPower = SimPowerScript.new(sim)
	power.setup(20, 0, 0, 0.0)
	power.broken_panels = 2
	# 18 working panels * 1 kW * 24 h * 1.0 * (1 - 0.05) = 18 * 24 * 0.95 = 410.4 kWh
	var res: Dictionary = power.resolve(1)
	assert_near(float(res["solar_kwh"]), 410.4, 0.01, "2 broken panels should reduce generation to 410.4 kWh")

