extends "res://source/match/units/actions/Action.gd"

class_name CollectingResource

const Worker = preload("res://source/match/units/Worker.gd")
const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")

@export var collecting_cooldown := 1.0
var _timer := 0.0
var _resource_unit = null


@onready var _unit = get_parent().get_parent()
@onready var _unit_movement_trait = _unit.find_child("Movement")


static func is_applicable(source_unit, target_unit):
	if source_unit is not Worker or target_unit is not ResourceUnit:
		return false
	
	return true


func _init(resource_unit):
	_resource_unit = resource_unit


func _ready():
	_resource_unit.tree_exited.connect(queue_free)

func _process(delta: float) -> void:
	#if Utils.Match.Unit.Movement.units_adhere(_unit, _resource_unit):
	#	queue_free()
		
	_timer += delta
	if _timer >= collecting_cooldown:
		collect_resource_from_target_unit()
		_timer = 0.0


func collect_resource_from_target_unit():
	_resource_unit.collect_resource(_unit)
	
	if _unit.is_full():
		queue_free()


func _rotate_unit_towards_resource_unit():
	_unit.global_transform = _unit.global_transform.looking_at(
		Vector3(
			_resource_unit.global_position.x,
			_unit.global_position.y,
			_resource_unit.global_position.z
		),
		Vector3(0, 1, 0)
	)

func _to_string() -> String:
	return "{0};{1}".format(["CollectingResource",  _resource_unit.name])

static func new_from_string(action_string: String, ctx: ActionContext):
	var split = action_string.split(";")
	var targetUnit = ctx.unit.find_parent("Match").find_child("Map").find_child("Resources").find_child(split[1])
	return CollectingResource.new(targetUnit)
