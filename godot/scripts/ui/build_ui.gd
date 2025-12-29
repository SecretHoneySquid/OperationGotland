extends CanvasLayer

@export var build_controller_path := NodePath("../BuildController")
@export var game_controller_path := NodePath("../GameController")
@export var selection_controller_path := NodePath("../SelectionController")

var _controller: BuildController
var _game_controller: GameController
var _selection_controller: SelectionController
var _status_label: Label
var _credits_label: Label
var _income_label: Label
var _prod_label: Label
var _infantry_status_label: Label
var _queue_label: Label
var _rally_label: Label
var _queue_button: Button
var _rally_button: Button
var _barracks_panel: VBoxContainer
var _barracks_name_label: Label
var _barracks_type: OptionButton
var _barracks_wait: CheckButton
var _barracks_type_ids: Array[String] = []
var _barracks_type_index := {}
var _selected_barracks: Building
var _barracks_updating := false
var _factory_panel: VBoxContainer
var _factory_name_label: Label
var _factory_type: OptionButton
var _factory_queue_button: Button
var _factory_type_ids: Array[String] = []
var _factory_type_index := {}
var _selected_factory: Building
var _factory_updating := false

func _ready() -> void:
	_controller = get_node_or_null(build_controller_path) as BuildController
	_game_controller = get_node_or_null(game_controller_path) as GameController
	_selection_controller = get_node_or_null(selection_controller_path) as SelectionController
	_build_ui()
	if _controller != null:
		_controller.build_mode_changed.connect(_on_build_mode_changed)
		_on_build_mode_changed(_controller.get_active_build_id())
	if _selection_controller != null:
		_selection_controller.building_selected.connect(_on_building_selected)

func _process(_delta: float) -> void:
	if _credits_label != null:
		_credits_label.text = "Credits: %d" % GameState.p1_credits
	if _income_label != null:
		_income_label.text = "Income/s: %.1f" % GameState.p1_income_rate
	if _prod_label != null:
		_prod_label.text = "Inf Prod: %.2f (Barracks: %d)  Veh Prod: %.2f (Factories: %d)" % [
			GameState.p1_infantry_prod,
			GameState.p1_barracks,
			GameState.p1_vehicle_prod,
			GameState.p1_factory
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
	if _rally_button != null and _game_controller != null:
		if _game_controller.is_rally_mode("p1"):
			_rally_button.text = "Rally Mode: Click Map"
		else:
			_rally_button.text = "Set Rally Point"
	if _barracks_panel != null:
		_update_barracks_panel()
	if _factory_panel != null:
		_update_factory_panel()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "BuildPanel"
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 12.0
	panel.offset_top = 110.0
	panel.offset_right = 260.0
	panel.offset_bottom = 860.0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

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
	_prod_label.text = "Inf Prod: %.2f (Barracks: %d)  Veh Prod: %.2f (Factories: %d)" % [
		GameState.p1_infantry_prod,
		GameState.p1_barracks,
		GameState.p1_vehicle_prod,
		GameState.p1_factory
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

	var spacer := HSeparator.new()
	vbox.add_child(spacer)

	var queue_title := Label.new()
	queue_title.text = "Factory Queue"
	vbox.add_child(queue_title)

	_queue_label = Label.new()
	_queue_label.text = "Factory Queue: %d" % GameState.p1_factory_queue
	vbox.add_child(_queue_label)

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
	vbox.add_child(_queue_button)

	var rally_title := Label.new()
	rally_title.text = "Rally Point"
	vbox.add_child(rally_title)

	_rally_label = Label.new()
	_rally_label.text = "Rally: (0, 0)"
	vbox.add_child(_rally_label)

	_rally_button = Button.new()
	_rally_button.text = "Set Rally Point"
	_rally_button.pressed.connect(func():
		if _game_controller != null:
			if _controller != null:
				_controller.cancel_placement()
			_game_controller.start_rally_mode("p1")
	)
	vbox.add_child(_rally_button)

	_status_label = Label.new()
	_status_label.text = "Placement: none"
	vbox.add_child(_status_label)

	var barracks_spacer := HSeparator.new()
	vbox.add_child(barracks_spacer)

	_barracks_panel = VBoxContainer.new()
	_barracks_panel.visible = false
	_barracks_panel.add_theme_constant_override("separation", 4)
	vbox.add_child(_barracks_panel)

	var barracks_title := Label.new()
	barracks_title.text = "Barracks Control"
	_barracks_panel.add_child(barracks_title)

	_barracks_name_label = Label.new()
	_barracks_name_label.text = "No barracks selected"
	_barracks_panel.add_child(_barracks_name_label)

	_barracks_type = OptionButton.new()
	_barracks_panel.add_child(_barracks_type)
	_barracks_type.item_selected.connect(func(index: int):
		if _barracks_updating:
			return
		if _selected_barracks == null or not is_instance_valid(_selected_barracks):
			return
		if index < 0 or index >= _barracks_type_ids.size():
			return
		_selected_barracks.production_type = _barracks_type_ids[index]
	)

	_barracks_wait = CheckButton.new()
	_barracks_wait.text = "Wait At Base Edge"
	_barracks_wait.toggled.connect(func(pressed: bool):
		if _selected_barracks == null or not is_instance_valid(_selected_barracks):
			return
		_selected_barracks.wait_mode = pressed
	)
	_barracks_panel.add_child(_barracks_wait)

	_setup_barracks_options()

	var factory_spacer := HSeparator.new()
	vbox.add_child(factory_spacer)

	_factory_panel = VBoxContainer.new()
	_factory_panel.visible = false
	_factory_panel.add_theme_constant_override("separation", 4)
	vbox.add_child(_factory_panel)

	var factory_title := Label.new()
	factory_title.text = "Factory Control"
	_factory_panel.add_child(factory_title)

	_factory_name_label = Label.new()
	_factory_name_label.text = "No factory selected"
	_factory_panel.add_child(_factory_name_label)

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

	_factory_queue_button = Button.new()
	_factory_queue_button.text = "Queue Vehicle"
	_factory_queue_button.pressed.connect(func():
		if _game_controller == null:
			return
		if _selected_factory == null or not is_instance_valid(_selected_factory):
			return
		_game_controller.queue_vehicle("p1", _selected_factory.vehicle_production_type, _selected_factory)
	)
	_factory_panel.add_child(_factory_queue_button)

	_setup_factory_options()

func _on_build_mode_changed(active_id: String) -> void:
	if _status_label == null:
		return
	if active_id == "":
		_status_label.text = "Placement: none"
	else:
		_status_label.text = "Placement: %s" % active_id

func _setup_barracks_options() -> void:
	if _barracks_type == null:
		return
	_barracks_type.clear()
	_barracks_type_ids.clear()
	_barracks_type_index.clear()
	var options: Array = []
	if _game_controller != null:
		options = _game_controller.get_infantry_type_options()
	if options.is_empty():
		options = [
			{"id": "mixed", "name": "Mixed"},
			{"id": "rifle", "name": "Rifle"},
			{"id": "sniper", "name": "Sniper"},
			{"id": "rocket", "name": "Rocket"},
		]
	var index := 0
	for option in options:
		if typeof(option) != TYPE_DICTIONARY:
			continue
		var type_id := str(option.get("id", "mixed"))
		var name := str(option.get("name", type_id))
		_barracks_type.add_item(name)
		_barracks_type_ids.append(type_id)
		_barracks_type_index[type_id] = index
		index += 1

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
		if _barracks_panel != null:
			_barracks_panel.visible = false
		if _factory_panel != null:
			_factory_panel.visible = false
		return
	if building.build_id != "barracks":
		if building.build_id == "factory":
			_selected_factory = building
			_selected_barracks = null
			if _barracks_panel != null:
				_barracks_panel.visible = false
			if _factory_panel != null:
				_factory_panel.visible = true
				_update_factory_panel()
		else:
			_selected_barracks = null
			_selected_factory = null
			if _barracks_panel != null:
				_barracks_panel.visible = false
			if _factory_panel != null:
				_factory_panel.visible = false
		return
	_selected_barracks = building
	_selected_factory = null
	if _factory_panel != null:
		_factory_panel.visible = false
	if _barracks_panel != null:
		_barracks_panel.visible = true
		_update_barracks_panel()

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
	if _barracks_type != null:
		var type_id := _selected_barracks.production_type
		var index := int(_barracks_type_index.get(type_id, 0))
		_barracks_updating = true
		_barracks_type.select(index)
		_barracks_updating = false
	if _barracks_wait != null:
		_barracks_wait.button_pressed = _selected_barracks.wait_mode

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
