extends Node3D

signal sun_updated(t: float, azimuth_rad: float, is_day: bool)

const SUN_LOW_DEG := 4.0      # elevation at sunrise and sunset
const SUN_RISE_DEG := 60.0    # extra elevation at midday
const SUN_ENERGY := 1.4

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $SunLight
@onready var sun_glow: Sprite3D = $SunGlow
@onready var stars: MultiMeshInstance3D = $Stars
@onready var earth: MeshInstance3D = $Earth

var current_day: int = 1
var current_frac: float = 0.0
var current_t: float = 0.0
var current_azimuth: float = 0.0
var _day_tween: Tween = null

func _ready() -> void:
	_init_stars()
	_connect_game_state()
	apply_sun(0.0)

func _enter_tree() -> void:
	_connect_game_state()

func _connect_game_state() -> void:
	if not is_inside_tree():
		return
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		if not gs.mission_started.is_connected(_on_mission_started):
			gs.mission_started.connect(_on_mission_started)
		if not gs.day_resolved.is_connected(_on_day_resolved):
			gs.day_resolved.connect(_on_day_resolved)

func _on_mission_started(_mission) -> void:
	set_day(1, 0.0)

func _on_day_resolved(report) -> void:
	var day_num: int = int(report.day if "day" in report else (report.get("day", 1) if report is Dictionary else 1))
	var dur: float = 1.5
	if is_inside_tree():
		var settings = get_node_or_null("/root/Settings")
		if settings != null and "fast_mode" in settings and settings.fast_mode:
			dur = 0.4
	animate_day(day_num, dur)

func _init_stars() -> void:
	if not stars:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var quad := QuadMesh.new()
	quad.size = Vector2(0.8, 0.8)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	quad.material = mat
	mm.mesh = quad

	var count := 400
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = 19690720

	for i in count:
		# Distribute on upper sphere of radius 260-300
		var u := rng.randf_range(0.02, 1.0)
		var theta := rng.randf_range(0.0, TAU)
		var phi := acos(u)
		var r := rng.randf_range(260.0, 300.0)
		var pos := Vector3(
			r * sin(phi) * cos(theta),
			r * cos(phi),
			r * sin(phi) * sin(theta)
		)
		var star_scale := rng.randf_range(0.3, 1.2)
		var t := Transform3D(Basis().scaled(Vector3.ONE * star_scale), pos)
		mm.set_instance_transform(i, t)

	stars.multimesh = mm
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func sun_progress(day: int, frac: float) -> float:
	var sunset_day: float = 15.0
	if is_inside_tree() and get_node_or_null("/root/Constants") != null:
		var c = get_node("/root/Constants")
		if c.has_method("has") and c.has("SUNSET_DAY"):
			sunset_day = float(c.v("SUNSET_DAY"))
		elif "v" in c:
			sunset_day = float(c.v("SUNSET_DAY"))
	return clampf((float(day - 1) + frac) / (sunset_day - 0.5), 0.0, 1.0)

func apply_sun(t: float) -> void:
	current_t = t
	if not sun:
		return
	var elevation := deg_to_rad(SUN_LOW_DEG + sin(t * PI) * SUN_RISE_DEG)
	var azimuth := deg_to_rad(lerpf(-90.0, 90.0, t))
	current_azimuth = azimuth
	sun.rotation = Vector3(-elevation, azimuth, 0.0)
	sun.light_energy = SUN_ENERGY if t < 1.0 else 0.0

	if sun_glow:
		sun_glow.visible = t < 1.0
		if t < 1.0:
			var sun_basis := sun.global_transform.basis if is_inside_tree() else sun.transform.basis
			var sun_dir: Vector3 = sun_basis.z.normalized()
			if is_inside_tree():
				sun_glow.global_position = global_position + sun_dir * 240.0
			else:
				sun_glow.position = position + sun_dir * 240.0

	sun_updated.emit(t, azimuth, t < 1.0)

func set_day(day: int, frac: float = 0.0) -> void:
	if _day_tween != null and _day_tween.is_valid():
		_day_tween.kill()
		_day_tween = null
	current_day = day
	current_frac = frac
	var t := sun_progress(day, frac)
	apply_sun(t)

func animate_day(day: int, duration: float = 1.5) -> Tween:
	if _day_tween != null and _day_tween.is_valid():
		_day_tween.kill()
		_day_tween = null

	current_day = day
	var start_t := sun_progress(day, 0.0)
	var end_t := sun_progress(day, 1.0)

	if start_t >= 1.0:
		apply_sun(1.0)
		return null

	if duration <= 0.01:
		set_day(day, 1.0)
		return null

	_day_tween = create_tween()
	_day_tween.tween_method(
		func(val: float) -> void:
			current_frac = val
			var t: float = lerpf(start_t, end_t, val)
			apply_sun(t),
		0.0,
		1.0,
		duration
	)
	return _day_tween

func show_sunrise_glow(duration: float = 1.5) -> Tween:
	if _day_tween != null and _day_tween.is_valid():
		_day_tween.kill()
		_day_tween = null

	var elevation := deg_to_rad(2.5)
	var azimuth := deg_to_rad(-90.0)
	current_azimuth = azimuth
	if sun != null:
		sun.rotation = Vector3(-elevation, azimuth, 0.0)
		sun.light_energy = 0.0
		var sun_basis := sun.global_transform.basis if is_inside_tree() else sun.transform.basis
		var sun_dir: Vector3 = sun_basis.z.normalized()
		if sun_glow != null:
			sun_glow.visible = true
			sun_glow.modulate = Color(1.0, 0.8, 0.45, 0.0)
			if is_inside_tree():
				sun_glow.global_position = global_position + sun_dir * 240.0
			else:
				sun_glow.position = position + sun_dir * 240.0

	if duration <= 0.01:
		if sun != null:
			sun.light_energy = 0.85
		if sun_glow != null:
			sun_glow.modulate = Color(1.0, 0.85, 0.5, 0.95)
		return null

	_day_tween = create_tween()
	_day_tween.set_parallel(true)
	if sun != null:
		_day_tween.tween_property(sun, "light_energy", 0.85, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if sun_glow != null:
		_day_tween.tween_property(sun_glow, "modulate:a", 0.95, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return _day_tween

func get_sun_azimuth() -> float:
	return current_azimuth

func is_day() -> bool:
	return current_t < 1.0

func get_sun_t() -> float:
	return current_t
