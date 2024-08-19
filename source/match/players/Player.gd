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

@onready var _match = find_parent("Match")

var id:
	get():
		return get_index()

var _color_material = null

func _ready() -> void:
	var spawn_transform = _match.map.find_child("SpawnPoints").get_child(get_index()).global_transform
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
	$Units.add_child(unit)
	unit.global_transform = a_transform
	unit.setup_unit_groups(self)
	MatchSignals.unit_spawned.emit(unit)
func emit_changed():
	changed.emit()
