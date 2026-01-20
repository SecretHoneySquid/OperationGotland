extends CanvasLayer

@export var build_controller_path := NodePath("../BuildController")
@export var game_controller_path := NodePath("../GameController")
@export var selection_controller_path := NodePath("../SelectionController")
@export var bombardment_controller_path := NodePath("../BombardmentController")
@export var battalion_controller_path := NodePath("../BattalionController")

var _controller: BuildController
var _game_controller: GameController
var _selection_controller: SelectionController
var _bombardment_controller: BombardmentController
var _status_label: Label
var _credits_label: Label
var _income_label: Label
var _prod_label: Label
var _infantry_status_label: Label
var _queue_label: Label
var _rally_label: Label
var _queue_button: Button
var _rally_button: TextureButton
var _barracks_panel: VBoxContainer
var _barracks_name_label: Label
var _selected_barracks: Building
var _factory_panel: VBoxContainer
var _factory_name_label: Label
var _factory_type: OptionButton
var _factory_queue_button: Button
var _factory_type_ids: Array[String] = []
var _factory_type_index := {}
var _selected_factory: Building
var _factory_updating := false
var _airfield_panel: VBoxContainer
var _airfield_name_label: Label
var _airfield_f35_button: Button
var _airfield_uav_button: TextureButton
var _airfield_command_button: Button
var _selected_airfield: Building

# Airforce Command UI
var _airforce_panel: VBoxContainer
var _airforce_title_label: Label
var _airforce_aircraft_count_label: Label
var _airforce_status_label: Label
var _airforce_fuel_label: Label
var _airforce_defend_button: Button
var _airforce_superiority_button: Button
var _airforce_back_button: Button
var _airforce_mode_active := false  # True when showing airforce panel instead of airfield panel
var _himars_button: TextureButton
var _factory_himars_button: TextureButton
var _bombardment_panel: VBoxContainer
var _bombardment_button: Button
var _cancel_bombardment_button: Button
var _selected_units: Array[Unit] = []
var _tooltip_panel: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: Label
var _tooltip_strong: Label
var _tooltip_weak: Label

# Battalion UI
var _battalion_controller: BattalionController
var _battalion_buttons: Array[Button] = []
var _battalion_selected_panel: VBoxContainer
var _battalion_name_label: Label
var _battalion_strength_label: Label
var _battalion_state_label: Label
var _battalion_withdraw_button: Button
var _selected_battalion: Battalion = null
var _battalion_placement_preview: Node2D = null

func _ready() -> void:
	_controller = get_node_or_null(build_controller_path) as BuildController
	_game_controller = get_node_or_null(game_controller_path) as GameController
	_selection_controller = get_node_or_null(selection_controller_path) as SelectionController
	_bombardment_controller = get_node_or_null(bombardment_controller_path) as BombardmentController
	_battalion_controller = get_node_or_null(battalion_controller_path) as BattalionController
	_build_ui()
	if _controller != null:
		_controller.build_mode_changed.connect(_on_build_mode_changed)
		_on_build_mode_changed(_controller.get_active_build_id())
	if _selection_controller != null:
		_selection_controller.building_selected.connect(_on_building_selected)
		_selection_controller.units_selected.connect(_on_units_selected)
	if _battalion_controller != null:
		_battalion_controller.battalion_selected.connect(_on_battalion_selected)
		_battalion_controller.placement_started.connect(_on_battalion_placement_started)
		_battalion_controller.placement_cancelled.connect(_on_battalion_placement_cancelled)

func _process(_delta: float) -> void:
	if _credits_label != null:
		_credits_label.text = "Credits: %d" % GameState.p1_credits
	if _income_label != null:
		_income_label.text = "Income/s: %.1f" % GameState.p1_income_rate
	if _prod_label != null:
		_prod_label.text = "Inf Prod: %.2f (Barracks: %d)\nVeh Prod: %.2f (Factories: %d)\nAir Prod: %.2f (Airfields: %d)" % [
			GameState.p1_infantry_prod,
			GameState.p1_barracks,
			GameState.p1_vehicle_prod,
			GameState.p1_factory,
			GameState.p1_aircraft_prod,
			GameState.p1_airfield
		]
	if _infantry_status_label != null:
		var eta_text := "--"
		if GameState.p1_infantry_prod > 0.0:
			if GameState.p1_infantry_eta <= 0.0:
				eta_text = "ready"
			else:
				eta_text = "%.1fs" % GameState.p1_infantry_eta
		var blocked := ""
		if GameState.p1_infantry_pool >= 1.0 and _game_controller != null:
			if GameState.p1_credits < _game_controller.infantry_unit_cost:
				blocked = " (need $%d)" % _game_controller.infantry_unit_cost
		_infantry_status_label.text = "Inf Pool: %.2f  Next: %s%s" % [
			GameState.p1_infantry_pool,
			eta_text,
			blocked
		]
	if _queue_label != null:
		_queue_label.text = "Factory Queue: %d" % GameState.p1_factory_queue
	if _rally_label != null and _game_controller != null:
		var rally := _game_controller.get_rally_point("p1")
		_rally_label.text = "Rally: (%.0f, %.0f)" % [rally.x, rally.y]
	if _queue_button != null and _game_controller != null:
		var queue_cost := _game_controller.vehicle_unit_cost
		var label := "Queue Vehicle ($%d)" % queue_cost
		if _selected_factory != null and is_instance_valid(_selected_factory):
			var type_name := _selected_factory.vehicle_production_type
			var type_label := type_name
			if _factory_type != null:
				var type_index := int(_factory_type_index.get(type_name, -1))
				if type_index >= 0:
					type_label = _factory_type.get_item_text(type_index)
			label = "Queue %s ($%d)" % [type_label, queue_cost]
		_queue_button.text = label
		_queue_button.disabled = (
			GameState.p1_factory <= 0
			or GameState.p1_credits < _game_controller.vehicle_unit_cost
			or GameState.p1_factory_queue >= _game_controller.factory_queue_max
		)
	if _factory_himars_button != null and _game_controller != null:
		_factory_himars_button.disabled = (
			GameState.p1_factory <= 0
			or GameState.p1_credits < GameBalance.HIMARS_UNIT_COST
			or GameState.p1_factory_queue >= _game_controller.factory_queue_max
		)
	if _airfield_uav_button != null:
		_airfield_uav_button.disabled = (
			GameState.p1_airfield <= 0
			or GameState.p1_credits < 100
		)
	if _rally_button != null and _game_controller != null:
		# Visual feedback via modulate color when in rally mode
		if _game_controller.is_rally_mode("p1"):
			_rally_button.modulate = Color(0.5, 1.0, 0.5)  # Green tint when active
		else:
			_rally_button.modulate = Color.WHITE
	if _barracks_panel != null:
		_update_barracks_panel()
	if _factory_panel != null:
		_update_factory_panel()
	if _airfield_panel != null:
		_update_airfield_panel()
	if _airforce_panel != null:
		_update_airforce_panel()
	if _bombardment_panel != null:
		_update_bombardment_panel()

func _build_ui() -> void:
	# LEFT PANEL - Buildings only
	var left_panel := PanelContainer.new()
	left_panel.name = "BuildingsPanel"
	left_panel.anchor_left = 0.0
	left_panel.anchor_top = 0.0
	left_panel.anchor_right = 0.0
	left_panel.anchor_bottom = 1.0
	left_panel.offset_left = 12.0
	left_panel.offset_top = 110.0
	left_panel.offset_right = 220.0
	left_panel.offset_bottom = -12.0
	add_child(left_panel)

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 10)
	left_margin.add_theme_constant_override("margin_right", 10)
	left_margin.add_theme_constant_override("margin_top", 10)
	left_margin.add_theme_constant_override("margin_bottom", 10)
	left_panel.add_child(left_margin)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_margin.add_child(left_scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	left_scroll.add_child(vbox)

	# BOTTOM PANEL - Units, HIMARS, Aircraft
	var bottom_panel := PanelContainer.new()
	bottom_panel.name = "UnitsPanel"
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 232.0
	bottom_panel.offset_top = -280.0
	bottom_panel.offset_right = -12.0
	bottom_panel.offset_bottom = -12.0
	add_child(bottom_panel)

	var bottom_margin := MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 10)
	bottom_margin.add_theme_constant_override("margin_right", 10)
	bottom_margin.add_theme_constant_override("margin_top", 10)
	bottom_margin.add_theme_constant_override("margin_bottom", 10)
	bottom_panel.add_child(bottom_margin)

	var bottom_scroll := ScrollContainer.new()
	bottom_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	bottom_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bottom_margin.add_child(bottom_scroll)

	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_theme_constant_override("separation", 15)
	bottom_scroll.add_child(bottom_hbox)

	# ========== LEFT PANEL CONTENT (Buildings) ==========
	var title := Label.new()
	title.text = "Build Menu"
	vbox.add_child(title)

	_credits_label = Label.new()
	_credits_label.text = "Credits: %d" % GameState.p1_credits
	vbox.add_child(_credits_label)

	_income_label = Label.new()
	_income_label.text = "Income/s: %.1f" % GameState.p1_income_rate
	vbox.add_child(_income_label)

	_prod_label = Label.new()
	_prod_label.text = "Inf Prod: %.2f (Barracks: %d)\nVeh Prod: %.2f (Factories: %d)\nAir Prod: %.2f (Airfields: %d)" % [
		GameState.p1_infantry_prod,
		GameState.p1_barracks,
		GameState.p1_vehicle_prod,
		GameState.p1_factory,
		GameState.p1_aircraft_prod,
		GameState.p1_airfield
	]
	vbox.add_child(_prod_label)

	_infantry_status_label = Label.new()
	_infantry_status_label.text = "Inf Pool: 0.00  Next: --"
	vbox.add_child(_infantry_status_label)

	if _controller == null:
		var error_label := Label.new()
		error_label.text = "BuildController not found."
		vbox.add_child(error_label)
		return

	var options: Array = _controller.get_build_options()
	for option in options:
		if typeof(option) != TYPE_DICTIONARY:
			continue
		var build_id := str(option.get("id", ""))
		var label := "%s ($%d)" % [
			str(option.get("name", build_id)),
			int(option.get("cost", 0))
		]
		var button := Button.new()
		button.text = label
		button.pressed.connect(func():
			_controller.start_placement(build_id)
		)
		vbox.add_child(button)

	var cancel := Button.new()
	cancel.text = "Cancel Placement"
	cancel.pressed.connect(func():
		if _controller != null:
			_controller.cancel_placement()
	)
	vbox.add_child(cancel)

	_status_label = Label.new()
	_status_label.text = "Placement: none"
	vbox.add_child(_status_label)

	# ========== BOTTOM PANEL CONTENT (Units/Controls) ==========

	# Factory Panel
	_factory_panel = VBoxContainer.new()
	_factory_panel.visible = false
	_factory_panel.add_theme_constant_override("separation", 6)
	_factory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(_factory_panel)

	var factory_title := Label.new()
	factory_title.text = "Factory Control"
	_factory_panel.add_child(factory_title)

	_factory_name_label = Label.new()
	_factory_name_label.text = "No factory selected"
	_factory_panel.add_child(_factory_name_label)

	_queue_label = Label.new()
	_queue_label.text = "Factory Queue: %d" % GameState.p1_factory_queue
	_factory_panel.add_child(_queue_label)

	_factory_type = OptionButton.new()
	_factory_panel.add_child(_factory_type)
	_factory_type.item_selected.connect(func(index: int):
		if _factory_updating:
			return
		if _selected_factory == null or not is_instance_valid(_selected_factory):
			return
		if index < 0 or index >= _factory_type_ids.size():
			return
		_selected_factory.vehicle_production_type = _factory_type_ids[index]
	)

	_queue_button = Button.new()
	if _game_controller != null:
		_queue_button.text = "Queue Vehicle ($%d)" % _game_controller.vehicle_unit_cost
	else:
		_queue_button.text = "Queue Vehicle"
	_queue_button.pressed.connect(func():
		if _game_controller != null:
			if _controller != null:
				_controller.cancel_placement()
			if _selected_factory != null and is_instance_valid(_selected_factory):
				_game_controller.queue_vehicle("p1", _selected_factory.vehicle_production_type, _selected_factory)
			else:
				_game_controller.queue_vehicle("p1")
	)
	_factory_panel.add_child(_queue_button)

	_rally_label = Label.new()
	_rally_label.text = "Rally: (0, 0)"
	_factory_panel.add_child(_rally_label)

	# HBox for HIMARS and Rally buttons side-by-side
	var buttons_hbox := HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 10)
	buttons_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_factory_panel.add_child(buttons_hbox)

	# HIMARS Icon Button (64x64 square)
	var himars_container = AspectRatioContainer.new()
	himars_container.ratio = 1.0
	himars_container.custom_minimum_size = Vector2(64, 64)
	himars_container.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_factory_himars_button = TextureButton.new()
	_factory_himars_button.stretch_mode = TextureButton.STRETCH_SCALE
	_factory_himars_button.ignore_texture_size = true
	var himars_icon := load("res://assets/models/HIMARS/ICON_HIMARS.jpg")
	if himars_icon != null:
		_factory_himars_button.texture_normal = himars_icon
	himars_container.add_child(_factory_himars_button)
	_factory_himars_button.pressed.connect(func():
		if _game_controller != null:
			if _controller != null:
				_controller.cancel_placement()
			if _selected_factory != null and is_instance_valid(_selected_factory):
				_game_controller.queue_himars("p1", _selected_factory)
			else:
				_game_controller.queue_himars("p1")
	)
	_factory_himars_button.mouse_entered.connect(func():
		_show_tooltip(
			_factory_himars_button,
			"HIMARS ($%d)" % GameBalance.HIMARS_UNIT_COST,
			"Long-range rocket artillery system. Launches devastating ATACMS ballistic missiles at distant targets.",
			"",  # Strong vs - empty for now
			""   # Weak vs - empty for now
		)
	)
	_factory_himars_button.mouse_exited.connect(_hide_tooltip)
	buttons_hbox.add_child(himars_container)

	# Rally Point Icon Button (64x64 square)
	var rally_container = AspectRatioContainer.new()
	rally_container.ratio = 1.0
	rally_container.custom_minimum_size = Vector2(64, 64)
	rally_container.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_rally_button = TextureButton.new()
	_rally_button.stretch_mode = TextureButton.STRETCH_SCALE
	_rally_button.ignore_texture_size = true
	# Create a simple rally point icon (white flag/target on dark background)
	var rally_image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	rally_image.fill(Color(0.2, 0.2, 0.2, 1.0))  # Dark gray background
	# Draw a simple flag/target pattern
	for y in range(16, 48):
		for x in range(28, 36):
			rally_image.set_pixel(x, y, Color.WHITE)  # Vertical pole
	for y in range(16, 32):
		for x in range(36, 52):
			rally_image.set_pixel(x, y, Color(0.9, 0.9, 0.2, 1.0))  # Yellow flag
	var rally_texture := ImageTexture.create_from_image(rally_image)
	_rally_button.texture_normal = rally_texture
	rally_container.add_child(_rally_button)
	_rally_button.pressed.connect(func():
		if _game_controller != null:
			if _controller != null:
				_controller.cancel_placement()
			_game_controller.start_rally_mode("p1")
	)
	_rally_button.mouse_entered.connect(func():
		_show_tooltip(
			_rally_button,
			"Set Rally Point",
			"Click to set where newly built vehicles will move to after production.",
			"",
			""
		)
	)
	_rally_button.mouse_exited.connect(_hide_tooltip)
	buttons_hbox.add_child(rally_container)

	_setup_factory_options()

	# Barracks Panel - now contains battalion buttons
	_barracks_panel = VBoxContainer.new()
	_barracks_panel.visible = false
	_barracks_panel.add_theme_constant_override("separation", 6)
	_barracks_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(_barracks_panel)

	var barracks_title := Label.new()
	barracks_title.text = "Barracks - Battalions"
	_barracks_panel.add_child(barracks_title)

	_barracks_name_label = Label.new()
	_barracks_name_label.text = "No barracks selected"
	_barracks_panel.add_child(_barracks_name_label)

	# Battalion buttons (1-4) inside barracks panel
	var battalion_buttons_hbox := HBoxContainer.new()
	battalion_buttons_hbox.add_theme_constant_override("separation", 8)
	_barracks_panel.add_child(battalion_buttons_hbox)

	var battalion_types := [
		{"type": Battalion.Type.ASSAULT, "name": "Assault", "desc": "Advances aggressively, takes ground"},
		{"type": Battalion.Type.DEFENSE, "name": "Defense", "desc": "Holds position, digs in"},
		{"type": Battalion.Type.CONTROL, "name": "Control", "desc": "Spreads out, patrols area"},
		{"type": Battalion.Type.AIR_DEFENSE, "name": "Air Defense", "desc": "Provides AA coverage"}
	]

	for i in range(battalion_types.size()):
		var btype: Dictionary = battalion_types[i]
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.custom_minimum_size = Vector2(50, 50)
		var type_val: Battalion.Type = btype["type"]
		var cost := Battalion.get_cost_for_type(type_val)
		btn.tooltip_text = "%s Battalion ($%d)\n%s" % [btype["name"], cost, btype["desc"]]
		btn.pressed.connect(_on_battalion_button_pressed.bind(type_val))
		battalion_buttons_hbox.add_child(btn)
		_battalion_buttons.append(btn)

	# Airfield Panel
	_airfield_panel = VBoxContainer.new()
	_airfield_panel.visible = false
	_airfield_panel.add_theme_constant_override("separation", 6)
	_airfield_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(_airfield_panel)

	var airfield_title := Label.new()
	airfield_title.text = "Airfield Control"
	_airfield_panel.add_child(airfield_title)

	_airfield_name_label = Label.new()
	_airfield_name_label.text = "No airfield selected"
	_airfield_panel.add_child(_airfield_name_label)

	_airfield_f35_button = Button.new()
	_airfield_f35_button.text = "Upgrade Aircraft"
	_airfield_f35_button.pressed.connect(func():
		if _game_controller == null:
			return
		if _selected_airfield == null or not is_instance_valid(_selected_airfield):
			return
		_game_controller.upgrade_airfield_aircraft("p1", _selected_airfield)
	)
	_airfield_panel.add_child(_airfield_f35_button)

	# UAV Icon Button (64x64 square)
	var uav_container = AspectRatioContainer.new()
	uav_container.ratio = 1.0
	uav_container.custom_minimum_size = Vector2(64, 64)
	uav_container.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_airfield_uav_button = TextureButton.new()
	_airfield_uav_button.stretch_mode = TextureButton.STRETCH_SCALE
	_airfield_uav_button.ignore_texture_size = true
	var uav_icon := load("res://assets/models/Drones/MQ-9_Reaper_UAV_(cropped).jpg")
	if uav_icon != null:
		_airfield_uav_button.texture_normal = uav_icon
	uav_container.add_child(_airfield_uav_button)
	_airfield_uav_button.pressed.connect(func():
		if _game_controller == null:
			return
		if _selected_airfield == null or not is_instance_valid(_selected_airfield):
			return
		# Purchase a single UAV for 100 credits
		if GameState.p1_credits >= 100:
			GameState.p1_credits -= 100
			_game_controller.spawn_aircraft("p1", _selected_airfield, "uav")
	)
	_airfield_uav_button.mouse_entered.connect(func():
		_show_tooltip(
			_airfield_uav_button,
			"UAV Drone ($100)",
			"Unarmed reconnaissance drone with large vision radius. Circles designated area to reveal fog of war.",
			"",  # Strong vs - empty for now
			""   # Weak vs - empty for now
		)
	)
	_airfield_uav_button.mouse_exited.connect(_hide_tooltip)
	_airfield_panel.add_child(uav_container)

	# Airforce Command Button
	_airfield_command_button = Button.new()
	_airfield_command_button.text = "AIRFORCE COMMAND"
	_airfield_command_button.pressed.connect(_on_airforce_command_pressed)
	_airfield_panel.add_child(_airfield_command_button)

	# ========== AIRFORCE COMMAND PANEL ==========
	_airforce_panel = VBoxContainer.new()
	_airforce_panel.visible = false
	_airforce_panel.add_theme_constant_override("separation", 6)
	_airforce_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(_airforce_panel)

	_airforce_title_label = Label.new()
	_airforce_title_label.text = "Airforce Command"
	_airforce_panel.add_child(_airforce_title_label)

	_airforce_aircraft_count_label = Label.new()
	_airforce_aircraft_count_label.text = "Aircraft: 0"
	_airforce_panel.add_child(_airforce_aircraft_count_label)

	_airforce_status_label = Label.new()
	_airforce_status_label.text = "Ready: 0 | Flying: 0 | Refueling: 0"
	_airforce_panel.add_child(_airforce_status_label)

	_airforce_fuel_label = Label.new()
	_airforce_fuel_label.text = "Avg Fuel: --"
	_airforce_panel.add_child(_airforce_fuel_label)

	var patrol_mode_label := Label.new()
	patrol_mode_label.text = "Patrol Mode:"
	_airforce_panel.add_child(patrol_mode_label)

	var patrol_buttons_hbox := HBoxContainer.new()
	patrol_buttons_hbox.add_theme_constant_override("separation", 8)
	_airforce_panel.add_child(patrol_buttons_hbox)

	_airforce_defend_button = Button.new()
	_airforce_defend_button.text = "Defend Base"
	_airforce_defend_button.toggle_mode = true
	_airforce_defend_button.tooltip_text = "Aircraft patrol close to base, conserving fuel.\nProvides air dominance near friendly territory."
	_airforce_defend_button.pressed.connect(_on_patrol_defend_pressed)
	patrol_buttons_hbox.add_child(_airforce_defend_button)

	_airforce_superiority_button = Button.new()
	_airforce_superiority_button.text = "Air Superiority"
	_airforce_superiority_button.toggle_mode = true
	_airforce_superiority_button.tooltip_text = "Aircraft push forward into contested territory.\nConsumes more fuel but extends air dominance further."
	_airforce_superiority_button.pressed.connect(_on_patrol_superiority_pressed)
	patrol_buttons_hbox.add_child(_airforce_superiority_button)

	_airforce_back_button = Button.new()
	_airforce_back_button.text = "< Back"
	_airforce_back_button.pressed.connect(_on_airforce_back_pressed)
	_airforce_panel.add_child(_airforce_back_button)

	# Bombardment Panel
	_bombardment_panel = VBoxContainer.new()
	_bombardment_panel.visible = false
	_bombardment_panel.add_theme_constant_override("separation", 6)
	_bombardment_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(_bombardment_panel)

	var bombardment_title := Label.new()
	bombardment_title.text = "HIMARS Control"
	_bombardment_panel.add_child(bombardment_title)

	_bombardment_button = Button.new()
	_bombardment_button.text = "Launch Bombardment"
	_bombardment_button.pressed.connect(func():
		if _bombardment_controller == null:
			return
		if _selected_units.is_empty():
			return
		var himars_unit: Unit = null
		for unit in _selected_units:
			if is_instance_valid(unit) and unit.is_himars:
				himars_unit = unit
				break
		if himars_unit == null:
			return
		if _controller != null:
			_controller.cancel_placement()
		_bombardment_controller.start_bombardment(himars_unit)
	)
	_bombardment_panel.add_child(_bombardment_button)

	_cancel_bombardment_button = Button.new()
	_cancel_bombardment_button.text = "Cancel Bombardment"
	_cancel_bombardment_button.visible = false  # Hidden by default
	_cancel_bombardment_button.pressed.connect(func():
		if _selected_units.is_empty():
			return
		for unit in _selected_units:
			if is_instance_valid(unit) and unit.is_himars:
				unit.clear_bombardment_area()
	)
	_bombardment_panel.add_child(_cancel_bombardment_button)

	# ========== BATTALION PANELS ==========

	# Battalion Selected Panel (shown when battalion selected)
	_battalion_selected_panel = VBoxContainer.new()
	_battalion_selected_panel.visible = false
	_battalion_selected_panel.add_theme_constant_override("separation", 6)
	_battalion_selected_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(_battalion_selected_panel)

	var battalion_selected_title := Label.new()
	battalion_selected_title.text = "Selected Battalion"
	_battalion_selected_panel.add_child(battalion_selected_title)

	_battalion_name_label = Label.new()
	_battalion_name_label.text = "No battalion selected"
	_battalion_selected_panel.add_child(_battalion_name_label)

	_battalion_strength_label = Label.new()
	_battalion_strength_label.text = "Strength: --"
	_battalion_selected_panel.add_child(_battalion_strength_label)

	_battalion_state_label = Label.new()
	_battalion_state_label.text = "Status: --"
	_battalion_selected_panel.add_child(_battalion_state_label)

	_battalion_withdraw_button = Button.new()
	_battalion_withdraw_button.text = "Withdraw"
	_battalion_withdraw_button.pressed.connect(_on_battalion_withdraw_pressed)
	_battalion_selected_panel.add_child(_battalion_withdraw_button)

	# Minimap - top right corner
	var minimap_script := load("res://scripts/ui/minimap.gd")
	if minimap_script != null:
		var minimap_container := PanelContainer.new()
		minimap_container.name = "MinimapContainer"
		minimap_container.anchor_left = 1.0
		minimap_container.anchor_top = 0.0
		minimap_container.anchor_right = 1.0
		minimap_container.anchor_bottom = 0.0
		minimap_container.offset_left = -220.0
		minimap_container.offset_top = 12.0
		minimap_container.offset_right = -12.0
		minimap_container.offset_bottom = 220.0
		add_child(minimap_container)

		var minimap := Control.new()
		minimap.set_script(minimap_script)
		minimap.name = "Minimap"
		minimap_container.add_child(minimap)

	# Tooltip Panel - initially hidden, shown on hover
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't intercept mouse events
	add_child(_tooltip_panel)

	var tooltip_margin := MarginContainer.new()
	tooltip_margin.add_theme_constant_override("margin_left", 8)
	tooltip_margin.add_theme_constant_override("margin_right", 8)
	tooltip_margin.add_theme_constant_override("margin_top", 6)
	tooltip_margin.add_theme_constant_override("margin_bottom", 6)
	_tooltip_panel.add_child(tooltip_margin)

	var tooltip_vbox := VBoxContainer.new()
	tooltip_vbox.add_theme_constant_override("separation", 4)
	tooltip_margin.add_child(tooltip_vbox)

	_tooltip_name = Label.new()
	_tooltip_name.add_theme_font_size_override("font_size", 16)
	tooltip_vbox.add_child(_tooltip_name)

	_tooltip_desc = Label.new()
	_tooltip_desc.add_theme_font_size_override("font_size", 12)
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.custom_minimum_size = Vector2(200, 0)
	tooltip_vbox.add_child(_tooltip_desc)

	_tooltip_strong = Label.new()
	_tooltip_strong.add_theme_font_size_override("font_size", 11)
	_tooltip_strong.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	tooltip_vbox.add_child(_tooltip_strong)

	_tooltip_weak = Label.new()
	_tooltip_weak.add_theme_font_size_override("font_size", 11)
	_tooltip_weak.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	tooltip_vbox.add_child(_tooltip_weak)

func _show_tooltip(button: Control, name_text: String, desc_text: String, strong_text: String = "", weak_text: String = "") -> void:
	if _tooltip_panel == null:
		return
	_tooltip_name.text = name_text
	_tooltip_desc.text = desc_text
	_tooltip_strong.text = strong_text if strong_text != "" else ""
	_tooltip_strong.visible = strong_text != ""
	_tooltip_weak.text = weak_text if weak_text != "" else ""
	_tooltip_weak.visible = weak_text != ""
	_tooltip_panel.visible = true

	# Position tooltip with bounds checking to keep it on screen
	await get_tree().process_frame  # Wait for tooltip to calculate its size
	var button_rect := button.get_global_rect()
	var viewport_size := get_viewport().get_visible_rect().size
	var tooltip_size := _tooltip_panel.size

	# Try to position to the right of button
	var pos_x := button_rect.position.x + button_rect.size.x + 10
	var pos_y := button_rect.position.y

	# If it goes off right edge, position to the left instead
	if pos_x + tooltip_size.x > viewport_size.x:
		pos_x = button_rect.position.x - tooltip_size.x - 10

	# If still off left edge, clamp to right side of screen
	if pos_x < 0:
		pos_x = viewport_size.x - tooltip_size.x - 10

	# Clamp vertical position to keep it on screen
	pos_y = clampf(pos_y, 0, viewport_size.y - tooltip_size.y)

	_tooltip_panel.global_position = Vector2(pos_x, pos_y)

func _hide_tooltip() -> void:
	if _tooltip_panel != null:
		_tooltip_panel.visible = false

func _on_build_mode_changed(active_id: String) -> void:
	if _status_label == null:
		return
	if active_id == "":
		_status_label.text = "Placement: none"
	else:
		_status_label.text = "Placement: %s" % active_id

func _setup_factory_options() -> void:
	if _factory_type == null:
		return
	_factory_type.clear()
	_factory_type_ids.clear()
	_factory_type_index.clear()
	var options: Array = []
	if _game_controller != null:
		options = _game_controller.get_vehicle_type_options()
	if options.is_empty():
		options = [
			{"id": "mixed", "name": "Mixed"},
			{"id": "tank", "name": "Tank"},
			{"id": "artillery", "name": "Artillery"},
			{"id": "ifv", "name": "IFV"},
		]
	var index := 0
	for option in options:
		if typeof(option) != TYPE_DICTIONARY:
			continue
		var type_id := str(option.get("id", "mixed"))
		var name := str(option.get("name", type_id))
		_factory_type.add_item(name)
		_factory_type_ids.append(type_id)
		_factory_type_index[type_id] = index
		index += 1

func _on_building_selected(building: Building) -> void:
	if building == null or not is_instance_valid(building):
		_selected_barracks = null
		_selected_factory = null
		_selected_airfield = null
		_airforce_mode_active = false
		if _barracks_panel != null:
			_barracks_panel.visible = false
		if _factory_panel != null:
			_factory_panel.visible = false
		if _airfield_panel != null:
			_airfield_panel.visible = false
		if _airforce_panel != null:
			_airforce_panel.visible = false
		return
	_selected_barracks = null
	_selected_factory = null
	_selected_airfield = null
	_airforce_mode_active = false
	if _barracks_panel != null:
		_barracks_panel.visible = false
	if _factory_panel != null:
		_factory_panel.visible = false
	if _airfield_panel != null:
		_airfield_panel.visible = false
	if _airforce_panel != null:
		_airforce_panel.visible = false
	if building.build_id == "barracks":
		_selected_barracks = building
		if _barracks_panel != null:
			_barracks_panel.visible = true
			_update_barracks_panel()
	elif building.build_id == "factory":
		_selected_factory = building
		if _factory_panel != null:
			_factory_panel.visible = true
			_update_factory_panel()
	elif building.build_id == "airfield":
		_selected_airfield = building
		if _airfield_panel != null:
			_airfield_panel.visible = true
			_update_airfield_panel()

func _update_barracks_panel() -> void:
	if _barracks_panel == null:
		return
	if _selected_barracks == null or not is_instance_valid(_selected_barracks):
		_barracks_panel.visible = false
		return
	_barracks_panel.visible = true
	if _barracks_name_label != null:
		_barracks_name_label.text = "Barracks @ (%.0f, %.0f)" % [
			_selected_barracks.global_position.x,
			_selected_barracks.global_position.y
		]
	# Update battalion button states based on credits
	_update_battalion_buttons()

func _update_factory_panel() -> void:
	if _factory_panel == null:
		return
	if _selected_factory == null or not is_instance_valid(_selected_factory):
		_factory_panel.visible = false
		return
	_factory_panel.visible = true
	if _factory_name_label != null:
		_factory_name_label.text = "Factory @ (%.0f, %.0f)" % [
			_selected_factory.global_position.x,
			_selected_factory.global_position.y
		]
	if _factory_type != null:
		var type_id := _selected_factory.vehicle_production_type
		if type_id == "apc":
			type_id = "ifv"
			_selected_factory.vehicle_production_type = "ifv"
		var index := int(_factory_type_index.get(type_id, 0))
		_factory_updating = true
		_factory_type.select(index)
		_factory_updating = false
	if _factory_queue_button != null and _game_controller != null:
		var queue_cost := _game_controller.vehicle_unit_cost
		var type_label := "Vehicle"
		if _factory_type != null:
			var type_index := int(_factory_type_index.get(_selected_factory.vehicle_production_type, -1))
			if type_index >= 0:
				type_label = _factory_type.get_item_text(type_index)
		_factory_queue_button.text = "Queue %s ($%d)" % [type_label, queue_cost]
		_factory_queue_button.disabled = (
			GameState.p1_factory <= 0
			or GameState.p1_credits < _game_controller.vehicle_unit_cost
			or GameState.p1_factory_queue >= _game_controller.factory_queue_max
		)

func _update_airfield_panel() -> void:
	if _airfield_panel == null:
		return
	if _selected_airfield == null or not is_instance_valid(_selected_airfield):
		_airfield_panel.visible = false
		return
	_airfield_panel.visible = true
	if _airfield_name_label != null:
		_airfield_name_label.text = "Airfield @ (%.0f, %.0f)" % [
			_selected_airfield.global_position.x,
			_selected_airfield.global_position.y
		]
	if _airfield_f35_button != null and _game_controller != null:
		var current_tier := _game_controller.get_airfield_aircraft_tier(_selected_airfield)
		var cost := _game_controller.aircraft_upgrade_cost
		var label := ""
		var disabled := false

		if _selected_airfield.team_id != "p1":
			disabled = true
			label = "Enemy Airfield"
		elif current_tier == "f16":
			label = "Upgrade to Gripen ($%d)" % cost
		elif current_tier == "gripen":
			label = "Upgrade to F-22 ($%d)" % cost
		elif current_tier == "f22":
			label = "Max Tier (F-22)"
			disabled = true
		else:
			label = "Unknown Tier"
			disabled = true

		if GameState.p1_credits < cost and disabled == false:
			disabled = true

		_airfield_f35_button.text = label
		_airfield_f35_button.disabled = disabled

func _update_bombardment_panel() -> void:
	# Check if any selected units are HIMARS
	var has_himars := false
	var himars_ready := false
	var area_bombardment_active := false
	for unit in _selected_units:
		if is_instance_valid(unit) and unit.is_himars:
			has_himars = true
			if unit.is_bombardment_ready():
				himars_ready = true
			if unit.is_area_bombardment_active():
				area_bombardment_active = true
			break

	_bombardment_panel.visible = has_himars

	if _bombardment_button != null and has_himars:
		if himars_ready:
			_bombardment_button.text = "Launch Bombardment (Ready)"
			_bombardment_button.disabled = false
		else:
			_bombardment_button.text = "Launch Bombardment (Reloading...)"
			_bombardment_button.disabled = true

	if _cancel_bombardment_button != null:
		_cancel_bombardment_button.visible = area_bombardment_active
		if area_bombardment_active:
			_cancel_bombardment_button.text = "Cancel Area Bombardment"

func update_selected_units(units: Array[Unit]) -> void:
	_selected_units = units

func _on_units_selected(units: Array[Unit]) -> void:
	update_selected_units(units)


# =============================================================================
# BATTALION UI HANDLERS
# =============================================================================

func _on_battalion_button_pressed(type: Battalion.Type) -> void:
	print("Battalion button pressed: ", type)
	# Lazy lookup for battalion controller (created dynamically by GameController)
	if _battalion_controller == null:
		var game_ctrl := get_node_or_null(game_controller_path) as GameController
		if game_ctrl != null:
			_battalion_controller = game_ctrl.get_node_or_null("BattalionController") as BattalionController
			print("  Found battalion controller via GameController: ", _battalion_controller)
			# Also connect signals we missed at _ready() time
			if _battalion_controller != null:
				_battalion_controller.battalion_selected.connect(_on_battalion_selected)
				_battalion_controller.placement_started.connect(_on_battalion_placement_started)
				_battalion_controller.placement_cancelled.connect(_on_battalion_placement_cancelled)
	if _battalion_controller == null:
		print("  ERROR: _battalion_controller is null (still couldn't find it)")
		return
	if _selected_barracks == null or not is_instance_valid(_selected_barracks):
		print("  ERROR: _selected_barracks is null or invalid")
		return
	# Check if player can afford it
	var cost := Battalion.get_cost_for_type(type)
	if GameState.p1_credits < cost:
		print("  ERROR: Not enough credits. Have: ", GameState.p1_credits, " Need: ", cost)
		return
	# Start placement mode - player clicks where they want the battalion to go
	# Pass the selected barracks so we know where to spawn from
	print("  Starting placement for type ", type, " with barracks at ", _selected_barracks.global_position)
	var success := _battalion_controller.start_placement("p1", type, _selected_barracks)
	print("  start_placement returned: ", success)


func _update_battalion_buttons() -> void:
	var costs := [
		GameBalance.ASSAULT_BATTALION_COST,
		GameBalance.DEFENSE_BATTALION_COST,
		GameBalance.CONTROL_BATTALION_COST,
		GameBalance.AIR_DEFENSE_BATTALION_COST
	]
	for i in range(_battalion_buttons.size()):
		if i < costs.size():
			_battalion_buttons[i].disabled = GameState.p1_credits < costs[i]


func _on_battalion_selected(battalion: Battalion) -> void:
	_selected_battalion = battalion
	_update_battalion_selected_panel()


func _on_battalion_placement_started(_type: Battalion.Type) -> void:
	# Could show placement preview or change cursor here
	if _status_label != null:
		_status_label.text = "Placing Battalion..."


func _on_battalion_placement_cancelled() -> void:
	if _status_label != null:
		_status_label.text = "Placement: none"


func _on_battalion_withdraw_pressed() -> void:
	if _selected_battalion == null or not is_instance_valid(_selected_battalion):
		return
	_selected_battalion.withdraw()
	_update_battalion_selected_panel()


func _update_battalion_selected_panel() -> void:
	if _battalion_selected_panel == null:
		return

	if _selected_battalion == null or not is_instance_valid(_selected_battalion):
		_battalion_selected_panel.visible = false
		return

	_battalion_selected_panel.visible = true

	if _battalion_name_label != null:
		_battalion_name_label.text = _selected_battalion.get_battalion_name()

	if _battalion_strength_label != null:
		var strength := _selected_battalion.get_strength()
		_battalion_strength_label.text = "Strength: %d/%d (%d reserves)" % [
			strength["active"],
			strength["max"],
			strength["reserves"]
		]

	if _battalion_state_label != null:
		_battalion_state_label.text = "Status: %s" % _selected_battalion.get_state_name()

	if _battalion_withdraw_button != null:
		_battalion_withdraw_button.disabled = (_selected_battalion.state == Battalion.State.WITHDRAWING)


# =============================================================================
# AIRFORCE COMMAND UI HANDLERS
# =============================================================================

func _on_airforce_command_pressed() -> void:
	if _selected_airfield == null or not is_instance_valid(_selected_airfield):
		return
	_airforce_mode_active = true
	if _airfield_panel != null:
		_airfield_panel.visible = false
	if _airforce_panel != null:
		_airforce_panel.visible = true
		_update_airforce_panel()


func _on_airforce_back_pressed() -> void:
	_airforce_mode_active = false
	if _airforce_panel != null:
		_airforce_panel.visible = false
	if _airfield_panel != null and _selected_airfield != null and is_instance_valid(_selected_airfield):
		_airfield_panel.visible = true


func _on_patrol_defend_pressed() -> void:
	if _selected_airfield == null or not is_instance_valid(_selected_airfield):
		return
	_set_airfield_patrol_mode(AircraftBehavior.PatrolMode.DEFEND_BASE)


func _on_patrol_superiority_pressed() -> void:
	if _selected_airfield == null or not is_instance_valid(_selected_airfield):
		return
	_set_airfield_patrol_mode(AircraftBehavior.PatrolMode.AIR_SUPERIORITY)


func _set_airfield_patrol_mode(mode: AircraftBehavior.PatrolMode) -> void:
	if _selected_airfield == null or not is_instance_valid(_selected_airfield):
		return

	# Store patrol mode on the airfield
	_selected_airfield.set_meta("patrol_mode", int(mode))

	# Update all aircraft belonging to this airfield
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null or unit.unit_kind != "aircraft":
			continue
		if unit.aircraft_home != _selected_airfield:
			continue
		if unit._aircraft_behavior != null:
			unit._aircraft_behavior.set_patrol_mode(mode)

	_update_airforce_panel()


func _update_airforce_panel() -> void:
	if _airforce_panel == null:
		return

	if not _airforce_mode_active:
		_airforce_panel.visible = false
		return

	if _selected_airfield == null or not is_instance_valid(_selected_airfield):
		_airforce_panel.visible = false
		_airforce_mode_active = false
		return

	_airforce_panel.visible = true

	# Gather aircraft stats for this airfield
	var total_aircraft := 0
	var ready_count := 0
	var flying_count := 0
	var refueling_count := 0
	var total_fuel := 0.0
	var fuel_count := 0

	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null or unit.unit_kind != "aircraft":
			continue
		if unit.aircraft_home != _selected_airfield:
			continue
		if unit.team_id != "p1":
			continue

		total_aircraft += 1
		if unit._aircraft_behavior != null:
			var behavior := unit._aircraft_behavior
			total_fuel += behavior.get_fuel_percent()
			fuel_count += 1

			if behavior.reloading or behavior.landing_taxi:
				refueling_count += 1
			elif behavior.takeoff_active or behavior.altitude_factor < 0.5:
				ready_count += 1
			else:
				flying_count += 1

	# Update labels
	if _airforce_aircraft_count_label != null:
		_airforce_aircraft_count_label.text = "Aircraft: %d" % total_aircraft

	if _airforce_status_label != null:
		_airforce_status_label.text = "Ready: %d | Flying: %d | Refueling: %d" % [ready_count, flying_count, refueling_count]

	if _airforce_fuel_label != null:
		if fuel_count > 0:
			var avg_fuel := (total_fuel / float(fuel_count)) * 100.0
			_airforce_fuel_label.text = "Avg Fuel: %.0f%%" % avg_fuel
		else:
			_airforce_fuel_label.text = "Avg Fuel: --"

	# Update patrol mode buttons
	var current_mode := int(_selected_airfield.get_meta("patrol_mode", 0))
	if _airforce_defend_button != null:
		_airforce_defend_button.button_pressed = (current_mode == int(AircraftBehavior.PatrolMode.DEFEND_BASE))
	if _airforce_superiority_button != null:
		_airforce_superiority_button.button_pressed = (current_mode == int(AircraftBehavior.PatrolMode.AIR_SUPERIORITY))
