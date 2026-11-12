class_name SimConstants
extends RefCounted

var _entries: Dictionary = {}

static func from_json(text: String) -> SimConstants:
	var instance := SimConstants.new()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		var dict: Dictionary = parsed as Dictionary
		if dict.has("values") and dict["values"] is Dictionary:
			instance._entries = dict["values"]
		else:
			instance._entries = dict
	else:
		push_error("SimConstants.from_json: Failed to parse valid JSON dictionary")
	return instance

func v(id: String) -> Variant:
	if _entries.has(id):
		return _entries[id].get("value")
	push_error("SimConstants: Unknown constant ID: %s" % id)
	assert(false, "SimConstants: Unknown constant ID: %s" % id)
	return null

func has(id: String) -> bool:
	return _entries.has(id)

func meta(id: String) -> Dictionary:
	if _entries.has(id):
		return _entries[id]
	push_error("SimConstants: Unknown constant ID for meta: %s" % id)
	return {}

## Returns a new SimConstants whose values for the given IDs are replaced.
## `overrides` maps ID string -> new numeric value.
## The original object is not modified.
func with_overrides(overrides: Dictionary) -> SimConstants:
	var copy := SimConstants.new()
	copy._entries = _entries.duplicate(true)
	for id in overrides.keys():
		if copy._entries.has(id):
			# Replace only the value field; keep type/unit/etc. intact
			var entry: Dictionary = copy._entries[id].duplicate()
			entry["value"] = overrides[id]
			copy._entries[id] = entry
		else:
			# New key not in the original – add a minimal entry
			copy._entries[id] = {"value": overrides[id], "type": "Game setting", "system": "Missions"}
	return copy

func ids() -> PackedStringArray:
	var result := PackedStringArray()
	for key in _entries.keys():
		result.append(str(key))
	return result

