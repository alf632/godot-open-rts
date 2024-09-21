extends PanelContainer

@export var playerId := 1
@export var type: int

@onready var _index = find_child("Index")
@onready var _spawn = find_child("Spawn")
@onready var _name = find_child("Name")
@onready var _name_edit = find_child("NameEdit")
@onready var _edit = find_child("Edit")
@onready var multiplayer_controller = find_parent("Multiplayer")

var spawn:
	get():
		return _spawn.selected


func _enter_tree():
	if multiplayer:
		if "AI_" in str(name):
			playerId=str(name).split("_")[1].to_int()
		else:
			playerId=str(name).to_int()
			$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	_index.text = str(playerId)
	if not multiplayer_controller:
		if type == Constants.PlayerType.HUMAN:
			_edit.show()
		return
	
	if multiplayer_controller.players.has(playerId):
		_name.text = str(multiplayer_controller.players[playerId].name)
	
	if type == Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI and multiplayer.is_server():
		_edit.show()
		return
	
	if playerId == multiplayer.get_unique_id():
		_edit.show()
	else:
		_spawn.disabled = true


func _on_edit_pressed() -> void:
	_name.hide()
	_edit.hide()
	_name_edit.show()
	_name_edit.grab_focus.call_deferred()

func _on_name_edit_text_submitted(new_text: String) -> void:
	_name.text = _name_edit.text
	_name.show()
	_edit.show()
	_name_edit.hide()
