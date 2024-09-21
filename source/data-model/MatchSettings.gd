extends Resource

const _player_settings = preload("res://source/data-model/PlayerSettings.gd")

enum Visibility { PER_PLAYER, ALL_PLAYERS, FULL }

@export var players: Array[_player_settings] = []
@export var player_slot_mapping = {}
@export var visibility = Visibility.PER_PLAYER
@export var visible_player = 0
