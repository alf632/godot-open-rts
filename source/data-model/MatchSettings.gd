extends Resource

enum Visibility { PER_PLAYER, ALL_PLAYERS, FULL }

@export var players: Array[Resource] = []
@export var player_slot_mapping = {}
@export var visibility = Visibility.PER_PLAYER
@export var visible_player = 0
