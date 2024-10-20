extends CollisionObject3D

signal selected
signal deselected
signal hp_changed
signal action_changed(new_action)
signal action_updated

const Actions = {
	"Moving" = preload("res://source/match/units/actions/Moving.gd"),
	"MovingToUnit" = preload("res://source/match/units/actions/MovingToUnit.gd"),
	"Following" = preload("res://source/match/units/actions/Following.gd"),
	"CollectingResourcesSequentially" = preload(
		"res://source/match/units/actions/CollectingResourcesSequentially.gd"
	),
	"AutoAttacking" = preload("res://source/match/units/actions/AutoAttacking.gd"),
	"Constructing" = preload("res://source/match/units/actions/Constructing.gd"),
}

const Faction = preload("res://source/match/players/faction/Faction.gd")
const Player = preload("res://source/match/players/Player.gd")
const Unit = preload("res://source/match/units/Unit.gd")

const MATERIAL_ALBEDO_TO_REPLACE = Color(0.99, 0.81, 0.48)
const MATERIAL_ALBEDO_TO_REPLACE_EPSILON = 0.05

@onready var _multiplayer_controller = find_parent("Multiplayer")
@onready var _match = find_parent("Match")
@onready var _units = _match.find_child("Units")
@onready var _resources = _match.find_child("Map").find_child("Resources")

var hp = null:
	set = _set_hp
var hp_max = null:
	set = _set_hp_max
var attack_damage = null
var projectile_speed = null
var attack_interval = null
var attack_range = null
var attack_aim = null
var attack_domains = []
var radius:
	get = _get_radius
var movement_domain:
	get = _get_movement_domain
var movement_speed = null
var sight_range = null
var player
var color:
	get:
		return player.color
var action = null:
	set = _set_action
var global_position_yless:
	get:
		return global_position * Vector3(1, 0, 1)
var type:
	get = _get_type

var groups_str

var _action_locked = false


func _setup_unit_groups():
	add_to_group("units")
	
	var controlled = false
	var friendly = false
	var revealed = false
	if player is Faction:
		for P in player.members:
			add_to_group("units_{0}".format([P.id]))
			if P.id == Globals.player.id:
				controlled = true
				revealed = true
	else:
		add_to_group("units_{0}".format([player.id]))
		if player.id == Globals.player.id:
			controlled = true
			revealed = true
		else:
			for F in player.factions:
				for P in F.members:
					if P.id == Globals.player.id:
						revealed = true
						friendly = true
		
		
	
	if controlled:
		add_to_group("controlled_units")
		add_to_group("friendly_units")
	elif friendly:
		add_to_group("friendly_units")
	else:
		add_to_group("adversary_units")
		
	if revealed:
		add_to_group("revealed_units")

func _ready():
	if not _match.is_node_ready():
		await _match.ready
	_setup_unit_groups()
	_setup_color()
	_setup_default_properties_from_constants()
	global_position = _match.map.get_pos_floored(global_position)
	#assert(_safety_checks())
	


func is_revealing():
	return is_in_group("revealed_units") and visible


func _set_hp(value):
	hp = max(0, value)
	hp_changed.emit()
	if hp == 0:
		_handle_unit_death()


func _set_hp_max(value):
	hp_max = value
	hp_changed.emit()


func _get_radius():
	if find_child("Movement") != null:
		return find_child("Movement").radius
	if find_child("MovementObstacle") != null:
		return find_child("MovementObstacle").radius
	return radius


func _get_movement_domain():
	if find_child("Movement") != null:
		return find_child("Movement").domain
	if find_child("MovementObstacle") != null:
		return find_child("MovementObstacle").domain
	return null


func _get_actual_movement_speed():
	if find_child("Movement") != null:
		return find_child("Movement").speed
	return 0.0


func _is_movable():
	if movement_speed and movement_speed > 0.0:
		return true
	return false


func _setup_color():
	var material = player.get_color_material()
	Utils.Match.traverse_node_tree_and_replace_materials_matching_albedo(
		find_child("Geometry"),
		MATERIAL_ALBEDO_TO_REPLACE,
		MATERIAL_ALBEDO_TO_REPLACE_EPSILON,
		material
	)


func _set_action(new_action):
	action = new_action

func clear_action():
	set_action_string(null)

func set_action_string(action_string, args=null, targetUnitName="", targetResourceName=""):
	if multiplayer.is_server():
		_do_set_action(action_string, args, targetUnitName, targetResourceName)
	else:
		request_set_action.rpc_id(1, action_string, args, targetUnitName, targetResourceName)

@rpc("any_peer", "reliable", "call_remote")
func request_set_action(action_string, args, targetUnitName, targetResourceName):
	_do_set_action.rpc(action_string, args, targetUnitName, targetResourceName)

@rpc("authority", "reliable", "call_local")
func _do_set_action(action_string, args=null, targetUnitName="", targetResourceName=""):
	# if args is a string it is most probably a targetUnit
	if not args:
		if targetUnitName:
			var targetUnit = _units.find_child(targetUnitName,false,false)
			if targetUnit:
				args = targetUnit
		elif targetResourceName:
			var targetResource = _resources.find_child(targetResourceName)
			if targetResource:
				args = targetResource
	var action_node
	if not action_string:
		action_node=null
	else:
		action_node = Actions[action_string].new(args)
	
	if not is_inside_tree() or _action_locked:
		if action_node != null:
			action_node.queue_free()
		return
	_action_locked = true
	_teardown_current_action()
	action = action_node
	if action != null:
		var action_copy = action  # bind() performs copy itself, but lets force copy just in case
		action.tree_exited.connect(_on_action_node_tree_exited.bind(action_copy))
		add_child(action_node)
	_action_locked = false
	action_changed.emit(action)


func _get_type():
	var unit_script_path = get_script().resource_path
	var unit_file_name = unit_script_path.substr(unit_script_path.rfind("/") + 1)
	var unit_name = unit_file_name.split(".")[0]
	return unit_name


func _teardown_current_action():
	if action != null and action.is_inside_tree():
		action.queue_free()
		remove_child(action)  # triggers _on_action_node_tree_exited immediately


func _safety_checks():
	if movement_domain == Constants.Match.Navigation.Domain.AIR:
		assert(
			(
				radius < Constants.Match.Air.Navmesh.MAX_AGENT_RADIUS
				or is_equal_approx(radius, Constants.Match.Air.Navmesh.MAX_AGENT_RADIUS)
			),
			"Unit radius exceeds the established limit"
		)
	elif movement_domain == Constants.Match.Navigation.Domain.TERRAIN:
		assert(
			(
				not _is_movable()
				or (
					radius < Constants.Match.Terrain.Navmesh.MAX_AGENT_RADIUS
					or is_equal_approx(radius, Constants.Match.Terrain.Navmesh.MAX_AGENT_RADIUS)
				)
			),
			"Unit radius exceeds the established limit"
		)
	return true


func _handle_unit_death():
	tree_exited.connect(func(): MatchSignals.unit_died.emit(self))
	queue_free()


func _setup_default_properties_from_constants():
	var default_properties = Constants.Match.Units.DEFAULT_PROPERTIES[
		get_script().resource_path.replace(".gd", ".tscn")
	]
	for property in default_properties:
		set(property, default_properties[property])


func _on_action_node_tree_exited(action_node):
	assert(action_node == action, "unexpected action released")
	action = null

func is_friendly_towards(entity):
	if "friendly_units" in entity.get_groups():
		return true
	
	var players = []
	if entity is Unit:
		players.append(entity.player)
	elif entity is Faction:
		for p in entity.members:
			players.append(p)
	elif entity is Player:
		players.append(entity)
	else:
		printerr("unexpected flow")
		return
	
	var friendly = false
	for p in players:
		if p.id == player.id:
			friendly = true
			break

	return friendly

func is_controllable_by(other_player):
	if other_player.id == player.id:
		return true
	
	if player is Faction:
		for p in player.members:
			if p.id == other_player.id:
				return true
	
	return false
