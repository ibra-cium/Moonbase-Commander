class_name PackScreen
extends Control

signal launch_requested(cargo: SimCargo)

const LANDER_SCENE: PackedScene = preload("res://assets/models/kaykit/lander_B.gltf")
const CRATES_SCENE: PackedScene = preload("res://assets/models/kaykit/cargo_A_packed.gltf")

const ICON_SOLAR: Texture2D = preload("res://assets/icons/bolt.svg")
const ICON_BATTERY: Texture2D = preload("res://assets/icons/bolt.svg")
const ICON_REACTOR: Texture2D = preload("res://assets/icons/science.svg")
const ICON_GREENHOUSE: Texture2D = preload("res://assets/icons/eco.svg")
const ICON_O2: Texture2D = preload("res://assets/icons/air.svg")
const ICON_WATER: Texture2D = preload("res://assets/icons/water_drop.svg")
const ICON_FOOD: Texture2D = preload("res://assets/icons/restaurant.svg")
const ICON_SHIELD: Texture2D = preload("res://assets/icons/shield.svg")
const ICON_WARN: Texture2D = preload("res://assets/icons/warning.svg")
const ICON_BOLT: Texture2D = preload("res://assets/icons/bolt.svg")
const ICON_LOCK: Texture2D = preload("res://assets/icons/lock.svg")

const SimMissionsScript := preload("res://sim/sim_missions.gd")

var cargo: SimCargo

var title_label: Label
var subtitle_label: Label
var cargo_bar_label: Label
var cargo_progress_bar: ProgressBar
var source_tag_limit: SourceTag

var card_solar: PackItemCard
var card_battery: PackItemCard
var card_reactor: PackItemCard
var card_greenhouse: PackItemCard
var card_o2: PackItemCard
var card_water: PackItemCard
var card_food: PackItemCard
var card_shield: PackItemCard

var preview_viewport: SubViewport
var lander_pivot: Node3D
var crates_node: Node3D

var warnings_title: Label
var warn_food_row: HBoxContainer
var warn_food_icon: TextureRect
var warn_food_label: Label
var source_tag_food: SourceTag

var warn_water_row: HBoxContainer
var warn_water_icon: TextureRect
var warn_water_label: Label
var source_tag_water: SourceTag

var warn_night_row: HBoxContainer
var warn_night_icon: TextureRect
var warn_night_label: Label
var source_tag_night: SourceTag

var launch_button: Button

var _cards: Dictionary = {}
var _is_initialized: bool = false
var _sim_missions: SimMissions = null

func _ensure_nodes() -> void:
	if launch_button != null:
		return

	title_label = get_node_or_null("Margin/VBox/TopBar/TitleVBox/TitleLabel")
	subtitle_label = get_node_or_null("Margin/VBox/TopBar/TitleVBox/SubtitleLabel")
	cargo_bar_label = get_node_or_null("Margin/VBox/TopBar/CargoBarHBox/BarVBox/CargoBarLabel")
	cargo_progress_bar = get_node_or_null("Margin/VBox/TopBar/CargoBarHBox/BarVBox/ProgressBar")
	source_tag_limit = get_node_or_null("Margin/VBox/TopBar/CargoBarHBox/SourceTagLimit")

	card_solar = get_node_or_null("Margin/VBox/BodyHBox/CatalogScroll/CatalogVBox/CardSolar")
	card_battery = get_node_or_null("Margin/VBox/BodyHBox/CatalogScroll/CatalogVBox/CardBattery")
	card_reactor = get_node_or_null("Margin/VBox/BodyHBox/CatalogScroll/CatalogVBox/CardReactor")
	card_greenhouse = get_node_or_null("Margin/VBox/BodyHBox/CatalogScroll/CatalogVBox/CardGreenhouse")
	card_o2 = get_node_or_null("Margin/VBox/BodyHBox/CatalogScroll/CatalogVBox/CardO2")
	card_water = get_node_or_null("Margin/VBox/BodyHBox/CatalogScroll/CatalogVBox/CardWater")
	card_food = get_node_or_null("Margin/VBox/BodyHBox/CatalogScroll/CatalogVBox/CardFood")
	card_shield = get_node_or_null("Margin/VBox/BodyHBox/CatalogScroll/CatalogVBox/CardShield")

	_cards = {
		"solar": card_solar,
		"battery": card_battery,
		"reactor": card_reactor,
		"greenhouse": card_greenhouse,
		"o2": card_o2,
		"water": card_water,
		"food": card_food,
		"shield": card_shield
	}

	preview_viewport = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/PreviewPanel/SubViewportContainer/SubViewport")
	lander_pivot = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/PreviewPanel/SubViewportContainer/SubViewport/LanderPivot")

	warnings_title = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarningsTitle")

	warn_food_row = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnFoodRow")
	warn_food_icon = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnFoodRow/Icon")
	warn_food_label = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnFoodRow/Label")
	source_tag_food = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnFoodRow/SourceTagFood")

	warn_water_row = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnWaterRow")
	warn_water_icon = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnWaterRow/Icon")
	warn_water_label = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnWaterRow/Label")
	source_tag_water = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnWaterRow/SourceTagWater")

	warn_night_row = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnNightRow")
	warn_night_icon = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnNightRow/Icon")
	warn_night_label = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnNightRow/Label")
	source_tag_night = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/WarningsPanel/Margin/VBox/WarnNightRow/SourceTagNight")

	launch_button = get_node_or_null("Margin/VBox/BodyHBox/RightVBox/LaunchButton")

const SafeArea := preload("res://ui/safe_area.gd")

func _ready() -> void:
	_ensure_nodes()
	_setup_3d_preview()
	_setup_cards()

	if source_tag_limit:
		source_tag_limit.setup("CARGO_LIMIT_KG")
	if source_tag_food:
		source_tag_food.setup("FOOD_PACKED_KG_PERSON_DAY")
	if source_tag_water:
		source_tag_water.setup("WATER_RECOVERY_FULL")
	if source_tag_night:
		source_tag_night.setup("NIGHT_HOURS")

	if launch_button and not launch_button.pressed.is_connected(_on_launch_pressed):
		launch_button.pressed.connect(_on_launch_pressed)
	if launch_button and not launch_button.gui_input.is_connected(_on_launch_button_gui_input):
		launch_button.gui_input.connect(_on_launch_button_gui_input)

	if Settings != null and Settings.has_signal("language_changed"):
		if not Settings.language_changed.is_connected(_on_language_changed):
			Settings.language_changed.connect(_on_language_changed)

	reset_to_initial_or_last()
	_is_initialized = true
	_apply_safe_area()
	SafeArea.connect_resize(self, _apply_safe_area)

func _apply_safe_area() -> void:
	var insets: Dictionary = SafeArea.get_insets(self)
	var margin := get_node_or_null("Margin") as MarginContainer
	SafeArea.apply_margin(margin, 16, 16, 16, 16, insets)

func _process(delta: float) -> void:
	if lander_pivot:
		lander_pivot.rotate_y(delta * 0.25)

func _setup_3d_preview() -> void:
	if lander_pivot == null:
		return
	for child in lander_pivot.get_children():
		child.queue_free()

	if LANDER_SCENE:
		var lander_node: Node3D = LANDER_SCENE.instantiate() as Node3D
		lander_pivot.add_child(lander_node)

	if CRATES_SCENE:
		crates_node = CRATES_SCENE.instantiate() as Node3D
		crates_node.position = Vector3(1.1, 0.0, 0.5)
		lander_pivot.add_child(crates_node)

func _get_sim_missions() -> SimMissions:
	if _sim_missions == null and Constants != null and Constants.sim != null:
		_sim_missions = SimMissionsScript.new(Constants.sim)
	return _sim_missions

func _get_sim_constants() -> SimConstants:
	var mission_id: String = Settings.current_mission_id if Settings != null else "M4"
	var sm := _get_sim_missions()
	if sm != null:
		return sm.get_sim_constants(mission_id)
	if Constants != null and "sim" in Constants and Constants.sim != null:
		return Constants.sim
	return null

func _get_mission_days() -> int:
	var sim_c := _get_sim_constants()
	if sim_c != null:
		return int(sim_c.v("MISSION_DAYS"))
	return 30

func _setup_single_card(
	card: PackItemCard,
	key: String,
	name_key: String,
	icon: Texture2D,
	dummy_cargo: SimCargo,
	hidden_items: Array,
	locked_items: Dictionary,
	is_gh: bool = false,
	gh_opts: Array = []
) -> void:
	if card == null:
		return
	var max_u: int = dummy_cargo.max_units(key)
	card.setup(key, name_key, dummy_cargo.unit_mass(key), icon, max_u, is_gh, gh_opts)
	if not card.count_changed.is_connected(_on_card_count_changed):
		card.count_changed.connect(_on_card_count_changed)
	card.visible = not (key in hidden_items)
	if key in locked_items:
		card.set_locked(int(locked_items[key]), "")
	else:
		card.set_locked(-1, "")

func _setup_cards() -> void:
	_ensure_nodes()
	var sim_c = _get_sim_constants()
	if sim_c == null:
		return

	var mission_id: String = Settings.current_mission_id if Settings != null else "M4"
	var sm := _get_sim_missions()
	var hidden_items: Array = sm.get_hidden_items(mission_id) if sm != null else []
	var locked_items: Dictionary = sm.get_locked_items(mission_id) if sm != null else {}

	var dummy_cargo := SimCargo.new(sim_c)
	var gh_opts: Array = sim_c.v("GREENHOUSE_SIZE_OPTIONS_M2")

	_setup_single_card(card_solar, "solar", "PACK_ITEM_SOLAR", ICON_SOLAR, dummy_cargo, hidden_items, locked_items)
	_setup_single_card(card_battery, "battery", "PACK_ITEM_BATTERY", ICON_BATTERY, dummy_cargo, hidden_items, locked_items)
	_setup_single_card(card_reactor, "reactor", "PACK_ITEM_REACTOR", ICON_REACTOR, dummy_cargo, hidden_items, locked_items)
	_setup_single_card(card_greenhouse, "greenhouse", "PACK_ITEM_GREENHOUSE", ICON_GREENHOUSE, dummy_cargo, hidden_items, locked_items, true, gh_opts)
	_setup_single_card(card_o2, "o2", "PACK_ITEM_O2", ICON_O2, dummy_cargo, hidden_items, locked_items)
	_setup_single_card(card_water, "water", "PACK_ITEM_WATER", ICON_WATER, dummy_cargo, hidden_items, locked_items)
	_setup_single_card(card_food, "food", "PACK_ITEM_FOOD", ICON_FOOD, dummy_cargo, hidden_items, locked_items)
	_setup_single_card(card_shield, "shield", "PACK_ITEM_SHIELD", ICON_SHIELD, dummy_cargo, hidden_items, locked_items)

func reset_to_initial_or_last() -> void:
	_ensure_nodes()
	# Re-setup cards for the current mission (hides/locks items)
	_setup_cards()

	var sim_c = _get_sim_constants()
	var mission_id: String = Settings.current_mission_id if Settings != null else "M4"
	var sm := _get_sim_missions()

	if GameState != null and GameState.last_cargo != null:
		cargo = GameState.last_cargo.clone()
		# Migrate cargo to mission's SimConstants if needed
		if sim_c != null and cargo.has_method("set_sim_constants"):
			cargo.set_sim_constants(sim_c)
		elif sim_c != null:
			# Rebuild with correct constants
			var rebuilt := SimCargo.new(sim_c)
			for key in ["solar", "battery", "reactor", "greenhouse", "o2", "water", "food", "shield"]:
				rebuilt.set_count(key, cargo.get_count(key))
			cargo = rebuilt
	else:
		cargo = SimCargo.new(sim_c)

	# Apply locked item counts to cargo
	var locked_items: Dictionary = sm.get_locked_items(mission_id) if sm != null else {}
	for key in locked_items.keys():
		cargo.set_count(str(key), int(locked_items[key]))

	_sync_ui_from_cargo()

func set_cargo(p_cargo: SimCargo) -> void:
	cargo = p_cargo.clone()
	_sync_ui_from_cargo()

func load_cargo_dict(dict: Dictionary) -> void:
	var sim_c := _get_sim_constants()
	if cargo == null:
		cargo = SimCargo.new(sim_c)
	cargo.load_dict(dict)
	_sync_ui_from_cargo()

func get_current_cargo() -> SimCargo:
	return cargo

func _on_card_count_changed(key: String, count: int) -> void:
	if cargo == null:
		return
	# Don't allow changing locked items
	var mission_id: String = Settings.current_mission_id if Settings != null else "M4"
	var sm := _get_sim_missions()
	var locked_items: Dictionary = sm.get_locked_items(mission_id) if sm != null else {}
	if key in locked_items:
		# Revert – locked
		return
	cargo.set_count(key, count)
	_refresh_all()

func _sync_ui_from_cargo() -> void:
	if cargo == null:
		return
	for key in _cards.keys():
		var card: PackItemCard = _cards[key]
		if card:
			card.set_count(cargo.get_count(key))
	_refresh_all()

func _refresh_all() -> void:
	if cargo == null:
		return
	_update_cargo_bar()
	_update_warnings()
	_update_3d_preview()
	_update_launch_button()
	_update_texts()

func _update_cargo_bar() -> void:
	if cargo_progress_bar == null or cargo_bar_label == null:
		return
	var sim_c = _get_sim_constants()
	if sim_c == null:
		return

	var limit_kg: float = float(sim_c.v("CARGO_LIMIT_KG"))
	var total_mass: float = cargo.total_mass()

	cargo_progress_bar.max_value = limit_kg
	cargo_progress_bar.value = minf(total_mass, limit_kg)

	cargo_bar_label.text = tr("PACK_CARGO_BAR_LABEL") + ": %d / %d kg" % [int(round(total_mass)), int(round(limit_kg))]

	if total_mass > limit_kg:
		cargo_bar_label.modulate = UIColors.ALERT
	else:
		cargo_bar_label.modulate = UIColors.TEXT

func _update_warnings() -> void:
	if cargo == null:
		return
	var warnings: Array[Dictionary] = cargo.get_warnings()
	for w in warnings:
		var code: String = w.get("code", "")
		var vals: Dictionary = w.get("values", {})
		var is_warn: bool = vals.get("is_warning", false)

		match code:
			"WARN_FOOD":
				if warn_food_label and warn_food_icon:
					var days_n: float = float(vals.get("n", 0.0))
					warn_food_label.text = tr("WARN_FOOD").format({"n": days_n})
					if is_warn:
						warn_food_label.modulate = UIColors.ALERT
						warn_food_icon.texture = ICON_WARN
						warn_food_icon.modulate = UIColors.ALERT
					else:
						warn_food_label.modulate = UIColors.OXYGEN
						warn_food_icon.texture = ICON_FOOD
						warn_food_icon.modulate = UIColors.OXYGEN
			"WARN_WATER":
				if warn_water_label and warn_water_icon:
					var days_n: float = float(vals.get("n", 0.0))
					warn_water_label.text = tr("WARN_WATER").format({"n": days_n})
					if is_warn:
						warn_water_label.modulate = UIColors.ALERT
						warn_water_icon.texture = ICON_WARN
						warn_water_icon.modulate = UIColors.ALERT
					else:
						warn_water_label.modulate = UIColors.WATER
						warn_water_icon.texture = ICON_WATER
						warn_water_icon.modulate = UIColors.WATER
			"WARN_NIGHT_ENERGY":
				# Hide night-energy warning for missions that end before night
				var mission_days: int = _get_mission_days()
				var sunset_day: int = int(Constants.v("SUNSET_DAY")) if Constants != null else 15
				if warn_night_row:
					warn_night_row.visible = mission_days >= sunset_day
				if mission_days >= sunset_day and warn_night_label and warn_night_icon:
					var have_val: float = float(vals.get("have", 0))
					var need_val: float = float(vals.get("need", 0))
					warn_night_label.text = tr("WARN_NIGHT_ENERGY").format({
						"have": int(round(have_val)),
						"need": int(round(need_val))
					})
					if is_warn:
						warn_night_label.modulate = UIColors.ALERT
						warn_night_icon.texture = ICON_WARN
						warn_night_icon.modulate = UIColors.ALERT
					else:
						warn_night_label.modulate = UIColors.POWER
						warn_night_icon.texture = ICON_BOLT
						warn_night_icon.modulate = UIColors.POWER

func _update_3d_preview() -> void:
	if crates_node == null:
		return
	var sim_c = _get_sim_constants()
	if sim_c == null:
		return

	var current_mass: float = cargo.total_mass()
	var limit_kg: float = float(sim_c.v("CARGO_LIMIT_KG"))

	if current_mass <= 0.0:
		crates_node.visible = false
	else:
		crates_node.visible = true
		var fraction: float = clampf(current_mass / limit_kg, 0.2, 1.2)
		crates_node.scale = Vector3(fraction, fraction, fraction)

func _update_launch_button() -> void:
	if launch_button == null or cargo == null:
		return
	var sim_c = _get_sim_constants()
	if sim_c == null:
		return

	var is_valid: bool = cargo.is_valid()
	var total_mass: float = cargo.total_mass()
	var limit_kg: float = float(sim_c.v("CARGO_LIMIT_KG"))

	if not is_valid:
		launch_button.disabled = true
		if total_mass > limit_kg:
			launch_button.text = tr("PACK_ERR_OVERWEIGHT").format({
				"mass": int(round(total_mass)),
				"limit": int(round(limit_kg))
			})
		else:
			launch_button.text = tr("PACK_ERR_INVALID")
	else:
		launch_button.disabled = false
		launch_button.text = tr("PACK_LAUNCH")

func _update_texts() -> void:
	if title_label:
		title_label.text = tr("PACK_TITLE")
	if subtitle_label:
		subtitle_label.text = tr("PACK_SUBTITLE")
	if warnings_title:
		warnings_title.text = tr("PACK_WARNINGS_TITLE")

func _on_launch_pressed() -> void:
	if cargo == null or not cargo.is_valid():
		_play_audio("ui_error")
		return
	_play_audio("ui_confirm")
	if GameState != null:
		GameState.last_cargo = cargo.clone()
	launch_requested.emit(cargo)

func _on_launch_button_gui_input(event: InputEvent) -> void:
	if launch_button != null and launch_button.disabled:
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed):
			_play_audio("ui_error")

func _play_audio(sound_name: String) -> void:
	if Audio != null:
		Audio.play(sound_name)

func _on_language_changed(_new_lang: String) -> void:
	_refresh_all()

