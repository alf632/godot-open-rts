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

func _calculate_stabilizing_torque():
	var torque = Vector3()
	var stable = true
	
	var euler = global_rotation
	# stabilize roll
	if abs(euler.z) > 0.02:
		torque.z = clampf(-euler.z, -5, 5)
		stable = false
	
	#stabilize pitch
	if abs(euler.x) > 0.02:
		torque.x = clampf(-euler.x, -5, 5)
		stable = false
	
	return [torque, stable]

func _calculate_dir_torque(dir :Vector3) -> Vector3:
	var torque = Vector3()
	var dir2 = Vector2(dir.x, dir.z)
	var currentAngle = global_rotation.y
	torque.y = dir2.rotated(currentAngle+PI).x
	
	return torque

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
