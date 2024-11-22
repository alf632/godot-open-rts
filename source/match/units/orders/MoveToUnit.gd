extends "res://source/match/units/orders/Order.gd"

class_name MoveToUnit

const Unit = preload("res://source/match/units/Unit.gd")
const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")

var _target_unit :Unit

static func is_applicable(unit):
	return MovingToUnit.is_applicable(unit)

func _init(target_unit :Unit) -> void:
	_target_unit = target_unit

func _to_string() -> String:
	return "{0};{1}".format(["MoveToUnit", _target_unit.name])

static func new_from_string(order_string: String, ctx: OrderContext):
	var unit = ctx.unit.get_parent().find_node(order_string.split(";")[1])
	return MoveToUnit.new(unit)

func get_action(behavior_manager):
	if Utils.Match.Unit.Movement.units_adhere(behavior_manager._unit, _target_unit):
		queue_free()
		return null
	var action = MovingToUnit.new(_target_unit.global_position)
	return action
