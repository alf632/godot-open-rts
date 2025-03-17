extends "res://source/match/units/Unit.gd"

const kind = "Tank"
const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")
const AttackingWhileInRange = preload("res://source/match/units/actions/AttackingWhileInRange.gd")

@export var damping_factor := 1.0
@export var error_factor := 1.0
@export var stablizing_threshold := 20.0
@export var y_weight := 1.5

@export var turret_min_tilt := 0.0
@export var turret_max_tilt := 5.0

@onready var _movement = $Movement
@onready var _ta = $TargetAquire
@onready var _turret :Node3D = find_child("Geometry").find_child("turret", true, false)

@export var stablilizing_altitude_addition = 2.0
@onready var _original_altitude = _movement.altitude

func _get_idle_action():
	var enemy = _ta.get_enemy_unit()
	if enemy and ( not action or not action is AttackingWhileInRange ):
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
		
		var stable = true
		if is_instance_valid(action) and action is AttackingWhileInRange:
			stable = _movement.torque_towards_dir(action_dir.normalized(), state)
		else:
			stable = _movement.torque_towards_dir(navDir, state)
		
		if not stable:
			_movement.altitude = _original_altitude + stablilizing_altitude_addition
			dir = _movement._calculate_hold_altitude_dir()
		else:
			_movement.altitude = _original_altitude
			var nearbyDir = _movement.calculate_nearby_dir(_ta.friendly_in_range)
			navDir = lerp(navDir, nearbyDir.normalized(), nearbyDir.length())
			var altDir = _movement._calculate_hold_altitude_dir()
			dir = lerp(navDir, altDir.normalized(), altDir.length())
		
		state.apply_central_force(dir * _movement.linearForce)

func _physics_process(delta: float) -> void:
	if is_instance_valid(action) and action is AttackingWhileInRange:
		_ta.predict_trajectory = true
		# use length to setup turret
		var prediction_dir = _ta.last_terrain_hit - global_position
		var prediction_offset_length = action_dir.length() - prediction_dir.length()
		_tilt_turret(prediction_offset_length)
	else:
		_ta.predict_trajectory = false

func _tilt_turret(offset :float):
	var euler = _turret.transform.basis.get_euler()
	var current_tilt = euler.x
	var diff = clampf(-offset, deg_to_rad(-0.5), deg_to_rad(0.5))
	var new_tilt = clampf(current_tilt+diff, deg_to_rad(-turret_max_tilt), deg_to_rad(turret_min_tilt))
	euler.x = new_tilt
	_turret.transform.basis = Basis.from_euler(euler)
