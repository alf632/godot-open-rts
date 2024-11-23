extends "res://source/match/units/actions/Moving.gd"

class_name MovingToUnit

var _target_unit = null

func _init(target_unit):
	_target_unit = target_unit

static func is_applicable(unit):
	return unit.find_child("Movement") != null
	
func _process(_delta):
	if Utils.Match.UnitUtils.Movement.units_adhere(_unit, _target_unit):
		queue_free()


func _ready():
	_target_unit.tree_exited.connect(queue_free)
	_target_position = (
		_target_unit.global_position_yless
		+ (
			(_unit.global_position_yless - _target_unit.global_position_yless).normalized()
			* _target_unit.radius
		)
	)
	super()


func _on_movement_finished():
	if Utils.Match.UnitUtils.Movement.units_adhere(_unit, _target_unit):
		queue_free()
	else:
		_target_position = _target_unit.global_position
		_movement_trait.move(_target_position)

func _to_string() -> String:
	return "{0};{1}".format(["MovingToUnit",  _target_unit.name])

static func new_from_string(action_string: String, ctx: ActionContext):
	var split = action_string.split(";")
	# search targetUnit name in Units
	var targetUnit = ctx.unit.get_parent().find_child(split[1], false, false)
	if not targetUnit:
		# if not found in units, search targetUnit name in Resources
		targetUnit = ctx.unit.find_parent("Match").find_child("Map").find_child("Resources").find_child(split[1])
	return MovingToUnit.new(targetUnit)
