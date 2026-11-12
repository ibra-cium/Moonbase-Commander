class_name KidGaugeGraphic
extends Control

## Lightweight custom-drawn kid UI glyphs (phone battery, 3-shape face, arrows, check/cross)
## avoiding missing Unicode glyphs and emoji fonts on mobile web exports.

var graphic_kind: String = ""
var graphic_color: Color = UIColors.OXYGEN
var battery_fill_ratio: float = 1.0


func configure(kind: String, col: Color, fill_ratio: float = 1.0) -> void:
	graphic_kind = kind
	graphic_color = col
	battery_fill_ratio = clampf(fill_ratio, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if graphic_kind.is_empty():
		return
	var s: Vector2 = size
	if s.x <= 0.0 or s.y <= 0.0:
		return

	match graphic_kind:
		"battery":
			_draw_battery(s)
		"face_good":
			_draw_face(s, "good")
		"face_stuffy":
			_draw_face(s, "stuffy")
		"face_danger":
			_draw_face(s, "danger")
		"arrow_up":
			_draw_arrow(s, true)
		"arrow_down":
			_draw_arrow(s, false)
		"check":
			_draw_check(s)
		"cross":
			_draw_cross(s)


func _draw_battery(s: Vector2) -> void:
	var pad_y: float = 2.0
	var nub_w: float = 2.5
	var body_w: float = maxf(10.0, s.x - nub_w - 2.0)
	var body_h: float = maxf(10.0, s.y - pad_y * 2.0)
	var body := Rect2(Vector2(1.0, pad_y), Vector2(body_w, body_h))

	var bg_col := Color(graphic_color.r, graphic_color.g, graphic_color.b, 0.16)
	draw_rect(body, bg_col, true)

	if battery_fill_ratio > 0.01:
		var inner_w: float = (body_w - 4.0) * battery_fill_ratio
		var fill_rect := Rect2(Vector2(3.0, pad_y + 2.0), Vector2(inner_w, body_h - 4.0))
		var fill_col := Color(graphic_color.r, graphic_color.g, graphic_color.b, 0.42)
		draw_rect(fill_rect, fill_col, true)

	draw_rect(body, graphic_color, false, 1.8)
	var nub_h: float = clampf(body_h * 0.45, 4.0, 8.0)
	var nub_rect := Rect2(
		Vector2(body.end.x, pad_y + (body_h - nub_h) * 0.5),
		Vector2(nub_w, nub_h)
	)
	draw_rect(nub_rect, graphic_color, true)


func _draw_face(s: Vector2, mood: String) -> void:
	var center := s * 0.5
	var r: float = minf(s.x, s.y) * 0.44
	var bg_col := Color(graphic_color.r, graphic_color.g, graphic_color.b, 0.22)
	draw_circle(center, r, bg_col)
	draw_arc(center, r, 0.0, TAU, 28, graphic_color, 1.8, true)

	var eye_dx: float = r * 0.36
	var eye_y: float = center.y - r * 0.20
	var left_eye := Vector2(center.x - eye_dx, eye_y)
	var right_eye := Vector2(center.x + eye_dx, eye_y)

	if mood == "danger":
		var xr: float = maxf(1.4, r * 0.16)
		draw_line(left_eye + Vector2(-xr, -xr), left_eye + Vector2(xr, xr), graphic_color, 1.6, true)
		draw_line(left_eye + Vector2(-xr, xr), left_eye + Vector2(xr, -xr), graphic_color, 1.6, true)
		draw_line(right_eye + Vector2(-xr, -xr), right_eye + Vector2(xr, xr), graphic_color, 1.6, true)
		draw_line(right_eye + Vector2(-xr, xr), right_eye + Vector2(xr, -xr), graphic_color, 1.6, true)
		var frown_center := Vector2(center.x, center.y + r * 0.48)
		draw_arc(frown_center, r * 0.36, 1.15 * PI, 1.85 * PI, 14, graphic_color, 1.7, true)
	elif mood == "stuffy":
		draw_circle(left_eye, maxf(1.2, r * 0.14), graphic_color)
		draw_circle(right_eye, maxf(1.2, r * 0.14), graphic_color)
		var y_mouth: float = center.y + r * 0.30
		var mx: float = r * 0.40
		draw_line(Vector2(center.x - mx, y_mouth), Vector2(center.x + mx, y_mouth), graphic_color, 1.8, true)
	else:
		draw_circle(left_eye, maxf(1.2, r * 0.14), graphic_color)
		draw_circle(right_eye, maxf(1.2, r * 0.14), graphic_color)
		var smile_center := Vector2(center.x, center.y + r * 0.05)
		draw_arc(smile_center, r * 0.44, 0.2 * PI, 0.8 * PI, 16, graphic_color, 1.8, true)


func _draw_arrow(s: Vector2, up: bool) -> void:
	var pad_x: float = 1.5
	var pad_y: float = 2.0
	var pts: PackedVector2Array
	if up:
		pts = PackedVector2Array([
			Vector2(s.x * 0.5, pad_y),
			Vector2(s.x - pad_x, s.y - pad_y),
			Vector2(pad_x, s.y - pad_y),
		])
	else:
		pts = PackedVector2Array([
			Vector2(pad_x, pad_y),
			Vector2(s.x - pad_x, pad_y),
			Vector2(s.x * 0.5, s.y - pad_y),
		])
	draw_colored_polygon(pts, graphic_color)


func _draw_check(s: Vector2) -> void:
	var p1 := Vector2(s.x * 0.16, s.y * 0.54)
	var p2 := Vector2(s.x * 0.42, s.y * 0.80)
	var p3 := Vector2(s.x * 0.86, s.y * 0.22)
	draw_line(p1, p2, graphic_color, 2.0, true)
	draw_line(p2, p3, graphic_color, 2.0, true)


func _draw_cross(s: Vector2) -> void:
	var m: float = minf(s.x, s.y) * 0.22
	draw_line(Vector2(m, m), Vector2(s.x - m, s.y - m), graphic_color, 2.0, true)
	draw_line(Vector2(s.x - m, m), Vector2(m, s.y - m), graphic_color, 2.0, true)

