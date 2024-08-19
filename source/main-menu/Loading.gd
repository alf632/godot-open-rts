extends Control

var match_settings = null
var map_path = null

@onready var _label = find_child("Label")
@onready var _progress_bar = find_child("ProgressBar")
@onready var multiplayer_controller = find_parent("Multiplayer")

func _ready():
	_progress_bar.value = 0.0

	_label.text = tr("LOADING_STEP_PRELOADING")
	await get_tree().physics_frame
	_preload_scenes()
	_progress_bar.value = 0.2

	_label.text = tr("LOADING_STEP_LOADING_MAP")
	await get_tree().physics_frame
	if multiplayer_controller and not multiplayer.is_server():
		var map = load(Globals.cache["match_details"].map_path).instantiate()
		Globals.cache["map"] = map
		_label.text += " - Sync"
		await multiplayer_controller.sync_lock()
		print("client waiting for server scene switch")
		return
		
	var map = load(map_path).instantiate()
	_progress_bar.value = 0.4	

	_label.text = tr("LOADING_STEP_LOADING_MATCH")
	await get_tree().physics_frame
	var match_prototype = load("res://source/match/Match.tscn")
	_progress_bar.value = 0.7

	_label.text = tr("LOADING_STEP_INSTANTIATING_MATCH")
	await get_tree().physics_frame
	var a_match = match_prototype.instantiate()
	a_match.settings = match_settings.to_dict()
	a_match.map = map
	_progress_bar.value = 0.9

	_label.text = tr("LOADING_STEP_STARTING_MATCH")
	await get_tree().physics_frame
	if multiplayer_controller:
		await multiplayer_controller.sync_lock()
		print("server switches scene")
		_on_all_clients_loaded(a_match)
	else:
		get_parent().add_child(a_match)
		get_tree().current_scene = a_match
		queue_free()

func _on_all_clients_loaded(a_match):
	multiplayer_controller.change_scene(a_match)

func _preload_scenes():
	var scene_paths = []
	scene_paths += Constants.Match.Units.PROJECTILES.values()
	scene_paths += Constants.Match.Units.CONSTRUCTION_COSTS.keys()
	for scene_path in scene_paths:
		Globals.cache[scene_path] = load(scene_path)
