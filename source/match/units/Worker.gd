extends "res://source/match/units/Unit.gd"

const kind = "Worker"

const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")

var resource_a = 0
var resource_b = 0
var resources_max = null

@onready var _animation_player = find_child("AnimationPlayer")
@onready var _movement = $Movement
@export var damping_factor := 1.0
@export var error_factor := 1.0
@export var stablizing_threshold := 20.0
@export var y_weight := 1.5

@export var stablilizing_altitude_addition = 2.0
@onready var _original_altitude = _movement.altitude

func is_full():
	assert(resource_a + resource_b <= resources_max, "worker capacity was exceeded somehow")
	return resource_a + resource_b == resources_max

func is_loaded():
	return resource_a > 0 or resource_b > 0

func play_collect_animation():
	if not _animation_player.is_playing():
		_animation_player.play("work", -1, 3)

func reset_animation():
	if not _animation_player.is_playing():
		AnimationPlayer.new().play()
		_animation_player.stop()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var dir := Vector3()
	if _movement.piloted:
		dir = _movement._direct.get_velocity()
		state.apply_central_force(dir * movement_speed)
		return
	else:
		var navDir = _movement._nav.get_velocity()
		if (navDir == Vector3() or _movement._nav.path_index == len(_movement._nav.path)-1) and is_instance_valid(action) and action is MovingToUnit:
			if not Utils.Match.UnitUtils.Movement.units_adhere(self, action._target_unit):
				navDir = (action._target_unit.global_position_yless - global_position_yless).normalized()
		var stable = _movement.torque_towards_dir(navDir, state)
		
		if not stable:
			_movement.altitude = _original_altitude + stablilizing_altitude_addition
			dir = _movement._calculate_hold_altitude_dir()
		else:
			_movement.altitude = _original_altitude
			var altDir = _movement._calculate_hold_altitude_dir()
			dir = lerp(navDir, altDir.normalized(), altDir.length())
		
		state.apply_central_force(dir * _movement.linearForce)
