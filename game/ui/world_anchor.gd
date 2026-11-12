class_name WorldAnchor
extends Control

## Control that tracks a 3D world point (or Node3D) every frame via Camera3D.
## Hides itself when the point is behind the camera or off screen.

@export var world_point: Vector3 = Vector3.ZERO
@export var world_offset: Vector3 = Vector3.ZERO
@export var screen_offset: Vector2 = Vector2.ZERO
@export var center_on_anchor: bool = true
@export var edge_padding: float = 0.0

var target_node: Node3D = null
var camera_override: Camera3D = null
var tracking_enabled: bool = true

const DEFAULT_VIEWPORT_SIZE := Vector2(1280.0, 720.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if not tracking_enabled:
		return
	update_position()


func set_anchor_point(point: Vector3) -> void:
	target_node = null
	world_point = point
	if tracking_enabled:
		update_position()


func set_anchor_node(node: Node3D, offset: Vector3 = Vector3.ZERO) -> void:
	target_node = node
	world_offset = offset
	if tracking_enabled:
		update_position()


func get_world_point() -> Vector3:
	if target_node != null and is_instance_valid(target_node):
		var base_pos: Vector3 = target_node.global_position if target_node.is_inside_tree() else target_node.position
		return base_pos + world_offset
	return world_point + world_offset


func update_position(cam: Camera3D = null, vp_size_override: Vector2 = Vector2.ZERO) -> bool:
	var active_cam: Camera3D = _resolve_camera(cam)
	if active_cam == null:
		visible = false
		return false

	var point: Vector3 = get_world_point()
	var vp_size: Vector2 = _resolve_viewport_size(vp_size_override)
	var behind: bool = false
	var screen_pos := Vector2.ZERO
	if active_cam.is_inside_tree():
		behind = active_cam.is_position_behind(point)
		if not behind:
			screen_pos = active_cam.unproject_position(point)
	else:
		var projected := _project_from_transform(active_cam, point, vp_size)
		behind = bool(projected.get("behind", true))
		screen_pos = projected.get("pos", Vector2.ZERO)

	if behind or _is_off_screen(screen_pos, vp_size):
		visible = false
		return false

	var box_size: Vector2 = size
	if box_size.x <= 0.0 or box_size.y <= 0.0:
		box_size = get_combined_minimum_size()

	var target_pos: Vector2 = screen_pos + screen_offset
	if center_on_anchor:
		target_pos -= box_size * 0.5
	position = target_pos
	visible = true
	return true


func _resolve_camera(explicit_cam: Camera3D) -> Camera3D:
	if explicit_cam != null and is_instance_valid(explicit_cam):
		return explicit_cam
	if camera_override != null and is_instance_valid(camera_override):
		return camera_override
	if is_inside_tree():
		return get_viewport().get_camera_3d()
	return null


func _resolve_viewport_size(vp_size_override: Vector2) -> Vector2:
	if vp_size_override.x > 0.0 and vp_size_override.y > 0.0:
		return vp_size_override
	if is_inside_tree():
		var rect_size: Vector2 = get_viewport().get_visible_rect().size
		if rect_size.x > 0.0 and rect_size.y > 0.0:
			return rect_size
		var control_vp: Vector2 = get_viewport_rect().size
		if control_vp.x > 0.0 and control_vp.y > 0.0:
			return control_vp
	return DEFAULT_VIEWPORT_SIZE


func _is_off_screen(screen_pos: Vector2, vp_size: Vector2) -> bool:
	return (
		screen_pos.x < -edge_padding
		or screen_pos.y < -edge_padding
		or screen_pos.x > vp_size.x + edge_padding
		or screen_pos.y > vp_size.y + edge_padding
	)


func _project_from_transform(cam: Camera3D, point: Vector3, vp_size: Vector2) -> Dictionary:
	var local_pos: Vector3 = cam.transform.affine_inverse() * point
	if local_pos.z >= 0.0:
		return {"behind": true, "pos": Vector2.ZERO}
	var dist: float = -local_pos.z
	var tan_half: float = tan(deg_to_rad(cam.fov) * 0.5)
	var aspect: float = vp_size.x / maxf(1.0, vp_size.y)
	var ndc_x: float = local_pos.x / (dist * tan_half * aspect)
	var ndc_y: float = -local_pos.y / (dist * tan_half)
	return {
		"behind": false,
		"pos": Vector2((ndc_x * 0.5 + 0.5) * vp_size.x, (ndc_y * 0.5 + 0.5) * vp_size.y),
	}
