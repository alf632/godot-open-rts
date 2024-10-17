extends Node3D

signal movement_finished
signal passive_movement_started
signal passive_movement_finished

@onready var _unit = get_parent()
@onready var _Match = find_parent("Match")
@onready var _Multiplayer = _Match.find_parent("Multiplayer")
@onready var _direct = find_child("DirectMovement")
@onready var _nav = find_child("NavMovement")

var domain = Constants.Match.Navigation.Domain.TERRAIN
var radius = 0.5

var target := Vector3()

func _ready() -> void:
	_nav.movement_finished.connect(func():movement_finished.emit())
	if is_multiplayer_authority():
		_nav.movement_finished.connect(func():stop.rpc())


func move(movement_target: Vector3):
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
	_direct.set_physics_process(true)
	_nav.set_physics_process(false)

func unpilot():
	_direct.set_physics_process(false)
	_direct.rpc_handoff_authority(1)
	_nav.set_physics_process(true)
	movement_finished.emit()
