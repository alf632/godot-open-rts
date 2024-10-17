extends Node3D

const Faction = preload("res://source/match/players/faction/Faction.tscn")


@onready var _match = find_parent("Match")
@onready var _players_node = _match.find_child("Players")

# Called when the node enters the scene tree for the first time.
func setup_factions() -> void:
	var spawns = {}
	var i = 0
	for player in _match.settings.players:
		if not player.spawn in spawns:
			spawns[player.spawn] = [i]
		else:
			spawns[player.spawn].append(i)
		i+=1
	
	for spawn in spawns.keys():
		var faction = newFaction(spawn)
		for member in spawns[spawn]:
			faction.join_by_id.rpc(member)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func newFaction(spawn):
	var faction = Faction.instantiate()
	faction.spawn = spawn
	_players_node.add_child(faction)
	return faction
	
