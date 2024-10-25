extends "res://source/match/units/orders/Order.gd"

class_name MoveToUnit

const Unit = preload("res://source/match/units/Unit.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")

@export var MinDistance := 1

var _target_unit :Unit

static func is_applicable(unit):
	return Moving.is_applicable(unit)

func _init(target_unit :Unit) -> void:
	_target_unit = target_unit

func _to_string() -> String:
	return "{0};{1}".format(["MoveToUnit", _target_unit.name])

func new_from_string(order_string: String, ctx: OrderContext):
	var unit = ctx.unit.get_parent().find_node(order_string.split(";")[1])
	return MoveToUnit.new(unit)

func get_action(behavior_manager):
	if behavior_manager._unit.global_position.distance_to(_target_unit.global_position) < MinDistance:
		queue_free()
		return null
	var action = Moving.new(_target_unit.global_position)
	return action
