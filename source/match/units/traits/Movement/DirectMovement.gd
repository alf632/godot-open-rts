extends Node3D

@onready var _match = find_parent("Match")
@onready var _moveTrait = get_parent()
@onready var _unit = _moveTrait.get_parent()
@onready var _UI_pos = find_child("PosValue")
@onready var _UI_velocity = find_child("VelocityValue")
@onready var _dir_synchronizer = find_child("dirSynchronizer")

@export var dir := Vector3()

func _ready() -> void:
	set_physics_process(false)

var target: Vector3:
	get():
		return _moveTrait.target

var piloted: bool:
	get():
		return _moveTrait.pilotID > 0

func _physics_process(delta):
	var _interim_speed = _unit.movement_speed * delta

	if _dir_synchronizer.is_multiplayer_authority():
		dir = _calculate_input_dir()
	_unit.velocity = dir * _interim_speed
	_unit.move_and_slide()
	_UI_pos.text = str(_unit.global_position)
	_UI_velocity.text = str(_unit.velocity)

func _calculate_input_dir():
	var xz_input = Input.get_vector("move_map_left", "move_map_right", "move_map_up", "move_map_down")
	var y_input = Input.get_axis("move_lower", "move_higher")
	var _dir = Vector3(xz_input.x, y_input, xz_input.y).rotated(Vector3.UP, _unit.rotation.y)
	return _dir

func request_authority():
	if multiplayer.get_unique_id() != _dir_synchronizer.get_multiplayer_authority():
		rpc_request_authority.rpc_id(_dir_synchronizer.get_multiplayer_authority())

@rpc("any_peer", "reliable")
func rpc_request_authority():
	rpc_handoff_authority.rpc(multiplayer.get_remote_sender_id())
	if multiplayer.get_unique_id() == 1:
		set_physics_process(true)

@rpc("authority", "reliable", "call_local")
func rpc_handoff_authority(new_authority):
	print("handoff authority from {0} to {1} on {2} by {3}".format([get_multiplayer_authority(), new_authority, multiplayer.get_unique_id(), multiplayer.get_remote_sender_id()]))

	# a player exited unit and gave authority back to the server
	if new_authority == 1 and multiplayer.get_remote_sender_id() != 1:
		set_physics_process(false)
	_dir_synchronizer.set_multiplayer_authority(new_authority)
