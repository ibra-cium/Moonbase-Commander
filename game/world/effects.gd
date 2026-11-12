class_name Effects
extends Node3D

signal effect_started(event_code: String)
signal effect_completed(event_code: String)

const TEX_TRACE: Texture2D = preload("res://assets/particles/kenney/trace_01.png")
const TEX_SPARK: Texture2D = preload("res://assets/particles/kenney/spark_01.png")
const TEX_STEAM: Texture2D = preload("res://assets/particles/kenney/smoke_01.png")
const TEX_DIRT_1: Texture2D = preload("res://assets/particles/kenney/dirt_01.png")
const TEX_DIRT_2: Texture2D = preload("res://assets/particles/kenney/dirt_02.png")
const TEX_STAR: Texture2D = preload("res://assets/particles/kenney/star_01.png")

@onready var storm_particles: CPUParticles3D = $StormStreaks
@onready var spark_particles: CPUParticles3D = $SparkParticles
@onready var steam_particles: CPUParticles3D = $SteamParticles
@onready var dirt_particles: CPUParticles3D = $DirtParticles
@onready var star_particles: CPUParticles3D = $StarParticles
@onready var meteoroid_streak: Sprite3D = $MeteoroidStreak
@onready var red_overlay: CanvasLayer = $RedOverlay
@onready var red_rect: ColorRect = $RedOverlay/ColorRect

var _active_tweens: Array[Tween] = []
var _last_played_effect: String = ""
var _is_running: bool = false
var _storm_emitting: bool = false
var _sparks_emitting: bool = false
var _steam_emitting: bool = false
var _dirt_emitting: bool = false
var _star_emitting: bool = false

# Initial poses cache for objects that animate (Rover, Drill)
var _rover_initial_transform: Transform3D = Transform3D.IDENTITY
var _rover_cached: bool = false
var _drill_module_initial_rotation: Vector3 = Vector3.ZERO
var _drill_cached: bool = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_kill_all_tweens()

func _ready() -> void:
	_ensure_nodes()
	_init_particles()
	_connect_game_state()
	_cache_initial_transforms()

func _enter_tree() -> void:
	_ensure_nodes()
	_connect_game_state()

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

func _kill_all_tweens() -> void:
	for tw in _active_tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_active_tweens.clear()
	_is_running = false

func _safe_emit(emitter: CPUParticles3D, emit: bool) -> void:
	if emitter == null:
		return
	if is_inside_tree() and emitter.is_inside_tree():
		if emit:
			emitter.restart()
		emitter.emitting = emit

func _play_audio(sound_name: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var audio_node := tree.root.get_node_or_null("Audio")
		if audio_node != null and audio_node.has_method("play"):
			audio_node.play(sound_name)

func _ensure_nodes() -> void:
	if storm_particles == null:
		storm_particles = get_node_or_null("StormStreaks") as CPUParticles3D
	if spark_particles == null:
		spark_particles = get_node_or_null("SparkParticles") as CPUParticles3D
	if steam_particles == null:
		steam_particles = get_node_or_null("SteamParticles") as CPUParticles3D
	if dirt_particles == null:
		dirt_particles = get_node_or_null("DirtParticles") as CPUParticles3D
	if star_particles == null:
		star_particles = get_node_or_null("StarParticles") as CPUParticles3D
	if meteoroid_streak == null:
		meteoroid_streak = get_node_or_null("MeteoroidStreak") as Sprite3D
	if red_overlay == null:
		red_overlay = get_node_or_null("RedOverlay") as CanvasLayer
	if red_overlay != null and red_rect == null:
		red_rect = red_overlay.get_node_or_null("ColorRect") as ColorRect

func _make_particle_material(tex: Texture2D, blend_add: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	if blend_add:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return mat

func _init_particles() -> void:
	_ensure_nodes()

	# 1. Storm Streaks: high above base moving fast
	if storm_particles != null:
		storm_particles.emitting = false
		storm_particles.one_shot = false
		storm_particles.amount = 30
		storm_particles.lifetime = 1.0
		storm_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		storm_particles.emission_box_extents = Vector3(25.0, 3.0, 25.0)
		storm_particles.direction = Vector3(1.0, -0.25, 0.4).normalized()
		storm_particles.spread = 15.0
		storm_particles.initial_velocity_min = 45.0
		storm_particles.initial_velocity_max = 65.0
		storm_particles.gravity = Vector3.ZERO
		storm_particles.scale_amount_min = 1.2
		storm_particles.scale_amount_max = 2.4
		storm_particles.color = Color(1.0, 0.45, 0.3, 0.85)
		var q := QuadMesh.new()
		q.size = Vector2(1.5, 0.3)
		q.material = _make_particle_material(TEX_TRACE, true)
		storm_particles.mesh = q
		storm_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# 2. Sparks (recycler, meteoroid impact)
	if spark_particles != null:
		spark_particles.emitting = false
		spark_particles.one_shot = true
		spark_particles.explosiveness = 0.95
		spark_particles.amount = 20
		spark_particles.lifetime = 0.4
		spark_particles.direction = Vector3(0.0, 1.0, 0.0)
		spark_particles.spread = 180.0
		spark_particles.initial_velocity_min = 4.0
		spark_particles.initial_velocity_max = 8.0
		spark_particles.gravity = Vector3(0.0, -1.6, 0.0) # ~1/6 Moon gravity
		spark_particles.scale_amount_min = 0.4
		spark_particles.scale_amount_max = 0.9
		spark_particles.color = Color(1.0, 0.9, 0.4, 1.0)
		var q := QuadMesh.new()
		q.size = Vector2(0.35, 0.35)
		q.material = _make_particle_material(TEX_SPARK, true)
		spark_particles.mesh = q
		spark_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# 3. Steam puff (recycler breakdown)
	if steam_particles != null:
		steam_particles.emitting = false
		steam_particles.one_shot = true
		steam_particles.explosiveness = 0.7
		steam_particles.amount = 8
		steam_particles.lifetime = 1.6
		steam_particles.direction = Vector3(0.0, 1.0, 0.0)
		steam_particles.spread = 35.0
		steam_particles.initial_velocity_min = 1.2
		steam_particles.initial_velocity_max = 2.6
		steam_particles.gravity = Vector3(0.0, -0.2, 0.0) # Slow rise on Moon
		steam_particles.scale_amount_min = 0.6
		steam_particles.scale_amount_max = 2.2
		steam_particles.color = Color(0.85, 0.88, 0.92, 0.55)
		var q := QuadMesh.new()
		q.size = Vector2(0.6, 0.6)
		q.material = _make_particle_material(TEX_STEAM, false)
		steam_particles.mesh = q
		steam_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# 4. Dirt puffs (rover driving, science drill)
	if dirt_particles != null:
		dirt_particles.emitting = false
		dirt_particles.one_shot = true
		dirt_particles.explosiveness = 0.75
		dirt_particles.amount = 16
		dirt_particles.lifetime = 1.2
		dirt_particles.direction = Vector3(0.0, 0.4, 0.0)
		dirt_particles.spread = 70.0
		dirt_particles.initial_velocity_min = 1.8
		dirt_particles.initial_velocity_max = 3.8
		dirt_particles.gravity = Vector3(0.0, -1.6, 0.0)
		dirt_particles.scale_amount_min = 0.5
		dirt_particles.scale_amount_max = 1.8
		dirt_particles.color = Color(0.55, 0.55, 0.58, 0.65) # Regolith grey tint
		var q := QuadMesh.new()
		q.size = Vector2(0.5, 0.5)
		q.material = _make_particle_material(TEX_DIRT_1, false)
		dirt_particles.mesh = q
		dirt_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# 5. Stars celebration (debrief / milestones)
	if star_particles != null:
		star_particles.emitting = false
		star_particles.one_shot = true
		star_particles.explosiveness = 0.85
		star_particles.amount = 18
		star_particles.lifetime = 1.5
		star_particles.direction = Vector3(0.0, 1.0, 0.0)
		star_particles.spread = 120.0
		star_particles.initial_velocity_min = 2.5
		star_particles.initial_velocity_max = 5.5
		star_particles.gravity = Vector3(0.0, -1.0, 0.0)
		star_particles.scale_amount_min = 0.5
		star_particles.scale_amount_max = 1.4
		star_particles.color = Color(1.0, 0.95, 0.45, 0.95)
		var q := QuadMesh.new()
		q.size = Vector2(0.45, 0.45)
		q.material = _make_particle_material(TEX_STAR, true)
		star_particles.mesh = q
		star_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Meteoroid streak sprite
	if meteoroid_streak != null:
		meteoroid_streak.visible = false
		meteoroid_streak.texture = TEX_TRACE
		meteoroid_streak.modulate = Color(1.0, 0.85, 0.5, 0.95)
		meteoroid_streak.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	# Red Screen Overlay (tint during storms)
	if red_rect != null:
		red_rect.color = Color(0.85, 0.12, 0.12, 0.0)
		red_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _cache_initial_transforms() -> void:
	var b := get_base()
	if b != null:
		var rover := b.get_rover()
		if rover != null and not _rover_cached:
			_rover_initial_transform = rover.transform
			_rover_cached = true
		var drill := b.get_drill_module()
		if drill != null and not _drill_cached:
			_drill_module_initial_rotation = drill.rotation
			_drill_cached = true

func _connect_game_state() -> void:
	if not is_inside_tree():
		return
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		if not gs.day_started.is_connected(_on_game_state_day_started):
			gs.day_started.connect(_on_game_state_day_started)
		if not gs.day_resolved.is_connected(_on_game_state_day_resolved):
			gs.day_resolved.connect(_on_game_state_day_resolved)
		if not gs.event_triggered.is_connected(_on_game_state_event_triggered):
			gs.event_triggered.connect(_on_game_state_event_triggered)

func _get_effective_duration(override_dur: float = -1.0) -> float:
	if override_dur > 0.0:
		return override_dur
	var is_fast: bool = false
	if is_inside_tree() and get_node_or_null("/root/Settings") != null:
		var s = get_node("/root/Settings")
		if "fast_mode" in s:
			is_fast = bool(s.fast_mode)
	return 0.5 if is_fast else 2.0

func _get_report_val(report, key: String, default_val = null) -> Variant:
	if report == null:
		return default_val
	if report is Dictionary:
		return report.get(key, default_val)
	if report.has_method("get"):
		var v = report.get(key)
		if v != null:
			return v
	if key in report:
		return report.get(key)
	return default_val

func _get_node_pos(node: Node3D) -> Vector3:
	if node == null:
		return Vector3.ZERO
	if node.is_inside_tree():
		return node.global_position
	return node.position

func _set_node_pos(node: Node3D, pos: Vector3) -> void:
	if node == null:
		return
	if node.is_inside_tree():
		node.global_position = pos
	else:
		node.position = pos

func get_base() -> BaseStation:
	var b = get_node_or_null("../Base")
	if b == null and get_parent() != null:
		b = get_parent().find_child("Base", true, false)
	return b as BaseStation

func get_sky_rig() -> Node3D:
	var s = get_node_or_null("../SkyRig")
	if s == null and get_parent() != null:
		s = get_parent().find_child("SkyRig", true, false)
	return s

func get_crew() -> Node3D:
	var c = get_node_or_null("../Crew")
	if c == null and get_parent() != null:
		c = get_parent().find_child("Crew", true, false)
	return c

func get_lander() -> Node3D:
	var l = get_node_or_null("../Lander")
	if l == null and get_parent() != null:
		l = get_parent().find_child("Lander", true, false)
	return l

# --- Event Triggers from GameState ---

func _on_game_state_day_started(_day: int, warnings: Array) -> void:
	for w in warnings:
		if w != null:
			var code: String = str(w.code if "code" in w else (w.get("code", "") if w is Dictionary else ""))
			if code == "STORM_WARNING":
				play_storm_warning()
				break

func _on_game_state_event_triggered(evt: RefCounted) -> void:
	if evt == null:
		return
	var code: String = str(evt.code if "code" in evt else "")
	if not code.is_empty():
		play_event(code)

func _on_game_state_day_resolved(report) -> void:
	if report == null:
		return
	var dur := _get_effective_duration()

	# 1. Play specific events in report
	var played_major := false
	var evts = _get_report_val(report, "events", [])
	if evts is Array:
		for evt in evts:
			var code: String = str(evt.code if "code" in evt else (evt.get("code", "") if evt is Dictionary else ""))
			match code:
				"STORM":
					play_storm(dur)
					played_major = true
				"METEOROID":
					play_meteoroid(dur)
					played_major = true
				"RECYCLER_BROKE":
					play_recycler_broke(dur)
					played_major = true
				"SUNSET":
					play_sunset(dur)
					played_major = true

	# 2. Blackout check
	var blackout: bool = bool(_get_report_val(report, "blackout", false))
	if blackout:
		play_blackout(dur)
		played_major = true

	# 3. Job effects: check if regolith or science worked today
	if not played_major:
		var has_regolith := false
		var has_science := false
		var crew_reps = _get_report_val(report, "crew_reports", [])
		if crew_reps is Array:
			for cr in crew_reps:
				var job: String = str(cr.get("job", "") if cr is Dictionary else (cr.job if "job" in cr else ""))
				if job.to_upper() == "REGOLITH":
					has_regolith = true
				elif job.to_upper() == "SCIENCE":
					has_science = true

		if has_regolith:
			play_regolith(dur)
		elif has_science:
			play_science(dur)

# --- Public API: Functions for every event code ---

func play_event(code: String, duration: float = -1.0) -> void:
	match code.to_upper():
		"STORM":
			play_storm(duration)
		"STORM_WARNING":
			play_storm_warning(duration)
		"METEOROID":
			play_meteoroid(duration)
		"RECYCLER_BROKE":
			play_recycler_broke(duration)
		"REGOLITH":
			play_regolith(duration)
		"SCIENCE":
			play_science(duration)
		"BLACKOUT":
			play_blackout(duration)
		"SUNSET":
			play_sunset(duration)
		"SUPPLY_LOW":
			play_supply_low("", duration)
		"EVAC", "EVAC_RADIATION", "EVAC_CO2", "EVAC_O2", "EVAC_WATER", "EVAC_FOOD":
			play_evacuation(code, duration)
		"STARS":
			play_stars(3, duration)
		_:
			print("Effects: Unknown event code '%s'" % code)

# 1. Storm: red screen tint, streaks across sky, alarm light on shelter (lasts resolve animation)
func play_storm(duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "STORM"
	_is_running = true
	effect_started.emit("STORM")

	_cache_initial_transforms()
	_ensure_nodes()

	# Start sky particle streaks
	_storm_emitting = true
	_safe_emit(storm_particles, true)

	# Red screen tint fade-in, pulse, fade-out
	if red_rect != null:
		red_rect.color.a = 0.26
		var tw := _create_safe_tween()
		var half := dur * 0.5
		tw.tween_property(red_rect, "color:a", 0.18, half * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(red_rect, "color:a", 0.24, half * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(red_rect, "color:a", 0.0, dur * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Turn on shelter door alarm light
	var b := get_base()
	if b != null:
		b.set_shelter_door_light(true)

	# Complete after duration
	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_storm_emitting = false
		_safe_emit(storm_particles, false)
		if red_rect != null:
			red_rect.color.a = 0.0
		_is_running = false
		effect_completed.emit("STORM")
	)

func play_storm_warning(duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "STORM_WARNING"
	_is_running = true
	effect_started.emit("STORM_WARNING")

	_cache_initial_transforms()
	_ensure_nodes()

	# Brief warning streaks burst
	_storm_emitting = true
	_safe_emit(storm_particles, true)

	# Quick red pulse on screen
	if red_rect != null:
		red_rect.color.a = 0.22
		var tw := _create_safe_tween()
		tw.tween_property(red_rect, "color:a", 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Shelter alarm light lit immediately
	var b := get_base()
	if b != null:
		b.set_shelter_door_light(true)

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_storm_emitting = false
		_safe_emit(storm_particles, false)
		_is_running = false
		effect_completed.emit("STORM_WARNING")
	)

# 2. Meteoroid: streak -> spark burst -> panel goes dark
func play_meteoroid(duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "METEOROID"
	_is_running = true
	effect_started.emit("METEOROID")

	_cache_initial_transforms()
	_ensure_nodes()

	var b := get_base()
	var target_pos := Vector3(-5.5, 0.45, 6.5) # Default solar slot
	var target_panel: Node3D = null

	if b != null:
		var panels := b.get_solar_panels()
		if not panels.is_empty():
			# Pick the first panel or the one being broken
			target_panel = panels[0]
			target_pos = _get_node_pos(target_panel) + Vector3(0.0, 0.35, 0.0)
		else:
			target_pos = b.get_slot_position("Slot_Solar") + Vector3(0.0, 0.35, 0.0)

	var start_pos := target_pos + Vector3(12.0, 22.0, -8.0)
	var streak_time := clampf(dur * 0.3, 0.12, 0.4)

	if meteoroid_streak != null:
		_set_node_pos(meteoroid_streak, start_pos)
		meteoroid_streak.scale = Vector3(1.2, 3.2, 1.2)
		meteoroid_streak.visible = true

		var streak_tw := _create_safe_tween()
		var prop := "global_position" if meteoroid_streak.is_inside_tree() else "position"
		streak_tw.tween_property(meteoroid_streak, prop, target_pos, streak_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		streak_tw.tween_callback(func():
			meteoroid_streak.visible = false
			_trigger_meteoroid_impact(target_pos, target_panel)
		)
	else:
		_trigger_meteoroid_impact(target_pos, target_panel)

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_is_running = false
		effect_completed.emit("METEOROID")
	)

func _trigger_meteoroid_impact(pos: Vector3, panel_node: Node3D) -> void:
	_ensure_nodes()
	_play_audio("impact")
	_sparks_emitting = true
	_dirt_emitting = true
	if spark_particles != null:
		_set_node_pos(spark_particles, pos)
		_safe_emit(spark_particles, true)

	if dirt_particles != null:
		_set_node_pos(dirt_particles, pos)
		_safe_emit(dirt_particles, true)

	var b := get_base()
	if b != null:
		# If panel node exists, break it directly visually
		if panel_node != null and b.has_method("_update_single_panel"):
			b.call("_update_single_panel", panel_node, true)
		elif b.has_method("_update_solar_panels"):
			var cur_broken: int = int(b.get("_current_broken_panels")) if "_current_broken_panels" in b else 0
			b.call("_update_solar_panels", maxi(1, cur_broken + 1))

# 3. Recycler breaks: sparks + steam + red light
func play_recycler_broke(duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "RECYCLER_BROKE"
	_is_running = true
	effect_started.emit("RECYCLER_BROKE")

	_cache_initial_transforms()
	_ensure_nodes()
	_play_audio("spark")

	var b := get_base()
	var ls_pos := Vector3(4.0, 1.25, 0.45)
	if b != null:
		ls_pos = b.get_slot_position("Slot_LifeSupport") + Vector3(0.0, 1.25, 0.45)

	# Sparks burst at recycler
	_sparks_emitting = true
	_steam_emitting = true
	if spark_particles != null:
		_set_node_pos(spark_particles, ls_pos)
		_safe_emit(spark_particles, true)

	# Steam puff rising slowly
	if steam_particles != null:
		_set_node_pos(steam_particles, ls_pos)
		_safe_emit(steam_particles, true)

	# Red indicator light turns on
	if b != null:
		b.set_recycler_light(true)

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_is_running = false
		effect_completed.emit("RECYCLER_BROKE")
	)

# 4. Regolith days: rover drives dig site -> shelter, dirt puffs, mound grows
func play_regolith(duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "REGOLITH"
	_is_running = true
	effect_started.emit("REGOLITH")

	_cache_initial_transforms()
	_ensure_nodes()

	var b := get_base()
	var rover := b.get_rover() if b != null else null
	var trailer := b.get_trailer() if b != null else null

	var start_pos := Vector3(-10.5, 0.0, -1.0)
	var dig_pos := Vector3(-13.5, 0.0, -2.0)
	var shelter_pos := Vector3(-2.8, 0.0, -3.2)

	if b != null:
		dig_pos = b.get_slot_position("Slot_DigSite") + Vector3(0.5, 0.0, 0.0)
		shelter_pos = b.get_slot_position("Slot_Shelter") + Vector3(-2.6, 0.0, 0.5)

	if rover != null:
		if not _rover_cached:
			_rover_initial_transform = rover.transform
			_rover_cached = true
		start_pos = _rover_initial_transform.origin

		var drive_tw := _create_safe_tween()
		var segment := dur * 0.45

		# Drive from parked spot towards shelter delivery
		drive_tw.tween_property(rover, "position", shelter_pos, segment).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if trailer != null:
			var trailer_target := shelter_pos + Vector3(-2.5, 0.0, 0.0)
			drive_tw.parallel().tween_property(trailer, "position", trailer_target, segment).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# Dirt puff at delivery spot + shelter mound growth
		drive_tw.tween_callback(func():
			_dirt_emitting = true
			if dirt_particles != null:
				_set_node_pos(dirt_particles, shelter_pos + Vector3(1.2, 0.1, 0.0))
				_safe_emit(dirt_particles, true)
			if b != null:
				var mound := b.get_shelter_mound()
				if mound != null:
					mound.visible = true
					var grow_tw := _create_safe_tween()
					grow_tw.tween_property(mound, "scale", mound.scale * 1.15, segment * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)

		# Drive back to parked origin
		drive_tw.tween_property(rover, "position", start_pos, segment).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if trailer != null:
			var trailer_origin: Vector3 = trailer.position
			if "_rover_initial_transform" in self:
				trailer_origin = start_pos + Vector3(3.3, 0.0, 0.0)
			drive_tw.parallel().tween_property(trailer, "position", trailer_origin, segment).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_dirt_emitting = false
		_safe_emit(dirt_particles, false)
		_is_running = false
		effect_completed.emit("REGOLITH")
	)

# 5. Science days: drill spins, dust puff
func play_science(duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "SCIENCE"
	_is_running = true
	effect_started.emit("SCIENCE")

	_cache_initial_transforms()
	_ensure_nodes()

	var b := get_base()
	var drill := b.get_drill_module() if b != null else null
	var drill_pos := Vector3(7.5, 0.1, 0.0)
	if b != null:
		drill_pos = b.get_slot_position("Slot_Drill") + Vector3(0.0, 0.1, 0.0)

	if drill != null:
		if not _drill_cached:
			_drill_module_initial_rotation = drill.rotation
			_drill_cached = true

		var spin_tw := _create_safe_tween()
		var full_spins := 4.0 if dur >= 1.5 else 2.0
		spin_tw.tween_property(drill, "rotation:y", drill.rotation.y + TAU * full_spins, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# Dust puff at drill foot
	_dirt_emitting = true
	if dirt_particles != null:
		_set_node_pos(dirt_particles, drill_pos)
		_safe_emit(dirt_particles, true)

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_dirt_emitting = false
		_safe_emit(dirt_particles, false)
		_is_running = false
		effect_completed.emit("SCIENCE")
	)

# 6. Blackout: lamps and window lights extinguished
func play_blackout(duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "BLACKOUT"
	_is_running = true
	effect_started.emit("BLACKOUT")

	var b := get_base()
	if b != null:
		if b.has_method("_update_lamps"):
			b.call("_update_lamps", true, true)
		if b.has_method("_update_windows"):
			b.call("_update_windows", true, true)
		if b.has_method("_set_status_light"):
			b.call("_set_status_light", "red")

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_is_running = false
		effect_completed.emit("BLACKOUT")
	)

# 7. Sunset: sun drops, shadows stretch, lamps on
func play_sunset(duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "SUNSET"
	_is_running = true
	effect_started.emit("SUNSET")

	var sky := get_sky_rig()
	if sky != null and sky.has_method("animate_day"):
		sky.call("animate_day", 15, dur)

	var b := get_base()
	if b != null and b.has_method("_update_lamps"):
		b.call("_update_lamps", false, true)

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_is_running = false
		effect_completed.emit("SUNSET")
	)

# 8. Supply Low: status indicator pulse
func play_supply_low(_item: String = "", duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "SUPPLY_LOW"
	_is_running = true
	effect_started.emit("SUPPLY_LOW")

	var b := get_base()
	if b != null and b.has_method("_set_status_light"):
		b.call("_set_status_light", "yellow")

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_is_running = false
		effect_completed.emit("SUPPLY_LOW")
	)

# 9. Evacuation: hook for lander lift-off preparation
func play_evacuation(evac_type: String = "EVAC_RADIATION", duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = evac_type
	_is_running = true
	effect_started.emit(evac_type)

	var l := get_lander()
	if l != null:
		var flame = l.find_child("FlameSprite", true, false)
		if flame != null:
			flame.visible = true
		var dust = l.find_child("DustParticles", true, false) as CPUParticles3D
		if dust != null and dust.is_inside_tree():
			dust.restart()
			dust.emitting = true

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_is_running = false
		effect_completed.emit(evac_type)
	)

# 10. Stars: debrief & milestone pop
func play_stars(count: int = 3, duration: float = -1.0) -> void:
	var dur := _get_effective_duration(duration)
	_last_played_effect = "STARS"
	_is_running = true
	effect_started.emit("STARS")

	_ensure_nodes()
	_star_emitting = true
	if star_particles != null:
		star_particles.amount = count * 6
		_safe_emit(star_particles, true)

	var end_tw := _create_safe_tween()
	end_tw.tween_interval(dur)
	end_tw.tween_callback(func():
		_star_emitting = false
		_safe_emit(star_particles, false)
		_is_running = false
		effect_completed.emit("STARS")
	)

# Uppercase alias methods per lighting-and-effects SKILL.md table
func STORM(duration: float = -1.0) -> void:
	play_storm(duration)

func STORM_WARNING(duration: float = -1.0) -> void:
	play_storm_warning(duration)

func METEOROID(duration: float = -1.0) -> void:
	play_meteoroid(duration)

func RECYCLER_BROKE(duration: float = -1.0) -> void:
	play_recycler_broke(duration)

func REGOLITH(duration: float = -1.0) -> void:
	play_regolith(duration)

func SCIENCE(duration: float = -1.0) -> void:
	play_science(duration)

func BLACKOUT(duration: float = -1.0) -> void:
	play_blackout(duration)

func SUNSET(duration: float = -1.0) -> void:
	play_sunset(duration)

func SUPPLY_LOW(duration: float = -1.0) -> void:
	play_supply_low("", duration)

func EVAC(duration: float = -1.0) -> void:
	play_evacuation("EVAC", duration)

# Queries & State
func is_effect_running() -> bool:
	return _is_running

func get_last_played_effect() -> String:
	return _last_played_effect

func get_red_overlay_opacity() -> float:
	return red_rect.color.a if red_rect != null else 0.0

func is_storm_emitting() -> bool:
	return _storm_emitting or (storm_particles != null and storm_particles.emitting)

func is_sparks_emitting() -> bool:
	return _sparks_emitting or (spark_particles != null and spark_particles.emitting)

func is_steam_emitting() -> bool:
	return _steam_emitting or (steam_particles != null and steam_particles.emitting)

func is_dirt_emitting() -> bool:
	return _dirt_emitting or (dirt_particles != null and dirt_particles.emitting)

func is_star_emitting() -> bool:
	return _star_emitting or (star_particles != null and star_particles.emitting)

func reset_all_effects() -> void:
	_kill_all_tweens()
	_ensure_nodes()
	_storm_emitting = false
	_sparks_emitting = false
	_steam_emitting = false
	_dirt_emitting = false
	_star_emitting = false
	_safe_emit(storm_particles, false)
	_safe_emit(spark_particles, false)
	_safe_emit(steam_particles, false)
	_safe_emit(dirt_particles, false)
	_safe_emit(star_particles, false)
	if meteoroid_streak != null:
		meteoroid_streak.visible = false
	if red_rect != null:
		red_rect.color.a = 0.0

	var b := get_base()
	if b != null:
		var rover := b.get_rover()
		if rover != null and _rover_cached:
			rover.transform = _rover_initial_transform
		var drill := b.get_drill_module()
		if drill != null and _drill_cached:
			drill.rotation = _drill_module_initial_rotation
