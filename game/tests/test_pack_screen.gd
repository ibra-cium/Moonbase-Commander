extends "res://tests/test_case.gd"

const PackScreenScene: PackedScene = preload("res://ui/PackScreen.tscn")
const PackScreenScript := preload("res://ui/pack_screen.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")

func test_pack_screen_instantiation_and_nodes() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var pack = PackScreenScene.instantiate()
	root.add_child(pack)
	pack._ready()

	assert_true(pack != null, "PackScreen must instantiate")
	assert_true(pack.launch_button != null, "Launch button must exist")
	assert_true(pack.card_solar != null, "Card solar must exist")
	assert_true(pack.card_battery != null, "Card battery must exist")
	assert_true(pack.card_reactor != null, "Card reactor must exist")
	assert_true(pack.card_greenhouse != null, "Card greenhouse must exist")
	assert_true(pack.card_o2 != null, "Card o2 must exist")
	assert_true(pack.card_water != null, "Card water must exist")
	assert_true(pack.card_food != null, "Card food must exist")
	assert_true(pack.card_shield != null, "Card shield must exist")

	assert_true(pack.source_tag_limit != null, "Limit source tag must exist")
	assert_true(pack.source_tag_food != null, "Food source tag must exist")
	assert_true(pack.source_tag_water != null, "Water source tag must exist")
	assert_true(pack.source_tag_night != null, "Night energy source tag must exist")

	assert_eq(pack.source_tag_limit.constant_id, "CARGO_LIMIT_KG", "Limit tag constant_id")
	assert_eq(pack.source_tag_food.constant_id, "FOOD_PACKED_KG_PERSON_DAY", "Food tag constant_id")
	assert_eq(pack.source_tag_water.constant_id, "WATER_RECOVERY_FULL", "Water tag constant_id")
	assert_eq(pack.source_tag_night.constant_id, "NIGHT_HOURS", "Night tag constant_id")

	# Touch target check: Launch button >= 64px, cards +/- buttons >= 64px
	assert_true(pack.launch_button.custom_minimum_size.y >= 64.0, "Launch button height must be >= 64px")
	assert_true(pack.card_solar.btn_minus.custom_minimum_size.x >= 64.0, "Minus button width >= 64px")
	assert_true(pack.card_solar.btn_minus.custom_minimum_size.y >= 64.0, "Minus button height >= 64px")
	assert_true(pack.card_solar.btn_plus.custom_minimum_size.x >= 64.0, "Plus button width >= 64px")
	assert_true(pack.card_solar.btn_plus.custom_minimum_size.y >= 64.0, "Plus button height >= 64px")

	root.remove_child(pack)
	pack.free()

func test_initial_state_empty_lander() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var pack: PackScreen = PackScreenScene.instantiate() as PackScreen
	root.add_child(pack)

	# Ensure last_cargo is cleared for first-run test
	GameState.last_cargo = null
	pack._ready()

	var cargo: SimCargo = pack.get_current_cargo()
	assert_true(cargo != null, "Cargo must be initialized")
	assert_near(cargo.total_mass(), 0.0, 0.001, "Initial lander must be empty (0 kg)")

	for key in SimCargoScript.ITEM_KEYS:
		assert_eq(cargo.get_count(key), 0, "Initial count for %s must be 0" % key)

	# In empty lander, food and water days are 0 < 30, so active warnings exist
	assert_true(cargo.has_warnings(), "Empty lander must have active warnings")

	# In empty lander, crates 3D node should not be visible
	if pack.crates_node != null:
		assert_false(pack.crates_node.visible, "Crates should be hidden when mass is 0")

	root.remove_child(pack)
	pack.free()

func test_item_increment_decrement_and_greenhouse() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var pack: PackScreen = PackScreenScene.instantiate() as PackScreen
	root.add_child(pack)
	GameState.last_cargo = null
	pack._ready()

	# Increment solar
	pack.card_solar._on_plus_pressed()
	assert_eq(pack.get_current_cargo().get_count("solar"), 1, "Solar should be 1 after plus pressed")
	assert_near(pack.get_current_cargo().total_mass(), 12.5, 0.1, "Solar unit mass is 12.5 kg")

	# Decrement solar back to 0
	pack.card_solar._on_minus_pressed()
	assert_eq(pack.get_current_cargo().get_count("solar"), 0, "Solar should be 0 after minus pressed")

	# Decrement solar at 0 should stay 0
	pack.card_solar._on_minus_pressed()
	assert_eq(pack.get_current_cargo().get_count("solar"), 0, "Solar should clamp at 0")

	# Greenhouse size cycle: 0 -> 5 -> 10 -> 20
	assert_eq(pack.card_greenhouse.get_count(), 0, "Greenhouse starts at 0")
	pack.card_greenhouse._on_plus_pressed()
	assert_eq(pack.card_greenhouse.get_count(), 5, "Greenhouse steps to 5 m²")
	assert_eq(pack.get_current_cargo().get_count("greenhouse"), 5, "Cargo greenhouse count matches")

	pack.card_greenhouse._on_plus_pressed()
	assert_eq(pack.card_greenhouse.get_count(), 10, "Greenhouse steps to 10 m²")

	pack.card_greenhouse._on_plus_pressed()
	assert_eq(pack.card_greenhouse.get_count(), 20, "Greenhouse steps to 20 m²")

	# Beyond 20 should stay 20
	pack.card_greenhouse._on_plus_pressed()
	assert_eq(pack.card_greenhouse.get_count(), 20, "Greenhouse clamped to max 20 m²")

	pack.card_greenhouse._on_minus_pressed()
	assert_eq(pack.card_greenhouse.get_count(), 10, "Greenhouse steps back to 10 m²")

	root.remove_child(pack)
	pack.free()

func test_s08_overweight_cannot_launch() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var pack: PackScreen = PackScreenScene.instantiate() as PackScreen
	root.add_child(pack)
	pack._ready()

	# S08 cargo: 40 solar, 60 battery, 3 reactor, 20 gh, 20 o2/water/food/shield
	var s08_dict := {
		"solar": 40,
		"battery": 60,
		"reactor": 3,
		"greenhouse": 20,
		"o2": 20,
		"water": 20,
		"food": 20,
		"shield": 20
	}
	pack.load_cargo_dict(s08_dict)

	var cargo: SimCargo = pack.get_current_cargo()
	assert_near(cargo.total_mass(), 15640.6, 1.0, "S08 mass is ~15641 kg")
	assert_false(cargo.is_valid(), "S08 cargo must be invalid")
	assert_true(pack.launch_button.disabled, "S08 cargo cannot launch (button disabled)")
	assert_true(pack.launch_button.text.contains("Overweight"), "Button text explains overweight: %s" % pack.launch_button.text)

	# Verify 3D crates are visible and scaled
	if pack.crates_node != null:
		assert_true(pack.crates_node.visible, "Crates must be visible for heavy cargo")
		assert_true(pack.crates_node.scale.x > 0.5, "Crates must be scaled up")

	root.remove_child(pack)
	pack.free()

func test_base_cargo_can_launch() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var pack: PackScreen = PackScreenScene.instantiate() as PackScreen
	root.add_child(pack)
	pack._ready()

	var base_dict := {
		"solar": 20,
		"battery": 4,
		"reactor": 2,
		"greenhouse": 0,
		"o2": 2,
		"water": 4,
		"food": 5,
		"shield": 10
	}
	pack.load_cargo_dict(base_dict)

	var cargo: SimCargo = pack.get_current_cargo()
	assert_near(cargo.total_mass(), 5342.54, 1.0, "Base cargo mass is ~5343 kg")
	assert_true(cargo.is_valid(), "Base cargo must be valid")
	assert_false(pack.launch_button.disabled, "Base cargo can launch (button enabled)")
	assert_eq(pack.launch_button.text, "Launch Mission", "Launch button says 'Launch Mission'")

	# Test launch request signal
	var received_cargo := [null]
	pack.launch_requested.connect(func(c: SimCargo): received_cargo[0] = c)
	pack._on_launch_pressed()

	assert_true(received_cargo[0] != null, "launch_requested signal emitted")
	assert_near(received_cargo[0].total_mass(), 5342.54, 1.0, "Emitted cargo matches")
	assert_true(GameState.last_cargo != null, "GameState.last_cargo saved")

	root.remove_child(pack)
	pack.free()

func test_warnings_change_live_and_match_sim_cargo() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var pack: PackScreen = PackScreenScene.instantiate() as PackScreen
	root.add_child(pack)
	GameState.last_cargo = null
	pack._ready()

	# Start with empty: food days = 0, water days = 0
	var sim_warnings: Array[Dictionary] = pack.get_current_cargo().get_warnings()
	assert_true(pack.warn_food_label.text.contains("0"), "Food warning text shows 0 days initially")
	assert_true(pack.warn_water_label.text.contains("0"), "Water warning text shows 0 days initially")

	# Add 5 food crates (= 35 days, since 1 crate = 7 days)
	pack.card_food.set_count(5)
	pack._on_card_count_changed("food", 5)

	var updated_cargo: SimCargo = pack.get_current_cargo()
	assert_near(updated_cargo.food_days(), 35.0, 0.1, "5 food crates = 35 days")
	assert_true(pack.warn_food_label.text.contains("35"), "Food label updated live to 35 days")

	# Add 4 water crates
	pack.card_water.set_count(4)
	pack._on_card_count_changed("water", 4)
	var expected_water_days: float = snappedf(updated_cargo.water_days(), 0.1)
	assert_true(pack.warn_water_label.text.contains(str(expected_water_days)), "Water label updated live to match SimCargo")

	root.remove_child(pack)
	pack.free()

func test_last_cargo_persistence() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root

	# Pre-populate GameState.last_cargo
	var saved_cargo := SimCargoScript.new(Constants.sim)
	saved_cargo.set_count("solar", 18)
	saved_cargo.set_count("food", 6)
	GameState.last_cargo = saved_cargo

	var pack: PackScreen = PackScreenScene.instantiate() as PackScreen
	root.add_child(pack)
	pack._ready()

	# Should restore solar 18 and food 6
	assert_eq(pack.get_current_cargo().get_count("solar"), 18, "Solar count restored from last_cargo")
	assert_eq(pack.get_current_cargo().get_count("food"), 6, "Food count restored from last_cargo")
	assert_eq(pack.card_solar.get_count(), 18, "Card solar reflects restored count")
	assert_eq(pack.card_food.get_count(), 6, "Card food reflects restored count")

	# Clean up
	GameState.last_cargo = null
	root.remove_child(pack)
	pack.free()
