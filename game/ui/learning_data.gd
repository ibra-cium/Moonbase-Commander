class_name LearningData
extends RefCounted

const LEARNING_PATH: String = "res://data/learning.json"
const FACTS_PATH: String = "res://data/facts.json"

const ICON_LANDSCAPE := preload("res://assets/icons/landscape.svg")
const ICON_SHIELD := preload("res://assets/icons/shield.svg")
const ICON_ROCKET := preload("res://assets/icons/rocket_launch.svg")
const ICON_WATER := preload("res://assets/icons/water_drop.svg")
const ICON_AIR := preload("res://assets/icons/air.svg")
const ICON_ECO := preload("res://assets/icons/eco.svg")
const ICON_BOLT := preload("res://assets/icons/bolt.svg")
const ICON_SCIENCE := preload("res://assets/icons/science.svg")
const ICON_WARNING := preload("res://assets/icons/warning.svg")
const ICON_CLEANING := preload("res://assets/icons/cleaning_services.svg")
const ICON_NIGHT := preload("res://assets/icons/nightlight.svg")
const ICON_SUN := preload("res://assets/icons/wb_sunny.svg")
const ICON_CONSTRUCTION := preload("res://assets/icons/construction.svg")
const ICON_BEDTIME := preload("res://assets/icons/bedtime.svg")
const ICON_STAR := preload("res://assets/icons/star.svg")

var _data: Dictionary = {}
var _facts_by_id: Dictionary = {}
var _facts_list: Array = []
var _cards_by_fact_id: Dictionary = {}
var _cards_by_trigger: Dictionary = {}
var _format_regex: RegEx


func _init() -> void:
	_format_regex = RegEx.new()
	_format_regex.compile("\\{([A-Za-z0-9_]+)\\|([a-z0-9]+)\\}")
	_load_learning()
	_load_facts()


func _load_learning() -> void:
	if not FileAccess.file_exists(LEARNING_PATH):
		return
	var text_data: String = FileAccess.get_file_as_string(LEARNING_PATH)
	var parsed: Variant = JSON.parse_string(text_data)
	if parsed is Dictionary:
		_data = parsed
		_index_cards()


func _index_cards() -> void:
	_cards_by_fact_id.clear()
	_cards_by_trigger.clear()
	for entry in cards():
		if not (entry is Dictionary):
			continue
		var card: Dictionary = entry
		var fid: String = str(card.get("fact_id", ""))
		if not fid.is_empty():
			_cards_by_fact_id[fid] = card
		var trig: String = str(card.get("trigger", ""))
		if not trig.is_empty():
			if not _cards_by_trigger.has(trig):
				_cards_by_trigger[trig] = []
			(_cards_by_trigger[trig] as Array).append(card)


func _load_facts() -> void:
	if not FileAccess.file_exists(FACTS_PATH):
		return
	var text_data: String = FileAccess.get_file_as_string(FACTS_PATH)
	var parsed: Variant = JSON.parse_string(text_data)
	if parsed is Dictionary:
		var arr: Variant = parsed.get("facts", [])
		if arr is Array:
			_facts_list = arr
			for entry in _facts_list:
				if entry is Dictionary:
					var fid: String = str(entry.get("id", ""))
					if not fid.is_empty():
						_facts_by_id[fid] = entry


func _is_bangla() -> bool:
	return Settings != null and Settings.language == "bn"


## Return bn when language is Bangla and bn is non-empty; otherwise en.
func text(obj: Variant) -> String:
	if obj == null:
		return ""
	if obj is String:
		return obj
	if obj is Dictionary:
		var dict: Dictionary = obj
		var en_text: String = str(dict.get("en", ""))
		if _is_bangla():
			var bn_text: String = str(dict.get("bn", ""))
			if not bn_text.strip_edges().is_empty():
				return bn_text
		return en_text
	return ""


## Resolve {CONSTANT_ID|fmt} tokens using Constants.v(ID).
## Formats: 0 = whole number, 1 = one decimal, pct = x100 then %, k = nearest 1,000 with commas.
func format(s: String) -> String:
	if s.is_empty() or _format_regex == null:
		return s
	var matches: Array[RegExMatch] = _format_regex.search_all(s)
	if matches.is_empty():
		return s
	var out: String = ""
	var cursor: int = 0
	for m in matches:
		var start_idx: int = m.get_start(0)
		var end_idx: int = m.get_end(0)
		out += s.substr(cursor, start_idx - cursor)
		var const_id: String = m.get_string(1)
		var fmt: String = m.get_string(2)
		if Constants != null and Constants.has(const_id):
			var raw_val: float = float(Constants.v(const_id))
			out += _format_value(raw_val, fmt)
		else:
			out += m.get_string(0)
		cursor = end_idx
	out += s.substr(cursor)
	return out


func formatted_text(obj: Variant) -> String:
	return format(text(obj))


func _format_value(val: float, fmt: String) -> String:
	match fmt:
		"0":
			return str(roundi(val))
		"1":
			return "%.1f" % val
		"pct":
			return "%d%%" % roundi(val * 100.0)
		"k":
			var nearest_thousand: int = roundi(val / 1000.0) * 1000
			return _format_commas(nearest_thousand)
		_:
			return str(val)


func _format_commas(value: int) -> String:
	var sign_prefix: String = "-" if value < 0 else ""
	var digits: String = str(absi(value))
	var length: int = digits.length()
	if length <= 3:
		return sign_prefix + digits
	var parts: Array[String] = []
	var idx: int = length
	while idx > 0:
		var take_start: int = maxi(0, idx - 3)
		parts.push_front(digits.substr(take_start, idx - take_start))
		idx = take_start
	return sign_prefix + ",".join(parts)


func find_placeholders(s: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _format_regex == null:
		return result
	for m in _format_regex.search_all(s):
		result.append({
			"id": m.get_string(1),
			"fmt": m.get_string(2),
		})
	return result


func mission_control() -> Dictionary:
	var mc: Variant = _data.get("mission_control", {})
	return mc if mc is Dictionary else {}


func mission_control_name() -> String:
	return text(mission_control())


func ranks() -> Array:
	var arr: Variant = _data.get("ranks", [])
	return arr if arr is Array else []


func rank_info(rank_id: String) -> Dictionary:
	for r in ranks():
		if r is Dictionary and str(r.get("id", "")) == rank_id:
			return r
	return {}


func rank_name(rank_id: String) -> String:
	return text(rank_info(rank_id).get("name", {}))


func rank_order(rank_id: String) -> int:
	var list: Array = ranks()
	for i in range(list.size()):
		var entry: Variant = list[i]
		if entry is Dictionary and str(entry.get("id", "")) == rank_id:
			return i
	return -1


func rank_after(mid: String) -> String:
	if mid.is_empty():
		return ""
	for r in ranks():
		if r is Dictionary and str(r.get("after", "")) == mid:
			return str(r.get("id", ""))
	return ""


func _mission(mid: String) -> Dictionary:
	var missions: Variant = _data.get("missions", {})
	if missions is Dictionary:
		var entry: Variant = missions.get(mid, {})
		if entry is Dictionary:
			return entry
	return {}


func briefing(mid: String) -> Array:
	var arr: Variant = _mission(mid).get("briefing", [])
	return arr if arr is Array else []


func question(mid: String) -> Dictionary:
	var q: Variant = _mission(mid).get("question", {})
	return q if q is Dictionary else {}


func lesson(mid: String) -> Dictionary:
	var l: Variant = _mission(mid).get("lesson", {})
	return l if l is Dictionary else {}


func nasa_now_fact_id(mid: String) -> String:
	return str(_mission(mid).get("nasa_now_fact", ""))


func nasa_now_fact(mid: String) -> Dictionary:
	return fact(nasa_now_fact_id(mid))


func fact(id: String) -> Dictionary:
	if id.is_empty():
		return {}
	var entry: Variant = _facts_by_id.get(id, {})
	return entry if entry is Dictionary else {}


func all_facts() -> Array:
	return _facts_list


func cards() -> Array:
	var arr: Variant = _data.get("cards", [])
	return arr if arr is Array else []


func card_by_fact_id(fact_id: String) -> Dictionary:
	if fact_id.is_empty():
		return {}
	var entry: Variant = _cards_by_fact_id.get(fact_id, {})
	return entry if entry is Dictionary else {}


func cards_for_trigger(trigger: String) -> Array:
	if trigger.is_empty():
		return []
	var arr: Variant = _cards_by_trigger.get(trigger, [])
	return arr if arr is Array else []


func cards_by_category(cat: String) -> Array:
	if cat.is_empty() or cat == "all":
		return cards()
	var out: Array = []
	for entry in cards():
		if entry is Dictionary and str(entry.get("category", "")) == cat:
			out.append(entry)
	return out


func total_cards_count() -> int:
	return cards().size()


func science_thresholds() -> Array:
	var arr: Variant = _data.get("science_thresholds", [])
	return arr if arr is Array else []


func quiet_day_pool() -> Array[String]:
	var out: Array[String] = []
	var arr: Variant = _data.get("quiet_day_pool", [])
	if arr is Array:
		for item in arr:
			var s: String = str(item)
			if not s.is_empty():
				out.append(s)
	return out


static func category_color(cat: String) -> Color:
	match cat:
		"moon":
			return UIColors.REGOLITH
		"survival":
			return UIColors.WATER
		"nasa":
			return UIColors.POWER
		_:
			return UIColors.REGOLITH


static func card_icon(card: Dictionary) -> Texture2D:
	var trig: String = str(card.get("trigger", ""))
	var cat: String = str(card.get("category", ""))
	match trig:
		"landed", "sunset":
			return ICON_NIGHT
		"first_outside_job", "first_regolith":
			return ICON_LANDSCAPE
		"science_1", "science_3", "science_6", "science_10", "science_15":
			return ICON_SCIENCE
		"dusty", "first_clean":
			return ICON_CLEANING
		"meteoroid", "storm_warning":
			return ICON_WARNING
		"recycler_broke":
			return ICON_WATER
		"storm_survived":
			return ICON_SHIELD
		"night_reactor":
			return ICON_BOLT
		"night_battery_low":
			return ICON_BOLT
		"first_farm":
			return ICON_ECO
		"crew_tired":
			return ICON_BEDTIME
		"quiet_day":
			return ICON_ROCKET
		_:
			pass
	match cat:
		"moon":
			return ICON_LANDSCAPE
		"survival":
			return ICON_SHIELD
		"nasa":
			return ICON_ROCKET
		_:
			return ICON_STAR


func missions_dict() -> Dictionary:
	var m: Variant = _data.get("missions", {})
	return m if m is Dictionary else {}


func raw_data() -> Dictionary:
	return _data

