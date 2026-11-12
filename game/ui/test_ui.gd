extends Control

@onready var gauge_power: Gauge = $Margin/VBox/WidgetsGrid/GaugePower
@onready var gauge_water: Gauge = $Margin/VBox/WidgetsGrid/GaugeWater
@onready var gauge_alert: Gauge = $Margin/VBox/WidgetsGrid/GaugeAlert

@onready var tag_cargo: SourceTag = $Margin/VBox/TagsRow/CardCargo/Margin/HBox/TagCargo
@onready var tag_solar: SourceTag = $Margin/VBox/TagsRow/CardSolar/Margin/HBox/TagSolar
@onready var tag_rad: SourceTag = $Margin/VBox/TagsRow/CardRad/Margin/HBox/TagRad

@onready var btn_popup: Button = $Margin/VBox/ActionsRow/BtnPopup
@onready var btn_sources: Button = $Margin/VBox/ActionsRow/BtnSources

@onready var event_popup: EventPopup = $EventPopup
@onready var sources_screen: SourcesScreen = $SourcesScreen

const ICON_BOLT: Texture2D = preload("res://assets/icons/bolt.svg")
const ICON_WATER: Texture2D = preload("res://assets/icons/water_drop.svg")
const ICON_WARN: Texture2D = preload("res://assets/icons/warning.svg")

func _ready() -> void:
	# Configure 3 Gauges
	gauge_power.setup(ICON_BOLT, "kW", UIColors.POWER, "SOLAR_UNIT_KW", "Power Generation")
	gauge_power.set_value(14.0, 20.0)
	gauge_power.set_state("normal")

	gauge_water.setup(ICON_WATER, "kg", UIColors.WATER, "WATER_KG_PERSON_DAY", "Water Storage")
	gauge_water.set_value(35.0, 100.0)
	gauge_water.set_state("warn")

	gauge_alert.setup(ICON_WARN, "mSv", UIColors.ALERT, "RAD_SPE_LIMIT_MSV", "Radiation Level")
	gauge_alert.set_value(280.0, 250.0)
	gauge_alert.set_state("critical")

	# Configure 3 SourceTags
	tag_cargo.setup("CARGO_LIMIT_KG")
	tag_solar.setup("SOLAR_UNIT_KW")
	tag_rad.setup("RAD_SPE_LIMIT_MSV")

	# Wire buttons
	btn_popup.pressed.connect(_on_btn_popup_pressed)
	btn_sources.pressed.connect(_on_btn_sources_pressed)
	sources_screen.back_pressed.connect(_on_sources_back_pressed)
	sources_screen.visible = false

func _on_btn_popup_pressed() -> void:
	event_popup.popup_event(
		"Solar Storm Alert",
		"Solar storm warning received! High proton flux expected in 15 minutes.",
		["Go to Shelter", "Stay at Posts"],
		ICON_WARN
	)

func _on_btn_sources_pressed() -> void:
	sources_screen.visible = true

func _on_sources_back_pressed() -> void:
	sources_screen.visible = false
