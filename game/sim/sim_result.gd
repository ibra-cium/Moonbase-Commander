class_name SimResult
extends RefCounted

var outcome: String = ""
var end_day: int = 0
var total_days: int = 30
var stars: int = 0
var cause_chain: Array[Dictionary] = []
var root_cause_code: String = ""
var root_cause_values: Dictionary = {}
var root_cause_text: String = ""
var fact_id: String = ""
var fact: Dictionary = {}
var stats: Dictionary = {}

func is_success() -> bool:
	return outcome == "SURVIVED"

func to_dict() -> Dictionary:
	return {
		"outcome": outcome,
		"end_day": end_day,
		"total_days": total_days,
		"stars": stars,
		"cause_chain": cause_chain.duplicate(true),
		"root_cause_code": root_cause_code,
		"root_cause_values": root_cause_values.duplicate(true),
		"root_cause_text": root_cause_text,
		"fact_id": fact_id,
		"fact": fact.duplicate(true),
		"stats": stats.duplicate(true),
		"is_success": is_success()
	}

