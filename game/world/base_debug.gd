extends Node3D

const BaseStationScript := preload("res://world/base.gd")
const SimConstantsScript := preload("res://sim/sim_constants.gd")
const SimMissionScript := preload("res://sim/sim_mission.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimPlanScript := preload("res://sim/sim_plan.gd")

@onready var base: Node3D = $Base
@onready var sky_rig: Node3D = get_node_or_null("SkyRig")
@onready var status_label: Label = $CanvasLayer/Panel/VBoxContainer/StatusLabel
@onready var info_label: Label = $CanvasLayer/Panel/VBoxContainer/InfoLabel

const S01_CARGO := {
	"solar": 20,
	"battery": 10,
	"reactor": 0,
	"greenhouse": 0,
	"o2": 2,
	"water": 4,
	"food": 5,
	"shield": 10
}
const S01_FORCE := {
	"storm_day": 10,
	"recycler_day": 99,
	"meteoroid_day": 0
}

const S07_CARGO := {
	"solar": 24,
	"battery": 6,
	"reactor": 2,
	"greenhouse": 10,
	"o2": 2,
	"water": 4,
	"food": 5,
	"shield": 10
}
const S07_FORCE := {
	"storm_day": 12,
	"recycler_day": 14,
	"meteoroid_day": 20
}

const NO_GH_CARGO := {
	"solar": 24,
	"battery": 6,
	"reactor": 2,
	"greenhouse": 0,
	"o2": 2,
	"water": 4,
	"food": 5,
	"shield": 10
}

const OVER_BATTERY_CARGO := {
	"solar": 24,
	"battery": 16,
	"reactor": 2,
	"greenhouse": 10,
	"o2": 2,
	"water": 4,
	"food": 5,
	"shield": 10
}

const S08_CARGO := {
	"solar": 40,
	"battery": 60,
	"reactor": 3,
	"greenhouse": 20,
	"o2": 20,
	"water": 20,
	"food": 20,
	"shield": 20
}

var _current_mode := "S07"
var _mission: RefCounted = null
var _sim_constants: SimConstants = null
var _scenario_rule: String = "SMART"
var _last_report: RefCounted = null

func _ready() -> void:
	_init_sim_constants()
	_load_scenario("S07", S07_CARGO, S07_FORCE, "SMART")

func _init_sim_constants() -> void:
	if _sim_constants != null:
		return
	if is_inside_tree() and get_node_or_null("/root/Constants") != null:
		var c_node = get_node("/root/Constants")
		if "sim" in c_node and c_node.sim != null:
			_sim_constants = c_node.sim
	if _sim_constants == null:
		var txt := FileAccess.get_file_as_string("res://data/constants.json")
		_sim_constants = SimConstantsScript.from_json(txt)

func _process(_delta: float) -> void:
	if info_label != null:
		var dc: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var objs: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		var fps: float = Performance.get_monitor(Performance.TIME_FPS)
		var scale_val: float = get_viewport().scaling_3d_scale if get_viewport() != null else 1.0
		info_label.text = "FPS: %d | DC: %d | Objs: %d | Scale: %.2f" % [fps, dc, objs, scale_val]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			step_day()
		elif event.keycode == KEY_1:
			_load_scenario("S01", S01_CARGO, S01_FORCE, "REST")
		elif event.keycode == KEY_7:
			_load_scenario("S07", S07_CARGO, S07_FORCE, "SMART")
		elif event.keycode == KEY_8:
			_on_btn_s08_pressed()
		elif event.keycode == KEY_B:
			jump_to_day_16()
		elif event.keycode == KEY_E:
			_on_btn_evac_pressed()

func _load_scenario(mode_name: String, cargo_dict: Dictionary, force: Dictionary, rule: String) -> void:
	_init_sim_constants()
	_current_mode = mode_name
	_scenario_rule = rule
	_last_report = null

	var cargo := SimCargoScript.new(_sim_constants)
	cargo.load_dict(cargo_dict)

	_mission = SimMissionScript.new(_sim_constants, cargo, 1, force)
	base.call("build_from_cargo", cargo_dict)
	if has_node("Crew"):
		var crew_node = get_node("Crew")
		var init_plan := _build_plan(rule, 1, _get_state_for_plan(), _sim_constants)
		crew_node.call("apply_plan", init_plan)
	if sky_rig != null:
		sky_rig.call("set_day", 1, 0.0)
	_update_ui()
	print("BaseDebug: Loaded %s (Rule: %s)" % [mode_name, rule])

func _load_static_mode(mode_name: String, cargo_dict: Dictionary) -> void:
	_current_mode = mode_name
	_mission = null
	_last_report = null
	base.call("build_from_cargo", cargo_dict)
	if sky_rig != null:
		sky_rig.call("set_day", 1, 0.0)
	if status_label != null:
		status_label.text = "Mode: %s (Greenhouse: %d m², Solar: %d, Battery: %d, Reactor: %d)" % [
			mode_name,
			cargo_dict.get("greenhouse", 0),
			cargo_dict.get("solar", 0),
			cargo_dict.get("battery", 0),
			cargo_dict.get("reactor", 0)
		]
	print("BaseDebug: Loaded static mode %s" % mode_name)

func step_day() -> RefCounted:
	if _mission == null:
		print("BaseDebug: No active simulation scenario to step")
		return null
	if _mission.ended:
		print("BaseDebug: Mission already ended on Day %d (Outcome: %s)" % [_mission.day, _mission.result.outcome if _mission.result != null else "ended"])
		return null

	var current_day: int = _mission.day
	var state := _get_state_for_plan()
	var plan := _build_plan(_scenario_rule, current_day, state, _sim_constants)
	var report = _mission.step_day(plan)
	_last_report = report
	base.call("apply_report", report)
	if has_node("Crew"):
		$Crew.call("apply_report", report)
	if sky_rig != null:
		sky_rig.call("animate_day", current_day, 1.2)
	_update_ui()
	return report

func jump_to_day_16() -> void:
	if _current_mode != "S01":
		_load_scenario("S01", S01_CARGO, S01_FORCE, "REST")
	while _mission != null and _mission.day <= 16 and not _mission.ended:
		step_day()
	if sky_rig != null:
		sky_rig.call("set_day", 16, 0.0)

func _get_state_for_plan() -> Dictionary:
	if _last_report != null:
		return {
			"day": _mission.day,
			"recycler_broken": _last_report.recycler_broken,
			"broken_panels": _last_report.broken_panels,
			"dust": _last_report.dust,
			"shelter_g_cm2": _last_report.shelter_g_cm2,
			"greenhouse_alive": _last_report.greenhouse_alive,
			"greenhouse_area": _mission.greenhouse.area
		}
	else:
		return {
			"day": _mission.day,
			"recycler_broken": _mission.life.recycler_broken,
			"broken_panels": _mission.power.broken_panels,
			"dust": _mission.dust,
			"shelter_g_cm2": _mission.shelter_g_cm2,
			"greenhouse_alive": _mission.greenhouse.alive,
			"greenhouse_area": _mission.greenhouse.area
		}

func _build_plan(rule: String, current_day: int, state: Dictionary, sim: SimConstants) -> SimPlan:
	var sunset_day: int = int(sim.v("SUNSET_DAY")) if sim != null else 15
	var is_day: bool = (current_day < sunset_day)
	var plan := SimPlanScript.new()

	match rule:
		"REST":
			var broken_rec: bool = bool(state.get("recycler_broken", false))
			var broken_pan: int = int(state.get("broken_panels", 0))
			if broken_rec or broken_pan > 0:
				plan.set_job(0, "REPAIR")
			else:
				plan.set_job(0, "REST")
			for i in range(1, 4):
				plan.set_job(i, "REST")
			plan.greenhouse_lights_on = false
			plan.science_gear_on = false

		"SMART":
			var broken_rec: bool = bool(state.get("recycler_broken", false))
			var broken_pan: int = int(state.get("broken_panels", 0))
			var dust: float = float(state.get("dust", 0.0))
			var shelter_g: float = float(state.get("shelter_g_cm2", 0.0))
			var gh_alive: bool = bool(state.get("greenhouse_alive", false))

			# crew 0
			if broken_rec or broken_pan > 0:
				plan.set_job(0, "REPAIR")
			elif dust > 0.2:
				plan.set_job(0, "CLEAN")
			else:
				plan.set_job(0, "REST")

			# crew 1
			if shelter_g < 15.0:
				plan.set_job(1, "REGOLITH")
			elif is_day:
				plan.set_job(1, "SCIENCE")
			else:
				plan.set_job(1, "REST")

			# crew 2
			if is_day:
				plan.set_job(2, "SCIENCE")
			else:
				plan.set_job(2, "REST")

			# crew 3
			if gh_alive:
				plan.set_job(3, "FARM")
			elif is_day:
				plan.set_job(3, "SCIENCE")
			else:
				plan.set_job(3, "REST")

			plan.greenhouse_lights_on = true
			plan.science_gear_on = is_day

	return plan

func _update_ui() -> void:
	if status_label == null:
		return
	if _mission == null:
		return

	var day_num: int = (_mission.day - 1) if _last_report != null else 0
	var light_col: String = base.call("get_status_light_state") if base.has_method("get_status_light_state") else "-"
	var lamps_lit: bool = base.call("are_lamps_lit") if base.has_method("are_lamps_lit") else true

	var crew_str := ""
	if has_node("Crew"):
		var crew_node = get_node("Crew")
		var jobs_list := []
		for i in range(4):
			jobs_list.append(crew_node.call("get_astronaut_job", i))
		crew_str = " | Crew: %s" % str(jobs_list)

	var sun_str: String = "NIGHT" if day_num >= 15 else "DAY"
	if _last_report != null:
		status_label.text = "[%s] Day %d (%s) | Bat: %.0f%% | Blackout: %s | Light: %s | Lamps: %s | Shelter: %.1f g | GH: %d%s" % [
			_current_mode,
			day_num,
			sun_str,
			_last_report.battery_percent,
			"YES" if _last_report.blackout else "NO",
			light_col.to_upper(),
			"ON" if lamps_lit else "OFF",
			_last_report.shelter_g_cm2,
			_last_report.greenhouse_growth_days,
			crew_str
		]
	else:
		status_label.text = "[%s] Day 0 (Ready) | Rule: %s%s" % [_current_mode, _scenario_rule, crew_str]

func _on_btn_evac_pressed() -> void:
	if has_node("Crew"):
		$Crew.call("evacuate")
		print("BaseDebug: Evacuating crew to lander")

func _on_btn_s01_pressed() -> void:
	_load_scenario("S01", S01_CARGO, S01_FORCE, "REST")

func _on_btn_s07_pressed() -> void:
	_load_scenario("S07", S07_CARGO, S07_FORCE, "SMART")

func _on_btn_no_gh_pressed() -> void:
	_load_static_mode("No Greenhouse", NO_GH_CARGO)

func _on_btn_over_battery_pressed() -> void:
	_load_static_mode("16 Batteries (>12 label check)", OVER_BATTERY_CARGO)

func _on_btn_step_pressed() -> void:
	step_day()

func _on_btn_day16_pressed() -> void:
	jump_to_day_16()

func _on_btn_s08_pressed() -> void:
	_load_static_mode("S08 (Max Base)", S08_CARGO)

func _on_btn_toggle_scale_pressed() -> void:
	if get_viewport() != null:
		var cur: float = get_viewport().scaling_3d_scale
		get_viewport().scaling_3d_scale = 1.0 if cur < 0.9 else 0.75
