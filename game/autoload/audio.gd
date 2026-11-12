extends Node

const SOUND_PATHS: Dictionary = {
	"hum_loop": "res://assets/audio/hum_loop.ogg",
	"alarm": "res://assets/audio/alarm.ogg",
	"impact": "res://assets/audio/impact.ogg",
	"spark": "res://assets/audio/spark.ogg",
	"engine": "res://assets/audio/engine.ogg",
	"ui_click": "res://assets/audio/ui_click.ogg",
	"ui_confirm": "res://assets/audio/ui_confirm.ogg",
	"ui_error": "res://assets/audio/ui_error.ogg",
	"ui_switch": "res://assets/audio/ui_switch.ogg",
}

const STREAMS: Dictionary = {
	"hum_loop": preload("res://assets/audio/hum_loop.ogg"),
	"alarm": preload("res://assets/audio/alarm.ogg"),
	"impact": preload("res://assets/audio/impact.ogg"),
	"spark": preload("res://assets/audio/spark.ogg"),
	"engine": preload("res://assets/audio/engine.ogg"),
	"ui_click": preload("res://assets/audio/ui_click.ogg"),
	"ui_confirm": preload("res://assets/audio/ui_confirm.ogg"),
	"ui_error": preload("res://assets/audio/ui_error.ogg"),
	"ui_switch": preload("res://assets/audio/ui_switch.ogg"),
}

const VOLUME_DB: Dictionary = {
	"hum_loop": -14.0,
	"alarm": -3.0,
	"impact": -2.0,
	"spark": -3.0,
	"engine": -5.0,
	"ui_click": -5.0,
	"ui_confirm": -4.0,
	"ui_error": -4.0,
	"ui_switch": -5.0,
}

const ALIASES: Dictionary = {
	"hum": "hum_loop",
}

const DEDUP_SFX: PackedStringArray = ["impact", "spark", "alarm", "ui_error"]
const DEDUP_WINDOW_MS: int = 80
const ONE_SHOT_POOL_SIZE: int = 8

var _initialized: bool = false
var _unlocked: bool = true
var _loop_players: Dictionary = {}
var _active_loops: Dictionary = {}
var _one_shot_players: Array[AudioStreamPlayer] = []
var _one_shot_cursor: int = 0
var _last_sfx_ms: Dictionary = {}
var _headless_playing_one_shots: Dictionary = {}

func _ready() -> void:
	_ensure_initialized()

func _ensure_initialized() -> void:
	if not is_inside_tree():
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null and get_parent() == null:
			tree.root.add_child(self)
			return

	if Settings != null:
		if Settings.has_signal("sound_changed") and not Settings.sound_changed.is_connected(_on_settings_sound_changed):
			Settings.sound_changed.connect(_on_settings_sound_changed)

	if GameState != null:
		if GameState.has_signal("mission_started") and not GameState.mission_started.is_connected(_on_mission_started):
			GameState.mission_started.connect(_on_mission_started)
		if GameState.has_signal("day_resolved") and not GameState.day_resolved.is_connected(_on_day_resolved):
			GameState.day_resolved.connect(_on_day_resolved)
		if GameState.has_signal("mission_ended") and not GameState.mission_ended.is_connected(_on_mission_ended):
			GameState.mission_ended.connect(_on_mission_ended)

	if _initialized:
		return
	_initialized = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		_unlocked = false

	if _one_shot_players.is_empty():
		for i in range(ONE_SHOT_POOL_SIZE):
			var p := AudioStreamPlayer.new()
			p.name = "OneShot_%d" % i
			p.bus = "Master"
			add_child(p)
			_one_shot_players.append(p)

	apply_mute(_is_sound_enabled())

func _input(event: InputEvent) -> void:
	if _unlocked:
		return
	if (event is InputEventMouseButton and event.pressed) \
	or (event is InputEventScreenTouch and event.pressed) \
	or (event is InputEventKey and event.pressed):
		unlock()

func unlock() -> void:
	_ensure_initialized()
	if _unlocked:
		return
	_unlocked = true
	for loop_name in _active_loops.keys():
		_start_loop_player(str(loop_name))

func is_unlocked() -> bool:
	return _unlocked

func set_unlocked_for_test(val: bool) -> void:
	_ensure_initialized()
	_unlocked = val
	if _unlocked:
		for loop_name in _active_loops.keys():
			_start_loop_player(str(loop_name))
	else:
		_headless_playing_one_shots.clear()
		for p in _loop_players.values():
			if p != null:
				p.stop()
		for p in _one_shot_players:
			if p != null:
				p.stop()

func play(sound_name: String) -> void:
	_ensure_initialized()
	var key := _resolve_name(sound_name)
	if not STREAMS.has(key):
		push_warning("Audio: unknown sound '%s'" % sound_name)
		return
	if not _unlocked or not _is_sound_enabled():
		return

	if key in DEDUP_SFX:
		var now: int = Time.get_ticks_msec()
		var prev: int = int(_last_sfx_ms.get(key, -1000))
		if now - prev < DEDUP_WINDOW_MS:
			return
		_last_sfx_ms[key] = now

	var p := _next_one_shot_player()
	if p == null:
		return
	p.stream = STREAMS[key]
	p.volume_db = float(VOLUME_DB.get(key, 0.0))
	if p.is_inside_tree():
		p.play()
	else:
		_headless_playing_one_shots[key] = true

func loop(sound_name: String) -> void:
	_ensure_initialized()
	var key := _resolve_name(sound_name)
	if not STREAMS.has(key):
		push_warning("Audio: unknown sound '%s'" % sound_name)
		return
	_active_loops[key] = true
	if _unlocked:
		_start_loop_player(key)

func stop(sound_name: String) -> void:
	_ensure_initialized()
	var key := _resolve_name(sound_name)
	_active_loops.erase(key)
	_headless_playing_one_shots.erase(key)
	if _loop_players.has(key):
		var lp: AudioStreamPlayer = _loop_players[key]
		if lp != null:
			lp.stream_paused = false
			lp.stop()
	var target_stream: AudioStream = STREAMS.get(key, null)
	if target_stream != null:
		for p in _one_shot_players:
			if p != null and p.playing and p.stream == target_stream:
				p.stop()

func stop_all() -> void:
	_ensure_initialized()
	_active_loops.clear()
	_headless_playing_one_shots.clear()
	for p in _loop_players.values():
		if p != null:
			p.stream_paused = false
			p.stop()
	for p in _one_shot_players:
		if p != null:
			p.stop()

func apply_mute(sound_enabled: bool) -> void:
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, not sound_enabled)
	for key in _loop_players.keys():
		var p: AudioStreamPlayer = _loop_players[key]
		if p != null:
			p.stream_paused = not sound_enabled
			if sound_enabled and _unlocked and _active_loops.has(key) and not p.playing and p.is_inside_tree():
				p.play()
	if not sound_enabled:
		_headless_playing_one_shots.clear()
		for p in _one_shot_players:
			if p != null and p.playing:
				p.stop()

func is_looping(sound_name: String) -> bool:
	_ensure_initialized()
	return _active_loops.has(_resolve_name(sound_name))

func is_playing(sound_name: String) -> bool:
	_ensure_initialized()
	if not _is_sound_enabled():
		return false
	var key := _resolve_name(sound_name)
	if _loop_players.has(key):
		var lp: AudioStreamPlayer = _loop_players[key]
		if lp != null and not lp.stream_paused:
			if lp.is_inside_tree():
				if lp.playing:
					return true
			elif _unlocked and _active_loops.has(key):
				return true
	var target_stream: AudioStream = STREAMS.get(key, null)
	if target_stream != null:
		if is_inside_tree():
			for p in _one_shot_players:
				if p != null and p.playing and p.stream == target_stream:
					return true
		elif _unlocked and _headless_playing_one_shots.has(key):
			return true
	return false

func is_muted() -> bool:
	_ensure_initialized()
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		return AudioServer.is_bus_mute(master_idx)
	return not _is_sound_enabled()

func _resolve_name(sound_name: String) -> String:
	if ALIASES.has(sound_name):
		return str(ALIASES[sound_name])
	return sound_name

func _is_sound_enabled() -> bool:
	if Settings != null and "sound_on" in Settings:
		return bool(Settings.sound_on)
	return true

func _start_loop_player(key: String) -> void:
	var p: AudioStreamPlayer = _loop_players.get(key, null)
	if p == null:
		p = AudioStreamPlayer.new()
		p.name = "Loop_" + key
		p.bus = "Master"
		add_child(p)
		_loop_players[key] = p
	p.stream = STREAMS[key]
	p.volume_db = float(VOLUME_DB.get(key, 0.0))
	var enabled := _is_sound_enabled()
	p.stream_paused = not enabled
	if p.is_inside_tree() and not p.playing:
		p.play()
		p.stream_paused = not enabled

func _next_one_shot_player() -> AudioStreamPlayer:
	for p in _one_shot_players:
		if p != null and not p.playing:
			return p
	if _one_shot_players.is_empty():
		return null
	var p: AudioStreamPlayer = _one_shot_players[_one_shot_cursor % _one_shot_players.size()]
	_one_shot_cursor = (_one_shot_cursor + 1) % _one_shot_players.size()
	return p

func _on_settings_sound_changed(enabled: bool) -> void:
	apply_mute(enabled)

func _on_mission_started(_mission: RefCounted) -> void:
	loop("hum_loop")

func _on_mission_ended(_result: RefCounted) -> void:
	stop("hum_loop")

func _on_day_resolved(report: RefCounted) -> void:
	if report == null:
		return
	var blackout: bool = bool(report.blackout) if "blackout" in report else false
	var core_served: bool = not blackout
	if "power_served" in report and report.power_served is Dictionary:
		core_served = bool(report.power_served.get("core", core_served)) and not blackout
	if core_served:
		loop("hum_loop")
	else:
		stop("hum_loop")
