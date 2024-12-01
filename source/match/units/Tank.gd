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

@export var stablilizing_altitude_addition = 2.0
@onready var _original_altitude = _movement.altitude

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
		var navDir = _movement._nav.get_velocity()
		var stable = _movement.torque_towards_dir(navDir, state)
		
		if not stable:
			_movement.altitude = _original_altitude + stablilizing_altitude_addition
			dir = _movement._calculate_hold_altitude_dir()
		else:
			_movement.altitude = _original_altitude
			var altDir = _movement._calculate_hold_altitude_dir()
			dir = lerp(navDir, altDir.normalized(), altDir.length())
		
		state.apply_central_force(dir * _movement.linearForce)
