extends Node3D

signal empty_ground_tapped

const EMPTY_TAP_MAX_PX: float = 12.0
const BUTTON_TOUCH_GUARD_PX: float = 8.0
const TOUCH_MOUSE_GUARD_MSEC: int = 300

@export var min_pitch_deg: float = 25.0
@export var max_pitch_deg: float = 65.0
@export var min_distance: float = 18.0
@export var max_distance: float = 60.0
@export var default_distance: float = 35.0
@export var default_pitch_deg: float = 40.0
@export var default_yaw_deg: float = -30.0
@export var damping: float = 12.0
@export var mouse_sensitivity: float = 0.005
@export var touch_sensitivity: float = 0.005
@export var zoom_step: float = 3.0
@export var pinch_sensitivity: float = 0.05

@onready var yaw_node: Node3D = $YawNode
@onready var pitch_node: Node3D = $YawNode/PitchNode
@onready var camera: Camera3D = $YawNode/PitchNode/Camera3D

var target_yaw: float = 0.0
var target_pitch: float = 0.0
var target_distance: float = 35.0

var current_yaw: float = 0.0
var current_pitch: float = 0.0
var current_distance: float = 35.0

var _mouse_dragging: bool = false
var _touches: Dictionary = {}
var _touch_start_on_ui: Dictionary = {}
var _mouse_start_on_ui: bool = false
var _mouse_start_pos: Vector2 = Vector2.ZERO
var _mouse_move_dist: float = 0.0
var _touch_start_pos: Dictionary = {}
var _touch_move_dist: Dictionary = {}
var _touch_had_multi: bool = false
var _last_empty_tap_ms: int = -1000
var _last_touch_msec: int = -1000

func _ready() -> void:
	target_yaw = deg_to_rad(default_yaw_deg)
	target_pitch = deg_to_rad(default_pitch_deg)
	target_distance = default_distance

	current_yaw = target_yaw
	current_pitch = target_pitch
	current_distance = target_distance

	_update_transforms()

func _process(delta: float) -> void:
	var blend: float = 1.0 - exp(-damping * delta)
	current_yaw = lerp_angle(current_yaw, target_yaw, blend)
	current_pitch = lerpf(current_pitch, target_pitch, blend)
	current_distance = lerpf(current_distance, target_distance, blend)
	_update_transforms()

func reset_camera(duration: float = 0.5) -> void:
	if duration <= 0.01 or not is_inside_tree():
		position = Vector3.ZERO
		target_yaw = deg_to_rad(default_yaw_deg)
		target_pitch = deg_to_rad(default_pitch_deg)
		target_distance = default_distance
		current_yaw = target_yaw
		current_pitch = target_pitch
		current_distance = target_distance
		_update_transforms()
		return

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position", Vector3.ZERO, duration).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "target_yaw", deg_to_rad(default_yaw_deg), duration).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "target_pitch", deg_to_rad(default_pitch_deg), duration).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "target_distance", default_distance, duration).set_trans(Tween.TRANS_SINE)

func follow_liftoff(duration: float = 2.4) -> Tween:
	if not is_inside_tree() or duration <= 0.01:
		return null
	var tw := create_tween()
	tw.set_parallel(true)
	var p_min := deg_to_rad(min_pitch_deg)
	tw.tween_property(self, "target_pitch", p_min, duration * 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "target_distance", 48.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", 15.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tw

func frame_celebration(duration: float = 1.5) -> Tween:
	if not is_inside_tree() or duration <= 0.01:
		return null
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position", Vector3(0.0, 0.0, 0.0), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "target_pitch", deg_to_rad(30.0), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "target_distance", 25.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tw

func _update_transforms() -> void:
	if yaw_node:
		yaw_node.rotation.y = current_yaw
	if pitch_node:
		pitch_node.rotation.x = -current_pitch
	if camera:
		camera.position.z = current_distance

func is_ui_blocking_point(pos: Vector2) -> bool:
	var vp: Viewport = get_viewport()
	if vp != null:
		var ctrl: Control = vp.gui_get_hovered_control()
		if ctrl != null and ctrl.is_visible_in_tree() and ctrl.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			if ctrl.get_global_rect().has_point(pos):
				return true
	var root_node: Node = get_tree().root if is_inside_tree() and get_tree() != null else null
	if root_node == null:
		var ml := Engine.get_main_loop()
		if ml is SceneTree:
			root_node = (ml as SceneTree).root
		elif vp != null:
			root_node = vp
	return _has_blocking_control_at(root_node, pos)

func _has_blocking_control_at(node: Node, pos: Vector2) -> bool:
	if node == null:
		return false
	if node is SubViewport:
		return false
	if node is CanvasLayer and not (node as CanvasLayer).visible:
		return false
	if node is CanvasItem and not (node as CanvasItem).visible:
		return false
	if node is Control:
		var c := node as Control
		var rect := c.get_global_rect()
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			if c.mouse_filter == Control.MOUSE_FILTER_STOP and rect.has_point(pos):
				return true
			if c is BaseButton and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				if rect.grow(BUTTON_TOUCH_GUARD_PX).has_point(pos):
					return true
	for child in node.get_children():
		if _has_blocking_control_at(child, pos):
			return true
	return false

func _is_hovering_ui() -> bool:
	var vp := get_viewport()
	if vp:
		var ctrl: Control = vp.gui_get_hovered_control()
		if ctrl and ctrl.is_visible_in_tree() and ctrl.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return true
	return false

func _emit_empty_ground_tapped() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_empty_tap_ms < 80:
		return
	_last_empty_tap_ms = now
	empty_ground_tapped.emit()

func _is_world_visible() -> bool:
	var cur: Node = self
	while cur != null:
		if cur is Node3D and not (cur as Node3D).visible:
			return false
		cur = cur.get_parent()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _is_world_visible():
		return
	var sens_mult: float = 1.0
	var settings_node: Node = get_node_or_null("/root/Settings") if is_inside_tree() else null
	if settings_node and "camera_sensitivity" in settings_node:
		sens_mult = float(settings_node.get("camera_sensitivity"))

	# Mouse wheel zoom & drag (skip touch-emulated mouse so browser/OS touch never double-fires)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.device == InputEvent.DEVICE_ID_EMULATION or (Time.get_ticks_msec() - _last_touch_msec) < TOUCH_MOUSE_GUARD_MSEC:
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			target_distance = clampf(target_distance - zoom_step, min_distance, max_distance)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			target_distance = clampf(target_distance + zoom_step, min_distance, max_distance)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_start_on_ui = is_ui_blocking_point(mb.position)
				_mouse_dragging = not _mouse_start_on_ui
				_mouse_start_pos = mb.position
				_mouse_move_dist = 0.0
			else:
				var dist: float = maxf(_mouse_move_dist, mb.position.distance_to(_mouse_start_pos))
				var was_tap: bool = _mouse_dragging and (not _mouse_start_on_ui) and _touches.is_empty() and dist < EMPTY_TAP_MAX_PX
				_mouse_dragging = false
				_mouse_start_on_ui = false
				_mouse_move_dist = 0.0
				if was_tap:
					_emit_empty_ground_tapped()

	elif event is InputEventMouseMotion and _mouse_dragging and _touches.is_empty():
		var mm := event as InputEventMouseMotion
		if mm.device == InputEvent.DEVICE_ID_EMULATION or (Time.get_ticks_msec() - _last_touch_msec) < TOUCH_MOUSE_GUARD_MSEC:
			_mouse_dragging = false
			return
		_mouse_move_dist = maxf(_mouse_move_dist, mm.position.distance_to(_mouse_start_pos))
		target_yaw -= mm.relative.x * mouse_sensitivity * sens_mult
		var p_min := deg_to_rad(min_pitch_deg)
		var p_max := deg_to_rad(max_pitch_deg)
		target_pitch = clampf(target_pitch - mm.relative.y * mouse_sensitivity * sens_mult, p_min, p_max)

	# Touch input
	elif event is InputEventScreenTouch:
		_last_touch_msec = Time.get_ticks_msec()
		_mouse_dragging = false
		_mouse_start_on_ui = false
		var st := event as InputEventScreenTouch
		if st.pressed:
			var on_ui := is_ui_blocking_point(st.position)
			_touch_start_on_ui[st.index] = on_ui
			_touch_start_pos[st.index] = st.position
			_touch_move_dist[st.index] = 0.0
			if not on_ui:
				_touches[st.index] = st.position
				if _touches.size() >= 2:
					_touch_had_multi = true
		else:
			var was_on_ui := bool(_touch_start_on_ui.get(st.index, false))
			var t_start: Vector2 = _touch_start_pos.get(st.index, st.position)
			var t_dist: float = maxf(float(_touch_move_dist.get(st.index, 0.0)), st.position.distance_to(t_start))
			_touches.erase(st.index)
			_touch_start_on_ui.erase(st.index)
			_touch_start_pos.erase(st.index)
			_touch_move_dist.erase(st.index)
			if not was_on_ui and not _touch_had_multi and _touches.is_empty() and t_dist < EMPTY_TAP_MAX_PX:
				_emit_empty_ground_tapped()
			if _touches.is_empty():
				_touch_had_multi = false

	elif event is InputEventScreenDrag:
		_last_touch_msec = Time.get_ticks_msec()
		_mouse_dragging = false
		var sd := event as InputEventScreenDrag
		if _touch_start_pos.has(sd.index):
			_touch_move_dist[sd.index] = maxf(float(_touch_move_dist.get(sd.index, 0.0)), sd.position.distance_to(_touch_start_pos[sd.index]))
		if _touch_start_on_ui.get(sd.index, false):
			return

		var _prev_pos: Vector2 = _touches.get(sd.index, sd.position - sd.relative)
		_touches[sd.index] = sd.position

		if _touches.size() == 1:
			target_yaw -= sd.relative.x * touch_sensitivity * sens_mult
			var p_min := deg_to_rad(min_pitch_deg)
			var p_max := deg_to_rad(max_pitch_deg)
			target_pitch = clampf(target_pitch - sd.relative.y * touch_sensitivity * sens_mult, p_min, p_max)
		elif _touches.size() >= 2:
			var keys := _touches.keys()
			var idx0: int = keys[0]
			var idx1: int = keys[1]
			var p0: Vector2 = _touches[idx0]
			var p1: Vector2 = _touches[idx1]
			var prev_p0: Vector2 = (p0 - sd.relative) if sd.index == idx0 else p0
			var prev_p1: Vector2 = (p1 - sd.relative) if sd.index == idx1 else p1
			var curr_dist := p0.distance_to(p1)
			var prev_dist := prev_p0.distance_to(prev_p1)
			var diff := curr_dist - prev_dist
			target_distance = clampf(target_distance - diff * pinch_sensitivity, min_distance, max_distance)
