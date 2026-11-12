## MissionMap — four circular mission waypoints along a lunar path on a Moon surface background.
## Code-builds all child nodes; the .tscn attaches this script with Theme.tres applied.
class_name MissionMap
extends Control

signal mission_selected(mission_id: String)

const SimMissionsScript := preload("res://sim/sim_missions.gd")
const SafeArea := preload("res://ui/safe_area.gd")
const CardAlbumScene := preload("res://ui/CardAlbum.tscn")
const ICON_LOCK: Texture2D = preload("res://assets/icons/lock.svg")

## Moon background texture (darkened with a radial/edge vignette for contrast)
const MOON_TEX_PATH := "res://assets/textures/nasa/lroc_color_2k.jpg"

const MISSION_POSITIONS: Array = [
	Vector2(0.18, 0.54),   # M1 – mare west
	Vector2(0.39, 0.35),   # M2 – northern basin
	Vector2(0.61, 0.39),   # M3 – central crater rim
	Vector2(0.81, 0.53),   # M4 – south-east highlands
]
const MISSION_IDS: Array = ["M1", "M2", "M3", "M4"]
const BUTTON_SIZE: float = 88.0       # circular waypoint diameter (>= 64 px touch target)
const NODE_BOX_WIDTH: float = 196.0
const ICON_STAR: Texture2D = preload("res://assets/icons/star.svg")
const ICON_CHECK: Texture2D = preload("res://assets/icons/check.svg")
const MOON_TEX: Texture2D = preload("res://assets/textures/nasa/lroc_color_2k.jpg")
const STAR_EMPTY_COLOR := Color(0.34, 0.38, 0.46, 0.45)

var _bg: TextureRect
var _scrim: Control
var _path_line: Control
var _btns: Array = []
var _detail_panel: PanelContainer
var _detail_name: Label
var _detail_goal: Label
var _play_btn: Button
var _free_toggle: CheckButton
var _free_panel: PanelContainer
var _title_label: Label
var _score_label: Label
var _title_panel: PanelContainer
var _left_bar: HBoxContainer
var _rank_panel: PanelContainer
var _rank_label: Label
var _results_btn: Button
var _cards_btn: Button
var _card_album: CanvasLayer
var _results_layer: CanvasLayer
var _results_panel: PanelContainer
var _results_title_label: Label
var _results_grid: GridContainer
var _results_note_label: Label
var _results_copy_btn: Button
var _results_copied_label: Label
var _credit_label: Label

var _learning: LearningData = LearningData.new()
var _selected_id: String = ""
var _missions: SimMissions = null

var _style_open: StyleBoxFlat
var _style_won: StyleBoxFlat
var _style_locked: StyleBoxFlat
var _style_selected: StyleBoxFlat
var _style_lock_badge: StyleBoxFlat
var _style_pill: StyleBoxFlat
var _style_title: StyleBoxFlat
var _style_free_off: StyleBoxFlat
var _style_free_on: StyleBoxFlat
var _style_card: StyleBoxFlat
var _style_play_normal: StyleBoxFlat
var _style_play_hover: StyleBoxFlat
var _style_play_pressed: StyleBoxFlat

func _ready() -> void:
	_build_ui()
	if not resized.is_connected(_update_positions):
		resized.connect(_update_positions)
	if Settings != null:
		if Settings.has_signal("language_changed") and not Settings.language_changed.is_connected(_on_language_changed):
			Settings.language_changed.connect(_on_language_changed)
		if Settings.has_signal("card_collected") and not Settings.card_collected.is_connected(_on_card_collected):
			Settings.card_collected.connect(_on_card_collected)
	SafeArea.connect_resize(self, _update_positions)
	_refresh()

func _make_circle_style(fill: Color, border: Color, border_w: int = 3) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(999)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	return sb

func _make_panel_style(fill: Color, border: Color, radius: int, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	return sb

func _init_styles() -> void:
	if _style_open != null:
		return
	_style_open = _make_circle_style(Color("16233AF0"), UIColors.WATER, 3)
	_style_won = _make_circle_style(Color("142B22F0"), UIColors.OXYGEN, 3)
	_style_locked = _make_circle_style(Color("141821D8"), Color("3E475B"), 2)
	_style_selected = _make_circle_style(Color("1D2A42FA"), UIColors.POWER, 4)
	_style_lock_badge = _make_circle_style(Color("141821FA"), UIColors.POWER, 2)
	_style_lock_badge.set_content_margin_all(5)
	_style_lock_badge.shadow_size = 3
	_style_pill = _make_panel_style(Color("141821D8"), Color("2A3347"), 10, 12, 4)
	_style_pill.shadow_size = 4
	_style_title = _make_panel_style(Color("141821E5"), Color("33415C"), 12, 26, 8)
	_style_free_off = _make_panel_style(Color("141821E0"), Color("384560"), 12, 14, 4)
	_style_free_on = _make_panel_style(Color("14281EE8"), UIColors.OXYGEN, 12, 14, 4)
	_style_card = _make_panel_style(Color("141821EB"), Color("33415C"), 14, 24, 16)
	_style_play_normal = _make_panel_style(Color("2563A8"), UIColors.WATER, 10, 24, 12)
	_style_play_hover = _make_panel_style(Color("3178C6"), Color("7CC0FF"), 10, 24, 12)
	_style_play_pressed = _make_panel_style(Color("1B4B82"), UIColors.WATER, 10, 24, 12)

func _build_ui() -> void:
	if _bg != null:
		return
	_init_styles()

	# -- Moon surface background --
	_bg = TextureRect.new()
	_bg.name = "Background"
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.modulate = Color(0.42, 0.44, 0.50, 1.0)
	_bg.texture = MOON_TEX
	add_child(_bg)

	# -- Subtle top/bottom vignette scrim so headers & cards read cleanly --
	_scrim = _EdgeScrim.new()
	_scrim.name = "EdgeScrim"
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scrim)

	# -- Connecting trajectory path (under buttons, center-to-center) --
	_path_line = _PathLine.new()
	_path_line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_path_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_path_line)

	# -- Top header bar: Top-left Rank + Results, Centered title + score, Top-right Free play --
	_left_bar = HBoxContainer.new()
	_left_bar.name = "LeftTopBar"
	_left_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_left_bar.offset_left = 14
	_left_bar.offset_top = 14
	_left_bar.add_theme_constant_override("separation", 8)
	add_child(_left_bar)

	_rank_panel = PanelContainer.new()
	_rank_panel.name = "RankPanel"
	_rank_panel.add_theme_stylebox_override("panel", _style_title)
	_left_bar.add_child(_rank_panel)

	var rank_hbox := HBoxContainer.new()
	rank_hbox.add_theme_constant_override("separation", 6)
	_rank_panel.add_child(rank_hbox)

	var rank_star := TextureRect.new()
	rank_star.custom_minimum_size = Vector2(20, 20)
	rank_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rank_star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rank_star.texture = ICON_STAR
	rank_star.modulate = UIColors.POWER
	rank_hbox.add_child(rank_star)

	_rank_label = Label.new()
	_rank_label.name = "RankLabel"
	_rank_label.text = "Rank: Cadet"
	_rank_label.add_theme_font_size_override("font_size", 16)
	_rank_label.add_theme_color_override("font_color", UIColors.TEXT)
	rank_hbox.add_child(_rank_label)

	_results_btn = Button.new()
	_results_btn.name = "ResultsButton"
	_results_btn.text = tr("MAP_RESULTS")
	_results_btn.custom_minimum_size = Vector2(88, 64)
	_results_btn.focus_mode = Control.FOCUS_NONE
	_results_btn.add_theme_stylebox_override("normal", _style_free_off)
	_results_btn.add_theme_stylebox_override("hover", _style_play_hover)
	_results_btn.add_theme_stylebox_override("pressed", _style_play_pressed)
	_results_btn.add_theme_font_size_override("font_size", 15)
	_results_btn.add_theme_color_override("font_color", UIColors.TEXT)
	_results_btn.pressed.connect(open_results)
	_left_bar.add_child(_results_btn)

	_cards_btn = Button.new()
	_cards_btn.name = "CardsButton"
	_cards_btn.text = tr("CARD_ALBUM_COUNT").format({"n": 0, "total": _learning.total_cards_count()})
	_cards_btn.custom_minimum_size = Vector2(118, 64)
	_cards_btn.focus_mode = Control.FOCUS_NONE
	_cards_btn.add_theme_stylebox_override("normal", _style_free_off)
	_cards_btn.add_theme_stylebox_override("hover", _style_play_hover)
	_cards_btn.add_theme_stylebox_override("pressed", _style_play_pressed)
	_cards_btn.add_theme_font_size_override("font_size", 15)
	_cards_btn.add_theme_color_override("font_color", UIColors.TEXT)
	_cards_btn.pressed.connect(open_cards)
	_left_bar.add_child(_cards_btn)

	_title_panel = PanelContainer.new()
	_title_panel.name = "TitlePanel"
	_title_panel.add_theme_stylebox_override("panel", _style_title)
	_title_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title_panel.offset_top = 18
	add_child(_title_panel)

	var title_vbox := VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 2)
	_title_panel.add_child(title_vbox)

	_title_label = Label.new()
	_title_label.text = tr("MAP_TITLE")
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", UIColors.TEXT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_vbox.add_child(_title_label)

	_score_label = Label.new()
	_score_label.name = "TrainingScoreLabel"
	_score_label.visible = false
	_score_label.add_theme_font_size_override("font_size", 14)
	_score_label.add_theme_color_override("font_color", UIColors.POWER)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_vbox.add_child(_score_label)

	_free_panel = PanelContainer.new()
	_free_panel.name = "FreePlayPanel"
	_free_panel.add_theme_stylebox_override("panel", _style_free_off)
	_free_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_free_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_free_panel.offset_right = -18
	_free_panel.offset_top = 14
	add_child(_free_panel)

	_free_toggle = CheckButton.new()
	_free_toggle.name = "FreePlayToggle"
	_free_toggle.text = tr("MAP_FREE_PLAY")
	_free_toggle.custom_minimum_size = Vector2(180, 64)
	_free_toggle.flat = true
	_free_toggle.add_theme_font_size_override("font_size", 17)
	_free_toggle.add_theme_color_override("font_color", UIColors.TEXT)
	_free_toggle.button_pressed = Settings.free_play if Settings != null else false
	_free_toggle.toggled.connect(_on_free_play_toggled)
	_free_panel.add_child(_free_toggle)

	# -- Mission waypoint nodes --
	for i in range(MISSION_IDS.size()):
		var id: String = MISSION_IDS[i]
		var btn_root := VBoxContainer.new()
		btn_root.name = "MissionBtn_" + id
		btn_root.custom_minimum_size = Vector2(NODE_BOX_WIDTH, BUTTON_SIZE + 70.0)
		btn_root.add_theme_constant_override("separation", 6)
		btn_root.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(btn_root)

		var circle_center := CenterContainer.new()
		circle_center.name = "CircleCenter"
		circle_center.custom_minimum_size = Vector2(NODE_BOX_WIDTH, BUTTON_SIZE)
		circle_center.mouse_filter = Control.MOUSE_FILTER_PASS
		btn_root.add_child(circle_center)

		var circle := Button.new()
		circle.name = "Circle"
		circle.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		circle.focus_mode = Control.FOCUS_NONE
		circle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		circle_center.add_child(circle)

		var num_label := Label.new()
		num_label.name = "NumLabel"
		num_label.text = str(i + 1)
		num_label.add_theme_font_size_override("font_size", 30)
		num_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circle.add_child(num_label)

		var lock_badge := PanelContainer.new()
		lock_badge.name = "LockBadge"
		lock_badge.add_theme_stylebox_override("panel", _style_lock_badge)
		lock_badge.custom_minimum_size = Vector2(30, 30)
		lock_badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		lock_badge.offset_left = -28
		lock_badge.offset_top = -28
		lock_badge.offset_right = 4
		lock_badge.offset_bottom = 4
		lock_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_badge.visible = false
		circle.add_child(lock_badge)

		var lock_icon := TextureRect.new()
		lock_icon.name = "LockIcon"
		lock_icon.texture = ICON_LOCK
		lock_icon.custom_minimum_size = Vector2(16, 16)
		lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_icon.modulate = UIColors.POWER
		lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_badge.add_child(lock_icon)

		var caption_pill := PanelContainer.new()
		caption_pill.name = "CaptionPill"
		caption_pill.add_theme_stylebox_override("panel", _style_pill)
		caption_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		caption_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_root.add_child(caption_pill)

		var caption_vbox := VBoxContainer.new()
		caption_vbox.name = "CaptionVBox"
		caption_vbox.add_theme_constant_override("separation", 1)
		caption_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption_pill.add_child(caption_vbox)

		var stars_row := HBoxContainer.new()
		stars_row.name = "StarsRow"
		stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
		stars_row.add_theme_constant_override("separation", 4)
		stars_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption_vbox.add_child(stars_row)
		for _s in range(3):
			var star_icon := TextureRect.new()
			star_icon.custom_minimum_size = Vector2(15, 15)
			star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			star_icon.texture = ICON_STAR
			star_icon.modulate = STAR_EMPTY_COLOR
			star_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stars_row.add_child(star_icon)

		var name_lbl := Label.new()
		name_lbl.name = "NameLabel"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", UIColors.TEXT)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption_vbox.add_child(name_lbl)

		circle.pressed.connect(_on_mission_pressed.bind(id))
		_btns.append(btn_root)

	# -- Bottom mission briefing bar (centered horizontally, clean bottom margin) --
	_detail_panel = PanelContainer.new()
	_detail_panel.name = "DetailPanel"
	_detail_panel.add_theme_stylebox_override("panel", _style_card)
	_detail_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_detail_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_detail_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_detail_panel.custom_minimum_size = Vector2(640, 0)
	_detail_panel.offset_left = -320
	_detail_panel.offset_right = 320
	_detail_panel.offset_bottom = -28
	_detail_panel.visible = false
	add_child(_detail_panel)

	var detail_hbox := HBoxContainer.new()
	detail_hbox.add_theme_constant_override("separation", 24)
	detail_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_detail_panel.add_child(detail_hbox)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_vbox.add_theme_constant_override("separation", 4)
	detail_hbox.add_child(text_vbox)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 22)
	_detail_name.add_theme_color_override("font_color", UIColors.TEXT)
	text_vbox.add_child(_detail_name)

	_detail_goal = Label.new()
	_detail_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_goal.add_theme_font_size_override("font_size", 16)
	_detail_goal.add_theme_color_override("font_color", UIColors.MUTED)
	text_vbox.add_child(_detail_goal)

	_play_btn = Button.new()
	_play_btn.name = "PlayButton"
	_play_btn.text = tr("MAP_PLAY")
	_play_btn.custom_minimum_size = Vector2(168, 64)
	_play_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_play_btn.focus_mode = Control.FOCUS_NONE
	_play_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_play_btn.add_theme_font_size_override("font_size", 20)
	_play_btn.add_theme_color_override("font_color", UIColors.TEXT)
	_play_btn.add_theme_stylebox_override("normal", _style_play_normal)
	_play_btn.add_theme_stylebox_override("hover", _style_play_hover)
	_play_btn.add_theme_stylebox_override("pressed", _style_play_pressed)
	_play_btn.pressed.connect(_on_play_pressed)
	detail_hbox.add_child(_play_btn)

	# -- NASA SVS attribution (subtle readable caption at bottom-right) --
	_credit_label = Label.new()
	_credit_label.text = tr("MAP_CREDIT_MOON")
	_credit_label.add_theme_font_size_override("font_size", 11)
	_credit_label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.96, 0.55))
	_credit_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_credit_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_credit_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_credit_label.offset_right = -14
	_credit_label.offset_bottom = -6
	add_child(_credit_label)

func _apply_circle_style(circle: Button, sb: StyleBoxFlat) -> void:
	circle.add_theme_stylebox_override("normal", sb)
	circle.add_theme_stylebox_override("hover", sb)
	circle.add_theme_stylebox_override("pressed", sb)

func _pick_default_selected() -> void:
	if _selected_id != "" and Settings != null and Settings.is_mission_unlocked(_selected_id):
		return
	var best_open := "M1"
	if Settings != null:
		for id in MISSION_IDS:
			if Settings.is_mission_unlocked(id):
				best_open = id
	_selected_id = best_open

## Called whenever visibility changes or after stars update.
func _refresh() -> void:
	_build_ui()
	if _missions == null and Constants != null and Constants.sim != null:
		_missions = SimMissionsScript.new(Constants.sim)

	_pick_default_selected()
	_update_positions()

	for i in range(MISSION_IDS.size()):
		var id: String = MISSION_IDS[i]
		var btn_root: Control = _btns[i]
		var circle: Button = btn_root.get_node_or_null("CircleCenter/Circle")
		var num_lbl: Label = circle.get_node_or_null("NumLabel") if circle else null
		var lock_badge: Control = circle.get_node_or_null("LockBadge") if circle else null
		var stars_row: HBoxContainer = btn_root.get_node_or_null("CaptionPill/CaptionVBox/StarsRow")
		var name_lbl: Label = btn_root.get_node_or_null("CaptionPill/CaptionVBox/NameLabel")

		var unlocked: bool = Settings != null and Settings.is_mission_unlocked(id)
		var best_stars: int = int(Settings.mission_stars.get(id, 0)) if Settings != null else 0
		var is_selected: bool = (id == _selected_id) and unlocked

		if circle:
			# Keep button enabled so tapping a locked mission plays ui_error and shows lock message
			circle.disabled = false
			circle.modulate = Color.WHITE
			if not unlocked:
				_apply_circle_style(circle, _style_locked)
			elif is_selected:
				_apply_circle_style(circle, _style_selected)
			elif best_stars >= 1:
				_apply_circle_style(circle, _style_won)
			else:
				_apply_circle_style(circle, _style_open)
		if num_lbl:
			num_lbl.add_theme_color_override("font_color", UIColors.TEXT if unlocked else UIColors.MUTED)
		if lock_badge:
			lock_badge.visible = not unlocked

		if stars_row:
			var star_icons := stars_row.get_children()
			for s in range(3):
				var si: TextureRect = star_icons[s] as TextureRect if s < star_icons.size() else null
				if si:
					var filled: bool = s < best_stars
					si.modulate = UIColors.POWER if filled else STAR_EMPTY_COLOR

		if name_lbl:
			if _missions != null:
				var m := _missions.get_mission(id)
				name_lbl.text = tr(str(m.get("name_key", id))) if not m.is_empty() else id
			name_lbl.add_theme_color_override("font_color", UIColors.TEXT if unlocked else UIColors.MUTED)

	if _title_label:
		_title_label.text = tr("MAP_TITLE")
	if _rank_label:
		var rid: String = Settings.rank_id if Settings != null else "CADET"
		_rank_label.text = tr("MAP_RANK").format({"rank": _learning.rank_name(rid)})
	if _results_btn:
		_results_btn.text = tr("MAP_RESULTS")
	if _cards_btn:
		var card_n: int = Settings.collected_cards.size() if Settings != null else 0
		_cards_btn.text = tr("CARD_ALBUM_COUNT").format({"n": card_n, "total": _learning.total_cards_count()})
	if _score_label and Settings != null:
		var score: Dictionary = Settings.training_score()
		var answered: int = int(score.get("answered", 0))
		_score_label.visible = answered > 0
		if answered > 0:
			_score_label.text = tr("MAP_TRAINING_SCORE").format({
				"b": int(score.get("before_right", 0)),
				"a": int(score.get("after_right", 0)),
				"n": answered,
			})
	if _results_layer != null and _results_layer.visible:
		_refresh_results_modal()
	if _play_btn:
		_play_btn.text = tr("MAP_PLAY")
	if _free_toggle:
		var fp_on: bool = Settings.free_play if Settings != null else false
		_free_toggle.text = tr("MAP_FREE_PLAY")
		_free_toggle.set_pressed_no_signal(fp_on)
		if _free_panel:
			_free_panel.add_theme_stylebox_override("panel", _style_free_on if fp_on else _style_free_off)
	if _credit_label:
		_credit_label.text = tr("MAP_CREDIT_MOON")

	if _path_line != null:
		_path_line.queue_redraw()

	if _viewed_locked_id != "" and Settings != null and not Settings.is_mission_unlocked(_viewed_locked_id):
		_show_locked_detail(_viewed_locked_id)
	elif _selected_id != "" and Settings != null and Settings.is_mission_unlocked(_selected_id):
		_viewed_locked_id = ""
		_show_detail(_selected_id)

func _update_positions() -> void:
	var vp_size: Vector2 = size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		if is_inside_tree() and get_viewport() != null:
			vp_size = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		vp_size = Vector2(1280.0, 720.0)
	var insets: Dictionary = SafeArea.get_insets(self)
	var l: float = float(insets.get("left", 0))
	var t: float = float(insets.get("top", 0))
	var r: float = float(insets.get("right", 0))
	var b: float = float(insets.get("bottom", 0))
	var is_narrow: bool = vp_size.x < 780.0
	if _title_panel != null:
		if is_narrow:
			_title_panel.anchor_left = 0.0
			_title_panel.anchor_right = 0.0
			_title_panel.grow_horizontal = Control.GROW_DIRECTION_END
			_title_panel.offset_left = 12.0 + l
			_title_panel.offset_right = 12.0 + l
			_title_panel.offset_top = 12.0 + t
		else:
			_title_panel.anchor_left = 0.5
			_title_panel.anchor_right = 0.5
			_title_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
			_title_panel.offset_left = 0.0
			_title_panel.offset_right = 0.0
			_title_panel.offset_top = 14.0 + t
	if _title_label != null:
		_title_label.add_theme_font_size_override("font_size", 19 if is_narrow else 26)
	if _score_label != null:
		_score_label.custom_minimum_size = Vector2(180.0 if is_narrow else 0.0, 0.0)
		_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if is_narrow else TextServer.AUTOWRAP_OFF
	if _free_panel != null:
		_free_panel.offset_right = -12.0 - r
		_free_panel.offset_top = 12.0 + t
	if _free_toggle != null:
		_free_toggle.custom_minimum_size = Vector2(124.0 if is_narrow else 180.0, 64.0)
	if _left_bar != null:
		_left_bar.offset_left = 12.0 + l
		var title_w: float = _title_panel.get_combined_minimum_size().x if _title_panel != null else 300.0
		var left_w: float = _left_bar.get_combined_minimum_size().x
		var overlap_title: bool = (12.0 + l + left_w + 12.0) > (vp_size.x * 0.5 - title_w * 0.5)
		if is_narrow or overlap_title:
			var title_h: float = _title_panel.get_combined_minimum_size().y if _title_panel != null else 72.0
			_left_bar.offset_top = maxf(96.0 + t, 14.0 + t + title_h + 8.0)
		else:
			_left_bar.offset_top = 14.0 + t
	if _results_panel != null:
		var max_rw: float = maxf(300.0, vp_size.x - l - r - 28.0)
		_results_panel.custom_minimum_size = Vector2(minf(520.0, max_rw), 0.0)
	if _detail_panel != null:
		_detail_panel.offset_bottom = -28.0 - b
	if _credit_label != null:
		_credit_label.offset_right = -14.0 - r
		_credit_label.offset_bottom = -6.0 - b
	for i in range(_btns.size()):
		var btn_root: Control = _btns[i]
		var frac: Vector2 = MISSION_POSITIONS[i]
		var centre: Vector2 = frac * vp_size
		var min_x: float = l + NODE_BOX_WIDTH * 0.5 + 4.0
		var max_x: float = vp_size.x - r - NODE_BOX_WIDTH * 0.5 - 4.0
		if max_x >= min_x:
			centre.x = clampf(centre.x, min_x, max_x)
		# Horizontally center the NODE_BOX_WIDTH container and align Circle Center with `centre`
		btn_root.position = centre - Vector2(NODE_BOX_WIDTH * 0.5, BUTTON_SIZE * 0.5)
	if _path_line != null:
		_path_line.queue_redraw()
	if _scrim != null:
		_scrim.queue_redraw()

var _viewed_locked_id: String = ""

func _show_locked_detail(id: String) -> void:
	if _missions != null:
		var m := _missions.get_mission(id)
		if _detail_name:
			_detail_name.text = tr(str(m.get("name_key", id))) if not m.is_empty() else id
			_detail_name.add_theme_color_override("font_color", UIColors.TEXT)
	if _detail_goal:
		_detail_goal.text = tr("MAP_LOCKED")
		_detail_goal.add_theme_color_override("font_color", UIColors.POWER)
	if _play_btn:
		_play_btn.visible = false
	if _detail_panel:
		_detail_panel.visible = true

func _on_mission_pressed(id: String) -> void:
	_build_ui()
	if _missions == null and Constants != null and Constants.sim != null:
		_missions = SimMissionsScript.new(Constants.sim)
	var unlocked: bool = Settings != null and Settings.is_mission_unlocked(id)
	if not unlocked:
		if Audio != null:
			Audio.play("ui_error")
		_viewed_locked_id = id
		_show_locked_detail(id)
		return
	if Audio != null:
		Audio.play("ui_click")
	_viewed_locked_id = ""
	_selected_id = id
	_refresh()

func _show_detail(id: String) -> void:
	if _missions == null:
		return
	var m := _missions.get_mission(id)
	if m.is_empty():
		return
	var days_id: String = str(m.get("days_id", "MISSION_DAYS"))
	var days_val: int = int(Constants.v(days_id)) if Constants != null and Constants.has(days_id) else 30
	var night_days: int = int(Constants.v("NIGHT_DAYS")) if Constants != null and Constants.has("NIGHT_DAYS") else 14
	var goal_key: String = str(m.get("goal_key", ""))
	var goal_text: String = tr(goal_key).format({"days": days_val, "night": night_days}) if goal_key != "" else ""
	if _detail_name:
		_detail_name.text = tr(str(m.get("name_key", id)))
		_detail_name.add_theme_color_override("font_color", UIColors.TEXT)
	if _detail_goal:
		_detail_goal.text = goal_text
		_detail_goal.add_theme_color_override("font_color", Color("D3DAE6"))
	if _play_btn:
		_play_btn.visible = true
	if _detail_panel:
		_detail_panel.visible = true

func _on_play_pressed() -> void:
	if _selected_id == "":
		return
	if Audio != null:
		Audio.play("ui_confirm")
	if Settings != null:
		Settings.current_mission_id = _selected_id
	mission_selected.emit(_selected_id)

func _on_free_play_toggled(pressed: bool) -> void:
	if Settings != null:
		Settings.free_play = pressed
	_refresh()

## Called from main.gd each time the map is shown.
func refresh_map() -> void:
	_refresh()

func _on_language_changed(_lang: String) -> void:
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		if _results_layer != null:
			_results_layer.visible = false


func _ensure_results_modal() -> void:
	if _results_layer != null:
		return
	_results_layer = CanvasLayer.new()
	_results_layer.name = "ResultsLayer"
	_results_layer.layer = 18
	_results_layer.visible = false
	add_child(_results_layer)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.025, 0.04, 0.65)
	backdrop.gui_input.connect(_on_results_backdrop_input)
	_results_layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_results_layer.add_child(center)

	_results_panel = PanelContainer.new()
	_results_panel.name = "ResultsPanel"
	_results_panel.add_theme_stylebox_override("panel", _style_card)
	var vp_x: float = get_viewport_rect().size.x if (is_inside_tree() and get_viewport() != null) else 1280.0
	_results_panel.custom_minimum_size = Vector2(minf(520.0, maxf(300.0, vp_x - 28.0)), 0.0)
	center.add_child(_results_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_results_panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	_results_title_label = Label.new()
	_results_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_results_title_label.add_theme_font_size_override("font_size", 22)
	_results_title_label.add_theme_color_override("font_color", UIColors.TEXT)
	header.add_child(_results_title_label)

	var close_btn := Button.new()
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.text = "×"
	close_btn.pressed.connect(close_results)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	_results_grid = GridContainer.new()
	_results_grid.columns = 4
	_results_grid.add_theme_constant_override("h_separation", 16)
	_results_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(_results_grid)

	_results_note_label = Label.new()
	_results_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_results_note_label.add_theme_font_size_override("font_size", 14)
	_results_note_label.add_theme_color_override("font_color", UIColors.MUTED)
	vbox.add_child(_results_note_label)

	var copy_row := HBoxContainer.new()
	copy_row.add_theme_constant_override("separation", 12)
	vbox.add_child(copy_row)

	_results_copy_btn = Button.new()
	_results_copy_btn.custom_minimum_size = Vector2(140, 64)
	_results_copy_btn.focus_mode = Control.FOCUS_NONE
	_results_copy_btn.add_theme_stylebox_override("normal", _style_play_normal)
	_results_copy_btn.add_theme_stylebox_override("hover", _style_play_hover)
	_results_copy_btn.add_theme_stylebox_override("pressed", _style_play_pressed)
	_results_copy_btn.add_theme_color_override("font_color", UIColors.TEXT)
	_results_copy_btn.pressed.connect(copy_results_summary)
	copy_row.add_child(_results_copy_btn)

	_results_copied_label = Label.new()
	_results_copied_label.visible = false
	_results_copied_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_results_copied_label.add_theme_font_size_override("font_size", 16)
	_results_copied_label.add_theme_color_override("font_color", UIColors.OXYGEN)
	copy_row.add_child(_results_copied_label)


func _on_results_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_results()


func open_results() -> void:
	if Audio != null:
		Audio.play("ui_click")
	_ensure_results_modal()
	if _results_copied_label != null:
		_results_copied_label.visible = false
	_refresh_results_modal()
	_results_layer.visible = true


func close_results() -> void:
	if Audio != null:
		Audio.play("ui_click")
	if _results_layer != null:
		_results_layer.visible = false


func open_cards() -> void:
	if Audio != null:
		Audio.play("ui_click")
	if _card_album == null:
		_card_album = CardAlbumScene.instantiate()
		add_child(_card_album)
	if _card_album != null and _card_album.has_method("open_album"):
		_card_album.call("open_album")


func close_cards() -> void:
	if _card_album != null and _card_album.has_method("close_album"):
		_card_album.call("close_album")


func _on_card_collected(_fid: String) -> void:
	_refresh()


func _refresh_results_modal() -> void:
	_ensure_results_modal()
	_results_title_label.text = tr("RESULTS_TITLE")
	_results_note_label.text = tr("RESULTS_NOTE")
	_results_copy_btn.text = tr("RESULTS_COPY")
	if _results_copied_label != null:
		_results_copied_label.text = tr("RESULTS_COPIED")

	for child in _results_grid.get_children():
		_results_grid.remove_child(child)
		child.queue_free()

	for col_key in ["RESULTS_COL_MISSION", "RESULTS_COL_BEFORE", "RESULTS_COL_AFTER", "RESULTS_COL_STARS"]:
		var hdr := Label.new()
		hdr.text = tr(col_key)
		hdr.add_theme_font_size_override("font_size", 15)
		hdr.add_theme_color_override("font_color", UIColors.MUTED)
		_results_grid.add_child(hdr)

	for mid in MISSION_IDS:
		var m_lbl := Label.new()
		m_lbl.text = mid
		m_lbl.add_theme_font_size_override("font_size", 17)
		m_lbl.add_theme_color_override("font_color", UIColors.TEXT)
		m_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_results_grid.add_child(m_lbl)

		var correct_idx: int = int(_learning.question(mid).get("correct", -1))
		var before_idx: int = Settings.get_before_answer(mid) if Settings != null else -1
		var after_idx: int = Settings.get_after_answer(mid) if Settings != null else -1
		var stars: int = int(Settings.mission_stars.get(mid, 0)) if Settings != null else 0

		_results_grid.add_child(_make_status_cell(before_idx, correct_idx))
		_results_grid.add_child(_make_status_cell(after_idx, correct_idx))

		var star_row := HBoxContainer.new()
		star_row.add_theme_constant_override("separation", 3)
		for i in range(3):
			var st := TextureRect.new()
			st.custom_minimum_size = Vector2(18, 18)
			st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			st.texture = ICON_STAR
			st.modulate = UIColors.POWER if i < stars else STAR_EMPTY_COLOR
			star_row.add_child(st)
		_results_grid.add_child(star_row)


func _make_status_cell(answer_idx: int, correct_idx: int) -> Control:
	var box := HBoxContainer.new()
	box.custom_minimum_size = Vector2(44, 24)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	if answer_idx < 0 or correct_idx < 0:
		var dash := Label.new()
		dash.text = "–"
		dash.add_theme_font_size_override("font_size", 18)
		dash.add_theme_color_override("font_color", UIColors.MUTED)
		box.add_child(dash)
	elif answer_idx == correct_idx:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = ICON_CHECK
		icon.modulate = UIColors.OXYGEN
		box.add_child(icon)
	else:
		var wrong := Label.new()
		wrong.text = "×"
		wrong.add_theme_font_size_override("font_size", 20)
		wrong.add_theme_color_override("font_color", Color("#E04848"))
		box.add_child(wrong)
	return box


func build_results_summary() -> String:
	var rid: String = Settings.rank_id if Settings != null else "CADET"
	var score: Dictionary = Settings.training_score() if Settings != null else {"before_right": 0, "after_right": 0, "answered": 0}
	var parts: Array[String] = []
	for mid in MISSION_IDS:
		var correct_idx: int = int(_learning.question(mid).get("correct", -1))
		var b_idx: int = Settings.get_before_answer(mid) if Settings != null else -1
		var a_idx: int = Settings.get_after_answer(mid) if Settings != null else -1
		var stars: int = int(Settings.mission_stars.get(mid, 0)) if Settings != null else 0
		var b_mark: String = "-" if b_idx < 0 else ("Y" if b_idx == correct_idx else "X")
		var a_mark: String = "-" if a_idx < 0 else ("Y" if a_idx == correct_idx else "X")
		parts.append("%s %s->%s %d/3" % [mid, b_mark, a_mark, stars])
	return "Rank: %s | Before %d/%d -> After %d/%d | %s" % [
		_learning.rank_name(rid),
		int(score.get("before_right", 0)),
		int(score.get("answered", 0)),
		int(score.get("after_right", 0)),
		int(score.get("answered", 0)),
		"; ".join(parts),
	]


func copy_results_summary() -> void:
	if Audio != null:
		Audio.play("ui_confirm")
	DisplayServer.clipboard_set(build_results_summary())
	if _results_copied_label != null:
		_results_copied_label.text = tr("RESULTS_COPIED")
		_results_copied_label.visible = true

# ---- Helper: subtle top and bottom darkening gradient for readability (no hard seam) ----
class _EdgeScrim extends Control:
	func _draw() -> void:
		var vp: Vector2 = size
		if vp.x <= 0.0 or vp.y <= 0.0:
			return
		var top_h: float = minf(120.0, vp.y * 0.20)
		var bot_h: float = minf(180.0, vp.y * 0.28)
		var dark := Color(0.03, 0.04, 0.07, 0.52)
		var clear := Color(0.03, 0.04, 0.07, 0.0)
		draw_polygon(
			PackedVector2Array([Vector2(0, 0), Vector2(vp.x, 0), Vector2(vp.x, top_h), Vector2(0, top_h)]),
			PackedColorArray([dark, dark, clear, clear])
		)
		draw_polygon(
			PackedVector2Array([Vector2(0, vp.y - bot_h), Vector2(vp.x, vp.y - bot_h), Vector2(vp.x, vp.y), Vector2(0, vp.y)]),
			PackedColorArray([clear, clear, dark, dark])
		)

# ---- Helper: draws smooth trajectory path connecting waypoint centers ----
class _PathLine extends Control:
	func _draw() -> void:
		var vp: Vector2 = size
		if vp.x <= 0.0 or vp.y <= 0.0:
			vp = get_viewport_rect().size if is_inside_tree() and get_viewport() != null else Vector2(1280.0, 720.0)
		var pts: Array = []
		for frac in MissionMap.MISSION_POSITIONS:
			pts.append(frac * vp)
		for i in range(pts.size() - 1):
			var next_id: String = MissionMap.MISSION_IDS[i + 1]
			var seg_open: bool = Settings != null and Settings.is_mission_unlocked(next_id)
			var glow_col := Color(0.04, 0.07, 0.12, 0.75)
			var dash_col := Color(0.27, 0.70, 0.35, 0.75) if seg_open else Color(0.65, 0.74, 0.90, 0.42)
			draw_line(pts[i], pts[i + 1], glow_col, 7.0, true)
			draw_dashed_line(pts[i], pts[i + 1], dash_col, 3.0, 12.0, true)
