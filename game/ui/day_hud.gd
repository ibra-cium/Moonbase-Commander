class_name DayHud
extends Control

signal end_day_pressed
signal fast_toggled(enabled: bool)
signal plan_changed(plan: SimPlan)
signal crew_job_changed(crew_index: int, new_job: String)
signal crew_selected(crew_index: int)
signal menu_requested
signal science_card_notification_pressed(fact_id: String, is_quiet: bool)
signal science_card_notification_finished(fact_id: String, is_quiet: bool)

const SimPlanScript := preload("res://sim/sim_plan.gd")
const SafeArea := preload("res://ui/safe_area.gd")
const LearningDataScript := preload("res://ui/learning_data.gd")
const CrewCardScript := preload("res://ui/crew_card.gd")
const GaugeScript := preload("res://ui/gauge.gd")
const CollectBubbleScene: PackedScene = preload("res://ui/CollectBubble.tscn")
const CollectBubbleScript := preload("res://ui/collect_bubble.gd")
const BuildingMarkerScene: PackedScene = preload("res://ui/BuildingMarker.tscn")
const CrewTagButtonScene: PackedScene = preload("res://ui/CrewTagButton.tscn")
const BANNER_FEEDBACK_DURATION: float = 2.0
const CARD_TOAST_HOLD_SEC: float = 4.0
const CARD_QUIET_HOLD_SEC: float = 6.0
const ICON_ROCKET: Texture2D = preload("res://assets/icons/rocket_launch.svg")
const ICON_VOLUME_UP: Texture2D = preload("res://assets/icons/volume_up.svg")
const ICON_VOLUME_OFF: Texture2D = preload("res://assets/icons/volume_off.svg")
const ICON_SCIENCE: Texture2D = preload("res://assets/icons/science.svg")
const ICON_BOLT: Texture2D = preload("res://assets/icons/bolt.svg")
const ICON_SHIELD: Texture2D = preload("res://assets/icons/shield.svg")
const ICON_ECO: Texture2D = preload("res://assets/icons/eco.svg")
const ICON_AIR: Texture2D = preload("res://assets/icons/air.svg")
const ICON_CO2: Texture2D = preload("res://assets/icons/co2.svg")
const MAX_COLLECT_BUBBLES := 4
const SHELTER_ACCENT_COLOR := Color("9B51E0")
const BATTERY_GREEN_PERCENT: float = 50.0
const BATTERY_WARN_PERCENT: float = 30.0
const STORM_TWO_PIP_FRAC: float = 0.50
const STORM_THREE_PIP_FRAC: float = 0.25

# Top bar nodes
var day_label: Label
var sun_night_icon: TextureRect
var sun_night_label: Label
var res_science_pill: PanelContainer
var res_science_icon: TextureRect
var res_science_title: Label
var res_science_value: Label
var res_science_tag: SourceTag
var res_energy_pill: PanelContainer
var res_energy_icon: TextureRect
var res_energy_title: Label
var res_energy_value: Label
var res_energy_tag: SourceTag
var res_shelter_pill: PanelContainer
var res_shelter_icon: TextureRect
var res_shelter_title: Label
var res_shelter_value: Label
var res_shelter_tag: SourceTag
var fast_toggle: Button
var mute_btn: Button
var menu_btn: Button
var bubbles_layer: Control
var fly_layer: Control

# Left column gauges
var power_gauge: Gauge
var o2_gauge: Gauge
var co2_gauge: Gauge
var water_gauge: Gauge
var food_gauge: Gauge
var rad_gauge: Gauge
var shelter_gauge: Gauge

# Bottom bar crew cards
var crew_cards: Array[Node] = []

# Right controls
var greenhouse_switch: Button
var science_switch: Button
var status_label: Label
var end_day_button: Button

# Toast notification
var toast_panel: PanelContainer
var toast_line1: Label
var toast_line2: Label
var _toast_tween: Tween

# Science Card toast / Quiet-day chip
var _card_learning: LearningData = LearningDataScript.new()
var _card_toast_wrap: CenterContainer
var _card_toast_btn: Button
var _card_toast_icon: TextureRect
var _card_toast_badge: Label
var _card_toast_title: Label
var _card_toast_tween: Tween
var _card_toast_fact_id: String = ""
var _card_toast_is_quiet: bool = false
var _card_toast_style: StyleBoxFlat
var _card_pickup_hint: PanelContainer
var _card_pickup_tween: Tween
var select_banner_panel: PanelContainer
var select_banner_label: Label

# Pause menu popup
var pause_layer: CanvasLayer
var pause_backdrop: Control
var pause_title_label: Label
var pause_resume_btn: Button
var pause_sources_btn: Button
var pause_lang_btn: Button
var pause_science_btn: Button

# Tip bubble popup ("What should I do?")
var tip_panel: PanelContainer
var tip_label: Label
var tip_show_me_btn: Button
var tip_close_btn: Button
var _tip_style: StyleBoxFlat
var _active_tip_gauge_key: String = ""
var _active_tip_key: String = ""
var _active_tip_target: String = ""
var last_show_me_target: String = ""
var _greenhouse_pulse_tween: Tween = null

# Cached kid/science gauge state
var _last_report: RefCounted = null
var _prev_battery_pct: float = 100.0
var _battery_trend: String = "up"
var _last_battery_pct: float = 100.0
var _last_battery_kwh: float = 0.0
var _last_battery_cap_kwh: float = 0.0
var _last_battery_blackout: bool = false
var _last_o2_kg: float = 100.0
var _last_o2_days_left: float = 30.0
var _last_air_machine_off: bool = false
var _last_air_level: String = "good"
var _last_water_kg: float = 100.0
var _last_water_days_left: float = 30.0
var _last_recycler_broken: bool = false
var _last_food_kg: float = 100.0
var _last_food_days_left: float = 30.0
var _last_days_to_go: int = 30
var _last_rad_msv: float = 0.0
var _last_shelter_g: float = 0.0
var _last_storm_dose_if_now_msv: float = 0.0
var _last_storm_pips: int = 0

# State
var current_plan: SimPlan
var current_day: int = 1
var is_resolving: bool = false
var has_greenhouse: bool = false
var greenhouse_alive: bool = false
var max_o2_packed: float = 100.0
var max_water_packed: float = 100.0
var max_food_packed: float = 100.0
var _mission_total_days: int = 30  # mission's MISSION_DAYS (may differ from base constant)

var _sun_icon: Texture2D
var _night_icon: Texture2D
var _science_goal: int = 10
var _target_science: int = 0
var _displayed_science: int = 0
var _target_energy_today: int = 0
var _displayed_energy_today: int = 0
var _target_shelter_g: float = 0.0
var _displayed_shelter_g: float = 0.0
var _last_co2_mmhg: float = 0.5
var _active_bubbles: Array[Control] = []
var _science_pill_gold_style: StyleBoxFlat = null
var _science_pill_default_style: StyleBox = null
var packed_greenhouse: bool = false
var selected_crew_index: int = -1
var _base_ref: Node = null
var _crew_ref: Node = null
var _building_markers: Dictionary = {}
var _crew_tag_buttons: Array[Control] = []
var _banner_feedback_timer: float = 0.0

func _ensure_nodes() -> void:
	if end_day_button != null:
		return
	
	# Top bar
	day_label = get_node_or_null("TopBar/HBox/DayInfo/Margin/HBox/DayLabel")
	sun_night_icon = get_node_or_null("TopBar/HBox/DayInfo/Margin/HBox/SunNightIcon")
	sun_night_label = get_node_or_null("TopBar/HBox/DayInfo/Margin/HBox/SunNightLabel")
	res_science_pill = get_node_or_null("TopBar/HBox/ResourceBar/SciencePill")
	res_science_icon = get_node_or_null("TopBar/HBox/ResourceBar/SciencePill/HBox/IconRect")
	res_science_title = get_node_or_null("TopBar/HBox/ResourceBar/SciencePill/HBox/VBox/TitleLabel")
	res_science_value = get_node_or_null("TopBar/HBox/ResourceBar/SciencePill/HBox/VBox/ValueLabel")
	res_science_tag = get_node_or_null("TopBar/HBox/ResourceBar/SciencePill/HBox/SourceTag")
	res_energy_pill = get_node_or_null("TopBar/HBox/ResourceBar/EnergyPill")
	res_energy_icon = get_node_or_null("TopBar/HBox/ResourceBar/EnergyPill/HBox/IconRect")
	res_energy_title = get_node_or_null("TopBar/HBox/ResourceBar/EnergyPill/HBox/VBox/TitleLabel")
	res_energy_value = get_node_or_null("TopBar/HBox/ResourceBar/EnergyPill/HBox/VBox/ValueLabel")
	res_energy_tag = get_node_or_null("TopBar/HBox/ResourceBar/EnergyPill/HBox/SourceTag")
	res_shelter_pill = get_node_or_null("TopBar/HBox/ResourceBar/ShelterPill")
	res_shelter_icon = get_node_or_null("TopBar/HBox/ResourceBar/ShelterPill/HBox/IconRect")
	res_shelter_title = get_node_or_null("TopBar/HBox/ResourceBar/ShelterPill/HBox/VBox/TitleLabel")
	res_shelter_value = get_node_or_null("TopBar/HBox/ResourceBar/ShelterPill/HBox/VBox/ValueLabel")
	res_shelter_tag = get_node_or_null("TopBar/HBox/ResourceBar/ShelterPill/HBox/SourceTag")
	fast_toggle = get_node_or_null("TopBar/HBox/FastButton")
	mute_btn = get_node_or_null("TopBar/HBox/MuteButton")
	menu_btn = get_node_or_null("TopBar/HBox/MenuButton")
	bubbles_layer = get_node_or_null("BubblesLayer")
	fly_layer = get_node_or_null("FlyLayer")

	# Gauges
	power_gauge = get_node_or_null("LeftColumn/Gauges/PowerGauge")
	o2_gauge = get_node_or_null("LeftColumn/Gauges/O2Gauge")
	co2_gauge = get_node_or_null("LeftColumn/Gauges/CO2Gauge")
	water_gauge = get_node_or_null("LeftColumn/Gauges/WaterGauge")
	food_gauge = get_node_or_null("LeftColumn/Gauges/FoodGauge")
	rad_gauge = get_node_or_null("LeftColumn/Gauges/RadGauge")
	shelter_gauge = get_node_or_null("LeftColumn/Gauges/ShelterGauge")

	# Crew cards
	crew_cards.clear()
	for i in range(4):
		var card = get_node_or_null("BottomBar/HBox/CrewCard_%d" % i)
		if card != null:
			crew_cards.append(card)
			if card.has_method("setup"):
				card.setup(i)
			if card.has_signal("job_changed") and not card.job_changed.is_connected(_on_crew_card_job_changed):
				card.job_changed.connect(_on_crew_card_job_changed)
			if card.has_signal("card_selected") and not card.card_selected.is_connected(_on_crew_card_selected):
				card.card_selected.connect(_on_crew_card_selected)
			if card.has_signal("picker_opened") and not card.picker_opened.is_connected(_on_crew_card_picker_opened):
				card.picker_opened.connect(_on_crew_card_picker_opened)

	# Right controls
	greenhouse_switch = get_node_or_null("RightControls/VBox/GreenhouseSwitch")
	science_switch = get_node_or_null("RightControls/VBox/ScienceSwitch")
	status_label = get_node_or_null("RightControls/VBox/StatusLabel")
	end_day_button = get_node_or_null("RightControls/VBox/EndDayButton")

	# Toast
	toast_panel = get_node_or_null("ToastContainer/ToastPanel")
	if toast_panel != null:
		toast_line1 = toast_panel.get_node_or_null("Margin/VBox/Line1")
		toast_line2 = toast_panel.get_node_or_null("Margin/VBox/Line2")

	select_banner_panel = get_node_or_null("SelectBannerContainer/SelectBannerPanel")
	if select_banner_panel != null:
		select_banner_label = select_banner_panel.get_node_or_null("Margin/SelectBannerLabel")

	# Pause menu
	pause_layer = get_node_or_null("PauseMenuLayer")
	if pause_layer != null:
		pause_backdrop = pause_layer.get_node_or_null("Backdrop")
		pause_title_label = pause_layer.get_node_or_null("Center/Panel/Margin/VBox/Title") as Label
		pause_resume_btn = pause_layer.get_node_or_null("Center/Panel/Margin/VBox/ResumeBtn")
		pause_sources_btn = pause_layer.get_node_or_null("Center/Panel/Margin/VBox/SourcesBtn")
		pause_lang_btn = pause_layer.get_node_or_null("Center/Panel/Margin/VBox/LangBtn")
		pause_science_btn = pause_layer.get_node_or_null("Center/Panel/Margin/VBox/ScienceBtn")

func _ready() -> void:
	_ensure_nodes()
	_sun_icon = preload("res://assets/icons/wb_sunny.svg")
	_night_icon = preload("res://assets/icons/nightlight.svg")

	if current_plan == null:
		current_plan = SimPlanScript.new()

	# Connect buttons
	if end_day_button != null and not end_day_button.pressed.is_connected(_on_end_day_pressed):
		end_day_button.pressed.connect(_on_end_day_pressed)
	if fast_toggle != null and not fast_toggle.pressed.is_connected(_on_fast_button_pressed):
		fast_toggle.pressed.connect(_on_fast_button_pressed)
	if mute_btn != null and not mute_btn.pressed.is_connected(_on_mute_button_pressed):
		mute_btn.pressed.connect(_on_mute_button_pressed)
	if menu_btn != null and not menu_btn.pressed.is_connected(_on_menu_button_pressed):
		menu_btn.pressed.connect(_on_menu_button_pressed)

	if greenhouse_switch != null:
		if not greenhouse_switch.pressed.is_connected(_on_greenhouse_switch_pressed):
			greenhouse_switch.pressed.connect(_on_greenhouse_switch_pressed)
		if not greenhouse_switch.gui_input.is_connected(_on_greenhouse_switch_gui_input):
			greenhouse_switch.gui_input.connect(_on_greenhouse_switch_gui_input)
	if science_switch != null and not science_switch.pressed.is_connected(_on_science_switch_pressed):
		science_switch.pressed.connect(_on_science_switch_pressed)

	# Connect pause menu
	if pause_layer != null:
		pause_layer.visible = false
	if pause_backdrop != null and not pause_backdrop.gui_input.is_connected(_on_pause_backdrop_gui_input):
		pause_backdrop.gui_input.connect(_on_pause_backdrop_gui_input)
	if pause_resume_btn != null and not pause_resume_btn.pressed.is_connected(_close_pause_menu):
		pause_resume_btn.pressed.connect(_close_pause_menu)
	if pause_sources_btn != null and not pause_sources_btn.pressed.is_connected(_on_pause_sources_pressed):
		pause_sources_btn.pressed.connect(_on_pause_sources_pressed)
	if pause_lang_btn != null and not pause_lang_btn.pressed.is_connected(_on_pause_lang_pressed):
		pause_lang_btn.pressed.connect(_on_pause_lang_pressed)
	if pause_science_btn != null and not pause_science_btn.pressed.is_connected(_on_pause_science_pressed):
		pause_science_btn.pressed.connect(_on_pause_science_pressed)

	if status_label != null:
		status_label.visible = false
	if toast_panel != null:
		toast_panel.visible = false
	if select_banner_panel != null:
		select_banner_panel.visible = false
	if not visibility_changed.is_connected(_on_hud_visibility_changed):
		visibility_changed.connect(_on_hud_visibility_changed)

	if not Settings.fast_mode_changed.is_connected(_on_settings_fast_mode_changed):
		Settings.fast_mode_changed.connect(_on_settings_fast_mode_changed)
	if Settings.has_signal("sound_changed") and not Settings.sound_changed.is_connected(_on_settings_sound_changed):
		Settings.sound_changed.connect(_on_settings_sound_changed)
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)
	if Settings != null and Settings.has_signal("science_view_changed") and not Settings.science_view_changed.is_connected(_on_science_view_changed):
		Settings.science_view_changed.connect(_on_science_view_changed)

	# Wire crew cards
	for i in range(crew_cards.size()):
		var card: Node = crew_cards[i]
		card.setup(i)
		if not card.job_changed.is_connected(_on_crew_card_job_changed):
			card.job_changed.connect(_on_crew_card_job_changed)
		if card.has_signal("card_selected") and not card.card_selected.is_connected(_on_crew_card_selected):
			card.card_selected.connect(_on_crew_card_selected)
		if card.has_signal("picker_opened") and not card.picker_opened.is_connected(_on_crew_card_picker_opened):
			card.picker_opened.connect(_on_crew_card_picker_opened)

	_init_gauges()
	_refresh_language_texts()
	if science_switch != null:
		science_switch.visible = false
	set_day(1)
	apply_safe_area()
	SafeArea.connect_resize(self, apply_safe_area)

func apply_safe_area() -> void:
	var insets: Dictionary = SafeArea.get_insets(self)
	var l: int = int(insets.get("left", 0))
	var t: int = int(insets.get("top", 0))
	var r: int = int(insets.get("right", 0))
	var b: int = int(insets.get("bottom", 0))
	var top_bar := get_node_or_null("TopBar") as MarginContainer
	if top_bar != null:
		SafeArea.apply_margin(top_bar, 16, 6, 16, 0, {"left": l, "top": t, "right": r, "bottom": 0})
		top_bar.offset_bottom = 72.0 + float(t)
	var left_col := get_node_or_null("LeftColumn") as Control
	if left_col != null:
		left_col.offset_left = 16.0 + float(l)
		left_col.offset_right = 280.0 + float(l)
		left_col.offset_top = 75.0 + float(t)
		left_col.offset_bottom = -180.0 - float(b)
	var bottom_bar := get_node_or_null("BottomBar") as Control
	if bottom_bar != null:
		bottom_bar.offset_top = -112.0 - float(b)
		bottom_bar.offset_bottom = -14.0 - float(b)
	var right_ctrl := get_node_or_null("RightControls") as Control
	if right_ctrl != null:
		right_ctrl.offset_left = -226.0 - float(r)
		right_ctrl.offset_right = -16.0 - float(r)
		right_ctrl.offset_top = -225.0 - float(b)
		right_ctrl.offset_bottom = -14.0 - float(b)
	var toast_c := get_node_or_null("ToastContainer") as Control
	if toast_c != null:
		toast_c.offset_top = 75.0 + float(t)
		toast_c.offset_bottom = 140.0 + float(t)
	var banner_c := get_node_or_null("SelectBannerContainer") as Control
	if banner_c != null:
		banner_c.offset_top = 75.0 + float(t)
		banner_c.offset_bottom = 122.0 + float(t)
	_update_card_toast_position()

func _init_gauges() -> void:
	if power_gauge != null:
		power_gauge.gauge_key = "battery"
		power_gauge.setup(ICON_BOLT, "%", UIColors.OXYGEN, "BATTERY_UNIT_KWH", _tr_gauge_title("battery"))
		_wire_gauge_tap(power_gauge)
	if o2_gauge != null:
		o2_gauge.gauge_key = "o2"
		o2_gauge.setup(ICON_AIR, "kg", UIColors.OXYGEN, "O2_KG_PERSON_DAY", _tr_gauge_title("o2"))
		_wire_gauge_tap(o2_gauge)
	if co2_gauge != null:
		co2_gauge.gauge_key = "air"
		co2_gauge.setup(ICON_AIR, "mmHg", UIColors.OXYGEN, "CO2_LIMIT_MMHG", _tr_gauge_title("air"))
		_wire_gauge_tap(co2_gauge)
	if water_gauge != null:
		water_gauge.gauge_key = "water"
		water_gauge.setup(preload("res://assets/icons/water_drop.svg"), "kg", UIColors.OXYGEN, "WATER_KG_PERSON_DAY", _tr_gauge_title("water"))
		_wire_gauge_tap(water_gauge)
	if food_gauge != null:
		food_gauge.gauge_key = "food"
		food_gauge.setup(preload("res://assets/icons/restaurant.svg"), "d", UIColors.OXYGEN, "FOOD_PACKED_KG_PERSON_DAY", _tr_gauge_title("food"))
		_wire_gauge_tap(food_gauge)
	if rad_gauge != null:
		rad_gauge.gauge_key = "rad"
		rad_gauge.setup(preload("res://assets/icons/warning.svg"), "mSv", UIColors.OXYGEN, "RAD_HABITAT_MSV_DAY", _tr_gauge_title("rad"))
		_wire_gauge_tap(rad_gauge)
	if shelter_gauge != null:
		shelter_gauge.gauge_key = "storm"
		shelter_gauge.setup(ICON_SHIELD, "g/cm²", UIColors.OXYGEN, "RAD_SPE_LIMIT_MSV", _tr_gauge_title("storm"))
		_wire_gauge_tap(shelter_gauge)
	_apply_science_view()
	_init_resource_bar()

func _wire_gauge_tap(g: Gauge) -> void:
	if g != null and not g.gauge_tapped.is_connected(_on_gauge_tapped):
		g.gauge_tapped.connect(_on_gauge_tapped)

func _is_science_view() -> bool:
	return Settings != null and Settings.science_view

func _tr_gauge_title(gkey: String) -> String:
	var sci_on: bool = _is_science_view()
	match gkey:
		"battery":
			return tr("HUD_POWER") if sci_on else _tr_fallback("KID_BATTERY", "Battery")
		"o2":
			return tr("HUD_OXYGEN")
		"air":
			return tr("HUD_CO2") if sci_on else _tr_fallback("KID_AIR", "Air")
		"water":
			return tr("HUD_WATER")
		"food":
			return tr("HUD_FOOD")
		"rad":
			return tr("HUD_RADIATION")
		"storm":
			return tr("HUD_SHELTER") if sci_on else _tr_fallback("KID_STORM_SAFETY", "Storm safety")
	return ""

func _refresh_gauge_titles() -> void:
	if power_gauge != null:
		power_gauge.set_title(_tr_gauge_title("battery"))
	if o2_gauge != null:
		o2_gauge.set_title(_tr_gauge_title("o2"))
	if co2_gauge != null:
		co2_gauge.set_title(_tr_gauge_title("air"))
	if water_gauge != null:
		water_gauge.set_title(_tr_gauge_title("water"))
	if food_gauge != null:
		food_gauge.set_title(_tr_gauge_title("food"))
	if rad_gauge != null:
		rad_gauge.set_title(_tr_gauge_title("rad"))
	if shelter_gauge != null:
		shelter_gauge.set_title(_tr_gauge_title("storm"))

func _apply_science_view() -> void:
	var sci_on: bool = _is_science_view()
	if o2_gauge != null:
		o2_gauge.visible = sci_on
	if rad_gauge != null:
		rad_gauge.visible = sci_on
	if co2_gauge != null:
		co2_gauge.icon_texture = ICON_CO2 if sci_on else ICON_AIR
	_refresh_gauge_titles()
	_render_all_gauges()
	for card in crew_cards:
		if card != null and card.has_method("_refresh_display"):
			card.call("_refresh_display")
	_refresh_tip_bubble_texts()
	_update_pause_menu_texts()

func _init_resource_bar() -> void:
	_science_goal = int(Constants.v("SCIENCE_GOAL_POINTS")) if Constants != null else 0
	if res_science_title != null:
		res_science_title.text = _tr_fallback("RES_SCIENCE", "Science")
	if res_science_tag != null:
		res_science_tag.setup("SCIENCE_GOAL_POINTS")
	if res_energy_title != null:
		res_energy_title.text = _tr_fallback("RES_ENERGY", "Energy today")
	if res_energy_tag != null:
		res_energy_tag.setup("SOLAR_UNIT_KW")
	if res_shelter_title != null:
		res_shelter_title.text = _tr_fallback("RES_SHELTER", "Shelter")
	if res_shelter_tag != null:
		res_shelter_tag.setup("SHIELD_GOAL_G_CM2")
	_refresh_resource_bar()
	_update_co2_status_word(_last_co2_mmhg)

func setup_mission(mission: RefCounted) -> void:
	_ensure_nodes()
	if mission == null:
		return
	
	current_plan = SimPlanScript.new()
	# Cache the mission's total days for the HUD display
	if mission.has_method("get_total_days"):
		_mission_total_days = int(mission.get_total_days())
	elif mission.get("_c") != null:
		var mc = mission.get("_c")
		_mission_total_days = int(mc.v("MISSION_DAYS")) if mc.has("MISSION_DAYS") else 30
	else:
		_mission_total_days = int(Constants.v("MISSION_DAYS")) if Constants != null else 30
	set_day(mission.day if "day" in mission else 1, _mission_total_days)

	var cargo = mission.cargo
	if cargo != null:
		var o2_tanks: int = cargo.get_count("o2") if cargo.has_method("get_count") else 0
		var water_tanks: int = cargo.get_count("water") if cargo.has_method("get_count") else 0
		var food_crates: int = cargo.get_count("food") if cargo.has_method("get_count") else 0
		var gh_count: int = cargo.get_count("greenhouse") if cargo.has_method("get_count") else 0

		var o2_unit: float = float(Constants.v("O2_UNIT_KG"))
		var water_unit: float = float(Constants.v("WATER_UNIT_KG"))
		var food_unit: float = float(Constants.v("FOOD_CRATE_MASS_KG"))

		max_o2_packed = maxf(1.0, o2_tanks * o2_unit)
		max_water_packed = maxf(1.0, water_tanks * water_unit)
		max_food_packed = maxf(1.0, food_crates * food_unit)
		has_greenhouse = gh_count > 0
		packed_greenhouse = has_greenhouse
		greenhouse_alive = has_greenhouse
	else:
		has_greenhouse = false
		packed_greenhouse = false
		greenhouse_alive = false

	# Initial gauge values for Day 1
	var o2_initial: float = mission.life.o2_kg if mission.life else 100.0
	var water_initial: float = mission.life.water_kg if mission.life else 100.0
	var food_initial: float = mission.life.food_kg if mission.life else 100.0
	var shelter_initial: float = mission.shelter_g_cm2
	var bat_cap: float = mission.power.capacity_kwh if mission.power else 100.0
	var bat_kwh: float = mission.power.battery_kwh if mission.power else bat_cap
	var crew_cnt: int = maxi(1, crew_cards.size() if not crew_cards.is_empty() else 4)
	if mission.crew != null and "members" in mission.crew:
		crew_cnt = maxi(1, mission.crew.members.size())
	var day1: int = mission.day if "day" in mission else 1
	var sunset_day: int = int(Constants.v("SUNSET_DAY")) if Constants != null else 15

	_last_report = null
	_prev_battery_pct = 100.0
	_last_battery_pct = 100.0
	_last_battery_kwh = bat_kwh
	_last_battery_cap_kwh = bat_cap
	_last_battery_blackout = false
	_battery_trend = "up" if day1 < sunset_day else "flat"

	_last_o2_kg = o2_initial
	_last_o2_days_left = mission.life.get_o2_tank_days_left(crew_cnt) if (mission.life != null and mission.life.has_method("get_o2_tank_days_left")) else 30.0
	_last_co2_mmhg = 0.5
	_last_air_machine_off = false
	_last_water_kg = water_initial
	_last_recycler_broken = mission.life.recycler_broken if mission.life else false
	_last_water_days_left = mission.life.get_water_days_left(crew_cnt, not _last_recycler_broken) if (mission.life != null and mission.life.has_method("get_water_days_left")) else 30.0
	_last_food_kg = food_initial
	_last_food_days_left = mission.life.get_food_days_left(crew_cnt) if (mission.life != null and mission.life.has_method("get_food_days_left")) else 30.0
	_last_days_to_go = maxi(0, _mission_total_days - (day1 - 1))
	_last_rad_msv = 0.0
	_last_shelter_g = shelter_initial
	_last_storm_dose_if_now_msv = mission.events.storm_dose(shelter_initial) if (mission.events != null and mission.events.has_method("storm_dose")) else 0.0

	_hide_tip_bubble()
	_render_all_gauges()

	# Reset crew cards
	var max_e: int = _get_max_crew_energy()
	for card in crew_cards:
		card.set_crew_data(0.0, false, 0, max_e)
		card.update_availability(false, false, 0, has_greenhouse, greenhouse_alive)
		card.set_job(SimPlanScript.JOB_REST)

	_sync_science_gear_from_jobs()
	set_day(1)
	_update_switches_ui()
	clear_collect_bubbles()
	deselect_crew()
	_science_goal = _read_science_goal(mission)
	_target_science = 0
	_displayed_science = 0
	_target_energy_today = 0
	_displayed_energy_today = 0
	_target_shelter_g = shelter_initial
	_displayed_shelter_g = shelter_initial
	_refresh_resource_bar()

func update_from_report(report: RefCounted, defer_resource_bar: bool = false, skip_toast_events: Array = []) -> void:
	_ensure_nodes()
	if report == null:
		return

	has_greenhouse = report.greenhouse_alive or (report.greenhouse_wilt_days < 2 and has_greenhouse)
	greenhouse_alive = report.greenhouse_alive
	if greenhouse_alive:
		packed_greenhouse = true

	_last_report = report
	var pct: float = _normalize_battery_pct(float(report.battery_percent))
	var in_sunlight: bool = float(report.sun_factor) > 0.05
	if pct > _prev_battery_pct + 0.05 or (pct >= 99.5 and in_sunlight):
		_battery_trend = "up"
	elif pct < _prev_battery_pct - 0.05:
		_battery_trend = "down"
	else:
		_battery_trend = "flat"
	_prev_battery_pct = pct

	_last_battery_pct = pct
	_last_battery_kwh = float(report.battery_kwh)
	_last_battery_cap_kwh = float(report.battery_capacity_kwh)
	_last_battery_blackout = bool(report.blackout)

	_last_o2_kg = float(report.o2_kg)
	_last_o2_days_left = float(report.o2_days_left)
	_last_co2_mmhg = float(report.co2_mmhg)
	_last_air_machine_off = bool(report.blackout) or (report.power_served.has("core") and not bool(report.power_served.get("core", true)))

	_last_water_kg = float(report.water_kg)
	_last_water_days_left = float(report.water_days_left)
	_last_recycler_broken = bool(report.recycler_broken)

	_last_food_kg = float(report.food_kg)
	_last_food_days_left = float(report.food_days_left)
	_last_days_to_go = int(report.days_to_go)

	_last_rad_msv = float(report.highest_dose_msv)
	_last_shelter_g = float(report.shelter_g_cm2)
	_last_storm_dose_if_now_msv = float(report.storm_dose_if_now_msv)

	_render_all_gauges()
	_refresh_tip_bubble_texts()

	# 8. Update Crew Cards
	var max_e: int = _get_max_crew_energy()
	for i in range(mini(crew_cards.size(), report.crew_reports.size())):
		var card = crew_cards[i]
		var c_rep: Dictionary = report.crew_reports[i]
		card.set_crew_data(
			float(c_rep.get("dose_msv", 0.0)),
			bool(c_rep.get("sick", false)),
			int(c_rep.get("sick_days", 0)),
			int(c_rep.get("energy", max_e))
		)
		card.update_availability(
			false, # Will be set to true if start-of-day storm arrives
			report.recycler_broken,
			report.broken_panels,
			has_greenhouse,
			greenhouse_alive
		)

	# 9. Toast notification summary
	_generate_and_show_toast(report, skip_toast_events)
	_update_switches_ui()

	# 10. Resource bar targets
	_target_science = int(report.science_points)
	_target_energy_today = roundi(float(report.generation_kwh))
	_target_shelter_g = float(report.shelter_g_cm2)
	if not defer_resource_bar:
		flush_pending_collections()
		_displayed_science = _target_science
		_displayed_energy_today = _target_energy_today
		_displayed_shelter_g = _target_shelter_g
		_refresh_resource_bar()

func _generate_and_show_toast(report: RefCounted, skip_toast_events: Array = []) -> void:
	var line1: String = ""
	var line2: String = ""

	if report.blackout:
		line1 = tr("HUD_TOAST_BATTERY_HOURS").format({"h": "%.1f" % report.hours_on_battery})
		line2 = tr("HUD_TOAST_BLACKOUT")
	elif not report.power_shed.is_empty():
		var shed_pct: int = roundi(_normalize_battery_pct(float(report.battery_percent)))
		line1 = _tr_fallback("HUD_TOAST_POWER_SHED", "Power shed: {list}").format({"list": ", ".join(report.power_shed)})
		line2 = _tr_fallback("HUD_TOAST_BATTERY_PCT", "Battery: {pct}%").format({"pct": shed_pct})
	elif report.co2_high:
		line1 = tr("HUD_TOAST_CO2_HIGH")
		if _is_science_view():
			line2 = _tr_fallback("HUD_TOAST_CO2_VALUE", "CO2: {mmhg} mmHg").format({"mmhg": "%.1f" % report.co2_mmhg})
		else:
			line2 = _air_status_word(_last_air_level)
	else:
		var special_evt: String = ""
		var skipped_evt: bool = false
		for evt in report.events:
			var code: String = str(evt.get("code", "")) if evt is Dictionary else str(evt.code if "code" in evt else "")
			if code in skip_toast_events:
				skipped_evt = true
				continue
			if code == "METEOROID":
				special_evt = tr("HUD_TOAST_METEOROID")
				break
			elif code == "RECYCLER_BROKE":
				special_evt = tr("HUD_TOAST_RECYCLER_BROKE")
				break
		if special_evt.is_empty() and skipped_evt:
			if toast_panel != null:
				toast_panel.visible = false
			return

		var bat_pct: int = roundi(_normalize_battery_pct(float(report.battery_percent)))
		if _is_science_view():
			line2 = _tr_fallback("HUD_TOAST_POWER_BATTERY", "Power: {kwh} kWh · Battery {pct}%").format({
				"kwh": "%.0f" % report.generation_kwh,
				"pct": bat_pct,
			})
		else:
			line2 = _tr_fallback("HUD_TOAST_BATTERY_PCT", "Battery: {pct}%").format({"pct": bat_pct})
		if not special_evt.is_empty():
			line1 = special_evt
		else:
			var raw_nom := tr("HUD_TOAST_NOMINAL")
			if raw_nom == "HUD_TOAST_NOMINAL":
				raw_nom = "Day {day} complete. All systems nominal."
			line1 = raw_nom.format({"day": report.day})

	show_toast(line1, line2)

func show_toast(line1: String, line2: String = "") -> void:
	_ensure_nodes()
	if toast_panel == null or toast_line1 == null:
		return

	toast_line1.text = line1
	if toast_line2 != null:
		toast_line2.text = line2
		toast_line2.visible = not line2.is_empty()

	toast_panel.visible = true
	toast_panel.modulate.a = 0.0

	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()

	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(3.5)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(func(): toast_panel.visible = false)

func set_day(day_num: int, total_days_arg: int = -1) -> void:
	_ensure_nodes()
	current_day = day_num
	# Use explicit positive total_days_arg if given, otherwise cached mission total days
	var total_days: int = total_days_arg if total_days_arg > 0 else (_mission_total_days if _mission_total_days > 0 else 30)
	if day_label != null:
		var raw_text := tr("HUD_DAY")
		if raw_text == "HUD_DAY":
			raw_text = "Day {day} / {total}"
		day_label.text = raw_text.format({"day": day_num, "total": total_days})

	var sunset_day: int = int(Constants.v("SUNSET_DAY"))
	var is_night: bool = day_num >= sunset_day
	if sun_night_icon != null:
		sun_night_icon.texture = _night_icon if is_night else _sun_icon
		sun_night_icon.modulate = Color("#8B8D90") if is_night else UIColors.POWER
	if sun_night_label != null:
		sun_night_label.text = tr("HUD_NIGHT") if is_night else tr("HUD_SUN")

func set_storm_day(is_storm: bool) -> void:
	for card in crew_cards:
		card.update_availability(is_storm, card.recycler_broken, card.broken_panels, has_greenhouse, greenhouse_alive)
		if is_storm:
			card.set_job(SimPlanScript.JOB_REST)
	if selected_crew_index >= 0:
		_rebuild_building_markers()

func set_resolving(resolving: bool) -> void:
	_ensure_nodes()
	is_resolving = resolving
	if resolving:
		deselect_crew()
		hide_science_card_toast(true)
	_set_crew_tags_active(visible and not resolving)
	if end_day_button != null:
		end_day_button.disabled = resolving
	if status_label != null:
		status_label.visible = resolving
		if resolving:
			var raw_text := tr("HUD_RESOLVING")
			if raw_text == "HUD_RESOLVING":
				raw_text = "Resolving..."
			status_label.text = raw_text

	if greenhouse_switch != null:
		greenhouse_switch.disabled = resolving or not (has_greenhouse and greenhouse_alive)
	if science_switch != null:
		science_switch.disabled = resolving

	for card in crew_cards:
		if card.prev_job_btn:
			card.prev_job_btn.disabled = resolving
		if card.job_btn:
			card.job_btn.disabled = resolving
		if card.next_job_btn:
			card.next_job_btn.disabled = resolving

func get_plan() -> SimPlan:
	if current_plan == null:
		current_plan = SimPlanScript.new()
	for i in range(mini(4, crew_cards.size())):
		current_plan.set_job(i, crew_cards[i].get_job())
	_sync_science_gear_from_jobs()
	return current_plan

func reset_crew_to_rest() -> void:
	if current_plan == null:
		current_plan = SimPlanScript.new()
	for i in range(crew_cards.size()):
		var card = crew_cards[i]
		if card != null and card.has_method("set_job"):
			card.set_job(SimPlanScript.JOB_REST)
		if current_plan != null:
			current_plan.set_job(i, SimPlanScript.JOB_REST)
	_sync_science_gear_from_jobs()

func _sync_science_gear_from_jobs() -> void:
	if current_plan == null:
		return
	var has_sci: bool = false
	for i in range(mini(4, crew_cards.size())):
		var card = crew_cards[i]
		if card != null and card.get_job() == SimPlanScript.JOB_SCIENCE:
			has_sci = true
			break
	if crew_cards.is_empty():
		for j in current_plan.jobs:
			if j == SimPlanScript.JOB_SCIENCE:
				has_sci = true
				break
	current_plan.science_gear_on = has_sci

func _on_crew_card_job_changed(idx: int, new_job: String) -> void:
	if current_plan != null:
		current_plan.set_job(idx, new_job)
		_sync_science_gear_from_jobs()
		plan_changed.emit(current_plan)
	crew_job_changed.emit(idx, new_job)

func _on_greenhouse_switch_pressed() -> void:
	if current_plan == null:
		current_plan = SimPlanScript.new()
	current_plan.greenhouse_lights_on = not current_plan.greenhouse_lights_on
	if Audio != null:
		Audio.play("ui_switch")
	_update_switches_ui()
	plan_changed.emit(current_plan)

func _on_greenhouse_switch_gui_input(event: InputEvent) -> void:
	if greenhouse_switch != null and greenhouse_switch.disabled:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if Audio != null:
				Audio.play("ui_error")

func _on_science_switch_pressed() -> void:
	if current_plan == null:
		current_plan = SimPlanScript.new()
	_sync_science_gear_from_jobs()
	_update_switches_ui()
	plan_changed.emit(current_plan)

func _update_switches_ui() -> void:
	_ensure_nodes()
	if greenhouse_switch != null:
		var gh_available: bool = has_greenhouse and greenhouse_alive
		greenhouse_switch.disabled = not gh_available
		var is_on: bool = (current_plan != null and current_plan.greenhouse_lights_on and gh_available)
		var state_text: String = _tr_fallback("HUD_ON", "ON") if is_on else _tr_fallback("HUD_OFF", "OFF")
		greenhouse_switch.text = "%s: %s" % [tr("HUD_GREENHOUSE_LIGHTS"), state_text]
		if not gh_available:
			greenhouse_switch.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 0.7))
			greenhouse_switch.modulate = Color(0.6, 0.6, 0.6, 0.6)
		elif is_on:
			greenhouse_switch.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55, 1.0))
			greenhouse_switch.modulate = Color(0.9, 1.25, 0.9, 1.0)
		else:
			greenhouse_switch.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1.0))
			greenhouse_switch.modulate = Color.WHITE

	if science_switch != null:
		science_switch.visible = false
		var is_on: bool = (current_plan != null and current_plan.science_gear_on)
		var sci_state: String = _tr_fallback("HUD_ON", "ON") if is_on else _tr_fallback("HUD_OFF", "OFF")
		science_switch.text = "%s: %s" % [tr("HUD_SCIENCE_GEAR"), sci_state]
		if is_on:
			science_switch.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0, 1.0))
			science_switch.modulate = Color(0.9, 1.15, 1.25, 1.0)
		else:
			science_switch.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1.0))
			science_switch.modulate = Color.WHITE

func _on_end_day_pressed() -> void:
	if not is_resolving:
		_hide_tip_bubble()
		if Audio != null:
			Audio.play("ui_confirm")
		end_day_pressed.emit()

func _on_fast_button_pressed() -> void:
	if Audio != null:
		Audio.play("ui_switch")
	Settings.fast_mode = not Settings.fast_mode
	fast_toggled.emit(Settings.fast_mode)
	_update_fast_button_text()

func _on_mute_button_pressed() -> void:
	if Audio != null:
		Audio.unlock()
	Settings.sound_on = not Settings.sound_on
	if Audio != null and Settings.sound_on:
		Audio.play("ui_switch")
	_update_mute_button()

func _on_settings_sound_changed(_enabled: bool) -> void:
	_update_mute_button()

func _update_mute_button() -> void:
	_ensure_nodes()
	if mute_btn == null:
		return
	var is_on: bool = Settings.sound_on if Settings != null else true
	mute_btn.icon = ICON_VOLUME_UP if is_on else ICON_VOLUME_OFF
	mute_btn.modulate = Color.WHITE if is_on else Color(0.85, 0.45, 0.45, 1.0)
	mute_btn.tooltip_text = tr("HUD_SOUND_ON") if is_on else tr("HUD_SOUND_OFF")

func _on_settings_fast_mode_changed(_enabled: bool) -> void:
	_update_fast_button_text()

func _update_fast_button_text() -> void:
	_ensure_nodes()
	if fast_toggle == null:
		return
	var raw_fast := tr("HUD_FAST")
	if raw_fast == "HUD_FAST":
		raw_fast = "Fast (0.5s)"
	var is_on: bool = Settings.fast_mode
	var state_text: String = _tr_fallback("HUD_ON", "ON") if is_on else _tr_fallback("HUD_OFF", "OFF")
	fast_toggle.text = "%s: %s" % [raw_fast, state_text]
	if is_on:
		fast_toggle.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55, 1.0))
		fast_toggle.modulate = Color(0.9, 1.25, 0.9, 1.0)
	else:
		fast_toggle.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1.0))
		fast_toggle.modulate = Color.WHITE

# Pause Menu methods
func _on_menu_button_pressed() -> void:
	_ensure_nodes()
	_hide_tip_bubble()
	deselect_crew()
	if Audio != null:
		Audio.play("ui_click")
	if pause_layer != null:
		pause_layer.visible = true
	_update_pause_menu_texts()

func _close_pause_menu() -> void:
	if Audio != null and pause_layer != null and pause_layer.visible:
		Audio.play("ui_click")
	if pause_layer != null:
		pause_layer.visible = false

func _on_pause_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_pause_menu()
	elif event is InputEventScreenTouch and event.pressed:
		_close_pause_menu()

func _on_pause_sources_pressed() -> void:
	if Audio != null:
		Audio.play("ui_click")
	if pause_layer != null:
		pause_layer.visible = false
	menu_requested.emit()

func _update_pause_menu_texts() -> void:
	_ensure_nodes()
	if pause_title_label != null:
		pause_title_label.text = tr("MENU_PAUSE_TITLE")
	if pause_resume_btn != null:
		pause_resume_btn.text = tr("MENU_RESUME")
	if pause_sources_btn != null:
		pause_sources_btn.text = tr("MENU_SOURCES")
	if pause_lang_btn != null:
		var cur_lang: String = Settings.language if Settings != null else "en"
		var lang_name: String = "English" if cur_lang == "en" else "বাংলা"
		pause_lang_btn.text = _tr_fallback("HUD_LANGUAGE", "Language: {lang}").format({"lang": lang_name})
	if pause_science_btn != null:
		var sci_on: bool = _is_science_view()
		var state_text: String = _tr_fallback("HUD_ON", "ON") if sci_on else _tr_fallback("HUD_OFF", "OFF")
		pause_science_btn.text = "%s: %s" % [_tr_fallback("KID_SCIENCE_NUMBERS", "Science numbers"), state_text]
		pause_science_btn.modulate = Color(0.9, 1.25, 0.9, 1.0) if sci_on else Color.WHITE
		pause_science_btn.add_theme_color_override("font_color", UIColors.OXYGEN if sci_on else Color(0.92, 0.94, 0.96, 1.0))

func _refresh_language_texts() -> void:
	_ensure_nodes()
	_refresh_gauge_titles()
	_render_all_gauges()
	_refresh_tip_bubble_texts()
	_init_resource_bar()
	set_day(current_day)
	_update_fast_button_text()
	_update_mute_button()
	_update_switches_ui()
	if end_day_button != null:
		end_day_button.text = tr("HUD_END_DAY")
	if menu_btn != null:
		menu_btn.text = tr("HUD_MENU")
	if status_label != null and is_resolving:
		status_label.text = _tr_fallback("HUD_RESOLVING", "Resolving...")
	_update_pause_menu_texts()
	_refresh_selection_locale()
	for card in crew_cards:
		if card != null and card.has_method("_refresh_language_texts"):
			card._refresh_language_texts()
	for tag_btn in _crew_tag_buttons:
		if tag_btn != null and is_instance_valid(tag_btn) and tag_btn.has_method("refresh_language"):
			tag_btn.call("refresh_language")
	_refresh_card_toast_texts()

func _on_language_changed(_lang: String) -> void:
	_refresh_language_texts()

func _on_pause_lang_pressed() -> void:
	if Audio != null:
		Audio.play("ui_switch")
	var next_lang: String = "bn" if Settings.language == "en" else "en"
	Settings.language = next_lang
	if Settings == null or not Settings.language_changed.is_connected(_on_language_changed):
		_refresh_language_texts()

func _on_pause_science_pressed() -> void:
	if Audio != null:
		Audio.play("ui_switch")
	if Settings != null:
		Settings.science_view = not Settings.science_view
	if Settings == null or not Settings.science_view_changed.is_connected(_on_science_view_changed):
		_apply_science_view()

func _on_science_view_changed(_enabled: bool) -> void:
	_apply_science_view()


func _read_science_goal(mission: RefCounted) -> int:
	if mission != null:
		if mission.has_method("get_constants"):
			var mc = mission.get_constants()
			if mc != null and mc.has("SCIENCE_GOAL_POINTS"):
				return int(mc.v("SCIENCE_GOAL_POINTS"))
		if mission.get("_c") != null:
			var mc2 = mission.get("_c")
			if mc2.has("SCIENCE_GOAL_POINTS"):
				return int(mc2.v("SCIENCE_GOAL_POINTS"))
	return int(Constants.v("SCIENCE_GOAL_POINTS")) if Constants != null else 0


func _tr_fallback(key: String, fallback: String) -> String:
	var val: String = tr(key)
	return fallback if val == key or val.is_empty() else val


func _update_co2_status_word(co2_mmhg: float) -> void:
	_last_co2_mmhg = co2_mmhg
	if co2_gauge == null or Constants == null:
		return
	var healthy_max: float = float(Constants.v("CO2_HEALTHY_MAX_MMHG"))
	var warn_limit: float = float(Constants.v("CO2_LIMIT_MMHG"))
	var warn_days: float = float(Constants.v("SUPPLY_WARNING_DAYS"))
	var low_o2_with_air_off: bool = _last_air_machine_off and (_last_o2_days_left < warn_days - 0.0001)
	if co2_mmhg > warn_limit or low_o2_with_air_off:
		_last_air_level = "danger"
	elif co2_mmhg > healthy_max:
		_last_air_level = "stuffy"
	else:
		_last_air_level = "good"
	co2_gauge.set_face_visual(_last_air_level)
	co2_gauge.set_status_word(_air_status_word(_last_air_level), _air_level_color(_last_air_level), true)

func _air_status_word(level: String) -> String:
	match level:
		"danger":
			return _tr_fallback("AIR_DANGER", "Air: danger!")
		"stuffy":
			return _tr_fallback("AIR_STUFFY", "Air: stuffy")
		_:
			return _tr_fallback("AIR_GOOD", "Air: good")

func _air_level_color(level: String) -> Color:
	match level:
		"danger":
			return UIColors.ALERT
		"stuffy":
			return UIColors.POWER
		_:
			return UIColors.OXYGEN


func _refresh_resource_bar() -> void:
	_ensure_nodes()
	if _science_goal <= 0 and Constants != null:
		_science_goal = int(Constants.v("SCIENCE_GOAL_POINTS"))
	var goal: int = maxi(1, _science_goal)
	if res_science_value != null:
		var fmt: String = _tr_fallback("RES_SCIENCE_VALUE", "{n} / {goal}")
		res_science_value.text = fmt.format({"n": _displayed_science, "goal": goal})
		var reached: bool = _displayed_science >= goal
		res_science_value.add_theme_color_override("font_color", UIColors.POWER if reached else UIColors.TEXT)
		if res_science_icon != null:
			res_science_icon.modulate = UIColors.POWER if reached else UIColors.WATER
		_apply_science_pill_gold(reached)
	if res_energy_value != null:
		res_energy_value.text = "%d kWh" % _displayed_energy_today
	if res_shelter_value != null:
		res_shelter_value.text = "%.1f g/cm²" % _displayed_shelter_g


func _apply_science_pill_gold(reached: bool) -> void:
	if res_science_pill == null:
		return
	if _science_pill_default_style == null:
		_science_pill_default_style = res_science_pill.get_theme_stylebox("panel")
	if _science_pill_gold_style == null and _science_pill_default_style is StyleBoxFlat:
		var copy := (_science_pill_default_style as StyleBoxFlat).duplicate() as StyleBoxFlat
		copy.border_color = UIColors.POWER
		copy.border_width_left = 2
		copy.border_width_top = 2
		copy.border_width_right = 2
		copy.border_width_bottom = 2
		_science_pill_gold_style = copy
	if reached and _science_pill_gold_style != null:
		res_science_pill.add_theme_stylebox_override("panel", _science_pill_gold_style)
	elif _science_pill_default_style != null:
		res_science_pill.add_theme_stylebox_override("panel", _science_pill_default_style)


static func build_collect_specs(prev_report: Variant, report: RefCounted, base: Node = null, initial_shelter_g: float = 0.0) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	if report == null:
		return specs

	var prev_science: int = 0
	var prev_shelter: float = initial_shelter_g
	if prev_report != null:
		if "science_points" in prev_report:
			prev_science = int(prev_report.science_points)
		if "shelter_g_cm2" in prev_report:
			prev_shelter = float(prev_report.shelter_g_cm2)

	return build_collect_specs_from_prev(report, prev_science, prev_shelter, base)


static func build_collect_specs_from_prev(report: RefCounted, prev_science: int, prev_shelter_g: float, base: Node = null) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	if report == null:
		return specs

	var has_anchor_fn: bool = base != null and base.has_method("get_collect_anchor")
	var kwh_rounded: int = roundi(float(report.generation_kwh))
	var energy_anchor: Vector3 = base.get_collect_anchor("energy") if has_anchor_fn else Vector3(1.0, 2.0, 1.0)
	if not has_anchor_fn or energy_anchor != Vector3.ZERO:
		specs.append({
			"kind": "energy",
			"icon": ICON_BOLT,
			"amount": float(kwh_rounded),
			"text": "+%d" % kwh_rounded,
			"color": UIColors.POWER,
			"anchor": energy_anchor,
		})

	var science_delta: int = int(report.science_points) - prev_science
	if science_delta > 0:
		var sci_anchor: Vector3 = base.get_collect_anchor("science") if has_anchor_fn else Vector3(2.0, 2.0, 0.0)
		if not has_anchor_fn or sci_anchor != Vector3.ZERO:
			specs.append({
				"kind": "science",
				"icon": ICON_SCIENCE,
				"amount": float(science_delta),
				"text": "+%d" % science_delta,
				"color": UIColors.WATER,
				"anchor": sci_anchor,
			})

	var shelter_delta: float = float(report.shelter_g_cm2) - prev_shelter_g
	if shelter_delta > 0.001:
		var sh_anchor: Vector3 = base.get_collect_anchor("shelter") if has_anchor_fn else Vector3(0.0, 2.0, -4.0)
		if not has_anchor_fn or sh_anchor != Vector3.ZERO:
			specs.append({
				"kind": "shelter",
				"icon": ICON_SHIELD,
				"amount": shelter_delta,
				"text": "+%.1f" % shelter_delta,
				"color": SHELTER_ACCENT_COLOR,
				"anchor": sh_anchor,
			})

	if bool(report.greenhouse_healthy):
		var plant_anchor: Vector3 = base.get_collect_anchor("plants") if has_anchor_fn else Vector3(-4.0, 2.0, 0.0)
		if not has_anchor_fn or plant_anchor != Vector3.ZERO:
			var o2_val: float = float(report.greenhouse_o2_kg)
			specs.append({
				"kind": "plants",
				"icon": ICON_ECO,
				"amount": o2_val,
				"text": "+%.1f" % o2_val,
				"color": UIColors.OXYGEN,
				"anchor": plant_anchor,
			})

	if specs.size() > MAX_COLLECT_BUBBLES:
		specs.resize(MAX_COLLECT_BUBBLES)
	return specs


func spawn_collect_bubbles_for_report(report: RefCounted, prev_science: int, prev_shelter_g: float, base: Node = null) -> Array[Control]:
	_ensure_nodes()
	flush_pending_collections()
	clear_collect_bubbles()
	if report == null:
		return []

	_target_science = int(report.science_points)
	_target_energy_today = roundi(float(report.generation_kwh))
	_target_shelter_g = float(report.shelter_g_cm2)

	var specs: Array[Dictionary] = build_collect_specs_from_prev(report, prev_science, prev_shelter_g, base)
	return spawn_collect_bubbles_from_specs(specs)


func spawn_collect_bubbles_from_specs(specs: Array[Dictionary], show_hint_if_unseen: bool = true) -> Array[Control]:
	_ensure_nodes()
	clear_collect_bubbles()

	_displayed_science = _target_science
	_displayed_energy_today = _target_energy_today
	_displayed_shelter_g = _target_shelter_g
	for spec in specs:
		match str(spec.get("kind", "")):
			"science":
				_displayed_science = maxi(0, _target_science - roundi(float(spec.get("amount", 0.0))))
			"energy":
				_displayed_energy_today = 0
			"shelter":
				_displayed_shelter_g = maxf(0.0, _target_shelter_g - float(spec.get("amount", 0.0)))
	_refresh_resource_bar()

	var parent_layer: Control = bubbles_layer if bubbles_layer != null else self
	var fly_host: Control = fly_layer if fly_layer != null else self
	var limit: int = mini(specs.size(), MAX_COLLECT_BUBBLES)
	var show_hint: bool = show_hint_if_unseen and (Settings == null or not Settings.hint_collect_shown)

	for i in range(limit):
		var spec: Dictionary = specs[i]
		var bubble := CollectBubbleScene.instantiate() as Control
		parent_layer.add_child(bubble)
		var kind: String = str(spec.get("kind", ""))
		var target_ctrl: Control = _get_fly_target_for_kind(kind)
		bubble.call("setup", spec, target_ctrl, fly_host, float(i) * 1.35)
		bubble.connect("bubble_tapped", Callable(self, "_on_bubble_tapped"))
		bubble.connect("collection_arrived", Callable(self, "_on_bubble_collection_arrived").bind(bubble))
		if i == 0 and show_hint:
			bubble.call("show_hint", _tr_fallback("COLLECT_HINT", "Tap the bubbles!"))
			if Settings != null:
				Settings.hint_collect_shown = true
		_active_bubbles.append(bubble)

	return get_collect_bubbles()


func auto_collect_all() -> void:
	var copy: Array[Control] = _active_bubbles.duplicate()
	var triggered_any: bool = false
	for bubble in copy:
		if is_instance_valid(bubble):
			bubble.call("hide_hint")
			if not bool(bubble.call("is_collecting")) and not bool(bubble.call("is_collected_done")):
				bubble.call("collect", CollectBubbleScript.FLY_DURATION_FAST, false)
				triggered_any = true
	if triggered_any and Audio != null:
		Audio.play("ui_switch")


func flush_pending_collections() -> void:
	var copy: Array[Control] = _active_bubbles.duplicate()
	for bubble in copy:
		if is_instance_valid(bubble) and bubble.has_method("finish_immediately"):
			bubble.call("finish_immediately")
	_active_bubbles.clear()
	_displayed_science = _target_science
	_displayed_energy_today = _target_energy_today
	_displayed_shelter_g = _target_shelter_g
	_refresh_resource_bar()


func clear_collect_bubbles() -> void:
	for bubble in _active_bubbles:
		if is_instance_valid(bubble):
			bubble.queue_free()
	_active_bubbles.clear()


func get_collect_bubbles() -> Array[Control]:
	var alive: Array[Control] = []
	for bubble in _active_bubbles:
		if is_instance_valid(bubble) and not bool(bubble.call("is_collected_done")):
			alive.append(bubble)
	return alive


func get_pending_collect_count() -> int:
	var count: int = 0
	for bubble in _active_bubbles:
		if is_instance_valid(bubble) and not bool(bubble.call("is_collecting")) and not bool(bubble.call("is_collected_done")):
			count += 1
	return count


func get_co2_status_text() -> String:
	_ensure_nodes()
	if co2_gauge != null and co2_gauge.status_label != null and co2_gauge.status_label.visible:
		return co2_gauge.status_label.text
	return ""


func _get_fly_target_for_kind(kind: String) -> Control:
	match kind:
		"science":
			return _pick_ctrl(res_science_icon, res_science_pill)
		"energy":
			return _pick_ctrl(res_energy_icon, res_energy_pill)
		"shelter":
			return _pick_ctrl(res_shelter_icon, res_shelter_pill)
		"plants":
			var plant_target_gauge: Gauge = o2_gauge if (o2_gauge != null and o2_gauge.visible) else co2_gauge
			var o2_icon: Control = plant_target_gauge.icon_rect if plant_target_gauge != null else null
			return _pick_ctrl(o2_icon, plant_target_gauge)
		_:
			return res_energy_pill


func _pick_ctrl(primary: Control, fallback: Control) -> Control:
	return primary if primary != null else fallback


func _on_bubble_tapped(_tapped: Control) -> void:
	if Settings != null:
		Settings.hint_collect_shown = true
	for bubble in _active_bubbles:
		if is_instance_valid(bubble) and bubble.has_method("hide_hint"):
			bubble.call("hide_hint")


func _on_bubble_collection_arrived(kind: String, _amount: float, bubble: Control) -> void:
	_active_bubbles.erase(bubble)
	match kind:
		"science":
			_displayed_science = _target_science
		"energy":
			_displayed_energy_today = _target_energy_today
		"shelter":
			_displayed_shelter_g = _target_shelter_g
	_refresh_resource_bar()
	_pulse_target_control(_get_pill_for_kind(kind))


func _get_pill_for_kind(kind: String) -> Control:
	match kind:
		"science":
			return res_science_pill
		"energy":
			return res_energy_pill
		"shelter":
			return res_shelter_pill
		"plants":
			return o2_gauge if (o2_gauge != null and o2_gauge.visible) else co2_gauge
		_:
			return null


func _pulse_target_control(ctrl: Control) -> void:
	if ctrl == null or not is_inside_tree():
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	var tween := ctrl.create_tween()
	tween.tween_property(ctrl, "scale", Vector2(1.12, 1.12), 0.1)
	tween.tween_property(ctrl, "scale", Vector2.ONE, 0.12)


# --- Tap-to-assign (M-05) ---

func _process(delta: float) -> void:
	if _banner_feedback_timer > 0.0:
		_banner_feedback_timer -= delta
		if _banner_feedback_timer <= 0.0:
			_banner_feedback_timer = 0.0
			if selected_crew_index >= 0:
				_show_select_prompt_banner()
			else:
				_hide_select_banner()


## Connects Base and Crew 3D world references so 2D WorldAnchor tags and building markers stay bound.
func bind_world_nodes(base_node: Node, crew_node: Node) -> void:
	_ensure_nodes()
	var crew_changed: bool = _crew_ref != crew_node
	_base_ref = base_node
	_crew_ref = crew_node
	if crew_changed or _crew_tag_buttons.is_empty():
		_setup_crew_tag_buttons()
	_set_crew_tags_active(visible and not is_resolving)
	if selected_crew_index >= 0:
		_rebuild_building_markers()


func set_packed_greenhouse(packed: bool) -> void:
	packed_greenhouse = packed
	if selected_crew_index >= 0:
		_rebuild_building_markers()


func select_crew(idx: int, play_sound: bool = true) -> void:
	_ensure_nodes()
	if is_resolving:
		return
	if idx == selected_crew_index:
		deselect_crew()
		if play_sound and Audio != null:
			Audio.play("ui_click")
		return
	if idx < 0 or idx >= crew_cards.size():
		deselect_crew()
		return
	for c in crew_cards:
		if c != null and c.has_method("close_picker"):
			c.close_picker()
	selected_crew_index = idx
	_sync_selection_highlights()
	if _crew_ref != null and _crew_ref.has_method("select_astronaut"):
		_crew_ref.select_astronaut(selected_crew_index)
	_show_select_prompt_banner()
	_rebuild_building_markers()
	crew_selected.emit(selected_crew_index)
	if play_sound and Audio != null:
		Audio.play("ui_click")


func deselect_crew() -> void:
	if selected_crew_index == -1 and _building_markers.is_empty():
		_hide_select_banner()
		return
	selected_crew_index = -1
	_banner_feedback_timer = 0.0
	_sync_selection_highlights()
	if _crew_ref != null and _crew_ref.has_method("select_astronaut"):
		_crew_ref.select_astronaut(-1)
	_hide_select_banner()
	_clear_building_markers()
	crew_selected.emit(-1)


func get_selected_crew_index() -> int:
	return selected_crew_index


func get_building_markers() -> Dictionary:
	return _building_markers


func get_crew_tag_buttons() -> Array[Control]:
	return _crew_tag_buttons


func get_select_banner_text() -> String:
	return select_banner_label.text if select_banner_label != null else ""


func is_select_banner_visible() -> bool:
	return select_banner_panel != null and select_banner_panel.visible


func _sync_selection_highlights() -> void:
	for i in range(crew_cards.size()):
		var c = crew_cards[i]
		if c != null and c.has_method("set_selected"):
			c.set_selected(i == selected_crew_index)
	for i in range(_crew_tag_buttons.size()):
		var btn := _crew_tag_buttons[i]
		if is_instance_valid(btn) and btn.has_method("set_selected"):
			btn.call("set_selected", i == selected_crew_index)


func _setup_crew_tag_buttons() -> void:
	for btn in _crew_tag_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_crew_tag_buttons.clear()
	if _crew_ref == null or not _crew_ref.has_method("get_astronaut"):
		return
	var host: Control = bubbles_layer if bubbles_layer != null else self
	for i in range(4):
		var astro := _crew_ref.call("get_astronaut", i) as Node3D
		if astro == null:
			continue
		var tag_btn := CrewTagButtonScene.instantiate() as Control
		host.add_child(tag_btn)
		var card = crew_cards[i] if i < crew_cards.size() else null
		var crew_name: String = card.get_crew_name() if card != null else _tr_fallback("CREW_MEMBER", "Crew {n}").format({"n": i})
		var suit_col: Color = card.get_suit_color() if card != null else Color.WHITE
		var anchor_node := astro.get_node_or_null("BodyPivot/NameTag") as Node3D
		if tag_btn.has_method("setup"):
			tag_btn.call("setup", i, crew_name, suit_col, astro, anchor_node)
		if tag_btn.has_signal("tag_pressed") and not tag_btn.is_connected("tag_pressed", _on_crew_tag_pressed):
			tag_btn.connect("tag_pressed", _on_crew_tag_pressed)
		_crew_tag_buttons.append(tag_btn)


func _set_crew_tags_active(active: bool) -> void:
	if _crew_ref != null and _crew_ref.has_method("set_overlay_tag_mode"):
		_crew_ref.set_overlay_tag_mode(active)
	for btn in _crew_tag_buttons:
		if is_instance_valid(btn) and btn.has_method("set_overlay_enabled"):
			btn.call("set_overlay_enabled", active)


func _rebuild_building_markers() -> void:
	_clear_building_markers()
	if selected_crew_index < 0 or selected_crew_index >= crew_cards.size():
		return
	var card = crew_cards[selected_crew_index]
	var specs: Array[Dictionary] = _build_marker_specs(card)
	var host: Control = bubbles_layer if bubbles_layer != null else self
	for spec in specs:
		var bkey: String = str(spec.get("building_key", ""))
		var marker := BuildingMarkerScene.instantiate() as Control
		marker.z_index = 2
		host.add_child(marker)
		var anchor_pt := _get_building_anchor(bkey, str(spec.get("job", "REST")), str(spec.get("repair_target", "")))
		if bool(spec.get("split", false)):
			marker.call("configure_split", bkey, spec.get("left", {}), spec.get("right", {}), anchor_pt)
		else:
			marker.call(
				"configure_single",
				bkey,
				str(spec.get("job", "REST")),
				str(spec.get("label_key", "JOB_REST")),
				spec.get("icon"),
				Color(spec.get("accent", UIColors.MODULE)),
				bool(spec.get("available", true)),
				str(spec.get("reason", "")),
				anchor_pt,
				str(spec.get("warning", ""))
			)
		if marker.has_signal("marker_activated"):
			marker.connect("marker_activated", _on_building_marker_activated)
		if marker.has_signal("disabled_tapped"):
			marker.connect("disabled_tapped", _on_building_marker_disabled)
		_building_markers[bkey] = marker


func _build_marker_specs(card: CrewCard) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	var hab_label: String = "CREW_REST_REFILL" if card.is_tired_warning() else "JOB_REST"
	specs.append(_make_single_spec(card, "habitat", SimPlanScript.JOB_REST, hab_label, UIColors.MODULE))
	specs.append(_make_single_spec(card, "life_support", SimPlanScript.JOB_REPAIR, "JOB_REPAIR", UIColors.WATER, "RECYCLER"))
	if not card.is_storm and not card.is_sick and card.broken_panels > 0 and not card.recycler_broken:
		var clean_avail: bool = card.is_job_available(SimPlanScript.JOB_CLEAN)
		var panel_avail: bool = card.is_job_available(SimPlanScript.JOB_REPAIR, "PANEL")
		var tired_warn: String = card.get_tired_warning_text() if card.is_tired_warning() else ""
		specs.append({
			"building_key": "solar",
			"split": true,
			"job": SimPlanScript.JOB_CLEAN,
			"left": {
				"job": SimPlanScript.JOB_CLEAN,
				"label_key": "ASSIGN_CLEAN",
				"icon": CrewCardScript.JOB_ICONS.get(SimPlanScript.JOB_CLEAN),
				"accent": UIColors.POWER,
				"available": clean_avail,
				"reason": card.get_job_disabled_reason(SimPlanScript.JOB_CLEAN),
				"warning": tired_warn if clean_avail else "",
			},
			"right": {
				"job": SimPlanScript.JOB_REPAIR,
				"label_key": "ASSIGN_REPAIR",
				"icon": CrewCardScript.JOB_ICONS.get(SimPlanScript.JOB_REPAIR),
				"accent": UIColors.ALERT,
				"available": panel_avail,
				"reason": card.get_job_disabled_reason(SimPlanScript.JOB_REPAIR, "PANEL"),
				"warning": tired_warn if panel_avail else "",
			},
		})
	else:
		specs.append(_make_single_spec(card, "solar", SimPlanScript.JOB_CLEAN, "JOB_CLEAN", UIColors.POWER))
	if packed_greenhouse or card.has_greenhouse or card.greenhouse_alive:
		specs.append(_make_single_spec(card, "greenhouse", SimPlanScript.JOB_FARM, "JOB_FARM", UIColors.OXYGEN))
	specs.append(_make_single_spec(card, "dig_site", SimPlanScript.JOB_REGOLITH, "JOB_REGOLITH", UIColors.REGOLITH))
	specs.append(_make_single_spec(card, "drill", SimPlanScript.JOB_SCIENCE, "JOB_SCIENCE", UIColors.WATER))
	return specs


func _make_single_spec(
	card: CrewCard,
	building_key: String,
	job: String,
	label_key: String,
	accent: Color,
	repair_target: String = ""
) -> Dictionary:
	var avail: bool = card.is_job_available(job, repair_target)
	var warn_txt: String = ""
	if avail and job != SimPlanScript.JOB_REST and card.is_tired_warning():
		warn_txt = card.get_tired_warning_text()
	return {
		"building_key": building_key,
		"split": false,
		"job": job,
		"label_key": label_key,
		"icon": CrewCardScript.JOB_ICONS.get(job),
		"accent": accent,
		"repair_target": repair_target,
		"available": avail,
		"reason": card.get_job_disabled_reason(job, repair_target),
		"warning": warn_txt,
	}


func _get_max_crew_energy() -> int:
	if Constants != null and "sim" in Constants and Constants.sim != null and Constants.sim.has("CREW_ENERGY_MAX"):
		return int(Constants.v("CREW_ENERGY_MAX"))
	return 3


func _get_building_anchor(building_key: String, job: String, repair_target: String = "") -> Vector3:
	if _base_ref != null and _base_ref.has_method("get_building_marker_anchor"):
		return _base_ref.get_building_marker_anchor(building_key)
	if _base_ref != null and _base_ref.has_method("get_job_spot_position"):
		return _base_ref.get_job_spot_position(job, repair_target) + Vector3(0.0, 2.0, 0.0)
	var fallback: Dictionary = {
		"habitat": Vector3(0.0, 2.0, 1.8),
		"life_support": Vector3(4.0, 2.0, 1.8),
		"solar": Vector3(-5.5, 2.0, 6.5),
		"greenhouse": Vector3(-4.0, 2.0, 1.8),
		"dig_site": Vector3(-12.5, 2.0, -2.0),
		"drill": Vector3(7.5, 2.0, 1.5),
	}
	return fallback.get(building_key, Vector3(0.0, 2.0, 0.0))


func _clear_building_markers() -> void:
	for m in _building_markers.values():
		if is_instance_valid(m):
			(m as Node).queue_free()
	_building_markers.clear()


func _show_select_prompt_banner() -> void:
	_ensure_nodes()
	if select_banner_panel == null or select_banner_label == null:
		return
	if selected_crew_index < 0 or selected_crew_index >= crew_cards.size():
		_hide_select_banner()
		return
	if toast_panel != null and toast_panel.visible:
		toast_panel.visible = false
	var crew_name: String = crew_cards[selected_crew_index].get_crew_name()
	var tmpl: String = tr("ASSIGN_PICK_BUILDING")
	if tmpl == "ASSIGN_PICK_BUILDING":
		tmpl = "Where should {name} work?"
	select_banner_label.text = tmpl.format({"name": crew_name})
	select_banner_label.add_theme_color_override("font_color", UIColors.POWER)
	select_banner_panel.visible = true
	_banner_feedback_timer = 0.0
	_update_card_toast_position()


func _show_banner_error(reason_text: String) -> void:
	_ensure_nodes()
	if select_banner_panel == null or select_banner_label == null:
		return
	if reason_text.is_empty():
		return
	select_banner_label.text = reason_text
	select_banner_label.add_theme_color_override("font_color", UIColors.ALERT)
	select_banner_panel.visible = true
	_banner_feedback_timer = BANNER_FEEDBACK_DURATION
	_update_card_toast_position()


func _hide_select_banner() -> void:
	if select_banner_panel != null:
		select_banner_panel.visible = false
	_update_card_toast_position()


func _find_next_rest_crew(from_idx: int) -> int:
	if crew_cards.is_empty():
		return -1
	var count: int = crew_cards.size()
	for offset in range(1, count):
		var cand: int = (from_idx + offset) % count
		var card = crew_cards[cand]
		if card != null and card.get_job() == SimPlanScript.JOB_REST:
			return cand
	return -1


func _refresh_selection_locale() -> void:
	for card in crew_cards:
		if card != null and card.has_method("_refresh_display"):
			card._refresh_display()
	if selected_crew_index >= 0:
		if _banner_feedback_timer <= 0.0:
			_show_select_prompt_banner()
		_rebuild_building_markers()


func _on_crew_card_selected(idx: int) -> void:
	select_crew(idx, true)


func _on_crew_tag_pressed(idx: int) -> void:
	select_crew(idx, true)


func _on_crew_card_picker_opened(_idx: int) -> void:
	deselect_crew()


func _on_building_marker_activated(_bkey: String, job: String) -> void:
	if selected_crew_index < 0 or selected_crew_index >= crew_cards.size():
		return
	var assigned_idx: int = selected_crew_index
	var card = crew_cards[assigned_idx]
	var warn_overwork: bool = (card != null and card.has_method("is_tired_warning") and card.is_tired_warning() and job != SimPlanScript.JOB_REST)
	if Audio != null:
		Audio.play("ui_error" if warn_overwork else "ui_confirm")
	if card != null and card.has_method("set_job"):
		card.set_job(job)
	var next_rest := _find_next_rest_crew(assigned_idx)
	if next_rest >= 0:
		select_crew(next_rest, false)
	else:
		deselect_crew()


func _on_building_marker_disabled(_bkey: String, _job: String, reason_text: String) -> void:
	if Audio != null:
		Audio.play("ui_error")
	_show_banner_error(reason_text)


func _on_hud_visibility_changed() -> void:
	if not visible:
		_hide_tip_bubble()
		deselect_crew()
		hide_science_card_toast(true)
	_set_crew_tags_active(visible and not is_resolving)


func _ensure_card_toast_ui() -> void:
	if _card_toast_wrap != null:
		return
	_card_toast_wrap = CenterContainer.new()
	_card_toast_wrap.name = "ScienceCardToastWrap"
	_card_toast_wrap.anchor_left = 0.0
	_card_toast_wrap.anchor_right = 1.0
	_card_toast_wrap.anchor_top = 0.0
	_card_toast_wrap.anchor_bottom = 0.0
	_card_toast_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_toast_wrap.visible = false
	add_child(_card_toast_wrap)

	_card_toast_style = StyleBoxFlat.new()
	_card_toast_style.bg_color = Color("141821F5")
	_card_toast_style.border_color = UIColors.POWER
	_card_toast_style.set_border_width_all(2)
	_card_toast_style.set_corner_radius_all(12)
	_card_toast_style.content_margin_left = 14
	_card_toast_style.content_margin_right = 14
	_card_toast_style.content_margin_top = 6
	_card_toast_style.content_margin_bottom = 6
	_card_toast_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	_card_toast_style.shadow_size = 10
	_card_toast_style.shadow_offset = Vector2(0, 4)

	var toast_vbox := VBoxContainer.new()
	toast_vbox.name = "ToastVBox"
	toast_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	toast_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_vbox.add_theme_constant_override("separation", 6)
	_card_toast_wrap.add_child(toast_vbox)

	var panel := PanelContainer.new()
	panel.name = "ScienceCardToastPanel"
	panel.add_theme_stylebox_override("panel", _card_toast_style)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	toast_vbox.add_child(panel)

	_card_toast_btn = Button.new()
	_card_toast_btn.name = "ScienceCardToastButton"
	_card_toast_btn.flat = true
	_card_toast_btn.custom_minimum_size = Vector2(240, 52)
	_card_toast_btn.focus_mode = Control.FOCUS_NONE
	_card_toast_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_card_toast_btn.pressed.connect(_on_card_toast_pressed)
	panel.add_child(_card_toast_btn)

	var hbox := HBoxContainer.new()
	hbox.name = "ContentRow"
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	_card_toast_icon = TextureRect.new()
	_card_toast_icon.name = "Icon"
	_card_toast_icon.custom_minimum_size = Vector2(24, 24)
	_card_toast_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_card_toast_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card_toast_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_toast_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_card_toast_icon)

	_card_toast_badge = Label.new()
	_card_toast_badge.name = "BadgeLabel"
	_card_toast_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_card_toast_badge.add_theme_font_size_override("font_size", 16)
	_card_toast_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_card_toast_badge)

	var sep := Label.new()
	sep.text = "-"
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sep.add_theme_color_override("font_color", UIColors.MUTED)
	sep.add_theme_font_size_override("font_size", 16)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(sep)

	_card_toast_title = Label.new()
	_card_toast_title.name = "TitleLabel"
	_card_toast_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_card_toast_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_card_toast_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_card_toast_title.clip_text = true
	_card_toast_title.add_theme_color_override("font_color", UIColors.TEXT)
	_card_toast_title.add_theme_font_size_override("font_size", 17)
	_card_toast_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_card_toast_title)

	_card_pickup_hint = PanelContainer.new()
	_card_pickup_hint.name = "ScienceCardPickupHint"
	_card_pickup_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color("141821F5")
	hint_style.border_color = UIColors.POWER
	hint_style.set_border_width_all(2)
	hint_style.set_corner_radius_all(10)
	hint_style.content_margin_left = 12
	hint_style.content_margin_right = 12
	hint_style.content_margin_top = 4
	hint_style.content_margin_bottom = 4
	_card_pickup_hint.add_theme_stylebox_override("panel", hint_style)
	_card_pickup_hint.mouse_filter = Control.MOUSE_FILTER_PASS
	_card_pickup_hint.visible = false

	var hint_hbox := HBoxContainer.new()
	hint_hbox.name = "HintHBox"
	hint_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_hbox.add_theme_constant_override("separation", 6)
	_card_pickup_hint.add_child(hint_hbox)

	var arrow_lbl := Label.new()
	arrow_lbl.text = "▲"
	arrow_lbl.add_theme_color_override("font_color", UIColors.POWER)
	arrow_lbl.add_theme_font_size_override("font_size", 14)
	arrow_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_hbox.add_child(arrow_lbl)

	var hint_lbl := Label.new()
	hint_lbl.name = "HintLabel"
	hint_lbl.text = tr("CARD_PICKUP_HINT")
	hint_lbl.add_theme_color_override("font_color", UIColors.TEXT)
	hint_lbl.add_theme_font_size_override("font_size", 15)
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_hbox.add_child(hint_lbl)

	_card_pickup_hint.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			_on_card_toast_pressed()
	)
	toast_vbox.add_child(_card_pickup_hint)

	_update_card_toast_position()


func _update_card_toast_position() -> void:
	if _card_toast_wrap == null:
		return
	var insets := SafeArea.get_insets(self)
	var t: float = float(insets.get("top", 0))
	var l: float = float(insets.get("left", 0))
	var r: float = float(insets.get("right", 0))
	var banner_open: bool = select_banner_panel != null and select_banner_panel.visible
	var y_top: float = (128.0 + t) if banner_open else (75.0 + t)
	_card_toast_wrap.offset_top = y_top
	_card_toast_wrap.offset_bottom = y_top + 104.0
	_card_toast_wrap.offset_left = l + 12.0
	_card_toast_wrap.offset_right = -r - 12.0
	if _card_toast_title != null:
		var vp_w: float = get_viewport_rect().size.x if (is_inside_tree() and get_viewport() != null) else 1280.0
		var max_title_w: float = clampf(vp_w - l - r - 280.0, 110.0, 380.0)
		_card_toast_title.custom_minimum_size = Vector2(minf(max_title_w, 220.0), 0.0)


func show_science_card_toast(fact_id: String, is_quiet: bool = false) -> void:
	_ensure_nodes()
	_ensure_card_toast_ui()
	if fact_id.is_empty():
		return
	if toast_panel != null and toast_panel.visible:
		toast_panel.visible = false
		if _toast_tween != null and _toast_tween.is_valid():
			_toast_tween.kill()

	_card_toast_fact_id = fact_id
	_card_toast_is_quiet = is_quiet
	_refresh_card_toast_texts()
	_update_card_toast_position()

	if _card_toast_tween != null and _card_toast_tween.is_valid():
		_card_toast_tween.kill()
		_card_toast_tween = null
	if _card_pickup_tween != null and _card_pickup_tween.is_valid():
		_card_pickup_tween.kill()
		_card_pickup_tween = null

	var is_first: bool = (Settings != null and not Settings.card_first_pickup_done)
	if _card_pickup_hint != null:
		_card_pickup_hint.visible = is_first
		if is_first:
			var hint_lbl: Label = _card_pickup_hint.get_node_or_null("HintHBox/HintLabel") as Label
			if hint_lbl != null:
				hint_lbl.text = tr("CARD_PICKUP_HINT")

	_card_toast_wrap.visible = true
	_card_toast_wrap.modulate.a = 0.0

	if not is_quiet and Audio != null:
		Audio.play("ui_confirm")

	if not is_inside_tree():
		_card_toast_wrap.modulate.a = 1.0
		return

	if is_first:
		# First-time card pickup: hold indefinitely until tapped!
		_card_toast_tween = create_tween()
		_card_toast_tween.tween_property(_card_toast_wrap, "modulate:a", 1.0, 0.2)
		_card_pickup_tween = create_tween().set_loops()
		_card_pickup_tween.tween_property(_card_pickup_hint, "modulate:a", 0.45, 0.6)
		_card_pickup_tween.tween_property(_card_pickup_hint, "modulate:a", 1.0, 0.6)
	else:
		var hold_sec: float = CARD_QUIET_HOLD_SEC if is_quiet else CARD_TOAST_HOLD_SEC
		_card_toast_tween = create_tween()
		_card_toast_tween.tween_property(_card_toast_wrap, "modulate:a", 1.0, 0.2)
		_card_toast_tween.tween_interval(hold_sec)
		_card_toast_tween.tween_property(_card_toast_wrap, "modulate:a", 0.0, 0.25)
		_card_toast_tween.tween_callback(_on_card_toast_timeout)


func hide_science_card_toast(silent: bool = true) -> void:
	if _card_toast_tween != null and _card_toast_tween.is_valid():
		_card_toast_tween.kill()
		_card_toast_tween = null
	if _card_pickup_tween != null and _card_pickup_tween.is_valid():
		_card_pickup_tween.kill()
		_card_pickup_tween = null
	if _card_pickup_hint != null:
		_card_pickup_hint.visible = false
	var was_open: bool = _card_toast_wrap != null and _card_toast_wrap.visible
	if _card_toast_wrap != null:
		_card_toast_wrap.visible = false
	var fid: String = _card_toast_fact_id
	var quiet_flag: bool = _card_toast_is_quiet
	_card_toast_fact_id = ""
	if was_open and not silent and not fid.is_empty():
		science_card_notification_finished.emit(fid, quiet_flag)


func is_science_card_toast_showing() -> bool:
	return _card_toast_wrap != null and _card_toast_wrap.visible


func _refresh_card_toast_texts() -> void:
	if _card_toast_wrap == null or _card_toast_fact_id.is_empty():
		return
	var card: Dictionary = _card_learning.card_by_fact_id(_card_toast_fact_id)
	var cat: String = str(card.get("category", "moon"))
	var accent: Color = UIColors.WATER if _card_toast_is_quiet else LearningDataScript.category_color(cat)
	if _card_toast_style != null:
		_card_toast_style.border_color = accent
	if _card_toast_icon != null:
		_card_toast_icon.texture = ICON_ROCKET if _card_toast_is_quiet else LearningDataScript.card_icon(card)
		_card_toast_icon.modulate = accent
	if _card_toast_badge != null:
		_card_toast_badge.text = tr("CARD_DID_YOU_KNOW") if _card_toast_is_quiet else tr("CARD_NEW")
		_card_toast_badge.add_theme_color_override("font_color", accent)
	if _card_toast_title != null:
		var title_txt: String = _card_learning.text(card.get("title", {}))
		var final_title: String = title_txt if not title_txt.is_empty() else _card_toast_fact_id
		_card_toast_title.text = final_title
		var insets := SafeArea.get_insets(self)
		var vp_w: float = get_viewport_rect().size.x if (is_inside_tree() and get_viewport() != null) else 1280.0
		var max_title_w: float = clampf(vp_w - float(insets.get("left", 0)) - float(insets.get("right", 0)) - 280.0, 110.0, 380.0)
		var font: Font = _card_toast_title.get_theme_font("font")
		var nat_w: float = font.get_string_size(final_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 6.0 if font != null else float(final_title.length() * 9)
		_card_toast_title.custom_minimum_size = Vector2(clampf(nat_w, 60.0, max_title_w), 0.0)
	if _card_pickup_hint != null and _card_pickup_hint.visible:
		var hint_lbl: Label = _card_pickup_hint.get_node_or_null("HintHBox/HintLabel") as Label
		if hint_lbl != null:
			hint_lbl.text = tr("CARD_PICKUP_HINT")


func _on_card_toast_pressed() -> void:
	if _card_toast_fact_id.is_empty():
		return
	if Settings != null:
		Settings.card_first_pickup_done = true
	if _card_pickup_tween != null and _card_pickup_tween.is_valid():
		_card_pickup_tween.kill()
		_card_pickup_tween = null
	if _card_pickup_hint != null:
		_card_pickup_hint.visible = false
	var fid: String = _card_toast_fact_id
	var quiet_flag: bool = _card_toast_is_quiet
	hide_science_card_toast(true)
	science_card_notification_pressed.emit(fid, quiet_flag)
	hide_science_card_toast(true)
	science_card_notification_pressed.emit(fid, quiet_flag)


func _on_card_toast_timeout() -> void:
	var fid: String = _card_toast_fact_id
	var quiet_flag: bool = _card_toast_is_quiet
	if _card_toast_wrap != null:
		_card_toast_wrap.visible = false
	_card_toast_fact_id = ""
	if not fid.is_empty():
		science_card_notification_finished.emit(fid, quiet_flag)


# --- Kid Gauges & Tip Bubble (M-07) ---

func _normalize_battery_pct(raw_pct: float) -> float:
	if raw_pct > 0.0 and raw_pct <= 1.0:
		return raw_pct * 100.0
	return raw_pct


func _render_all_gauges() -> void:
	var sci_on: bool = _is_science_view()
	_render_battery_gauge(sci_on)
	_render_o2_gauge(sci_on)
	_render_air_gauge(sci_on)
	_render_days_supply_gauge(water_gauge, _last_water_days_left, _last_water_kg, true, _last_recycler_broken, sci_on)
	_render_days_supply_gauge(food_gauge, _last_food_days_left, _last_food_kg, false, false, sci_on)
	_render_rad_gauge(sci_on)
	_render_storm_gauge(sci_on)


func _render_battery_gauge(sci_on: bool) -> void:
	if power_gauge == null:
		return
	var pct: float = clampf(_last_battery_pct, 0.0, 100.0)
	var pct_int: int = roundi(pct)
	if _last_battery_blackout or pct < BATTERY_WARN_PERCENT:
		power_gauge.set_state("critical", _last_battery_blackout or pct <= 0.01)
	elif pct < BATTERY_GREEN_PERCENT:
		power_gauge.set_state("warn")
	else:
		power_gauge.set_state("normal")

	power_gauge.set_value(pct, 100.0, "")
	power_gauge.set_primary_kid_text("%d%%" % pct_int, true)

	var arrow_dir: String = ""
	var arrow_txt: String = ""
	var arrow_col: Color = UIColors.MUTED
	if _battery_trend == "up":
		arrow_dir = "up"
		arrow_txt = _tr_fallback("KID_CHARGING", "Charging")
		arrow_col = UIColors.OXYGEN
	elif _battery_trend == "down":
		arrow_dir = "down"
		arrow_txt = _tr_fallback("KID_DRAINING", "Draining")
		arrow_col = UIColors.ALERT if pct < BATTERY_WARN_PERCENT else UIColors.POWER
	power_gauge.set_battery_visual(true, pct / 100.0, arrow_dir, arrow_txt, arrow_col)

	if sci_on:
		var cap_txt: String = "%.0f / %.0f kWh" % [_last_battery_kwh, maxf(_last_battery_cap_kwh, _last_battery_kwh)] if _last_battery_cap_kwh > 0.0 else "%.0f kWh" % _last_battery_kwh
		power_gauge.set_science_subtext(cap_txt)
	else:
		power_gauge.set_science_subtext("")


func _render_o2_gauge(sci_on: bool) -> void:
	if o2_gauge == null:
		return
	var warn_days: float = float(Constants.v("SUPPLY_WARNING_DAYS")) if Constants != null else 3.0
	if _last_o2_kg <= 0.0:
		o2_gauge.set_state("critical")
	elif _last_o2_days_left < warn_days - 0.0001:
		o2_gauge.set_state("warn")
	else:
		o2_gauge.set_state("normal")
	o2_gauge.set_value(_last_o2_kg, maxf(1.0, max_o2_packed), "%d kg" % roundi(_last_o2_kg))
	o2_gauge.set_primary_kid_text("%d kg" % roundi(_last_o2_kg), true)
	var air_word: String = _tr_fallback("KID_AIR_MACHINE_OFF", "Air machine: OFF!") if _last_air_machine_off else _tr_fallback("KID_AIR_MACHINE_ON", "Air machine: on")
	o2_gauge.set_extra_status(air_word, UIColors.ALERT if _last_air_machine_off else UIColors.OXYGEN)
	var days_i: int = maxi(0, floori(maxf(0.0, _last_o2_days_left) + 0.001))
	o2_gauge.set_science_subtext(_tr_fallback("KID_DAYS_LEFT", "{n} days left").format({"n": days_i}) if sci_on else "")


func _render_air_gauge(sci_on: bool) -> void:
	if co2_gauge == null:
		return
	_update_co2_status_word(_last_co2_mmhg)
	if _last_air_level == "danger":
		co2_gauge.set_state("critical")
	elif _last_air_level == "stuffy":
		co2_gauge.set_state("warn")
	else:
		co2_gauge.set_state("normal")

	if sci_on:
		var evac_limit: float = float(Constants.v("CO2_EVAC_MMHG")) if Constants != null else 6.0
		co2_gauge.set_value(_last_co2_mmhg, evac_limit, "")
	else:
		var kid_fill: float = 60.0 if _last_air_level == "stuffy" else 100.0
		co2_gauge.set_value(kid_fill, 100.0, "")
	_update_co2_status_word(_last_co2_mmhg)

	if _last_air_machine_off:
		co2_gauge.set_extra_status(_tr_fallback("KID_AIR_MACHINE_OFF", "Air machine: OFF!"), UIColors.ALERT)
	else:
		co2_gauge.set_extra_status("")

	if sci_on:
		var machine_str: String = _tr_fallback("KID_AIR_MACHINE_OFF" if _last_air_machine_off else "KID_AIR_MACHINE_ON", "")
		co2_gauge.set_science_subtext("%.1f mmHg · %s" % [_last_co2_mmhg, machine_str])
	else:
		co2_gauge.set_science_subtext("")


func _render_days_supply_gauge(gauge: Gauge, days_left: float, kg_val: float, is_water: bool, recycler_broken: bool, sci_on: bool) -> void:
	if gauge == null:
		return
	var warn_days: float = float(Constants.v("SUPPLY_WARNING_DAYS")) if Constants != null else 3.0
	var enough_to_end: bool = (days_left + 0.0001) >= float(_last_days_to_go)
	if days_left < warn_days - 0.0001:
		gauge.set_state("critical")
	elif not enough_to_end:
		gauge.set_state("warn")
	else:
		gauge.set_state("normal")

	var bar_max: float = maxf(1.0, float(_mission_total_days))
	gauge.set_value(clampf(days_left, 0.0, bar_max), bar_max, "")
	var shown_days: int = maxi(0, floori(maxf(0.0, days_left) + 0.001))
	gauge.set_primary_kid_text(_tr_fallback("KID_DAYS_LEFT", "{n} days left").format({"n": shown_days}), true)

	if is_water and recycler_broken:
		gauge.set_extra_status(_tr_fallback("KID_RECYCLER_BROKEN", "Water recycler: broken!"), UIColors.ALERT, "")
	elif enough_to_end:
		gauge.set_extra_status(_tr_fallback("KID_ENOUGH", "Enough!"), UIColors.OXYGEN, "check")
	elif is_water and sci_on:
		gauge.set_extra_status(_tr_fallback("KID_RECYCLER_OK", "Water recycler: OK"), UIColors.MUTED, "")
	else:
		gauge.set_extra_status("", UIColors.MUTED, "")

	if sci_on:
		if is_water:
			var rec_str: String = _tr_fallback("KID_RECYCLER_BROKEN" if recycler_broken else "KID_RECYCLER_OK", "")
			gauge.set_science_subtext("%.0f kg · %s" % [kg_val, rec_str])
		else:
			gauge.set_science_subtext("%.0f kg" % kg_val)
	else:
		gauge.set_science_subtext("")


func _render_rad_gauge(sci_on: bool) -> void:
	if rad_gauge == null:
		return
	var spe_limit: float = float(Constants.v("RAD_SPE_LIMIT_MSV")) if Constants != null else 250.0
	if _last_rad_msv >= spe_limit:
		rad_gauge.set_state("critical")
	elif _last_rad_msv >= spe_limit * STORM_TWO_PIP_FRAC:
		rad_gauge.set_state("warn")
	else:
		rad_gauge.set_state("normal")
	rad_gauge.set_value(_last_rad_msv, spe_limit, "")
	rad_gauge.set_primary_kid_text("%d mSv" % roundi(_last_rad_msv), true)
	rad_gauge.set_science_subtext("%.1f mSv" % _last_rad_msv if sci_on else "")


func _render_storm_gauge(sci_on: bool) -> void:
	if shelter_gauge == null:
		return
	var spe_limit: float = float(Constants.v("RAD_SPE_LIMIT_MSV")) if Constants != null else 250.0
	var pips: int = 0
	if _last_storm_dose_if_now_msv <= spe_limit * STORM_THREE_PIP_FRAC + 0.001:
		pips = 3
	elif _last_storm_dose_if_now_msv <= spe_limit * STORM_TWO_PIP_FRAC + 0.001:
		pips = 2
	elif _last_storm_dose_if_now_msv <= spe_limit + 0.001:
		pips = 1
	_last_storm_pips = pips

	var pip_col: Color = UIColors.OXYGEN
	var empty_col: Color = Color(0.55, 0.60, 0.68, 0.28)
	if pips == 0:
		shelter_gauge.set_state("critical")
		pip_col = UIColors.ALERT
		empty_col = Color(0.88, 0.28, 0.28, 0.30)
		shelter_gauge.set_value(0.0, 3.0, "")
		shelter_gauge.set_primary_kid_text(_tr_fallback("KID_STORM_NOT_SAFE", "Not safe!"), true)
		shelter_gauge.set_primary_mark("cross", UIColors.ALERT)
	elif pips == 1:
		shelter_gauge.set_state("warn")
		pip_col = UIColors.POWER
		shelter_gauge.set_value(1.0, 3.0, "")
		shelter_gauge.set_primary_kid_text(_tr_fallback("KID_STORM_SAFE", "Safe"), true)
		shelter_gauge.set_primary_mark("check", UIColors.POWER)
	else:
		shelter_gauge.set_state("normal")
		shelter_gauge.set_value(float(pips), 3.0, "")
		shelter_gauge.set_primary_kid_text(_tr_fallback("KID_STORM_SAFE", "Safe"), true)
		shelter_gauge.set_primary_mark("check", UIColors.OXYGEN)

	shelter_gauge.set_shield_pips(true, pips, pip_col, empty_col)
	if sci_on:
		shelter_gauge.set_science_subtext("%.1f g/cm² · %.0f mSv" % [_last_shelter_g, _last_storm_dose_if_now_msv])
	else:
		shelter_gauge.set_science_subtext("")


func get_gauge_by_key(gkey: String) -> Gauge:
	match gkey.to_lower():
		"battery", "power":
			return power_gauge
		"o2", "oxygen":
			return o2_gauge
		"air", "co2":
			return co2_gauge
		"water":
			return water_gauge
		"food":
			return food_gauge
		"rad", "radiation":
			return rad_gauge
		"storm", "shelter":
			return shelter_gauge
	return null


func evaluate_gauge_tip(gkey: String) -> Dictionary:
	var key_norm: String = gkey.to_lower()
	var sunset_day: int = int(Constants.v("SUNSET_DAY")) if Constants != null else 15
	var is_night: bool = current_day >= sunset_day
	match key_norm:
		"water":
			if _last_recycler_broken:
				return {"tip_key": "TIP_WATER_REPAIR", "show_me": "life_support"}
			if water_gauge != null and water_gauge.current_state != GaugeScript.State.NORMAL:
				return {"tip_key": "TIP_WATER_PACK", "show_me": ""}
		"food":
			if food_gauge != null and food_gauge.current_state != GaugeScript.State.NORMAL:
				return {"tip_key": "TIP_FOOD_PACK", "show_me": ""}
		"air", "co2":
			if _last_air_level == "stuffy" or _last_air_level == "danger":
				return {"tip_key": "TIP_AIR_POWER", "show_me": "greenhouse_switch"}
		"battery", "power":
			var bat_crit: bool = power_gauge != null and power_gauge.current_state == GaugeScript.State.CRITICAL
			var bat_warn: bool = power_gauge != null and power_gauge.current_state == GaugeScript.State.WARN
			if bat_crit or (bat_warn and is_night):
				return {"tip_key": "TIP_BATTERY_NIGHT", "show_me": "greenhouse_switch"}
		"storm", "shelter":
			if _last_storm_pips == 0:
				return {"tip_key": "TIP_STORM_DIG", "show_me": "dig_site"}
	return {"tip_key": "TIP_ALL_GOOD", "show_me": ""}


func tap_gauge(gauge_or_key: Variant) -> void:
	var g: Gauge = gauge_or_key as Gauge if gauge_or_key is Gauge else get_gauge_by_key(str(gauge_or_key))
	if g != null:
		_on_gauge_tapped(g)


func _on_gauge_tapped(gauge: Gauge) -> void:
	if gauge == null or is_resolving:
		return
	var gkey: String = gauge.gauge_key
	if tip_panel != null and tip_panel.visible and _active_tip_gauge_key == gkey:
		_hide_tip_bubble()
		return
	_ensure_tip_bubble()
	var info: Dictionary = evaluate_gauge_tip(gkey)
	_active_tip_gauge_key = gkey
	_active_tip_key = str(info.get("tip_key", "TIP_ALL_GOOD"))
	_active_tip_target = str(info.get("show_me", ""))
	if Audio != null:
		Audio.play("ui_click")
	_refresh_tip_bubble_texts()
	if _tip_style != null:
		var border_col: Color = UIColors.OXYGEN
		if gauge.current_state == GaugeScript.State.CRITICAL:
			border_col = UIColors.ALERT
		elif gauge.current_state == GaugeScript.State.WARN:
			border_col = UIColors.POWER
		_tip_style.border_color = border_col
	tip_panel.visible = true
	_position_tip_bubble(gauge)


func _ensure_tip_bubble() -> void:
	if tip_panel != null:
		return
	tip_panel = PanelContainer.new()
	tip_panel.name = "GaugeTipBubble"
	tip_panel.visible = false
	tip_panel.z_index = 25
	tip_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	tip_panel.custom_minimum_size = Vector2(220, 0)

	_tip_style = StyleBoxFlat.new()
	_tip_style.bg_color = Color("141821F5")
	_tip_style.border_color = UIColors.OXYGEN
	_tip_style.set_border_width_all(2)
	_tip_style.set_corner_radius_all(10)
	_tip_style.content_margin_left = 12
	_tip_style.content_margin_right = 12
	_tip_style.content_margin_top = 10
	_tip_style.content_margin_bottom = 10
	_tip_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	_tip_style.shadow_size = 10
	_tip_style.shadow_offset = Vector2(0, 4)
	tip_panel.add_theme_stylebox_override("panel", _tip_style)
	add_child(tip_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_panel.add_child(vbox)

	tip_label = Label.new()
	tip_label.name = "TipLabel"
	tip_label.custom_minimum_size = Vector2(200, 0)
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.add_theme_color_override("font_color", UIColors.TEXT)
	tip_label.add_theme_font_size_override("font_size", 14)
	tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(tip_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(actions)

	tip_show_me_btn = Button.new()
	tip_show_me_btn.name = "ShowMeButton"
	tip_show_me_btn.custom_minimum_size = Vector2(120, 44)
	tip_show_me_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip_show_me_btn.focus_mode = Control.FOCUS_NONE
	tip_show_me_btn.add_theme_color_override("font_color", UIColors.POWER)
	tip_show_me_btn.pressed.connect(_on_tip_show_me_pressed)
	actions.add_child(tip_show_me_btn)

	tip_close_btn = Button.new()
	tip_close_btn.name = "CloseTipButton"
	tip_close_btn.text = "X"
	tip_close_btn.custom_minimum_size = Vector2(44, 44)
	tip_close_btn.focus_mode = Control.FOCUS_NONE
	tip_close_btn.pressed.connect(_hide_tip_bubble)
	actions.add_child(tip_close_btn)


func _refresh_tip_bubble_texts() -> void:
	if tip_panel == null or _active_tip_key.is_empty():
		return
	var fallback_map: Dictionary = {
		"TIP_WATER_REPAIR": "The water recycler is broken. Send someone to Repair it!",
		"TIP_WATER_PACK": "Water is running low. Pack more water next time.",
		"TIP_FOOD_PACK": "Food is running low. Pack more food next time.",
		"TIP_AIR_POWER": "The air machine needs power. Turn off the greenhouse lights to save power.",
		"TIP_BATTERY_NIGHT": "The night is long! Save power for the air machine.",
		"TIP_STORM_DIG": "Not safe from a solar storm! Send crew to Dig moon soil over the shelter.",
		"TIP_ALL_GOOD": "All good!",
	}
	if tip_label != null:
		tip_label.text = _tr_fallback(_active_tip_key, str(fallback_map.get(_active_tip_key, "All good!")))
	if tip_show_me_btn != null:
		tip_show_me_btn.text = _tr_fallback("KID_SHOW_ME", "Show me")
		tip_show_me_btn.visible = not _active_tip_target.is_empty()


func _position_tip_bubble(gauge: Gauge) -> void:
	if tip_panel == null or gauge == null:
		return
	var g_rect: Rect2 = gauge.get_global_rect()
	var vp_size: Vector2 = get_viewport_rect().size if (is_inside_tree() and get_viewport() != null) else Vector2(1280.0, 720.0)
	if vp_size.x <= 0.0:
		vp_size = Vector2(1280.0, 720.0)
	var bubble_size: Vector2 = tip_panel.get_combined_minimum_size()
	bubble_size.x = maxf(bubble_size.x, 240.0)
	bubble_size.y = maxf(bubble_size.y, 70.0)
	tip_panel.size = bubble_size

	var pos_x: float = g_rect.end.x + 8.0
	if pos_x + bubble_size.x > vp_size.x - 8.0:
		pos_x = maxf(8.0, vp_size.x - bubble_size.x - 8.0)
	var pos_y: float = g_rect.position.y
	if pos_x <= g_rect.end.x + 2.0 and vp_size.x < 560.0:
		pos_y = g_rect.end.y + 6.0
	pos_y = clampf(pos_y, 8.0, maxf(8.0, vp_size.y - bubble_size.y - 8.0))
	tip_panel.position = Vector2(pos_x, pos_y)


func _on_tip_show_me_pressed() -> void:
	if _active_tip_target.is_empty():
		_hide_tip_bubble()
		return
	var target: String = _active_tip_target
	last_show_me_target = target
	_hide_tip_bubble()
	if Audio != null:
		Audio.play("ui_confirm")

	if target == "greenhouse_switch":
		_pulse_greenhouse_switch()
		return

	var chosen_idx: int = _pick_crew_for_show_me()
	if chosen_idx >= 0:
		if selected_crew_index != chosen_idx:
			select_crew(chosen_idx, false)
		elif _building_markers.is_empty():
			_rebuild_building_markers()
	var marker = _building_markers.get(target, null)
	if marker != null and marker.has_method("pulse_highlight"):
		marker.call("pulse_highlight")


func _pick_crew_for_show_me() -> int:
	if crew_cards.is_empty():
		return -1
	if selected_crew_index >= 0 and selected_crew_index < crew_cards.size():
		var sel = crew_cards[selected_crew_index]
		if sel != null and not bool(sel.is_sick):
			return selected_crew_index
	for i in range(crew_cards.size()):
		var c = crew_cards[i]
		if c != null and not bool(c.is_sick) and c.get_job() == SimPlanScript.JOB_REST:
			return i
	for i in range(crew_cards.size()):
		var c = crew_cards[i]
		if c != null and not bool(c.is_sick):
			return i
	return 0


func _pulse_greenhouse_switch() -> void:
	if greenhouse_switch == null:
		return
	if _greenhouse_pulse_tween != null and _greenhouse_pulse_tween.is_valid():
		_greenhouse_pulse_tween.kill()
	if not is_inside_tree():
		return
	greenhouse_switch.pivot_offset = greenhouse_switch.size * 0.5
	_greenhouse_pulse_tween = greenhouse_switch.create_tween()
	for _i in range(3):
		_greenhouse_pulse_tween.tween_property(greenhouse_switch, "scale", Vector2(1.12, 1.12), 0.15)
		_greenhouse_pulse_tween.parallel().tween_property(greenhouse_switch, "modulate", Color(1.35, 1.2, 0.55, 1.0), 0.15)
		_greenhouse_pulse_tween.tween_property(greenhouse_switch, "scale", Vector2.ONE, 0.16)
		_greenhouse_pulse_tween.parallel().tween_property(greenhouse_switch, "modulate", Color.WHITE, 0.16)
	_greenhouse_pulse_tween.tween_callback(_update_switches_ui)


func _hide_tip_bubble() -> void:
	if tip_panel != null:
		tip_panel.visible = false
	_active_tip_gauge_key = ""
	_active_tip_key = ""
	_active_tip_target = ""


func _input(event: InputEvent) -> void:
	if tip_panel == null or not tip_panel.visible:
		return
	var press_pos := Vector2(-1.0, -1.0)
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		press_pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.device != InputEvent.DEVICE_ID_EMULATION:
			press_pos = mb.position
	if press_pos.x < 0.0:
		return
	if tip_panel.get_global_rect().has_point(press_pos):
		return
	var gauges_box := get_node_or_null("LeftColumn/Gauges") as Control
	if gauges_box != null and gauges_box.get_global_rect().has_point(press_pos):
		return
	_hide_tip_bubble()


