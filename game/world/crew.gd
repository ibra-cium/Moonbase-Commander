class_name Crew
extends Node3D

const AstronautScene := preload("res://world/Astronaut.tscn")
const AstronautScript := preload("res://world/astronaut.gd")

@export var base_path: NodePath = ^"../Base"

var astronauts: Array[Astronaut] = []

func _ready() -> void:
	_ensure_astronauts()
	_connect_game_state()

func _ensure_astronauts() -> void:
	if astronauts.size() == 4:
		return
	astronauts.clear()
	for child in get_children():
		if child is Astronaut:
			astronauts.append(child)

	while astronauts.size() < 4:
		var idx: int = astronauts.size()
		var astro: Astronaut = AstronautScene.instantiate()
		astro.name = "Astronaut_%d" % idx
		astro.set_crew_index(idx)
		add_child(astro)
		astronauts.append(astro)

	for i in range(astronauts.size()):
		var astro := astronauts[i]
		astro.set_crew_index(i)
		astro.position = Vector3(0.0, 0.0, 1.8) + _get_spot_offset(i)
		astro.set_state(AstronautScript.State.RESTING)

func get_astronaut(index: int) -> Astronaut:
	_ensure_astronauts()
	if index >= 0 and index < astronauts.size():
		return astronauts[index]
	return null

func get_astronaut_count() -> int:
	_ensure_astronauts()
	return astronauts.size()

func get_astronaut_job(index: int) -> String:
	var astro := get_astronaut(index)
	return astro.current_job if astro != null else ""

func get_astronaut_state(index: int) -> int:
	var astro := get_astronaut(index)
	return int(astro.current_state) if astro != null else -1

func get_base() -> Node3D:
	if has_node(base_path):
		return get_node(base_path) as Node3D
	if get_parent() != null:
		if get_parent().has_method("get_job_spot_position"):
			return get_parent() as Node3D
		if get_parent().has_node("Base"):
			return get_parent().get_node("Base") as Node3D
	return null

func _get_spot_offset(index: int) -> Vector3:
	var offsets: Array[Vector3] = [
		Vector3(-0.6, 0.0, 0.0),
		Vector3(-0.2, 0.0, 0.35),
		Vector3(0.2, 0.0, 0.35),
		Vector3(0.6, 0.0, 0.0)
	]
	return offsets[clampi(index, 0, 3)]

func _get_target_spot(job: String, index: int, is_storm: bool, recycler_broken: bool) -> Vector3:
	var base := get_base()
	var base_spot := Vector3.ZERO
	if is_storm:
		if base != null and base.has_method("get_job_spot_position"):
			base_spot = base.call("get_job_spot_position", "SHELTER")
		else:
			base_spot = Vector3(0.0, 0.0, -2.5)
	else:
		if base != null and base.has_method("get_job_spot_position"):
			var target_repair := "RECYCLER" if recycler_broken else "PANEL"
			base_spot = base.call("get_job_spot_position", job, target_repair)
		else:
			match job.to_upper():
				"REST": base_spot = Vector3(0.0, 0.0, 1.8)
				"CLEAN": base_spot = Vector3(-5.5, 0.0, 6.5)
				"FARM": base_spot = Vector3(-4.0, 0.0, 1.8)
				"REGOLITH": base_spot = Vector3(-12.5, 0.0, -1.5)
				"SCIENCE": base_spot = Vector3(7.5, 0.0, 1.5)
				"REPAIR": base_spot = Vector3(4.0, 0.0, 1.8) if recycler_broken else Vector3(-5.5, 0.0, 6.5)
				_: base_spot = Vector3(0.0, 0.0, 1.8)
	return base_spot + _get_spot_offset(index)

func _get_game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	var main_loop := Engine.get_main_loop() as SceneTree
	if main_loop != null and main_loop.root != null:
		return main_loop.root.get_node_or_null("GameState")
	return null

func _connect_game_state() -> void:
	var gs := _get_game_state()
	if gs == null:
		return
	if not gs.is_connected("mission_started", Callable(self, "_on_mission_started")):
		gs.connect("mission_started", Callable(self, "_on_mission_started"))
	if not gs.is_connected("day_started", Callable(self, "_on_day_started")):
		gs.connect("day_started", Callable(self, "_on_day_started"))
	if not gs.is_connected("day_resolved", Callable(self, "_on_day_resolved")):
		gs.connect("day_resolved", Callable(self, "_on_day_resolved"))
	if not gs.is_connected("mission_ended", Callable(self, "_on_mission_ended")):
		gs.connect("mission_ended", Callable(self, "_on_mission_ended"))

func _on_mission_started(_mission: RefCounted) -> void:
	_ensure_astronauts()
	reset_scales()
	for i in range(astronauts.size()):
		var astro := astronauts[i]
		astro.position = Vector3(0.0, 0.0, 1.8) + _get_spot_offset(i)
		astro.current_job = "REST"
		astro.set_state(AstronautScript.State.RESTING)

func _on_day_started(_day: int, _warnings: Array) -> void:
	pass

func _on_day_resolved(report) -> void:
	var storm_today := _is_storm_report(report)
	var crew_reps_val = _get_field(report, "crew_reports", [])
	var crew_reps: Array = crew_reps_val if crew_reps_val is Array else []
	for i in range(astronauts.size()):
		var is_sick := false
		if i < crew_reps.size():
			var cr = crew_reps[i]
			is_sick = bool(_get_field(cr, "sick", false))
			if not is_sick and cr != null and not (cr is Dictionary) and cr.has_method("is_sick"):
				is_sick = bool(cr.is_sick())
		astronauts[i].set_sick(is_sick)
	recall_to_rest(storm_today)

func _is_storm_report(report) -> bool:
	if report == null:
		return false
	var storm_dose: float = float(_get_field(report, "storm_dose_msv", 0.0))
	if storm_dose > 0.0:
		return true
	var events_val = _get_field(report, "events", [])
	if events_val is Array:
		for evt in events_val:
			var code: String = str(_get_field(evt, "code", ""))
			if code == "STORM_WARNING" or code == "SOLAR_STORM":
				return true
	return false

func _on_mission_ended(result) -> void:
	if result == null:
		return
	var outcome: String = str(_get_field(result, "outcome", ""))
	if outcome.to_lower().contains("evac") or outcome.to_lower().contains("fail"):
		evacuate()

func _get_field(obj, field_name: String, default_val = null) -> Variant:
	if obj == null:
		return default_val
	if obj is Dictionary:
		return (obj as Dictionary).get(field_name, default_val)
	if field_name in obj:
		return obj.get(field_name)
	return default_val

func apply_report(report) -> void:
	_ensure_astronauts()
	if report == null:
		return

	var storm_today := false
	var storm_dose: float = float(_get_field(report, "storm_dose_msv", 0.0))
	if storm_dose > 0.0:
		storm_today = true
	else:
		var events_val = _get_field(report, "events", [])
		if events_val is Array:
			for evt in events_val:
				var code: String = str(_get_field(evt, "code", ""))
				if code == "STORM_WARNING" or code == "SOLAR_STORM":
					storm_today = true
					break

	var base := get_base()
	if base != null and base.has_method("set_shelter_door_light"):
		base.call("set_shelter_door_light", storm_today)

	var recycler_broken: bool = bool(_get_field(report, "recycler_broken", false))
	var crew_reps_val = _get_field(report, "crew_reports", [])
	var crew_reps: Array = crew_reps_val if crew_reps_val is Array else []

	var hop_dur: float = 1.5
	if is_inside_tree():
		var settings = get_node_or_null("/root/Settings")
		if settings != null and "fast_mode" in settings and settings.fast_mode:
			hop_dur = 0.4

	for i in range(astronauts.size()):
		var astro := astronauts[i]
		var job := "REST"
		var is_sick := false
		if i < crew_reps.size():
			var cr = crew_reps[i]
			job = str(_get_field(cr, "job", "REST"))
			is_sick = bool(_get_field(cr, "sick", false))
			if not is_sick and cr != null and not (cr is Dictionary) and cr.has_method("is_sick"):
				is_sick = bool(cr.is_sick())

		astro.current_job = job

		if storm_today:
			var target_spot := _get_target_spot("SHELTER", i, true, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.WORKING)
			astro.hop_to(target_spot, hop_dur, 3, func():
				astro.set_state(AstronautScript.State.SHELTERED)
			)
		elif is_sick:
			var target_spot := _get_target_spot("REST", i, false, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.SICK)
			astro.hop_to(target_spot, hop_dur, 2, func():
				astro.set_state(AstronautScript.State.SICK)
			)
		elif job == "REST":
			var target_spot := _get_target_spot("REST", i, false, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.WORKING)
			astro.hop_to(target_spot, hop_dur, 3, func():
				astro.set_state(AstronautScript.State.RESTING)
			)
		else:
			var target_spot := _get_target_spot(job, i, false, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.WORKING)
			astro.hop_to(target_spot, hop_dur, 3, func():
				astro.set_state(AstronautScript.State.WORKING)
			)

func set_name_tags_visible(p_visible: bool) -> void:
	_ensure_astronauts()
	for astro in astronauts:
		if astro != null and astro.has_method("set_name_tag_hidden"):
			astro.set_name_tag_hidden(not p_visible)

func set_overlay_tag_mode(enabled: bool) -> void:
	_ensure_astronauts()
	for astro in astronauts:
		if astro != null and astro.has_method("set_overlay_tag_mode"):
			astro.set_overlay_tag_mode(enabled)

func select_astronaut(selected_index: int) -> void:
	_ensure_astronauts()
	for i in range(astronauts.size()):
		var astro: Astronaut = astronauts[i]
		if astro == null:
			continue
		var is_sel := (i == selected_index)
		if astro.has_method("set_selected"):
			astro.set_selected(is_sel)
		if is_sel and astro.has_method("play_select_hop"):
			astro.play_select_hop()

func apply_kept_jobs(jobs: Array, sick_flags: Array = [], is_storm: bool = false) -> void:
	_ensure_astronauts()
	if is_storm:
		return
	for i in range(mini(astronauts.size(), jobs.size())):
		var astro := astronauts[i]
		var job: String = str(jobs[i])
		var is_sick: bool = bool(sick_flags[i]) if i < sick_flags.size() else (astro.current_state == AstronautScript.State.SICK)
		if is_sick or job == "REST":
			astro.current_job = "REST"
			continue
		assign_job(i, job)

func apply_plan(plan = null, sick_flags: Array = [], is_storm: bool = false, recycler_broken: bool = false) -> void:
	_ensure_astronauts()
	var base := get_base()
	if base != null and base.has_method("set_shelter_door_light"):
		base.call("set_shelter_door_light", is_storm)

	var jobs_arr: Array = []
	if plan != null:
		var j_val = _get_field(plan, "jobs", null)
		if j_val is Array:
			jobs_arr = j_val
		elif plan.has_method("get_jobs"):
			jobs_arr = plan.get_jobs()

	for i in range(astronauts.size()):
		var astro := astronauts[i]
		var job: String = str(jobs_arr[i]) if i < jobs_arr.size() else "REST"
		var is_sick: bool = bool(sick_flags[i]) if i < sick_flags.size() else false
		astro.current_job = job

		if is_storm:
			var target_spot := _get_target_spot("SHELTER", i, true, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.WORKING)
			astro.hop_to(target_spot, 1.5, 3, func():
				astro.set_state(AstronautScript.State.SHELTERED)
			)
		elif is_sick:
			var target_spot := _get_target_spot("REST", i, false, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.SICK)
			astro.hop_to(target_spot, 1.5, 2, func():
				astro.set_state(AstronautScript.State.SICK)
			)
		elif job == "REST":
			var target_spot := _get_target_spot("REST", i, false, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.WORKING)
			astro.hop_to(target_spot, 1.5, 3, func():
				astro.set_state(AstronautScript.State.RESTING)
			)
		else:
			var target_spot := _get_target_spot(job, i, false, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.WORKING)
			astro.hop_to(target_spot, 1.5, 3, func():
				astro.set_state(AstronautScript.State.WORKING)
			)

func assign_job(index: int, job: String) -> void:
	_ensure_astronauts()
	var astro := get_astronaut(index)
	if astro == null:
		return

	astro.current_job = job

	var hop_dur: float = 1.5
	if is_inside_tree():
		var settings = get_node_or_null("/root/Settings")
		if settings != null and "fast_mode" in settings and settings.fast_mode:
			hop_dur = 0.4

	var recycler_broken := false
	var gs := _get_game_state()
	if gs != null and gs.current_mission != null and gs.current_mission.life != null:
		recycler_broken = gs.current_mission.life.recycler_broken

	if astro.current_state == AstronautScript.State.SICK:
		var target_spot := _get_target_spot("REST", index, false, recycler_broken)
		astro.visible = true
		astro.hop_to(target_spot, hop_dur, 2, func():
			astro.set_state(AstronautScript.State.SICK)
		)
		return

	if job.to_upper() == "REST":
		if astro.current_state == AstronautScript.State.RESTING and not astro.visible:
			return
		var target_spot := _get_target_spot("REST", index, false, recycler_broken)
		astro.visible = true
		astro.set_state(AstronautScript.State.WORKING)
		astro.hop_to(target_spot, hop_dur, 3, func():
			astro.set_state(AstronautScript.State.RESTING)
		)
	else:
		if astro.current_state == AstronautScript.State.RESTING or not astro.visible:
			astro.position = _get_target_spot("REST", index, false, recycler_broken)
		var target_spot := _get_target_spot(job, index, false, recycler_broken)
		astro.visible = true
		astro.set_state(AstronautScript.State.WORKING)
		astro.hop_to(target_spot, hop_dur, 3, func():
			astro.set_state(AstronautScript.State.WORKING)
		)

func recall_to_rest(is_storm: bool = false) -> void:
	_ensure_astronauts()
	var base := get_base()
	if base != null and base.has_method("set_shelter_door_light"):
		base.call("set_shelter_door_light", is_storm)

	var hop_dur: float = 1.5
	if is_inside_tree():
		var settings = get_node_or_null("/root/Settings")
		if settings != null and "fast_mode" in settings and settings.fast_mode:
			hop_dur = 0.4

	var recycler_broken := false
	var gs := _get_game_state()
	if gs != null and gs.current_mission != null and gs.current_mission.life != null:
		recycler_broken = gs.current_mission.life.recycler_broken

	for i in range(astronauts.size()):
		var astro := astronauts[i]
		astro.current_job = "REST"
		if is_storm:
			var target_spot := _get_target_spot("SHELTER", i, true, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.WORKING)
			astro.hop_to(target_spot, hop_dur, 3, func():
				astro.set_state(AstronautScript.State.SHELTERED)
			)
		elif astro.current_state == AstronautScript.State.SICK:
			var target_spot := _get_target_spot("REST", i, false, recycler_broken)
			astro.visible = true
			astro.hop_to(target_spot, hop_dur, 2, func():
				astro.set_state(AstronautScript.State.SICK)
			)
		elif astro.current_state == AstronautScript.State.RESTING and not astro.visible:
			# Already resting inside habitat
			pass
		else:
			var target_spot := _get_target_spot("REST", i, false, recycler_broken)
			astro.visible = true
			astro.set_state(AstronautScript.State.WORKING)
			astro.hop_to(target_spot, hop_dur, 3, func():
				astro.set_state(AstronautScript.State.RESTING)
			)

func evacuate() -> void:
	_ensure_astronauts()
	set_name_tags_visible(false)
	var base := get_base()
	for i in range(astronauts.size()):
		var astro := astronauts[i]
		var lander_spot := Vector3.ZERO
		if base != null and base.has_method("get_job_spot_position"):
			lander_spot = base.call("get_job_spot_position", "LANDER")
		else:
			lander_spot = Vector3(10.5, 0.0, 7.5)
		var target := lander_spot + _get_spot_offset(i)
		astro.visible = true
		astro.set_state(AstronautScript.State.EVACUATING)
		astro.hop_to(target, 1.8, 4, func():
			astro.set_state(AstronautScript.State.EVACUATING)
		)

func board_lander() -> void:
	_ensure_astronauts()
	for astro in astronauts:
		astro.visible = false
		astro.scale = Vector3(0.001, 0.001, 0.001)

func celebrate_success(on_complete: Callable = Callable()) -> void:
	_ensure_astronauts()
	set_name_tags_visible(false)
	reset_scales()
	var base := get_base()
	var center_spot := Vector3(0.0, 0.0, 3.2)
	if base != null and base.has_method("get_job_spot_position"):
		center_spot = base.call("get_job_spot_position", "REST") + Vector3(0.0, 0.0, 1.2)

	var cele_offsets: Array[Vector3] = [
		Vector3(-1.8, 0.0, 0.0),
		Vector3(-0.6, 0.0, 0.2),
		Vector3(0.6, 0.0, 0.2),
		Vector3(1.8, 0.0, 0.0)
	]

	var hop_dur: float = 1.4
	if is_inside_tree():
		var settings = get_node_or_null("/root/Settings")
		if settings != null and "fast_mode" in settings and settings.fast_mode:
			hop_dur = 0.4

	for i in range(astronauts.size()):
		var astro := astronauts[i]
		astro.visible = true
		astro.set_sick(false)
		astro.current_job = "REST"
		var target := center_spot + cele_offsets[i]
		astro.set_state(AstronautScript.State.WORKING)
		var is_last := (i == astronauts.size() - 1)
		astro.hop_to(target, hop_dur, 3, func():
			astro.set_state(AstronautScript.State.WORKING)
			if is_last and on_complete.is_valid():
				on_complete.call()
		)

func prepare_for_landing() -> void:
	_ensure_astronauts()
	set_name_tags_visible(false)
	for astro in astronauts:
		astro.scale = Vector3(0.001, 0.001, 0.001)

func reset_scales() -> void:
	_ensure_astronauts()
	for astro in astronauts:
		astro.scale = Vector3.ONE

func animate_pop_in(duration: float = 0.4) -> Tween:
	_ensure_astronauts()
	var tween := create_tween()
	tween.set_parallel(true)
	var delay: float = 0.15
	for i in range(astronauts.size()):
		var astro := astronauts[i]
		astro.scale = Vector3(0.001, 0.001, 0.001)
		tween.tween_property(astro, "scale", Vector3.ONE, duration).set_delay(delay + i * 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween

