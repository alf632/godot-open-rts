extends Node3D

const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const Unit = preload("res://source/match/units/Unit.gd")
const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")

const BaseTerrainScene = preload("res://source/match/units/traits/BaseTerrain.tscn")
const BaseStructureOverlayScene = preload("res://source/match/base_structure_overlay.tscn")
const BaseStructureOverlay = preload("res://source/match/base_structure_overlay.gd")

@onready var _base_handler = get_parent().get_parent()

var command_center :CommandCenter
var structures = {}
var units = []
var resources = []

var color :Color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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

func unregister_unit(unit :Unit):
	if unit in units:
		#search for unit in all territories belonging to base:
		var found = false
		for structure in structures.keys():
			if structure.find_child("BaseTerrain").find_unit(unit):
				found = true
				break
		if not found:
			units.erase(unit)

func register_resource(resource: ResourceUnit):
	if not resource in resources:
		resources.append(resource)

func unregister_resource(resource: ResourceUnit):
	if resource in resources:
		resources.erase(resource)
