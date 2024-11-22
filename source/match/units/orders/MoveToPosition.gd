extends "res://source/match/units/orders/Order.gd"

class_name MoveToPosition

const Moving = preload("res://source/match/units/actions/Moving.gd")

@export var MinDistance := 2.0

var _target_position :Vector3

static func is_applicable(unit):
	return Moving.is_applicable(unit)

func _init(target_position :Vector3, mark_to_be_queued := false) -> void:
	_target_position = target_position
	to_be_queued = mark_to_be_queued

func _to_string() -> String:
	return "{0};{1};{2}".format(["MoveToPosition", var_to_str(to_be_queued), Utils.Vec3.serialize(_target_position)])

static func new_from_string(order_string: String, ctx: OrderContext):
	var split = order_string.split(";")
	var newAction = MoveToPosition.new(Utils.Vec3.deserialize(split[2]), str_to_var(split[1]))
	return newAction

func get_action(behavior_manager):
	if behavior_manager._unit.global_position_yless.distance_to(_target_position*Vector3(1,0,1)) < MinDistance:
		queue_free()
		return null
	var action = Moving.new(_target_position)
	return action
