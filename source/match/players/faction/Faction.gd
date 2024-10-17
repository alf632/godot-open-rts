extends "res://source/match/players/Player.gd"

@onready var _players_node = _match.find_child("Players")

var members = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_base_units(spawn_transform):
	setup_and_spawn_unit("CommandCenter", spawn_transform, false)
	setup_and_spawn_unit(
		"Drone", spawn_transform.translated(Vector3(-2, 0, -2))
	)
	setup_and_spawn_unit(
		"Worker", spawn_transform.translated(Vector3(-3, 0, 3))
	)
	setup_and_spawn_unit(
		"Worker", spawn_transform.translated(Vector3(3, 0, 3))
	)

@rpc("authority", "call_local", "reliable")
func join_by_id(playerID):
	var player = _players_node.get_child(playerID)
	join(player)

func join(player):
	members.append(player)
	player.factions.append(self)
