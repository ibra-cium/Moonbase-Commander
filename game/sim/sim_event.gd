class_name SimEvent
extends RefCounted

var code: String = ""
var day: int = 0
var needs_popup: bool = false
var needs_choice: bool = false
var data: Dictionary = {}

func _init(p_code: String = "", p_day: int = 0, p_needs_popup: bool = false, p_data: Dictionary = {}) -> void:
	code = p_code
	day = p_day
	needs_popup = p_needs_popup
	needs_choice = p_needs_popup
	data = p_data

func to_dict() -> Dictionary:
	return {
		"code": code,
		"day": day,
		"needs_popup": needs_popup,
		"needs_choice": needs_choice,
		"data": data.duplicate(true),
	}

