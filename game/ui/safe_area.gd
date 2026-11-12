class_name UiSafeArea
extends RefCounted

## Computes logical-canvas safe-area insets from OS display safe area and Web CSS env().
## Desktop viewports without hardware cutouts return zero insets so 1280x720 layout stays unchanged.

const MOBILE_MIN_SIDE_PX: int = 24
const MOBILE_MIN_BOTTOM_PX: int = 8
const MAX_INSET_PX: int = 96


static func is_touch_or_mobile() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		var coarse: Variant = JavaScriptBridge.eval(
			"(typeof window !== 'undefined' && window.matchMedia) ? window.matchMedia('(pointer: coarse)').matches : false"
		)
		if coarse is bool and bool(coarse):
			return true
	return false


static func read_web_css_insets() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var raw: Variant = JavaScriptBridge.eval(
		"(typeof window !== 'undefined' && window.__moonbaseSafeInsets) ? JSON.stringify(window.__moonbaseSafeInsets) : ''"
	)
	if typeof(raw) != TYPE_STRING or String(raw).is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(String(raw))
	return parsed as Dictionary if parsed is Dictionary else {}


static func compute_insets_from_rects(
	safe_px: Rect2i,
	win_px: Vector2i,
	canvas_size: Vector2,
	web_css: Dictionary,
	touch_mobile: bool
) -> Dictionary:
	var left: float = 0.0
	var top: float = 0.0
	var right: float = 0.0
	var bottom: float = 0.0

	if win_px.x > 0 and win_px.y > 0 and safe_px.size.x > 0 and safe_px.size.y > 0 and canvas_size.x > 0.0 and canvas_size.y > 0.0:
		var sx: float = canvas_size.x / float(win_px.x)
		var sy: float = canvas_size.y / float(win_px.y)
		left = maxf(left, float(maxi(0, safe_px.position.x)) * sx)
		top = maxf(top, float(maxi(0, safe_px.position.y)) * sy)
		right = maxf(right, float(maxi(0, win_px.x - safe_px.end.x)) * sx)
		bottom = maxf(bottom, float(maxi(0, win_px.y - safe_px.end.y)) * sy)

	if not web_css.is_empty() and canvas_size.x > 0.0 and canvas_size.y > 0.0:
		var vw: float = float(web_css.get("vw", 0.0))
		var vh: float = float(web_css.get("vh", 0.0))
		if vw > 0.0 and vh > 0.0:
			var wsx: float = canvas_size.x / vw
			var wsy: float = canvas_size.y / vh
			left = maxf(left, float(web_css.get("left", 0.0)) * wsx)
			top = maxf(top, float(web_css.get("top", 0.0)) * wsy)
			right = maxf(right, float(web_css.get("right", 0.0)) * wsx)
			bottom = maxf(bottom, float(web_css.get("bottom", 0.0)) * wsy)

	if touch_mobile:
		left = maxf(left, float(MOBILE_MIN_SIDE_PX))
		right = maxf(right, float(MOBILE_MIN_SIDE_PX))
		bottom = maxf(bottom, float(MOBILE_MIN_BOTTOM_PX))

	return {
		"left": clampi(int(round(left)), 0, MAX_INSET_PX),
		"top": clampi(int(round(top)), 0, MAX_INSET_PX),
		"right": clampi(int(round(right)), 0, MAX_INSET_PX),
		"bottom": clampi(int(round(bottom)), 0, MAX_INSET_PX),
	}


static func get_insets(node: Node, force_mobile: bool = false) -> Dictionary:
	var vp: Viewport = node.get_viewport() if node != null and node.is_inside_tree() else null
	var canvas_size: Vector2 = vp.get_visible_rect().size if vp != null else Vector2(1280.0, 720.0)
	var win_px: Vector2i = DisplayServer.window_get_size()
	var safe_px: Rect2i = DisplayServer.get_display_safe_area()
	var web_css: Dictionary = read_web_css_insets()
	return compute_insets_from_rects(safe_px, win_px, canvas_size, web_css, force_mobile or is_touch_or_mobile())


static func apply_margin(
	margin: MarginContainer,
	base_left: int,
	base_top: int,
	base_right: int,
	base_bottom: int,
	insets: Dictionary
) -> void:
	if margin == null:
		return
	margin.add_theme_constant_override("margin_left", base_left + int(insets.get("left", 0)))
	margin.add_theme_constant_override("margin_top", base_top + int(insets.get("top", 0)))
	margin.add_theme_constant_override("margin_right", base_right + int(insets.get("right", 0)))
	margin.add_theme_constant_override("margin_bottom", base_bottom + int(insets.get("bottom", 0)))


static func connect_resize(ctrl: Control, callback: Callable) -> void:
	if ctrl == null:
		return
	if not ctrl.resized.is_connected(callback):
		ctrl.resized.connect(callback)
	var vp: Viewport = ctrl.get_viewport() if ctrl.is_inside_tree() else null
	if vp != null and not vp.size_changed.is_connected(callback):
		vp.size_changed.connect(callback)
