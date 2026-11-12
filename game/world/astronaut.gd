class_name Astronaut
extends Node3D

enum State {
	IDLE,
	WORKING,
	SICK,
	RESTING,
	SHELTERED,
	EVACUATING
}

const SUIT_COLORS: Array[Color] = [
	Color("#F28C28"), # Crew 0: orange
	Color("#8B5CF6"), # Crew 1: purple
	Color("#EC6FA8"), # Crew 2: pink
	Color("#A0673A")  # Crew 3: brown
]

const COLOR_HELMET := Color("#E9E7E2")
const COLOR_VISOR := Color("#1A1A1A")
const COLOR_BACKPACK := Color("#D8D7D3")
const COLOR_ALERT_RED := Color("#E04848")
const DEFAULT_CREW_NAMES: Array[String] = ["Rafi", "Mira", "Leo", "Nadia"]

const HOP_FREQ_WORKING := 14.0 # rad/s (~2.2 hops/sec)
const HOP_HEIGHT_WORKING := 0.10 # m
const HOP_FREQ_SICK := 7.0 # slower hop
const HOP_HEIGHT_SICK := 0.05

const TRANSIT_HOP_HEIGHT := 0.22 # m
const NAME_TAG_FADE_START_M := 42.0
const NAME_TAG_FADE_END_M := 58.0

static func crew_name_for(idx: int) -> String:
	var clamped_idx: int = clampi(idx, 0, DEFAULT_CREW_NAMES.size() - 1)
	var key: String = "CREW_NAME_%d" % clamped_idx
	var translated: String = TranslationServer.translate(key)
	if translated.is_empty() or translated == key:
		return DEFAULT_CREW_NAMES[clamped_idx]
	return translated

@export var crew_index: int = 0:
	set(val):
		crew_index = clampi(val, 0, 3)
		if is_node_ready():
			_apply_suit_color()
			refresh_name_tag()

@export var base_scale: float = 1.0:
	set(val):
		base_scale = maxf(0.1, val)
		var p := _get_body_pivot()
		if p != null:
			p.scale = Vector3.ONE * base_scale

var current_state: State = State.IDLE
var current_job: String = "REST"

@onready var body_pivot: Node3D = $BodyPivot
@onready var capsule: MeshInstance3D = $BodyPivot/Capsule
@onready var helmet: MeshInstance3D = $BodyPivot/Helmet
@onready var visor: MeshInstance3D = $BodyPivot/Helmet/Visor
@onready var backpack: MeshInstance3D = $BodyPivot/Backpack
@onready var sick_icon: Label3D = $BodyPivot/SickIcon
@onready var name_tag: Label3D = $BodyPivot/NameTag

var _name_tag_hidden: bool = false
var _overlay_tag_mode: bool = false
var _is_selected: bool = false
var _select_hop_tween: Tween = null
var _hop_time: float = 0.0
var _is_moving: bool = false
var _move_progress: float = 0.0
var _move_start_pos: Vector3 = Vector3.ZERO
var _move_target_pos: Vector3 = Vector3.ZERO
var _move_hops: int = 3
var _move_tween: Tween = null
var _suit_mat: StandardMaterial3D = null

func _get_body_pivot() -> Node3D:
	if body_pivot == null:
		body_pivot = get_node_or_null("BodyPivot") as Node3D
	return body_pivot

func _get_capsule() -> MeshInstance3D:
	if capsule == null:
		capsule = get_node_or_null("BodyPivot/Capsule") as MeshInstance3D
	return capsule

func _get_helmet() -> MeshInstance3D:
	if helmet == null:
		helmet = get_node_or_null("BodyPivot/Helmet") as MeshInstance3D
	return helmet

func _get_visor() -> MeshInstance3D:
	if visor == null:
		visor = get_node_or_null("BodyPivot/Helmet/Visor") as MeshInstance3D
	return visor

func _get_backpack() -> MeshInstance3D:
	if backpack == null:
		backpack = get_node_or_null("BodyPivot/Backpack") as MeshInstance3D
	return backpack

func _get_sick_icon() -> Label3D:
	if sick_icon == null:
		sick_icon = get_node_or_null("BodyPivot/SickIcon") as Label3D
	return sick_icon

func _get_name_tag() -> Label3D:
	if name_tag == null:
		name_tag = get_node_or_null("BodyPivot/NameTag") as Label3D
	return name_tag

func _ready() -> void:
	_setup_materials()
	_apply_suit_color()
	refresh_name_tag()
	var p := _get_body_pivot()
	if p != null:
		p.scale = Vector3.ONE * base_scale
	set_state(current_state)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_name_tag()

func refresh_name_tag() -> void:
	var tag := _get_name_tag()
	if tag != null:
		tag.text = crew_name_for(crew_index)
		tag.visible = (not _name_tag_hidden) and (not _overlay_tag_mode)

func set_name_tag_hidden(hidden: bool) -> void:
	_name_tag_hidden = hidden
	var tag := _get_name_tag()
	if tag != null:
		tag.visible = (not _name_tag_hidden) and (not _overlay_tag_mode)
		if tag.visible:
			_update_name_tag_fade()

func is_name_tag_hidden() -> bool:
	return _name_tag_hidden

func set_overlay_tag_mode(enabled: bool) -> void:
	_overlay_tag_mode = enabled
	refresh_name_tag()

func set_selected(selected: bool) -> void:
	_is_selected = selected
	var tag := _get_name_tag()
	if tag != null:
		tag.outline_modulate = Color("F2C14E") if _is_selected else Color(0.08, 0.09, 0.13, 0.95)
		tag.outline_size = 10 if _is_selected else 6

func play_select_hop() -> void:
	if not visible or _is_moving:
		return
	var pivot: Node3D = body_pivot if body_pivot != null else get_node_or_null("BodyPivot") as Node3D
	if pivot == null:
		return
	if _select_hop_tween != null and _select_hop_tween.is_valid():
		_select_hop_tween.kill()
	pivot.position.y = 0.0
	if not is_inside_tree():
		return
	_select_hop_tween = create_tween()
	_select_hop_tween.tween_property(pivot, "position:y", 0.42, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_select_hop_tween.tween_property(pivot, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _setup_materials() -> void:
	var h := _get_helmet()
	if h != null and h.material_override == null:
		var mat_helmet := StandardMaterial3D.new()
		mat_helmet.albedo_color = COLOR_HELMET
		mat_helmet.roughness = 0.4
		h.material_override = mat_helmet

	var v := _get_visor()
	if v != null:
		v.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if v.material_override == null:
			var mat_visor := StandardMaterial3D.new()
			mat_visor.albedo_color = COLOR_VISOR
			mat_visor.roughness = 0.15
			mat_visor.metallic = 0.6
			v.material_override = mat_visor

	var bp := _get_backpack()
	if bp != null:
		bp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if bp.material_override == null:
			var mat_bp := StandardMaterial3D.new()
			mat_bp.albedo_color = COLOR_BACKPACK
			mat_bp.roughness = 0.6
			bp.material_override = mat_bp

func _apply_suit_color() -> void:
	var cap := _get_capsule()
	if cap == null:
		return
	var col: Color = SUIT_COLORS[clampi(crew_index, 0, SUIT_COLORS.size() - 1)]
	if _suit_mat == null:
		_suit_mat = StandardMaterial3D.new()
		_suit_mat.roughness = 0.75
		cap.material_override = _suit_mat
	_suit_mat.albedo_color = col

func set_crew_index(idx: int) -> void:
	crew_index = idx
	_apply_suit_color()
	refresh_name_tag()

func get_suit_color() -> Color:
	return SUIT_COLORS[clampi(crew_index, 0, SUIT_COLORS.size() - 1)]

func _update_name_tag_fade() -> void:
	var tag := _get_name_tag()
	if tag == null:
		return
	if _name_tag_hidden or _overlay_tag_mode or not visible:
		tag.visible = false
		return
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		tag.modulate.a = 1.0
		tag.outline_modulate.a = 1.0
		tag.visible = true
		return
	var dist: float = global_position.distance_to(cam.global_position)
	var alpha: float = clampf(1.0 - (dist - NAME_TAG_FADE_START_M) / (NAME_TAG_FADE_END_M - NAME_TAG_FADE_START_M), 0.0, 1.0)
	tag.modulate.a = alpha
	tag.outline_modulate.a = alpha
	tag.visible = alpha > 0.02

func set_state(new_state: State) -> void:
	current_state = new_state
	var icon := _get_sick_icon()
	match current_state:
		State.IDLE, State.WORKING:
			visible = true
			if icon != null:
				icon.visible = false
		State.SICK:
			visible = true
			if icon != null:
				icon.visible = true
		State.RESTING:
			visible = false
			if icon != null:
				icon.visible = false
		State.SHELTERED:
			visible = false
			if icon != null:
				icon.visible = false
		State.EVACUATING:
			visible = true
			if icon != null:
				icon.visible = false

func set_sick(sick: bool) -> void:
	if sick:
		set_state(State.SICK)
	elif current_job == "REST":
		set_state(State.RESTING)
	else:
		set_state(State.WORKING)

func is_sick_icon_visible() -> bool:
	var icon := _get_sick_icon()
	return icon != null and icon.visible and visible

func hop_to(target_pos: Vector3, duration: float = 1.5, hops: int = 3, on_complete: Callable = Callable()) -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()

	_move_start_pos = position
	_move_target_pos = target_pos
	_move_hops = maxi(1, hops)
	_move_progress = 0.0

	var dir := target_pos - position
	dir.y = 0.0
	if is_inside_tree() and dir.length_squared() > 0.01:
		look_at(position + dir, Vector3.UP)

	if not is_inside_tree():
		position = target_pos
		_is_moving = false
		if on_complete.is_valid():
			on_complete.call()
		return

	_is_moving = true
	_move_tween = create_tween()
	if _move_tween != null:
		_move_tween.tween_property(self, "_move_progress", 1.0, duration).set_trans(Tween.TRANS_LINEAR)
		_move_tween.tween_callback(func():
			_is_moving = false
			position = target_pos
			var p := _get_body_pivot()
			if p != null:
				p.position.y = 0.0
				p.scale = Vector3.ONE * base_scale
			if on_complete.is_valid():
				on_complete.call()
		)
	else:
		_is_moving = false
		position = target_pos
		var p := _get_body_pivot()
		if p != null:
			p.position.y = 0.0
			p.scale = Vector3.ONE * base_scale
		if on_complete.is_valid():
			on_complete.call()

func _process(delta: float) -> void:
	_update_name_tag_fade()
	var p := _get_body_pivot()
	if p == null:
		return

	if _is_moving:
		var progress := _move_progress
		position.x = lerp(_move_start_pos.x, _move_target_pos.x, progress)
		position.z = lerp(_move_start_pos.z, _move_target_pos.z, progress)
		var hop_cycle := progress * float(_move_hops)
		var hop_phase := fposmod(hop_cycle, 1.0)
		var hop_sin := sin(hop_phase * PI)
		p.position.y = hop_sin * (TRANSIT_HOP_HEIGHT * base_scale)
		if hop_sin < 0.2:
			var sq := (0.2 - hop_sin) / 0.2 * 0.15
			p.scale = base_scale * Vector3(1.0 + sq, 1.0 - sq * 1.2, 1.0 + sq)
		else:
			p.scale = base_scale * Vector3(0.96, 1.04, 0.96)
	else:
		if current_state == State.WORKING or current_state == State.SICK or current_state == State.IDLE or current_state == State.EVACUATING:
			var freq := HOP_FREQ_SICK if current_state == State.SICK else HOP_FREQ_WORKING
			var height := HOP_HEIGHT_SICK if current_state == State.SICK else HOP_HEIGHT_WORKING
			_hop_time += delta * freq
			var hop := absf(sin(_hop_time))
			p.position.y = hop * (height * base_scale)
			if hop < 0.15:
				var sq := (0.15 - hop) / 0.15 * 0.12
				p.scale = base_scale * Vector3(1.0 + sq, 1.0 - sq * 1.1, 1.0 + sq)
			else:
				p.scale = base_scale * Vector3(0.97, 1.03, 0.97)
		else:
			p.position.y = 0.0
			p.scale = Vector3.ONE * base_scale
