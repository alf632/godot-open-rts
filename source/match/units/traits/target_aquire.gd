extends Area3D

const Unit = preload("res://source/match/units/Unit.gd")

@onready var _unit = get_parent()

var enemy_in_range = []
var friendly_in_range = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_dir_to_enemy():
	if enemy_in_range.is_empty():
		return Vector3()
	return enemy_in_range[0].global_position - _unit.global_position

func get_enemy_unit() -> Unit:
	if not enemy_in_range.is_empty():
		return enemy_in_range[0]
	
	return null

func _on_node_entered(node: Node3D) -> void:
	if node == _unit:
		return
		
	if node is Unit:
		if node.is_friendly_towards(_unit.player):
			friendly_in_range.append(node)
		else:
			enemy_in_range.append(node)


func _on_node_exited(node: Node3D) -> void:
	if node is Unit:
		enemy_in_range.erase(node)
		friendly_in_range.erase(node)
	
