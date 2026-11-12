extends SceneTree

func _init() -> void:
	print("Building Theme.tres...")
	var theme: Theme = Theme.new()

	# Fonts
	var base_regular: FontFile = load("res://assets/fonts/NotoSans-Regular.ttf") as FontFile
	var fallback_regular: FontFile = load("res://assets/fonts/NotoSansBengali-Regular.ttf") as FontFile
	var font_regular: FontVariation = FontVariation.new()
	font_regular.base_font = base_regular
	font_regular.fallbacks = [fallback_regular]

	var base_bold: FontFile = load("res://assets/fonts/NotoSans-Bold.ttf") as FontFile
	var fallback_bold: FontFile = load("res://assets/fonts/NotoSansBengali-Bold.ttf") as FontFile
	var font_bold: FontVariation = FontVariation.new()
	font_bold.base_font = base_bold
	font_bold.fallbacks = [fallback_bold]

	theme.default_font = font_regular
	theme.default_font_size = 22

	var color_panel_bg: Color = Color("141821e0")
	var color_panel_border: Color = Color("2a3245")
	var color_text: Color = Color("F3F4F6")
	var color_muted: Color = Color("9AA3B2")
	var color_btn_normal: Color = Color("1e2433")
	var color_btn_hover: Color = Color("2c354b")
	var color_btn_pressed: Color = Color("161b26")
	var color_btn_disabled: Color = Color("12151ea0")
	var color_btn_border: Color = Color("3d4861")
	var color_accent: Color = Color("3D8BD9")

	# Panel & PanelContainer
	var style_panel: StyleBoxFlat = StyleBoxFlat.new()
	style_panel.bg_color = color_panel_bg
	style_panel.set_corner_radius_all(8)
	style_panel.set_border_width_all(1)
	style_panel.border_color = color_panel_border
	style_panel.set_content_margin_all(14.0)

	theme.set_stylebox("panel", "Panel", style_panel)
	theme.set_stylebox("panel", "PanelContainer", style_panel)

	# Label
	theme.set_color("font_color", "Label", color_text)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.4))
	theme.set_font("font", "Label", font_regular)
	theme.set_font_size("font_size", "Label", 22)

	# Buttons - min height 64px for touch targets
	var btn_normal: StyleBoxFlat = _create_btn_style(color_btn_normal, color_btn_border)
	var btn_hover: StyleBoxFlat = _create_btn_style(color_btn_hover, color_accent)
	var btn_pressed: StyleBoxFlat = _create_btn_style(color_btn_pressed, color_accent)
	var btn_disabled: StyleBoxFlat = _create_btn_style(color_btn_disabled, Color("202530"))
	var btn_focus: StyleBoxFlat = StyleBoxFlat.new()
	btn_focus.draw_center = false
	btn_focus.set_corner_radius_all(8)
	btn_focus.set_border_width_all(2)
	btn_focus.border_color = color_accent

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", btn_focus)

	theme.set_color("font_color", "Button", color_text)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color("E9E7E2"))
	theme.set_color("font_disabled_color", "Button", color_muted)
	theme.set_font("font", "Button", font_bold)
	theme.set_font_size("font_size", "Button", 22)

	# ProgressBar
	var pb_bg: StyleBoxFlat = StyleBoxFlat.new()
	pb_bg.bg_color = Color("141821")
	pb_bg.set_corner_radius_all(4)
	pb_bg.content_margin_top = 4.0
	pb_bg.content_margin_bottom = 4.0

	var pb_fill: StyleBoxFlat = StyleBoxFlat.new()
	pb_fill.bg_color = color_accent
	pb_fill.set_corner_radius_all(4)

	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)
	theme.set_font_size("font_size", "ProgressBar", 18)

	# PopupPanel
	theme.set_stylebox("panel", "PopupPanel", style_panel)

	# Save font resources separately so they can also be referenced if needed
	var err_reg: Error = ResourceSaver.save(font_regular, "res://ui/font_regular.tres")
	if err_reg != OK:
		push_error("Failed to save font_regular.tres: %d" % err_reg)
		quit(1)
		return

	var err_bold: Error = ResourceSaver.save(font_bold, "res://ui/font_bold.tres")
	if err_bold != OK:
		push_error("Failed to save font_bold.tres: %d" % err_bold)
		quit(1)
		return

	var err_theme: Error = ResourceSaver.save(theme, "res://ui/Theme.tres")
	if err_theme != OK:
		push_error("Failed to save Theme.tres: %d" % err_theme)
		quit(1)
		return

	print("Successfully generated res://ui/Theme.tres, font_regular.tres, and font_bold.tres!")
	quit(0)

func _create_btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.content_margin_top = 16.0
	sb.content_margin_bottom = 16.0
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	return sb
