extends "res://source/match/units/actions/Action.gd"

class_name UnloadingResource

const Worker = preload("res://source/match/units/Worker.gd")
const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")

@export var unload_cooldown := 1.0
var _timer := 0.0
var _command_center = null


@onready var _unit = get_parent().get_parent()
@onready var _unit_movement_trait = _unit.find_child("Movement")


static func is_applicable(source_unit, target_unit):
	if source_unit is not Worker or target_unit is not ResourceUnit:
		return false
	
	return true


func _init(cc):
	_command_center = cc


func _ready():
	_command_center.tree_exited.connect(queue_free)

func _process(delta: float) -> void:
	#if Utils.Match.Unit.Movement.units_adhere(_unit, _command_center):
	#	queue_free()
		
	_timer += delta
	if _timer >= unload_cooldown:
		unload_resource_to_target_cc()
		_timer = 0.0


func unload_resource_to_target_cc():
	_command_center.unload_resources(_unit)
	
	if not _unit.is_loaded():
		queue_free()


func _rotate_unit_towards_command_center():
	_unit.global_transform = _unit.global_transform.looking_at(
		Vector3(
			_command_center.global_position.x,
			_unit.global_position.y,
			_command_center.global_position.z
		),
		Vector3(0, 1, 0)
	)

func _to_string() -> String:
	return "{0};{1}".format(["UnloadingResource",  _command_center.name])

static func new_from_string(action_string: String, ctx: ActionContext):
	var split = action_string.split(";")
	# search targetUnit name in Units
	var targetUnit = ctx.unit.get_parent().find_child(split[1], false, false)
	return UnloadingResource.new(targetUnit)
