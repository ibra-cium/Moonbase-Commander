extends Node

enum State {
	TITLE,
	MAP,
	BRIEFING,
	PACK,
	LANDING,
	PLAN_DAY,
	RESOLVE_DAY,
	ENDING,
	DEBRIEF,
	CERTIFICATE,
}

const DayHudScript := preload("res://ui/day_hud.gd")
const DebriefScreenScript := preload("res://ui/debrief_screen.gd")
const EventPopupScript := preload("res://ui/event_popup.gd")
const CardControllerScript := preload("res://ui/card_controller.gd")
const CardViewScene := preload("res://ui/CardView.tscn")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimPlanScript := preload("res://sim/sim_plan.gd")
const SimMissionsScript := preload("res://sim/sim_missions.gd")
const SpeechBubbleScene := preload("res://world/SpeechBubble.tscn")
const SpeechBubbleScript := preload("res://world/speech_bubble.gd")
const BATTERY_LOW_HINT_PERCENT: float = 30.0

var current_state: State = State.TITLE
var current_cargo: RefCounted = null
var current_seed: int = 0
var current_plan: RefCounted = null
var pending_popups: Array = []
var pending_hints: Array[String] = []

var _sim_missions: SimMissions = null
var _pending_bubble: Dictionary = {}
var _last_bubble_day: int = -1
var _prev_crew_sick: Array[bool] = [false, false, false, false]
var _prev_recycler_broken: bool = false
var _prev_broken_panels: int = 0
var _prev_science_points: int = 0
var _pending_collect_data: Dictionary = {}
var _prev_collect_science: int = 0
var _prev_collect_shelter: float = 0.0
var _card_controller: CardController = CardControllerScript.new()
var _card_view: CanvasLayer = null

var world: Node3D
var ui: CanvasLayer
var title_screen: TitleScreen
var mission_map: Control
var mission_briefing: Control
var certificate_screen: Control
var sources_screen: SourcesScreen
var pack_screen: PackScreen
var day_hud: Control
var speech_bubble: Control
var debrief_screen: Control
var event_popup: CanvasLayer
var ending_overlay: Control
var tutorial_overlay: CanvasLayer

func _ensure_nodes() -> void:
	if ui != null:
		return
	world = get_node_or_null("World")
	ui = get_node_or_null("UI")
	if ui != null:
		title_screen = ui.get_node_or_null("TitleScreen")
		mission_map = ui.get_node_or_null("MissionMap")
		mission_briefing = ui.get_node_or_null("MissionBriefing")
		certificate_screen = ui.get_node_or_null("CertificateScreen")
		sources_screen = ui.get_node_or_null("SourcesScreen")
		pack_screen = ui.get_node_or_null("PackScreen")
		day_hud = ui.get_node_or_null("DayHud")
		speech_bubble = ui.get_node_or_null("SpeechBubble")
		if speech_bubble == null and SpeechBubbleScene != null:
			speech_bubble = SpeechBubbleScene.instantiate()
			if speech_bubble != null:
				speech_bubble.name = "SpeechBubble"
				ui.add_child(speech_bubble)
				if day_hud != null:
					ui.move_child(speech_bubble, day_hud.get_index() + 1)
		debrief_screen = ui.get_node_or_null("DebriefScreen")
		event_popup = ui.get_node_or_null("EventPopup")
		ending_overlay = ui.get_node_or_null("EndingOverlay")
		tutorial_overlay = ui.get_node_or_null("TutorialOverlay")
		_card_view = ui.get_node_or_null("CardView")
		if _card_view == null and CardViewScene != null:
			_card_view = CardViewScene.instantiate()
			if _card_view != null:
				_card_view.name = "CardView"
				ui.add_child(_card_view)

func _get_sim_missions() -> SimMissions:
	if _sim_missions == null and Constants != null and Constants.sim != null:
		_sim_missions = SimMissionsScript.new(Constants.sim)
	return _sim_missions

func _get_tree() -> SceneTree:
	if is_inside_tree():
		return get_tree()
	return Engine.get_main_loop() as SceneTree

func _ready() -> void:
	_ensure_nodes()
	if title_screen:
		if not title_screen.start_completed.is_connected(_on_title_start_completed):
			title_screen.start_completed.connect(_on_title_start_completed)
		if not title_screen.sources_pressed.is_connected(_on_title_sources_pressed):
			title_screen.sources_pressed.connect(_on_title_sources_pressed)
	if mission_map:
		if mission_map.has_signal("mission_selected") and not mission_map.mission_selected.is_connected(_on_mission_selected):
			mission_map.mission_selected.connect(_on_mission_selected)
	if mission_briefing:
		if mission_briefing.has_signal("completed") and not mission_briefing.completed.is_connected(_on_briefing_completed):
			mission_briefing.completed.connect(_on_briefing_completed)
		mission_briefing.visible = false
	if certificate_screen:
		if certificate_screen.has_signal("back_to_map_pressed") and not certificate_screen.back_to_map_pressed.is_connected(_on_certificate_back_to_map_pressed):
			certificate_screen.back_to_map_pressed.connect(_on_certificate_back_to_map_pressed)
		certificate_screen.visible = false
	if sources_screen:
		if not sources_screen.back_pressed.is_connected(_on_sources_back_pressed):
			sources_screen.back_pressed.connect(_on_sources_back_pressed)
		sources_screen.visible = false
	if pack_screen:
		if not pack_screen.launch_requested.is_connected(_on_pack_launch_requested):
			pack_screen.launch_requested.connect(_on_pack_launch_requested)
		pack_screen.visible = false
	if day_hud:
		if not day_hud.end_day_pressed.is_connected(_on_end_day_pressed):
			day_hud.end_day_pressed.connect(_on_end_day_pressed)
		if day_hud.has_signal("menu_requested") and not day_hud.menu_requested.is_connected(_on_hud_menu_requested):
			day_hud.menu_requested.connect(_on_hud_menu_requested)
		if day_hud.has_signal("crew_job_changed") and not day_hud.crew_job_changed.is_connected(_on_hud_crew_job_changed):
			day_hud.crew_job_changed.connect(_on_hud_crew_job_changed)
		if day_hud.has_signal("science_card_notification_pressed") and not day_hud.science_card_notification_pressed.is_connected(_on_science_card_notification_pressed):
			day_hud.science_card_notification_pressed.connect(_on_science_card_notification_pressed)
		if day_hud.has_signal("science_card_notification_finished") and not day_hud.science_card_notification_finished.is_connected(_on_science_card_notification_finished):
			day_hud.science_card_notification_finished.connect(_on_science_card_notification_finished)
		var cam_node := world.get_node_or_null("CameraRig") if world != null else null
		if cam_node != null and cam_node.has_signal("empty_ground_tapped") and not cam_node.empty_ground_tapped.is_connected(day_hud.deselect_crew):
			cam_node.empty_ground_tapped.connect(day_hud.deselect_crew)
		if world != null and day_hud.has_method("bind_world_nodes"):
			day_hud.bind_world_nodes(world.get_node_or_null("Base"), world.get_node_or_null("Crew"))
		day_hud.visible = false
	if debrief_screen:
		if not debrief_screen.retry_pressed.is_connected(_on_debrief_retry_pressed):
			debrief_screen.retry_pressed.connect(_on_debrief_retry_pressed)
		if not debrief_screen.change_cargo_pressed.is_connected(_on_debrief_change_cargo_pressed):
			debrief_screen.change_cargo_pressed.connect(_on_debrief_change_cargo_pressed)
		if debrief_screen.has_signal("title_pressed") and not debrief_screen.title_pressed.is_connected(_on_debrief_title_pressed):
			debrief_screen.title_pressed.connect(_on_debrief_title_pressed)
		if debrief_screen.has_signal("next_mission_pressed") and not debrief_screen.next_mission_pressed.is_connected(_on_debrief_next_mission_pressed):
			debrief_screen.next_mission_pressed.connect(_on_debrief_next_mission_pressed)
		if debrief_screen.has_signal("certificate_pressed") and not debrief_screen.certificate_pressed.is_connected(_on_debrief_certificate_pressed):
			debrief_screen.certificate_pressed.connect(_on_debrief_certificate_pressed)
		debrief_screen.visible = false
	if event_popup:
		event_popup.visible = false
	if ending_overlay:
		if ending_overlay.has_signal("skip_pressed") and not ending_overlay.skip_pressed.is_connected(_on_ending_skip_pressed):
			ending_overlay.skip_pressed.connect(_on_ending_skip_pressed)
		ending_overlay.visible = false
	if tutorial_overlay:
		if tutorial_overlay.has_signal("step_acknowledged") and not tutorial_overlay.step_acknowledged.is_connected(_on_tutorial_step_acknowledged):
			tutorial_overlay.step_acknowledged.connect(_on_tutorial_step_acknowledged)
		if tutorial_overlay.has_signal("tutorial_finished") and not tutorial_overlay.tutorial_finished.is_connected(_on_tutorial_finished):
			tutorial_overlay.tutorial_finished.connect(_on_tutorial_finished)
		if tutorial_overlay.has_signal("tutorial_skipped") and not tutorial_overlay.tutorial_skipped.is_connected(_on_tutorial_skipped):
			tutorial_overlay.tutorial_skipped.connect(_on_tutorial_skipped)
		if tutorial_overlay.has_signal("hint_closed") and not tutorial_overlay.hint_closed.is_connected(_on_tutorial_hint_closed):
			tutorial_overlay.hint_closed.connect(_on_tutorial_hint_closed)
		tutorial_overlay.visible = false

	if speech_bubble != null and speech_bubble.has_signal("bubble_hidden") and not speech_bubble.bubble_hidden.is_connected(_on_speech_bubble_hidden):
		speech_bubble.bubble_hidden.connect(_on_speech_bubble_hidden)
	if _card_view != null and _card_view.has_signal("closed") and not _card_view.closed.is_connected(_on_card_view_closed):
		_card_view.closed.connect(_on_card_view_closed)
	if not GameState.day_started.is_connected(_on_day_started):
		GameState.day_started.connect(_on_day_started)
	if not GameState.mission_started.is_connected(_on_game_state_mission_started):
		GameState.mission_started.connect(_on_game_state_mission_started)
	if not GameState.day_resolved.is_connected(_on_game_state_day_resolved):
		GameState.day_resolved.connect(_on_game_state_day_resolved)

	_enter_state(State.TITLE)

func _enter_state(new_state: State) -> void:
	_ensure_nodes()
	current_state = new_state
	match current_state:
		State.TITLE:
			_state_title()
		State.MAP:
			_state_map()
		State.BRIEFING:
			_state_briefing()
		State.PACK:
			_state_pack()
		State.LANDING:
			_state_landing()
		State.PLAN_DAY:
			_state_plan_day()
		State.RESOLVE_DAY:
			_state_resolve_day()
		State.ENDING:
			_state_ending()
		State.DEBRIEF:
			_state_debrief()
		State.CERTIFICATE:
			_state_certificate()

func _state_title() -> void:
	if Audio != null:
		Audio.stop("hum_loop")
		Audio.stop("engine")
	if world:
		world.visible = false
	if title_screen:
		title_screen.visible = true
		title_screen.reset()
	if mission_map:
		mission_map.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if sources_screen:
		sources_screen.visible = false
	if pack_screen:
		pack_screen.visible = false
	if day_hud:
		day_hud.visible = false
	if debrief_screen:
		debrief_screen.visible = false
	if event_popup:
		event_popup.visible = false
	if ending_overlay:
		ending_overlay.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
	pending_popups.clear()
	pending_hints.clear()

func _state_map() -> void:
	if Audio != null:
		Audio.stop("hum_loop")
		Audio.stop("engine")
	if title_screen:
		title_screen.visible = false
	if world:
		world.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if sources_screen:
		sources_screen.visible = false
	if pack_screen:
		pack_screen.visible = false
	if day_hud:
		day_hud.visible = false
	if debrief_screen:
		debrief_screen.visible = false
	if event_popup:
		event_popup.visible = false
	if ending_overlay:
		ending_overlay.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
	if mission_map:
		mission_map.visible = true
		if mission_map.has_method("refresh_map"):
			mission_map.refresh_map()
	pending_popups.clear()
	pending_hints.clear()
	_reset_bubble_tracking()

func _state_briefing() -> void:
	if Audio != null:
		Audio.stop("hum_loop")
		Audio.stop("engine")
	if world:
		world.visible = false
	if title_screen:
		title_screen.visible = false
	if mission_map:
		mission_map.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if sources_screen:
		sources_screen.visible = false
	if pack_screen:
		pack_screen.visible = false
	if day_hud:
		day_hud.visible = false
	if debrief_screen:
		debrief_screen.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if event_popup:
		event_popup.visible = false
	if ending_overlay:
		ending_overlay.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
	if mission_briefing:
		mission_briefing.visible = true
		var mid: String = Settings.current_mission_id if Settings != null else "M1"
		if mission_briefing.has_method("start_briefing"):
			mission_briefing.start_briefing(mid)

func _state_certificate() -> void:
	if Audio != null:
		Audio.stop("hum_loop")
		Audio.stop("engine")
	if world:
		world.visible = false
	if title_screen:
		title_screen.visible = false
	if mission_map:
		mission_map.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if sources_screen:
		sources_screen.visible = false
	if pack_screen:
		pack_screen.visible = false
	if day_hud:
		day_hud.visible = false
	if debrief_screen:
		debrief_screen.visible = false
	if event_popup:
		event_popup.visible = false
	if ending_overlay:
		ending_overlay.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
	if certificate_screen:
		certificate_screen.visible = true
		if certificate_screen.has_method("refresh_certificate"):
			certificate_screen.refresh_certificate()

func _state_pack() -> void:
	if Audio != null:
		Audio.stop("hum_loop")
		Audio.stop("engine")
	if title_screen:
		title_screen.visible = false
	if mission_map:
		mission_map.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if sources_screen:
		sources_screen.visible = false
	if pack_screen:
		pack_screen.visible = true
		pack_screen.reset_to_initial_or_last()
	_reset_bubble_tracking()
	if world:
		world.visible = false
	if day_hud:
		day_hud.visible = false
	if debrief_screen:
		debrief_screen.visible = false
	if event_popup:
		event_popup.visible = false
	if ending_overlay:
		ending_overlay.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
		if Settings != null and not Settings.tutorial_skipped and not Settings.tutorial_pack_done:
			tutorial_overlay.show_step(1)
	print("Main: Entered PACK state for mission %s" % (Settings.current_mission_id if Settings else "?"))

func _state_landing() -> void:
	if title_screen:
		title_screen.visible = false
	if mission_map:
		mission_map.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if sources_screen:
		sources_screen.visible = false
	if pack_screen:
		pack_screen.visible = false
	if day_hud:
		day_hud.visible = false
	if debrief_screen:
		debrief_screen.visible = false
	if event_popup:
		event_popup.visible = false
	if ending_overlay:
		ending_overlay.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
	pending_hints.clear()
	_reset_bubble_tracking()
	if world:
		world.visible = true

	var lander_pre: Node3D = world.get_node_or_null("Lander") if world else null
	if lander_pre != null and lander_pre.has_method("reset_state"):
		lander_pre.call("reset_state")
	var cam_pre: Node3D = world.get_node_or_null("CameraRig") if world else null
	if cam_pre != null and cam_pre.has_method("reset_camera"):
		cam_pre.call("reset_camera", 0.0)

	# Hide/prepare base buildings and crew for landing pop-in
	var base_node: Node3D = world.get_node_or_null("Base") if world else null
	var crew_node: Node3D = world.get_node_or_null("Crew") if world else null

	if base_node != null and base_node.has_method("prepare_for_landing"):
		base_node.call("prepare_for_landing")
	if crew_node != null and crew_node.has_method("prepare_for_landing"):
		crew_node.call("prepare_for_landing")

	# Start mission in GameState — pass mission's SimConstants and force
	if current_cargo == null:
		if GameState.last_cargo != null:
			current_cargo = GameState.last_cargo
		else:
			var sim_c = Constants.sim if Constants and "sim" in Constants else null
			current_cargo = SimCargoScript.new(sim_c)

	var mission_id: String = Settings.current_mission_id if Settings != null else "M4"
	var sm := _get_sim_missions()
	var mission_sim_c: SimConstants = sm.get_sim_constants(mission_id) if sm != null else null
	var mission_force: Dictionary = sm.get_force(mission_id) if sm != null else {}

	GameState.new_mission(current_cargo, current_seed, mission_force, mission_sim_c)

	# Ensure base spawns stay at 0.001 scale until crate rollout triggers pop-in
	if base_node != null and base_node.has_method("prepare_for_landing"):
		base_node.call("prepare_for_landing")

	var is_fast: bool = Settings.fast_mode

	var lander_node: Node3D = world.get_node_or_null("Lander") if world else null
	if lander_node != null and lander_node.has_method("play_landing"):
		if not lander_node.is_connected("landing_completed", Callable(self, "_on_landing_completed")):
			lander_node.connect("landing_completed", Callable(self, "_on_landing_completed"), CONNECT_ONE_SHOT)
		lander_node.call("play_landing", base_node, crew_node, is_fast)

func _state_plan_day() -> void:
	if ending_overlay:
		ending_overlay.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if pack_screen:
		pack_screen.visible = false
	if debrief_screen:
		debrief_screen.visible = false
	if world:
		world.visible = true
	var crew_node: Node3D = world.get_node_or_null("Crew") if world != null else null
	if crew_node != null and crew_node.has_method("set_name_tags_visible"):
		crew_node.set_name_tags_visible(true)

	var m_day: int = GameState.current_mission.day if GameState.current_mission else 1
	var is_storm_today: bool = false
	if GameState.current_mission != null and GameState.current_mission.events != null:
		is_storm_today = GameState.current_mission.events.is_storm_day(m_day)
	for p in pending_popups:
		if p != null and str(p.code if "code" in p else "") == "STORM_WARNING":
			is_storm_today = true
			break

	if day_hud:
		day_hud.visible = true
		if world != null and day_hud.has_method("bind_world_nodes"):
			day_hud.bind_world_nodes(world.get_node_or_null("Base"), world.get_node_or_null("Crew"))
		day_hud.set_day(m_day)
		day_hud.set_resolving(false)
		if not _pending_collect_data.is_empty() and day_hud.has_method("spawn_collect_bubbles_for_report"):
			var c_data: Dictionary = _pending_collect_data
			_pending_collect_data = {}
			var base_node: Node = world.get_node_or_null("Base") if world != null else null
			day_hud.spawn_collect_bubbles_for_report(
				c_data.get("report"),
				int(c_data.get("prev_science", 0)),
				float(c_data.get("prev_shelter", 0.0)),
				base_node
			)

	current_plan = SimPlanScript.new()
	if day_hud and day_hud.has_method("get_plan"):
		var kept_plan = day_hud.get_plan()
		if kept_plan != null:
			for i in range(4):
				current_plan.set_job(i, SimPlanScript.JOB_REST if is_storm_today else kept_plan.get_job(i))
			current_plan.greenhouse_lights_on = kept_plan.greenhouse_lights_on
	_sync_plan_science_gear(current_plan)

	if m_day > 1 and not is_storm_today and crew_node != null and crew_node.has_method("apply_kept_jobs"):
		crew_node.apply_kept_jobs(current_plan.jobs, _prev_crew_sick, is_storm_today)

	if m_day == 1 and _last_bubble_day < 0:
		_pending_bubble = SpeechBubbleScript.pick_hello(current_seed, _prev_crew_sick)
		_last_bubble_day = 0

	_process_next_popup()

func _process_next_popup() -> void:
	if pending_popups.is_empty() or event_popup == null:
		_process_onboarding_and_hints()
		return

	_ensure_popup_signals_connected()
	var evt = pending_popups.pop_front()
	var code: String = str(evt.get("code", "")) if evt is Dictionary else str(evt.code if "code" in evt else "")
	var data: Dictionary = evt.get("data", {}) if evt is Dictionary else (evt.data if "data" in evt and evt.data is Dictionary else {})
	event_popup.set_meta("popup_code", code)
	event_popup.set_meta("storm_auto_ended", false)

	match code:
		"STORM_WARNING":
			_show_storm_warning_card()
		"STORM_RESULT":
			_show_storm_result_card(data)
		"METEOROID":
			event_popup.popup_alert(load("res://assets/icons/warning.svg") as Texture2D, "ALERT_METEOR_TITLE", "ALERT_METEOR_BODY", "danger", ["POPUP_OK"])
		"RECYCLER_BROKE":
			if Settings != null:
				Settings.hint_broken_shown = true
			event_popup.popup_alert(load("res://assets/icons/water_drop.svg") as Texture2D, "ALERT_RECYCLER_TITLE", "ALERT_RECYCLER_BODY", "danger", ["POPUP_OK"])
		"SUNSET":
			_show_night_card()
		_:
			event_popup.popup_event(code, code, ["POPUP_OK"])

func _ensure_popup_signals_connected() -> void:
	if event_popup == null:
		return
	if not event_popup.choice_selected.is_connected(_on_popup_choice_selected):
		event_popup.choice_selected.connect(_on_popup_choice_selected)
	if not event_popup.closed.is_connected(_on_popup_closed):
		event_popup.closed.connect(_on_popup_closed)

func _on_popup_choice_selected(_choice_idx: int) -> void:
	if event_popup == null:
		return
	var active_code: String = str(event_popup.get_meta("popup_code", ""))
	if active_code == "STORM_WARNING":
		event_popup.set_meta("storm_auto_ended", true)
		event_popup.set_meta("popup_code", "")
		if day_hud and day_hud.has_method("set_storm_day"):
			day_hud.set_storm_day(true)
		if current_plan != null:
			for i in range(4):
				current_plan.set_job(i, SimPlanScript.JOB_REST)
		var crew_node = world.get_node_or_null("Crew") if world != null else null
		if crew_node != null and crew_node.has_method("recall_to_rest"):
			crew_node.recall_to_rest(true)
		_on_end_day_pressed()

func _on_popup_closed() -> void:
	if event_popup == null:
		return
	var auto_ended: bool = bool(event_popup.get_meta("storm_auto_ended", false))
	event_popup.set_meta("popup_code", "")
	event_popup.set_meta("storm_auto_ended", false)
	if not auto_ended:
		_process_next_popup()

func _show_storm_warning_card() -> void:
	if Audio != null:
		Audio.play("alarm")
	var crew_node = world.get_node_or_null("Crew") if world != null else null
	if crew_node != null and crew_node.has_method("recall_to_rest"):
		crew_node.recall_to_rest(true)
	var warn_min: float = float(Constants.v("SPE_WARNING_TYPICAL_MIN")) if Constants != null else 60.0
	var fast: bool = Settings != null and Settings.fast_mode
	var dur_sec: float = EventPopupScript.STORM_COUNTDOWN_FAST_SEC if fast else EventPopupScript.STORM_COUNTDOWN_SEC
	var template: String = tr("ALERT_STORM_COUNT")
	event_popup.popup_alert(
		load("res://assets/icons/warning.svg") as Texture2D,
		"ALERT_STORM_TITLE",
		template.format({"min": int(round(warn_min))}),
		"danger",
		["EVT_CHOICE_SHELTER"],
		{"countdown_start": warn_min, "countdown_sec": dur_sec, "countdown_template": template}
	)

func _show_storm_result_card(data: Dictionary) -> void:
	var dose_int: int = int(round(float(data.get("dose", 0.0))))
	var limit_int: int = int(round(float(Constants.v("RAD_SPE_LIMIT_MSV")) if Constants != null else 250.0))
	var body_text: String = tr("ALERT_STORM_SAFE_BODY").format({"dose": dose_int, "limit": limit_int})
	event_popup.popup_alert(
		load("res://assets/icons/shield.svg") as Texture2D,
		"ALERT_STORM_SAFE_TITLE",
		body_text,
		"safe",
		["POPUP_OK"],
		{"bar_value": float(dose_int), "bar_max": maxf(float(limit_int), 1.0), "source_id": "RAD_SPE_LIMIT_MSV"}
	)

func _show_night_card() -> void:
	var have_kwh: float = 0.0
	var need_kwh: float = 0.0
	if GameState != null and GameState.current_mission != null and GameState.current_mission.cargo != null:
		var c = GameState.current_mission.cargo
		if c.has_method("night_energy_have_kwh"):
			have_kwh = float(c.night_energy_have_kwh())
		if c.has_method("night_energy_need_kwh"):
			need_kwh = float(c.night_energy_need_kwh())
	var tone: String = "warn" if have_kwh < need_kwh else "safe"
	var body_text: String = tr("ALERT_NIGHT_BODY").format({"have": int(round(have_kwh)), "need": int(round(need_kwh))})
	event_popup.popup_alert(
		load("res://assets/icons/nightlight.svg") as Texture2D,
		"ALERT_NIGHT_TITLE",
		body_text,
		tone,
		["POPUP_OK"],
		{"bar_value": have_kwh, "bar_max": maxf(need_kwh, 1.0), "source_id": "NIGHT_HOURS"}
	)

func _state_resolve_day() -> void:
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
	if day_hud:
		day_hud.set_resolving(true)

	var crew_node = world.get_node_or_null("Crew") if world != null else null
	if crew_node != null and crew_node.has_method("recall_to_rest"):
		crew_node.recall_to_rest()

	GameState.submit_day(current_plan)

	var is_fast: bool = Settings.fast_mode
	var duration: float = 0.5 if is_fast else 2.0
	var tree := _get_tree()
	if tree != null:
		tree.create_timer(duration).timeout.connect(_on_resolve_completed, CONNECT_ONE_SHOT)

func _on_resolve_completed() -> void:
	if current_state != State.RESOLVE_DAY:
		return
	if GameState.current_mission != null and GameState.current_mission.ended:
		_enter_state(State.ENDING)
	else:
		_enter_state(State.PLAN_DAY)

func _state_ending() -> void:
	if _card_view != null and _card_view.visible:
		_card_view.visible = false
	if _card_controller != null:
		_card_controller.clear_pending_notifications()
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
	pending_hints.clear()
	_reset_bubble_tracking()
	if day_hud:
		day_hud.visible = false
	if event_popup:
		event_popup.visible = false
	if debrief_screen:
		debrief_screen.visible = false
	if world:
		world.visible = true

	var res = GameState.current_mission.result if GameState.current_mission else null
	var outcome: String = str(res.outcome if res and "outcome" in res else "")
	var is_success: bool = (outcome == "SURVIVED")

	# Record stars on success
	if is_success and Settings != null and GameState.current_mission != null:
		var stars_val: int = int(res.stars) if "stars" in res else 0
		Settings.record_stars(Settings.current_mission_id, stars_val)

	if ending_overlay:
		ending_overlay.visible = true
		if ending_overlay.has_method("setup"):
			ending_overlay.setup(is_success)

	var is_fast: bool = Settings.fast_mode
	var crew_node: Node3D = world.get_node_or_null("Crew") if world else null
	if crew_node != null and crew_node.has_method("set_name_tags_visible"):
		crew_node.set_name_tags_visible(false)
	var lander_node: Node3D = world.get_node_or_null("Lander") if world else null
	var sky_node: Node3D = world.get_node_or_null("SkyRig") if world else null
	var cam_node: Node3D = world.get_node_or_null("CameraRig") if world else null
	var effects_node: Node3D = world.get_node_or_null("Effects") if world else null

	if is_success:
		# 1. Sunrise dawn glow on horizon
		if sky_node != null and sky_node.has_method("show_sunrise_glow"):
			sky_node.call("show_sunrise_glow", 0.8 if is_fast else 2.0)
		# 2. Crew gathers outside and hops happily
		if crew_node != null and crew_node.has_method("celebrate_success"):
			crew_node.call("celebrate_success")
		# 3. Stars pop
		if effects_node != null and effects_node.has_method("play_stars"):
			effects_node.call("play_stars", 3, 0.8 if is_fast else 2.0)
		# 4. Camera frames the celebrating base
		if cam_node != null and cam_node.has_method("frame_celebration"):
			cam_node.call("frame_celebration", 0.8 if is_fast else 2.0)

		var cele_dur: float = 1.0 if is_fast else 3.2
		var tree := _get_tree()
		if tree != null:
			tree.create_timer(cele_dur).timeout.connect(func():
				if current_state == State.ENDING:
					_enter_state(State.DEBRIEF)
			, CONNECT_ONE_SHOT)
		else:
			_enter_state(State.DEBRIEF)
	else:
		# Evacuation lift-off:
		# 1. Play evacuation effect / flame / dust
		if effects_node != null and effects_node.has_method("play_evacuation"):
			effects_node.call("play_evacuation", "EVAC", 0.6 if is_fast else 2.0)

		# 2. Lander plays liftoff (crew hops to lander, boards, flame & dust, ascends)
		if lander_node != null and lander_node.has_method("play_liftoff"):
			if not lander_node.is_connected("liftoff_completed", Callable(self, "_on_liftoff_completed")):
				lander_node.connect("liftoff_completed", Callable(self, "_on_liftoff_completed"), CONNECT_ONE_SHOT)
			lander_node.call("play_liftoff", crew_node, is_fast)
		else:
			if crew_node != null and crew_node.has_method("evacuate"):
				crew_node.call("evacuate")
			var tree := _get_tree()
			if tree != null:
				tree.create_timer(1.0 if is_fast else 2.5).timeout.connect(_on_liftoff_completed, CONNECT_ONE_SHOT)
			else:
				_on_liftoff_completed()

		# 3. Camera follows the lander rising into the sky
		if cam_node != null and cam_node.has_method("follow_liftoff"):
			cam_node.call("follow_liftoff", 1.0 if is_fast else 2.5)

func _on_liftoff_completed() -> void:
	if current_state == State.ENDING:
		_enter_state(State.DEBRIEF)

func _on_ending_skip_pressed() -> void:
	if current_state == State.ENDING:
		if Audio != null:
			Audio.stop("engine")
		var cam_node = world.get_node_or_null("CameraRig") if world else null
		if cam_node != null and cam_node.has_method("reset_camera"):
			cam_node.call("reset_camera", 0.0)
		_enter_state(State.DEBRIEF)

func _state_debrief() -> void:
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
	pending_hints.clear()
	_reset_bubble_tracking()
	if title_screen:
		title_screen.visible = false
	if mission_map:
		mission_map.visible = false
	if mission_briefing:
		mission_briefing.visible = false
	if certificate_screen:
		certificate_screen.visible = false
	if sources_screen:
		sources_screen.visible = false
	if pack_screen:
		pack_screen.visible = false
	if ending_overlay:
		ending_overlay.visible = false
	if day_hud:
		day_hud.visible = false
	if event_popup:
		event_popup.visible = false
	if debrief_screen:
		debrief_screen.visible = true
		var res = GameState.current_mission.result if GameState.current_mission else null
		# Tell debrief screen whether a next mission exists
		var has_next: bool = _has_next_mission()
		if debrief_screen.has_method("show_result_with_next"):
			debrief_screen.show_result_with_next(res, current_seed, has_next)
		else:
			debrief_screen.show_result(res, current_seed)

func _has_next_mission() -> bool:
	var mid: String = Settings.current_mission_id if Settings != null else "M4"
	var all_ids: Array = ["M1", "M2", "M3", "M4"]
	var idx: int = all_ids.find(mid)
	return idx >= 0 and idx < all_ids.size() - 1

func _get_next_mission_id() -> String:
	var mid: String = Settings.current_mission_id if Settings != null else "M4"
	var all_ids: Array = ["M1", "M2", "M3", "M4"]
	var idx: int = all_ids.find(mid)
	if idx >= 0 and idx < all_ids.size() - 1:
		return all_ids[idx + 1]
	return ""

func _on_landing_completed() -> void:
	if current_state == State.LANDING:
		_enter_state(State.PLAN_DAY)

func _on_title_start_completed() -> void:
	_enter_state(State.MAP)

func _prepare_mission_start_cargo(mission_id: String) -> void:
	var sm := _get_sim_missions()
	if sm == null:
		GameState.last_cargo = null
		return
	var start_cargo_dict := sm.get_start_cargo(mission_id)
	if not start_cargo_dict.is_empty():
		var mission_sim_c := sm.get_sim_constants(mission_id)
		if mission_sim_c != null:
			var tmp_cargo := SimCargoScript.new(mission_sim_c)
			tmp_cargo.load_dict(start_cargo_dict)
			GameState.last_cargo = tmp_cargo
			return
	GameState.last_cargo = null

func _on_mission_selected(mission_id: String) -> void:
	if Settings != null:
		Settings.current_mission_id = mission_id
		Settings.begin_mission_cards()
	_prepare_mission_start_cargo(mission_id)
	current_cargo = null
	_enter_state(State.BRIEFING)

func _on_briefing_completed() -> void:
	_enter_state(State.PACK)

func _on_pack_launch_requested(launch_cargo: RefCounted) -> void:
	current_cargo = launch_cargo
	current_seed = (randi() & 0x7FFFFFFF) % 1000000 + 1
	print("Main: Launch requested with seed %d, cargo mass %f" % [current_seed, launch_cargo.total_mass()])
	_enter_state(State.LANDING)

func _on_end_day_pressed() -> void:
	if current_state == State.PLAN_DAY:
		_pending_bubble.clear()
		if speech_bubble and speech_bubble.has_method("hide_bubble"):
			speech_bubble.hide_bubble()
		if day_hud and day_hud.has_method("auto_collect_all"):
			day_hud.auto_collect_all()
		if day_hud and day_hud.has_method("get_plan"):
			var hud_plan = day_hud.get_plan()
			if current_plan != null:
				for i in range(4):
					var j: String = current_plan.get_job(i)
					if j != SimPlanScript.JOB_REST and hud_plan.get_job(i) == SimPlanScript.JOB_REST:
						hud_plan.set_job(i, j)
			current_plan = hud_plan
		_sync_plan_science_gear(current_plan)
		_enter_state(State.RESOLVE_DAY)

func _on_debrief_retry_pressed() -> void:
	if Settings != null:
		Settings.begin_mission_cards()
	current_seed = (randi() & 0x7FFFFFFF) % 1000000 + 1
	# Retry keeps the same mission and the last cargo
	var lander_node: Node3D = world.get_node_or_null("Lander") if world else null
	if lander_node != null and lander_node.has_method("reset_state"):
		lander_node.call("reset_state")
	var cam_node: Node3D = world.get_node_or_null("CameraRig") if world else null
	if cam_node != null and cam_node.has_method("reset_camera"):
		cam_node.call("reset_camera", 0.0)
	_enter_state(State.LANDING)

func _on_debrief_change_cargo_pressed() -> void:
	if Settings != null:
		Settings.begin_mission_cards()
	var lander_node: Node3D = world.get_node_or_null("Lander") if world else null
	if lander_node != null and lander_node.has_method("reset_state"):
		lander_node.call("reset_state")
	var cam_node: Node3D = world.get_node_or_null("CameraRig") if world else null
	if cam_node != null and cam_node.has_method("reset_camera"):
		cam_node.call("reset_camera", 0.0)
	current_cargo = null
	_enter_state(State.PACK)

func _on_debrief_title_pressed() -> void:
	_enter_state(State.MAP)

func _on_debrief_next_mission_pressed() -> void:
	var next_id := _get_next_mission_id()
	if next_id == "" or Settings == null or not Settings.is_mission_unlocked(next_id):
		_enter_state(State.MAP)
		return
	Settings.current_mission_id = next_id
	Settings.begin_mission_cards()
	_prepare_mission_start_cargo(next_id)
	current_cargo = null
	_enter_state(State.BRIEFING)

func _on_debrief_certificate_pressed() -> void:
	_enter_state(State.CERTIFICATE)

func _on_certificate_back_to_map_pressed() -> void:
	_enter_state(State.MAP)

func _on_day_started(_day: int, warnings: Array) -> void:
	var sunset_day: int = int(Constants.v("SUNSET_DAY")) if Constants != null else 15
	var has_sunset := false
	for w in warnings:
		if w != null and str(w.code if "code" in w else "") == "SUNSET":
			has_sunset = true
			break
	if _day == sunset_day and not has_sunset:
		pending_popups.append({"code": "SUNSET", "day": _day, "data": {}})
	for w in warnings:
		if w != null:
			pending_popups.append(w)
	if _card_controller != null:
		_card_controller.on_day_started(_day, warnings, {"sunset_day": sunset_day})

func _on_game_state_mission_started(mission: RefCounted) -> void:
	_reset_bubble_tracking()
	_prev_collect_science = 0
	_prev_collect_shelter = float(mission.shelter_g_cm2) if (mission != null and "shelter_g_cm2" in mission) else 0.0
	var init_dust: float = float(mission.dust) if (mission != null and "dust" in mission) else (float(Constants.v("DUST_LANDING")) if Constants != null else 0.05)
	if _card_controller != null:
		_card_controller.reset_mission(_prev_collect_shelter, init_dust)
	if day_hud and day_hud.has_method("setup_mission"):
		day_hud.setup_mission(mission)

func _on_game_state_day_resolved(report: RefCounted) -> void:
	if event_popup != null and event_popup.has_method("dismiss_silent"):
		event_popup.dismiss_silent()
	var mission_ended: bool = GameState.current_mission == null or GameState.current_mission.ended
	if mission_ended:
		pending_popups.clear()
	var card_events: Array[String] = _queue_result_cards(report, mission_ended)
	if _card_controller != null and report != null:
		var mission_c_card = GameState.current_mission.get_constants() if GameState.current_mission and GameState.current_mission.has_method("get_constants") else null
		var sunset_day_card: int = int(mission_c_card.v("SUNSET_DAY")) if mission_c_card != null and mission_c_card.has("SUNSET_DAY") else (int(Constants.v("SUNSET_DAY")) if Constants != null else 15)
		var jobs_arr: Array = current_plan.jobs if (current_plan != null and "jobs" in current_plan) else []
		var rep_day_card: int = int(report.day) if "day" in report else 0
		_card_controller.on_day_resolved(report, jobs_arr, {
			"mission_ended": mission_ended,
			"sunset_day": sunset_day_card,
			"had_m04_alert": (not card_events.is_empty()) or (rep_day_card == sunset_day_card),
		})
	if day_hud and day_hud.has_method("update_from_report"):
		day_hud.update_from_report(report, not mission_ended, card_events)
	if report != null and not mission_ended:
		_pending_collect_data = {
			"report": report,
			"prev_science": _prev_collect_science,
			"prev_shelter": _prev_collect_shelter,
		}
		_prev_collect_science = int(report.science_points)
		_prev_collect_shelter = float(report.shelter_g_cm2)
		var rep_day: int = int(report.day) if "day" in report else 1
		if rep_day != _last_bubble_day:
			var mission_c = GameState.current_mission.get_constants() if GameState.current_mission and GameState.current_mission.has_method("get_constants") else null
			var sunset_day_val: int = int(mission_c.v("SUNSET_DAY")) if mission_c != null and mission_c.has("SUNSET_DAY") else (int(Constants.v("SUNSET_DAY")) if Constants != null else 15)
			var newly_tired_ids: Array[int] = []
			var m_log = GameState.current_mission.log if GameState.current_mission != null and "log" in GameState.current_mission else null
			if m_log != null and "new_log_ids" in report:
				for lid in report.new_log_ids:
					var entry: Dictionary = m_log.get_entry(int(lid))
					if str(entry.get("code", "")) == "CREW_TIRED":
						var vals: Dictionary = entry.get("values", {})
						for cidx in vals.get("crew_indices", []):
							var ci: int = int(cidx)
							if not newly_tired_ids.has(ci):
								newly_tired_ids.append(ci)
			var ctx := {
				"prev_sick": _prev_crew_sick.duplicate(),
				"prev_recycler_broken": _prev_recycler_broken,
				"prev_broken_panels": _prev_broken_panels,
				"prev_science_points": _prev_science_points,
				"newly_tired": newly_tired_ids,
				"sunset_day": sunset_day_val,
				"seed_val": current_seed
			}
			_pending_bubble = SpeechBubbleScript.pick_voice(report, ctx)
			_last_bubble_day = rep_day
		_snapshot_prev_report_state(report)
		_check_context_hints(report)

func _queue_result_cards(report: RefCounted, mission_ended: bool) -> Array[String]:
	var queued: Array[String] = []
	if mission_ended or report == null or not ("events" in report):
		return queued
	var rep_day: int = int(report.day) if "day" in report else 0
	for evt in report.events:
		var code: String = str(evt.get("code", "")) if evt is Dictionary else str(evt.code if "code" in evt else "")
		if code == "STORM" and not queued.has("STORM"):
			var dose_val: float = float(report.storm_dose_msv) if "storm_dose_msv" in report else 0.0
			pending_popups.append({"code": "STORM_RESULT", "day": rep_day, "data": {"dose": dose_val}})
			queued.append("STORM")
		elif code == "METEOROID" and not queued.has("METEOROID"):
			pending_popups.append({"code": "METEOROID", "day": rep_day, "data": {}})
			queued.append("METEOROID")
		elif code == "RECYCLER_BROKE" and not queued.has("RECYCLER_BROKE"):
			if Settings != null:
				Settings.hint_broken_shown = true
			pending_popups.append({"code": "RECYCLER_BROKE", "day": rep_day, "data": {}})
			queued.append("RECYCLER_BROKE")
	return queued

func _process_onboarding_and_hints() -> void:
	if current_state != State.PLAN_DAY or tutorial_overlay == null:
		return
	if event_popup != null and event_popup.visible:
		return
	if Settings != null and not Settings.tutorial_skipped and not Settings.tutorial_hud_done:
		tutorial_overlay.show_step(2)
		return
	_process_next_hint()

func _process_next_hint() -> void:
	if current_state != State.PLAN_DAY or tutorial_overlay == null:
		return
	if tutorial_overlay.visible:
		return
	if event_popup != null and event_popup.visible:
		return
	if pending_hints.is_empty():
		_maybe_show_pending_bubble()
		return
	var next_hint: String = pending_hints.pop_front()
	tutorial_overlay.show_hint(next_hint)

func _reset_bubble_tracking() -> void:
	_pending_bubble.clear()
	_last_bubble_day = -1
	_prev_crew_sick = [false, false, false, false]
	_prev_recycler_broken = false
	_prev_broken_panels = 0
	_prev_science_points = 0
	_pending_collect_data.clear()
	_prev_collect_science = 0
	_prev_collect_shelter = 0.0
	if day_hud != null and day_hud.has_method("clear_collect_bubbles"):
		day_hud.clear_collect_bubbles()
	if speech_bubble != null and speech_bubble.has_method("hide_bubble"):
		speech_bubble.hide_bubble()

func _sync_plan_science_gear(plan: RefCounted) -> void:
	if plan == null or not ("jobs" in plan):
		return
	var has_science: bool = false
	for j in plan.jobs:
		if j == SimPlanScript.JOB_SCIENCE:
			has_science = true
			break
	plan.science_gear_on = has_science

func _snapshot_prev_report_state(report: RefCounted) -> void:
	if report == null:
		return
	if "crew_reports" in report and report.crew_reports is Array:
		var reps: Array = report.crew_reports
		for i in range(mini(4, reps.size())):
			var cr = reps[i]
			if cr is Dictionary:
				_prev_crew_sick[i] = bool(cr.get("sick", false))
	if "recycler_broken" in report:
		_prev_recycler_broken = bool(report.recycler_broken)
	if "broken_panels" in report:
		_prev_broken_panels = int(report.broken_panels)
	if "science_points" in report:
		_prev_science_points = int(report.science_points)

func _maybe_show_pending_bubble() -> void:
	if _pending_bubble.is_empty():
		_maybe_show_pending_card_notification()
		return
	if current_state != State.PLAN_DAY:
		return
	if event_popup != null and event_popup.visible:
		return
	if tutorial_overlay != null and tutorial_overlay.visible:
		return
	_ensure_nodes()
	if speech_bubble == null:
		return
	var line_key: String = str(_pending_bubble.get("key", ""))
	var crew_idx: int = int(_pending_bubble.get("crew_index", 0))
	_pending_bubble.clear()
	if line_key.is_empty():
		return
	var crew_node: Node3D = world.get_node_or_null("Crew") if world != null else null
	var astro: Node3D = crew_node.call("get_astronaut", crew_idx) if (crew_node != null and crew_node.has_method("get_astronaut")) else null
	var avoid_ctrl: Control = day_hud.toast_panel if (day_hud != null and "toast_panel" in day_hud) else null
	speech_bubble.show_bubble(line_key, astro, crew_idx, avoid_ctrl)

func _check_context_hints(report: RefCounted) -> void:
	if report == null or Settings == null:
		return

	# 1. First time battery < 30 % at night
	if not Settings.hint_battery_low_shown:
		var sunset_day: int = int(Constants.v("SUNSET_DAY")) if Constants != null else 15
		var rep_day: int = int(report.day) if "day" in report else 1
		var is_night: bool = rep_day >= sunset_day
		var bat_pct: float = float(report.battery_percent) if "battery_percent" in report else 100.0
		var bat_cap: float = float(report.battery_capacity_kwh) if "battery_capacity_kwh" in report else 0.0
		var reactor_kwh: float = float(report.reactor_kwh) if "reactor_kwh" in report else 0.0
		var is_blackout: bool = bool(report.blackout) if "blackout" in report else false
		var has_shed: bool = ("power_shed" in report and not report.power_shed.is_empty())
		if bat_cap <= 0.0 and bat_pct > 0.0 and bat_pct <= 1.0:
			bat_pct *= 100.0
		var ignore_no_bat_with_reactor: bool = (bat_cap <= 0.0 and reactor_kwh > 0.0 and not is_blackout and not has_shed)
		if is_night and bat_pct < BATTERY_LOW_HINT_PERCENT and not ignore_no_bat_with_reactor:
			Settings.hint_battery_low_shown = true
			if not pending_hints.has("battery_low"):
				pending_hints.append("battery_low")

	# 2. First broken thing (water recycler or solar panel)
	if not Settings.hint_broken_shown:
		var rec_broken: bool = bool(report.recycler_broken) if "recycler_broken" in report else false
		var panels_broken: int = int(report.broken_panels) if "broken_panels" in report else 0
		if rec_broken or panels_broken > 0:
			Settings.hint_broken_shown = true
			if not pending_hints.has("broken"):
				pending_hints.append("broken")

	# 3. First time CO2 is yellow (above CO2_HEALTHY_MAX_MMHG)
	if not Settings.hint_co2_yellow_shown:
		var co2_healthy_max: float = float(Constants.v("CO2_HEALTHY_MAX_MMHG")) if Constants != null else 2.0
		var co2_val: float = float(report.co2_mmhg) if "co2_mmhg" in report else 0.0
		if co2_val > co2_healthy_max:
			Settings.hint_co2_yellow_shown = true
			if not pending_hints.has("co2_yellow"):
				pending_hints.append("co2_yellow")

	# 4. First time any crew member reaches 1 energy pip
	if not Settings.hint_tired_shown:
		var crew_reps: Array = report.crew_reports if "crew_reports" in report else []
		for cr in crew_reps:
			var is_cr_sick: bool = bool(cr.get("sick", false)) if cr is Dictionary else false
			var cr_energy: int = int(cr.get("energy", -1)) if cr is Dictionary else -1
			if not is_cr_sick and cr_energy == 1:
				Settings.hint_tired_shown = true
				if not pending_hints.has("tired"):
					pending_hints.append("tired")
				break

func _on_tutorial_step_acknowledged(step_num: int) -> void:
	if Settings != null and step_num == 1:
		Settings.tutorial_pack_done = true

func _on_tutorial_finished() -> void:
	if Settings != null:
		Settings.tutorial_pack_done = true
		Settings.tutorial_hud_done = true
	if current_state == State.PLAN_DAY:
		_process_next_hint()

func _on_tutorial_skipped() -> void:
	if Settings != null:
		Settings.tutorial_skipped = true
		Settings.tutorial_pack_done = true
		Settings.tutorial_hud_done = true
	if current_state == State.PLAN_DAY:
		_process_next_hint()

func _on_tutorial_hint_closed(_hint_id: String) -> void:
	if current_state == State.PLAN_DAY:
		_process_next_hint()

func _on_hud_crew_job_changed(idx: int, new_job: String) -> void:
	if current_plan != null and current_plan.has_method("set_job"):
		current_plan.set_job(idx, new_job)
		_sync_plan_science_gear(current_plan)
	var crew_node = world.get_node_or_null("Crew") if world != null else null
	if crew_node != null and crew_node.has_method("assign_job"):
		crew_node.assign_job(idx, new_job)

func _on_hud_menu_requested() -> void:
	if _card_view != null and _card_view.visible:
		_card_view.visible = false
	if speech_bubble != null and speech_bubble.has_method("hide_bubble"):
		speech_bubble.hide_bubble()
	if tutorial_overlay and tutorial_overlay.has_method("hide_overlay"):
		tutorial_overlay.hide_overlay()
	if sources_screen:
		if world:
			world.visible = false
		if day_hud:
			day_hud.visible = false
		sources_screen.visible = true

func _on_title_sources_pressed() -> void:
	if title_screen:
		title_screen.visible = false
	if sources_screen:
		sources_screen.visible = true

func _on_sources_back_pressed() -> void:
	if sources_screen:
		sources_screen.visible = false
	if current_state == State.TITLE:
		if title_screen:
			title_screen.visible = true
	elif current_state == State.PLAN_DAY:
		if world:
			world.visible = true
		if day_hud:
			day_hud.visible = true
		_maybe_show_pending_card_notification()


func _maybe_show_pending_card_notification() -> void:
	if current_state != State.PLAN_DAY:
		return
	if event_popup != null and event_popup.visible:
		return
	if tutorial_overlay != null and tutorial_overlay.visible:
		return
	if not pending_popups.is_empty() or not pending_hints.is_empty():
		return
	if speech_bubble != null and speech_bubble.has_method("is_showing") and speech_bubble.is_showing():
		return
	if not _pending_bubble.is_empty():
		return
	if _card_view != null and _card_view.visible:
		return
	if sources_screen != null and sources_screen.visible:
		return
	if day_hud == null or not day_hud.visible:
		return
	if day_hud.has_method("is_science_card_toast_showing") and day_hud.is_science_card_toast_showing():
		return
	if _card_controller == null or not _card_controller.has_pending_notification():
		return

	if Settings != null and not Settings.hint_card_shown and not Settings.tutorial_skipped and tutorial_overlay != null:
		Settings.hint_card_shown = true
		tutorial_overlay.show_hint("science_card")
		return

	var item: Dictionary = _card_controller.pop_next_notification()
	var fid: String = str(item.get("fact_id", ""))
	var is_quiet: bool = (str(item.get("kind", "")) == "quiet")
	if not fid.is_empty() and day_hud.has_method("show_science_card_toast"):
		day_hud.show_science_card_toast(fid, is_quiet)


func _on_speech_bubble_hidden() -> void:
	_maybe_show_pending_card_notification()


func _on_science_card_notification_pressed(fact_id: String, _is_quiet: bool) -> void:
	if _card_view != null and _card_view.has_method("open_card"):
		_card_view.call("open_card", fact_id)


func _on_science_card_notification_finished(_fact_id: String, _is_quiet: bool) -> void:
	_maybe_show_pending_card_notification()


func _on_card_view_closed(_fact_id: String) -> void:
	_maybe_show_pending_card_notification()
