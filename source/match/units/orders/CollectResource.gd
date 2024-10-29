extends "res://source/match/units/orders/Order.gd"

class_name Collect

const CollectingResourcesSequentially = preload("res://source/match/units/actions/CollectingResourcesSequentially.gd")
const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")

@export var MinDistance := 1

var _target_unit :ResourceUnit

static func is_applicable(unit, _target_unit):
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
	var action = CollectingResourcesSequentially.new(_target_unit)
	return action
