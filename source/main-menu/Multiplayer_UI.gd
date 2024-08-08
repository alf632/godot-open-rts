extends VBoxContainer

const Slot = preload("res://source/main-menu/MultiPlay/slot.tscn")

@onready var Play = find_parent("Play")
@onready var multiplayer_controller = find_parent("Multiplayer")

var _player_slot_mapping = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	if not multiplayer_controller:
		hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_map_change(num_player):
	for c in $Slots.get_children():
		c.disconnect("selected", on_slot_selected)
		c.disconnect("name_changed", on_name_changed)
		$Slots.remove_child(c)
		c.queue_free()
	for i in range(0,num_player):
		var slot = Slot.instantiate()
		slot.id = i
		slot.connect("selected", on_slot_selected)
		slot.connect("name_changed", on_name_changed)
		$Slots.add_child(slot)

func on_slot_selected(slotid):
	send_slot_selected.rpc_id(1, slotid)

@rpc("any_peer", "reliable", "call_local")
func send_slot_selected(slotid):
	if not multiplayer.is_server():
		return
	var playerid = multiplayer.get_remote_sender_id()
	sync_slot_selection.rpc(slotid, playerid)

@rpc("authority", "reliable", "call_local")
func sync_slot_selection(slotid, playerid):
	if _player_slot_mapping.has(playerid):
		var slot = $Slots.get_children()[_player_slot_mapping[playerid]]
		slot.player_name = ""
		slot.player_id = 0
		
	_player_slot_mapping[playerid] = slotid
	var slot = $Slots.get_children()[slotid]
	slot.player_name=multiplayer_controller.players[playerid].name
	slot.player_id = playerid
	
func on_name_changed(player_name):
	send_name_changed.rpc_id(1, player_name)

@rpc("any_peer", "reliable", "call_local")
func send_name_changed(player_name):
	if not multiplayer.is_server():
		return
	var playerid = multiplayer.get_remote_sender_id()
	sync_name_changed.rpc(player_name, playerid)

@rpc("authority", "reliable", "call_local")
func sync_name_changed(player_name, playerid):
	multiplayer_controller.players[playerid].name = player_name
	if playerid == multiplayer.get_unique_id():
		multiplayer.player_info.name = player_name
	var slot = $Slots.get_children()[_player_slot_mapping[playerid]]
	slot.player_name=multiplayer_controller.players[playerid].name
