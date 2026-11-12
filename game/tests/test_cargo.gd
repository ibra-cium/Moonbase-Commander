extends "res://tests/test_case.gd"

const SimCargoScript := preload("res://sim/sim_cargo.gd")

func _create_base_cargo(sim: SimConstants) -> Object:
	var cargo: Object = SimCargoScript.new(sim)
	cargo.load_dict({
		"solar": 20,
		"battery": 4,
		"reactor": 2,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 5,
		"shield": 10
	})
	return cargo

func test_base_cargo_mass_and_validity() -> void:
	var sim: SimConstants = load_constants()
	var cargo: Object = _create_base_cargo(sim)

	# GAME_RULES §10: base cargo mass ≈ 5343 kg (exact: 5342.54 kg)
	var mass: float = cargo.total_mass()
	assert_near(mass, 5342.54, 1.0, "Base cargo mass should be ~5343 kg")
	assert_true(cargo.is_valid(), "Base cargo should be valid")

func test_s08_overweight() -> void:
	var sim: SimConstants = load_constants()
	var cargo: Object = SimCargoScript.new(sim)
	# S08 from GAME_RULES §10: 40 solar, 60 battery, 3 reactor, 20 gh, 20 o2/water/food/shield
	cargo.load_dict({
		"solar": 40,
		"battery": 60,
		"reactor": 3,
		"greenhouse": 20,
		"o2": 20,
		"water": 20,
		"food": 20,
		"shield": 20
	})

	var mass: float = cargo.total_mass()
	assert_near(mass, 15640.6, 1.0, "S08 cargo mass should be ~15641 kg")
	assert_true(not cargo.is_valid(), "S08 cargo should be invalid because mass > CARGO_LIMIT_KG")

func test_greenhouse_size_options_and_invalid_area() -> void:
	var sim: SimConstants = load_constants()
	var cargo: Object = _create_base_cargo(sim)

	# 7 m² is not in GREENHOUSE_SIZE_OPTIONS_M2 [0, 5, 10, 20]
	cargo.set_count("greenhouse", 7)
	assert_eq(cargo.get_count("greenhouse"), 7, "Greenhouse area count should be set to 7")
	assert_true(not cargo.is_valid(), "Greenhouse 7 m² should make cargo invalid")

	# Valid size 10 m²
	cargo.set_count("greenhouse", 10)
	assert_eq(cargo.get_count("greenhouse"), 10, "Greenhouse area count should be set to 10")
	assert_true(cargo.is_valid(), "Greenhouse 10 m² should be valid")

func test_night_energy_need_and_essential_kw() -> void:
	var sim: SimConstants = load_constants()
	var cargo: Object = _create_base_cargo(sim)

	# Essential load: core + water + food ≈ 8.97 kW
	var essential: float = cargo.essential_kw()
	assert_near(essential, 8.9667, 0.05, "Essential load should be ~8.97 kW")

	# Night need: essential_kw × NIGHT_HOURS ≈ 3178 kWh
	var need: float = cargo.night_energy_need_kwh()
	assert_near(need, 3177.49, 2.0, "Night energy need should be ~3178 kWh")

	# Night have for base: 4 batteries (40 kWh) + 2 reactors (20 kW * 354.3672 h = 7087.34 kWh) ≈ 7127.34 kWh
	var have: float = cargo.night_energy_have_kwh()
	assert_near(have, 7127.34, 2.0, "Night energy have for base cargo should be ~7127 kWh")
	assert_true(have > need, "Base cargo should have sufficient night energy")

func test_clamping() -> void:
	var sim: SimConstants = load_constants()
	var cargo: Object = SimCargoScript.new(sim)

	# Solar limit clamp: max 40, min 0
	cargo.set_count("solar", -10)
	assert_eq(cargo.get_count("solar"), 0, "Negative count should clamp to 0")
	cargo.set_count("solar", 100)
	assert_eq(cargo.get_count("solar"), 40, "Over-limit solar should clamp to 40")

	# Reactor limit clamp: max 3, min 0
	cargo.set_count("reactor", 10)
	assert_eq(cargo.get_count("reactor"), 3, "Over-limit reactor should clamp to 3")

	# Battery limit clamp: max 60, min 0
	cargo.set_count("battery", 999)
	assert_eq(cargo.get_count("battery"), 60, "Over-limit battery should clamp to 60")

	# Supplies limit clamp: max 20, min 0
	cargo.set_count("food", 50)
	assert_eq(cargo.get_count("food"), 20, "Over-limit food should clamp to 20")

	# Alias support: gh -> greenhouse
	cargo.set_count("gh", 5)
	assert_eq(cargo.get_count("greenhouse"), 5, "Setting 'gh' should set 'greenhouse'")

func test_summary_values() -> void:
	var sim: SimConstants = load_constants()
	var cargo: Object = _create_base_cargo(sim)

	# Base counts: solar 20, battery 4, reactor 2, gh 0, o2 2, water 4, food 5, shield 10
	assert_near(cargo.solar_kw(), 20.0, 0.01, "Solar kW should be 20 kW")
	assert_near(cargo.battery_kwh_capacity(), 40.0, 0.01, "Battery capacity should be 40 kWh")
	assert_near(cargo.reactor_kw(), 20.0, 0.01, "Reactor kW should be 20 kW")
	assert_near(cargo.o2_kg(), 50.0, 0.01, "O2 kg should be 50 kg (2 * 25)")
	assert_near(cargo.water_kg(), 180.0, 0.01, "Water kg should be 180 kg (4 * 45)")
	assert_near(cargo.food_kg(), 334.6, 0.01, "Food kg should be 334.6 kg (5 * 66.92)")
	assert_near(cargo.shelter_g_cm2(), 10.0, 0.01, "Shelter g/cm2 should be 10 g/cm2 (10 * 1)")

func test_pack_warnings() -> void:
	var sim: SimConstants = load_constants()
	var cargo: Object = _create_base_cargo(sim)

	# Food days for 5 crates: 5 * 7 days = 35 days (>= 30 days, not a warning)
	assert_near(cargo.food_days(), 35.0, 0.01, "5 food crates should cover 35 days")

	# Water days for 4 units (180 kg): 180 / 4.28486 ≈ 42.0 days (>= 30 days)
	assert_near(cargo.water_days(), 42.0, 0.1, "4 water units should cover ~42 days")

	var warnings: Array[Dictionary] = cargo.get_warnings()
	assert_eq(warnings.size(), 3, "get_warnings() should return 3 warning entries")

	var active: Array[Dictionary] = cargo.get_active_warnings()
	assert_eq(active.size(), 0, "Base cargo should have 0 active warnings")

	# Reduce food to 2 crates: covers 14 days (< 30 days) -> should trigger warning
	cargo.set_count("food", 2)
	assert_near(cargo.food_days(), 14.0, 0.01, "2 food crates should cover 14 days")
	var active_after: Array[Dictionary] = cargo.get_active_warnings()
	assert_eq(active_after.size(), 1, "Should have 1 active warning after reducing food")
	assert_eq(active_after[0]["code"], "WARN_FOOD", "Warning code should be WARN_FOOD")

func test_catalog_structure() -> void:
	var sim: SimConstants = load_constants()
	var cargo: Object = SimCargoScript.new(sim)
	var catalog: Array[Dictionary] = cargo.get_catalog()

	assert_eq(catalog.size(), 8, "Catalog should contain 8 item definitions")
	for entry in catalog:
		assert_true(entry.has("key"), "Entry missing 'key'")
		assert_true(entry.has("name_key"), "Entry missing 'name_key'")
		assert_true(entry.has("unit_mass"), "Entry missing 'unit_mass'")
		assert_true(entry.has("max_units"), "Entry missing 'max_units'")
		assert_true(entry.has("mass_id"), "Entry missing 'mass_id'")

