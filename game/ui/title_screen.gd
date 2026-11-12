class_name TitleScreen
extends Control

signal start_completed
signal sources_pressed

const LROC_TEX: Texture2D = preload("res://assets/textures/nasa/lroc_color_2k.jpg")
const LDEM_TEX: Texture2D = preload("res://assets/textures/nasa/ldem_3_8bit.jpg")
const EARTH_TEX: Texture2D = preload("res://assets/textures/nasa/earth_bluemarble_jan_1024.jpg")
const ICON_VOLUME_UP: Texture2D = preload("res://assets/icons/volume_up.svg")
const ICON_VOLUME_OFF: Texture2D = preload("res://assets/icons/volume_off.svg")

const MOON_ROT_SPEED: float = 0.04
const EARTH_ROT_SPEED: float = 0.015
const SafeArea := preload("res://ui/safe_area.gd")

var viewport: SubViewport
var camera: Camera3D
var moon: MeshInstance3D
var earth: MeshInstance3D
var stars: MultiMeshInstance3D

var ui_overlay: Control
var title_label: Label
var subtitle_label: Label
var start_button: Button
var lang_button: Button
var sources_button: Button
var mute_button: Button
var credit_label: Label
var fade_rect: ColorRect

var _cam_initial_pos: Vector3 = Vector3(0.0, 0.0, 5.0)
var _cam_initial_fov: float = 42.0
var _is_starting: bool = false
var _stars_initialized: bool = false

func _ensure_nodes() -> void:
	if start_button != null:
		return
	viewport = get_node_or_null("ViewportContainer/SubViewport")
	camera = get_node_or_null("ViewportContainer/SubViewport/Camera3D")
	moon = get_node_or_null("ViewportContainer/SubViewport/Moon")
	earth = get_node_or_null("ViewportContainer/SubViewport/Earth")
	stars = get_node_or_null("ViewportContainer/SubViewport/Stars")

	ui_overlay = get_node_or_null("UIOverlay")
	title_label = get_node_or_null("UIOverlay/Margin/VBox/TopSection/TitleLabel")
	subtitle_label = get_node_or_null("UIOverlay/Margin/VBox/TopSection/SubtitleLabel")
	start_button = get_node_or_null("UIOverlay/Margin/VBox/BottomSection/ButtonsVBox/StartButton")
	lang_button = get_node_or_null("UIOverlay/Margin/VBox/BottomSection/ButtonsVBox/SecondaryHBox/LangButton")
	sources_button = get_node_or_null("UIOverlay/Margin/VBox/BottomSection/ButtonsVBox/SecondaryHBox/SourcesButton")
	mute_button = get_node_or_null("UIOverlay/TopRightMargin/MuteButton")
	credit_label = get_node_or_null("UIOverlay/Margin/VBox/BottomSection/CreditLabel")
	fade_rect = get_node_or_null("FadeRect")

func _ready() -> void:
	_ensure_nodes()
	_setup_materials()
	_init_stars()

	if start_button and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if lang_button and not lang_button.pressed.is_connected(_on_lang_pressed):
		lang_button.pressed.connect(_on_lang_pressed)
	if sources_button and not sources_button.pressed.is_connected(_on_sources_pressed):
		sources_button.pressed.connect(_on_sources_pressed)
	if mute_button and not mute_button.pressed.is_connected(_on_mute_pressed):
		mute_button.pressed.connect(_on_mute_pressed)

	if Settings != null and Settings.has_signal("language_changed"):
		if not Settings.language_changed.is_connected(_on_language_changed):
			Settings.language_changed.connect(_on_language_changed)
	if Settings != null and Settings.has_signal("sound_changed"):
		if not Settings.sound_changed.is_connected(_on_sound_changed):
			Settings.sound_changed.connect(_on_sound_changed)

	reset()
	_update_texts()
	_update_mute_button()
	_apply_safe_area()
	SafeArea.connect_resize(self, _apply_safe_area)

func _apply_safe_area() -> void:
	var insets: Dictionary = SafeArea.get_insets(self)
	var main_margin := get_node_or_null("UIOverlay/Margin") as MarginContainer
	if main_margin != null:
		SafeArea.apply_margin(main_margin, 32, 28, 32, 20, insets)
	var top_right_margin := get_node_or_null("UIOverlay/TopRightMargin") as MarginContainer
	if top_right_margin != null:
		var r: int = int(insets.get("right", 0))
		var t: int = int(insets.get("top", 0))
		top_right_margin.offset_left = -88.0 - float(r)
		top_right_margin.offset_bottom = 88.0 + float(t)
		SafeArea.apply_margin(top_right_margin, 0, 24, 24, 0, {"left": 0, "top": t, "right": r, "bottom": 0})

func _process(delta: float) -> void:
	if moon:
		moon.rotate_y(delta * MOON_ROT_SPEED)
	if earth:
		earth.rotate_y(delta * EARTH_ROT_SPEED)

func reset() -> void:
	_ensure_nodes()
	_is_starting = false
	if camera:
		camera.position = _cam_initial_pos
		camera.fov = _cam_initial_fov
	if ui_overlay:
		ui_overlay.modulate.a = 1.0
	if fade_rect:
		fade_rect.color.a = 0.0
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if start_button:
		start_button.disabled = false
	if lang_button:
		lang_button.disabled = false
	if sources_button:
		sources_button.disabled = false
	if mute_button:
		mute_button.disabled = false
	_update_texts()
	_update_mute_button()

func _setup_materials() -> void:
	_ensure_nodes()
	if moon:
		var moon_mat := StandardMaterial3D.new()
		moon_mat.albedo_texture = LROC_TEX
		moon_mat.normal_enabled = true
		moon_mat.normal_texture = LDEM_TEX
		moon_mat.normal_scale = 1.2
		moon_mat.roughness = 0.95
		moon_mat.metallic = 0.0
		moon.material_override = moon_mat

	if earth:
		var earth_mat := StandardMaterial3D.new()
		earth_mat.albedo_texture = EARTH_TEX
		earth_mat.roughness = 0.8
		earth_mat.emission_enabled = true
		earth_mat.emission = Color(0.12, 0.18, 0.25, 1.0)
		earth_mat.emission_energy_multiplier = 0.25
		earth.material_override = earth_mat

func _init_stars() -> void:
	_ensure_nodes()
	if not stars or _stars_initialized:
		return
	_stars_initialized = true
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
	quad.material = mat
	mm.mesh = quad

	var count := 350
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261022

	for i in count:
		var u := rng.randf_range(-1.0, 1.0)
		var theta := rng.randf_range(0.0, TAU)
		var phi := acos(u)
		var r := rng.randf_range(25.0, 45.0)
		var pos := Vector3(
			r * sin(phi) * cos(theta),
			r * sin(phi) * sin(theta),
			r * cos(phi)
		)
		var star_scale := rng.randf_range(0.35, 1.25)
		var t := Transform3D(Basis().scaled(Vector3.ONE * star_scale), pos)
		mm.set_instance_transform(i, t)

	stars.multimesh = mm
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _update_texts() -> void:
	_ensure_nodes()
	if title_label:
		title_label.text = tr("GAME_TITLE")
	if subtitle_label:
		subtitle_label.text = tr("TITLE_SUBTITLE_TRAINING")
	if start_button:
		start_button.text = tr("TITLE_START")
	if sources_button:
		sources_button.text = tr("TITLE_SOURCES")
	if credit_label:
		credit_label.text = tr("TITLE_CREDIT_MOON")
	if lang_button:
		var current_lang: String = "en"
		if Settings != null:
			current_lang = Settings.language
		if current_lang == "bn":
			lang_button.text = "English"
		else:
			lang_button.text = "বাংলা"

func _on_lang_pressed() -> void:
	if Audio != null:
		Audio.unlock()
		Audio.play("ui_switch")
	if Settings != null:
		if Settings.language == "en":
			Settings.language = "bn"
		else:
			Settings.language = "en"
	_update_texts()

func _on_sources_pressed() -> void:
	if _is_starting:
		return
	if Audio != null:
		Audio.unlock()
		Audio.play("ui_click")
	sources_pressed.emit()

func _on_mute_pressed() -> void:
	if Audio != null:
		Audio.unlock()
	if Settings != null:
		Settings.sound_on = not Settings.sound_on
	if Audio != null and Settings != null and Settings.sound_on:
		Audio.play("ui_switch")
	_update_mute_button()

func _on_sound_changed(_enabled: bool) -> void:
	_update_mute_button()

func _update_mute_button() -> void:
	_ensure_nodes()
	if mute_button == null:
		return
	var is_on: bool = Settings.sound_on if Settings != null else true
	mute_button.icon = ICON_VOLUME_UP if is_on else ICON_VOLUME_OFF
	mute_button.modulate = Color.WHITE if is_on else Color(0.85, 0.45, 0.45, 1.0)
	mute_button.tooltip_text = tr("HUD_SOUND_ON") if is_on else tr("HUD_SOUND_OFF")

func _on_start_pressed() -> void:
	if _is_starting:
		return
	if Audio != null:
		Audio.unlock()
		Audio.play("ui_confirm")
	_is_starting = true
	_ensure_nodes()

	if start_button:
		start_button.disabled = true
	if lang_button:
		lang_button.disabled = true
	if sources_button:
		sources_button.disabled = true
	if mute_button:
		mute_button.disabled = true

	# Fade out UI overlay
	if ui_overlay:
		var ui_tween := create_tween()
		ui_tween.tween_property(ui_overlay, "modulate:a", 0.0, 0.4)

	# Camera dive towards Moon surface
	var target_cam_pos: Vector3 = moon.position + Vector3(0.0, 0.0, 1.75) if moon else Vector3(0.0, 0.0, 1.75)
	if camera:
		var dive_tween := create_tween()
		dive_tween.set_parallel(true)
		dive_tween.set_trans(Tween.TRANS_QUAD)
		dive_tween.set_ease(Tween.EASE_IN)
		dive_tween.tween_property(camera, "position", target_cam_pos, 1.2)
		dive_tween.tween_property(camera, "fov", 62.0, 1.2)

	# Fade to black in final 0.35s
	if fade_rect:
		var fade_tween := create_tween()
		fade_tween.tween_interval(0.85)
		fade_tween.tween_property(fade_rect, "color:a", 1.0, 0.35)
		fade_tween.finished.connect(_on_dive_finished)
	else:
		_on_dive_finished()

func _on_dive_finished() -> void:
	start_completed.emit()

func _on_language_changed(_lang: String) -> void:
	_update_texts()
