extends Resource

enum Visibility { PER_PLAYER, ALL_PLAYERS, FULL }

@export var players: Array[Resource] = []
@export var player_slot_mapping = {}
@export var visibility = Visibility.PER_PLAYER
@export var visible_player = 0

func to_dict():
	return {
		"players": players,
		"player_slot_mapping": player_slot_mapping,
		"visibility": Visibility.PER_PLAYER,
		"visible_player": visible_player
	}
