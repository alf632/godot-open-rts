extends Node3D

signal changed

const Structure = preload("res://source/match/units/Structure.gd")
const CommandCenter = preload("res://source/match/units/CommandCenter.tscn")
const Drone = preload("res://source/match/units/Drone.tscn")
const Worker = preload("res://source/match/units/Worker.tscn")

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

var play_mode = Constants.PlayModes.Pilot
var piloted_unit = null
var last_command_center = null

var id:
	get():
		return get_index()

var _color_material = null

func _ready() -> void:
	add_to_group("players")
	var spawn_transform = _match.map.find_child("SpawnPoints").get_child(spawn).global_transform
	spawn_player_units(spawn_transform)

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

func spawn_player_units(spawn_transform):
	setup_and_spawn_unit(CommandCenter.instantiate(), spawn_transform, false)
	setup_and_spawn_unit(
		Drone.instantiate(), spawn_transform.translated(Vector3(-2, 0, -2))
	)
	setup_and_spawn_unit(
		Worker.instantiate(), spawn_transform.translated(Vector3(-3, 0, 3))
	)
	setup_and_spawn_unit(
		Worker.instantiate(), spawn_transform.translated(Vector3(3, 0, 3))
	)


func setup_and_spawn_unit(unit, a_transform, mark_structure_under_construction = true):
	if unit is Structure and mark_structure_under_construction:
		unit.mark_as_under_construction()
	unit.name = "unit_{0}_{1}".format([unit.get_instance_id(),self.id])
	print(unit.name)
	_units.add_child(unit)
	unit.global_transform = a_transform.translated(Vector3(0, _match.map.terrain.storage.get_height(a_transform.origin)+1, 0))
	
	MatchSignals.unit_spawned.emit(unit)
	
func emit_changed():
	changed.emit()
