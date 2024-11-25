extends "res://source/match/units/actions/Action.gd"

class_name ConstructingWhileInRange

const Worker = preload("res://source/match/units/Worker.gd")
const Structure = preload("res://source/match/units/Structure.gd")

var _target_unit = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


func _init(target_unit):
	_target_unit = target_unit

static func is_applicable(source_unit, target_unit):
	return (
		source_unit is Worker
		and target_unit is Structure
		and not target_unit.is_constructed()
		and source_unit.player == target_unit.player
	)

func _ready():
	_target_unit.tree_exited.connect(queue_free)
	_target_unit.constructed.connect(queue_free)
	_unit.get_node("Sparkling").enable()


func _exit_tree():
	_unit.get_node("Sparkling").disable()

func _to_string():
	return "{0};{1}".format(["ConstructingWhileInRange", _target_unit.name])

static func new_from_string(action_string: String, ctx: ActionContext):
	var split = action_string.split(";")
	var targetUnit = ctx.unit.get_parent().find_child(split[1], false, false)
	return ConstructingWhileInRange.new(targetUnit)

func _process(delta):
	if (
		not Utils.Match.UnitUtils.Movement.units_adhere(_unit, _target_unit)
		or _target_unit.is_constructed()
	):
		queue_free()
		return
	_target_unit.construct(delta * Constants.Match.Units.STRUCTURE_CONSTRUCTING_SPEED)
