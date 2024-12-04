extends "res://source/match/units/Unit.gd"

const kind = "Drone"

const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")

@export var damping_factor := 1.0
@export var error_factor := 1.0
@export var stablizing_threshold := 20.0
@export var y_weight := 1.5

@onready var _movement = $Movement
var home_unit = null #for aircraft this is set to factory by productionqueue

func _get_idle_action():
	if home_unit and is_instance_valid(home_unit):
		return MovingToUnit.new(home_unit)
	
	return null
	
func _ready() -> void:
	super()
	$Movement.domain = Constants.Match.Navigation.Domain.AIR

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var dir := Vector3()
	if _movement.piloted:
		dir = _movement._direct.get_velocity()
		state.apply_central_force(dir * movement_speed)
		return
	else:
		
		var altDir = _movement._calculate_hold_altitude_dir()
		var navDir = _movement._nav.get_velocity()
		var currentDir = -state.transform.basis.z
		
		var targetDir = navDir - currentDir
		
		_movement.torque_towards_dir(targetDir, state)
		
		dir = lerp(currentDir, altDir.normalized(), altDir.length())
		state.apply_central_force(dir * _movement.linearForce)
