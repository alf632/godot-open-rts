extends "res://source/match/units/actions/Action.gd"
class_name Moving

var _target_position = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")
@onready var _movement_trait = _unit.find_child("Movement")


static func is_applicable(unit):
	return unit.find_child("Movement") != null


func _init(target_position):
	_target_position = target_position


func _ready():
	_movement_trait.move(_target_position)
	_movement_trait.movement_finished.connect(_on_movement_finished)


func _exit_tree():
	if is_inside_tree():
		_movement_trait.stop()


func _on_movement_finished():
	queue_free()

func _to_string() -> String:
	return "{0};{1}".format(["Moving",  Utils.Vec3.serialize(_target_position)])

static func new_from_string(action_string: String):
	return Moving.new(Utils.Vec3.deserialize(action_string.split(";")[1]))
