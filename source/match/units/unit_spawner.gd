extends MultiplayerSpawner

const Structure = preload("res://source/match/units/Structure.gd")
const CommandCenter = preload("res://source/match/units/CommandCenter.tscn")
const Drone = preload("res://source/match/units/Drone.tscn")
const Worker = preload("res://source/match/units/Worker.tscn")
const Pilot = preload("res://source/match/units/Pilot.tscn")

@onready var _match = get_parent()
@onready var _players = _match.find_child("Players")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_spawn_function(spawn_unit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# data= {"unitType": "CommandCenter", "transform": Ventor3(), "playerID": 1, "constructing": true}
func spawn_unit(data):
	var unit
	if data.unitType == "CommandCenter":
		unit = CommandCenter.instantiate()
	elif data.unitType == "Drone":
		unit = Drone.instantiate()
	elif data.unitType == "Worker":
		unit = Worker.instantiate()
	elif data.unitType == "Pilot":
		unit = Pilot.instantiate()
	else:
		printerr("unitType \"{0}\" not supported by spawner".format([data.unitType]))
		return
	
	if unit is Structure and data.constructing:
		unit.mark_as_under_construction()
	
	unit.global_transform = data.transform.translated(Vector3(0, _match.map.terrain.storage.get_height(data.transform.origin)+1, 0))
	unit.player = _players.get_child(data.playerID)
	if not unit.player:
		print("no player")
	
	MatchSignals.unit_spawned.emit.call_deferred(unit)
	return unit
