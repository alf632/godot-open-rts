extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal synced

const Play = preload("res://source/main-menu/Play.tscn")

const PORT = 4433
const DEFAULT_SERVER_IP = "127.0.0.1"

# This will contain player info for every player,
# with the keys being each player's unique IDs.
@export var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name"}

var queued_players = 0

func _ready():
	# Start paused.
	#get_tree().paused = true
	# You can save bandwidth by disabling server relay and peer notifications.
	#multiplayer.server_relay = false
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		_on_host_pressed.call_deferred()


func _on_host_pressed():
	# Start as server.
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer

	players[1] = player_info
	player_connected.emit(1, player_info)

	start_lobby()


func _on_connect_pressed():
	# Start as client.
	var address : String = $UI/Net/Options/Remote.text
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	start_lobby()


func start_lobby():
	# Hide the UI and unpause to start the game.
	$UI.hide()
	#get_tree().paused = false
	if multiplayer.is_server():
		var play = Play.instantiate()
		change_scene.call_deferred(play)

# Call this function deferred and only on the main authority (server).
func change_scene(scene: Node):
	if not multiplayer.is_server():
		return
	# Remove old level if any.
	var activeScene = $ActiveScene
	for c in activeScene.get_children():
		activeScene.remove_child(c)
		c.queue_free()
	# Add new activeScene.
	activeScene.add_child(scene)

func sync_lock():
	print("player {0} lock".format([str(multiplayer.get_unique_id())]))
	_rpc_player_queued.rpc_id.call_deferred(1)
	await synced
	print("player {0} unlock".format([str(multiplayer.get_unique_id())]))

func map_player(id, obj):
	players[id].player = obj

@rpc("any_peer", "call_local", "reliable")
func _rpc_player_queued():
	if multiplayer.is_server():
		print("player {0} queued".format([str(multiplayer.get_remote_sender_id())]))
		queued_players += 1
		if queued_players == players.size():
			print("sync complete")
			queued_players = 0
			
			_rcp_synced.rpc()
			return
		print("{0} of {1}".format([queued_players,players.size()]))
	else:
		print("_rpc_player_queued should not be called on {0} by {1}".format([str(multiplayer.get_remote_sender_id()),str(multiplayer.get_unique_id())]))

@rpc("authority", "call_local", "reliable")
func _rcp_synced():
	print("unlocking {0}".format([multiplayer.get_unique_id()]))
	synced.emit()
	
# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)
	print("player {0} connected".format([id]))

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)
	print("player {0} disconnected".format([id]))

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)
	print("connected ok as {0}".format([peer_id]))

func _on_connected_fail():
	multiplayer.multiplayer_peer = null
	print("connection failed")


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	print("server disconnected")
