extends "res://tests/test_case.gd"

const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimPlanScript := preload("res://sim/sim_plan.gd")
const TitleScreenScene: PackedScene = preload("res://ui/TitleScreen.tscn")
const DayHudScene: PackedScene = preload("res://ui/DayHud.tscn")

func _reset_audio_state() -> void:
	Settings.sound_on = true
	Audio.set_unlocked_for_test(true)
	Audio.stop_all()
	GameState.current_mission = null

func test_audio_autoload_and_streams() -> void:
	assert_true(Audio != null, "Audio autoload must exist")
	_reset_audio_state()

	for sfx_name in ["alarm", "impact", "spark", "engine", "ui_click", "ui_confirm", "ui_error", "ui_switch"]:
		assert_true(Audio.STREAMS.has(sfx_name), "STREAMS should contain %s" % sfx_name)
		Audio.play(sfx_name)
		assert_true(Audio.is_playing(sfx_name), "%s should start playing" % sfx_name)
		Audio.stop(sfx_name)
		assert_false(Audio.is_playing(sfx_name), "%s should stop cleanly" % sfx_name)

	Audio.loop("hum_loop")
	assert_true(Audio.is_looping("hum_loop"), "hum_loop should be active")
	assert_true(Audio.is_playing("hum_loop"), "hum_loop should be playing when unlocked and sound is on")

	Audio.stop("hum_loop")
	assert_false(Audio.is_looping("hum_loop"), "hum_loop should stop")
	assert_false(Audio.is_playing("hum_loop"), "hum_loop player should stop")
	_reset_audio_state()

func test_audio_mute_toggle_and_loop_pause() -> void:
	_reset_audio_state()

	Audio.loop("hum_loop")
	assert_false(Audio.is_muted(), "Audio should start unmuted")
	assert_true(Audio.is_playing("hum_loop"), "hum_loop should play before mute")

	Settings.sound_on = false
	assert_true(Audio.is_muted(), "Master bus must mute when Settings.sound_on is false")
	assert_true(Audio.is_looping("hum_loop"), "hum_loop remains logically active while muted")
	assert_false(Audio.is_playing("hum_loop"), "hum_loop player pauses when muted")

	Settings.sound_on = true
	assert_false(Audio.is_muted(), "Master bus must unmute when Settings.sound_on is true")
	assert_true(Audio.is_playing("hum_loop"), "hum_loop resumes playing after unmute")

	_reset_audio_state()

func test_audio_web_first_tap_gate() -> void:
	_reset_audio_state()
	Audio.set_unlocked_for_test(false)
	assert_false(Audio.is_unlocked(), "Web gate should start locked when locked for test")

	Audio.play("ui_click")
	assert_false(Audio.is_playing("ui_click"), "SFX must not play before first user tap")

	Audio.loop("hum_loop")
	assert_true(Audio.is_looping("hum_loop"), "Loop intent is recorded while waiting for tap")
	assert_false(Audio.is_playing("hum_loop"), "Loop audio must not play before unlock")

	Audio.unlock()
	assert_true(Audio.is_unlocked(), "unlock() should unlock audio")
	assert_true(Audio.is_playing("hum_loop"), "Deferred hum_loop should start immediately on unlock")

	_reset_audio_state()

func test_hum_stops_on_day_16_blackout_in_s01() -> void:
	_reset_audio_state()

	Constants.v("SOLAR_MAX_UNITS")
	var c := Constants.sim
	assert_true(c != null, "Constants.sim must be loaded")

	var cargo := SimCargoScript.new(c)
	cargo.set_count("solar", 20)
	cargo.set_count("battery", 10)
	cargo.set_count("reactor", 0)
	cargo.set_count("greenhouse", 0)
	cargo.set_count("o2", 2)
	cargo.set_count("water", 4)
	cargo.set_count("food", 5)
	cargo.set_count("shield", 10)

	var force := {
		"storm_day": 10,
		"recycler_day": 99,
		"meteoroid_day": 0
	}
	GameState.new_mission(cargo, 1, force)
	assert_true(Audio.is_looping("hum_loop"), "hum_loop must start on mission_started")
	assert_true(Audio.is_playing("hum_loop"), "hum_loop must play on mission_started")

	var ended_by_day: int = 0
	for day_num in range(1, 17):
		if GameState.current_mission.ended:
			break
		var plan := SimPlanScript.new()
		GameState.submit_day(plan)
		if day_num <= 14:
			assert_true(Audio.is_looping("hum_loop"), "hum_loop should keep looping on Day %d" % day_num)
		if day_num == 15 and not GameState.current_mission.ended:
			assert_true(Audio.is_looping("hum_loop"), "hum_loop should keep looping on Day 15 in S01")
		if day_num == 16:
			assert_false(Audio.is_looping("hum_loop"), "hum_loop must stop on Day 16 blackout in S01")
			assert_false(Audio.is_playing("hum_loop"), "hum_loop player must stop on Day 16 in S01")
		if GameState.current_mission.ended:
			ended_by_day = day_num

	assert_false(Audio.is_looping("hum_loop"), "hum_loop must be stopped by end of S01 (%d)" % ended_by_day)
	_reset_audio_state()

func test_ui_mute_buttons_exist_and_sync() -> void:
	_reset_audio_state()
	var root: Window = (Engine.get_main_loop() as SceneTree).root

	var title: TitleScreen = TitleScreenScene.instantiate() as TitleScreen
	root.add_child(title)
	title._ready()

	var hud := DayHudScene.instantiate()
	root.add_child(hud)
	hud._ready()

	assert_true(title.mute_button != null, "TitleScreen must have MuteButton")
	assert_true(title.mute_button.custom_minimum_size.y >= 64.0, "Title MuteButton height must be >= 64px")
	assert_true(hud.mute_btn != null, "DayHud must have MuteButton")
	assert_true(hud.mute_btn.custom_minimum_size.y >= 64.0, "DayHud MuteButton height must be >= 64px")

	title._on_mute_pressed()
	assert_false(Settings.sound_on, "Title MuteButton press should disable Settings.sound_on")
	assert_true(Audio.is_muted(), "Audio must mute after Title MuteButton press")
	assert_eq(hud.mute_btn.tooltip_text, title.mute_button.tooltip_text, "DayHud MuteButton should sync with Title MuteButton")

	hud._on_mute_button_pressed()
	assert_true(Settings.sound_on, "DayHud MuteButton press should re-enable Settings.sound_on")
	assert_false(Audio.is_muted(), "Audio must unmute after DayHud MuteButton press")

	root.remove_child(hud)
	hud.free()
	root.remove_child(title)
	title.free()
	_reset_audio_state()

