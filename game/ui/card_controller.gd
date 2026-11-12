class_name CardController
extends RefCounted

const LearningDataScript := preload("res://ui/learning_data.gd")
const CardTriggersScript := preload("res://ui/card_triggers.gd")

const MAX_TOASTS_PER_DAY: int = 2
const M04_ALERT_CODES: Array[String] = ["STORM", "STORM_WARNING", "METEOROID", "RECYCLER_BROKE", "SUNSET"]

var triggers: CardTriggers
var _learning: LearningData
var _prev_report: Variant = null
var _initial_shelter_g_cm2: float = 0.0
var _initial_dust: float = 0.05

var _pending_toasts: Array[String] = []
var _pending_quiet_card: String = ""
var _toasts_shown_today: int = 0
var _had_alert_today: bool = false


func _init(learning: LearningData = null) -> void:
	_learning = learning if learning != null else LearningDataScript.new()
	triggers = CardTriggersScript.new(_learning)


func reset_mission(initial_shelter_g_cm2: float = 0.0, initial_dust: float = 0.05) -> void:
	_prev_report = null
	_initial_shelter_g_cm2 = initial_shelter_g_cm2
	_initial_dust = initial_dust
	_pending_toasts.clear()
	_pending_quiet_card = ""
	_toasts_shown_today = 0
	_had_alert_today = false


func clear_pending_notifications() -> void:
	_pending_toasts.clear()
	_pending_quiet_card = ""
	_toasts_shown_today = 0
	_had_alert_today = false


func on_day_started(day: int, warnings: Array = [], extra_context: Dictionary = {}) -> Array[String]:
	_toasts_shown_today = 0
	var sunset_day: int = int(extra_context.get("sunset_day", int(Constants.v("SUNSET_DAY")) if Constants != null else 15))
	var has_alert_warning: bool = (day == sunset_day)
	for w in warnings:
		var code: String = _event_code(w)
		if M04_ALERT_CODES.has(code):
			has_alert_warning = true
			break
	_had_alert_today = has_alert_warning

	var triggered: Array[String] = triggers.evaluate_day_start(day, warnings, extra_context)
	for fid in triggered:
		if Settings != null:
			Settings.collect_card(fid)
		if not _pending_toasts.has(fid):
			_pending_toasts.append(fid)

	if has_alert_warning or not _pending_toasts.is_empty():
		_pending_quiet_card = ""
	return triggered


func on_day_resolved(curr_report: Variant, jobs: Array = [], extra_context: Dictionary = {}) -> Dictionary:
	_pending_quiet_card = ""
	var sunset_day: int = int(extra_context.get("sunset_day", int(Constants.v("SUNSET_DAY")) if Constants != null else 15))
	var rep_day: int = _prop_int(curr_report, "day", 0)
	var mission_ended: bool = bool(extra_context.get("mission_ended", false))

	var had_alert: bool = _had_alert_today or (rep_day == sunset_day) or bool(extra_context.get("had_m04_alert", false))
	var rep_events: Variant = _prop(curr_report, "events", [])
	if rep_events is Array:
		for evt in rep_events:
			if M04_ALERT_CODES.has(_event_code(evt)):
				had_alert = true
				break

	var prior_sci: int = Settings.session_science_prior if Settings != null else int(extra_context.get("prior_session_science", 0))
	var q_count: int = Settings.quiet_day_counter if Settings != null else int(extra_context.get("quiet_day_counter", 0))

	var ctx := extra_context.duplicate()
	ctx["sunset_day"] = sunset_day
	ctx["prior_session_science"] = prior_sci
	ctx["had_m04_alert"] = had_alert
	ctx["quiet_day_counter"] = q_count
	ctx["initial_shelter_g_cm2"] = _initial_shelter_g_cm2
	ctx["initial_dust"] = _initial_dust
	ctx["mission_ended"] = mission_ended

	var res: Dictionary = triggers.evaluate_day(_prev_report, curr_report, jobs, ctx)
	if Settings != null:
		Settings.quiet_day_counter = int(res.get("quiet_day_counter", Settings.quiet_day_counter))
		Settings.update_mission_science(_prop_int(curr_report, "science_points", 0))

	var triggered_arr: Array = res.get("triggered", [])
	for fid_v in triggered_arr:
		var fid: String = str(fid_v)
		if Settings != null:
			Settings.collect_card(fid)
		if not mission_ended and not _pending_toasts.has(fid):
			_pending_toasts.append(fid)

	var quiet_fid: String = str(res.get("quiet_card_id", ""))
	if not quiet_fid.is_empty() and not mission_ended and _pending_toasts.is_empty():
		if Settings != null:
			Settings.collect_card(quiet_fid)
		_pending_quiet_card = quiet_fid

	_prev_report = curr_report
	_had_alert_today = false
	return res


func has_pending_notification() -> bool:
	return not peek_next_notification().is_empty()


func peek_next_notification() -> Dictionary:
	if not _pending_toasts.is_empty() and _toasts_shown_today < MAX_TOASTS_PER_DAY:
		return {"kind": "toast", "fact_id": _pending_toasts[0]}
	if _pending_toasts.is_empty() and not _pending_quiet_card.is_empty():
		return {"kind": "quiet", "fact_id": _pending_quiet_card}
	return {}


func pop_next_notification() -> Dictionary:
	if not _pending_toasts.is_empty() and _toasts_shown_today < MAX_TOASTS_PER_DAY:
		var fid: String = _pending_toasts.pop_front()
		_toasts_shown_today += 1
		return {"kind": "toast", "fact_id": fid}
	if _pending_toasts.is_empty() and not _pending_quiet_card.is_empty():
		var qid: String = _pending_quiet_card
		_pending_quiet_card = ""
		return {"kind": "quiet", "fact_id": qid}
	return {}


func pending_toast_count() -> int:
	return _pending_toasts.size()


func toasts_shown_today() -> int:
	return _toasts_shown_today


func _event_code(evt: Variant) -> String:
	if evt == null:
		return ""
	if evt is String:
		return evt
	if evt is Dictionary:
		return str(evt.get("code", ""))
	if evt is Object and "code" in evt:
		return str(evt.code)
	return ""


func _prop(obj: Variant, key: String, default_val: Variant) -> Variant:
	if obj == null:
		return default_val
	if obj is Dictionary:
		return obj.get(key, default_val)
	if obj is Object and key in obj:
		return obj.get(key)
	return default_val


func _prop_int(obj: Variant, key: String, default_val: int) -> int:
	return int(_prop(obj, key, default_val))

