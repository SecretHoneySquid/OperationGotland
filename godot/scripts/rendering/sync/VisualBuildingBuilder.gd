extends Node
class_name VisualBuildingBuilder

## Visual Building Builder
##
## Handles building visual proxies for all building types including:
## - Turrets, Barracks, Factories, Airfields
## - Supply, Power, Command Centers, Defense structures
## - HQ buildings with pentagon layouts
## - Building details, pads, props, and compounds

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Building Heights")
@export var turret_height := 9.0
@export var building_height := 18.0
@export var hq_height := 26.0

@export_group("Building Pad")
@export var building_pad_enabled := true
@export var building_pad_margin := 0.08
@export var building_pad_height := 0.06
@export var building_pad_color := Color(0.08, 0.08, 0.08, 0.55)

@export_group("Building Props")
@export var prop_detail_enabled := true
@export var prop_tank_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/detail-tank.glb"
@export var prop_chimney_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/chimney-medium.glb"
@export var prop_model_scale := 1.0

@export_group("Barracks")
@export var barracks_model_path := "res://assets/models/barracks.glb"
@export var barracks_model_scale := 1.0
@export var barracks_model_rotation := Vector3(0.0, -90.0, 0.0)
@export var barracks_compound_enabled := false
@export var barracks_compound_rows := 3
@export var barracks_compound_cols := 4
@export var barracks_compound_spacing := 2.0
@export var barracks_compound_models := PackedStringArray([
	"res://assets/vendor/quaternius_ultimate_buildings/Models with Materials/FBX/2Story_Sidehouse_Mat.fbx",
])

@export_group("Factory")
@export var factory_model_path := "res://assets/models/factory.glb"
@export var factory_model_scale := 1.0
@export var factory_compound_enabled := false
@export var factory_compound_rows := 2
@export var factory_compound_cols := 2
@export var factory_compound_spacing := 4.0
@export var factory_compound_models := PackedStringArray([
	"res://assets/vendor/quaternius_ultimate_buildings/Models with Materials/FBX/2Story_Double_Mat.fbx",
	"res://assets/vendor/quaternius_ultimate_buildings/Models with Materials/FBX/2Story_Columns_Mat.fbx",
	"res://assets/vendor/quaternius_ultimate_buildings/Models with Materials/FBX/1Story_RoundRoof_Mat.fbx",
])

@export_group("Airfield")
@export var airfield_model_path := "res://assets/models/airfield.glb"
@export var airfield_model_scale := 1.0
@export var airfield_runway_color := Color(0.12, 0.12, 0.14, 1.0)
@export var airfield_marking_color := Color(0.9, 0.9, 0.9, 0.85)

@export_group("Supply Building")
@export var supply_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-r.glb"
@export var supply_model_scale := 1.0

@export_group("Power Building")
@export var power_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-l.glb"
@export var power_model_scale := 1.0

@export_group("Command Center")
@export var command_center_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-p.glb"
@export var command_center_model_scale := 1.0

@export_group("Defense Structures")
@export var defense_gun_model_path := ""
@export var defense_gun_model_scale := 1.0
@export var defense_missile_model_path := ""
@export var defense_missile_model_scale := 1.0
@export var defense_laser_model_path := ""
@export var defense_laser_model_scale := 1.0

@export_group("HQ Pentagon")
@export var hq_pentagon_enabled := true
@export var hq_pentagon_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-s.glb"
@export var hq_pentagon_model_scale := 1.0
@export var hq_pentagon_center_model_path := "res://assets/vendor/kenney_city-kit-industrial/Models/GLB format/building-q.glb"
@export var hq_pentagon_center_model_scale := 1.0
@export var hq_pentagon_center_size_scale := 0.45
@export var hq_pentagon_radius_scale := 0.42
@export var hq_pentagon_wing_depth_scale := 0.22

@export_group("Health Bar Settings")
@export var health_bar_height := 6.0
@export var health_bar_offset := 8.0

# =============================================================================
# TURRET BUILDER
# =============================================================================

func build_turret_proxy(proxy: Node3D, turret, ui_overlays: VisualUIOverlays) -> void:
	var base_radius := maxf(4.0, VisualUtilities.get_float(turret, "base_radius", 8.0))
	var height := turret_height
	var base_color := VisualUtilities.get_color(turret, "base_color", Color(0.7, 0.7, 0.7, 1.0))

	var base := VisualUtilities.make_cylinder(base_radius, height * 0.45, base_color.darkened(0.08))
	base.position = Vector3(0, height * 0.225, 0)
	proxy.add_child(base)

	var head := VisualUtilities.make_cylinder(base_radius * 0.55, height * 0.25, base_color.lightened(0.2))
	head.position = Vector3(0, height * 0.55, 0)
	proxy.add_child(head)

	var barrel := VisualUtilities.make_cylinder(base_radius * 0.12, base_radius * 1.4, base_color.lightened(0.35))
	barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	barrel.position = Vector3(0, height * 0.55, -base_radius * 1.0)
	proxy.add_child(barrel)

	ui_overlays.update_turret_range(proxy, turret)

# =============================================================================
# BUILDING BUILDER
# =============================================================================

func build_building_proxy(proxy: Node3D, building, ui_overlays: VisualUIOverlays) -> void:
	var size2d := VisualUtilities.get_vec2(building, "size", Vector2(80, 80))
	var height := building_height
	var size := Vector3(size2d.x, height, size2d.y)
	var base_color := VisualUtilities.get_color(building, "fill_color", Color(0.7, 0.7, 0.7, 1.0))
	var build_id := str(VisualUtilities.get_value(building, "build_id", ""))

	_add_building_pad(proxy, size2d, base_color)

	if build_id == "barracks":
		var model_height := 0.0
		if barracks_compound_enabled and not barracks_compound_models.is_empty():
			model_height = _add_barracks_compound(proxy, size2d, height)
		elif barracks_model_path != "" and ResourceLoader.exists(barracks_model_path):
			model_height = _add_scene_model(
				proxy,
				barracks_model_path,
				size2d,
				0.0,
				barracks_model_scale,
				Vector3.ZERO,
				barracks_model_rotation
			)
		if model_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, model_height), base_color)
			ui_overlays.attach_health_bar(proxy, size2d.x, model_height, health_bar_height, health_bar_offset)
			return

	elif build_id == "factory":
		var factory_height := 0.0
		if factory_compound_enabled and not factory_compound_models.is_empty():
			factory_height = _add_factory_compound(proxy, size2d, height)
		elif factory_model_path != "" and ResourceLoader.exists(factory_model_path):
			factory_height = _add_scene_model(proxy, factory_model_path, size2d, 0.0, factory_model_scale)
		if factory_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, factory_height), base_color)
			ui_overlays.attach_health_bar(proxy, size2d.x, factory_height, health_bar_height, health_bar_offset)
			return

	elif build_id == "airfield":
		var airfield_height := 0.0
		if airfield_model_path != "" and ResourceLoader.exists(airfield_model_path):
			airfield_height = _add_scene_model(proxy, airfield_model_path, size2d, 0.0, airfield_model_scale)
		if airfield_height <= 0.0:
			airfield_height = _build_airfield_base(proxy, size2d, height, base_color)
		_add_building_props(proxy, build_id, size2d, maxf(height, airfield_height), base_color)
		ui_overlays.attach_health_bar(proxy, size2d.x, airfield_height, health_bar_height, health_bar_offset)
		return

	elif build_id == "supply":
		var supply_height := 0.0
		if supply_model_path != "" and ResourceLoader.exists(supply_model_path):
			supply_height = _add_scene_model(proxy, supply_model_path, size2d, 0.0, supply_model_scale)
		if supply_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, supply_height), base_color)
			ui_overlays.attach_health_bar(proxy, size2d.x, supply_height, health_bar_height, health_bar_offset)
			return
		var fallback_height := _build_supply_fallback(proxy, size2d, height, base_color)
		_add_building_props(proxy, build_id, size2d, maxf(height, fallback_height), base_color)
		ui_overlays.attach_health_bar(proxy, size2d.x, fallback_height, health_bar_height, health_bar_offset)
		return

	elif build_id == "power":
		var power_height := 0.0
		if power_model_path != "" and ResourceLoader.exists(power_model_path):
			power_height = _add_scene_model(proxy, power_model_path, size2d, 0.0, power_model_scale)
		if power_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, power_height), base_color)
			ui_overlays.attach_health_bar(proxy, size2d.x, power_height, health_bar_height, health_bar_offset)
			return

	elif build_id == "command_center":
		var command_height := 0.0
		if command_center_model_path != "" and ResourceLoader.exists(command_center_model_path):
			command_height = _add_scene_model(proxy, command_center_model_path, size2d, 0.0, command_center_model_scale)
		if command_height > 0.0:
			_add_building_props(proxy, build_id, size2d, maxf(height, command_height), base_color)
			ui_overlays.attach_health_bar(proxy, size2d.x, command_height, health_bar_height, health_bar_offset)
			return

	elif build_id.begins_with("defense"):
		var defense_path := ""
		var defense_scale := 1.0
		match build_id:
			"defense_gun":
				defense_path = defense_gun_model_path
				defense_scale = defense_gun_model_scale
			"defense_missile":
				defense_path = defense_missile_model_path
				defense_scale = defense_missile_model_scale
			"defense_laser":
				defense_path = defense_laser_model_path
				defense_scale = defense_laser_model_scale
		var defense_height := 0.0
		if defense_path != "" and ResourceLoader.exists(defense_path):
			defense_height = _add_scene_model(proxy, defense_path, size2d, 0.0, defense_scale)
		if defense_height <= 0.0:
			defense_height = _build_defense_base(proxy, build_id, size2d, height, base_color)
		_add_building_props(proxy, build_id, size2d, maxf(height, defense_height), base_color)
		ui_overlays.attach_health_bar(proxy, size2d.x, defense_height, health_bar_height, health_bar_offset)
		return

	elif build_id == "missile_carrier":
		var ship_height := _build_missile_carrier_ship(proxy, size2d, height, base_color)
		ui_overlays.attach_health_bar(proxy, size2d.x, ship_height, health_bar_height, health_bar_offset)
		return

	# Default building
	var body := VisualUtilities.make_box(size, base_color)
	body.position = Vector3(0, height * 0.5, 0)
	proxy.add_child(body)
	_add_building_details(proxy, build_id, size2d, height, base_color)
	_add_building_props(proxy, build_id, size2d, height, base_color)
	ui_overlays.attach_health_bar(proxy, size2d.x, height, health_bar_height, health_bar_offset)

# =============================================================================
# HQ BUILDER
# =============================================================================

func build_hq_proxy(proxy: Node3D, hq, ui_overlays: VisualUIOverlays) -> void:
	var size2d := VisualUtilities.get_vec2(hq, "size", Vector2(140, 140))
	var height := hq_height
	var base_color := VisualUtilities.get_color(hq, "fill_color", Color(0.7, 0.7, 0.7, 1.0))

	_add_building_pad(proxy, size2d, base_color)

	if hq_pentagon_enabled and hq_pentagon_model_path != "" and ResourceLoader.exists(hq_pentagon_model_path):
		var model_height := _add_hq_pentagon(proxy, size2d, height)
		if model_height > 0.0:
			_add_hq_props(proxy, size2d, maxf(height, model_height), base_color)
			ui_overlays.attach_health_bar(proxy, size2d.x, model_height, health_bar_height, health_bar_offset)
			return

	var radius := minf(size2d.x, size2d.y) * 0.45
	var base_height := height * 0.45
	var base := VisualUtilities.make_pentagon_prism(radius, base_height, base_color)
	base.position = Vector3(0, base_height * 0.5, 0)
	proxy.add_child(base)

	var mid_height := height * 0.22
	var mid := VisualUtilities.make_pentagon_prism(radius * 0.62, mid_height, base_color.lightened(0.12))
	mid.position = Vector3(0, base_height + mid_height * 0.5, 0)
	proxy.add_child(mid)

	var top_height := height * 0.12
	var top := VisualUtilities.make_pentagon_prism(radius * 0.35, top_height, base_color.lightened(0.22))
	top.position = Vector3(0, base_height + mid_height + top_height * 0.5, 0)
	proxy.add_child(top)

	var mast_height := height * 0.18
	var mast := VisualUtilities.make_cylinder(radius * 0.08, mast_height, base_color.lightened(0.35))
	mast.position = Vector3(0, base_height + mid_height + top_height + mast_height * 0.5, 0)
	proxy.add_child(mast)

	var max_height := base_height + mid_height + top_height + mast_height
	_add_hq_props(proxy, size2d, maxf(height, max_height), base_color)
	ui_overlays.attach_health_bar(proxy, size2d.x, max_height, health_bar_height, health_bar_offset)

# =============================================================================
# BUILDING DETAILS (PROCEDURAL DECORATION)
# =============================================================================

func _add_building_details(proxy: Node3D, build_id: String, size2d: Vector2, height: float, base_color: Color) -> void:
	var accent := base_color.lightened(0.2)
	var dark := base_color.darkened(0.25)
	var roof_color := base_color.lightened(0.12)
	var slab_height := height * 0.08
	_add_box_detail(proxy, Vector3(size2d.x * 1.06, slab_height, size2d.y * 1.06), base_color.darkened(0.35),
		Vector3(0, slab_height * 0.5, 0))

	match build_id:
		"barracks":
			_add_box_detail(proxy, Vector3(size2d.x * 0.86, height * 0.14, size2d.y * 0.78), roof_color,
				Vector3(0, height * 0.9, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.34, height * 0.3, size2d.y * 0.56), accent.darkened(0.06),
				Vector3(-size2d.x * 0.34, height * 0.28, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.28, height * 0.26, size2d.y * 0.46), accent.darkened(0.08),
				Vector3(size2d.x * 0.36, height * 0.24, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.32, height * 0.22, size2d.y * 0.22), accent,
				Vector3(0, height * 0.26, -size2d.y * 0.46))
			_add_box_detail(proxy, Vector3(size2d.x * 0.4, height * 0.05, size2d.y * 0.16), roof_color.lightened(0.1),
				Vector3(0, height * 0.34, -size2d.y * 0.56))
			_add_box_detail(proxy, Vector3(size2d.x * 0.26, height * 0.07, size2d.y * 0.12), dark,
				Vector3(0, height * 0.2, -size2d.y * 0.64))
			_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.16, size2d.y * 0.5), accent.darkened(0.12),
				Vector3(size2d.x * 0.44, height * 0.2, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.16, size2d.y * 0.5), accent.darkened(0.12),
				Vector3(-size2d.x * 0.44, height * 0.2, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.22, size2d.y * 0.26), dark,
				Vector3(0, height * 0.18, size2d.y * 0.46))
			_add_box_detail(proxy, Vector3(size2d.x * 0.32, height * 0.06, size2d.y * 0.12), roof_color,
				Vector3(0, height * 0.26, size2d.y * 0.56))
			var tower := _add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.6, size2d.y * 0.2), accent,
				Vector3(-size2d.x * 0.3, height * 0.8, size2d.y * 0.24))
			tower.scale = Vector3(1.0, 1.1, 1.0)
			for i in range(4):
				var x := (float(i) - 1.5) * (size2d.x * 0.16)
				_add_box_detail(proxy, Vector3(size2d.x * 0.12, height * 0.08, size2d.y * 0.1), dark,
					Vector3(x, height * 0.92, size2d.y * 0.1))
			for i in range(3):
				var x := (float(i) - 1.0) * (size2d.x * 0.12)
				_add_box_detail(proxy, Vector3(size2d.x * 0.08, height * 0.06, size2d.y * 0.08), dark,
					Vector3(x, height * 0.82, -size2d.y * 0.22))
			for i in range(4):
				var x := (float(i) - 1.5) * (size2d.x * 0.16)
				_add_box_detail(proxy, Vector3(size2d.x * 0.08, height * 0.12, size2d.y * 0.04), accent.darkened(0.2),
					Vector3(x, height * 0.42, -size2d.y * 0.52))
			for i in range(3):
				var z := (float(i) - 1.0) * (size2d.y * 0.18)
				_add_box_detail(proxy, Vector3(size2d.x * 0.04, height * 0.1, size2d.y * 0.12), dark,
					Vector3(-size2d.x * 0.46, height * 0.36, z))
			_add_cylinder_detail(proxy, size2d.x * 0.02, height * 0.6, dark,
				Vector3(-size2d.x * 0.4, height * 1.04, size2d.y * 0.3))
			_add_cylinder_detail(proxy, size2d.x * 0.03, height * 0.42, accent,
				Vector3(size2d.x * 0.38, height * 0.86, -size2d.y * 0.32))
			_add_cylinder_detail(proxy, size2d.x * 0.035, height * 0.35, accent.lightened(0.12),
				Vector3(size2d.x * 0.18, height * 0.84, size2d.y * 0.32))
			_add_box_detail(proxy, Vector3(size2d.x * 0.1, height * 0.1, size2d.y * 0.1), roof_color,
				Vector3(-size2d.x * 0.06, height * 0.88, -size2d.y * 0.3))

		"factory":
			_add_box_detail(proxy, Vector3(size2d.x * 0.86, height * 0.18, size2d.y * 0.8), roof_color,
				Vector3(0, height * 0.9, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.62, height * 0.38, size2d.y * 0.08), dark,
				Vector3(0, height * 0.34, -size2d.y * 0.5))
			_add_box_detail(proxy, Vector3(size2d.x * 0.26, height * 0.32, size2d.y * 0.28), accent,
				Vector3(-size2d.x * 0.38, height * 0.44, size2d.y * 0.2))
			_add_box_detail(proxy, Vector3(size2d.x * 0.18, height * 0.24, size2d.y * 0.2), accent,
				Vector3(size2d.x * 0.36, height * 0.38, size2d.y * 0.24))
			for i in range(4):
				var x := (float(i) - 1.5) * (size2d.x * 0.18)
				_add_box_detail(proxy, Vector3(size2d.x * 0.14, height * 0.12, size2d.y * 0.16), roof_color,
					Vector3(x, height * 0.96, size2d.y * 0.02))
			_add_cylinder_detail(proxy, size2d.x * 0.05, height * 0.6, dark,
				Vector3(size2d.x * 0.42, height * 0.85, size2d.y * 0.32))
			_add_cylinder_detail(proxy, size2d.x * 0.04, height * 0.5, dark,
				Vector3(size2d.x * 0.32, height * 0.78, -size2d.y * 0.18))

		"supply":
			_add_box_detail(proxy, Vector3(size2d.x * 0.7, height * 0.14, size2d.y * 0.68), roof_color,
				Vector3(0, height * 0.86, 0))
			_add_cylinder_detail(proxy, size2d.x * 0.13, height * 0.5, accent,
				Vector3(-size2d.x * 0.26, height * 0.56, size2d.y * 0.22))
			_add_cylinder_detail(proxy, size2d.x * 0.13, height * 0.5, accent,
				Vector3(size2d.x * 0.26, height * 0.56, size2d.y * 0.22))
			var tank_c := _add_cylinder_detail(proxy, size2d.x * 0.1, height * 0.42, accent.lightened(0.08),
				Vector3(0, height * 0.52, size2d.y * 0.28))
			tank_c.scale = Vector3(1.0, 0.9, 1.0)
			var pipe := _add_cylinder_detail(proxy, size2d.x * 0.03, size2d.x * 0.55, dark,
				Vector3(0, height * 0.5, size2d.y * 0.22))
			pipe.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			_add_box_detail(proxy, Vector3(size2d.x * 0.42, height * 0.08, size2d.y * 0.1), dark,
				Vector3(0, height * 0.3, -size2d.y * 0.38))
			_add_box_detail(proxy, Vector3(size2d.x * 0.18, height * 0.2, size2d.y * 0.14), dark,
				Vector3(size2d.x * 0.3, height * 0.42, -size2d.y * 0.18))
			_add_box_detail(proxy, Vector3(size2d.x * 0.16, height * 0.16, size2d.y * 0.16), roof_color,
				Vector3(-size2d.x * 0.34, height * 0.38, -size2d.y * 0.1))

		"power":
			_add_box_detail(proxy, Vector3(size2d.x * 0.66, height * 0.16, size2d.y * 0.62), roof_color,
				Vector3(0, height * 0.88, 0))
			_add_cylinder_detail(proxy, size2d.x * 0.16, height * 0.7, accent,
				Vector3(-size2d.x * 0.24, height * 0.82, size2d.y * 0.18))
			_add_cylinder_detail(proxy, size2d.x * 0.16, height * 0.7, accent,
				Vector3(size2d.x * 0.24, height * 0.82, size2d.y * 0.18))
			_add_box_detail(proxy, Vector3(size2d.x * 0.26, height * 0.26, size2d.y * 0.2), dark,
				Vector3(0, height * 0.54, -size2d.y * 0.22))
			for i in range(3):
				var x := (float(i) - 1.0) * (size2d.x * 0.18)
				_add_box_detail(proxy, Vector3(size2d.x * 0.12, height * 0.14, size2d.y * 0.16), dark,
					Vector3(x, height * 0.34, -size2d.y * 0.38))
			_add_box_detail(proxy, Vector3(size2d.x * 0.16, height * 0.12, size2d.y * 0.12), dark,
				Vector3(-size2d.x * 0.32, height * 0.42, -size2d.y * 0.3))

		"command_center":
			_add_box_detail(proxy, Vector3(size2d.x * 0.72, height * 0.18, size2d.y * 0.72), roof_color,
				Vector3(0, height * 0.88, 0))
			_add_box_detail(proxy, Vector3(size2d.x * 0.26, height * 0.7, size2d.y * 0.24), accent,
				Vector3(-size2d.x * 0.2, height * 0.88, size2d.y * 0.1))
			var dish := _add_sphere_detail(proxy, size2d.x * 0.12, accent,
				Vector3(size2d.x * 0.26, height * 1.05, size2d.y * 0.02))
			dish.scale = Vector3(1.6, 0.4, 1.6)
			var radome := _add_sphere_detail(proxy, size2d.x * 0.1, roof_color,
				Vector3(-size2d.x * 0.34, height * 1.0, -size2d.y * 0.08))
			radome.scale = Vector3(1.2, 0.8, 1.2)
			_add_cylinder_detail(proxy, size2d.x * 0.03, height * 0.48, dark,
				Vector3(size2d.x * 0.32, height * 0.98, size2d.y * 0.2))
			var helipad := _add_cylinder_detail(proxy, size2d.x * 0.18, height * 0.04, dark,
				Vector3(size2d.x * 0.3, height * 0.24, -size2d.y * 0.22))
			helipad.scale = Vector3(1.4, 1.0, 1.4)
			_add_box_detail(proxy, Vector3(size2d.x * 0.22, height * 0.18, size2d.y * 0.12), dark,
				Vector3(0, height * 0.36, -size2d.y * 0.36))

		_:
			if build_id.begins_with("defense"):
				_add_box_detail(proxy, Vector3(size2d.x * 0.62, height * 0.14, size2d.y * 0.62), roof_color,
					Vector3(0, height * 0.74, 0))
				_add_box_detail(proxy, Vector3(size2d.x * 0.24, height * 0.26, size2d.y * 0.24), dark,
					Vector3(0, height * 0.44, 0))
				var radar := _add_sphere_detail(proxy, size2d.x * 0.1, accent,
					Vector3(size2d.x * 0.22, height * 0.86, -size2d.y * 0.12))
				radar.scale = Vector3(1.3, 0.5, 1.3)
				_add_box_detail(proxy, Vector3(size2d.x * 0.16, height * 0.12, size2d.y * 0.12), dark,
					Vector3(-size2d.x * 0.28, height * 0.36, size2d.y * 0.28))
			else:
				_add_box_detail(proxy, Vector3(size2d.x * 0.72, height * 0.18, size2d.y * 0.7), roof_color,
					Vector3(0, height * 0.88, 0))
				_add_box_detail(proxy, Vector3(size2d.x * 0.24, height * 0.2, size2d.y * 0.18), dark,
					Vector3(-size2d.x * 0.2, height * 0.45, -size2d.y * 0.3))
			_add_box_detail(proxy, Vector3(size2d.x * 0.18, height * 0.12, size2d.y * 0.1), accent,
				Vector3(size2d.x * 0.26, height * 0.36, size2d.y * 0.3))

# =============================================================================
# BUILDING PAD
# =============================================================================

func _add_building_pad(proxy: Node3D, size2d: Vector2, base_color: Color) -> void:
	if not building_pad_enabled:
		return

	var margin := maxf(0.0, building_pad_margin)
	var pad_height := maxf(0.01, building_pad_height)
	var pad_size := Vector3(size2d.x * (1.0 + margin), pad_height, size2d.y * (1.0 + margin))
	var pad_color := building_pad_color
	pad_color.a = clampf(pad_color.a, 0.1, 0.8)

	if pad_color.a <= 0.1:
		pad_color = base_color.darkened(0.55)
		pad_color.a = 0.55

	var pad := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = pad_size
	pad.mesh = mesh
	pad.material_override = VisualUtilities.make_pad_material(pad_color)
	pad.position = Vector3(0.0, pad_height * 0.5, 0.0)
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	proxy.add_child(pad)

# =============================================================================
# BUILDING PROPS (EXTERNAL DETAILS)
# =============================================================================

func _add_building_props(proxy: Node3D, build_id: String, size2d: Vector2, height: float, base_color: Color) -> void:
	if not prop_detail_enabled:
		return

	var accent := base_color.lightened(0.2)
	var dark := base_color.darkened(0.35)

	match build_id:
		"barracks":
			_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.12, size2d.y * 0.12), dark,
				Vector3(-size2d.x * 0.32, height * 0.06, size2d.y * 0.34))
			_add_box_detail(proxy, Vector3(size2d.x * 0.16, height * 0.1, size2d.y * 0.1), accent,
				Vector3(size2d.x * 0.34, height * 0.05, size2d.y * 0.32))
			_add_cylinder_detail(proxy, size2d.x * 0.035, height * 0.55, accent.lightened(0.2),
				Vector3(size2d.x * 0.2, height * 0.7, -size2d.y * 0.18))

		"factory":
			var chimney_height := height * 0.65
			if prop_chimney_model_path != "" and ResourceLoader.exists(prop_chimney_model_path):
				_add_scene_model(proxy, prop_chimney_model_path, Vector2(size2d.x * 0.16, size2d.y * 0.16), 0.0,
					prop_model_scale, Vector3(-size2d.x * 0.3, 0.0, -size2d.y * 0.32))
				_add_scene_model(proxy, prop_chimney_model_path, Vector2(size2d.x * 0.16, size2d.y * 0.16), 0.0,
					prop_model_scale, Vector3(size2d.x * 0.3, 0.0, -size2d.y * 0.32))
			else:
				_add_cylinder_detail(proxy, size2d.x * 0.05, chimney_height, dark,
					Vector3(-size2d.x * 0.3, chimney_height * 0.5, -size2d.y * 0.32))
				_add_cylinder_detail(proxy, size2d.x * 0.05, chimney_height * 0.85, dark,
					Vector3(size2d.x * 0.3, chimney_height * 0.42, -size2d.y * 0.32))
			_add_box_detail(proxy, Vector3(size2d.x * 0.24, height * 0.12, size2d.y * 0.16), accent,
				Vector3(size2d.x * 0.34, height * 0.06, size2d.y * 0.34))

		"supply":
			if prop_tank_model_path != "" and ResourceLoader.exists(prop_tank_model_path):
				_add_scene_model(proxy, prop_tank_model_path, Vector2(size2d.x * 0.28, size2d.y * 0.18), 0.0,
					prop_model_scale, Vector3(-size2d.x * 0.22, 0.0, size2d.y * 0.34))
				_add_scene_model(proxy, prop_tank_model_path, Vector2(size2d.x * 0.28, size2d.y * 0.18), 0.0,
					prop_model_scale, Vector3(size2d.x * 0.22, 0.0, size2d.y * 0.34))
			else:
				_add_cylinder_detail(proxy, size2d.x * 0.08, height * 0.32, accent,
					Vector3(-size2d.x * 0.26, height * 0.16, size2d.y * 0.32))
				_add_cylinder_detail(proxy, size2d.x * 0.08, height * 0.32, accent,
					Vector3(size2d.x * 0.26, height * 0.16, size2d.y * 0.32))
			_add_box_detail(proxy, Vector3(size2d.x * 0.22, height * 0.1, size2d.y * 0.14), dark,
				Vector3(0.0, height * 0.05, size2d.y * 0.34))

		"command_center":
			_add_cylinder_detail(proxy, size2d.x * 0.04, height * 0.5, accent,
				Vector3(size2d.x * 0.12, height * 0.7, 0.0))
			_add_sphere_detail(proxy, size2d.x * 0.06, accent.lightened(0.3),
				Vector3(-size2d.x * 0.16, height * 0.8, -size2d.y * 0.1))

		"power":
			_add_box_detail(proxy, Vector3(size2d.x * 0.18, height * 0.16, size2d.y * 0.18), dark,
				Vector3(size2d.x * 0.28, height * 0.08, -size2d.y * 0.22))
			_add_cylinder_detail(proxy, size2d.x * 0.03, height * 0.45, accent,
				Vector3(-size2d.x * 0.28, height * 0.65, size2d.y * 0.2))

		_:
			if build_id.begins_with("defense"):
				_add_box_detail(proxy, Vector3(size2d.x * 0.2, height * 0.12, size2d.y * 0.2), dark,
					Vector3(0.0, height * 0.06, size2d.y * 0.32))

# =============================================================================
# HQ PROPS
# =============================================================================

func _add_hq_props(proxy: Node3D, size2d: Vector2, height: float, base_color: Color) -> void:
	if not prop_detail_enabled:
		return

	var pad_radius := minf(size2d.x, size2d.y) * 0.22
	var helipad := VisualUtilities.make_cylinder(pad_radius, height * 0.04, base_color.darkened(0.4))
	helipad.position = Vector3(0.0, height * 0.02, -size2d.y * 0.12)
	helipad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	proxy.add_child(helipad)

	_add_cylinder_detail(proxy, size2d.x * 0.035, height * 0.55, base_color.lightened(0.25),
		Vector3(size2d.x * 0.18, height * 0.7, size2d.y * 0.08))
	_add_sphere_detail(proxy, size2d.x * 0.05, base_color.lightened(0.4),
		Vector3(size2d.x * 0.18, height * 0.9, size2d.y * 0.08))

# =============================================================================
# DETAIL HELPERS
# =============================================================================

func _add_box_detail(proxy: Node3D, size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := VisualUtilities.make_box(size, color)
	mesh.position = pos
	proxy.add_child(mesh)
	return mesh

func _add_cylinder_detail(proxy: Node3D, radius: float, height: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := VisualUtilities.make_cylinder(radius, height, color)
	mesh.position = pos
	proxy.add_child(mesh)
	return mesh

func _add_sphere_detail(proxy: Node3D, radius: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := VisualUtilities.make_sphere(radius, color)
	mesh.position = pos
	proxy.add_child(mesh)
	return mesh

# =============================================================================
# FALLBACK BUILDINGS
# =============================================================================

func _build_supply_fallback(proxy: Node3D, size2d: Vector2, height: float, base_color: Color) -> float:
	var fallback_height := height * 0.8
	var main_height := fallback_height * 0.45
	var main := VisualUtilities.make_box(Vector3(size2d.x * 0.78, main_height, size2d.y * 0.62), base_color)
	main.position = Vector3(0, main_height * 0.5, 0)
	proxy.add_child(main)

	var annex_height := fallback_height * 0.28
	var annex := VisualUtilities.make_box(Vector3(size2d.x * 0.28, annex_height, size2d.y * 0.22), base_color.lightened(0.08))
	annex.position = Vector3(size2d.x * 0.28, annex_height * 0.5, -size2d.y * 0.12)
	proxy.add_child(annex)

	var roof_height := fallback_height * 0.08
	var roof := VisualUtilities.make_box(Vector3(size2d.x * 0.84, roof_height, size2d.y * 0.68), base_color.lightened(0.18))
	roof.position = Vector3(0, main_height + roof_height * 0.5, 0)
	proxy.add_child(roof)

	var tank_height := fallback_height * 0.5
	for i in range(3):
		var x := (float(i) - 1.0) * (size2d.x * 0.18)
		var tank := VisualUtilities.make_cylinder(size2d.x * 0.06, tank_height, base_color.lightened(0.25))
		tank.position = Vector3(x, tank_height * 0.5, size2d.y * 0.28)
		proxy.add_child(tank)

	var max_height := maxf(main_height + roof_height, tank_height)
	if annex_height > max_height:
		max_height = annex_height

	return max_height

func _build_airfield_base(proxy: Node3D, size2d: Vector2, height: float, base_color: Color) -> float:
	var pad_height := maxf(0.2, height * 0.06)
	var pad := VisualUtilities.make_box(Vector3(size2d.x * 0.98, pad_height, size2d.y * 0.62), base_color.darkened(0.2))
	pad.position = Vector3(0.0, pad_height * 0.5, size2d.y * 0.08)
	proxy.add_child(pad)

	var runway_height := maxf(0.15, height * 0.04)
	var runway := VisualUtilities.make_box(Vector3(size2d.x * 0.9, runway_height, size2d.y * 0.28), airfield_runway_color)
	runway.position = Vector3(0.0, pad_height + runway_height * 0.5, size2d.y * 0.18)
	proxy.add_child(runway)

	var stripe_height := runway_height * 0.6
	var stripe_size := Vector3(size2d.x * 0.08, stripe_height, size2d.y * 0.03)
	var stripe_y := pad_height + runway_height * 0.5 + stripe_height * 0.5
	for i in range(4):
		var z := size2d.y * 0.18 + (float(i) - 1.5) * (size2d.y * 0.07)
		var stripe := VisualUtilities.make_box(stripe_size, airfield_marking_color)
		stripe.position = Vector3(0.0, stripe_y, z)
		proxy.add_child(stripe)

	var hangar_height := height * 0.42
	var hangar_size := Vector3(size2d.x * 0.4, hangar_height, size2d.y * 0.32)
	var hangar := VisualUtilities.make_box(hangar_size, base_color)
	hangar.position = Vector3(-size2d.x * 0.22, hangar_height * 0.5, -size2d.y * 0.18)
	proxy.add_child(hangar)

	var roof_height := hangar_height * 0.25
	var roof := VisualUtilities.make_box(Vector3(hangar_size.x * 1.02, roof_height, hangar_size.z * 1.05), base_color.lightened(0.18))
	roof.position = Vector3(hangar.position.x, hangar_height + roof_height * 0.5, hangar.position.z)
	proxy.add_child(roof)

	var tower_height := height * 0.7
	var tower_size := Vector3(size2d.x * 0.12, tower_height, size2d.y * 0.12)
	var tower := VisualUtilities.make_box(tower_size, base_color.lightened(0.12))
	tower.position = Vector3(size2d.x * 0.36, tower_height * 0.5, -size2d.y * 0.2)
	proxy.add_child(tower)

	var cabin_height := height * 0.18
	var cabin := VisualUtilities.make_box(Vector3(tower_size.x * 1.6, cabin_height, tower_size.z * 1.6), base_color.lightened(0.22))
	cabin.position = Vector3(tower.position.x, tower_height + cabin_height * 0.5, tower.position.z)
	proxy.add_child(cabin)

	var radar := VisualUtilities.make_cylinder(size2d.x * 0.05, height * 0.12, base_color.lightened(0.3))
	radar.position = Vector3(tower.position.x, tower_height + cabin_height + height * 0.08, tower.position.z)
	proxy.add_child(radar)

	var max_height := maxf(hangar_height + roof_height, tower_height + cabin_height + height * 0.12)
	return maxf(max_height, runway_height + pad_height)

func _build_defense_base(proxy: Node3D, build_id: String, size2d: Vector2, height: float, base_color: Color) -> float:
	var accent := base_color.lightened(0.2)
	var dark := base_color.darkened(0.35)
	var mid := base_color.darkened(0.18)

	var base_height := height * 0.2
	var base_size := Vector3(size2d.x * 0.86, base_height, size2d.y * 0.86)
	var base := VisualUtilities.make_box(base_size, mid)
	base.position = Vector3(0.0, base_height * 0.5, 0.0)
	proxy.add_child(base)

	var ring_height := height * 0.12
	var ring_radius := minf(size2d.x, size2d.y) * 0.22
	var ring := VisualUtilities.make_cylinder(ring_radius, ring_height, base_color.lightened(0.05))
	ring.position = Vector3(0.0, base_height + ring_height * 0.5, 0.0)
	proxy.add_child(ring)

	var deck_height := height * 0.05
	var deck := VisualUtilities.make_box(Vector3(size2d.x * 0.58, deck_height, size2d.y * 0.58), dark)
	deck.position = Vector3(0.0, base_height + ring_height + deck_height * 0.5, 0.0)
	proxy.add_child(deck)

	var max_height := base_height + ring_height + deck_height

	match build_id:
		"defense_gun":
			var ammo_height := height * 0.14
			var ammo_size := Vector3(size2d.x * 0.16, ammo_height, size2d.y * 0.12)
			var ammo_a := VisualUtilities.make_box(ammo_size, dark)
			ammo_a.position = Vector3(-size2d.x * 0.22, ammo_height * 0.5, size2d.y * 0.24)
			proxy.add_child(ammo_a)
			var ammo_b := VisualUtilities.make_box(ammo_size, dark)
			ammo_b.position = Vector3(size2d.x * 0.22, ammo_height * 0.5, size2d.y * 0.24)
			proxy.add_child(ammo_b)

			var mast_height := height * 0.32
			var mast := VisualUtilities.make_cylinder(size2d.x * 0.025, mast_height, accent)
			mast.position = Vector3(0.0, base_height + ring_height + deck_height + mast_height * 0.5, -size2d.y * 0.18)
			proxy.add_child(mast)

			var radar := VisualUtilities.make_sphere(size2d.x * 0.06, accent.lightened(0.3))
			radar.position = Vector3(0.0, base_height + ring_height + deck_height + mast_height, -size2d.y * 0.18)
			radar.scale = Vector3(1.4, 0.5, 1.4)
			proxy.add_child(radar)
			max_height = maxf(max_height, base_height + ring_height + deck_height + mast_height)

		"defense_missile":
			var tube_height := height * 0.55
			var tube_radius := minf(size2d.x, size2d.y) * 0.06
			var tube_y := base_height + ring_height + deck_height + tube_height * 0.5
			for i in range(3):
				var x := (float(i) - 1.0) * (size2d.x * 0.18)
				var tube := VisualUtilities.make_cylinder(tube_radius, tube_height, accent)
				tube.position = Vector3(x, tube_y, -size2d.y * 0.06)
				proxy.add_child(tube)

				var cap := VisualUtilities.make_sphere(tube_radius * 0.7, accent.lightened(0.3))
				cap.position = Vector3(x, tube_y + tube_height * 0.5, -size2d.y * 0.06)
				proxy.add_child(cap)
			max_height = maxf(max_height, tube_y + tube_height * 0.5)

		"defense_laser":
			var emitter_height := height * 0.65
			var emitter_radius := minf(size2d.x, size2d.y) * 0.045
			var emitter_y := base_height + ring_height + deck_height + emitter_height * 0.5
			var emitter := VisualUtilities.make_cylinder(emitter_radius, emitter_height, accent.lightened(0.1))
			emitter.position = Vector3(0.0, emitter_y, -size2d.y * 0.08)
			proxy.add_child(emitter)

			var lens := VisualUtilities.make_sphere(emitter_radius * 1.2, Color(0.4, 0.9, 1.0, 1.0))
			lens.position = Vector3(0.0, emitter_y + emitter_height * 0.5, -size2d.y * 0.08)
			proxy.add_child(lens)

			var cell_height := height * 0.2
			var cell := VisualUtilities.make_box(Vector3(size2d.x * 0.16, cell_height, size2d.y * 0.12), dark)
			cell.position = Vector3(-size2d.x * 0.22, cell_height * 0.5, size2d.y * 0.22)
			proxy.add_child(cell)

			var cell_b := VisualUtilities.make_box(Vector3(size2d.x * 0.16, cell_height, size2d.y * 0.12), dark)
			cell_b.position = Vector3(size2d.x * 0.22, cell_height * 0.5, size2d.y * 0.22)
			proxy.add_child(cell_b)
			max_height = maxf(max_height, emitter_y + emitter_height * 0.5)

	return max_height

func _build_missile_carrier_ship(proxy: Node3D, size2d: Vector2, height: float, base_color: Color) -> float:
	# Ship sits on water - no building pad needed
	var hull_color := base_color
	var deck_color := base_color.lightened(0.1)
	var superstructure_color := base_color.lightened(0.2)
	var radar_color := Color(0.6, 0.65, 0.7, 1.0)

	# Hull - main body of the ship (elongated box with slight taper)
	var hull_height := height * 0.35
	var hull_length := size2d.x * 0.95
	var hull_width := size2d.y * 0.85
	var hull := VisualUtilities.make_box(Vector3(hull_length, hull_height, hull_width), hull_color)
	hull.position = Vector3(0.0, hull_height * 0.5, 0.0)
	proxy.add_child(hull)

	# Bow (front) - tapered section
	var bow_length := size2d.x * 0.15
	var bow_height := hull_height * 0.8
	var bow := VisualUtilities.make_box(Vector3(bow_length, bow_height, hull_width * 0.6), hull_color.darkened(0.05))
	bow.position = Vector3(-hull_length * 0.5 - bow_length * 0.4, bow_height * 0.5, 0.0)
	proxy.add_child(bow)

	# Deck surface
	var deck_height := height * 0.04
	var deck := VisualUtilities.make_box(Vector3(hull_length * 0.9, deck_height, hull_width * 0.9), deck_color)
	deck.position = Vector3(0.0, hull_height + deck_height * 0.5, 0.0)
	proxy.add_child(deck)

	# Superstructure / Bridge tower (aft section)
	var bridge_height := height * 0.5
	var bridge_length := size2d.x * 0.25
	var bridge_width := size2d.y * 0.5
	var bridge := VisualUtilities.make_box(Vector3(bridge_length, bridge_height, bridge_width), superstructure_color)
	bridge.position = Vector3(hull_length * 0.25, hull_height + bridge_height * 0.5, 0.0)
	proxy.add_child(bridge)

	# Bridge windows (dark strip)
	var window_height := bridge_height * 0.15
	var windows := VisualUtilities.make_box(Vector3(bridge_length * 1.02, window_height, bridge_width * 1.02), Color(0.1, 0.15, 0.2, 1.0))
	windows.position = Vector3(hull_length * 0.25, hull_height + bridge_height * 0.75, 0.0)
	proxy.add_child(windows)

	# VLS (Vertical Launch System) missile cells - main weapon
	var vls_height := height * 0.2
	var vls_length := size2d.x * 0.3
	var vls_width := size2d.y * 0.45
	var vls := VisualUtilities.make_box(Vector3(vls_length, vls_height, vls_width), hull_color.darkened(0.15))
	vls.position = Vector3(-hull_length * 0.15, hull_height + vls_height * 0.5, 0.0)
	proxy.add_child(vls)

	# VLS cell hatches (grid pattern)
	var hatch_size := minf(vls_length, vls_width) * 0.12
	var hatch_height := vls_height * 0.1
	for row in range(2):
		for col in range(4):
			var hatch_x := -hull_length * 0.15 + (float(col) - 1.5) * (hatch_size * 1.4)
			var hatch_z := (float(row) - 0.5) * (hatch_size * 1.6)
			var hatch := VisualUtilities.make_box(Vector3(hatch_size, hatch_height, hatch_size), Color(0.25, 0.28, 0.3, 1.0))
			hatch.position = Vector3(hatch_x, hull_height + vls_height + hatch_height * 0.5, hatch_z)
			proxy.add_child(hatch)

	# Radar mast on bridge
	var mast_height := height * 0.35
	var mast_radius := size2d.x * 0.02
	var mast := VisualUtilities.make_cylinder(mast_radius, mast_height, superstructure_color.darkened(0.1))
	mast.position = Vector3(hull_length * 0.25, hull_height + bridge_height + mast_height * 0.5, 0.0)
	proxy.add_child(mast)

	# Radar dome (sphere on mast)
	var radar_radius := size2d.x * 0.06
	var radar := VisualUtilities.make_sphere(radar_radius, radar_color)
	radar.position = Vector3(hull_length * 0.25, hull_height + bridge_height + mast_height, 0.0)
	radar.scale = Vector3(1.2, 0.7, 1.2)
	proxy.add_child(radar)

	# Secondary radar/antenna
	var antenna_height := height * 0.18
	var antenna := VisualUtilities.make_cylinder(mast_radius * 0.6, antenna_height, superstructure_color)
	antenna.position = Vector3(hull_length * 0.35, hull_height + bridge_height * 0.6 + antenna_height * 0.5, bridge_width * 0.3)
	proxy.add_child(antenna)

	# Funnel/exhaust stack
	var funnel_height := height * 0.25
	var funnel_radius := size2d.y * 0.08
	var funnel := VisualUtilities.make_cylinder(funnel_radius, funnel_height, hull_color.darkened(0.2))
	funnel.position = Vector3(hull_length * 0.08, hull_height + funnel_height * 0.5, 0.0)
	proxy.add_child(funnel)

	# Gun turret (fore)
	var turret_height := height * 0.15
	var turret_radius := size2d.y * 0.12
	var turret_base := VisualUtilities.make_cylinder(turret_radius, turret_height, hull_color.lightened(0.05))
	turret_base.position = Vector3(-hull_length * 0.35, hull_height + turret_height * 0.5, 0.0)
	proxy.add_child(turret_base)

	# Gun barrel
	var barrel_length := size2d.x * 0.12
	var barrel_radius := turret_radius * 0.15
	var barrel := VisualUtilities.make_cylinder(barrel_radius, barrel_length, hull_color.darkened(0.3))
	barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	barrel.position = Vector3(-hull_length * 0.35, hull_height + turret_height * 0.8, -turret_radius - barrel_length * 0.4)
	proxy.add_child(barrel)

	var max_height := hull_height + bridge_height + mast_height + radar_radius
	return max_height

# =============================================================================
# COMPOUND BUILDERS
# =============================================================================

func _add_barracks_compound(proxy: Node3D, target_size: Vector2, target_height: float) -> float:
	return _add_compound(
		proxy,
		target_size,
		target_height,
		barracks_compound_rows,
		barracks_compound_cols,
		barracks_compound_spacing,
		barracks_compound_models,
		barracks_model_scale
	)

func _add_factory_compound(proxy: Node3D, target_size: Vector2, target_height: float) -> float:
	return _add_compound(
		proxy,
		target_size,
		target_height,
		factory_compound_rows,
		factory_compound_cols,
		factory_compound_spacing,
		factory_compound_models,
		factory_model_scale
	)

func _add_hq_pentagon(proxy: Node3D, target_size: Vector2, target_height: float) -> float:
	var radius := minf(target_size.x, target_size.y) * hq_pentagon_radius_scale
	if radius <= 0.0:
		return 0.0

	var edge_len := 2.0 * radius * sin(PI / 5.0)
	var wing_depth := minf(target_size.x, target_size.y) * hq_pentagon_wing_depth_scale
	var wing_size := Vector2(maxf(10.0, edge_len), maxf(8.0, wing_depth))
	var max_height := 0.0

	for i in range(5):
		var angle := (TAU / 5.0) * float(i)
		var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var yaw := -rad_to_deg(angle) + 90.0
		var rotation := Vector3(0.0, yaw, 0.0)
		var model_height := _add_scene_model(proxy, hq_pentagon_model_path, wing_size, 0.0, hq_pentagon_model_scale, offset, rotation)
		if model_height > max_height:
			max_height = model_height

	if hq_pentagon_center_model_path != "" and ResourceLoader.exists(hq_pentagon_center_model_path):
		var center_size := Vector2(
			maxf(10.0, target_size.x * hq_pentagon_center_size_scale),
			maxf(10.0, target_size.y * hq_pentagon_center_size_scale)
		)
		var center_height := _add_scene_model(proxy, hq_pentagon_center_model_path, center_size, 0.0, hq_pentagon_center_model_scale)
		if center_height > max_height:
			max_height = center_height

	return max_height

func _add_compound(
	proxy: Node3D,
	target_size: Vector2,
	target_height: float,
	rows: int,
	cols: int,
	spacing: float,
	models: PackedStringArray,
	scale_hint: float
) -> float:
	var use_rows := maxi(1, rows)
	var use_cols := maxi(1, cols)
	var use_spacing := maxf(0.0, spacing)
	var total_spacing_x := use_spacing * float(use_cols - 1)
	var total_spacing_z := use_spacing * float(use_rows - 1)

	var cell_size := Vector2(
		maxf(6.0, (target_size.x - total_spacing_x) / float(use_cols)),
		maxf(6.0, (target_size.y - total_spacing_z) / float(use_rows))
	)

	var start := Vector2(
		-target_size.x * 0.5 + cell_size.x * 0.5,
		-target_size.y * 0.5 + cell_size.y * 0.5
	)

	var max_height := 0.0
	var idx := 0

	for row in range(use_rows):
		for col in range(use_cols):
			var path := models[idx % models.size()]
			idx += 1
			if path == "" or not ResourceLoader.exists(path):
				continue

			var offset := Vector3(
				start.x + float(col) * (cell_size.x + use_spacing),
				0.0,
				start.y + float(row) * (cell_size.y + use_spacing)
			)

			var model_height := _add_scene_model(proxy, path, cell_size, 0.0, scale_hint, offset)
			if model_height > max_height:
				max_height = model_height

	return max_height

# =============================================================================
# MODEL LOADING
# =============================================================================

func _add_scene_model(
	proxy: Node3D,
	scene_path: String,
	target_size: Vector2,
	target_height: float,
	scale_hint: float,
	offset := Vector3.ZERO,
	rotation_degrees := Vector3.ZERO
) -> float:
	var packed: Resource = load(scene_path)
	if packed == null or not (packed is PackedScene):
		return 0.0

	var instance := (packed as PackedScene).instantiate()
	if instance == null or not (instance is Node3D):
		return 0.0

	var model := instance as Node3D
	proxy.add_child(model)

	var bounds := _calc_model_aabb(model)
	if bounds.size == Vector3.ZERO:
		return 0.0

	var scale := scale_hint if scale_hint > 0.0 else 1.0
	if bounds.size.x > 0.0 and bounds.size.z > 0.0:
		scale *= minf(target_size.x / bounds.size.x, target_size.y / bounds.size.z)
	if target_height > 0.0 and bounds.size.y > 0.0:
		scale = minf(scale, target_height / bounds.size.y)

	model.scale = Vector3.ONE * scale
	var center := bounds.position + (bounds.size * 0.5)
	model.position = Vector3(-center.x * scale, -bounds.position.y * scale, -center.z * scale) + offset
	model.rotation_degrees = rotation_degrees

	return bounds.size.y * scale

func _calc_model_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	var min_v := Vector3.ZERO
	var max_v := Vector3.ZERO
	var root_inv := root.global_transform.affine_inverse()

	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)

		if not (node is MeshInstance3D):
			continue

		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue

		var local_aabb := mesh_instance.mesh.get_aabb()
		var xform := root_inv * mesh_instance.global_transform

		for corner in _get_aabb_corners(local_aabb):
			var p := xform * corner
			if first:
				min_v = p
				max_v = p
				first = false
			else:
				min_v = Vector3(minf(min_v.x, p.x), minf(min_v.y, p.y), minf(min_v.z, p.z))
				max_v = Vector3(maxf(max_v.x, p.x), maxf(max_v.y, p.y), maxf(max_v.z, p.z))

	if first:
		return AABB()

	combined.position = min_v
	combined.size = max_v - min_v
	return combined

func _get_aabb_corners(aabb: AABB) -> Array[Vector3]:
	var pos := aabb.position
	var size := aabb.size
	return [
		pos,
		pos + Vector3(size.x, 0.0, 0.0),
		pos + Vector3(0.0, size.y, 0.0),
		pos + Vector3(0.0, 0.0, size.z),
		pos + Vector3(size.x, size.y, 0.0),
		pos + Vector3(size.x, 0.0, size.z),
		pos + Vector3(0.0, size.y, size.z),
		pos + size,
	]
