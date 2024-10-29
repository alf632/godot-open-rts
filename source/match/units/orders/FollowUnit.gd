extends "res://source/match/units/orders/Order.gd"

class_name FollowUnit

const Unit = preload("res://source/match/units/Unit.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")

@export var MinDistance := 1

var _target_unit :Unit

static func is_applicable(unit):
	return Moving.is_applicable(unit)

func _init(target_unit :Unit) -> void:
	_target_unit = target_unit

func _to_string() -> String:
	return "{0};{1}".format(["FollowUnit", _target_unit])

static func new_from_string(order_string: String, ctx: OrderContext):
	var split = order_string.split(";")
	var targetUnit = ctx.unit.get_parent().find_child(split[1])
	return FollowUnit.new(targetUnit)

func get_action(behavior_manager):
	if behavior_manager._unit.global_position.distance_to(_target_unit.global_position) < MinDistance:
		return null
	var action = Moving.new(_target_unit.global_position)
	return action
