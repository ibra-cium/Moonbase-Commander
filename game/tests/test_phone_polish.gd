extends "res://tests/test_case.gd"

const CameraRigScene: PackedScene = preload("res://world/CameraRig.tscn")
const DayHudScene: PackedScene = preload("res://ui/DayHud.tscn")
const TitleScreenScene: PackedScene = preload("res://ui/TitleScreen.tscn")
const PackScreenScene: PackedScene = preload("res://ui/PackScreen.tscn")
const SourcesScreenScene: PackedScene = preload("res://ui/SourcesScreen.tscn")
const MissionMapScene: PackedScene = preload("res://ui/MissionMap.tscn")
const DebriefScreenScene: PackedScene = preload("res://ui/DebriefScreen.tscn")
const EndingOverlayScene: PackedScene = preload("res://ui/EndingOverlay.tscn")
const SafeArea := preload("res://ui/safe_area.gd")


func test_camera_ignores_emulated_mouse_and_hidden_world() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var world_holder := Node3D.new()
	var cam := CameraRigScene.instantiate()
	world_holder.add_child(cam)
	root.add_child(world_holder)
	cam._ready()

	# Hidden parent blocks orbit
	world_holder.visible = false
	var yaw0: float = cam.target_yaw
	var st_down := InputEventScreenTouch.new()
	st_down.index = 0
	st_down.pressed = true
	st_down.position = Vector2(500, 350)
	cam._unhandled_input(st_down)
	var st_drag := InputEventScreenDrag.new()
	st_drag.index = 0
	st_drag.position = Vector2(560, 350)
	st_drag.relative = Vector2(60, 0)
	cam._unhandled_input(st_drag)
	assert_near(cam.target_yaw, yaw0, 0.0001, "Hidden World ignores touch orbit")

	# Emulated mouse (device == -1) ignored while visible
	world_holder.visible = true
	var mb_emu := InputEventMouseButton.new()
	mb_emu.button_index = MOUSE_BUTTON_LEFT
	mb_emu.pressed = true
	mb_emu.position = Vector2(500, 350)
	mb_emu.device = InputEvent.DEVICE_ID_EMULATION
	cam._unhandled_input(mb_emu)
	var mm_emu := InputEventMouseMotion.new()
	mm_emu.position = Vector2(580, 350)
	mm_emu.relative = Vector2(80, 0)
	mm_emu.device = InputEvent.DEVICE_ID_EMULATION
	cam._unhandled_input(mm_emu)
	assert_near(cam.target_yaw, yaw0, 0.0001, "Touch-emulated mouse motion does not orbit")

	world_holder.free()


func test_camera_blocks_hud_pills_gaps_and_button_slop() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var cam := CameraRigScene.instantiate()
	var hud: DayHud = DayHudScene.instantiate() as DayHud
	root.add_child(cam)
	root.add_child(hud)
	cam._ready()
	hud._ready()

	# ResourceBar pills block camera
	var energy_pill := hud.get_node("TopBar/HBox/ResourceBar/EnergyPill") as Control
	energy_pill.position = Vector2(520, 14)
	energy_pill.size = Vector2(120, 44)
	var pill_rect := energy_pill.get_global_rect()
	assert_true(cam.is_ui_blocking_point(pill_rect.get_center()), "EnergyPill stops touch orbit")

	# Point 4px outside EndDayButton is shielded by BUTTON_TOUCH_GUARD_PX (8px)
	var end_btn := hud.end_day_button
	end_btn.size = Vector2(210, 64)
	var end_rect := end_btn.get_global_rect()
	var near_edge := Vector2(end_rect.position.x - 4.0, end_rect.position.y + end_rect.size.y * 0.5)
	assert_true(cam.is_ui_blocking_point(near_edge), "8px touch slop near EndDayButton blocks orbit")

	var empty_taps := [0]
	cam.empty_ground_tapped.connect(func(): empty_taps[0] += 1)
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = near_edge
	cam._unhandled_input(down)
	var yaw_before: float = cam.target_yaw
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = near_edge + Vector2(30, 0)
	drag.relative = Vector2(30, 0)
	cam._unhandled_input(drag)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = near_edge + Vector2(30, 0)
	cam._unhandled_input(up)
	assert_near(cam.target_yaw, yaw_before, 0.0001, "Near-button slop drag does not orbit camera")
	assert_eq(empty_taps[0], 0, "Near-button slop tap does not trigger empty_ground_tapped")

	# BottomBar/HBox gap between crew cards and LeftColumn/Gauges gap block orbit
	var card_hbox := hud.get_node("BottomBar/HBox") as Control
	card_hbox.size = Vector2(760, 96)
	var hbox_rect := card_hbox.get_global_rect()
	assert_true(cam.is_ui_blocking_point(hbox_rect.get_center()), "BottomBar HBox gap blocks orbit")
	var gauges := hud.get_node("LeftColumn/Gauges") as Control
	gauges.size = Vector2(252, 360)
	var gauges_rect := gauges.get_global_rect()
	assert_true(cam.is_ui_blocking_point(gauges_rect.get_center()), "LeftColumn Gauges container blocks orbit")

	# Open 3D ground remains unobstructed
	assert_false(cam.is_ui_blocking_point(Vector2(640, 340)), "Open sky/ground center remains orbitable")

	hud.free()
	cam.free()


func test_safe_area_desktop_zero_and_mobile_insets() -> void:
	var desktop := SafeArea.compute_insets_from_rects(
		Rect2i(0, 0, 1280, 720),
		Vector2i(1280, 720),
		Vector2(1280.0, 720.0),
		{},
		false
	)
	assert_eq(int(desktop["left"]), 0, "Desktop left safe inset is 0")
	assert_eq(int(desktop["top"]), 0, "Desktop top safe inset is 0")
	assert_eq(int(desktop["right"]), 0, "Desktop right safe inset is 0")
	assert_eq(int(desktop["bottom"]), 0, "Desktop bottom safe inset is 0")

	var mobile_fallback := SafeArea.compute_insets_from_rects(
		Rect2i(0, 0, 800, 360),
		Vector2i(800, 360),
		Vector2(1600.0, 720.0),
		{"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0, "vw": 800.0, "vh": 360.0},
		true
	)
	assert_true(int(mobile_fallback["left"]) >= SafeArea.MOBILE_MIN_SIDE_PX, "Mobile enforces side margin for rounded corners")
	assert_true(int(mobile_fallback["right"]) >= SafeArea.MOBILE_MIN_SIDE_PX, "Mobile enforces right margin for rounded corners")
	assert_true(int(mobile_fallback["bottom"]) >= SafeArea.MOBILE_MIN_BOTTOM_PX, "Mobile enforces bottom gesture clearance")

	var mobile_notch := SafeArea.compute_insets_from_rects(
		Rect2i(0, 0, 800, 360),
		Vector2i(800, 360),
		Vector2(1600.0, 720.0),
		{"left": 44.0, "top": 0.0, "right": 12.0, "bottom": 21.0, "vw": 800.0, "vh": 360.0},
		true
	)
	assert_eq(int(mobile_notch["left"]), 88, "Web CSS left cutout inset scales to logical canvas")
	assert_eq(int(mobile_notch["bottom"]), 42, "Web CSS bottom inset scales to logical canvas")

	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var scenes: Array[PackedScene] = [DayHudScene, TitleScreenScene, PackScreenScene, SourcesScreenScene, MissionMapScene, DebriefScreenScene, EndingOverlayScene]
	for scn in scenes:
		var inst: Node = scn.instantiate()
		root.add_child(inst)
		assert_eq(inst.get_parent(), root, "UI scene with SafeArea mounts cleanly: %s" % scn.resource_path)
		inst.free()


func test_web_shell_and_export_preset_configured() -> void:
	assert_true(FileAccess.file_exists("res://web/shell.html"), "Custom web shell.html exists")
	var html := FileAccess.get_file_as_string("res://web/shell.html")
	assert_true(html.contains("MOONBASE COMMANDER"), "Loading shell displays game title")
	assert_true(html.contains("viewport-fit=cover"), "Shell enables safe-area viewport-fit=cover")
	assert_true(html.contains("$GODOT_URL"), "Shell keeps $GODOT_URL for export_web.ps1 patching")
	assert_true(html.contains("Engine.getMissingFeatures"), "Shell keeps Engine.getMissingFeatures check")
	assert_true(html.contains("window.__moonbaseSafeInsets"), "Shell exposes CSS safe-area insets to Godot")
	assert_true(html.contains("rotate-hint") and html.contains("Rotate your phone to landscape"), "Shell includes portrait rotate-to-landscape hint")

	assert_true(FileAccess.file_exists("res://export_presets.cfg"), "export_presets.cfg exists")
	var cfg := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert_true(cfg.contains('html/custom_html_shell="res://web/shell.html"'), "Web preset points to custom shell")
	assert_true(cfg.contains("assets/nasa3d/*") and cfg.contains("assets/ui/*"), "Unused nasa3d and ui packs excluded from web pck")
	for used_particle in ["dirt_01.png", "dirt_02.png", "flame_01.png", "flare_01.png", "scorch_01.png", "scratch_01.png", "smoke_01.png", "spark_01.png", "star_01.png", "trace_01.png"]:
		assert_false(cfg.contains(used_particle), "Active particle %s is not listed in exclude_filter" % used_particle)

