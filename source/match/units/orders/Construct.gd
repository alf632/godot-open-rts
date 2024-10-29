extends "res://source/match/units/orders/Order.gd"

class_name Construct

const Constructing = preload("res://source/match/units/actions/Constructing.gd")
const Unit = preload("res://source/match/units/Unit.gd")

@export var MinDistance := 1

var _target_unit :Unit

static func is_applicable(unit, _target_unit):
	return Constructing.is_applicable(unit, _target_unit)

func _init(target_unit :Unit) -> void:
	_target_unit = target_unit

func _to_string() -> String:
	return "{0};{1}".format(["Construct", _target_unit.name])

static func new_from_string(order_string: String, ctx: OrderContext):
	var split = order_string.split(";")
	var targetUnit = ctx.unit.get_parent().find_child(split[1])
	return Construct.new(targetUnit)

func get_action(behavior_manager):
	if _target_unit.is_constructed():
		queue_free()
		return null
	var action = Constructing.new(_target_unit)
	return action
