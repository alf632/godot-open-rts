extends Node3D

const PilotScene = preload("res://source/match/units/Pilot.tscn")
const Pilot = preload("res://source/match/units/Pilot.gd")

var pilotable = null
var command_center = null: set = _set_command_center
func _set_command_center(value):
	if value != null:
		Globals.player.last_command_center = value
	command_center = value

@onready var _match = find_parent("Match")
@onready var _multiplayer_controller = _match.find_parent("Multiplayer")

func _unhandled_input(event):
	if event.is_action_pressed("toggle_play_mode"):
		_toggle_play_mode.rpc_id(1)

@rpc("any_peer", "reliable")
func _toggle_play_mode():
	if not multiplayer.is_server():
		print("_toggle_play_mode should only be called on the server")
		return
	var remoteID = multiplayer.get_remote_sender_id()
	var player = _multiplayer_controller.players[remoteID]
	# playing in FPS
	if player.play_mode == Constants.PlayModes.Pilot:
		if player.piloted_unit is Pilot:
			# enter ship
			if pilotable != null:
				player.piloted_unit.tree_exited.disconnect(enter_command_center)
				player.piloted_unit.queue_free()
				pilot_unit.rpc_id(remoteID,pilotable)
			# enter commandCenter
			elif command_center != null:
				enter_command_center()
				player.piloted_unit.queue_free()
		else:
			# exit ship
			var new_pilot = PilotScene.instantiate()
			MatchSignals.setup_and_spawn_unit.emit(new_pilot, player.piloted_unit.global_transform.translated(Vector3(-1, 0, -1)), Globals.player)
			player.piloted_unit.find_child("Movement").pilotID = 0
			pilot_unit.rpc_id(remoteID,new_pilot)
			
	# playing as operator
	else:
		# exit commandCenter
		if player.last_command_center != null:
			var new_pilot = PilotScene.instantiate()
			MatchSignals.setup_and_spawn_unit.emit(new_pilot, player.last_command_center.global_transform.translated(Vector3(-1, 0, -1)), Globals.player)
			pilot_unit.rpc_id(remoteID,new_pilot)
			player.play_mode = Constants.PlayModes.Pilot

@rpc("authority", "reliable", "call_local")
func pilot_unit(unit):
	unit.find_child("Movement").pilotID = multiplayer.get_unique_id()
	unit.tree_exited.connect(enter_command_center)
	_multiplayer_controller.players[multiplayer.get_unique_id()].piloted_unit = unit
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func enter_command_center():
	_multiplayer_controller.players[multiplayer.get_unique_id()].play_mode = Constants.PlayModes.Operator
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_match.find_child("IsometricCamera3D").make_current()
