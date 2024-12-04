extends "res://source/match/units/orders/Order.gd"

class_name Collect

const CollectingResource = preload("res://source/match/units/actions/CollectingResource.gd")
const UnloadingResource = preload("res://source/match/units/actions/UnloadingResource.gd")
const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")

const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")

var _target_unit :ResourceUnit

static func is_applicable(unit, _target_unit):
	if not _target_unit is ResourceUnit:
		return false
	return CollectingResourcesSequentially.is_applicable(unit, _target_unit)

func _init(target_unit :ResourceUnit) -> void:
	_target_unit = target_unit

func _to_string() -> String:
	return "{0};{1}".format(["CollectResource", _target_unit.name])

static func new_from_string(order_string: String, ctx: OrderContext):
	var split = order_string.split(";")
	var targetUnit = ctx.unit.find_parent("Match").find_child("Map").find_child("Resources").find_child(split[1])
	return Collect.new(targetUnit)

func get_action(behavior_manager):
	if not _target_unit:
		queue_free()
		return null
	var unit = behavior_manager.get_parent()
	if unit.is_full():
		if not Utils.Match.UnitUtils.Movement.units_adhere(unit, _target_unit.in_base.command_center):
			return MovingToUnit.new(_target_unit.in_base.command_center)
		else:
			return UnloadingResource.new(_target_unit.in_base.command_center)
	else:
		if not Utils.Match.UnitUtils.Movement.units_adhere(unit, _target_unit):
			return MovingToUnit.new(_target_unit)
		else:
			return CollectingResource.new(_target_unit)
	
	var action = CollectingResourcesSequentially.new(_target_unit)
	return action
