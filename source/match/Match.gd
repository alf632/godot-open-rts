extends Node3D

signal rcp_match_ready

const Unit = preload("res://source/match/units/Unit.gd")
const Player = preload("res://source/match/players/Player.gd")
const Human = preload("res://source/match/players/human/Human.gd")

const Pilot = preload("res://source/match/units/Pilot.tscn")

const MatchSettings = preload("res://source/data-model/MatchSettings.gd")

@export var settings: Dictionary = {}

var map:
	set = _set_map,
	get = _get_map
var visible_player = null:
	set = _set_visible_player
var visible_players = null:
	set = _ignore,
	get = _get_visible_players

@onready var fog_of_war = $FogOfWar

@onready var _camera = $IsometricCamera3D
@onready var _players = $Players
@onready var _SH = $Handlers/PlayModeSwitchHandler
@onready var _multiplayer_controller = find_parent("Multiplayer")

var is_initialized = false


#func _enter_tree():
	#assert(settings != null, "match cannot start without settings, see examples in tests/manual/")
	#assert(map != null, "match cannot start without map, see examples in tests/manual/")


func _ready():
	if not _multiplayer_controller or multiplayer.is_server():
		print("waiting for initial sync")
		await _multiplayer_controller.sync_lock()
		print("synced")
		
		print("waiting for map sync")
		await _multiplayer_controller.sync_lock()
		print("synced")
		
		MatchSignals.setup_and_spawn_unit.connect(_spawn_unit)
		_setup_subsystems_dependent_on_map()
		_setup_players()
		_setup_player_units()
		visible_player = get_tree().get_nodes_in_group("players")[settings.visible_player]
		_move_camera_to_initial_position()
		if settings.visibility == MatchSettings.Visibility.FULL:
			fog_of_war.reveal()
		print("waiting for units sync")
		await _multiplayer_controller.sync_lock()
		print("synced")
		_rcp_match_ready.rpc()
		is_initialized = true
		MatchSignals.match_started.emit()
	else:
		print("waiting for initial sync")
		await _multiplayer_controller.sync_lock()
		print("synced")
		
		_set_map(Globals.cache["map"])
		#Globals.cache.erase("map")
		settings = Globals.cache["match_details"].settings
		#Globals.cache.erase("match_details")
		_setup_subsystems_dependent_on_map()
		print("waiting for map sync")
		await _multiplayer_controller.sync_lock()
		print("synced")
		
		print("waiting for units sync")
		await _multiplayer_controller.sync_lock()
		print("synced")
		is_initialized = true
		

@rpc("authority", "reliable", "call_remote")
func _rcp_match_ready():
	rcp_match_ready.emit()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.is_action_pressed("shift_selecting"):
			return
		MatchSignals.deselect_all_units.emit()

func _spawn_unit(unit_to_spawn, target_transform, _player):
	_player.setup_and_spawn_unit(unit_to_spawn, target_transform, true)

func _set_map(a_map):
	assert(get_node_or_null("Map") == null, "map already set")
	a_map.name = "Map"
	add_child(a_map)
	a_map.owner = self


func _ignore(_value):
	pass


func _get_map():
	return get_node_or_null("Map")


func _set_visible_player(player):
	_conceal_player_units(visible_player)
	_reveal_player_units(player)
	visible_player = player


func _get_visible_players():
	if settings.visibility == MatchSettings.Visibility.PER_PLAYER:
		return [visible_player]
	return get_tree().get_nodes_in_group("players")


func _setup_subsystems_dependent_on_map():
	var mapsize = map.size
	fog_of_war.resize(mapsize)
	_recalculate_camera_bounding_planes(mapsize)


func _recalculate_camera_bounding_planes(map_size: Vector2):
	_camera.bounding_planes[1] = Plane(-1, 0, 0, -map_size.x)
	_camera.bounding_planes[3] = Plane(0, 0, -1, -map_size.y)


func _setup_players():
	assert(
		_players.get_children().is_empty() or settings.players.is_empty(),
		"players can be defined either in settings or in scene tree, not in both"
	)
	if _players.get_children().is_empty():
		_create_players_from_settings()
	for node in _players.get_children():
		if node is Player:
			node.add_to_group("players")


func _create_players_from_settings():
	for player_settings in settings.players:
		var player_scene = Constants.Match.Player.CONTROLLER_SCENES[player_settings.controller]
		var player = player_scene.instantiate()
		player.color = player_settings.color
		if player_settings.spawn_index_offset > 0:
			for _i in range(player_settings.spawn_index_offset):
				_players.add_child(Node.new())
		_players.add_child(player)


func _setup_player_units():
	for player in _players.get_children():
		if not player is Player:
			continue
		if player is Human:
			var player_spawn = map.find_child("SpawnPoints").get_child(player.id)
			Globals.player = player
			var pilot = Pilot.instantiate()
			player.setup_and_spawn_unit(pilot, player_spawn.global_transform.translated(Vector3(-3, 0, -3)))
			_SH.pilot_unit(pilot)


func get_human_player():
	var human_players = get_tree().get_nodes_in_group("players").filter(
		func(player): return player is Human
	)
	assert(human_players.size() <= 1, "more than one human player is not allowed")
	if not human_players.is_empty():
		return human_players[0]
	return null


func _move_camera_to_initial_position():
	var human_player = get_human_player()
	if human_player != null:
		_move_camera_to_player_units_crowd_pivot(human_player)
	else:
		_move_camera_to_player_units_crowd_pivot(get_tree().get_nodes_in_group("players")[0])


func _move_camera_to_player_units_crowd_pivot(player):
	var player_units = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit.player == player
	)
	assert(not player_units.is_empty(), "player must have at least one initial unit")
	var crowd_pivot = Utils.Match.Unit.Movement.calculate_aabb_crowd_pivot_yless(player_units)
	_camera.set_position_safely(crowd_pivot)


func _reveal_player_units(player):
	if player == null:
		return
	for unit in get_tree().get_nodes_in_group("units").filter(
		func(a_unit): return a_unit.player == player
	):
		unit.add_to_group("revealed_units")


func _conceal_player_units(player):
	if player == null:
		return
	for unit in get_tree().get_nodes_in_group("units").filter(
		func(a_unit): return a_unit.player == player
	):
		unit.remove_from_group("revealed_units")
