extends Node3D

signal changed

@export var resource_a = 0:
	set(value):
		resource_a = value
		emit_changed()
@export var resource_b = 0:
	set(value):
		resource_b = value
		emit_changed()
@export var color = Color.WHITE

@export var spawn := 0

@onready var _match = find_parent("Match")
@onready var _units = _match.find_child("Units")
@onready var _unit_spawner = _match.find_child("UnitSpawner")

var play_mode = Constants.PlayModes.Pilot
var pilotable = null
var piloted_unit = null
var last_command_center = null
var factions = []

var command_center = null: set = _set_command_center
func _set_command_center(value):
	if value != null:
		last_command_center = value
	command_center = value

var id:
	get():
		return get_index()

var _color_material = null

func _ready() -> void:
	add_to_group("players")
	#var spawn_transform = _match.map.find_child("SpawnPoints").get_child(spawn).global_transform

func add_resources(resources):
	for resource in resources:
		set(resource, get(resource) + resources[resource])

func has_resources(resources):
	if FeatureFlags.allow_resources_deficit_spending:
		return true
	for resource in resources:
		if get(resource) < resources[resource]:
			return false
	return true


func subtract_resources(resources):
	for resource in resources:
		set(resource, get(resource) - resources[resource])


func get_color_material():
	if _color_material == null:
		_color_material = StandardMaterial3D.new()
		_color_material.vertex_color_use_as_albedo = true
		_color_material.albedo_color = color
		_color_material.metallic = 1
	return _color_material


func setup_and_spawn_unit(unitType, a_transform, constructing = true):
	var data = {"unitType": unitType, "transform": a_transform, "playerID": get_index(), "constructing": constructing}
	if multiplayer.is_server():
		return _do_spawn(data)
	else:
		_request_spawn.rpc_id(get_multiplayer_authority(), data)

@rpc("any_peer", "reliable", "call_remote")
func _request_spawn(data):
	_do_spawn(data)

func _do_spawn(data):
	return _unit_spawner.spawn(data)
	
func emit_changed():
	changed.emit()
