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
@export var stablizing_threshold = 0.2

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
	var t_height = _Terrain.data.get_height(_unit.global_position)
	var u_height = _unit.global_position.y
	var power = clampf((t_height+altitude)-u_height, -1.0, 1.0)
	if abs(power) <= 0.1:
		return Vector3() 
	return Vector3.UP * power

func normalize_diff_angle(v : float) -> float:
	return fmod((v) + PI, 2 * PI) - PI

func torque_towards_dir(dir: Vector3, state: PhysicsDirectBodyState3D) -> bool:
	var stable = true
	var updiff = Vector3.UP.angle_to(state.transform.basis.y)
	if updiff > _unit.stablizing_threshold:
		stable = false
	
	
	var dir2d = (dir * Vector3(1,0,1)).normalized()
	
	var current_rotation = state.transform.basis
	var target_rotation :Basis
	if stable and dir != Vector3():
		target_rotation = Basis.looking_at(dir2d, Vector3.UP, false)
	else:
		target_rotation = Basis.looking_at((-state.transform.basis.z * Vector3(1,0,1)).normalized(), Vector3.UP, false)
	
	var correcting_rotation = target_rotation * current_rotation.inverse()
	var correcting_euler = correcting_rotation.get_euler()
	
	var correcting_force_roll = clampf(correcting_euler.z, -PI/2, PI/2)/PI/2
	var torque = Vector3(0,0,correcting_force_roll)
	state.apply_torque(torque * angularForce)
	
	var correcting_force_pitch = clampf(correcting_euler.x, -PI/2, PI/2)/PI/2
	torque = Vector3(correcting_force_pitch,0,0)
	state.apply_torque(torque * angularForce)
	
	if dir != Vector3() and stable:
		var correcting_force_yaw = clampf(correcting_euler.y, -PI/2, PI/2)/PI/2
		torque = Vector3(0,correcting_force_yaw,0)
		state.apply_torque(torque * angularForce * _unit.y_weight)
		
	return stable
	

func calculate_nearby_dir(units):
	if not units or len(units) == 0:
		return Vector3()
		
	var dir = Vector3()
	for otherUnit in units:
		var unitdir =   _unit.global_position_yless - otherUnit.global_position_yless
		dir = lerp(dir, unitdir.normalized(), 1 - clampf(unitdir.length()+_unit.radius, 0.0, 4.0)/4.0)
	
	return dir

func look_there(direction: Vector3, up: Vector3 = Vector3.UP) -> Basis:
	# Berechne den rechten Vektor (rechtshändiges Koordinatensystem)
	var right = direction.cross(up).normalized()
	# Berechne den neuen "oben"-Vektor
	var new_up = right.cross(direction).normalized()
	# Erstelle eine Rotationsmatrix aus den Basisvektoren
	return Basis(-right, new_up, -direction.normalized())
	


func move(movement_target: Vector3):
	target = movement_target
	var t_height = _Terrain.data.get_height(movement_target)
	if target.y < t_height + + altitude:
		target.y = t_height + + altitude
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
