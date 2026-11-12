extends "res://tests/test_case.gd"

const TitleScreenScene: PackedScene = preload("res://ui/TitleScreen.tscn")

func test_title_screen_instantiation_and_nodes() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var title: TitleScreen = TitleScreenScene.instantiate() as TitleScreen
	root.add_child(title)
	title._ready()

	assert_true(title != null, "TitleScreen must instantiate")
	assert_true(title.moon != null, "Moon MeshInstance3D must exist")
	assert_true(title.earth != null, "Earth MeshInstance3D must exist")
	assert_true(title.stars != null, "Stars MultiMeshInstance3D must exist")
	assert_true(title.camera != null, "Camera3D must exist")
	assert_true(title.start_button != null, "Start button must exist")
	assert_true(title.lang_button != null, "Language button must exist")
	assert_true(title.sources_button != null, "Sources button must exist")
	assert_true(title.credit_label != null, "Credit label must exist")

	# Check minimum touch target size 64px for buttons
	assert_true(title.start_button.custom_minimum_size.y >= 64.0, "Start button must be at least 64px tall")
	assert_true(title.lang_button.custom_minimum_size.y >= 64.0, "Lang button must be at least 64px tall")
	assert_true(title.sources_button.custom_minimum_size.y >= 64.0, "Sources button must be at least 64px tall")

	# Check credit text references NASA
	assert_true(title.credit_label.text.contains("NASA"), "Credit text must mention NASA")

	root.remove_child(title)
	title.free()

func test_title_screen_language_toggle() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var title: TitleScreen = TitleScreenScene.instantiate() as TitleScreen
	root.add_child(title)
	title._ready()

	Settings.language = "en"
	title._update_texts()
	assert_eq(title.start_button.text, "Start", "Start button text in EN should be 'Start'")
	assert_eq(title.lang_button.text, "বাংলা", "Lang button in EN should offer 'বাংলা'")

	# Toggle to Bangla
	title._on_lang_pressed()
	assert_eq(Settings.language, "bn", "Language should be switched to 'bn'")
	assert_eq(title.start_button.text, "শুরু", "Start button text in BN should be 'শুরু'")
	assert_eq(title.lang_button.text, "English", "Lang button in BN should offer 'English'")

	# Toggle back to English
	title._on_lang_pressed()
	assert_eq(Settings.language, "en", "Language should be back to 'en'")
	assert_eq(title.start_button.text, "Start", "Start button text in EN should be 'Start'")

	root.remove_child(title)
	title.free()

func test_title_screen_sources_signal() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var title: TitleScreen = TitleScreenScene.instantiate() as TitleScreen
	root.add_child(title)
	title._ready()

	var sources_emitted := [false]
	title.sources_pressed.connect(func(): sources_emitted[0] = true)
	title._on_sources_pressed()
	assert_true(sources_emitted[0], "Sources button press must emit sources_pressed")

	root.remove_child(title)
	title.free()

func test_title_screen_start_signal() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	var title: TitleScreen = TitleScreenScene.instantiate() as TitleScreen
	root.add_child(title)
	title._ready()

	var start_finished := [false]
	title.start_completed.connect(func(): start_finished[0] = true)
	title._on_dive_finished()
	assert_true(start_finished[0], "Dive finish must emit start_completed")

	root.remove_child(title)
	title.free()
