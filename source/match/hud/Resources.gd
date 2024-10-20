extends VBoxContainer

const Human = preload("res://source/match/players/human/Human.gd")

@onready var _match = find_parent("Match")
@onready var _players = _match.find_child("Players")

# TODO: handle human player removal/addition


func _ready():
	_hide_all_bars()
	if not _match.is_initialized:
		set_process(false)
		await MatchSignals.match_started
		set_process(true)
	_setup_all_bars()
	
	
	if (
		_match.settings.visibility == _match.MatchSettings.Visibility.PER_PLAYER
	):
		for f in Globals.player.factions:
			_show_player_bars(f)
		_show_player_bars(Globals.player)
	else:
		_show_player_bars(_players.get_children())


func _hide_all_bars():
	for bar in get_children():
		bar.hide()


func _setup_all_bars():
	var bar_nodes = get_children()
	var players = _players.get_children()
	for i in range(players.size()):
		bar_nodes[i].setup(players[i])


func _show_player_bars(player):
	for bar_node in get_children():
		if bar_node.player == player:
			bar_node.show()
