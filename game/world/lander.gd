class_name Lander
extends Node3D

signal landing_completed
signal liftoff_completed

const SCENE_LANDER_MODEL: PackedScene = preload("res://assets/models/kaykit/lander_B.gltf")
const SCENE_CRATE_MODEL: PackedScene = preload("res://assets/models/kaykit/cargo_A_packed.gltf")
const TEX_FLAME: Texture2D = preload("res://assets/particles/kenney/flame_01.png")
const TEX_SMOKE: Texture2D = preload("res://assets/particles/kenney/smoke_01.png")
const TEX_SCORCH: Texture2D = preload("res://assets/particles/kenney/scorch_01.png")

@onready var lander_body: Node3D = $LanderBody
@onready var flame_sprite: Sprite3D = $LanderBody/FlameSprite
@onready var dust_particles: CPUParticles3D = $DustParticles
@onready var scorch_mesh: MeshInstance3D = $ScorchMark
@onready var crates_container: Node3D = $CratesContainer

var _scorch_material: StandardMaterial3D = null
var _landing_tween: Tween = null
var _active_tweens: Array[Tween] = []
var _is_landing: bool = false
var _is_liftoff: bool = false
var _flame_time: float = 0.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_kill_all_tweens()

func _kill_all_tweens() -> void:
	for tw in _active_tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_active_tweens.clear()
	_landing_tween = null

func _create_safe_tween() -> Tween:
	var tw: Tween = null
	if is_inside_tree():
		tw = create_tween()
	else:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			tw = tree.create_tween()
	if tw != null:
		_active_tweens.append(tw)
	return tw

func _ensure_nodes() -> void:
	if lander_body == null:
		lander_body = get_node_or_null("LanderBody") as Node3D
	if flame_sprite == null and lander_body != null:
		flame_sprite = lander_body.get_node_or_null("FlameSprite") as Sprite3D
	elif flame_sprite == null:
		flame_sprite = get_node_or_null("LanderBody/FlameSprite") as Sprite3D
	if dust_particles == null:
		dust_particles = get_node_or_null("DustParticles") as CPUParticles3D
	if scorch_mesh == null:
		scorch_mesh = get_node_or_null("ScorchMark") as MeshInstance3D
	if crates_container == null:
		crates_container = get_node_or_null("CratesContainer") as Node3D

func _ready() -> void:
	_ensure_nodes()
	_init_scorch()
	_init_particles()
	reset_state()

func _process(delta: float) -> void:
	if (_is_landing or _is_liftoff) and flame_sprite != null and flame_sprite.visible:
		_flame_time += delta * 25.0
		var flicker: float = 0.85 + sin(_flame_time) * 0.15 + cos(_flame_time * 1.7) * 0.1
		flame_sprite.scale = Vector3(1.2 * flicker, 1.8 * flicker, 1.2 * flicker)

func _init_scorch() -> void:
	_ensure_nodes()
	if scorch_mesh != null:
		_scorch_material = StandardMaterial3D.new()
		_scorch_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_scorch_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_scorch_material.albedo_texture = TEX_SCORCH
		_scorch_material.albedo_color = Color(0.12, 0.12, 0.14, 0.0)
		scorch_mesh.material_override = _scorch_material

func _init_particles() -> void:
	_ensure_nodes()
	if dust_particles != null:
		dust_particles.emitting = false
		dust_particles.one_shot = true
		dust_particles.explosiveness = 0.85
		dust_particles.amount = 28
		dust_particles.lifetime = 1.0
		dust_particles.direction = Vector3(0, 0.15, 0)
		dust_particles.spread = 85.0
		dust_particles.initial_velocity_min = 3.5
		dust_particles.initial_velocity_max = 6.0
		dust_particles.gravity = Vector3(0, -0.8, 0)
		dust_particles.scale_amount_min = 0.8
		dust_particles.scale_amount_max = 2.2
		dust_particles.color = Color(0.55, 0.55, 0.57, 0.65) # Regolith grey tint

func reset_state() -> void:
	_ensure_nodes()
	_is_landing = false
	_is_liftoff = false
	_kill_all_tweens()
	_stop_audio("engine")

	if lander_body != null:
		lander_body.position = Vector3(0.0, 0.0, 0.0)
	if flame_sprite != null:
		flame_sprite.visible = false
	if dust_particles != null:
		dust_particles.emitting = false
	if _scorch_material != null:
		_scorch_material.albedo_color.a = 0.0
	if crates_container != null:
		for child in crates_container.get_children():
			child.queue_free()

func setup_landing_start() -> void:
	_ensure_nodes()
	_is_landing = true
	if lander_body != null:
		lander_body.position = Vector3(0.0, 22.0, 0.0)
	if flame_sprite != null:
		flame_sprite.visible = true
	if dust_particles != null:
		dust_particles.emitting = false
	if _scorch_material != null:
		_scorch_material.albedo_color.a = 0.0
	if crates_container != null:
		for child in crates_container.get_children():
			child.queue_free()

func play_landing(base: Node3D = null, crew: Node3D = null, fast: bool = false) -> void:
	_ensure_nodes()
	setup_landing_start()

	var descent_time: float = 0.5 if fast else 1.5
	var shock_time: float = 0.06 if fast else 0.12
	var roll_time: float = 0.12 if fast else 0.28
	var pop_time: float = 0.18 if fast else 0.45

	_kill_all_tweens()

	_landing_tween = _create_safe_tween()
	if _landing_tween == null:
		landing_completed.emit()
		return

	_play_audio("engine")

	# 1. Descent to pad
	_landing_tween.tween_property(lander_body, "position:y", 0.0, descent_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 2. Touchdown
	_landing_tween.tween_callback(func():
		_is_landing = false
		_stop_audio("engine")
		if flame_sprite != null:
			flame_sprite.visible = false
		if dust_particles != null and dust_particles.is_inside_tree():
			dust_particles.restart()
	)

	# Shock absorber spring bounce on gear
	_landing_tween.tween_property(lander_body, "position:y", -0.08, shock_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_landing_tween.parallel().tween_method(func(alpha: float):
		if _scorch_material != null:
			_scorch_material.albedo_color.a = alpha
	, 0.0, 0.85, shock_time * 2.0)
	_landing_tween.tween_property(lander_body, "position:y", 0.03, shock_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_landing_tween.tween_property(lander_body, "position:y", 0.0, shock_time * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Crates rollout one by one
	_landing_tween.tween_interval(0.1 if fast else 0.2)
	_landing_tween.tween_callback(func():
		_start_crates_rollout(roll_time, base, crew, pop_time)
	)

func _start_crates_rollout(roll_time: float, base: Node3D, crew: Node3D, pop_time: float) -> void:
	var crate_spots: Array[Vector3] = [
		Vector3(-1.8, 0.0, 0.4),
		Vector3(-2.3, 0.0, -0.3),
		Vector3(-2.6, 0.0, 0.6)
	]

	var crate_tween := _create_safe_tween()
	if crate_tween == null:
		_finish_landing_and_pop_in(base, crew, pop_time)
		return

	for i in range(crate_spots.size()):
		var target_pos := crate_spots[i]
		crate_tween.tween_callback(func():
			_spawn_and_roll_crate(target_pos, roll_time)
		)
		crate_tween.tween_interval(roll_time * 0.85)

	crate_tween.tween_interval(0.1)
	crate_tween.tween_callback(func():
		_finish_landing_and_pop_in(base, crew, pop_time)
	)

func _spawn_and_roll_crate(target_pos: Vector3, duration: float) -> void:
	if crates_container == null:
		return
	var crate: Node3D = SCENE_CRATE_MODEL.instantiate() as Node3D
	crates_container.add_child(crate)
	crate.position = Vector3(0.0, 0.25, 0.0)
	crate.scale = Vector3(0.1, 0.1, 0.1)

	var roll := _create_safe_tween()
	if roll != null:
		roll.set_parallel(true)
		roll.tween_property(crate, "scale", Vector3.ONE, duration * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		roll.tween_property(crate, "position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		roll.tween_property(crate, "rotation:y", randf_range(-PI, PI), duration)

func _finish_landing_and_pop_in(base: Node3D, crew: Node3D, pop_time: float) -> void:
	if base != null and base.has_method("animate_pop_in"):
		base.call("animate_pop_in", pop_time)

	if crew != null and crew.has_method("animate_pop_in"):
		crew.call("animate_pop_in", pop_time)

	var finisher := _create_safe_tween()
	if finisher != null:
		finisher.tween_interval(pop_time + 0.1)
		finisher.tween_callback(func():
			landing_completed.emit()
		)
	else:
		landing_completed.emit()

func is_liftoff() -> bool:
	return _is_liftoff

func play_liftoff(crew: Node3D = null, fast: bool = false) -> void:
	_ensure_nodes()
	_kill_all_tweens()
	_is_liftoff = true
	_is_landing = false

	var boarding_time: float = 0.4 if fast else 1.2
	var liftoff_time: float = 0.8 if fast else 2.4

	var seq := _create_safe_tween()
	if seq == null:
		if crew != null and crew.has_method("evacuate"):
			crew.call("evacuate")
		liftoff_completed.emit()
		return

	# 1. Crew hops to the lander and boards inside ("door closes")
	if crew != null:
		if crew.has_method("evacuate"):
			crew.call("evacuate")
		seq.tween_interval(boarding_time)
		seq.tween_callback(func():
			if crew.has_method("board_lander"):
				crew.call("board_lander")
			elif crew.has_method("prepare_for_landing"):
				crew.call("prepare_for_landing")
		)
	else:
		seq.tween_interval(0.1)

	# 2. Engines ignite: flame flickers, dust kicks up on the pad
	seq.tween_callback(func():
		_play_audio("engine")
		if flame_sprite != null:
			flame_sprite.visible = true
		if dust_particles != null and dust_particles.is_inside_tree():
			dust_particles.restart()
			dust_particles.emitting = true
	)

	# 3. Lift-off acceleration upwards into the sky
	if lander_body != null:
		seq.tween_property(lander_body, "position:y", 40.0, liftoff_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		seq.tween_interval(liftoff_time)

	# 4. Finish liftoff
	seq.tween_callback(func():
		_is_liftoff = false
		_stop_audio("engine")
		if flame_sprite != null:
			flame_sprite.visible = false
		liftoff_completed.emit()
	)

func _play_audio(sound_name: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var audio_node := tree.root.get_node_or_null("Audio")
		if audio_node != null and audio_node.has_method("play"):
			audio_node.play(sound_name)

func _stop_audio(sound_name: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var audio_node := tree.root.get_node_or_null("Audio")
		if audio_node != null and audio_node.has_method("stop"):
			audio_node.stop(sound_name)

