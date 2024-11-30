extends "res://source/match/units/Unit.gd"

const kind = "Tank"
const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")
const AttackingWhileInRange = preload("res://source/match/units/actions/AttackingWhileInRange.gd")

@export var damping_factor := 1.0
@export var error_factor := 1.0
@export var stablizing_threshold := 20.0
@export var y_weight := 1.5

@onready var _movement = $Movement
@onready var _ta = $TargetAquire

func _get_idle_action():
	var enemy = _ta.get_enemy_unit()
	if enemy:
		return AttackingWhileInRange.new(enemy)
	
	return null

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var dir := Vector3()
	if _movement.piloted:
		dir = _movement._direct.get_velocity()
		state.apply_central_force(dir * movement_speed)
		return
	else:
		var altDir = _movement._calculate_hold_altitude_dir()
		var navDir = _movement._nav.get_velocity()
		dir = lerp(navDir, altDir.normalized(), altDir.length())
		if navDir == Vector3():
			navDir = -state.transform.basis.z
		
		_movement.torque_towards_dir(navDir, state)
		
		state.apply_central_force(dir * _movement.linearForce)
