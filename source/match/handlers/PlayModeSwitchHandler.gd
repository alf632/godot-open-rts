extends Node3D

const PilotScene = preload("res://source/match/units/Pilot.tscn")
const Pilot = preload("res://source/match/units/Pilot.gd")

@onready var _match = find_parent("Match")
@onready var _units = _match.find_child("Units")
@onready var _multiplayer_controller = _match.find_parent("Multiplayer")

func _unhandled_input(event):
	if event.is_action_pressed("toggle_play_mode"):
		_toggle_play_mode.rpc_id(1)

@rpc("any_peer", "reliable", "call_local")
func _toggle_play_mode():
	if not multiplayer.is_server():
		print("_toggle_play_mode should only be called on the server")
		return
	var remoteID = multiplayer.get_remote_sender_id()
	var player = _multiplayer_controller.players[remoteID].player
	# playing in FPS
	if player.play_mode == Constants.PlayModes.Pilot:
		if player.piloted_unit is Pilot:
			# enter ship
			if player.pilotable != null:
				player.piloted_unit.queue_free()
				pilot_unit.rpc_id(remoteID,player.pilotable.name)
				player.piloted_unit = player.pilotable
			# enter commandCenter
			elif player.command_center != null:
				enter_command_center.rpc_id(remoteID)
				player.piloted_unit.queue_free()
				player.piloted_unit = null
		else:
			# exit ship
			var new_pilot = player.setup_and_spawn_unit("Pilot", player.piloted_unit.global_transform.translated(Vector3(-1, 0, -1)))
			pilot_unit.rpc_id(remoteID,new_pilot.name)
			player.piloted_unit = new_pilot
			
	# playing as operator
	else:
		# exit commandCenter
		if player.last_command_center != null:
			var new_pilot = player.setup_and_spawn_unit("Pilot", player.last_command_center.global_transform.translated(Vector3(-1, 0, -1)))
			pilot_unit.rpc_id(remoteID,new_pilot.name)
			player.piloted_unit = new_pilot
			

@rpc("authority", "reliable", "call_local")
func pilot_unit(unitName):
	if Globals.player.piloted_unit:
		Globals.player.piloted_unit.find_child("Movement").unpilot()
		Globals.player.piloted_unit.tree_exited.disconnect(enter_command_center)
	var unit = _units.find_child(unitName, false, false)
	unit.find_child("Movement").pilot()
	unit.tree_exited.connect(enter_command_center)
	Globals.player.piloted_unit = unit
	Globals.player.play_mode = Constants.PlayModes.Pilot
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

@rpc("authority", "reliable", "call_local")
func enter_command_center():
	if Globals.player.piloted_unit:
		Globals.player.piloted_unit.find_child("Movement").unpilot()
		Globals.player.piloted_unit.tree_exited.disconnect(enter_command_center)
	Globals.player.piloted_unit = null
	Globals.player.play_mode = Constants.PlayModes.Operator
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_match.find_child("IsometricCamera3D").make_current()
