extends Node3D

signal movement_finished
signal passive_movement_started
signal passive_movement_finished

@onready var _Match = find_parent("Match")
@onready var _NavHandler = _Match.find_child("NavHandler")
@onready var _moveTrait = get_parent()
@onready var _Unit = _moveTrait.get_parent()

@export var climb_angle = PI * 0.125
@export var min_target_distance = 1.5
@export var waypoint_reach = 1.0

var target = Vector3()
var path = []
var path_index = 0
var path_visualizer = null
var path_recalc_timer := 0.0
var path_recalc_timeout = 5.0

var _moving = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(false)

func _process(delta: float) -> void:
	path_recalc_timer += delta

func _exit_tree():
	if path_visualizer != null:
		path_visualizer.destroy()

func move(movement_target: Vector3):
	target = movement_target
	_moving = true
	set_physics_process(true)

func stop():
	target = _Unit.global_position
	path = null
	_moving = false

func _physics_process_disabled(delta):
	#if piloted:
	#	return
		
	var _dir = Vector3()
	if _moving:
		_dir = _calculate_path_dir()
	
	
	_Unit.velocity = _dir.normalized() * _Unit.movement_speed * delta
	_Unit.move_and_slide()

func get_velocity():
	var _dir = Vector3()
	if _moving:
		_dir = _calculate_path_dir()

	return _dir.normalized()

func _calculate_path_dir():
	if path_recalc_timer > path_recalc_timeout:
		path = null
		path_recalc_timer = 0
	var dir = Vector3()
	if not path:
		if _Unit.global_position_yless.distance_to(target * Vector3(1,0,1)) > min_target_distance:
			path = _NavHandler.find_path_with_max_climb_angle(
				_Unit.global_position, target, null, climb_angle
			)
			path_recalc_timer = 0
			path_index = 0
			if path_visualizer != null:
				path_visualizer.destroy()
				path_visualizer = null
			path_visualizer = _NavHandler.create_path_visualizer(path)
			_moving = true
		elif _moving:
			_moving = false
			if path_visualizer != null:
				path_visualizer.destroy()
				path_visualizer = null
			movement_finished.emit()
			return dir
		else:
			return dir

	if path:
		if path_index < clamp(path.size(),0,10):
			dir = ((path[path_index]+Vector3(0,0.1,0)) - _Unit.global_position).normalized()
		else:
			path = null
			return Vector3()
		
		var waypoint_distance = _Unit.global_position_yless.distance_to(path[path_index]*Vector3(1,0,1))
		if waypoint_distance < waypoint_reach:
			path_index += 1
			path_recalc_timer = 0
		
		# if there is a next waypoint
		if path_index+1 < len(path):
			# and that waypoint is closer to the unit
			if _Unit.global_position_yless.distance_to(path[path_index+1]*Vector3(1,0,1)) < waypoint_distance:
				# switch to it
				path_index += 1
				path_recalc_timer = 0

		
	return dir
	#return 0.1*dir*_Unit.movement_speed + 0.9 * _Unit.velocity
