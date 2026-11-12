extends "res://tests/test_case.gd"

const DayHudScene: PackedScene = preload("res://ui/DayHud.tscn")
const GaugeScene: PackedScene = preload("res://ui/Gauge.tscn")
const SimMissionScript := preload("res://sim/sim_mission.gd")
const SimCargoScript := preload("res://sim/sim_cargo.gd")
const SimPlanScript := preload("res://sim/sim_plan.gd")
const SimDayReportScript := preload("res://sim/sim_day_report.gd")
const SimEventsScript := preload("res://sim/sim_events.gd")


func _get_root() -> Window:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root if tree != null else null


func _make_hud() -> DayHud:
	var hud: DayHud = DayHudScene.instantiate() as DayHud
	_get_root().add_child(hud)
	hud._ready()
	return hud


func test_sim_report_kid_fields() -> void:
	var c := load_constants()
	var cargo := {"solar": 20, "battery": 4, "reactor": 2, "greenhouse": 0, "o2": 2, "water": 4, "food": 5, "shield": 10}
	var m := SimMissionScript.new(c, cargo, 42, {"storm": 10, "recycler": 99, "meteoroid": 0})
	var plan := SimPlanScript.new()
	var rep: SimDayReport = m.step_day(plan)

	assert_true(rep.o2_days_left > 0.0, "Report populates o2_days_left")
	assert_true(rep.water_days_left > 0.0, "Report populates water_days_left")
	assert_true(rep.food_days_left > 0.0, "Report populates food_days_left")
	assert_eq(rep.days_to_go, int(c.v("MISSION_DAYS")) - 1, "Day 1 report has MISSION_DAYS - 1 days_to_go")
	assert_near(rep.storm_dose_if_now_msv, m.events.storm_dose(m.shelter_g_cm2), 0.01, "storm_dose_if_now_msv matches events.storm_dose")

	var d: Dictionary = rep.to_dict()
	for k in ["o2_days_left", "water_days_left", "food_days_left", "days_to_go", "storm_dose_if_now_msv"]:
		assert_true(d.has(k), "to_dict() includes %s" % k)

	# Breaking recycler cuts water_days_left accurately
	var rec_ok_days: float = rep.water_days_left
	m.life.recycler_broken = true
	var rep2: SimDayReport = m.step_day(plan)
	assert_true(rep2.water_days_left < rec_ok_days * 0.5, "Broken recycler sharply drops water_days_left")


func test_default_five_kid_gauges_no_science_units_and_fit() -> void:
	var saved_lang: String = Settings.language
	var saved_sci: bool = Settings.science_view
	Settings.language = "en"
	Settings.science_view = false

	var c := load_constants()
	var cargo := SimCargoScript.new(c)
	var m := SimMissionScript.new(c, cargo, 7)
	var hud := _make_hud()
	hud.setup_mission(m)

	assert_true(hud.power_gauge.visible, "Battery gauge visible")
	assert_true(hud.co2_gauge.visible, "Air gauge visible")
	assert_true(hud.water_gauge.visible, "Water gauge visible")
	assert_true(hud.food_gauge.visible, "Food gauge visible")
	assert_true(hud.shelter_gauge.visible, "Storm safety gauge visible")
	assert_false(hud.o2_gauge.visible, "Separate O2 gauge hidden in Kid view")
	assert_false(hud.rad_gauge.visible, "Radiation gauge hidden in Kid view")

	assert_eq(hud.shelter_gauge.source_constant_id, "RAD_SPE_LIMIT_MSV", "Storm safety SourceTag uses RAD_SPE_LIMIT_MSV")

	var kid_gauges: Array[Gauge] = [hud.power_gauge, hud.co2_gauge, hud.water_gauge, hud.food_gauge, hud.shelter_gauge]
	for g in kid_gauges:
		assert_true(g.source_constant_id != "", "Kid gauge %s keeps source_constant_id" % g.name)
		assert_true(g.source_tag.visible, "Kid gauge %s keeps SourceTag visible" % g.name)
		var combined_text: String = "%s %s %s %s %s %s" % [
			g.title_label.text,
			g.value_label.text if g.value_label.visible else "",
			g.unit_label.text if g.unit_label.visible else "",
			g.status_label.text if g.status_label.visible else "",
			g.extra_status_label.text if g.extra_status_label.visible else "",
			g.science_label.text if g.science_label.visible else "",
		]
		for forbidden in ["kg", "mmHg", "mSv", "g/cm²", "kWh"]:
			assert_false(combined_text.contains(forbidden), "Kid gauge %s hides science unit '%s' (got '%s')" % [g.name, forbidden, combined_text])
		assert_true(g.get_combined_minimum_size().x <= 390.0, "Gauge %s readable within 390px width" % g.name)

	var lc := hud.get_node("LeftColumn") as MarginContainer
	var avail_720p_h: float = 720.0 + lc.offset_bottom - lc.offset_top
	var gauges_box := hud.get_node("LeftColumn/Gauges") as VBoxContainer
	var sep: float = float(gauges_box.get_theme_constant("separation"))
	var real_total_h: float = sep * float(kid_gauges.size() - 1)
	for g in kid_gauges:
		var sb := g.get_theme_stylebox("panel")
		var margin := g.get_node("Margin") as MarginContainer
		var vb := g.get_node("Margin/VBox") as VBoxContainer
		var tl := g.get_node("Margin/VBox/TopRow/TitleLabel") as Label
		var vl := g.get_node("Margin/VBox/ValueRow/ValueLabel") as Label
		var top_h: float = maxf(22.0, tl.get_theme_font("font").get_height(tl.get_theme_font_size("font_size")))
		var val_h: float = maxf(18.0, vl.get_theme_font("font").get_height(vl.get_theme_font_size("font_size")))
		var bar_h: float = g.bar.get_combined_minimum_size().y
		var vb_sep: float = float(vb.get_theme_constant("separation")) * 2.0
		var m_h: float = float(margin.get_theme_constant("margin_top") + margin.get_theme_constant("margin_bottom"))
		var sb_h: float = (sb.content_margin_top + sb.content_margin_bottom) if sb != null else 0.0
		real_total_h += top_h + val_h + bar_h + vb_sep + m_h + sb_h
	assert_true(real_total_h <= avail_720p_h, "Five kid gauges (%.1fpx) fit LeftColumn at 720p (%.1fpx available) without scrolling" % [real_total_h, avail_720p_h])
	assert_true(real_total_h <= 365.0, "Five kid gauges remain compact (%.1fpx <= 365px)" % real_total_h)

	for card in hud.crew_cards:
		assert_false(card.dose_label.visible, "Crew card mSv dose hidden when Science numbers is OFF")

	hud.free()
	Settings.language = saved_lang
	Settings.science_view = saved_sci


func test_battery_colors_pulse_and_arrows() -> void:
	var saved_lang: String = Settings.language
	var saved_sci: bool = Settings.science_view
	Settings.language = "en"
	Settings.science_view = false

	var hud := _make_hud()
	var r := SimDayReportScript.new()
	r.sun_factor = 1.0
	r.battery_percent = 100.0
	r.o2_days_left = 20.0
	r.water_days_left = 20.0
	r.food_days_left = 20.0
	r.days_to_go = 15
	hud.update_from_report(r)
	assert_eq(hud.power_gauge.current_state, Gauge.State.NORMAL, "100% battery is green")
	assert_eq(hud.power_gauge.value_label.text, "100%", "Battery shows 100%")
	assert_eq(hud.power_gauge.arrow_graphic.graphic_kind, "arrow_up", "Full in sunlight shows up arrow")
	assert_eq(hud.power_gauge.extra_status_label.text, tr("KID_CHARGING"), "Shows Charging word")

	# Drain to amber (35%)
	r.sun_factor = 0.0
	r.battery_percent = 35.0
	hud.update_from_report(r)
	assert_eq(hud.power_gauge.current_state, Gauge.State.WARN, "35% battery (>= 30%) is amber")
	assert_eq(hud.power_gauge.arrow_graphic.graphic_kind, "arrow_down", "Drop shows down arrow")
	assert_eq(hud.power_gauge.extra_status_label.text, tr("KID_DRAINING"), "Shows Draining word")

	# Rise to 55% -> green + Charging arrow
	r.sun_factor = 1.0
	r.battery_percent = 55.0
	hud.update_from_report(r)
	assert_eq(hud.power_gauge.current_state, Gauge.State.NORMAL, "55% battery (>= 50%) is green")
	assert_eq(hud.power_gauge.arrow_graphic.graphic_kind, "arrow_up", "Rise shows up arrow")

	# Low non-zero (15%) -> red without pulse
	r.battery_percent = 15.0
	hud.update_from_report(r)
	assert_eq(hud.power_gauge.current_state, Gauge.State.CRITICAL, "15% battery (< 30%) is red")
	assert_false(hud.power_gauge.is_processing(), "Non-zero red battery does not pulse")

	# 0% / blackout -> red WITH pulse
	r.battery_percent = 0.0
	r.blackout = true
	hud.update_from_report(r)
	assert_eq(hud.power_gauge.current_state, Gauge.State.CRITICAL, "0% battery is red")
	assert_true(hud.power_gauge.is_processing(), "0% battery pulses red")

	hud.free()
	Settings.language = saved_lang
	Settings.science_view = saved_sci


func test_days_left_colors_and_storm_pips() -> void:
	var saved_lang: String = Settings.language
	var saved_sci: bool = Settings.science_view
	Settings.language = "en"
	Settings.science_view = false

	var c := load_constants()
	var events := SimEventsScript.new(c)
	var hud := _make_hud()
	var r := SimDayReportScript.new()
	r.days_to_go = 15
	r.o2_days_left = 20.0
	r.water_days_left = 15.0
	r.food_days_left = 15.0
	r.battery_percent = 80.0

	# Storm pips 0 / 5 / 10 / 15 g/cm2
	r.storm_dose_if_now_msv = events.storm_dose(0.0)
	hud.update_from_report(r)
	assert_eq(hud.shelter_gauge.get_shield_pip_count(), 0, "0 g/cm2 -> 0 storm pips")
	assert_eq(hud.shelter_gauge.current_state, Gauge.State.CRITICAL, "0 pips is red")
	assert_eq(hud.shelter_gauge.value_label.text, tr("KID_STORM_NOT_SAFE"), "0 pips says Not safe!")

	r.storm_dose_if_now_msv = events.storm_dose(5.0)
	hud.update_from_report(r)
	assert_eq(hud.shelter_gauge.get_shield_pip_count(), 1, "5 g/cm2 -> 1 storm pip")
	assert_eq(hud.shelter_gauge.current_state, Gauge.State.WARN, "1 pip is amber")
	assert_eq(hud.shelter_gauge.value_label.text, tr("KID_STORM_SAFE"), "1 pip says Safe")

	r.storm_dose_if_now_msv = events.storm_dose(10.0)
	hud.update_from_report(r)
	assert_eq(hud.shelter_gauge.get_shield_pip_count(), 2, "10 g/cm2 -> 2 storm pips")
	assert_eq(hud.shelter_gauge.current_state, Gauge.State.NORMAL, "2 pips is green")

	r.storm_dose_if_now_msv = events.storm_dose(15.0)
	hud.update_from_report(r)
	assert_eq(hud.shelter_gauge.get_shield_pip_count(), 3, "15 g/cm2 -> 3 storm pips")
	assert_eq(hud.shelter_gauge.current_state, Gauge.State.NORMAL, "3 pips is green")

	# Days-left thresholds against days_to_go=15 and SUPPLY_WARNING_DAYS=3
	assert_eq(hud.water_gauge.current_state, Gauge.State.NORMAL, "Water 15 >= 15 is green")
	assert_eq(hud.water_gauge.value_label.text, tr("KID_DAYS_LEFT").format({"n": 15}), "Water shows 15 days left")
	assert_eq(hud.water_gauge.extra_status_label.text, tr("KID_ENOUGH"), "Enough! shown when >= days_to_go")

	r.water_days_left = 10.0
	r.food_days_left = 3.0
	hud.update_from_report(r)
	assert_eq(hud.water_gauge.current_state, Gauge.State.WARN, "Water 10 (< 15, >= 3) is amber")
	assert_false(hud.water_gauge.extra_status_label.visible, "Enough! hidden when < days_to_go")
	assert_eq(hud.food_gauge.current_state, Gauge.State.WARN, "Food == SUPPLY_WARNING_DAYS (3) is amber")

	r.water_days_left = 2.5
	r.food_days_left = 2.0
	hud.update_from_report(r)
	assert_eq(hud.water_gauge.current_state, Gauge.State.CRITICAL, "Water < 3 days is red")
	assert_eq(hud.food_gauge.current_state, Gauge.State.CRITICAL, "Food < 3 days is red")

	r.water_days_left = 20.0
	r.recycler_broken = true
	hud.update_from_report(r)
	assert_eq(hud.water_gauge.extra_status_label.text, tr("KID_RECYCLER_BROKEN"), "Broken recycler shown on water gauge")

	hud.free()
	Settings.language = saved_lang
	Settings.science_view = saved_sci


func test_air_face_co2_and_air_off_low_o2() -> void:
	var saved_lang: String = Settings.language
	var saved_sci: bool = Settings.science_view
	Settings.language = "en"
	Settings.science_view = false

	var c := load_constants()
	var hud := _make_hud()
	var r := SimDayReportScript.new()
	r.days_to_go = 10
	r.water_days_left = 20.0
	r.food_days_left = 20.0
	r.o2_days_left = 10.0
	r.power_served = {"core": true}

	# Good
	r.co2_mmhg = float(c.v("CO2_HEALTHY_MAX_MMHG")) - 0.5
	hud.update_from_report(r)
	assert_eq(hud.co2_gauge.face_graphic.graphic_kind, "face_good", "Healthy CO2 draws happy face")
	assert_eq(hud.co2_gauge.current_state, Gauge.State.NORMAL, "Healthy CO2 is green")
	assert_eq(hud.get_co2_status_text(), tr("AIR_GOOD"), "Healthy CO2 shows AIR_GOOD")

	# Stuffy
	r.co2_mmhg = float(c.v("CO2_HEALTHY_MAX_MMHG")) + 0.4
	hud.update_from_report(r)
	assert_eq(hud.co2_gauge.face_graphic.graphic_kind, "face_stuffy", "Elevated CO2 draws flat stuffy face")
	assert_eq(hud.co2_gauge.current_state, Gauge.State.WARN, "Elevated CO2 is amber")
	assert_eq(hud.get_co2_status_text(), tr("AIR_STUFFY"), "Elevated CO2 shows AIR_STUFFY")

	# Danger by CO2
	r.co2_mmhg = float(c.v("CO2_LIMIT_MMHG")) + 0.5
	hud.update_from_report(r)
	assert_eq(hud.co2_gauge.face_graphic.graphic_kind, "face_danger", "High CO2 draws danger face")
	assert_eq(hud.co2_gauge.current_state, Gauge.State.CRITICAL, "High CO2 is red")
	assert_eq(hud.get_co2_status_text(), tr("AIR_DANGER"), "High CO2 shows AIR_DANGER")

	# Danger when air machine off AND o2_days_left < SUPPLY_WARNING_DAYS (even if CO2 is low!)
	r.co2_mmhg = 0.6
	r.power_served = {"core": false}
	r.o2_days_left = float(c.v("SUPPLY_WARNING_DAYS")) - 0.5
	hud.update_from_report(r)
	assert_eq(hud.co2_gauge.face_graphic.graphic_kind, "face_danger", "Air off + low O2 draws danger face")
	assert_eq(hud.co2_gauge.current_state, Gauge.State.CRITICAL, "Air off + low O2 is red")
	assert_eq(hud.get_co2_status_text(), tr("AIR_DANGER"), "Air off + low O2 shows AIR_DANGER")

	hud.free()
	Settings.language = saved_lang
	Settings.science_view = saved_sci


func test_tip_rules_show_me_and_source_tag_exclusion() -> void:
	var saved_lang: String = Settings.language
	var saved_sci: bool = Settings.science_view
	Settings.language = "en"
	Settings.science_view = false

	var c := load_constants()
	var hud := _make_hud()
	var r := SimDayReportScript.new()
	r.days_to_go = 15
	r.o2_days_left = 20.0
	r.water_days_left = 20.0
	r.food_days_left = 20.0
	r.battery_percent = 80.0
	r.co2_mmhg = 1.0
	r.power_served = {"core": true}
	r.storm_dose_if_now_msv = 68.0
	hud.update_from_report(r)

	# 1. Any fine -> TIP_ALL_GOOD, no Show me
	hud.tap_gauge("water")
	assert_true(hud.tip_panel.visible, "Tapping water opens tip bubble")
	assert_eq(hud.tip_label.text, tr("TIP_ALL_GOOD"), "Fine water shows All good!")
	assert_false(hud.tip_show_me_btn.visible, "No Show me when All good!")

	# 2. SourceTag tap does NOT trigger gauge_tapped
	hud.tip_panel.visible = false
	hud.water_gauge.size = Vector2(264, 65)
	hud.water_gauge.source_tag.visible = true
	hud.water_gauge.source_tag.size = Vector2(22, 22)
	var tag_mb := InputEventMouseButton.new()
	tag_mb.button_index = MOUSE_BUTTON_LEFT
	tag_mb.pressed = true
	tag_mb.position = hud.water_gauge.source_tag.get_global_rect().get_center() - hud.water_gauge.get_global_transform_with_canvas().origin
	hud.water_gauge._gui_input(tag_mb)
	assert_false(hud.tip_panel.visible, "Tapping SourceTag inside gauge does not open tip bubble")

	# 3. Water recycler broken -> TIP_WATER_REPAIR + Show me -> life_support marker pulsing
	r.recycler_broken = true
	r.water_days_left = 5.0 # also amber, but recycler_broken wins first!
	hud.update_from_report(r)
	hud.tap_gauge("water")
	assert_eq(hud.tip_label.text, tr("TIP_WATER_REPAIR"), "Broken recycler wins over low water")
	assert_true(hud.tip_show_me_btn.visible, "Repair tip has Show me")
	hud.tip_show_me_btn.pressed.emit()
	assert_eq(hud.last_show_me_target, "life_support", "Show me targets life_support")
	var markers := hud.get_building_markers()
	assert_true(markers.has("life_support"), "Show me opens M-05 building markers")
	assert_true((markers["life_support"] as BuildingMarker).is_pulsing, "life_support marker pulses")

	# 4. Water low with recycler OK -> TIP_WATER_PACK, no Show me
	r.recycler_broken = false
	r.water_days_left = 8.0
	hud.update_from_report(r)
	hud.tap_gauge("water")
	assert_eq(hud.tip_label.text, tr("TIP_WATER_PACK"), "Low water with OK recycler gives pack tip")
	assert_false(hud.tip_show_me_btn.visible, "Pack tip has no Show me")

	# 5. Food low -> TIP_FOOD_PACK, no Show me
	r.food_days_left = 6.0
	hud.update_from_report(r)
	hud.tap_gauge("food")
	assert_eq(hud.tip_label.text, tr("TIP_FOOD_PACK"), "Low food gives pack tip")
	assert_false(hud.tip_show_me_btn.visible, "Food pack tip has no Show me")

	# 6. Air stuffy -> TIP_AIR_POWER + Show me -> greenhouse_switch
	r.co2_mmhg = float(c.v("CO2_HEALTHY_MAX_MMHG")) + 0.5
	hud.update_from_report(r)
	hud.tap_gauge("air")
	assert_eq(hud.tip_label.text, tr("TIP_AIR_POWER"), "Stuffy air gives TIP_AIR_POWER")
	assert_true(hud.tip_show_me_btn.visible, "Air tip has Show me")
	hud.tip_show_me_btn.pressed.emit()
	assert_eq(hud.last_show_me_target, "greenhouse_switch", "Air tip Show me targets greenhouse_switch")

	# 7. Battery amber: fine during day, tip at night; red triggers even in day
	r.battery_percent = 40.0
	hud.set_day(5)
	hud.update_from_report(r)
	hud.tap_gauge("battery")
	assert_eq(hud.tip_label.text, tr("TIP_ALL_GOOD"), "Amber battery in daytime gives All good!")
	hud.set_day(int(c.v("SUNSET_DAY")))
	hud._hide_tip_bubble()
	hud.tap_gauge("battery")
	assert_eq(hud.tip_label.text, tr("TIP_BATTERY_NIGHT"), "Amber battery at night gives TIP_BATTERY_NIGHT")
	assert_true(hud.tip_show_me_btn.visible, "Battery night tip has Show me")
	hud.tip_show_me_btn.pressed.emit()
	assert_eq(hud.last_show_me_target, "greenhouse_switch", "Battery tip Show me targets greenhouse_switch")

	hud.set_day(5)
	r.battery_percent = 20.0
	hud.update_from_report(r)
	hud.tap_gauge("battery")
	assert_eq(hud.tip_label.text, tr("TIP_BATTERY_NIGHT"), "Red battery gives TIP_BATTERY_NIGHT even in daytime")

	# 8. Storm 0 pips -> TIP_STORM_DIG + Show me -> dig_site pulsing
	r.storm_dose_if_now_msv = 398.0
	hud.update_from_report(r)
	hud.tap_gauge("storm")
	assert_eq(hud.tip_label.text, tr("TIP_STORM_DIG"), "0 pips storm gives TIP_STORM_DIG")
	assert_true(hud.tip_show_me_btn.visible, "Storm dig tip has Show me")
	hud.tip_show_me_btn.pressed.emit()
	assert_eq(hud.last_show_me_target, "dig_site", "Storm tip Show me targets dig_site")
	markers = hud.get_building_markers()
	assert_true(markers.has("dig_site"), "Show me opens dig_site marker")
	assert_true((markers["dig_site"] as BuildingMarker).is_pulsing, "dig_site marker pulses")

	hud.free()
	Settings.language = saved_lang
	Settings.science_view = saved_sci


func test_science_numbers_switch_units_rad_crew_and_toast() -> void:
	var saved_lang: String = Settings.language
	var saved_sci: bool = Settings.science_view
	Settings.language = "en"
	Settings.science_view = false

	var c := load_constants()
	var hud := _make_hud()
	var r := SimDayReportScript.new()
	r.day = 4
	r.generation_kwh = 120.0
	r.battery_kwh = 18.0
	r.battery_capacity_kwh = 20.0
	r.battery_percent = 90.0
	r.o2_kg = 50.0
	r.o2_days_left = 14.0
	r.co2_mmhg = 1.2
	r.water_kg = 180.0
	r.water_days_left = 25.0
	r.food_kg = 140.0
	r.food_days_left = 20.0
	r.days_to_go = 26
	r.highest_dose_msv = 45.0
	r.shelter_g_cm2 = 10.0
	r.storm_dose_if_now_msv = 68.1
	r.power_served = {"core": true}
	r.crew_reports = [{"dose_msv": 12.3, "sick": false, "sick_days": 0, "energy": 3}]

	hud.update_from_report(r)
	assert_false(hud.toast_line2.text.contains("kWh"), "Nominal toast omits kWh in Kid view")
	assert_false(hud.rad_gauge.visible, "RadGauge hidden in Kid view")
	assert_false(hud.crew_cards[0].dose_label.visible, "Crew dose hidden in Kid view")

	# CO2 toast in Kid view omits mmHg
	var r_co2 := SimDayReportScript.new()
	r_co2.day = 5
	r_co2.co2_mmhg = float(c.v("CO2_LIMIT_MMHG")) + 1.0
	r_co2.co2_high = true
	hud.update_from_report(r_co2)
	assert_false(hud.toast_line2.text.contains("mmHg"), "CO2 toast omits mmHg in Kid view")

	# Toggle Science numbers ON via pause menu button
	hud.update_from_report(r)
	hud._on_pause_science_pressed()
	assert_true(Settings.science_view, "Pause ScienceBtn toggles Settings.science_view ON")
	assert_true(hud.o2_gauge.visible, "O2 gauge appears in Science view")
	assert_true(hud.rad_gauge.visible, "Rad gauge appears in Science view")
	assert_true(hud.crew_cards[0].dose_label.visible, "Crew mSv dose appears in Science view")
	assert_true(hud.power_gauge.science_label.text.contains("kWh"), "Battery shows kWh in Science view")
	assert_true(hud.co2_gauge.science_label.text.contains("mmHg"), "Air shows mmHg in Science view")
	assert_true(hud.water_gauge.science_label.text.contains("kg"), "Water shows kg in Science view")
	assert_true(hud.food_gauge.science_label.text.contains("kg"), "Food shows kg in Science view")
	assert_true(hud.shelter_gauge.science_label.text.contains("g/cm²"), "Storm shows g/cm2 in Science view")
	assert_true(hud.shelter_gauge.science_label.text.contains("mSv"), "Storm shows mSv in Science view")
	assert_true(hud.rad_gauge.value_label.text.contains("mSv"), "Rad gauge shows mSv in Science view")

	# Science view toasts include real units
	hud.update_from_report(r)
	assert_true(hud.toast_line2.text.contains("kWh"), "Nominal toast includes kWh in Science view")
	hud.update_from_report(r_co2)
	assert_true(hud.toast_line2.text.contains("mmHg"), "CO2 toast includes mmHg in Science view")

	# Toggle OFF hides Science units again
	hud._on_pause_science_pressed()
	assert_false(Settings.science_view, "Second press toggles Science view OFF")
	assert_false(hud.rad_gauge.visible, "RadGauge hides when switched OFF")
	assert_false(hud.power_gauge.science_label.visible, "Battery science subtext hides when switched OFF")
	assert_false(hud.crew_cards[0].dose_label.visible, "Crew dose hides when switched OFF")

	hud.free()
	Settings.language = saved_lang
	Settings.science_view = saved_sci

