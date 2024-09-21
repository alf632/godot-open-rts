extends "res://source/match/players/Player.gd"

const AI = preload("res://source/match/players/simple-clairvoyant-ai/ai.tscn")
const Human = preload("res://source/match/players/human/human_handler.tscn")

@onready var _SH = _match.find_child("PlayModeSwitchHandler")
@onready var _multiplayer_controller = _match.find_parent("Multiplayer")

var playerid: int
var type: int

func _ready() -> void:
	
	var split = name.split("_")
	playerid = split[0].to_int()
	type = split[1].to_int()
	
	if type == Constants.PlayerType.HUMAN and playerid == multiplayer.get_unique_id():
		var newHumanControls = Human.instantiate()
		add_child(newHumanControls)
		_multiplayer_controller.map_player(playerid, self)
		Globals.player = self
	
	if type == Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI and multiplayer.is_server():
		var newAi = AI.instantiate()
		add_child(newAi)
		return
