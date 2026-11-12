extends "res://tests/test_case.gd"

const LanderScene := preload("res://world/Lander.tscn")
const CrewScene := preload("res://world/Crew.tscn")
const SkyRigScene := preload("res://world/SkyRig.tscn")
const CameraRigScene := preload("res://world/CameraRig.tscn")
const EndingOverlayScene := preload("res://ui/EndingOverlay.tscn")
const MainScene := preload("res://scenes/Main.tscn")

func test_lander_liftoff() -> void:
	var lander = LanderScene.instantiate()
	assert_true(lander != null, "Lander instantiates")
	if lander == null:
		return
	assert_true(lander.has_signal("liftoff_completed"), "Lander has liftoff_completed signal")
	assert_true(lander.has_method("play_liftoff"), "Lander has play_liftoff method")
	assert_true(lander.has_method("is_liftoff"), "Lander has is_liftoff method")

	# Liftoff in fast mode headlessly
	lander.play_liftoff(null, true)
	assert_true(lander.is_liftoff(), "Lander is in liftoff state while thrusting")

	# Reset state
	lander.reset_state()
	assert_false(lander.is_liftoff(), "Lander resets liftoff flag")
	assert_eq(lander.lander_body.position.y, 0.0, "Lander body resets to y=0")
	lander.free()

func test_crew_endings() -> void:
	var crew = CrewScene.instantiate()
	assert_true(crew != null, "Crew instantiates")
	if crew == null:
		return
	assert_true(crew.has_method("celebrate_success"), "Crew has celebrate_success method")
	assert_true(crew.has_method("board_lander"), "Crew has board_lander method")

	# Test celebration: crew gathers outside
	crew.celebrate_success()
	for i in range(crew.get_astronaut_count()):
		var astro = crew.get_astronaut(i)
		assert_true(astro != null and astro.visible, "Celebration astronaut %d is visible" % i)

	# Test boarding lander: crew hidden inside
	crew.board_lander()
	for i in range(crew.get_astronaut_count()):
		var astro = crew.get_astronaut(i)
		assert_false(astro.visible, "Boarded astronaut %d is hidden inside lander" % i)

	# Reset scales
	crew.reset_scales()
	crew.free()

func test_sky_rig_sunrise_glow() -> void:
	var sky = SkyRigScene.instantiate()
	assert_true(sky != null, "SkyRig instantiates")
	if sky == null:
		return
	assert_true(sky.has_method("show_sunrise_glow"), "SkyRig has show_sunrise_glow method")

	sky.show_sunrise_glow(0.0)
	var az = sky.get_sun_azimuth()
	assert_near(az, deg_to_rad(-90.0), 0.01, "Sunrise glow azimuth is at eastern horizon (-90 deg)")
	sky.free()

func test_camera_rig_cutscenes() -> void:
	var cam = CameraRigScene.instantiate()
	assert_true(cam != null, "CameraRig instantiates")
	if cam == null:
		return
	assert_true(cam.has_method("follow_liftoff"), "CameraRig has follow_liftoff method")
	assert_true(cam.has_method("frame_celebration"), "CameraRig has frame_celebration method")
	assert_true(cam.has_method("reset_camera"), "CameraRig has reset_camera method")

	cam.reset_camera(0.0)
	assert_eq(cam.position, Vector3.ZERO, "CameraRig resets position to zero")
	cam.free()

func test_ending_overlay_ui() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var overlay = EndingOverlayScene.instantiate()
	assert_true(overlay != null, "EndingOverlay instantiates")
	if overlay == null:
		return
	root.add_child(overlay)
	overlay._ready()
	assert_true(overlay.has_signal("skip_pressed"), "EndingOverlay has skip_pressed signal")

	# Test setup for success
	overlay.setup(true)
	var title_lbl: Label = overlay.get_node_or_null("TopBanner/Margin/TitleLabel")
	assert_true(title_lbl != null, "TitleLabel found in EndingOverlay")
	assert_false(title_lbl.text.is_empty(), "Success title is populated")

	# Test setup for evacuation
	overlay.setup(false)
	assert_false(title_lbl.text.is_empty(), "Evacuation title is populated")

	# Test skip button press signal
	var skipped := [false]
	overlay.skip_pressed.connect(func(): skipped[0] = true)
	var btn: Button = overlay.get_node_or_null("TopRightMargin/SkipButton")
	assert_true(btn != null, "SkipButton found in EndingOverlay")
	assert_true(btn.custom_minimum_size.y >= 64.0, "SkipButton meets minimum 64 px touch target")
	btn.pressed.emit()
	assert_true(skipped[0], "SkipButton emits skip_pressed signal")

	root.remove_child(overlay)
	overlay.free()

func test_main_ending_state_and_skip() -> void:
	var main = MainScene.instantiate()
	assert_true(main != null, "Main instantiates")
	if main == null:
		return

	assert_true("State" in main, "Main defines State enum")
	assert_true(main.has_method("_state_ending"), "Main defines _state_ending")
	assert_true(main.has_method("_on_ending_skip_pressed"), "Main defines _on_ending_skip_pressed")

	# Verify Main scene has EndingOverlay node
	var overlay = main.get_node_or_null("UI/EndingOverlay")
	assert_true(overlay != null, "Main UI contains EndingOverlay node")

	main.free()
