extends Node

const SimMissionScript := preload("res://sim/sim_mission.gd")

signal mission_started(mission: RefCounted)
signal day_started(day: int, warnings: Array)
signal day_resolved(report: RefCounted)
signal event_triggered(evt: RefCounted)
signal mission_ended(result: RefCounted)

var current_mission: RefCounted = null
var last_cargo: RefCounted = null

func new_mission(cargo = null, seed_val: int = 0, force: Dictionary = {}, custom_constants = null) -> void:
	var sim_c = custom_constants
	if sim_c == null and Constants != null and "sim" in Constants and Constants.sim != null:
		sim_c = Constants.sim

	var mission := SimMissionScript.new(sim_c, cargo, seed_val, force)
	current_mission = mission
	if mission.cargo != null and mission.cargo.has_method("clone"):
		last_cargo = mission.cargo.clone()
	mission_started.emit(mission)

	var popups: Array = mission.get_start_of_day_popups(1)
	day_started.emit(1, popups)

func submit_day(plan: RefCounted = null) -> void:
	if current_mission == null or not current_mission.has_method("step_day"):
		push_error("GameState: No active mission to step")
		return

	var report = current_mission.step_day(plan)
	if report == null:
		return

	if "events" in report and report.events is Array:
		for evt in report.events:
			event_triggered.emit(evt)

	day_resolved.emit(report)

	if current_mission.ended:
		mission_ended.emit(current_mission.result)
	else:
		var next_day: int = current_mission.day
		var popups: Array = current_mission.get_start_of_day_popups(next_day)
		day_started.emit(next_day, popups)
