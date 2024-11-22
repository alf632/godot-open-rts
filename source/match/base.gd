extends Node3D

const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const Worker = preload("res://source/match/units/Worker.gd")
const Unit = preload("res://source/match/units/Unit.gd")
const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")

const BaseTerrainScene = preload("res://source/match/units/traits/BaseTerrain.tscn")
const BaseStructureOverlayScene = preload("res://source/match/base_structure_overlay.tscn")
const BaseStructureOverlay = preload("res://source/match/base_structure_overlay.gd")

const CollectResource = preload("res://source/match/units/orders/CollectResource.gd")

@onready var _base_handler = get_parent().get_parent()

var command_center :CommandCenter
var structures = {}
var units = []
var resources = []

var color :Color

var _check_intervall := 1.0
var _time_passed := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not multiplayer.is_server():
		set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_time_passed += delta
	if _time_passed >= _check_intervall:
		_time_passed = 0.0
		for unit in units:
			if unit is Worker and not unit.order:
				if len(resources) > 0:
					unit.order = CollectResource.new(resources[randi_range(0, len(resources)-1)])

func register_structure(unit :Structure):
	if unit in structures:
		return
	var overlay = BaseStructureOverlayScene.instantiate()
	overlay.position = Vector2(unit.position.x,unit.position.z)
	overlay.radius = unit.base_territory_radius
	overlay.color = color
	_base_handler.add_overlay(overlay)
	structures[unit] = overlay
	unit.in_base = self
	unit.connect("child_exiting_tree", unregister_structure)
	var baseTerrain = BaseTerrainScene.instantiate()
	baseTerrain.base = self
	unit.add_child(baseTerrain)

func unregister_structure(unit :Structure):
	structures[unit].queue_free()
	structures.erase(unit)
	_base_handler.refresh_overlays.call_deferred()

func register_unit(unit :Unit):
	if not unit in units:
		units.append(unit)
		unit.in_base = self

func unregister_unit(unit :Unit):
	if unit in units:
		#search for unit in all territories belonging to base:
		var found = false
		for structure in structures.keys():
			if structure.find_child("BaseTerrain", false, false).find_unit(unit):
				found = true
				break
		if not found:
			units.erase(unit)
			unit.in_base = null

func register_resource(resource: ResourceUnit):
	if not resource in resources:
		resources.append(resource)
		resource.in_base = self

func unregister_resource(resource: ResourceUnit):
	if resource in resources:
		resources.erase(resource)
		resource.in_base = null
