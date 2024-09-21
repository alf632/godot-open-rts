extends Node3D

@onready var _unit = get_parent()
@onready var _direct = find_child("DirectMovement")
@onready var _nav = find_child("NavMovement")

var domain = Constants.Match.Navigation.Domain.TERRAIN
var radius = 0.5

var pilotID :int:
	set(playerID):
		pilotID = playerID
		if playerID:
			pilot()
		else:
			unpilot()

var target := Vector3()

func move(movement_target: Vector3):
	target = movement_target

func stop():
	target = _unit.global_position

func pilot():
	_unit.find_child("Camera3D").make_current()
	_direct.rpc_handoff_authority.rpc(pilotID)
	_direct.set_physics_process(true)
	_nav.set_physics_process(false)

func unpilot():
	_direct.set_physics_process(false)
	_direct.rpc_handoff_authority(1)
	_nav.set_physics_process(true)
