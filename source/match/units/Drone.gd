extends "res://source/match/units/Unit.gd"

@onready var _movement = $Movement


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
		dir = _movement._nav.get_velocity()
		var stablelizing = _movement._calculate_stabilizing_torque()
		state.apply_torque(stablelizing[0] * _movement.angularForce)
		if stablelizing[1]:
			state.apply_torque(_movement._calculate_dir_torque(dir) * _movement.angularForce)
			var altDir = _movement._calculate_hold_altitude_dir()
			dir = lerp(dir, altDir.normalized(), altDir.length())
		
		state.apply_central_force(dir * _movement.linearForce)
