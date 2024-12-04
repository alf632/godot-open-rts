extends "res://source/match/units/Unit.gd"

const ROTOR_SPEED = 800.0  # degrees/s

const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

@export var y_weight := 1.5
@export var stablilizing_altitude_addition = 0.0

@onready var _movement = $Movement
@onready var _original_altitude = _movement.altitude
@onready var _ta = $TargetAquire

func _ready():
	await super()
	find_child("Movement").domain = Constants.Match.Navigation.Domain.AIR

func _get_idle_action():
	var enemy = _ta.get_enemy_unit()
	if enemy:
		return AttackingWhileInRange.new(enemy)
	
	return null

func _physics_process(delta):
	find_child("Rotor").rotation_degrees.y += ROTOR_SPEED * delta

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var dir := Vector3()
	if _movement.piloted:
		dir = _movement._direct.get_velocity()
		state.apply_central_force(dir * movement_speed)
		return
	else:
		var navDir = _movement._nav.get_velocity()
		if (navDir == Vector3() or _movement._nav.path_index == len(_movement._nav.path)-1) and is_instance_valid(action) and action is MovingToUnit:
			if not Utils.Match.UnitUtils.Movement.units_adhere(self, action._target_unit):
				navDir = (action._target_unit.global_position_yless - global_position_yless).normalized()
		var stable = _movement.torque_towards_dir(navDir, state)
		
		if not stable:
			_movement.altitude = _original_altitude + stablilizing_altitude_addition
			dir = _movement._calculate_hold_altitude_dir()
		else:
			_movement.altitude = _original_altitude
			var altDir = _movement._calculate_hold_altitude_dir()
			dir = lerp(navDir, altDir.normalized(), altDir.length())
		
		state.apply_central_force(dir * _movement.linearForce)
