extends Control

const MatchSettings = preload("res://source/data-model/MatchSettings.gd")
const PlayerSettings = preload("res://source/data-model/PlayerSettings.gd")
const LoadingScene = preload("res://source/main-menu/Loading.tscn")
const PlayerScene = preload("res://source/main-menu/Play_player.tscn")

var _map_paths = []

@onready var _start_button = find_child("StartButton")
@onready var _map_list = find_child("MapList")
@onready var _map_details = find_child("MapDetailsLabel")
@onready var multiplayer_controller = find_parent("Multiplayer")
@onready var _players = find_child("Players")

func _ready():
	if multiplayer_controller and multiplayer.is_server():
		multiplayer_controller.player_connected.connect(_on_player_connected)
		multiplayer_controller.player_disconnected.connect(_on_player_disconnected)
		var newPlayer = PlayerScene.instantiate()
		newPlayer.name = "1"
		newPlayer.type = Constants.PlayerType.HUMAN
		_players.add_child(newPlayer)
	_setup_map_list()
	_on_map_list_item_selected(0)

func _on_player_connected(playerId, playerDetails):
	var newPlayer = PlayerScene.instantiate()
	newPlayer.name = str(playerId)
	newPlayer.type = Constants.PlayerType.HUMAN
	_players.add_child(newPlayer, true)

func _on_player_disconnected(playerId):
	for player in _players.get_children():
		if player.playerId == playerId:
			player.queue_free()

func _on_add_ai_pressed() -> void:
	var newPlayer = PlayerScene.instantiate()
	var playerId = 2
	var used_IDs = _players.get_children().map(func(element): return element.playerId)
	while playerId in used_IDs:
		playerId += 1
	newPlayer.name = "AI_"+str(playerId)
	newPlayer.find_child("Name").text = "AI"
	newPlayer.type = Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI
	_players.add_child(newPlayer, true)

func _setup_map_list():
	var maps = Utils.Dict.items(Constants.Match.MAPS)
	maps.sort_custom(func(map_a, map_b): return map_a[1]["players"] < map_b[1]["players"])
	_map_paths = maps.map(func(map): return map[0])
	_map_list.clear()
	for map_path in _map_paths:
		_map_list.add_item(Constants.Match.MAPS[map_path]["name"])
	_map_list.select(0)


func _create_match_settings():
	var match_settings = MatchSettings.new()
	
	for player in _players.get_children():
		var player_settings = PlayerSettings.new()
		player_settings.controller = player.type
		player_settings.player_id = player.playerId
		player_settings.spawn = player.spawn
		#player_settings.color = Constants.Player.COLORS[option_node_id]
		
		match_settings.players.append(player_settings)
		
		
	return match_settings
	
	var option_nodes = find_child("GridContainer").find_children("OptionButton*")
	var spawn_index_offset = 0
	for option_node_id in range(option_nodes.size()):
		var player_controller = option_nodes[option_node_id].selected
		if player_controller != Constants.PlayerType.NONE:
			var player_settings = PlayerSettings.new()
			player_settings.controller = player_controller
			player_settings.color = Constants.Player.COLORS[option_node_id]
			player_settings.spawn_index_offset = spawn_index_offset
			match_settings.players.append(player_settings)
			spawn_index_offset = 0
		else:
			spawn_index_offset += 1

	match_settings.visible_player = -1
	for player_id in range(match_settings.players.size()):
		var player = match_settings.players[player_id]
		if player.controller == Constants.PlayerType.HUMAN:
			match_settings.visible_player = player_id
	if match_settings.visible_player == -1:
		match_settings.visibility = match_settings.Visibility.ALL_PLAYERS
	
	#var multiplayer_controller = find_parent("Multiplayer")
	#if multiplayer_controller:
	#	match_settings.player_slot_mapping = _multiplayer_ui.player_slot_mapping

	return match_settings


func _get_selected_map_path():
	return _map_paths[_map_list.get_selected_items()[0]]


func _on_start_button_pressed():
	hide()
	var new_scene = LoadingScene.instantiate()
	new_scene.match_settings = _create_match_settings()
	new_scene.map_path = _get_selected_map_path()
	
	_rcp_match_details.rpc({"settings": var_to_str(new_scene.match_settings), "map_path": new_scene.map_path})#details)
	
	var multiplayer_controller = find_parent("Multiplayer")
	if multiplayer_controller:
		multiplayer_controller.change_scene(new_scene)
	else:
		get_parent().add_child(new_scene)
		get_tree().current_scene = new_scene
		queue_free()

@rpc("authority", "reliable", "call_remote")
func _rcp_match_details(details):
	Globals.cache["match_details"] = details
	#print(Globals.cache["match_details"])

func _on_back_button_pressed():
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://source/main-menu/Main.tscn")


#func _align_player_controls_visibility_to_map(map):
#	var option_nodes = find_child("GridContainer").find_children("OptionButton*")
#	var label_nodes = find_child("GridContainer").find_children("Label*")
#	assert(option_nodes.size() == label_nodes.size())
#	for node_id in range(option_nodes.size()):
#		option_nodes[node_id].visible = node_id < map["players"]
#		label_nodes[node_id].visible = node_id < map["players"]

@rpc("call_remote", "authority", "reliable")
func _on_player_selected(selected_option_id, selected_player_id):
	var multiplayer_controller = find_parent("Multiplayer")
	if multiplayer_controller:
		if multiplayer.is_server():
			_on_player_selected.rpc(selected_option_id, selected_player_id)
		else:
			var option_node = find_child("GridContainer").find_child("OptionButton"+str(selected_player_id))
			option_node.selected = selected_option_id
	_start_button.disabled = false
	if selected_option_id == Constants.PlayerType.HUMAN:
		var option_nodes = find_child("GridContainer").find_children("OptionButton*")
		for option_node_id in range(option_nodes.size()):
			if (
				option_node_id != selected_player_id
				and option_nodes[option_node_id].selected == Constants.PlayerType.HUMAN
			):
				option_nodes[option_node_id].selected = (Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	elif selected_option_id == Constants.PlayerType.NONE:
		var option_nodes_with_player_controllers = (
			find_child("GridContainer")
			. find_children("OptionButton*")
			. filter(func(option_node): return option_node.selected != Constants.PlayerType.NONE)
		)
		if option_nodes_with_player_controllers.size() < 2:
			_start_button.disabled = true

@rpc("call_remote", "authority", "reliable")
func _on_map_list_item_selected(index):
	var multiplayer_controller = find_parent("Multiplayer")
	if multiplayer_controller:
		if multiplayer.is_server():
			_on_map_list_item_selected.rpc(index)
		else:
			_map_list.select(index)
	var map = Constants.Match.MAPS[_map_paths[index]]
	_map_details.text = "[u]Slots:[/u] {0}\n[u]Size:[/u] {1}x{2}".format(
		[map["players"], map["size"].x, map["size"].y]
	)
