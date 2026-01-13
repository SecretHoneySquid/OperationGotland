@tool
class_name MapLoader
extends Node2D

## Map Loader
##
## Loads map data from JSON files. 2D rendering is disabled - game uses 3D terrain.

@export var map_path := "res://data/maps/test_map.json":
	set(value):
		map_path = value
		if is_inside_tree():
			load_map(map_path)

var _map_size := Vector2.ZERO
var _build_zones: Array = []
var _resource_nodes: Array = []
var _start_positions: Array = []
var _rally_targets: Array = []

func _ready() -> void:
	add_to_group("map_loader")
	# Prefer a centralized map selection from the autoload `GameState` when available
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		map_path = gs.map_path
	load_map(map_path)

func load_map(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MapLoader: Failed to open map at %s" % path)
		return
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("MapLoader: Invalid JSON in %s" % path)
		return
	_map_size = _read_size(data.get("size", {}))
	_build_zones = data.get("build_zones", [])
	_resource_nodes = data.get("resource_nodes", [])
	_start_positions = data.get("start_positions", [])
	_rally_targets = data.get("rally_targets", [])

func _read_size(data: Dictionary) -> Vector2:
	var width := float(data.get("width", 0.0))
	var height := float(data.get("height", 0.0))
	return Vector2(width, height)

func _vec2_from(data: Dictionary) -> Vector2:
	return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
