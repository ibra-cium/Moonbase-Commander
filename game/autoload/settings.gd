extends Node

signal language_changed(new_language: String)

var language: String = "en":
	set(value):
		if language != value:
			language = value
			TranslationServer.set_locale(language)
			language_changed.emit(language)

signal sound_changed(enabled: bool)
signal science_view_changed(enabled: bool)
var sound_on: bool = true:
	set(value):
		if sound_on != value:
			sound_on = value
			sound_changed.emit(sound_on)
var science_view: bool = false:
	set(value):
		if science_view != value:
			science_view = value
			science_view_changed.emit(science_view)
var camera_sensitivity: float = 1.0

# Session-only onboarding and one-shot context hint flags
var tutorial_pack_done: bool = false
var tutorial_hud_done: bool = false
var tutorial_skipped: bool = false
var hint_battery_low_shown: bool = false
var hint_broken_shown: bool = false
var hint_co2_yellow_shown: bool = false
var hint_collect_shown: bool = false
var hint_tired_shown: bool = false
var hint_card_shown: bool = false
var card_first_pickup_done: bool = false

# Session-only mission progress (not saved between sessions)
var current_mission_id: String = "M1"
var mission_stars: Dictionary = {}  # mission_id -> best star count (int)
var free_play: bool = false          # teacher / judge / demo switch: unlocks all

# Session-only junior astronaut training state
signal card_collected(fact_id: String)

var training: Dictionary = {}         # mission_id -> {"before": int, "after": int}
var rank_id: String = "CADET"
var collected_cards: Array[String] = []
var mission_collected_cards: Array[String] = []
var session_science_prior: int = 0
var session_science_mission_max: int = 0
var quiet_day_counter: int = 0

## A mission is unlocked when the one before it has at least 1 star, or free_play is on.
func is_mission_unlocked(id: String) -> bool:
	if free_play:
		return true
	match id:
		"M1":
			return true          # first mission is always open
		"M2":
			return mission_stars.get("M1", 0) >= 1
		"M3":
			return mission_stars.get("M2", 0) >= 1
		"M4":
			return mission_stars.get("M3", 0) >= 1
	return false

## Record the best star count for a mission. Keeps the highest value.
func record_stars(id: String, stars: int) -> void:
	var prev: int = int(mission_stars.get(id, 0))
	if stars > prev:
		mission_stars[id] = stars


func _ensure_training_entry(mid: String) -> Dictionary:
	if not training.has(mid) or not (training[mid] is Dictionary):
		training[mid] = {"before": -1, "after": -1}
	return training[mid]


## Store the pre-mission guess index the first time only. Returns true when stored.
func record_before_answer(mid: String, answer_idx: int) -> bool:
	if mid.is_empty() or answer_idx < 0:
		return false
	var entry: Dictionary = _ensure_training_entry(mid)
	if int(entry.get("before", -1)) >= 0:
		return false
	entry["before"] = answer_idx
	return true


## Store the post-mission answer index the first time only. Returns true when stored.
func record_after_answer(mid: String, answer_idx: int) -> bool:
	if mid.is_empty() or answer_idx < 0:
		return false
	var entry: Dictionary = _ensure_training_entry(mid)
	if int(entry.get("after", -1)) >= 0:
		return false
	entry["after"] = answer_idx
	return true


func has_before_answer(mid: String) -> bool:
	var entry: Variant = training.get(mid, {})
	return entry is Dictionary and int(entry.get("before", -1)) >= 0


func has_after_answer(mid: String) -> bool:
	var entry: Variant = training.get(mid, {})
	return entry is Dictionary and int(entry.get("after", -1)) >= 0


func get_before_answer(mid: String) -> int:
	var entry: Variant = training.get(mid, {})
	if entry is Dictionary:
		return int(entry.get("before", -1))
	return -1


func get_after_answer(mid: String) -> int:
	var entry: Variant = training.get(mid, {})
	if entry is Dictionary:
		return int(entry.get("after", -1))
	return -1


## Collect a Moon Science Card fact ID once. Returns true when newly added.
func collect_card(fact_id: String) -> bool:
	if fact_id.is_empty() or collected_cards.has(fact_id):
		return false
	collected_cards.append(fact_id)
	if not mission_collected_cards.has(fact_id):
		mission_collected_cards.append(fact_id)
	card_collected.emit(fact_id)
	return true


## Start a fresh mission card & science tracking window (call before Briefing / launch).
func begin_mission_cards() -> void:
	mission_collected_cards.clear()
	session_science_prior += session_science_mission_max
	session_science_mission_max = 0


## Record current mission's highest science total without losing prior missions in this session.
func update_mission_science(mission_science_points: int) -> void:
	if mission_science_points > session_science_mission_max:
		session_science_mission_max = mission_science_points


func session_science_total() -> int:
	return session_science_prior + session_science_mission_max


## Return {"before_right": int, "after_right": int, "answered": int} over missions with an after answer.
func training_score() -> Dictionary:
	var ld := LearningData.new()
	var before_right: int = 0
	var after_right: int = 0
	var answered: int = 0
	var missions_dict: Dictionary = ld.missions_dict()
	for mid_var in missions_dict.keys():
		var mid: String = str(mid_var)
		var after_idx: int = get_after_answer(mid)
		if after_idx < 0:
			continue
		answered += 1
		var correct_idx: int = int(ld.question(mid).get("correct", -1))
		if correct_idx >= 0:
			if get_before_answer(mid) == correct_idx:
				before_right += 1
			if after_idx == correct_idx:
				after_right += 1
	return {
		"before_right": before_right,
		"after_right": after_right,
		"answered": answered,
	}


## Promote rank only on a win (>= 1 star) and only upward. Returns new rank_id or "".
func promote_after_win(mid: String, stars: int) -> String:
	if stars < 1:
		return ""
	var ld := LearningData.new()
	var next_rank: String = ld.rank_after(mid)
	if next_rank.is_empty():
		return ""
	if ld.rank_order(next_rank) > ld.rank_order(rank_id):
		rank_id = next_rank
		return next_rank
	return ""


func reset_training() -> void:
	training = {}
	rank_id = "CADET"
	collected_cards.clear()
	mission_collected_cards.clear()
	session_science_prior = 0
	session_science_mission_max = 0
	quiet_day_counter = 0

func reset_onboarding() -> void:
	tutorial_pack_done = false
	tutorial_hud_done = false
	tutorial_skipped = false
	hint_battery_low_shown = false
	hint_broken_shown = false
	hint_co2_yellow_shown = false
	hint_collect_shown = false
	hint_tired_shown = false
	hint_card_shown = false
	card_first_pickup_done = false

func is_tutorial_finished() -> bool:
	return tutorial_skipped or (tutorial_pack_done and tutorial_hud_done)

signal fast_mode_changed(enabled: bool)
var fast_mode: bool = false:
	set(value):
		if fast_mode != value:
			fast_mode = value
			fast_mode_changed.emit(fast_mode)

signal scaling_3d_changed(scale: float)

var scaling_3d: float = 1.0:
	set(value):
		scaling_3d = clampf(value, 0.25, 2.0)
		if is_inside_tree() and get_viewport() != null:
			get_viewport().scaling_3d_scale = scaling_3d
		scaling_3d_changed.emit(scaling_3d)

func _ready() -> void:
	_apply_device_settings()

func is_touch_or_mobile() -> bool:
	return (
		DisplayServer.is_touchscreen_available()
		or OS.has_feature("mobile")
		or OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
	)

func _apply_device_settings() -> void:
	if is_touch_or_mobile():
		scaling_3d = 0.75
	else:
		scaling_3d = 1.0

