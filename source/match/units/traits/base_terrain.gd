extends Node3D

const Structure = preload("res://source/match/units/Structure.gd")
const Unit = preload("res://source/match/units/Unit.gd")
const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")
const StaticMovementObstacle = preload("res://source/match/units/traits/StaticMovementObstacle.gd")

@onready var _shape = $Area3D/CollisionShape3D
@onready var _area = $Area3D
@onready var _unit = get_parent()

var base 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_shape.shape.radius = _unit.base_territory_radius


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func find_unit(unit :Unit):
	var bodies = _area.get_overlapping_bodies()
	for body in bodies:
		if unit == body.get_parent():
			return true
	return false


func _on_node_entered(node: Node3D) -> void:
	var nodename = node.name
	if node is StaticMovementObstacle and node.get_parent() is Structure:
		base.register_structure(node.get_parent())
	elif node is Unit:
		base.register_unit(node)
	elif node is ResourceUnit:
		base.register_resource(node)


func _on_node_exited(node: Node3D) -> void:
	if node is Structure:
		base.unregister_structure(node)
	elif node is Unit:
		base.unregister_unit(node)
	elif node is ResourceUnit:
		base.unregister_resource(node)
