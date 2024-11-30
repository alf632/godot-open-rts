extends Node3D

signal movement_finished
signal passive_movement_started
signal passive_movement_finished

@onready var _unit = get_parent()
@onready var _Match = find_parent("Match")
@onready var _Multiplayer = _Match.find_parent("Multiplayer")
@onready var _direct = find_child("DirectMovement")
@onready var _nav = find_child("NavMovement")
@onready var _Terrain = _Match.find_child("Terrain3D")

@export var altitude = 0.2
@export var linearForce = 12.0
@export var angularForce = 1.0

var domain = Constants.Match.Navigation.Domain.TERRAIN
var radius = 0.5

var target := Vector3()
var piloted = false

func _ready() -> void:
	_nav.movement_finished.connect(func():movement_finished.emit())
	if is_multiplayer_authority():
		_nav.movement_finished.connect(func():stop.rpc())
	if domain == Constants.Match.Navigation.Domain.AIR:
		altitude = 3.0

func _physics_process(delta: float) -> void:
	
	if _unit is CharacterBody3D:
		var dir = Vector3()
		if piloted:
			dir = _direct.get_velocity()
		else:
			var altDir = _calculate_hold_altitude_dir()
			dir = lerp(_nav.get_velocity(), altDir.normalized(), altDir.length())
		
		_unit.velocity = dir.normalized() * _unit.movement_speed * delta
		_unit.move_and_slide()
	


func _calculate_hold_altitude_dir():
	var t_height = _Terrain.storage.get_height(_unit.global_position)
	var u_height = _unit.global_position.y
	var power = clampf((t_height+altitude)-u_height, -1.0, 1.0)
	if abs(power) <= 0.1:
		return Vector3() 
	return Vector3.UP * power

func normalize_diff_angle(v : float) -> float:
	return fmod((v) + PI, 2 * PI) - PI

func torque_towards_dir(dir: Vector3, state: PhysicsDirectBodyState3D) -> void:
	var dir2d = dir * Vector3(1,0,1)
	
	var current_rotation = state.transform.basis
	var target_rotation = Basis.looking_at(dir2d)
	# Differenz zwischen Ziel- und aktueller Rotation (als Quaternion)
	var rotation_error = target_rotation * current_rotation.inverse()
	if rotation_error.get_euler().length() < _unit.stablizing_threshold:
		return
	
	var target_angle = target_rotation.get_euler()
	var source_angle = current_rotation.get_euler()
	var hori_angle = normalize_diff_angle(target_angle.y - source_angle.y)
	var verti_angle = normalize_diff_angle(target_angle.x - source_angle.x)
	var roll_angle = normalize_diff_angle(target_angle.z - source_angle.z)
	var angular_velocity_euler = Basis.looking_at(state.angular_velocity).get_euler()
	var velocity_max = 5.0
	var velocity_accel_step = 0.1
	var velocity_accel_step_velocity_diff = 3.0
	var velocity_accel_step_dir_length = 0.5 * PI  # 45 degrees
	var hori_step_dir_factor = min(max(hori_angle, -velocity_accel_step_dir_length),
		velocity_accel_step_dir_length) / velocity_accel_step_dir_length
	var verti_step_dir_factor = min(max(verti_angle, -velocity_accel_step_dir_length),
		velocity_accel_step_dir_length) / velocity_accel_step_dir_length
	var roll_step_dir_factor = min(max(roll_angle, -velocity_accel_step_dir_length),
		velocity_accel_step_dir_length) / velocity_accel_step_dir_length
	var wanted_velocity_euler = Vector3(
		hori_step_dir_factor * velocity_max,
		verti_step_dir_factor * velocity_max,
		roll_step_dir_factor * velocity_max
	)
	var damp : float = _unit.damping_factor
	var given_velocity_euler = Basis.looking_at(state.angular_velocity).get_euler()
	var accel_velocity_euler = Vector3(
		(min(max(wanted_velocity_euler.x - given_velocity_euler.x,
			-velocity_accel_step_velocity_diff), velocity_accel_step_velocity_diff) /
			velocity_accel_step_velocity_diff) * velocity_accel_step * damp,
		(min(max(wanted_velocity_euler.y - given_velocity_euler.y,
			-velocity_accel_step_velocity_diff), velocity_accel_step_velocity_diff) /
			velocity_accel_step_velocity_diff) * velocity_accel_step * damp,
		(min(max(wanted_velocity_euler.z - given_velocity_euler.z,
			-velocity_accel_step_velocity_diff), velocity_accel_step_velocity_diff) /
			velocity_accel_step_velocity_diff) * velocity_accel_step * damp
	)
	state.apply_torque(accel_velocity_euler)
	return
	# Winkelgeschwindigkeit als Vektor
	var angular_velocity = state.angular_velocity
	# Drehmoment berechnen (Proportional zur Winkelgeschwindigkeit und dem Rotationsfehler)
	var torque = -angular_velocity * _unit.damping_factor - rotation_error.get_euler() * _unit.error_factor
	# Drehmoment anwenden
	state.apply_torque(torque * Vector3(1,_unit.y_weight,1))

func look_there(direction: Vector3, up: Vector3 = Vector3.UP) -> Basis:
	# Berechne den rechten Vektor (rechtshändiges Koordinatensystem)
	var right = direction.cross(up).normalized()
	# Berechne den neuen "oben"-Vektor
	var new_up = right.cross(direction).normalized()
	# Erstelle eine Rotationsmatrix aus den Basisvektoren
	return Basis(-right, new_up, -direction.normalized())
	


func move(movement_target: Vector3):
	target = movement_target
	_nav.move(target)
	return
	
	if is_multiplayer_authority():
		rpc_move.rpc(movement_target)
	else:
		rpc_request_move.rpc_id(get_multiplayer_authority(), movement_target)

@rpc("authority", "reliable", "call_local")
func rpc_move(movement_target: Vector3):
	target = movement_target
	_nav.move(target)

@rpc("any_peer", "reliable")
func rpc_request_move(movement_target: Vector3):
	# TODO: check if player is actually controlling the unit
	if not is_multiplayer_authority():
		return
	rpc_move.rpc(movement_target)

@rpc("authority", "reliable", "call_remote")
func stop():
	target = _unit.global_position
	_nav.stop()

func pilot():
	_unit.find_child("Camera3D").make_current()
	_direct.request_authority()
	#_direct.set_physics_process(true)
	#_nav.set_physics_process(false)
	piloted = true

func unpilot():
	#_direct.set_physics_process(false)
	_direct.rpc_handoff_authority(1)
	#_nav.set_physics_process(true)
	movement_finished.emit()
	piloted = false
