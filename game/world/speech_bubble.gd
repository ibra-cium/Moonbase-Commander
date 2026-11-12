class_name SpeechBubble
extends Control

signal bubble_hidden

const AstronautScript := preload("res://world/astronaut.gd")

const BUBBLE_SHOW_SEC: float = 3.0
const POP_IN_SEC: float = 0.18
const FADE_OUT_SEC: float = 0.35
const MAX_TEXT_WIDTH: float = 320.0
const SCREEN_MARGIN: float = 16.0
const TAIL_HEIGHT: float = 8.0
const CREW_COUNT_DEFAULT: int = 4

const FALLBACK_LINES := {
	"CREW_SAY_HELLO": "Ready to work, Commander!",
	"CREW_SAY_STORM": "Into the shelter, quick!",
	"CREW_SAY_SICK": "I feel dizzy. I need rest.",
	"CREW_SAY_OVERWORKED": "I worked too hard and got sick...",
	"CREW_SAY_BROKEN": "Something broke! Who can fix it?",
	"CREW_SAY_TIRED": "I am exhausted. Can I rest tomorrow?",
	"CREW_SAY_STUFFY": "The air feels stuffy...",
	"CREW_SAY_FOOD_LOW": "We are running out of food!",
	"CREW_SAY_DARK": "It's so dark. Is the battery OK?",
	"CREW_SAY_FIXED": "Fixed it!",
	"CREW_SAY_SCIENCE": "We found something cool in the rocks!",
	"CREW_SAY_GOOD": "All good out here!",
}

@onready var bubble_panel: PanelContainer = $BubblePanel
@onready var text_label: Label = $BubblePanel/Margin/TextLabel
@onready var tail_poly: Polygon2D = $BubblePanel/Tail

var _panel_style: StyleBoxFlat = null
var _target_node: Node3D = null
var _avoid_control: Control = null
var _crew_index: int = 0
var _tween: Tween = null

func _ensure_nodes() -> void:
	if bubble_panel == null:
		bubble_panel = get_node_or_null("BubblePanel") as PanelContainer
	if text_label == null:
		text_label = get_node_or_null("BubblePanel/Margin/TextLabel") as Label
	if tail_poly == null:
		tail_poly = get_node_or_null("BubblePanel/Tail") as Polygon2D
	if _panel_style == null and bubble_panel != null:
		var existing := bubble_panel.get_theme_stylebox("panel")
		if existing is StyleBoxFlat:
			_panel_style = existing.duplicate() as StyleBoxFlat
		else:
			_panel_style = StyleBoxFlat.new()
			_panel_style.bg_color = Color(0.0784314, 0.0941176, 0.129412, 0.92)
			_panel_style.corner_radius_top_left = 12
			_panel_style.corner_radius_top_right = 12
			_panel_style.corner_radius_bottom_right = 12
			_panel_style.corner_radius_bottom_left = 12
		_panel_style.border_width_left = 2
		_panel_style.border_width_top = 2
		_panel_style.border_width_right = 2
		_panel_style.border_width_bottom = 2
		bubble_panel.add_theme_stylebox_override("panel", _panel_style)

var _current_line_key: String = ""

func _ready() -> void:
	_ensure_nodes()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	if Settings != null and Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
		Settings.language_changed.connect(_on_language_changed)

func _on_language_changed(_lang: String) -> void:
	if visible and _current_line_key.begins_with("CREW_SAY_") and text_label != null:
		text_label.text = translate_line(_current_line_key)

func _process(_delta: float) -> void:
	if not visible:
		return
	_update_screen_position()

static func translate_line(key: String) -> String:
	var translated: String = TranslationServer.translate(key)
	if translated.is_empty() or translated == key:
		return str(FALLBACK_LINES.get(key, key))
	return translated

static func pick_hello(mission_seed: int, sick_flags: Array = []) -> Dictionary:
	var healthy := _collect_healthy_from_flags(sick_flags)
	return {
		"key": "CREW_SAY_HELLO",
		"crew_index": _pick_seeded(healthy, mission_seed),
		"day": 0
	}

static func pick_voice(report, context: Dictionary = {}) -> Dictionary:
	var day: int = int(_field(report, "day", 1))
	var storm_dose: float = float(_field(report, "storm_dose_msv", 0.0))
	var events_val = _field(report, "events", [])
	var events: Array = events_val if events_val is Array else []
	var co2_mmhg: float = float(_field(report, "co2_mmhg", 0.0))
	var food_kg: float = float(_field(report, "food_kg", 100.0))
	var recycler_broken: bool = bool(_field(report, "recycler_broken", false))
	var broken_panels: int = int(_field(report, "broken_panels", 0))
	var science_points: int = int(_field(report, "science_points", 0))
	var crew_reps_val = _field(report, "crew_reports", [])
	var crew_reps: Array = crew_reps_val if crew_reps_val is Array else []

	var prev_sick: Array = context.get("prev_sick", [])
	var prev_recycler_broken: bool = bool(context.get("prev_recycler_broken", false))
	var prev_broken_panels: int = int(context.get("prev_broken_panels", 0))
	var prev_science_points: int = int(context.get("prev_science_points", 0))
	var seed_val: int = int(context.get("seed_val", 1))

	var sunset_day: int = int(context.get("sunset_day", _const_val("SUNSET_DAY", 15.0)))
	var co2_healthy_max: float = float(context.get("co2_healthy_max", _const_val("CO2_HEALTHY_MAX_MMHG", 2.0)))
	var supply_warn_days: float = float(context.get("supply_warning_days", _const_val("SUPPLY_WARNING_DAYS", 3.0)))
	var food_per_person_day: float = float(context.get("food_per_person_day", _const_val("FOOD_PACKED_KG_PERSON_DAY", 2.39)))
	var crew_count: int = int(context.get("crew_count", _const_val("MISSION_CREW", float(CREW_COUNT_DEFAULT))))

	var max_energy: int = int(_const_val("CREW_ENERGY_MAX", 3.0))
	var has_ctx_tired: bool = context.has("newly_tired")
	var ctx_tired: Array = context.get("newly_tired", [])
	var report_ever_tired: bool = bool(_field(report, "ever_tired", false))

	var now_sick: Array[bool] = []
	var newly_sick: Array[int] = []
	var newly_tired: Array[int] = []
	var tired_healthy: Array[int] = []
	var healthy: Array[int] = []
	var repairers: Array[int] = []
	var healthy_repairers: Array[int] = []

	for idx_val in ctx_tired:
		newly_tired.append(int(idx_val))

	for i in range(CREW_COUNT_DEFAULT):
		var sick: bool = false
		var job: String = "REST"
		var has_energy_field: bool = false
		var energy_val: int = max_energy
		if i < crew_reps.size():
			var cr = crew_reps[i]
			sick = bool(_field(cr, "sick", false))
			job = str(_field(cr, "job", "REST"))
			if cr is Dictionary and cr.has("energy"):
				has_energy_field = true
				energy_val = int(cr["energy"])
			elif cr is Object and "energy" in cr:
				has_energy_field = true
				energy_val = int(cr.energy)
		now_sick.append(sick)
		var was_sick: bool = bool(prev_sick[i]) if i < prev_sick.size() else false
		if sick and not was_sick:
			newly_sick.append(i)
			if not has_ctx_tired and report_ever_tired and has_energy_field and energy_val <= 0:
				newly_tired.append(i)
		if not sick:
			healthy.append(i)
			if has_energy_field and energy_val <= 0:
				tired_healthy.append(i)
		if job == "REPAIR":
			repairers.append(i)
			if not sick:
				healthy_repairers.append(i)

	var has_storm_evt: bool = false
	var has_broke_evt: bool = false
	for evt in events:
		var code: String = str(_field(evt, "code", ""))
		if code == "STORM" or code == "STORM_WARNING" or code == "SOLAR_STORM":
			has_storm_evt = true
		elif code == "RECYCLER_BROKE" or code == "METEOROID":
			has_broke_evt = true

	var eat_per_day: float = maxf(0.01, food_per_person_day * float(maxi(1, crew_count)))
	var food_days: float = food_kg / eat_per_day
	var rep_seed: int = seed_val + day * 31

	var line_key: String = "CREW_SAY_GOOD"
	var speaker_idx: int = _pick_seeded(healthy, rep_seed)

	if bool(context.get("is_storm", false)) or has_storm_evt or storm_dose > 0.0:
		line_key = "CREW_SAY_STORM"
	elif not newly_tired.is_empty():
		line_key = "CREW_SAY_OVERWORKED"
		speaker_idx = _pick_seeded(newly_tired, rep_seed)
	elif not newly_sick.is_empty():
		line_key = "CREW_SAY_SICK"
		speaker_idx = _pick_seeded(newly_sick, rep_seed)
	elif has_broke_evt or (not prev_recycler_broken and recycler_broken) or (broken_panels > prev_broken_panels):
		line_key = "CREW_SAY_BROKEN"
	elif not tired_healthy.is_empty():
		line_key = "CREW_SAY_TIRED"
		speaker_idx = _pick_seeded(tired_healthy, rep_seed)
	elif co2_mmhg > co2_healthy_max:
		line_key = "CREW_SAY_STUFFY"
	elif food_days < supply_warn_days:
		line_key = "CREW_SAY_FOOD_LOW"
	elif day == sunset_day + 1:
		line_key = "CREW_SAY_DARK"
	elif (prev_recycler_broken and not recycler_broken) or (broken_panels < prev_broken_panels):
		line_key = "CREW_SAY_FIXED"
		if not healthy_repairers.is_empty():
			speaker_idx = _pick_seeded(healthy_repairers, rep_seed)
		elif not repairers.is_empty():
			speaker_idx = _pick_seeded(repairers, rep_seed)
	elif science_points > prev_science_points:
		line_key = "CREW_SAY_SCIENCE"

	return {
		"key": line_key,
		"crew_index": speaker_idx,
		"day": day
	}

func show_bubble(line_or_key: String, target: Node3D = null, crew_idx: int = 0, avoid_control: Control = null) -> void:
	_ensure_nodes()
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null

	_target_node = target
	_avoid_control = avoid_control
	_crew_index = clampi(crew_idx, 0, AstronautScript.SUIT_COLORS.size() - 1)
	_current_line_key = line_or_key

	var display_text: String = translate_line(line_or_key) if line_or_key.begins_with("CREW_SAY_") else line_or_key

	if _panel_style != null:
		_panel_style.border_color = AstronautScript.SUIT_COLORS[_crew_index]

	if text_label != null:
		text_label.text = display_text
		var font: Font = text_label.get_theme_font("font")
		var fsize: int = text_label.get_theme_font_size("font_size")
		var str_w: float = font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x if font != null else float(display_text.length() * 12)
		if str_w > MAX_TEXT_WIDTH:
			text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_label.custom_minimum_size = Vector2(MAX_TEXT_WIDTH, 0.0)
		else:
			text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			text_label.custom_minimum_size = Vector2.ZERO

	if bubble_panel != null:
		bubble_panel.reset_size()
		var p_size: Vector2 = bubble_panel.get_combined_minimum_size()
		bubble_panel.size = p_size
		bubble_panel.pivot_offset = p_size * 0.5
		if tail_poly != null:
			tail_poly.position = Vector2(p_size.x * 0.5, p_size.y)

	visible = true
	modulate.a = 0.0
	_update_screen_position()

	if bubble_panel != null:
		bubble_panel.scale = Vector2(0.82, 0.82)

	if is_inside_tree():
		_tween = create_tween()
		if _tween != null:
			var fade_in_t := _tween.tween_property(self, "modulate:a", 1.0, POP_IN_SEC)
			fade_in_t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			if bubble_panel != null:
				var scale_t := _tween.parallel().tween_property(bubble_panel, "scale", Vector2.ONE, POP_IN_SEC)
				scale_t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_tween.tween_interval(BUBBLE_SHOW_SEC)
			var fade_out_t := _tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_SEC)
			fade_out_t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			_tween.tween_callback(hide_bubble)
			return

	modulate.a = 1.0
	if bubble_panel != null:
		bubble_panel.scale = Vector2.ONE

func hide_bubble() -> void:
	var was_visible: bool = visible
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null
	visible = false
	_target_node = null
	if was_visible:
		bubble_hidden.emit()

func is_showing() -> bool:
	return visible

func _update_screen_position() -> void:
	if bubble_panel == null:
		return
	var in_tree: bool = is_inside_tree()
	var vp_size: Vector2 = get_viewport_rect().size if in_tree else Vector2(1280.0, 720.0)
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		vp_size = Vector2(1280.0, 720.0)
	var panel_size: Vector2 = bubble_panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = bubble_panel.get_combined_minimum_size()

	var screen_pos: Vector2 = Vector2(vp_size.x * 0.5, vp_size.y * 0.42)
	var cam: Camera3D = get_viewport().get_camera_3d() if in_tree else null
	if cam != null:
		var world_pos: Vector3 = Vector3(0.0, 2.2, 2.0)
		if _target_node != null and _target_node.is_inside_tree():
			var y_off: float = 2.05 if _target_node.visible else 2.6
			world_pos = _target_node.global_position + Vector3(0.0, y_off, 0.0)
		if not cam.is_position_behind(world_pos):
			screen_pos = cam.unproject_position(world_pos)

	var pos := Vector2(screen_pos.x - panel_size.x * 0.5, screen_pos.y - panel_size.y - TAIL_HEIGHT - 4.0)
	pos.x = clampf(pos.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, vp_size.x - panel_size.x - SCREEN_MARGIN))
	pos.y = clampf(pos.y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, vp_size.y - panel_size.y - TAIL_HEIGHT - SCREEN_MARGIN))

	if in_tree and _avoid_control != null and _avoid_control.is_visible_in_tree():
		var avoid_rect: Rect2 = _avoid_control.get_global_rect().grow(8.0)
		var bubble_rect: Rect2 = Rect2(pos, panel_size + Vector2(0.0, TAIL_HEIGHT))
		if bubble_rect.intersects(avoid_rect):
			var below_y: float = avoid_rect.end.y + 8.0
			if below_y + panel_size.y + TAIL_HEIGHT + SCREEN_MARGIN <= vp_size.y:
				pos.y = below_y
			else:
				pos.y = maxf(SCREEN_MARGIN, avoid_rect.position.y - panel_size.y - TAIL_HEIGHT - 8.0)

	bubble_panel.position = pos

static func _collect_healthy_from_flags(sick_flags: Array) -> Array[int]:
	var healthy: Array[int] = []
	for i in range(CREW_COUNT_DEFAULT):
		var sick: bool = bool(sick_flags[i]) if i < sick_flags.size() else false
		if not sick:
			healthy.append(i)
	return healthy

static func _pick_seeded(indices: Array[int], seed_int: int) -> int:
	if indices.is_empty():
		return 0
	if indices.size() == 1:
		return indices[0]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_int)
	return indices[rng.randi_range(0, indices.size() - 1)]

static func _field(obj, field_name: String, default_val):
	if obj == null:
		return default_val
	if obj is Dictionary:
		return obj.get(field_name, default_val)
	if field_name in obj:
		return obj.get(field_name)
	return default_val

static func _const_val(id: String, fallback: float) -> float:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var c = tree.root.get_node_or_null("Constants")
		if c != null and c.has_method("has") and c.has(id):
			return float(c.v(id))
	return fallback

